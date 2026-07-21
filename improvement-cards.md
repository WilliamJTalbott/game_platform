# Improvement Cards

_Sourced from a `/rails-audit` pass and a `/improve-codebase-architecture` pass on 2026-07-21. Each card is a self-contained slice of ~1–2 hours._

**North star:** deepen the shared `CardGame::` core the recent commits started — so the platform's rules engines and players live behind one deep abstraction instead of two copy-pasted spines — and fix the one user-facing page that is currently broken. Cards 2 and 3 are the two halves of the same extraction and are best done together (either order); Card 1 is independent.

---

## 1. Fix the game history page — ✅ done

**Goal (done when):**
- `/history` shows only the games worth listing (finished games), ordered most-recent-first, with no `N+1` and no waiting/soft-deleted rows leaking in.
- The **Winner** column shows the actual winner's name — not the literal text "game winner".
- Behavior is pinned by a spec at the right layer (request spec for the page + presenter/scope unit coverage).

**Why (what the assessment surfaced):**
- `app/views/history/_game.html.slim:4` reads `td game winner` — in Slim that renders the **literal string "game winner"**, so every row's Winner column is the same hardcoded text instead of the real winner. Confirmed display bug.
- `HistoryController#index` (`app/controllers/history_controller.rb:3`) is `@games = Game.all` — unscoped. It returns games that are still `waiting`, soft-deleted (`deleted_at` set), and games belonging to other users, with no ordering and no eager loading of the winner association.
- The winner already has a home to derive from: `Game#end_game` stamps `participants.winner` (`app/models/game.rb:39-42`) and `GamePresenter#winner` resolves it (`app/presenters/game_presenter.rb:15`) — the view just isn't calling it.

**Files & code referenced:**
- `app/controllers/history_controller.rb:3` — `@games = Game.all` (needs a `finished` scope + ordering + eager load)
- `app/views/history/index.html.slim` — renders `partial: "history/game", collection: @games`
- `app/views/history/_game.html.slim:2-4` — `td game.duration` (ok) and `td game winner` (the literal-text bug)
- `app/models/game.rb:39-42` (`end_game` sets `participant.winner`), `app/models/game.rb:44-47` (`status`) — candidate home for a `finished` scope
- `app/presenters/game_presenter.rb:15` — `winner = game.participants.find_by(winner: true)&.user` (the correct way to get the name)
- New/updated spec: `spec/requests/` (history page) and/or a `Game` scope unit spec

---

## 2. Extract a shared `CardGame::Game` base for the two rules engines — ✅ done

**Goal (done when):**
- A new `CardGame::Game` superclass owns the shared rules-engine spine; `GoFish::Game` and `CrazyEights::Game` subclass it and contain **only their genuine rule differences** (`play_turn`, win detection, `switch_turn`, Crazy Eights' discard handling).
- `Serializable` schema inheritance still works through the new superclass (subclasses only declare the fields they add).
- The shared platform contract spec and both games' unit specs stay green with no behavior change.

**Why (what the assessment surfaced):**
- The two POROs duplicate a large, load-bearing spine verbatim: the constants `SMALL_HAND = 5` / `LARGE_HAND = 7` / `MIN_PLAYERS_SMALL_HAND = 4`, `active_player`, `hand_amount`, a near-identical `deal`, and **byte-identical** `self.dump`/`self.load` (including the `results = []` reset). Understanding "how a turn engine is shaped" currently means reading it twice and diffing (poor locality).
- The `card_game/` layer already hosts the shared `Card`/`Pile`/`Deck`/`Message`, but stops short of the one concept where the duplication is heaviest — the game object itself. This card is the natural next step of that recently-extracted seam (high leverage: the next game author studies one shape).
- The duplicated `self.load` `results = []` reset is the single most-warned-about footgun in `docs/serialization.md`; folding it into the base removes it from the "remember to re-type this" category (absorbs the standalone A4 opportunity).

**Files & code referenced:**
- `app/models/go_fish/game.rb` — constants `:16-18`, `active_player` `:20`, `deal` `:22-25`, `self.dump`/`self.load` `:34-40`, `hand_amount` `:130-132`
- `app/models/crazy_eights/game.rb` — constants `:18-20`, `active_player` `:22`, `deal` `:24-28`, `self.dump`/`self.load` `:45-51`, `hand_amount` `:53-55`
- `app/models/card_game/` — new `card_game/game.rb` sibling to existing `pile.rb`/`deck.rb`/`card.rb`/`message.rb`
- `app/models/concerns/serializable.rb:20-22` — `inherited_serialized` (the schema-inheritance mechanism the base relies on)
- `docs/serialization.md`, `docs/architecture.md` — update the "adding a game type" section and the `dump`/`load` footgun note
- Specs: `spec/models/go_fish/game_spec.rb`, `spec/models/crazy_eights/game_spec.rb`, `spec/support/shared_examples/platform_game.rb`

---

## 3. Extract a shared `CardGame::Player` base (and delete the dead, broken method)

**Goal (done when):**
- A new `CardGame::Player` base holds `user_id`/`name`/`messages`, `initialize`, `receive`/`process_card`, and **one correct** `out_of_cards?`.
- `GoFish::Player` and `CrazyEights::Player` subclass it, keeping only their real differences (Go Fish: `books`/`take`/`make_book`/`unique_cards`; Crazy Eights: `remove`).
- The broken `GoFish::Player#out_of_cards?` is deleted, not copied.
- `Serializable`/`Messageable` inclusion and schema inheritance stay intact; player specs green.

**Why (what the assessment surfaced):**
- Both `Player` classes duplicate `include Serializable` + `include Messageable`, the identical `initialize(id = nil, name = "unset")`, and an identical `receive`/`process_card` pair — a shallow copy-paste seam.
- That seam has **already rotted into a bug**: `GoFish::Player#out_of_cards?` (`app/models/go_fish/player.rb:44-46`) is `def out_of_cards? = player.empty?` — `player` is an undefined local, so it would raise `NameError` if ever called. It is dead (zero callers), while `CrazyEights::Player#out_of_cards?` (`app/models/crazy_eights/player.rb:17-19`) is the correct `cards.empty?`. Exactly the divergence a shallow duplication produces — the deletion test passes cleanly.
- Pairs with Card 2 to complete the shared-base extraction, but can land independently.

**Files & code referenced:**
- `app/models/go_fish/player.rb` — duplicated spine `:3-14`, **broken `out_of_cards?` `:44-46`**, GF-specific `books`/`take`/`make_book`/`unique_cards` (keep)
- `app/models/crazy_eights/player.rb` — duplicated spine `:3-13`, **correct `out_of_cards?` `:17-19`** (promote to base), CE-specific `remove` `:21-23` (keep)
- `app/models/card_game/player.rb` — new base
- `app/models/concerns/serializable.rb`, `app/models/concerns/messageable.rb` — includes move up to the base
- Specs: `spec/models/go_fish/player_spec.rb` and the Crazy Eights player coverage under `spec/models/crazy_eights/`

---

### Not selected this round (surfaced by the assessments, kept for later)
- **R1** — GoodJob dashboard mounted at `/good_job` with no auth constraint (`config/routes.rb:9`). _High / security._
- **R2** — Non-participants viewing a game 500 (`GoFishGamePresenter#messages/ranks/opponents` call `player` with no safe-nav; `games#show` has no participant check).
- **R4** — `turn_timer_controller.js` `setInterval` in `connect()` with no `disconnect()` → timer leak.
- **R5** — `TurnsController#check_user_turn` renders `@game.errors.full_messages` (always empty) on an authz reject.
- **R6** — `GamesController#build_and_save_game` guards on `save!` (raises) → dead `else`; inconsistent indentation.
- **R7** — no unique index on `participants (game_id, user_id)`; a user can join a game twice.
- **A3** — lift trivial per-user accessors into `GamePresenter`; kills `player` vs `player&.` drift (hardens R2).
- **A5** — give the rules PORO a legality predicate so Forms stop reaching through the seam; drop redundant `wild? ||`.
- **A6** — consolidate the end-of-game modal broadcast duplicated in `TurnsController#render_finished_game` and `GameTurboUpdate`.
