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

Pure Ruby under `app/models/go_fish/` and `app/models/crazy_eights/`. These hold the **rules and mutable game state** and know nothing about the database.

Per game namespace: `Game`, `Player`, `Deck`, `Card`, `TurnResult`, plus `Book` (Go Fish) and `Discard` / `Pile` / `Message` (Crazy Eights).

- `GoFish::Game` / `CrazyEights::Game` own `players`, `deck`, `turn_index`, and a list of `TurnResult`s.
- `Player` holds a hand of `Card`s and a `messages` log (per-player narration built during a turn).
- `TurnResult` is the narrator: when a turn happens it appends `Message`s to each player describing what they saw (attacking / defending / viewer perspectives).

**Why POROs instead of AR models?** The game rules are complex, mutation-heavy, and have nothing to do with persistence. Keeping them as plain objects makes them fast and exhaustively unit-testable without touching the DB, and keeps rules independent of Rails.

## The bridge: the `state` jsonb column

Each `*Game` subclass declares:

```ruby
serialize :state, coder: CrazyEights::Game   # or GoFish::Game
```

The PORO `Game` implements `self.dump(obj)` (→ `as_json`) and `self.load(json)` (→ `from_json`). So the entire live game — hands, deck, discard, whose turn it is — is stored as one JSON blob in `games.state`.

**Round-trip contract:** every PORO in the tree implements `as_json` and `self.load(hash)`, and they must stay in sync. If you add a field to a PORO, you must add it to *both* `as_json` and `load`, or it silently vanishes on the next save/reload.

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

1. Write the rules engine as POROs under `app/models/<game>/` (`Game`, `Player`, `Deck`, `Card`, `TurnResult`, …), each with `as_json` + `self.load`. TDD these first.
2. Add an STI subclass under `app/models/games/` that `serialize`s `state` and implements the abstract interface from `Game`: `build_game`, `play_turn`, `presenter`, `form_class`, `create_players`.
3. Add a `*Form` validator in `app/forms/`.
4. Add a `*GamePresenter` in `app/presenters/` and the matching view partial.
