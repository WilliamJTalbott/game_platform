# BRAVE Breakdown: Fix the game history page

## Brainstorm
`/history` is meant to show a user the finished games *they* participated in, with basic end-result info (winner, duration) and a link back into the game — useful for digging up a past game's final score. Two confirmed bugs block that today:

- `app/views/history/_game.html.slim:4` renders the literal string `"game winner"` instead of calling anything — every row shows identical, wrong text.
- `HistoryController#index` is unscoped `Game.all` — it returns every game on the platform (waiting, other users', soft-deleted) with no ordering and no eager loading.

Scope clarifications from this conversation (not fully spelled out in the card):
- History is **per-user** — only games the current user participated in, not all finished games platform-wide.
- Games always end with exactly one winner today — no draw/no-winner state to defend against.
- Soft-delete (`deleted_at`) is a cron-driven cleanup for *inactive* games, not a "hide from history" flag — a finished game that later gets soft-deleted should **still** show in history. So `deleted_at` doesn't factor into the history scope at all; the `finished` + "belongs to this user" filter is the whole gate.
- Empty history (no finished games yet) just renders an empty table — no special empty-state messaging.
- Deleted-user-record safety in the winner lookup is explicitly out of scope for this card.

## Approach
Bottom-up, following the existing `Game`/`GamePresenter`/`ApplicationController` patterns already in the codebase:

1. **Scope on `Game`** — add a `finished` scope (mirroring the existing `status` logic: `started_at` and `finished_at` both present) plus a per-user filter (via the `users`/`participants` association), ordered most-recent-first, with `includes` on `participants: :user` to kill the N+1 on winner lookup.
2. **New `HistoryPresenter`** — narrow, separate from `GamePresenter` (which requires a `user` + builds a `form_class.new(game: game.state)` — unnecessary machinery for a read-only history row). Exposes just `name`, `duration`, and `winner` (the winner's name), reusing the same `participants.find_by(winner: true)&.user` logic `GamePresenter#winner` already has.
3. **Wire up** `HistoryController#index` to the new scope, and swap `history/_game.html.slim`'s `td game winner` for the presenter's `winner`.

Order of work: scope → presenter → controller/view wiring — each step TDD'd (spec-first) before moving to the next, per the project's TDD-first convention.

Mid-way check: the scope spec (unit-level, no DB round-trip surprises) proves the query is correct before the presenter or view touch it at all — if the scope's wrong, nothing downstream can be right either.

Error/recovery: no finished games → empty table (default Rails behavior, no extra handling needed). No other error states are in scope for this card.

## Value
This is a **visibly broken page every user of the app hits** — not a minor internal cleanup, a real user-facing defect (wrong winner text, wrong games listed). Optimize for **quality within scope**: worth doing cleanly (a proper scope + a purpose-built presenter) rather than a minimal patch, but the card's own boundaries (no deleted-user handling, no empty-state design) keep it tightly scoped rather than gold-plated.

## Estimate
**2 points (X-Small, <2 hours)**, including the 15% review/pairing buffer (too small a card to bump the T-shirt size).

- **Biggest risk:** low. Self-contained page fix; the audit explicitly calls Card 1 independent of Cards 2/3 (the `CardGame::` extraction), so no sequencing conflict with the rest of the round.
- **Incremental shipping:** not needed — small enough to land as one slice.
- **Dependencies:** none.

## Implementation Plan
- [x] Write a spec for `Game.finished` (and the per-user filter/ordering/eager-load) — TDD, scope-first
- [x] Implement the `finished` scope (+ per-user scope, ordering, `includes(participants: :user)`) on `Game`
- [x] Write a spec for the new `HistoryPresenter` (`name`, `duration`, `winner`)
- [x] Implement `HistoryPresenter`
- [x] Wire `HistoryController#index` to the scope + presenter, filtered to `current_user`
- [x] Update `history/_game.html.slim` to render the presenter's `winner` instead of the literal-text bug
- [x] Write/confirm a request spec for `/history` covering: only finished, only this user's games, correct winner shown, soft-deleted-but-finished games still appear
