# Feature: Extract shared `CardGame::Player` base

## Feature summary

`GoFish::Player` and `CrazyEights::Player` duplicate their spine (includes, accessors, `initialize`, `serializes`, `receive`). A new `CardGame::Player` base absorbs the shared spine, following the `CardGame::Deck < CardGame::Pile` shape already in the codebase. `process_card` stays abstract (`raise NotImplementedError`) in the base since the two subclasses genuinely diverge there. Along the way, `GoFish::Player#out_of_cards?` (currently `player.empty?`, an undefined-local bug that would raise `NameError` if ever called) gets replaced by the correct base implementation (`cards.empty?`).

This is a refactor with no intended behavior change, except the `out_of_cards?` fix — so most confidence comes from re-running existing specs green, plus new specs for the previously-untested `out_of_cards?` path and the new base class itself.

## Test coverage

### `spec/models/card_game/player_spec.rb` (new file)

#### #initialize
- [ ] sets the player's name
- [ ] starts with no cards and no messages

#### #out_of_cards?
- [ ] is true when the player has no cards
- [ ] is false when the player holds cards

### `spec/models/crazy_eights/player_spec.rb` (new file — none exists today)

#### #remove
- [ ] removes the given card from the hand

#### #receive
- [ ] adds the given cards to the hand

### `spec/models/go_fish/player_spec.rb` (modify existing)

#### #out_of_cards? (new — Prove-It: reproduces the `NameError` bug first)
- [ ] is true when the player has no cards
- [ ] is false when the player holds cards

(Existing `#take` and `#receive` examples stay as-is — no behavior change expected there.)

## Related specs (regression check)

- `spec/models/card_game/deck_spec.rb`, `spec/models/card_game/pile_spec.rb` — sanity that the sibling `Pile`/`Deck` inheritance pattern is undisturbed
- `spec/support/shared_examples/platform_game.rb`, exercised via `spec/models/go_fish/game_spec.rb` and `spec/models/crazy_eights/game_spec.rb` — confirms dealing, turns, and win conditions still work through the new `Player` base
- Full `bundle exec rspec` before calling this done, per the plan's own checklist
