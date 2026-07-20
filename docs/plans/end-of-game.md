# Plan: End-of-Game System

## Purpose & how to use this doc

This plan describes the **target behavior** for what happens when a game
finishes. The failing specs listed under [Acceptance criteria](#acceptance-criteria)
already exist and encode this behavior — **your job is to make them green** while
keeping the architecture clean. This doc explains the *intent* behind those specs
so you can implement with judgment, not just pattern-match assertions.

Read [docs/architecture.md](../architecture.md) first for the two-layer `Game`
model, the jsonb `state` round-trip, and the turn/broadcast cycle.

---

## Current state (what's broken today)

- **Go Fish never finishes.** `GoFish::Game#play_turn` computes and returns the
  winner (`app/models/go_fish/game.rb`), but `GoFishGame#play_turn`
  (`app/models/games/go_fish_game.rb`) **throws the return value away** — it only
  calls `save!`. So Go Fish games never set `finished_at`, never mark a winning
  `Participant`, stay `status == "started"` forever, and contribute nothing to
  stats. This is the **keystone bug** — most of this plan depends on fixing it.
  Crazy Eights already does this correctly via `end_game(winner)`
  (`app/models/games/crazy_eights_game.rb`) — mirror that.
- **The end screen is a dead end.** The Go Fish overlay
  (`app/views/go_fish_games/_go_fish_game.html.slim`) shows `"<name> wins!"` and a
  "Restart Game" button that POSTs to `/reset` — **a route that does not exist**
  (404). This overlay is being replaced by the modal below.
- **`win_percentage` returns `NaN`** for a user with zero finished games
  (`app/models/user.rb` — divides by `games_played`).

### How each game decides a winner (do not change these rules)

- **Crazy Eights:** the moment the active player empties their hand, they win.
  Single winner, no ties.
- **Go Fish:** the game ends when every player is out of cards; the winner has the
  **most books** (`decide_winner` in `app/models/go_fish/game.rb`).

---

## Target behavior (the ideal end result)

### The end-of-game modal

When a game finishes, **every player sees a modal** on their game page:

- A prominent **"You win" / "You lose"** message near the top, framed *per user*
  (the winner sees "You win"; everyone else sees "You lose" and the winner named).
- A **scoreboard** listing every player with their result:
  - Go Fish → **number of books**
  - Crazy Eights → **number of cards remaining**
  - The winning player is visibly marked.
- **Three next actions**, with "Return to main page" as the primary/highlighted
  button and the other two as secondary options:
  | Label | Destination |
  |---|---|
  | **Return to main page** (primary) | `root_path` |
  | **View stats** | `stats_path` |
  | **Create a new game** | `new_game_path` |

Build this the same way for both games (shared modal, per-game scoreboard data),
and **render it through the presenter** — never the model directly (project norm).

### The modal is a view of persisted state (refresh durability)

The modal must **not** be a one-time broadcast artifact. It is a function of
`game.finished?`:

- The **live** end: the game-ending turn broadcasts the modal to each player.
- A **refresh / fresh load**: `games#show` renders the *same* modal from persisted
  state whenever the game is finished.

Same partial, two delivery paths, identical result. Refreshing a finished game
re-shows the modal; loading an in-progress game shows no modal.

### Turn-blocking is server-authoritative (three layers)

A finished game must reject any turn, even from a stale background tab. Defense in
depth, only the first layer is trustworthy:

1. **Server rejection (the real defense).** `TurnsController#check_user_turn`
   already rejects turns unless `status == "started"`. This starts working for Go
   Fish *for free* the moment the keystone fix sets `finished_at`.
2. **UI correction (convenience).** The end-of-game broadcast should remove/disable
   the turn form on every board so players don't try.
3. **Graceful rejection (UX).** When a stale tab does submit a turn to a finished
   game, respond by **rendering the end-of-game modal** (Turbo Stream) instead of
   the current raw `{"errors":[]}` JSON — correcting that tab into the end screen.

---

## Work items

Grouped by layer. Each maps to specs under [Acceptance criteria](#acceptance-criteria).

1. **Fix the keystone (`GoFishGame#play_turn`).** Capture the winner returned by
   the PORO and mark the winning `Participant` + set `finished_at`, mirroring
   Crazy Eights' `end_game`. Consider extracting the shared completion logic to the
   STI base (`app/models/game.rb`) so both games handle the winner uniformly and
   this class of drift can't recur.
2. **Guard `User#win_percentage`** against zero finished games — return `0`, never
   `NaN`.
3. **Presenter end-of-game contract** (both `GoFishGamePresenter` and
   `CrazyEightsGamePresenter`). The specs define this contract:
   - `#finished?` → Boolean (Crazy Eights has it; add to Go Fish).
   - `#won?` → Boolean — is the viewing user the winner?
   - `#winner` → `User` (already exists).
   - `#scoreboard` → Array of entries, winner-first; each entry responds to
     `#name`, `#score` (Go Fish: books, Crazy Eights: cards remaining), and
     `#winner?`.

   *This shape is a reasonable default, not a mandate — you may reshape the
   presenter API if you have a cleaner design, as long as the rendered behavior the
   request/system specs assert (button labels, "You win" text) still holds.*
4. **The modal partial**, gated on `finished?`, rendered per-user through the
   presenter. Replace the broken Go Fish overlay + `/reset` form.
5. **`games#show` renders the modal** for a finished game (durability on refresh).
6. **`TurnsController`**: on a turn to a finished game, render the modal via Turbo
   Stream instead of raw JSON.
7. **`BroadcastGameJob` / `GameTurboUpdate`**: the end-of-game broadcast delivers
   the modal and disables the turn form. (Fan-out per user already works and is
   spec'd — don't regress the per-user streaming that keeps hands hidden.)

---

## Acceptance criteria

These spec files already exist and encode the behavior above. Success = they pass
(without weakening the assertions).

| Spec | Covers |
|---|---|
| `spec/models/games/go_fish_game_spec.rb` | Keystone: Go Fish marks winner, sets `finished_at`, reports `finished` |
| `spec/models/user_spec.rb` (`stats`) | `games_played`, `games_won`, and `win_percentage` never `NaN` |
| `spec/presenters/go_fish_game_presenter_spec.rb` | `finished?` / `won?` / `winner` / `scoreboard` for Go Fish |
| `spec/presenters/crazy_eights_game_presenter_spec.rb` | same contract for Crazy Eights |
| `spec/requests/games_spec.rb` | Finished game renders the modal (+ actions, "You win"); in-progress does not |
| `spec/requests/turns_spec.rb` | Finished game rejects turns; responds with the modal, not JSON |
| `spec/jobs/broadcast_game_job_spec.rb` | Per-user broadcast fan-out (already green — keep it) |
| `spec/system/end_of_game_spec.rb` | The modal + its three actions in a real browser |

Spec conventions in this repo (see `AGENTS.md`): Given/When/Then maps to
`describe` / `context` / `it`; keep `it` blocks ~7 lines; use FactoryBot. Request
specs authenticate via `sign_in(user)` (`spec/support/request_auth_helpers.rb`).

---

## Out of scope / deferred

Do **not** build these now; they were explicitly deferred:

- **Ties.** Both games are treated as always having a single winner. No tie-break
  behavior or tests this round.
- **Draw / stalemate** (Crazy Eights running out of playable cards). A real
  "no winner" outcome is a future decision — for now assume a winner always exists.
- **Abandonment** (a player leaving mid-game — forfeit vs. void). Undecided policy;
  left for later.
- **Concurrency locking** (`lock_version` / `with_lock` around a turn to prevent
  last-write-wins on the `state` blob). A known reliability gap, but separate from
  this feature. Don't let it block the end-of-game work.

## The live opponent-push system test

`spec/system/end_of_game_spec.rb` has one `skip`ped example: the modal appearing
**live** on a waiting player's screen when the opponent makes the winning move.
Implementing it needs a two-session `:js` driver plus the working broadcast. Wire
it up once the broadcast (work item 7) is in place, or leave it skipped with a note
if out of time — the durability path (refresh) is covered without it.
