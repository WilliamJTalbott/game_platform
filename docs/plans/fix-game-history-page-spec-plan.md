# Feature: Fix the game history page

## Feature summary

`/history` shows a user the finished games *they* participated in: game name (linked), duration, and winner name. Today it's broken two ways: the winner cell renders the literal string "game winner" instead of calling anything, and the controller loads `Game.all` (every game platform-wide, any status, unscoped). The fix is per-user + finished-only scoping on `Game`, a narrow `HistoryPresenter` for the three display fields, and wiring the controller/view to both.

Out of scope (per the breakdown): no draw/no-winner handling (games always have exactly one winner), no empty-state messaging, no deleted-user-record safety in the winner lookup, `deleted_at` does not factor into the scope at all.

## Test coverage

### `spec/models/game_spec.rb` (modify existing)

#### `.finished`
- [x] includes a game with both `started_at` and `finished_at` present
- [x] excludes a waiting game (`started_at` nil)
- [x] excludes a started-but-not-finished game (`finished_at` nil)
- [x] includes a finished game that has since been soft-deleted (`deleted_at` present)

#### `.for_user`
- [x] includes a finished game the given user participated in
- [x] excludes a finished game the given user did not participate in

#### `.finished` ordering
- [x] orders most-recently-finished first

### `spec/presenters/history_presenter_spec.rb` (new file)

#### `#name`
- [x] returns the game's name

#### `#duration`
- [x] returns the game's duration

#### `#winner`
- [x] returns the name of the participant marked `winner: true`

### `spec/requests/history_spec.rb` (new file)

#### `GET /history`
- [x] shows only the current user's finished games
- [x] does not show another user's finished game
- [x] does not show a game that hasn't finished yet
- [x] shows the correct winner name for each game
- [x] still shows a finished game that has since been soft-deleted

## Related specs (regression check)

- `spec/system/history_spec.rb` — existing smoke test ("shows the history page"); must keep passing
- `spec/presenters/game_presenter_spec.rb` — `winner` logic being mirrored into `HistoryPresenter`; make sure nothing there regresses
