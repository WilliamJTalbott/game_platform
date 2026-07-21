# BRAVE Breakdown: Extract a shared `CardGame::Game` base for the two rules engines

## Brainstorm
`GoFish::Game` and `CrazyEights::Game` duplicate a large, load-bearing spine: the `SMALL_HAND`/`LARGE_HAND`/`MIN_PLAYERS_SMALL_HAND` constants, `active_player`, `hand_amount`, and a **byte-identical** `self.dump`/`self.load` (including the `results = []` reset — the single most-warned-about footgun in `docs/serialization.md`). A new `CardGame::Game` superclass should own that shared spine so `GoFish::Game`/`CrazyEights::Game` only contain their genuine rule differences.

Scope clarifications from this conversation (not fully spelled out in the card):
- **`serializes` for `players:`/`discard:` stays on each subclass**, not the base. `players: [ Player ]` resolves to a different class per module (`GoFish::Player` vs `CrazyEights::Player`), so it can't be lifted verbatim even though the line is textually identical — only `turn_index`/`deck` move to the base's own `serializes` call, relying on `Serializable`'s schema-inheritance merge for the rest.
- **`deal` stays duplicated in both subclasses.** It's not true duplication — Crazy Eights' `deal` is "deal hands, then establish the discard pile," a game-specific setup sequence that only coincidentally shares two lines with Go Fish's simpler "deal hands." Forcing a hook/helper into the base to save four lines isn't worth the seam. Instead, `CardGame::Game#deal` is declared as an explicit abstract method (`raise NotImplementedError`) so the base documents that every subclass must implement it, without the base providing (or subclasses inheriting/`super`-calling) any shared implementation.
- No extra spec coverage beyond what already exists — the shared `platform_game` contract spec plus both games' unit specs are considered sufficient to catch a jsonb round-trip regression.

## Approach
Copy `GoFish::Game` (the simpler of the two) into a new `app/models/card_game/game.rb` and strip it down to just the shared spine, rather than building the base up from an empty file:

1. Create `CardGame::Game` from a copy of `GoFish::Game`, then delete everything that isn't shared: keep the three constants, `active_player`, `hand_amount`, `self.dump`/`self.load`, and `include Serializable` with `serializes :turn_index, deck: CardGame::Deck`. Replace `deal` with `def deal = raise NotImplementedError`.
2. Re-derive `GoFish::Game < CardGame::Game`, removing everything now inherited and keeping only `play_turn`, win detection, `switch_turn`, and its own `serializes players: [ Player ]` line.
3. Re-derive `CrazyEights::Game < CardGame::Game`, keeping `play_turn`, `wins?`, discard handling, its own `deal`, and its own `serializes players: [ Player ], discard: Discard` line.

Mid-way check: both `spec/models/go_fish/game_spec.rb` and `spec/models/crazy_eights/game_spec.rb`, plus the shared `platform_game` contract spec, stay green after each of the three steps above — not just at the end.

Error/recovery: no behavior change is in scope, so the only real failure mode is a silent jsonb round-trip regression (the `results = []` reset footgun). The existing spec suites are the guard rail; no new spec is being added specifically for this.

## Value
Internal-quality work, not user-facing — the payoff is reducing the "read it twice and diff" burden for future contributors (per the card's own why), and making debugging easier since the abstract `deal` on the base now signals explicitly what a new `CardGame::Game` subclass is expected to implement. Not sprint-critical; optimize for **quality** — this is a refactor with no behavior change, so correctness and clarity matter more than speed.

## Estimate
**4 points (Small, ~4 hours)**, including the 15% review/pairing buffer (too small a card to scale the buffer further).

- **Biggest risk:** low likelihood, but real severity if it slipped — a jsonb round-trip regression in `dump`/`load` could silently corrupt saved game state. Mitigated by keeping both spec suites green after every incremental step rather than only at the end.
- **Incremental shipping:** not needed as a separate concern — since the approach is copy → strip → verify in discrete steps, the safe fallback if time ran short is simply to stop at any step where both spec suites are green.
- **Dependencies/sequencing:** pairs naturally with Card 3 (`CardGame::Player` base) since both extractions live in the same `CardGame::` layer, but per the improvement-cards doc there's no hard dependency — either order works, and this card ships independently.

## Implementation Plan
- [ ] Copy `GoFish::Game` to `app/models/card_game/game.rb`, strip to the shared spine (constants, `active_player`, `hand_amount`, `self.dump`/`self.load`, `serializes :turn_index, deck: CardGame::Deck`)
- [ ] Replace `CardGame::Game#deal` with an explicit `raise NotImplementedError`
- [ ] Re-derive `GoFish::Game < CardGame::Game`, removing inherited members, keeping its own `serializes players: [ Player ]`
- [ ] Run `spec/models/go_fish/game_spec.rb` + the shared `platform_game` contract spec — confirm green
- [ ] Re-derive `CrazyEights::Game < CardGame::Game`, removing inherited members, keeping its own `deal`, `serializes players: [ Player ], discard: Discard`
- [ ] Run `spec/models/crazy_eights/game_spec.rb` + the shared `platform_game` contract spec — confirm green
- [ ] Update `docs/serialization.md`/`docs/architecture.md`'s "adding a game type" section to describe the new base and the abstract `deal`
