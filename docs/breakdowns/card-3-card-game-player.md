# BRAVE Breakdown: Extract a shared `CardGame::Player` base (and delete the dead, broken method)

## Brainstorm
`GoFish::Player` and `CrazyEights::Player` duplicate their spine — `include Serializable`/`Messageable`, the `attr_accessor`s for `user_id`/`cards`/`name`/`messages`, `initialize`, and the `receive` public method. That duplication has already produced a real bug: `GoFish::Player#out_of_cards?` calls an undefined local `player` (`player.empty?`) and would raise `NameError` if ever invoked — it has zero callers today (confirmed via grep across `app/` and `spec/`), while `CrazyEights::Player#out_of_cards?` (`cards.empty?`) is correct.

`process_card` is the one place the two aren't identical: Crazy Eights' version is just "append the card," Go Fish's also checks for a completed book. Resolved: rather than have the base implement a default and have Go Fish call `super` plus extra logic, the base leaves `process_card` unimplemented/abstract and each subclass provides its own full implementation. Simpler, no ordering coupling between base and subclass behavior.

Confirmed the `Serializable` schema-inheritance mechanism (`docs/serialization.md`, `app/models/concerns/serializable.rb`) supports this cleanly: `serialized_scalars`/`serialized_nested` are memoized per-class via `inherited_serialized`, which dups the superclass's collection as the starting point. So the base declares `serializes :user_id, :name, cards: [CardGame::Card], messages: [CardGame::Message]`, and `GoFish::Player` layers `serializes books: [Book]` on top rather than replacing it — same mechanism already proven by `CrazyEights::Deck < CardGame::Pile`.

## Approach
Follow the `CardGame::Deck < CardGame::Pile` shape already in the codebase: thin subclass, `super` in `initialize` only where needed, private/unique methods stay local to the subclass that needs them.

- New `app/models/card_game/player.rb`: `include Serializable`, `include Messageable`, shared `attr_accessor`s, `initialize`, shared `serializes` fields, `receive`, correct `out_of_cards?` (`cards.empty?`), abstract `process_card`.
- `GoFish::Player < CardGame::Player` keeps: `books` accessor, `serializes books: [Book]`, `remove_cards`, `take`, `cards_of_rank`, `unique_cards`, `book_count`, `highest_book`, `make_book`, `completed_book?`, and its own `process_card`. Deletes the broken `out_of_cards?` entirely.
- `CrazyEights::Player < CardGame::Player` keeps: `remove`, its own `process_card`. Deletes its now-redundant (but correct) `out_of_cards?` in favor of the promoted base version.

**Spike order:** build `card_game/player.rb`, swap `CrazyEights::Player` over first (it's the simpler of the two — no extra state, no override quirks), run `spec/models/crazy_eights/player_spec.rb` (and the platform contract spec) to confirm green before touching Go Fish. Then swap Go Fish, delete the broken method, rerun both player specs plus the shared platform contract spec.

**Verified before starting:** grepped `out_of_cards?` across `app/` and `spec/` — only the two definitions exist, zero callers. Safe to delete outright, no shim needed.

## Value
Primarily a **locality** win: the next person adding a third game studies one `Player` shape instead of reading two nearly-identical classes and diffing them by eye. Secondarily removes a landmine (`NameError`-on-call dead code), though that's not urgent since nothing calls it today. Not sprint-critical — it's groundwork alongside Card 2's `CardGame::Game` extraction, not a fix for an active problem. Optimizing for **quality** on this one: get the shape right and specs airtight, since this is the reference other game authors will read.

## Estimate
**4 points / Small (~half day)**, plus the standard 15% review/pairing buffer (~4.5 hours all-in). Small and well-bounded: one new file, two subclasses trimmed to their genuine differences, one dead method deleted, existing specs already cover the behavior.

**Risks:**
- Low: `serializes` schema layering order — already verified against the concern's `inherited_serialized` mechanism, matches an existing proven pattern (`CrazyEights::Deck < CardGame::Pile`).
- Low: hidden callers of the broken `out_of_cards?` — grepped and confirmed zero.
- Low: `process_card` divergence — resolved by leaving it abstract in the base, no `super` coupling to get wrong.

**Sequencing:** independent of Card 2 (`CardGame::Game` extraction) — sibling extractions, either order works, no blocking dependency.

**Incremental shipping:** the spike order itself is the incremental path — Crazy Eights swap can land and stay green on its own if Go Fish's swap needs more time.

## Implementation Plan
- [ ] Create `app/models/card_game/player.rb` with shared spine: includes, `attr_accessor`s, `initialize`, `serializes` (shared fields), `receive`, correct `out_of_cards?`, abstract `process_card`
- [ ] Swap `CrazyEights::Player` to subclass `CardGame::Player`; strip duplicated spine, keep `remove` and `process_card`; run its spec + platform contract spec
- [ ] Swap `GoFish::Player` to subclass `CardGame::Player`; strip duplicated spine, add `serializes books: [Book]`, keep GF-specific methods and its own `process_card`
- [ ] Delete `GoFish::Player`'s broken `out_of_cards?`; delete `CrazyEights::Player`'s now-redundant `out_of_cards?` (promoted to base)
- [ ] Run `spec/models/go_fish/player_spec.rb`, `spec/models/crazy_eights/`, and `spec/support/shared_examples/platform_game.rb` — confirm all green, no behavior change
- [ ] Update `docs/serialization.md` / `docs/architecture.md` if the "adding a game type" guidance references the old per-game `Player` duplication
