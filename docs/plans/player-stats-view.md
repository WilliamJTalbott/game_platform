# One Source of Truth for Player Stats

**Goal: there is exactly one definition of "games played, games won, win percentage,
time played" in this app — a versioned SQL view — and every page that shows those
numbers reads it from the same place.**

Scenic is the tool, not the point. The point is that today those four numbers are
computed **twice**, by two unrelated implementations that already disagree with each
other, and neither one can be reused by the next page that needs them. A database view
makes the aggregation a *schema object*: named, versioned in git, and queryable with
ordinary Arel instead of heredoc SQL strings.

Status legend: 🟡 planned · 🟢 in progress · ✅ done

---

## 1. The problem, concretely

| Where | How it computes stats | Queries |
|---|---|---|
| `app/models/leaderboard.rb` | One `User.joins(participants: :game)` + `GROUP BY` with a hand-written 6-line `select_list` heredoc, ordered by four raw `ORDER BY` strings | 1 |
| `app/models/user.rb:14-21` | `games_played`, `games_won`, `win_percentage` as three independent AR methods | 3–4 per render |

`app/views/stats/index.html.slim` renders the second set straight off `@user`.

**They disagree.** `User#games_played` filters to finished games
(`where.not(finished_at: nil)`); `User#games_won` does not — it counts every
`participants.winner` row regardless of game state. `Leaderboard` filters both. Two
things that claim to be the same stat, computed differently.

Secondary problems this fixes:

- `Leaderboard::SORTS` is four raw SQL strings passed through `Arel.sql` — because
  `games_won` and `win_percentage` aren't columns, they're expressions in a `SELECT`
  list, so they can't be ordered by name.
- The win-% floor is a conditional `.having("COUNT(games.id) >= 5")` string appended
  to the scope after the fact.
- `/stats` renders a model directly into a template, against the project's
  always-render-through-a-presenter rule (AGENTS.md).

---

## 2. Decisions

The three marked **✅ yours** you already answered. The rest are recommendations I'll
implement unless you say otherwise.

| Question | Decision |
|---|---|
| Plain or materialized view? | **✅ yours — plain.** Re-computed per query, always fresh, no refresh job, no spec changes for staleness. Materialized is the perf play; premature at this volume |
| Leaderboard-only or shared? | **✅ yours — shared.** One view serves both `/leaderboard` and `/stats` |
| Inner or left join? | **✅ yours — left.** One row per user, always. Zero-game users get `games_played = 0` so `/stats` always finds its row; `Leaderboard` restores its exclusion with an explicit `games_played > 0` |
| View name | **`player_stats`** → model `PlayerStat`. Not `leaderboard_rows` — the leaderboard is one consumer, not the owner |
| Primary key | `self.primary_key = "user_id"`. One row per user; `user_id` is the natural key |
| Include `users.name` in the view? | **Yes.** It's a view, so the name is always live — no staleness risk. Saves a join for the leaderboard's only other needed column. Also add `belongs_to :user` for anything else |
| Read-only? | **Yes, explicitly** — `def readonly? = true`. Postgres won't auto-update an aggregate view anyway; the method makes the failure a clear Ruby error instead of a PG one |
| Where does the win-% floor live? | **Ruby.** `where(games_played: MINIMUM..)` in `Leaderboard`. It's application policy, not schema — and now it's a normal `where` on a real column instead of a `HAVING` string |
| Keep `Leaderboard` as a PORO? | **Yes.** It shrinks to "validate the sort param, order, apply the floor". That's a real job and it keeps sort policy out of the model |
| `User`'s three methods | **Delete.** Every caller moves to `PlayerStat`. Leaving them as delegators just preserves the ambiguity we're removing |
| How does `User` reach its stats? | **`has_one :player_stat`, and no delegating methods.** Split by grain: single-user reads (`/stats`) go through the association — one query, N+1 impossible; set reads (`/leaderboard`) query `PlayerStat` directly, so ordering stays `order(games_won: :desc)` instead of a join plus a raw order string. Delegators would re-hide the aggregate behind something that reads as cheap as `user.email_address`, which is precisely how the current duplication happened |
| `dependent:` on that `has_one`? | **No — and it must not be added.** You can't delete a row from a view, so `dependent: :destroy` raises on user deletion. It's also pointless: the view has no storage, so a user's row vanishes when the user does |
| `/stats` presenter | **Add `StatsPresenter`.** Required by the shared-view decision anyway — something has to fetch the row |
| Soft-deleted games | **Keep counting them.** Current `Leaderboard` doesn't filter `deleted_at` and `spec/models/leaderboard_spec.rb:57-65` locks that in. The view SQL will not filter it either |
| Schema format | **Stays `schema.rb`.** Scenic prepends `Scenic::SchemaDumper`, so `create_view "player_stats", sql_definition: <<-SQL` lands in `schema.rb` and `db:schema:load` / `db:test:prepare` recreate it. No switch to `structure.sql` |

**Out of scope:** the four unwired filter buttons on the stats page ("Big Numbers",
"Wins", "Strategy", …), any visual change to either page, materialized views, and new
stats beyond the four that exist.

**Non-goal:** this is behavior-neutral on `/leaderboard`. Every existing leaderboard
spec must pass unchanged. `/stats` changes in exactly one way — `games_won` starts
filtering to finished games, matching what the leaderboard already did.

---

## 3. The view

`db/views/player_stats_v01.sql`:

```sql
SELECT
  users.id AS user_id,
  users.name,
  COUNT(games.id) AS games_played,
  COUNT(games.id) FILTER (WHERE participants.winner) AS games_won,
  COALESCE(ROUND(COUNT(games.id) FILTER (WHERE participants.winner) * 100.0
    / NULLIF(COUNT(games.id), 0), 1), 0.0) AS win_percentage,
  COALESCE(SUM(EXTRACT(EPOCH FROM (games.finished_at - games.started_at))), 0)::bigint AS play_seconds
FROM users
LEFT JOIN participants ON participants.user_id = users.id
LEFT JOIN games ON games.id = participants.game_id
  AND games.started_at IS NOT NULL
  AND games.finished_at IS NOT NULL
GROUP BY users.id, users.name
```

Three things in there are load-bearing and easy to get wrong:

1. **The finished-game filter is in the `ON` clause, not `WHERE`.** In a `WHERE` it
   would discard the null rows the `LEFT JOIN` just produced, silently turning the
   whole thing back into an inner join — the exact bug the left-join decision exists
   to avoid.

2. **`NULLIF` guards division by zero.** With an inner join, `COUNT(games.id)` was never
   0. With a left join it is, for every user who's never finished a game, and `x / 0`
   raises in Postgres. `NULLIF(COUNT(games.id), 0)` makes the denominator `NULL`, the
   division yields `NULL`, and `COALESCE` catches it as `0.0` — matching what
   `User#win_percentage` already returned (`spec/models/user_spec.rb:51-53` asserts
   "never NaN").

3. **Every count is `COUNT(games.id)`, never `COUNT(*)`.** `COUNT(*)` counts *rows*;
   `COUNT(games.id)` counts *non-null game ids*. Under a left join those differ, and the
   difference is a bug in both directions. It's why `games_played` reads `0` rather than
   `1` for a zero-game user. And in the filtered count it's load-bearing: a participant
   flagged `winner` on an unfinished game still produces a row whose game columns are
   `NULL`, so `COUNT(*) FILTER (WHERE participants.winner)` would report a win with
   `games_played = 0` — the two columns contradicting each other. Verified against
   Postgres with a synthetic row before the fix: `games_played: 0, games_won: 1`. The
   symmetric pair (same expression, one filtered) also reads as the same population,
   which is the point.

A note on what gets clearer. Committed `HEAD` expresses the finished-game filter as two
separate calls:

```ruby
.where.not(games: { started_at: nil }).where.not(games: { finished_at: nil })
# => WHERE started_at IS NOT NULL AND finished_at IS NOT NULL
```

Collapsing those into one multi-key `where.not` — which reads as an obvious tidy-up —
silently changes the meaning:

```ruby
.where.not(games: { started_at: nil, finished_at: nil })
# => WHERE NOT (started_at IS NULL AND finished_at IS NULL)
```

That's NAND, not NOR, and it's satisfied by a game that has started but not finished, so
in-progress games get counted as played. This actually happened on this branch and
`spec/models/leaderboard_spec.rb`'s "still in progress / excludes them" example caught
it. The view's `IS NOT NULL AND IS NOT NULL` has no such second reading — that's the
real argument for moving this into SQL.

---

## 4. Steps

### 0 · Clear the stray scaffold ✅

`db/migrate/20260728123817_create_search_results.rb` calls
`create_view :search_results`, but `db/views/` is empty — its `_v01.sql` was deleted.
That migration **fails on the next `db:migrate`**. Delete it (and
`app/models/search_result.rb` + generated specs if present). Nothing has run it, so
there's no `schema_migrations` row to clean up — confirm with
`bin/rails db:migrate:status`.

### 1 · Generate the view and model ✅

```sh
bin/rails generate scenic:model player_stat
```

Creates `db/views/player_stats_v01.sql`, `app/models/player_stat.rb`, and a
`create_view :player_stats` migration. Fill in the SQL from §3, add `primary_key`,
`belongs_to :user`, and `readonly?` to the model, and add `has_one :player_stat` to
`User` (no `dependent:`), then `bin/rails db:migrate`.

Validate the SQL with `EXPLAIN` before migrating — it parses and plans without
executing, so a bad column name surfaces while v01 is still editable. Check the plan
kept the games filter *inside* the join rather than above it; that's the proof the outer
join didn't silently degrade to an inner one.

Spec: `spec/models/player_stat_spec.rb` — the four columns for a user with one won
2-hour game, the zero-row case (`games_played == 0`, `win_percentage == 0.0`),
multi-game summing, in-progress games excluded, soft-deleted games still counted, and
`user.player_stat` resolving through the association. Reuse
`spec/models/leaderboard_spec.rb`'s `finished_game_for` factory helper.

**Column types to expect:** `win_percentage` comes back as `BigDecimal` (Postgres
`numeric`), `play_seconds` as `Integer` (explicit `::bigint`), counts as `Integer`.
`LeaderboardEntry` already handles both (`format("%.1f%%", ...)` and
`play_seconds.to_i`), so nothing downstream changes.

### 2 · Rewire `Leaderboard` ✅

`base_scope` and `select_list` are deleted. `SORTS` stops being SQL strings:

```ruby
SORTS = {
  "wins"        => { games_won: :desc, games_played: :desc, name: :asc },
  "games"       => { games_played: :desc, games_won: :desc, name: :asc },
  "win_percent" => { win_percentage: :desc, games_played: :desc, name: :asc },
  "time"        => { play_seconds: :desc, games_played: :desc, name: :asc }
}.freeze

def rows
  scope = PlayerStat.where(games_played: 1..).order(SORTS.fetch(sort))
  win_percent_sort? ? scope.where(games_played: MINIMUM_GAMES_FOR_WIN_PERCENTAGE..) : scope
end
```

No `Arel.sql`, no heredoc, no `HAVING`. `where(games_played: 1..)` is the exclusion the
inner join used to give implicitly.

Then `LeaderboardPresenter#build_entry` changes `row.id` → `row.user_id` for the `you?`
comparison. **Existing leaderboard specs must pass untouched** — that's the regression
proof for this step.

### 3 · Rewire `/stats` ✅

Add `StatsPresenter` (reads the current user's row via `user.player_stat`, formats the
three displayed values), point `StatsController#index` at it, and change the template to
read from the presenter. `spec/system/stats_spec.rb` should pass unchanged; add
`spec/presenters/stats_presenter_spec.rb` for the numbers, including the brand-new-user
zero case — the exact scenario the left join exists for.

The `play_time` formatting logic in `LeaderboardEntry` is worth reusing rather than
duplicating if the stats page ends up showing time played; it currently doesn't, so
leave it alone for now.

### 4 · Retire `User`'s stat methods ✅

Delete `games_played`, `games_won`, `win_percentage` from `app/models/user.rb` and the
three examples covering them in `spec/models/user_spec.rb:41-53` (their behavior now
lives in `spec/models/player_stat_spec.rb`). `grep -rn "games_played\|games_won\|win_percentage" app spec`
should show only `PlayerStat`, `Leaderboard`, and the presenters.

### 5 · Verify ✅

`bundle exec rspec` green, then `bin/rubocop`. Also `bin/rails db:test:prepare` from
scratch, to prove the view survives a `schema.rb` load rather than only existing
because migrations happened to run locally.

---

## 5. Gotchas

- **Views can't be changed in place.** To alter the definition later, run
  `bin/rails generate scenic:view player_stats` again — it writes `_v02.sql` (seeded
  with v01's contents) and an `update_view ... revert_to_version: 1` migration. Never
  edit `_v01.sql` after it's been migrated; that's the versioning discipline the gem
  exists to enforce.
- **`schema.rb` will carry the SQL inline.** Expect a `create_view "player_stats",
  sql_definition: <<-SQL` block in the diff. That's correct and belongs in the commit.
- **Migration ordering.** The `create_view` migration must sort *after* the tables it
  reads. It will, since it's newest — but if it's ever rolled back and replayed out of
  order, Postgres will refuse to create a view over a missing table.
- **No index on a plain view.** You can't add one. If `/leaderboard` ever gets slow,
  the fix is either indexes on the *underlying* tables (`participants(user_id)` and
  `games(finished_at)` both already exist) or the materialized-view conversation we
  deferred.
- **`readonly?` is belt-and-suspenders.** Postgres auto-updates only *simple* views; an
  aggregate view like this one is not updatable, so a write would fail anyway. The
  method just makes it fail as `ActiveRecord::ReadOnlyRecord` with a clear message.

---

## 6. What "done" looks like

- `db/views/player_stats_v01.sql` is the only place those four numbers are defined.
- `app/models/leaderboard.rb` contains no SQL — just a sort whitelist and two `where`s.
- `app/models/user.rb` computes no stats — it has `has_one :player_stat` and nothing else.
- `/leaderboard` behaves identically; `/stats` shows the same numbers with `games_won`
  now correctly scoped to finished games, rendered through a presenter.
- Full suite green, `bin/rubocop` clean, `db:test:prepare` from scratch works.
