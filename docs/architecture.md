# Architecture & Model Relationships

This app has **two distinct layers** that both contain a class called `Game`. Keeping them straight is the single most important thing to understand about the codebase.

## The two layers

### 1. Persistence layer (ActiveRecord)

Standard Rails models backed by PostgreSQL.

- **`Game`** (`app/models/game.rb`) — abstract STI base. The `type` column selects a subclass.
  - **`GoFishGame`** / **`CrazyEightsGame`** (`app/models/games/`) — concrete subclasses.
- **`Participant`** (`app/models/participant.rb`) — join model between `User` and `Game`; also records `winner`.
- **`User`** (`app/models/user.rb`) — `has_secure_password`; `has_many :participants` / `:games`. Stats (`games_played`, `games_won`, `win_percentage`) are derived from participants.
- **`Session`** — one row per signed-in device; the auth cookie holds its id.

Relationships:

```
User ──< Participant >── Game (STI: GoFishGame | CrazyEightsGame)
User ──< Session
```

### 2. Game-logic layer (Plain Old Ruby Objects)

Pure Ruby under `app/models/go_fish/` and `app/models/crazy_eights/`, plus a shared `app/models/card_game/` namespace. These hold the **rules and mutable game state** and know nothing about the database.

Per game namespace: `Game`, `Player`, `TurnResult`, plus `Book` (Go Fish) and `Discard` (Crazy Eights, subclasses `CardGame::Pile`). `Card`, `Message`, `Pile`, `Deck`, `Game`, and `Player` are **shared** (`app/models/card_game/`) — a new game inherits from the shared base and only adds its genuine differences.

- `GoFish::Game` / `CrazyEights::Game` both inherit from `CardGame::Game`, which owns the shared spine: `initialize` (players, deck, `turn_index`, `results`), `active_player`, `hand_amount`, a base `deal` (shuffle + deal a hand to each player), and the `self.dump`/`self.load` bridge (see below). `deal` is a template a subclass can extend via `super` for setup that genuinely differs (e.g. Crazy Eights seeds the discard pile after dealing). Both games must implement `game_over?` (is the game over?) and `play_turn` (returns the winning `Player`, or `nil` if the game continues — the contract is documented on `CardGame::Game#play_turn`).
- `GoFish::Player` / `CrazyEights::Player` both inherit from `CardGame::Player`, which owns the hand of `Card`s, the `messages` log, `out_of_cards?`, and `receive` (which delegates each card to `process_card`). `process_card` is declared abstract on the base — each subclass implements its own, since Go Fish also has to detect and pull out completed books while Crazy Eights just appends the card. `GoFish::Player` additionally owns `books` and the book-related helpers (`take`, `cards_of_rank`, `make_book`, …); `CrazyEights::Player` additionally owns `remove`.
- `TurnResult` is the narrator: when a turn happens it appends `Message`s to each player describing what they saw (attacking / defending / viewer perspectives).

**Why POROs instead of AR models?** The game rules are complex, mutation-heavy, and have nothing to do with persistence. Keeping them as plain objects makes them fast and exhaustively unit-testable without touching the DB, and keeps rules independent of Rails.

## The bridge: the `state` jsonb column

Each `*Game` subclass declares:

```ruby
serialize :state, coder: CrazyEights::Game   # or GoFish::Game
```

The PORO `Game` implements `self.dump(obj)` (→ `as_json`) and `self.load(hash)`. So the entire live game — hands, deck, discard, whose turn it is — is stored as one JSON blob in `games.state`.

**Round-trip contract:** every PORO in the tree needs matching `as_json`/`self.load`. Most of them get this for free by `include`-ing the **`Serializable`** concern and declaring a `serializes` schema, instead of hand-writing the two methods — see [docs/serialization.md](docs/serialization.md). The `*::Game` PORO itself still defines a one-line `self.dump(obj) = obj.as_json`, which is the bridge to the AR `serialize` coder protocol, not something `Serializable` generates.

### The turn cycle

```
TurnsController#create
  └─ *Form.new(...).valid?         # validate the move (app/forms/)
       └─ game.play_turn(...)      # STI subclass loads state, mutates the PORO, save!s the jsonb
            └─ BroadcastGameJob    # re-render per-user and push over Turbo Streams
                 └─ GameTurboUpdate.broadcast → presenter → partial → Action Cable
```

**Gotcha:** `play_turn` mutates the in-memory PORO. The mutation only persists because the subclass calls `save!` — forget it and the move evaporates. Reads reconstruct a fresh PORO from jsonb each time.

## Supporting cast

- **Forms** (`app/forms/*.rb`) — `ActiveModel::Model` validators wrapping PORO state (e.g. "is that rank in your hand?"). Not persisted. Controllers validate through them before mutating.
- **Presenters** (`app/presenters/*.rb`) — build a **per-user** view of a game (each player only sees their own hand + their own message log). Rendering *always* goes through a presenter, never the model directly. `GamePresenter` defines `wait_time` (the turn timer, default 30s) as a `class_attribute` so it can be tuned per game.
- **Turn timer** — `turn_timer_controller.js` counts down `wait_time`; on expiry it dispatches `turn-timer:ended`, which auto-submits the move form (`game-form#submitForm`). This is how idle turns are forced along.
- **Auth** — hand-rolled `Authentication` concern (`app/controllers/concerns/authentication.rb`), not Devise. A signed cookie stores a `Session` id; `Current.session` / `current_user` expose the request context.
- **Jobs / cron** — GoodJob is the Active Job adapter. `CleanGamesJob` runs every 15 min (`config/initializers/good_job.rb`) and soft-deletes games older than 3 days. `BroadcastGameJob` fans out live turn updates.
- **Soft deletes** — games set `deleted_at` rather than being destroyed; index/lobby queries filter it out.

## Adding a new game type

1. Write the rules engine as POROs under `app/models/<game>/` (`Game < CardGame::Game`, `Player < CardGame::Player`, `TurnResult`, …), reusing `CardGame::Card`/`Pile`/`Deck`/`Message` as-is. `Game` inherits `initialize`, `active_player`, `hand_amount`, `deal`, and `dump`/`load` from `CardGame::Game` — override `deal` (calling `super`) only if setup needs more than shuffle-and-deal-a-hand — and must implement `game_over?` and `play_turn`. `Player` inherits its spine (accessors, `initialize`, `out_of_cards?`, `receive`) from `CardGame::Player` and only needs to implement `process_card`. Both declare their own `serializes …` line for whatever extra state they add — `Serializable`'s schema merges with the base's via inheritance (see [docs/serialization.md](docs/serialization.md)). TDD these first.
2. Add an STI subclass under `app/models/games/` that declares `self.game_class` / `self.player_class` (the `class_attribute`s the `Game` base uses to build the PORO and its players), `serialize`s `state`, declares `label`/`permitted_turn_params`, and implements one private `turn_target(**params)` mapping submitted turn params to the rules engine's `play_turn` args. `build_game`, `create_players`, `presenter`, and `form_class` are all inherited from `Game` by naming convention (`GoFishGame` → `GoFish::Game`/`GoFishGamePresenter`/`GoFishForm`) — a new subclass should not need to override them.
3. Register it in `Game::TYPES` (`app/models/game.rb`) — the one line that wires it into the new-game form and both controllers via the `Game.playable`/`.from_type` registry. No other shared file needs to change.
4. Add a `*Form` validator in `app/forms/`.
5. Add a `*GamePresenter` in `app/presenters/` — `name`, `player`, `user_turn?`, `messages`, `cards` are inherited from `GamePresenter`; only add genuinely game-specific view data and the `score_for`/`score_order`/`score_label` hooks — and the matching view partial.
6. Add `it_behaves_like "a platform game", …` to the new game's model spec with `legal_turn`/`winning_turn` lambdas — this is the contract that proves the new game is wired correctly.
