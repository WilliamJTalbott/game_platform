# Platform Improvement Plan

## The goal (north star)

> **Adding a new game is a safe, additive change** — a handful of new
> game-specific files plus a single registration, where a green contract spec
> proves the new game works and the shared core (and the existing games) cannot be
> broken in the process.

Everything in this plan exists to move one of the dials below. If a proposed change
doesn't serve this goal, it doesn't belong here.

### Definition of done (how we know we hit the goal)
A future game is added and **all** of these hold without extra work:
1. **Additive** — only new game-specific files change, plus **one line** in the
   type registry. No edits to shared controllers or views.
2. **Inherited, not copied** — the new game reuses the shared card primitives and
   writes **zero** hand-rolled `as_json`/`load`.
3. **Provably wired** — one `it_behaves_like "a platform game"` line turns the
   whole platform contract green for the new game.
4. **Safe by construction** — the serialization round-trip is guaranteed by a test,
   not by care; and no code path does anything unsafe with game-type input.

### How each item serves the goal
| Item | Barrier it removes | Definition-of-done it delivers |
|---|---|---|
| **1. Test the shared spine** | No way to prove a new game is wired correctly; the serialization trap is invisible until production. | #3, #4 |
| **2. Shared `CardGame::` layer** | A new game must copy-paste primitives and re-hand-roll serialization. | #2 |
| **3. Game-type registry** | A new game forces edits to shared view + controllers, via unsafe `constantize`. | #1 (and the safety half of #4) |

Status legend: 🟡 planned · 🟢 in progress · ✅ done

---

## Start here (for the implementing session)

**Read first:** `AGENTS.md` (conventions) and `docs/architecture.md` (the two
`Game` layers + the jsonb round-trip). Honor the house style: **~7-line methods**,
**TDD-first** (failing spec before code), **lean specs** (let describe/context/it
convey intent — no comment scaffolding), always render through a **presenter**,
validation in **form objects**.

**Item 1 is done and is your safety net.** Do not redo it. The
`"a platform game"` contract spec (`spec/support/shared_examples/platform_game.rb`)
runs against both games, and its "changes the persisted state" step is the current
round-trip guard. **`bundle exec rspec` must stay green after every change.** If the
contract or a presenter spec goes red during Item 2, stop and fix before continuing
— that red is the net doing its job.

**Working loop per item:** write/adjust specs first → implement → `bundle exec
rspec` green → `bin/rubocop` clean. An item is done when both pass and its
Definition-of-done criterion holds.

**Recommended order: Item 3, then Item 2.** They are independent (no shared
surface), so this is a preference, not a dependency: Item 3 is small, low-risk, and
already has request-spec coverage to extend — a clean way to establish the
green-suite rhythm before the larger Item 2 extraction. Do the Bonus smells
opportunistically (the `save`/`save!` one naturally rides along with Item 2's game
changes).

---

## Item 1 — Test the shared spine ✅ (done)

**Done:** `spec/support/shared_examples/platform_game.rb` (contract run against both
games via per-game `legal_turn`/`winning_turn` lambdas); `game_turbo_update_spec`;
`game_presenter_spec` (base logic once) with the two subclass presenter specs
shrunk to their deltas; `game_spec` trimmed to base-only behavior. The round-trip
guard (planned B) is folded into the contract's "changes the persisted state"
reload step rather than a separate spec. Full suite green (152 examples).

**Serves the goal:** delivers done-criteria **#3 (provably wired)** and **#4
(safe by construction)**. This is the contract and the net — without it, "a new
game works" is a hope, and the extraction in Item 2 has nothing catching it. Do it
first.

### Primary issues
1. **Zero shared example groups exist** (grep-confirmed). No single definition of
   the contract a `Game` subclass must satisfy; a new game has nothing to measure
   against.
2. **`spec/models/game_spec.rb` only ever drives Go Fish.** The `:game` factory
   defaults to `type { "GoFishGame" }`, so the "base `Game`" spec never exercises
   Crazy Eights through `start`/`play_turn`-persistence/`end_game`/`status`/
   `player_from_user`/`user_turn?`. Half the shared behavior is unverified for a
   shipping game.
3. **The jsonb round-trip has no guard** — the #1 trap in AGENTS.md. A desync
   between `as_json` and `load` passes every current test because the in-memory
   object is fine within one request; the bug only appears after a DB reload,
   which no unit spec forces today.
4. **`GameTurboUpdate` has no spec**, despite branching logic (dom_id target,
   presenter build, *conditional* end-of-game-modal broadcast) that both the
   controller and `BroadcastGameJob` depend on. Only reached via slow system specs.
5. **`GamePresenter` base logic is tested only through subclasses** — ranking/
   tie-break/scoreboard is coupled to two games and re-tested per game.

### Approach
- **A. `spec/support/shared_examples/platform_game.rb`** — the STI contract for
  any subclass: `start` deals + persists; `play_turn` mutates **and survives a
  reload**; winning sets winner participant + `finished_at`; `status` transitions;
  `presenter`/`form_class` types. Driven by
  `it_behaves_like "a platform game", :go_fish` / `:crazy_eights`.
  - *Design effort:* `play_turn` needs a legal move per game. Pass a
    "legal-turn-for-this-state" lambda in at each call site so the contract stays
    generic (no `if go_fish` inside the shared example).
- **B. Round-trip stability shared example** — build → deal → `dump/load/dump`,
  assert equal; play a turn, assert again. Run for both games. Generalizes to any
  `Serializable` object once Item 2 lands.
- **C. `spec/services/game_turbo_update_spec.rb`** — `.stream` targets the game
  dom_id with the presenter partial; `.broadcast` broadcasts to `(game, user)` and
  emits the modal **only** when `finished?` (via `have_broadcasted_to`).
- **D. `spec/presenters/game_presenter_spec.rb`** — test base ranking/tie logic
  once against a stub game; shrink the two subclass specs to their
  `score_for`/`score_order`/`score_label` deltas.

### Sequencing
B → A → C → D. B is highest-value and, with A, forms the net that de-risks Item 2;
both must be green **before and after** every Item 2 extraction step.

### Extensibility payoff
The contract + round-trip specs turn "did I wire the new game up right?" into a
green/red signal instead of a manual audit, and make the serialization trap
self-detecting.

---

## Item 2 — Extract a shared card-game PORO layer ✅ (done, Tier 3 deferred)

**Done:** Tiers 1 & 2 of the manifest below — `Serializable`, `Messageable`,
`CardGame::Card`/`Pile`/`Deck`, and `Book`/`Player`/`Game` all wired onto
`Serializable`. See [docs/serialization.md](../serialization.md) for the
resulting mechanism. Tier 3 (unifying `Player` beyond the two mixins, or the
`Game` rules classes) remains **intentionally deferred** until a real third game
exists — see that tier's own section below for why.

**Serves the goal:** delivers done-criteria **#2 (inherited, not copied)**. This is
what makes a new game *small* — it inherits its cards, deck, and serialization
instead of re-authoring them. Done under Item 1's net.

**Design is settled** (namespace `CardGame::`, unify nouns not verbs, `wild?` moves
to the CrazyEights rules, deck unified). The authoritative spec is the
**"Item 2 — decided structure"** and **"implementation manifest"** sections below;
the "Problem" recap here is just the motivation.

**Problem.** The game POROs are copy-paste across namespaces:
- `GoFish::Message` and `CrazyEights::Message` are byte-for-byte identical.
- `Card` classes are ~95% identical (CrazyEights adds `wild?`/`from_s`).
- `Player` classes share identical `add_*_message`, `receive`/`process_card`,
  and near-identical `as_json`/`load`.
- `Deck`s overlap on the standard-52 build and shuffle.
- **Every** PORO hand-rolls the `dump`/`load`/`as_json`/`from_json` protocol.

A third game reimplements all of this from scratch — and each new hand-rolled
`as_json`/`load` pair is a fresh chance to hit the desync trap.

**Tests.** The net (Item 1) already exists. Do the extraction one object at a time,
keeping `bundle exec rspec` green between moves. Specs to add/consolidate are in the
**Test inventory** appendix.

**Extensibility payoff.** Game #3 declares its cards/deck/player in a few lines
and gets serialization for free, instead of copying four files.

---

## Item 3 — Make "adding a game" purely additive ✅ (done)

**Done:** `Game.playable`/`.from_type`/`.label`/`.permitted_turn_params`
(`app/models/game.rb`), consumed by the new-game view and both controllers. Fixes
the unguarded `constantize` and the dead `:game_type` strong param described
below.

**Serves the goal:** delivers done-criterion **#1 (additive)** and the safety half
of **#4** (no unsafe game-type input). This is what keeps the shared view and
controllers untouched when a game is added. Independent of Items 1 & 2.

### Primary issues (central files edited per new game)
1. **Hardcoded type dropdown** — `app/views/games/new.html.slim`:
   `f.input :type, collection: ['Go Fish', 'Crazy Eights']`.
2. **`GamesController#create` munges + `constantize`s raw user input** —
   `"#{params[:game][:type]}Game".delete(" ").constantize`. Extensibility seam
   *and* a mild security smell (no allowlist; garbage input can hit `constantize`).
3. **`TurnsController#game_params` permits the union of all games' turn params** —
   `permit(:player_name, :rank, :card, :suit)`. A file that shouldn't know any
   specific game.
4. **Latent bug:** `GamesController#game_params` permits `:game_type`, but there is
   no such column and `type` is read directly from `params[:game][:type]`,
   bypassing strong params. Dead/incorrect permit.

Everything else is already additive: per-game view partials resolve via
`to_partial_path`; the STI subclass + presenter + form are genuinely new files.

### Approach — a small game-type registry
Each `Game` subclass declares its own metadata; `Game` exposes a registry the view
and controllers read from:
```ruby
class Game < ApplicationRecord
  TYPES = %w[GoFishGame CrazyEightsGame].freeze     # the one central list
  def self.playable            = TYPES.map(&:constantize)   # constantize of a fixed allowlist
  def self.from_type(name)     = playable.find { it.name == name }
  def self.label               = name.delete_suffix("Game").titleize
  def self.permitted_turn_params = []
end
# GoFishGame:      label "Go Fish";      permitted_turn_params %i[player_name rank]
# CrazyEightsGame: label "Crazy Eights"; permitted_turn_params %i[card suit]
```
Seams then read from it:
- **new view** → `collection: Game.playable.map { [it.label, it.name] }`.
- **`GamesController#create`** → `Game.from_type(params[:game][:type])`; reject
  `nil`. No munging, no raw `constantize`. Fixes the `:game_type` bug.
- **`TurnsController#game_params`** → `permit(*@game.class.permitted_turn_params)`.

**Decided:** explicit `TYPES` list over `Game.descendants` auto-discovery — Zeitwerk
lazy-loads in dev/test, so `descendants` is unreliable there. One greppable line per
game is the robust, honest trade.

**Decided:** `permitted_turn_params` lives on the **`Game` subclass** (not the
Form). The `TurnsController` already holds `@game`, so `@game.class.permitted_turn_params`
needs no extra lookup, and it keeps all per-game registration metadata
(`label`, `permitted_turn_params`) in one place — the class the registry lists.

### Tests
- Registry unit spec: `playable`, `from_type`, per-class `label`/turn params.
- `games_spec` request: each registered type creates; unknown/garbage type is
  rejected and instantiates nothing (guards the constantize hardening).
- `turns_spec` request: each game accepts only its own params; a foreign param is
  dropped.
- Assert the new-game options are registry-driven.

### Sequencing
Independent of Items 1 & 2 (no shared surface) — the smallest item, viable as a
standalone quick win. Extend the existing request specs alongside the change.

### Net effect for game #3
Add one line to `TYPES` and declare `label` + `permitted_turn_params` on the new
class. Zero edits to the view or either controller.

---

## Bonus — correctness smells (cheap, independent)

- `GoFish::Player#out_of_cards?` references an undefined local `player` — dead and
  broken; either fix to `cards.empty?` or delete.
- `Game#finish` doesn't persist and `Game#start` uses `save` (not `save!`); the
  persistence contract is inconsistent and relies on a later `save!`. Make it
  explicit.
- `BroadcastGameJob.perform_now` runs synchronously in the request path, negating
  the job. Decide: broadcast inline (drop the job) or `perform_later`.

---

## Item 2 — decided structure

**Guiding principle:** no concrete third game is picked yet, so extract only what
is *provably* duplicated today and *future-agnostic*. Defer anything that would
guess at a game shape we haven't committed to (Rule of Three). **Unify the nouns
and the serialization mechanism; never unify the `Game` rules class.**

### Tier 1 — extract now (mechanism, not domain; zero guessing)

1. **`Serializable` concern (keystone).** A declarative round-trip:
   ```ruby
   class GoFish::Player
     include Serializable
     serializes :user_id, :name, cards: Card, books: Book, messages: Message
   end
   ```
   One schema generates both `as_json` and `self.load`, so a field can never
   appear in one and not the other. Kills the AGENTS.md #1 trap for every current
   and future object. Roll it out object-by-object; the platform-game contract plus
   the new `serializable_spec` catch any regression.
2. **Collapse the identical `Message`** into one shared class (the two are
   byte-for-byte identical today).
3. **`Messageable` mixin** for the identical `add_normal/action/alert_message`
   trio on players.

### Tier 2 — extract now (two independent levers)

4. **Single shared `Card`.** Blocked today only by `wild?`. Relocate wildness to
   the CrazyEights rules (below), and `Card` collapses to one class. Keep
   `RANKS`/`SUITS` on the shared card as overridable defaults so a future
   non-standard deck isn't boxed in.
5. **Single shared `Deck` + `Pile`.** Blocked today only by the `draw`/`deal`
   signature: Go Fish's deck pushes cards into a player; Crazy Eights' deck
   returns cards and the caller distributes. Normalize Go Fish to the
   returns-cards style, then both decks are one class. `CrazyEights::Discard`
   stays game-specific but subclasses the shared `Pile`.

**Seam for future non-standard decks (Uno/Pokémon).** Keep the deck *mechanics*
(`shuffle`/`draw`/`deal`/pile ops) card-type-agnostic — they never reference
`rank`/`suit`. The standard-52 build lives in one overridable `populate` method and
rank/suit live on `CardGame::Card`. That is the only cheap decision made now: a
future non-standard game overrides `populate` with its own card set and reuses all
the mechanics. We do **not** build a `PlayingCard`/`StandardDeck` split until such
a game actually exists.

### Relocating `wild?` (prerequisite for shared `Card`)

`wild?` is a **rule**, not a card property. It is used in exactly four places, all
CrazyEights rules objects: `Discard#valid_play?`, `Discard#place`,
`Game#play_turn`, and `CrazyEightsForm` (×2). Introduce `CrazyEights::WILD_RANK`
and a `wild?(card)` predicate on the CrazyEights rules (home: `Discard`, which
every caller already holds), then delete `wild?`/`WILD` from `Card`.

### Tier 3 — defer until a real game #3 exists

- **`Player`** structure beyond the `Serializable` + `Messageable` mixins
  (Go Fish has books/`take`; Crazy Eights has `remove` — leave them separate).
- **The `Game` rules class — never unified.** Matching vs. shedding vs. future
  trick-taking are genuinely different verbs; share their parts, not the whole.

---

## Item 2 — implementation manifest (files added / removed / changed)

### ➕ Added
| File | Contents |
|---|---|
| `app/models/concerns/serializable.rb` | Declarative `serializes` DSL → generates `as_json` + `self.load` from one schema. |
| `app/models/concerns/messageable.rb` | The `add_normal/action/alert_message` trio for players. |
| `app/models/card_game/card.rb` | Shared value object: `rank`, `suit`, `==`, `to_s`, `from_s`, serialization. |
| `app/models/card_game/pile.rb` | Shared base: `cards`, `remaining`, `depleted?`, serialization. |
| `app/models/card_game/deck.rb` | `CardGame::Deck < CardGame::Pile`: standard-52 build, `shuffle`, `draw`, `deal(n)`. |
| `app/models/card_game/message.rb` | Shared message value object. |

### ➖ Removed
- `app/models/go_fish/card.rb`, `app/models/crazy_eights/card.rb`
- `app/models/go_fish/message.rb`, `app/models/crazy_eights/message.rb`
- `app/models/go_fish/deck.rb`, `app/models/crazy_eights/deck.rb`
- `app/models/crazy_eights/pile.rb` (folds into `CardGame::Pile`)

### ✏️ Changed
- **`GoFish::Player` / `CrazyEights::Player`** — `include Serializable, Messageable`;
  delete hand-rolled `as_json`/`load` + message methods; point at `CardGame::Card`.
  (Classes stay separate — books/`take` vs `remove`.)
- **`GoFish::Game`** — use `CardGame::Deck`; normalize `deal`/`draw_from_deck` to the
  returns-cards signature; `include Serializable` for its own state.
- **`CrazyEights::Game`** — use `CardGame::Deck`; `card.wild?` → `wild?(card)`;
  `include Serializable`.
- **`CrazyEights::Discard`** — `< CardGame::Pile`; owns `WILD_RANK` + `wild?(card)`;
  `include Serializable`.
- **`GoFish::Book`, `GoFish::TurnResult`, `CrazyEights::TurnResult`** — convert
  their serialization to `Serializable` (where present).
- **`CrazyEightsForm`** — `parsed_card.wild?` → `game.discard.wild?(parsed_card)`.
- **`GoFishForm`** — `GoFish::Card::RANKS` → `CardGame::Card::RANKS`.

### Net effect for game #3
Adding a game means: one `*::Game` rules class, one `*::Player` (include the two
concerns), reuse `CardGame::Card`/`Deck`/`Message` as-is, and declare state with
`serializes`. No hand-rolled round-trip, no copied value objects.

### Sequencing (test risk lives in one place)
Item 1 (round-trip + shared-example specs) lands **first** as the safety net. The
only behavioral change in the whole extraction is the Go Fish deck-signature
normalization — everything else is a pure move — so the deal/draw specs are the
ones to watch go red↔green.

---

## Test inventory (Items 2 & 3)

Item 1's test work is complete (see its section). The principle for what remains:
**prove each behavior at exactly one layer.** Tags: **NEW** / **UPDATE** /
**REMOVE**.

### Item 2
- `spec/models/concerns/serializable_spec.rb` **NEW** — via a dummy includer:
  scalar / nested-object / array-of-objects round-trip; missing key → default; nil
  nested. **The only place serialization mechanics are proven** — no PORO re-tests
  round-trip.
- `spec/models/concerns/messageable_spec.rb` **NEW** — via dummy includer: each
  `add_*_message` appends a `Message` of the right type/text. **Only home for the
  adder.**
- `spec/models/card_game/card_spec.rb` **NEW** — rank/suit, equality, invalid
  rank/suit raise, `to_s`, `from_s`. → **REMOVE** `spec/models/go_fish/card_spec.rb`
  and `spec/models/crazy_eights/card_spec.rb`. No round-trip here.
- `spec/models/card_game/deck_spec.rb` **NEW** — builds 52 unique; `shuffle`
  reorders; `draw` returns+removes top; `deal(n)` returns/removes n (new
  returns-cards signature). → **REMOVE** `spec/models/go_fish/deck_spec.rb`.
- `spec/models/card_game/pile_spec.rb` **NEW (tiny)** — `remaining`, `depleted?`.
  Deck spec does **not** re-test these (inherited).
- **No `Message` spec** — trivial; covered by Serializable + Messageable + usage.
- `spec/models/crazy_eights/discard_spec.rb` **UPDATE** — the "card is wild" case
  now targets the relocated `Discard#wild?`/`WILD_RANK`. `wild?` tested **once**,
  here (not on `Card`).
- `spec/models/go_fish/game_spec.rb` + `go_fish/player_spec.rb` **UPDATE** — adjust
  to the `CardGame::Deck` returns-cards API / `Player#receive`; **remove** any
  `add_*_message` checks from player_spec (now in Messageable).
- **Untouched:** `book_spec`, both `turn_result_spec`s (they test *which* narration
  is produced — a different concern from the adder), `crazy_eights/game_spec`.

### Item 3
- `spec/models/game_spec.rb` **UPDATE (add context)** — `Game.playable` returns the
  registered classes; `Game.from_type` resolves a known name, returns `nil` for
  unknown. (The nil path's *HTTP rejection* is proven below — not re-unit-tested.)
- `spec/models/games/*_game_spec.rb` **UPDATE (one line each)** — `.label` and
  `.permitted_turn_params` values.
- `spec/requests/games_spec.rb` **UPDATE** — POST create with each registered type
  builds the right subclass + participant + redirect; a garbage type is rejected and
  instantiates nothing (behavioral home for the constantize→allowlist hardening).
- `spec/requests/turns_spec.rb` **UPDATE** — a Go Fish turn drops a foreign `card`
  param; a Crazy Eights turn drops a foreign `player_name`. Proves
  `permit(*permitted_turn_params)` behaviorally — **no unit test of the permit
  wiring.**
- `spec/requests/games_spec.rb` — GET new options are registry-driven.
  **OPTIONAL/lowest** — thin guard; include only if you want the "auto-appears in
  menu" assertion.

---

## Gotchas for the implementer

- **Factory trait clash:** `:user_won` already adds the winner as a participant, so
  combining it with `:has_participants, users: [user, …]` adds `user` twice →
  `Participants is invalid`. For a finished game with a known winner, use
  `create(:finished_game, :go_fish, :user_won, :many_participants, user: user)` and
  `game.update!(finished_at: Time.current)` (see the existing presenter specs).
- **The jsonb round-trip is persisted via `serialize :state, coder: <PORO::Game>`.**
  When you add `Serializable`, each PORO's `as_json`/`self.load` are what that coder
  calls — keep the method names/signatures the coder expects.
- **`spec/support/**/*.rb` auto-loads** via `rails_helper` — shared examples there
  are available everywhere without an explicit `require`.
- **Persistence contract (Bonus smell), relevant to Item 2:** `Game#play_turn`
  persists only because the STI subclass calls `save!`; `Game#finish` sets
  `finished_at` in memory but does not save on its own. Don't assume mutating a PORO
  or calling `finish` persists.
- **`it` block param:** the registry snippets use Ruby 3.4's implicit `it` block
  parameter (`playable.find { it.name == name }`) — that's intentional, not a typo.
