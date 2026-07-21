# Serialization: the `Serializable` concern

See **[docs/architecture.md](docs/architecture.md)** first for *why* POROs need
`as_json`/`self.load` at all (the `state` jsonb bridge and the turn cycle). This
doc is about the *mechanism* that generates those methods: `app/models/concerns/serializable.rb`.

## The problem it solves

Every PORO in the game-logic layer used to hand-write matching `as_json` and
`self.load` methods. That's a trap: add a field to one and forget the other, and
the field silently vanishes the next time the object round-trips through the
`state` jsonb column — nothing fails loudly, because the in-memory object during
the request that added the field is still fine. The bug only shows up on the
*next* load.

`Serializable` closes that gap by generating both methods from **one schema**, so
a field can't exist in one without the other.

## Usage

```ruby
class GoFish::Player
  include Serializable

  serializes :user_id, :name, cards: [ CardGame::Card ], books: [ GoFish::Book ], messages: [ CardGame::Message ]
end
```

- Bare symbols (`:user_id`, `:name`) are scalars, stored and restored as-is.
- `attr: SomeClass` is a **single nested object** — `SomeClass` must itself
  `include Serializable` (or otherwise respond to `.load`/`#as_json`).
- `attr: [ SomeClass ]` (array literal) is an **array of nested objects**.

This generates:
- `#as_json` — walks the schema, calling `#as_json` on any nested value(s).
- `.load(hash)` — returns `nil` if `hash` is blank; otherwise builds an instance
  and assigns every declared attribute from the hash, recursively `.load`-ing
  nested values.

A subclass with no `serializes` call of its own inherits its parent's schema
(used by `CrazyEights::Deck < CardGame::Pile`, etc.) — see `serialized_scalars`/
`serialized_nested` in the concern for how that inheritance is resolved.

## Gotchas

- **`.load` uses `allocate`, not `new`.** It deliberately bypasses `initialize`
  so the same mechanism works whether a class's constructor takes required
  positional args (`CardGame::Card.new(rank, suit)`) or none. The consequence:
  **any ivar set by `initialize` but not listed in `serializes` comes back `nil`
  after a reload, not its `initialize` default.** `GoFish::Game`/`CrazyEights::Game`
  both hit this for `results` (the ephemeral per-turn narration list, never
  persisted) and carry a thin override to compensate:
  ```ruby
  def self.load(hash)
    super&.tap { |game| game.results = [] }
  end
  ```
  If you add a new non-persisted, initialize-only field to a class that includes
  `Serializable`, you need the same kind of override — or add the field to
  `serializes` if it *should* persist.
- **A missing array key defaults to `[]`, not an error** — `Array(nil) == []`
  falls out of the array-handling code path for free.
- **A missing/`nil` singular nested key loads as `nil`**, not an error — but a
  method that expects a non-nil nested object (e.g. `Discard#valid_play?` calling
  `active_card.rank`) will still blow up if you call it before that object is
  ever set. `Serializable` guarantees the *load* doesn't crash; it doesn't
  guarantee every caller is nil-safe.
- **Thin hand-written overrides are fine and expected** on top of `Serializable`
  when a class has genuine post-processing to do — see `CardGame::Message.load`
  (casts `type` back to a symbol) and `CrazyEights::Discard.load`/`#as_json`
  (merges in `active_card`, which isn't a plain scalar/nested-array shape). These
  call `super` for the mechanical part and add only the extra bit by hand — they
  are not a reversion to the old fully-hand-rolled pattern.

## What still needs care

The AR bridge itself (`serialize :state, coder: GoFish::Game`) expects the coder
to respond to `.dump(obj)` and `.load(hash)`. `Serializable` only generates
`.load`; each top-level `*::Game` PORO still defines its own one-line `self.dump`:

```ruby
def self.dump(obj)
  obj.as_json
end
```

That's not duplication to eliminate — it's the one place the Active Record
`serialize` coder protocol and this concern's `.load`/`#as_json` protocol meet.
