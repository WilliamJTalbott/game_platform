# Leaderboard — Ransack

**Goal: turn the leaderboard from a board you can only re-order into one you can
interrogate — narrow it to a country, to players who actually play, or to the one name
you're looking for, and watch the table answer as you type.**

Today the board is all-or-nothing: 1,000 seeded players, four sort orders, no way to
ask a smaller question. Ransack is now in the Gemfile (4.4.1). This replaces the
hand-rolled `SORTS` whitelist with ransack's search object and adds three filters, each
deliberately demonstrating a different predicate — `eq`, `gteq`, `i_cont`.

Status legend: 🟡 planned · 🟢 in progress · ✅ done

---

## 1. Decisions already made

Settled in conversation — do not re-litigate these while implementing:

| Question | Decision |
|---|---|
| Country source | **New Scenic view version `player_stats_v02`** adding `users.country`. Ransack filters `country_eq` on a flat `PlayerStat` — no join, no `ransackable_associations` |
| Sort UI | **Keep the four preset buttons.** No `sort_link` headers. Each button sets `q[s]` instead of `sort=` |
| Tie-breakers | **Preserved.** Server appends the same secondary sorts (`games_played desc`, `name asc`) behind whichever primary sort arrives |
| Win % floor | **No longer hidden.** The Win % button also sets `q[games_played_gteq]=5`, so the min-games control visibly reads 5 and the user can change it. The special case in `Leaderboard` is deleted |
| `games_played >= 1` | **Stays** as a hardcoded base scope. A crafted `q` param must not be able to surface players who never finished a game |
| Submission | **No Apply button.** A Stimulus controller submits the form: immediately on select/button change, debounced on typing |
| Frame scope | **Results only.** `turbo_frame_tag "leaderboard_results"` wraps the table + pagination. Form and sort buttons live *outside* it so the name field never loses its caret |
| Name predicate | `name_i_cont` — case-insensitive substring |
| Min games control | **`number_field`**, `min: 1`, not a preset dropdown |
| Country dropdown | The **full `Data::Country.all` list**, same collection as `users/edit.html.slim`, with `include_blank: "All countries"` |
| Seeding | Bulk players get one of **~8 hand-picked country ids**, US weighted heaviest, drawn from the existing deterministic `Random.new(20260728)` |
| Country in rows | **Flag prefixing the player's name.** No new column |
| Where the search object lives | `Leaderboard` builds it from the hardened base scope; `LeaderboardPresenter` exposes it as `#query` for the form |

Out of scope: `sort_link` headers, ascending toggles, per-game-type filters, date ranges,
advanced/`groupings` mode, saved searches.

---

## 2. Non-obvious constraints — read these before writing code

- **`config/countries.yml` has only 40 countries, and DE / FR / BR are not among them.**
  Available ids include `US CA GB MX JP PH ZA AU AR TH`. Seeding with an id that isn't in
  the file means `Data::Country.find(id)` returns `nil` and the flag helper blows up. Pick
  the seed list from ids that actually exist.
- **Ransack 4 denies everything by default.** `PlayerStat.ransackable_attributes` must be
  overridden or every filter silently does nothing. `ransortable_attributes` defaults to
  `ransackable_attributes`, so one method covers both filtering and sorting.
- **`PlayerStat` is a readonly Scenic view with `self.primary_key = "user_id"`.** Ransack
  works on it like any AR model, but `row.id` returns the *user* id — existing specs rely
  on that.
- **Never edit a migrated `_vNN.sql`.** Run `rails g scenic:view player_stats` to get v02
  plus a migration; the generated migration should carry `revert_to_version: 1`.
- **Adding `users.country` to the view requires adding it to `GROUP BY`** — the query
  aggregates over `users.id, users.name`, and Postgres will reject an ungrouped column.
- **`turbo_search_form_for` exists in ransack 4.4 but is the wrong tool here.** It submits
  `POST` turbo-streams. We want a plain `GET` into a frame — use `search_form_for` with
  `html: { data: { turbo_frame: "leaderboard_results" } }`.
- **The sort buttons are outside the frame, so the server never re-renders their active
  state after a filter change.** They must therefore be *inside the `<form>` element*
  (a form can wrap both the header and the filter row) and the Stimulus controller moves
  the `btn--active` class client-side. See §5.
- **`stylesheet_link_tag :app` auto-includes new CSS files** — no manifest, no import. Any
  new filter styling goes in `app/assets/stylesheets/components/lobby/leaderboard.css`
  alongside the existing block.
- **Components spend roles, never raw ramp steps, and never `color-mix()`.** The existing
  leaderboard CSS uses `--gp-surface-raised`, `--gp-color-muted`, `--gp-color-border-on-raised`,
  `--gp-color-accent`. Match it.
- **Do not run `rails db:seed` against the test DB.** See AGENTS.md.

---

## 3. The work

### 3.1 ✅ `player_stats_v02` — country in the view

```sh
rails g scenic:view player_stats
```

`db/views/player_stats_v02.sql` — copy v01 and add the one column:

```sql
SELECT
  users.id AS user_id,
  users.name,
  users.country,
  COUNT(games.id) AS games_played,
  ...
GROUP BY users.id, users.name, users.country
```

Migration:

```ruby
class UpdatePlayerStatsToVersion2 < ActiveRecord::Migration[8.1]
  def change
    update_view :player_stats, version: 2, revert_to_version: 1
  end
end
```

### 3.2 ✅ `PlayerStat` — the ransack allowlist

```ruby
class PlayerStat < ApplicationRecord
  RANSACKABLE = %w[name country games_played games_won win_percentage play_seconds].freeze

  self.primary_key = "user_id"
  belongs_to :user

  def self.ransackable_attributes(_auth_object = nil) = RANSACKABLE
  def self.ransackable_associations(_auth_object = nil) = []

  def readonly? = true
end
```

`user_id` is deliberately absent — nothing should filter or sort by it.

### 3.3 ✅ `Leaderboard` — ransack replaces `SORTS`

The `SORTS` hash, `DEFAULT_SORT` string keys, and the win-percent floor all go. What
replaces them:

```ruby
class Leaderboard
  WIN_PERCENT_MINIMUM_GAMES = 5
  DEFAULT_SORT = "games_won desc"
  TIE_BREAKERS = [ "games_played desc", "name asc" ].freeze
  PER_PAGE = 25

  attr_reader :query, :page

  def initialize(params: nil, page: nil)
    @query = PlayerStat.where(games_played: 1..).ransack(params)
    @query.sorts = sorts_with_tie_breakers
    @page = page
  end

  def rows = query.result.page(page).per(PER_PAGE)

  private

  def sorts_with_tie_breakers
    primary = query.sorts.first&.then { "#{it.name} #{it.dir}" } || DEFAULT_SORT
    [ primary, *TIE_BREAKERS ].uniq { |sort| sort.split.first }
  end
end
```

Notes for the implementer:

- `.where(games_played: 1..)` **before** `.ransack` is what makes the base scope
  un-bypassable; `query.result` carries it through.
- `.uniq { |sort| sort.split.first }` stops `games_played desc` appearing twice when the
  user sorts by games played.
- An unrecognized sort attribute is dropped by ransack's allowlist rather than raising, so
  the "falls back to default without raising" behavior survives for free — but keep a spec
  on it, because that's now ransack's promise rather than ours.
- `WIN_PERCENT_MINIMUM_GAMES` stays as a constant here only because the *view* needs it
  (the button link and the note). It no longer appears in the query.

### 3.4 ✅ `LeaderboardPresenter`

Changes:

- `initialize(params:, page:, current_user:)` — takes the whole `params[:q]` hash.
- `def query = @leaderboard.query` — the search object the form binds to.
- `SORT_BUTTONS` gains a `sort:` value per button and drops the `key:` indirection where it
  can't. Each entry needs: the `q[s]` string, the label, the icon, and (for Win %) the
  min-games it presets.

  ```ruby
  SORT_BUTTONS = [
    { sort: "games_won desc",      label: "Wins",            icon: "trophy" },
    { sort: "games_played desc",   label: "Games Played",    icon: "cards" },
    { sort: "win_percentage desc", label: "Win Percentage",  icon: "percent",
      minimum_games: Leaderboard::WIN_PERCENT_MINIMUM_GAMES },
    { sort: "play_seconds desc",   label: "Time Played",     icon: "timer" }
  ].freeze
  ```

- `sorted_by?(button)` compares against `query.sorts.first`, not a param string.
- `win_percent_note` fires when the primary sort is `win_percentage` — same copy.
- `empty_message` gains a third case: **filtered to nothing**. "No player matches those
  filters." is different from "nobody has played yet," and with three filters live the
  filtered-empty case is the common one. Decide between them on whether any filter is
  present (`query.conditions.any?`).
- `entries` is unchanged in shape; `build_entry` gains `country: row.country`.

### 3.5 ✅ `LeaderboardEntry` — the flag

```ruby
def initialize(..., country:, ...)
  @country = Data::Country.find(country) if country.present?
end

def flag = @country&.flag
```

`Data::Country.find` returns `nil` for an unknown id, so a stale or hand-typed country on a
user degrades to no flag rather than an exception. The view renders
`= entry.flag` before the name; blank for players with no country.

### 3.6 ✅ `LeaderboardController`

Stays one line:

```ruby
@presenter = LeaderboardPresenter.new(params: params[:q], page: params[:page], current_user: current_user)
```

Do **not** `permit` the `q` hash — ransack's allowlist is the authorization boundary, and
`ransack` accepts an `ActionController::Parameters` only if permitted, so pass
`params[:q]&.permit!` or `params.fetch(:q, {}).permit!` and let `ransackable_attributes`
do the filtering. Whichever form you choose, add a request spec proving that
`q[user_id_eq]` and `q[s]=user_id desc` are ignored.

### 3.7 ✅ The view

`app/views/leaderboard/index.html.slim`, restructured:

```
.leaderboard
  = search_form_for @presenter.query, url: leaderboard_index_path, method: :get,
      html: { class: "leaderboard__controls",
              data: { controller: "leaderboard-filters",
                      turbo_frame: "leaderboard_results",
                      leaderboard_filters_target: "form" } } do |f|

    .leaderboard__header
      h1.leaderboard__title Leaderboard
      .leaderboard__sorts
        - @presenter.sort_buttons.each do |button|
          button[type=button] ...   / see §5 for the data attributes

    = f.hidden_field :s, data: { leaderboard_filters_target: "sort" }

    .leaderboard__filters
      = f.search_field :name_i_cont, placeholder: "Search players",
          data: { action: "input->leaderboard-filters#debouncedSubmit" }
      = f.select :country_eq, Data::Country.all.map { [ it.name, it.id ] },
          { include_blank: "All countries" },
          data: { action: "change->leaderboard-filters#submit" }
      = f.number_field :games_played_gteq, min: 1, placeholder: "Min games",
          data: { action: "change->leaderboard-filters#submit",
                  leaderboard_filters_target: "minimumGames" }

  - if @presenter.win_percent_note
    p.leaderboard__note = @presenter.win_percent_note

  = turbo_frame_tag "leaderboard_results", data: { turbo_action: "advance" } do
    - if @presenter.empty?
      p.leaderboard__empty = @presenter.empty_message
    - else
      table.leaderboard__table
        ...
              td
                - if entry.flag
                  span.leaderboard__flag = entry.flag
                = entry.name
        ...
      = paginate @presenter.rows
```

Two things worth calling out:

- **`data-turbo-action="advance"` on the frame** is what keeps the URL in sync as filters,
  sorts, and pages change — without it the board is unbookmarkable and a refresh throws
  the filters away. Kaminari's `paginate` already carries the current query params, so
  pagination keeps the filters once the URL is right.
- The `win_percent_note` sits **outside** the frame, next to the controls it explains. It's
  driven by the sort, which the frame doesn't own.

### 3.8 ✅ Seeding

In `db/seeds.rb`, in the bulk-insert block (which already has a deterministic
`Random.new(20260728)`):

```ruby
# Weighted so US dominates and the eq filter has one obviously-populous option to
# demonstrate against. Every id here must exist in config/countries.yml.
SEED_COUNTRIES = %w[US US US US CA GB MX JP PH ZA AU].freeze

user_rows = Array.new(1_000) do |n|
  { email_address: "player#{n + 1}@example.com", name: "Player #{n + 1}",
    country: SEED_COUNTRIES.sample(random: random),
    password_digest: digest, **timestamps }
end
```

Give `me` and `opponent` countries too (`create(:user, ..., country: "US")`) so the signed-in
user's own row carries a flag.

Order matters: `SEED_COUNTRIES.sample(random: random)` consumes draws from the same
generator the games use, so every downstream number shifts. That's fine — the seed is
deterministic, not stable across edits — but don't be surprised when the load-test board
looks different.

### 3.9 ✅ CSS

Add to `components/lobby/leaderboard.css`, inside the existing `.leaderboard` block:

- `.leaderboard__controls` — wraps header + filters; the header's existing centering moves
  under it unchanged.
- `.leaderboard__filters` — `display: flex; flex-wrap: wrap; justify-content: center;
  gap: var(--gp-space-medium);` mirroring `.leaderboard__sorts`.
- `.leaderboard__flag` — a right margin (`var(--gp-space-small)`), nothing more.
- Inputs: reuse whatever Optics form styling the profile edit form already gets. If the
  fields land unstyled inside a bare `search_form_for`, style them here rather than
  reaching for Optics classes in the markup.

---

## 4. What this deletes

Delete rather than deprecate:

- `Leaderboard::SORTS` and the string sort keys (`"wins"`, `"games"`, `"win_percent"`,
  `"time"`).
- `Leaderboard#qualifying`'s win-percent branch and `#win_percent_sort?`.
- `LeaderboardPresenter#sort` and `#sorted_by?(key)` in their current string-key form.
- The `sort:` query param. Nothing links to it after this change; an old bookmark
  degrades to the default sort, which is acceptable.

---

## 5. The Stimulus controller

`app/javascript/controllers/leaderboard_filters_controller.js`, registered in
`controllers/index.js` via `bin/rails stimulus:manifest:update`.

Targets: `form`, `sort` (the hidden `q[s]` field), `minimumGames`.

Behavior:

1. **`submit()`** — `this.formTarget.requestSubmit()`. Bound to `change` on the country
   select and the min-games field.
2. **`debouncedSubmit()`** — same, after ~300ms of no typing. Clear the pending timer on
   each keystroke and in `disconnect()`.
3. **`sort(event)`** — reads the clicked button's `data-leaderboard-filters-sort-param`,
   writes it into `sortTarget.value`, moves `btn--active` from the previously active button
   to this one, and submits. If the button carries a `minimum-games-param`, it also raises
   `minimumGamesTarget.value` to that number when the current value is lower — that's the
   Win % floor, now visible and overridable.

The sort buttons are `<button type="button">` inside the form. They must **not** be
`type="submit"` — a submit button's `name`/`value` would work natively, but then clicking
one wouldn't update the active styling, and the header never re-renders because it lives
outside the frame.

Server-side the hidden `q[s]` carries only the *primary* sort; `Leaderboard` appends the
tie-breakers. Don't try to round-trip three sorts through the form.

---

## 6. Specs

Write these failing first, in this order.

**`spec/models/leaderboard_spec.rb`** — the biggest rewrite. `Leaderboard.new(sort: "wins")`
becomes `Leaderboard.new(params: { s: "games_won desc" })`. Keep every existing measure
and pagination example; replace the sorting block's keys; **delete** the "win percentage
floor" context — that behavior moved to the button. Add:

- `given a country filter` → `it "returns only that country's players"` (`country_eq`)
- `given a minimum-games filter` → `it "excludes a player below the threshold"` (`games_played_gteq`)
- `given a partial name in a different case` → `it "matches the player"` (`name_i_cont`)
- `given a filter that would surface a never-played user` → `it "still excludes them"`
  (prove the base scope survives `games_played_gteq: 0`)
- `given a sort on an unallowlisted attribute` → `it "falls back to the default"`

**`spec/models/player_stat_spec.rb`** (new, small) — `it "reports the user's country"`,
plus `it "does not allow filtering by user_id"` locking the allowlist.

**`spec/presenters/leaderboard_presenter_spec.rb`** — `#query` returns a `Ransack::Search`;
`sorted_by?` tracks the primary sort; the filtered-empty message differs from the
never-played message.

**`spec/presenters/leaderboard_entry_spec.rb`** — flag for a known country, `nil` for a
blank one, `nil` for an unrecognized id.

**`spec/requests/leaderboard_spec.rb`** — one example per predicate hitting the real URL
(`get leaderboard_index_path(q: { country_eq: "US" })` etc.), plus the two authorization
examples from §3.6. Keep the existing unauthenticated-redirect example.

**`spec/system/leaderboard_spec.rb`** — this is the only place the JS wiring is provable, so
it gains `:js`. Per AGENTS.md keep it coarse: **one** example that types a partial name into
the search field and asserts the other player's row disappears from the frame. The existing
sort-button example stays (it exercises the same Stimulus path). Nothing else belongs here —
the predicates are already proven at the request layer.

**Factory** — add a `country` trait or just pass `country:` inline; `spec/factories/users.rb`
has no country today and doesn't need a default.

Then `bin/rubocop`.

---

## 7. Verifying it looks right

Per AGENTS.md, use a screenshot system spec, not the Chrome extension:

```ruby
page.driver.with_playwright_page { |p| p.emulate_media(colorScheme: "dark") }
screenshot("leaderboard-filtered", fullPage: true)
```

Drive it to the interesting state — a country selected, a min-games value, a few rows with
flags — then Read the PNG. Delete the spec afterward if it was only scaffolding to look at.

---

## 8. Docs to update when done

- **`docs/architecture.md`** — if it names the `sort=` param anywhere, update it.
- **`AGENTS.md`** — one line under "Conventions worth knowing" is warranted: ransack is now
  the filtering/sorting idiom, and every ransackable model must declare its allowlist.
