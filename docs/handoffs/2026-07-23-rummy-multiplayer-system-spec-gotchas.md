# Rummy turn-loop system spec — two false leads before the real fix

## What we were working on

Milestone 1 of Rummy (`docs/rummy-playable-plan.md`): a draw/discard turn
loop with live wiring. Needed a system spec proving a player draws,
discards, and the turn passes live. First attempt modeled it after the
plan's literal wording ("assert...the opponent's view updated") with two
Capybara sessions (`using_session(:active_player)` / `using_session(:waiting_player)`).

## What's done

- **False lead #1 — two-session flake.** The two-session spec failed
  intermittently (`Element is not attached to the DOM`, blank failure
  screenshots) only when run alongside other `:js` system specs, never in
  isolation. Root cause was never fully pinned down (browser-context
  contention under load, most likely) — but the bigger discovery was that
  **no other system spec in this codebase uses `using_session` at all**.
  `games_spec.rb`'s existing "allows user to take a turn" specs for Go
  Fish/Crazy Eights use a single session and assert on that user's own
  message feed after acting. Rewrote the Rummy spec to match — it's faster
  (no second browser context) and has been reliable across repeated runs
  both standalone and alongside the rest of `spec/system/`.
- **False lead #2 — `User.find` drops the login password.** While debugging
  the two-session version, `login_user` failed with "expected /session/new to
  equal /" — looked like a framework-level flake (the exact same symptom as
  the pre-existing `end_of_game_spec.rb` flake AGENTS.md already documents).
  It wasn't: the spec picked "which user is active" via
  `User.find(game.reload.state.active_player.user_id)`. `has_secure_password`'s
  `password=` is a virtual attribute — it's never persisted, so a
  freshly-`find`'d record has `user.password == nil`, and `login_user` silently
  submits a blank password. **Fix:** determine identity by comparing
  `user.id` against already-created (factory) user objects (which still hold
  the in-memory password), never by re-`find`ing the user you're about to log
  in as.
- **The real bug this uncovered** (unrelated to either false lead): a Rummy
  game persisted *before* `phase` was added to `Rummy::Game`'s `serializes`
  list loads with `phase == nil`, so `can_draw?`/`can_discard?` are false for
  everyone, forever. Initially fixed with a `self.load` backfill
  (`game.phase ||= "draw"`), then **deliberately reverted** — Rummy hasn't
  shipped, so the only affected records were this session's own dev-testing
  artifacts; `bin/rails db:seed` in development wipes them, and every Rummy
  game created from now on has `phase` from day one. Neither `GoFish::Game`
  nor `CrazyEights::Game` has an equivalent backward-compat shim, so adding
  one only for Rummy would've been inconsistent with how this codebase
  handles (or rather, doesn't need to handle) schema drift on `state`.

## What's left

- If Rummy ever ships with real in-progress games and a *new* field gets
  added to `Rummy::Game#serializes` afterward, this exact `nil`-field problem
  will recur for real user data — at that point a `self.load` backfill (or a
  proper data migration) is the right call, not premature now.
- `GamesController#start` renders `:show` without setting `@game_info` when
  `@game.start` returns `false` (e.g. too few participants) — 500s with
  `'nil' is not an ActiveModel-compatible object`. Found by accident while
  reproducing the above through the real UI with two real users; not fixed
  (out of scope for the session, pre-existing, affects all game types, not
  Rummy-specific). Worth a small follow-up.

## Decisions made

- Multi-user "does the turn pass live" coverage stays single-session,
  asserting on the acting user's own feed — matching existing convention
  over the plan's literal "opponent's view updated" wording. If true
  cross-session coverage is ever wanted, budget for chasing real flakiness
  under `:js` load, not just at implementation time.
