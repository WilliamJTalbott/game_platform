# Feature: Extract a shared `CardGame::Game` base for `GoFish::Game` / `CrazyEights::Game`

## Feature summary

Pure refactor, no behavior change. `GoFish::Game` and `CrazyEights::Game` currently duplicate a load-bearing spine: the `SMALL_HAND`/`LARGE_HAND`/`MIN_PLAYERS_SMALL_HAND` constants, `active_player`, `hand_amount`, and a byte-identical `self.dump`/`self.load` (including the `results = []` reset). This extracts that spine into a new `CardGame::Game` superclass. `deal` is declared abstract (`raise NotImplementedError`) on the base and stays fully duplicated in both subclasses since it's genuinely different setup logic per game.

Per the breakdown, no new spec coverage is being added — the existing suites already exercise every piece of shared behavior, and the risk being guarded against (a silent jsonb round-trip regression in `dump`/`load`) is exactly what they'd catch. The "test coverage" here is a checklist of existing specs to keep green after each incremental step, not new tests to write.

## Test coverage (existing specs, run after each step — no new tests)

### Step 1 — `CardGame::Game` created (base only, not yet wired to a subclass)
- [ ] No spec targets this directly; nothing should be affected yet since no subclass points at it.

### Step 2 — `GoFish::Game` re-derived from `CardGame::Game`
- [ ] `spec/models/go_fish/game_spec.rb` — all examples green (deal, play_turn, matches, go-fish, winner detection, turn switching)
- [ ] shared `platform_game` contract spec (via `spec/models/games/go_fish_game_spec.rb` or wherever `it_behaves_like "a platform game"` is declared for Go Fish) — start deals+persists, play_turn survives reload (jsonb round-trip), winner stamps `finished_at`

### Step 3 — `CrazyEights::Game` re-derived from `CardGame::Game`
- [ ] `spec/models/crazy_eights/game_spec.rb` — all examples green (deal incl. discard pile setup, play_turn, wins?, deck replenish, turn switching)
- [ ] shared `platform_game` contract spec for Crazy Eights — same jsonb round-trip guarantee

### Final — full regression sweep
- [ ] `spec/models/card_game/*` (card_spec, deck_spec, pile_spec) — untouched, but confirm still green since `CardGame::Deck` is now referenced from the new base
- [ ] `bundle exec rspec` (full suite) — nothing else touches these classes, but this is cheap insurance for a shared-base change

## Related specs (regression check)

- `spec/models/go_fish/player_spec.rb`, `spec/models/go_fish/book_spec.rb`, `spec/models/go_fish/turn_result_spec.rb` — unaffected (no changes to `Player`/`Book`/`TurnResult`), but part of the full-suite sweep
- `spec/models/crazy_eights/discard_spec.rb`, `spec/models/crazy_eights/turn_result_spec.rb` — same
- `docs/serialization.md`, `docs/architecture.md` — need their "adding a game type" sections updated to describe `CardGame::Game` and the abstract `deal`, per the breakdown's last checklist item (docs, not specs)
