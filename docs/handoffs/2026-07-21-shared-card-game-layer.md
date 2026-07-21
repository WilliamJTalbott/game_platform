# Shared CardGame:: layer + game-type registry

## What we were working on

Implementing `docs/plans/improvement-plan.md` step by step: making "adding a new
game" a safe, additive change. Three items in that plan:

1. Test the shared spine (contract spec + round-trip guard)
2. Extract a shared `CardGame::` PORO layer
3. A game-type registry so adding a game doesn't touch shared controllers/views

## What's done

**Item 1** was already complete before this session (contract spec, round-trip
guard, presenter specs — see the plan doc for details).

**Item 3 — game-type registry**: `Game.playable`/`.from_type`/`.label`/
`.permitted_turn_params` (`app/models/game.rb`), consumed by
`app/views/games/new.html.slim`, `GamesController#create`
(`app/controllers/games_controller.rb`), and `TurnsController#game_params`
(`app/controllers/turns_controller.rb`). Fixed the unguarded `constantize` and a
dead `:game_type` strong param along the way.

**Item 2 — shared `CardGame::` layer** (all tiers except the intentionally
deferred one):
- `Serializable` concern (`app/models/concerns/serializable.rb`) — declarative
  `serializes` schema generates `as_json`/`self.load`, supports scalar/nested/
  array-of-nested fields and class inheritance (a subclass with no schema of its
  own inherits the parent's).
- `Messageable` concern (`app/models/concerns/messageable.rb`) — the
  `add_normal/action/alert_message` trio, now shared instead of duplicated.
- `CardGame::Card`, `CardGame::Message`, `CardGame::Pile`, `CardGame::Deck`
  (`app/models/card_game/`) replace the per-namespace `GoFish::`/`CrazyEights::`
  versions. `wild?`/`WILD_RANK` moved off `Card` onto `CrazyEights::Discard`
  (it's a rule, not a card property).
- `GoFish::Book`, `GoFish::Player`, `CrazyEights::Player`, `GoFish::Game`,
  `CrazyEights::Game` all now `include Serializable` instead of hand-rolling
  `as_json`/`self.load`.
- Tier 3 (unifying `Player` beyond the two mixins, or unifying the `Game` rules
  classes) is **intentionally deferred** per the plan — do not do this until a
  real third game exists.

Full suite green across multiple random seeds, rubocop clean, at each commit.

## What's left

The plan's **Bonus — correctness smells** section (cheap, independent, not yet
touched):

1. `GoFish::Player#out_of_cards?` (`app/models/go_fish/player.rb`) references an
   undefined local `player` — currently dead/broken code. Fix to `cards.empty?`
   (matches `CrazyEights::Player#out_of_cards?`).
2. `Game#start` (`app/models/game.rb`) uses `save` (not `save!`), and `Game#finish`
   doesn't persist at all — inconsistent persistence contract that relies on the
   caller remembering to save afterward. Needs a decision on making both explicit
   (likely `save!` in both, or `finish` calling `save!` itself).
3. `BroadcastGameJob#perform_now` is called synchronously in the request path
   (see call sites of `BroadcastGameJob`), which defeats the purpose of it being a
   job. Needs a decision: broadcast inline and delete the job, or switch the call
   site to `perform_later`.

None of these block anything else — pick any one independently.

## Decisions made

- **Recommended order was Item 3 then Item 2** (from the plan) — followed as-is;
  they have no shared surface so this was a preference, not a dependency.
- **`Serializable.load` uses `allocate`, not `new`** — bypasses `initialize`
  entirely so it works uniformly across classes with required positional args
  (`Card`) and attr-reader-only value objects. Consequence: any ivar set by
  `initialize` but not part of the `serializes` schema (e.g. `Game#results`, the
  ephemeral per-turn narration list) comes back `nil` after a reload, not its
  `initialize` default. Both `GoFish::Game.load` and `CrazyEights::Game.load`
  carry a thin override (`super&.tap { |game| game.results = [] }`) to compensate
  — don't remove it without checking `results` is otherwise repopulated.
- **`GoFish::TurnResult#as_json` was deleted, not converted to `Serializable`** —
  it was dead code: never part of `Game#as_json` (turn results aren't persisted),
  never tested, and `CrazyEights::TurnResult` never had an equivalent method at
  all.
- **Found and fixed a real bug while unifying `Deck`**: Go Fish's deck had a
  guaranteed-reorder `shuffle` (retries until the order differs); Crazy Eights'
  did a plain `cards.shuffle`. Unifying to the Go Fish version caused an infinite
  loop, because Crazy Eights calls `shuffle` on a deck that can have 0 or 1 cards
  (after recycling the discard pile), and a 1-card array can never "reorder."
  Fixed with a `return if cards.size <= 1` guard in `CardGame::Deck#shuffle`, with
  a regression spec in `spec/models/card_game/deck_spec.rb`.
- **Several spec files were missing `require 'rails_helper'`** (silently relying
  on load order in a full suite run) — added it where found; this surfaced only
  because a spec file was run in isolation during debugging.
