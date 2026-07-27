# Leaderboard

**Goal: give the platform a public standing — one page where every player who has
finished a game can see where they rank against everyone else, and re-rank the room by
whichever measure they care about.**

Stats today is a private mirror: it tells you *your* numbers and nothing about whether
they're any good. The leaderboard is the social half of that — the same four measures,
every player at once, sortable, with your own row findable at a glance.

Status legend: 🟡 planned · 🟢 in progress · ✅ done

---

## 1. Decisions already made

Settled in conversation — do not re-litigate these while implementing:

| Question | Decision |
|---|---|
| Placement | New top-level page + sidebar link, alongside Stats / History / Rules |
| Pagination | **None.** Explicitly deferred; render every qualifying row |
| Total time played | `SUM(finished_at - started_at)` over the user's **finished** games. No new column |
| Sorting | **Server-side**, whitelisted `?sort=` param, `ORDER BY` in SQL |
| Direction | **Descending only.** No toggle, no direction param |
| Roster | Only users with **≥ 1 finished game** |
| Query shape | **One grouped aggregate query.** No N+1; existing `User#games_played` etc. untouched |
| Layout | Table with a **rank column**; sort buttons in a row above it |
| Own row | Subtle highlight via a BEM modifier |
| Win % floor | **5 finished games.** Under the win-% sort, users below the floor are **excluded from the view**; they reappear under the other three sorts |
| Time format | Compact human units — `14h 07m`, `07m 12s` under an hour. A **new** formatter; `Game#duration` stays `HH:MM:SS` |

Out of scope (later): pagination, per-game-type filtering, ascending toggle, date ranges,
live Turbo updates when a game ends.

---

## 2. What already exists — reuse, don't rebuild

- **`ScoreboardEntry`** (`app/presenters/scoreboard_entry.rb`) is the exact precedent for
  the row presenter: `attr_reader :name, :score, :rank` plus a `you?` predicate. Mirror
  its shape for `LeaderboardEntry` — same `rank:` / `you:` vocabulary.
- **`resources :stats, only: [:index]`** / `resources :history, only: [:index]` is the
  routing idiom for these read-only pages. Follow it (`leaderboard_index_path`), even
  though the `_index` suffix is ugly — consistency wins.
- **`app/views/stats/index.html.slim`** already has the visual pattern for a row of
  category buttons above a body (`.stats-page__header` with `.btn.btn--primary.btn--medium`
  + a `ph` icon each). Those buttons are currently **dead** — no links, no behavior. The
  leaderboard's sort buttons are the same shape but real `link_to`s.
- **`app/views/application/_sidebar.html.slim`** — add one `link_to` in
  `.sidebar__content--start`, matching the existing four (`btn btn--no-border` + a
  `ph` icon). Suggested icon: `ranking` or `trophy`.
- **`Game.finished`** scope encodes exactly the right game filter
  (`started_at NOT NULL AND finished_at NOT NULL`, and deliberately **ignores**
  `deleted_at` — a soft-deleted finished game still counts, as
  `spec/requests/history_spec.rb:41` locks in). Reuse the conditions, but see the
  `ORDER BY` gotcha in §5.
- **`participants.winner`** (boolean, `NOT NULL DEFAULT false`) is the win flag, set by
  `Game#end_game`. `COUNT(*) FILTER (WHERE participants.winner)` is the wins measure.

---

## 3. The pieces to build

```
config/routes.rb                                    + resources :leaderboard, only: [:index]
app/controllers/leaderboard_controller.rb           new
app/models/leaderboard.rb                           new — owns the SQL
app/presenters/leaderboard_presenter.rb             new — page: sort state, ranked entries
app/presenters/leaderboard_entry.rb                 new — one row
app/helpers/…                                       + play-time formatter (see §4.4)
app/views/leaderboard/index.html.slim               new
app/assets/stylesheets/components/lobby/leaderboard.css   new
app/views/application/_sidebar.html.slim            + one nav link
```

`app/models/leaderboard.rb` is a PORO (no `< ApplicationRecord`) whose only job is the
aggregate query. It lives in `models/` because that's where this codebase already keeps
non-AR domain objects (`app/models/go_fish/*`, `app/models/card_game/*`); `app/services/`
holds a job-ish collaborator (`GameTurboUpdate`) and is the wrong neighborhood.

---

## 4. Implementation detail

### 4.1 `Leaderboard` — the aggregate query

One grouped query, sorted in SQL. Sketch (Postgres):

```ruby
class Leaderboard
  MINIMUM_GAMES_FOR_WIN_PERCENTAGE = 5

  SORTS = {
    "wins"        => "games_won DESC, games_played DESC, users.name ASC",
    "games"       => "games_played DESC, games_won DESC, users.name ASC",
    "win_percent" => "win_percentage DESC, games_played DESC, users.name ASC",
    "time"        => "play_seconds DESC, games_played DESC, users.name ASC"
  }.freeze

  DEFAULT_SORT = "wins"

  # ...

  def rows
    scope = base_scope.order(Arel.sql(SORTS.fetch(sort)))
    qualified? ? scope.having("COUNT(games.id) >= #{MINIMUM_GAMES_FOR_WIN_PERCENTAGE}") : scope
  end
end
```

The `SELECT` list:

```sql
users.id,
users.name,
COUNT(games.id)                                        AS games_played,
COUNT(*) FILTER (WHERE participants.winner)            AS games_won,
ROUND(COUNT(*) FILTER (WHERE participants.winner) * 100.0 / COUNT(games.id), 1)
                                                       AS win_percentage,
COALESCE(SUM(EXTRACT(EPOCH FROM (games.finished_at - games.started_at))), 0)::bigint
                                                       AS play_seconds
```

built over `User.joins(participants: :game).group("users.id")` with the finished-game
conditions.

Notes that will bite if ignored:

- **No divide-by-zero guard is needed.** The `INNER JOIN` plus the finished-game filter
  means every returned row has `games_played >= 1`. That is *also* what implements the
  "≥ 1 finished game" roster rule — there is no separate filter for it.
- **`ORDER BY` may reference the aliases; `HAVING` may not.** Postgres allows output-column
  names in `ORDER BY` (so `games_won DESC` is fine) but not in `HAVING` — the threshold
  clause must repeat `COUNT(games.id)`, not say `games_played >= 5`.
- **Ties are broken deterministically** — every sort ends in `users.name ASC` so row order
  is stable across requests. Don't drop it.
- **Sanitize the sort, don't interpolate it.** `params[:sort]` selects a *key* in `SORTS`;
  an unknown or missing key falls back to `DEFAULT_SORT`. The SQL fragment is never built
  from user input, which is what makes the `Arel.sql` wrapper honest.
- **The win-% threshold only applies under the win-% sort.** Under the other three sorts
  every user with ≥ 1 finished game appears, including 1-game players.

### 4.2 `LeaderboardPresenter` — the page

Constructed with the requested sort and the current user. Responsibilities:

- Normalize the sort param (unknown → `DEFAULT_SORT`) and expose `sort` + `sorted_by?(key)`.
- Turn `Leaderboard#rows` into `LeaderboardEntry` objects, assigning `rank` by position
  (1-based, in the current sort order) and `you: row.id == current_user.id`.
- Expose the sort buttons as data, not markup: `[{ key:, label:, icon: }]` so the view
  loops instead of repeating four near-identical `link_to`s. Labels: `Wins`,
  `Games Played`, `Win %`, `Time Played`.
- Expose `empty?` and the right empty-state message — there are **two** distinct empty
  states (§4.5).

Rank is positional, not dense: two players tied at 60% get ranks 3 and 4, and the
name tiebreak decides which. That's acceptable and worth not over-engineering.

### 4.3 `LeaderboardEntry` — one row

Mirror `ScoreboardEntry`: keyword-initialized, `attr_reader` for the display values,
`you?` predicate. It holds `rank`, `name`, `games_played`, `games_won`,
`win_percentage`, `play_seconds` and returns display-ready strings for the last two
(`"62.5%"`, `"14h 07m"`).

### 4.4 The play-time formatter

New, and separate from `Game#format_duration` — which is a private stopwatch formatter
for a single game and stays as it is. Rules:

- `>= 1 hour` → `"14h 07m"` (minutes zero-padded to 2)
- `< 1 hour`  → `"07m 12s"`
- `0`         → `"0m"` (not reachable given the join, but define it rather than leave it
  to chance)

Put it wherever it can be unit-tested cheaply — a private method on `LeaderboardEntry` is
fine and keeps the formatting next to its only caller. Don't reach for
`ActiveSupport::Duration#inspect`; its output (`"14 hours and 7 minutes"`) is too long for
a table cell.

### 4.5 Two empty states

1. **Nobody has finished a game.** "No games have finished yet — play one and you'll be
   first on the board."
2. **Win-% sort with nobody past the floor.** Different message, because the board is not
   actually empty: "Win % ranks players with at least 5 finished games. Nobody qualifies
   yet." A short note explaining the 5-game floor should be visible **whenever** the win-%
   sort is active, not only when it empties the table — otherwise players who vanish from
   the list have no explanation.

### 4.6 View + CSS

`app/views/leaderboard/index.html.slim`: a `.leaderboard` block — header (title + the
sort-button row), then a `table.leaderboard__table` with
`Rank | Player | Games | Wins | Win % | Time`, then the empty state.

One new file, `app/assets/stylesheets/components/lobby/leaderboard.css` — Propshaft
picks it up automatically via `stylesheet_link_tag :app`; there is no manifest to edit.
It goes in `lobby/` because that's where the non-game page blocks live (`stats.css`,
`profile.css`, `info_card.css`).

Per DESIGN.md:

- **No page accent.** Stats, history and rules are deliberately unclaimed, and the
  One Page One Color rule says no-accent is a *finished* state — don't invent a
  leaderboard color to complete a pattern.
- **The own-row highlight is a coral job.** Coral is reserved for action, turn, and
  **identity** — "this is you" is precisely identity. A tinted wash
  (`--gp-color-accent-tint` family) or a coral left edge on `.leaderboard__row--you`.
  One signal, not both.
- **Active sort button gets one signal too** — the pressed/active button treatment, not a
  second competing accent.
- All color from `--gp-*` tokens. Referencing `--op-color-*` outside `core/theme.css` is a
  bug.
- Dark is the designed scheme; verify there first.

---

## 5. Traps to avoid

1. **`create(:finished_game)` does not persist `finished_at`.** The factory's
   `after(:create) { game.finish }` calls `Game#finish`, which assigns `finished_at` in
   memory and **never saves**. The DB column stays `NULL`, so an aggregate SQL query sees
   nothing. Every existing spec works around this with an explicit
   `.update!(finished_at: Time.current)` (see `spec/requests/history_spec.rb:9`,
   `spec/models/user_spec.rb:37`). This plan's specs need **both** timestamps set
   explicitly anyway, because duration is `finished_at - started_at` and
   `:started_game` stamps `started_at` with `Time.current`. Consider adding a factory
   trait that takes a duration and sets both — e.g.
   `game.update!(started_at: 2.hours.ago, finished_at: 1.hour.ago)` → exactly `1h 00m` —
   rather than repeating the pair in every example. Do **not** "fix" `Game#finish` to
   save as a side quest; it's called mid-`play_turn` before the subclass's own `save!`.
2. **`Game.finished` carries an `order(finished_at: :desc)`.** Merging the scope drags
   that ordering into a `GROUP BY` query, where `finished_at` is not grouped or aggregated
   → Postgres raises. Either `merge(Game.finished.unscope(:order))` or spell the two
   `where.not` conditions out. Spelling them out is clearer here.
3. **Soft-deleted games still count.** `Game.finished` intentionally ignores
   `deleted_at`, and history has a spec pinning that behavior. Don't add a
   `deleted_at: nil` filter — a finished game is finished.
4. **Concurrent games double-count time.** If a user had two games running at once, both
   durations are summed, so "total time played" can exceed wall-clock time. This is the
   accepted definition; don't try to merge overlapping intervals.
5. **`aggregate.size` vs `.count`.** On a grouped relation, `count` returns a *hash*.
   Guard the empty state on `rows.to_a.empty?` / `.length`, not `.count`.
6. **`n + 1` via `users.name`.** `name` is selected in the aggregate, so the entries must
   read it off the returned row — don't hand `User` records to the presenter and let it
   call `user.games_played` (which would re-query per row and defeat the whole design).
7. **The dead buttons on the Stats page stay dead.** Making them work is a different
   ticket. Copy the *visual* pattern, don't refactor `stats/index`.

---

## 6. Spec plan (TDD — write these first, in this order)

Lowest layer that can prove the behavior, per AGENTS.md.

### `spec/models/leaderboard_spec.rb` — the query (the bulk of the coverage)

- given users with finished games, **when** default sort, **then** rows carry the right
  `games_played`, `games_won`, `win_percentage`, `play_seconds`
- excludes a user with **no** finished game
- excludes a user whose only game is still in progress
- counts a soft-deleted finished game
- `sort=wins` orders by wins descending
- `sort=games` orders by games played descending
- `sort=time` orders by summed duration descending
- `sort=win_percent` orders by percentage descending
- `sort=win_percent` **excludes** a user with fewer than 5 finished games
- `sort=win_percent` **includes** a user with exactly 5
- a user under 5 games **does** appear under `sort=wins`
- an unrecognized `sort` value falls back to the default (and does not raise)
- ties break by games played, then name — deterministic order across two calls
- sums durations across multiple finished games for one user

### `spec/presenters/leaderboard_presenter_spec.rb`

- assigns `rank` 1..n in the current sort order
- marks exactly one entry `you?`
- `sorted_by?` reflects the normalized sort (including for a bogus param)
- exposes the four sort buttons
- reports empty when no user qualifies, with the win-%-specific message under that sort

### `spec/presenters/leaderboard_entry_spec.rb`

- formats a multi-hour total as `"14h 07m"`
- formats a sub-hour total as `"07m 12s"`
- formats a percentage with one decimal place

### `spec/requests/leaderboard_spec.rb`

- requires authentication (unauthenticated → redirect, matching the other pages)
- renders every qualifying player's name
- `?sort=time` renders rows in time order (assert two names' relative position in the body)
- `?sort=win_percent` omits a sub-5-game player's name
- `?sort=nonsense` renders successfully in default order

### `spec/system/leaderboard_spec.rb` — keep to one example

Only the wiring a browser is needed for: **click a sort button, see the order change.**
Everything else above is true with the browser off and does not belong here.

Plus a throwaway screenshot check in dark mode to confirm the table and the own-row
highlight look right (`emulate_media(colorScheme: "dark")` before `screenshot`), deleted
once it has served its purpose.

---

## 7. Order of work

1. ✅ Factory support: a way to create a finished game with a known duration (§5.1).
2. ✅ `Leaderboard` + its spec — all four sorts, the floor, the exclusions.
3. ✅ `LeaderboardEntry` + `LeaderboardPresenter` + specs.
4. ✅ Route, controller, request spec.
5. ✅ View + sidebar link.
6. ✅ `leaderboard.css`, dark-mode screenshot pass.
7. ✅ One system spec for the sort click.
8. ✅ `bin/rubocop`, full `bundle exec rspec`.

---

## 8. Done when

- `/leaderboard` lists every player with ≥ 1 finished game, showing total games, wins,
  win percentage, and total time played.
- Four buttons re-sort the board server-side, descending, with the active one marked and
  the sort visible in the URL.
- The win-% sort shows only players with ≥ 5 finished games, and says so on the page.
- Your own row is findable at a glance.
- The page has no accent color of its own, reads correctly in dark mode, and takes all
  color from `--gp-*` tokens.
- `bundle exec rspec` and `bin/rubocop` are green.
