# Making Rummy Playable — Plan

## North star

Turn the static Rummy preview (`docs/mockups/rummy-final.html`, rendered live at
`/rummy-preview`) into a **real, live-multiplayer Rummy game** that feels exactly
like the mockup: click-driven, phase-aware turns broadcast to every player.

We get there **outside-in and TDD**: each milestone starts with a failing
**system spec** describing the player-visible behavior, then we drive the failure
down through request → STI subclass → PORO game logic until it's green. We ship in
**thin playable slices** — the game is playable (if incomplete) at the end of every
milestone, and each slice ships with its **real mockup-faithful controls**, not a
throwaway plain form.

The feature list below is ordered **most important first**; the last section is
small visual polish that doesn't block playing.

---

## How this fits the existing architecture (read first)

The platform already did the prep work — Rummy is unblocked:

- **Shared `CardGame` layer** exists: `Card`, `Deck`, `Game`, `Player`, `Pile`,
  `Message`. `Rummy::Game < CardGame::Game`, `Rummy::Player < CardGame::Player`.
- **STI bridge**: add `RummyGame < Game` with `self.game_class` / `self.player_class`,
  `serialize :state, coder: Rummy::Game`, and `permitted_turn_params` / `turn_target`.
  The base `Game#play_turn` already loads the PORO from jsonb, mutates, stamps the
  winner via `end_game`, and `save!`s — we only supply the PORO and the param mapping.
- **Turn cycle is generic**: `TurnsController#create` → `form_class.valid?` →
  `game.play_turn(**params)` → `BroadcastGameJob`. Reused as-is.
- **Contract spec**: `spec/support/shared_examples/platform_game.rb`. One
  `it_behaves_like "a platform game", ...` line with `legal_turn`/`winning_turn`
  lambdas proves the STI + jsonb round-trip contract. We add it the moment Rummy can
  take a legal turn (end of Milestone 1) — it's a jsonb round-trip guard for free.
- **Serialization**: every new PORO field (stock, discard, melds) must be declared
  via `serializes ...` so it survives the jsonb round-trip. A field that mutates but
  isn't serialized is invisible after the controller reloads — the classic trap the
  `Serializable` concern exists to prevent. See `docs/serialization.md`.
- **Views/UI already built**: `app/views/rummy_games/_*.html.slim` (felt, piles,
  hand dock, meld, opponent, phase stepper, confirm pop, bubble stack) render the
  mockup today off `RummyPreviewsController`'s dummy structs. Making Rummy playable =
  feeding these same partials **real presenter data** and wiring the buttons.

**Ruleset target (agreed):** minimal turn loop first, then meld, then lay-off, then
win/score. Standard Rummy with **shared/public melds you can lay off onto** (as the
mockup shows). Build and test with **2 players** (the platform contract uses 2);
keep the PORO player-count-agnostic so 3–4 players work later.

---

## Milestone 0 — Skeleton that boots (enabler, not yet a turn)

*Goal: a Rummy game can be created, started, dealt, and rendered from real data.*

**Done.** One naming deviation from the plan: the factory trait is `:rummy`,
not `:rummy_game` (matches the existing `:go_fish`/`:crazy_eights` trait
naming convention already in `spec/factories/games.rb`).

- [x] Register `"RummyGame"` in `Game::TYPES` so it's `playable` and creatable.
- [x] `Rummy::Player < CardGame::Player` — implement `process_card` (append to hand).
- [x] `Rummy::Game < CardGame::Game` skeleton: `initialize` sets up a **stock**
      (`CardGame::Pile` / deck) and a **discard** pile; `deal` deals hands + flips one
      card to discard; `serializes` declares stock, discard, melds, turn_index.
      `play_turn` still `raise NotImplementedError`.
- [x] `RummyGame < Game`: `game_class` / `player_class`, `serialize :state`.
- [x] `RummyGamePresenter < GamePresenter` returning the per-user view data the
      existing `rummy_games/_*` partials expect (your hand, opponents, piles, melds,
      messages, current phase). Point `games#show` at the real partials.
- [x] **Retire the preview** once real views render: delete
      `RummyPreviewsController`, its `/rummy-preview` route, and `app/views/rummy_previews/`
      (the controller comment already says to). Keep the mockup HTML as reference.
- [x] Factory: `spec/factories/games.rb` gets a `:rummy` trait (+ `:started_game`/`:has_participants`).

*First red test can be the request/model level here (game creates + starts + deals);
the big outside-in system spec belongs to Milestone 1 where a turn actually happens.*

---

## Milestone 1 — Draw + discard turn loop  ← the core "playable"

*Goal: a player draws (stock or discard top), discards, the turn passes, and every
player sees it live. This is the smallest thing that is genuinely "a game of Rummy."*

**Done.** One deviation from the plan: the system spec asserts on the acting
user's own message feed rather than a second Capybara session watching the
opponent — see
[docs/handoffs/2026-07-23-rummy-multiplayer-system-spec-gotchas.md](handoffs/2026-07-23-rummy-multiplayer-system-spec-gotchas.md)
for why (matches existing convention; two-session specs were flakier, and
this codebase doesn't use that pattern anywhere else).

- [x] **RED — system spec** `spec/system/playing_rummy_spec.rb`: a user draws from
      the stock, discards, and the turn passes (asserted via the feed + disabled
      state), plus a "not your turn" guard. Kept coarse — two examples.
- [x] **Request spec** `spec/requests/rummy_turns_spec.rb`: `POST .../turns` with a
      draw action then a discard action; rejects out-of-turn and illegal draws
      (empty discard pile, discarding before drawing).
- [x] **`RummyForm`** (`ActiveModel::Model`): validate the turn params — which action
      (`draw_stock` / `draw_discard` / `discard`), and that a discard card is in hand.
- [x] **`Rummy::Game#play_turn`** (unit-spec exhaustively, no DB): draw from stock or
      discard top into the active hand; discard a chosen card to the pile; advance
      `turn_index`; recycle discard into stock when stock is depleted. Emits a
      `Rummy::TurnResult` message for the feed.
- [x] **`RummyGame#turn_target` / `permitted_turn_params`** map form params → PORO call.
- [x] **Mockup-faithful controls**: a `rummy-turn` Stimulus controller wires pile and
      hand-card button clicks into hidden `turn[action]`/`turn[card]` fields on one
      shared form, submitted via `requestSubmit`. Server renders each button's
      `disabled` state from `can_draw?`/`can_discard?` (phase + whose turn it is) —
      Stimulus only handles the click-to-submit wiring, not the enabled/disabled
      logic itself. The phase stepper shows the two real steps (Draw/Discard); the
      Meld step returns in Milestone 2.
- [x] **GREEN**, then added `it_behaves_like "a platform game", factory: :rummy`
      with `legal_turn` = draw from stock, `winning_turn` = empty your hand via
      discard (stub win path, as planned — real meld-based win is Milestone 4).

---

## Milestone 2 — Melding (runs & sets)

*Goal: during the meld phase, select cards in hand and lay down a valid meld; it
becomes shared, public state on the felt.*

**Done.** Two deviations from the plan, both agreed before implementation:

- The old two-phase model (`draw`/`discard`) became `draw`/`meld` — there's no
  persisted "discard phase"; discarding is just one of the actions available
  during `meld` (selection state lives server-side on `active_player.selected`,
  round-tripped through jsonb like everything else). The phase stepper's
  "3 · Discard" step is purely cosmetic and never actually activates.
- Discarding now goes through the same select-then-confirm interaction as
  melding (toggle exactly one card, click "Discard" in the confirm popup)
  rather than Milestone 1's direct click-to-discard, so both actions share one
  mental model instead of the hand card meaning two different things depending
  on phase.

- [x] Rules PORO (unit-spec first): a **run** = 3+ same-suit consecutive ranks; a
      **set** = 3+ same rank; reject invalid groups. `Rummy::Meld` value object with an
      `owner` (user_id) so the felt can label it.
- [x] `play_turn` grows a **meld action**: remove the selected cards from hand, create
      the meld, keep it in shared game state, stay in the meld phase (can meld again).
- [x] `RummyForm` validates the selected group is a legal meld and all cards are in hand.
- [x] **Mockup UX**: hand cards **toggle-select** on click (the `.sel` lift); a
      **contextual confirm popup** (`_confirm_pop`) appears above the selection —
      "Create a meld with these N cards?" — and its button submits. Phase stepper shows
      **2 · Meld / Lay off** active.
- [x] System spec: form a set/run and assert it appears in the shared melds zone for
      all players.

---

## Milestone 3 — Lay-offs onto shared melds

*Goal: extend any player's existing meld with cards from your hand.*

**Done.** One deviation from the plan, agreed before implementation: clicking a
meld with cards selected submits the lay-off immediately (like the piles in
Milestone 1) rather than routing through the confirm-pop — so there's no
lay-off copy variant to add there. Instead, melds that the current selection
*can't* legally extend render faded (`.meld--faded`) rather than getting a hot/
selected outline on the legal ones.

- [x] Rules: `Rummy::Meld#can_add?`/`#add` — legal iff the combined cards still
      form the *same* kind (run stays a same-suit consecutive run extendable at
      either end or both at once; set stays same-rank with unique suits, capped at
      4 by suit uniqueness). Reuses the existing `kind_for` logic instead of
      duplicating it.
- [x] `play_turn` **lay-off action**: `"lay_off"` + a `meld_index` (position in the
      serialized `melds` array — melds have no persisted id) validates against the
      target, moves the selected cards from hand onto it, stays in the meld phase.
- [x] `RummyForm` validates `meld_index` resolves to a real meld and the current
      selection legally extends it.
- [x] **Mockup UX**: with cards selected, clicking a meld immediately lays them
      off; melds the selection can't legally join render faded via presenter-computed
      `can_lay_off`/`faded` flags on `MeldView`.
- [x] System spec: lay a card off onto an opponent's meld; it renders on that meld live.

---

## Milestone 4 — Winning & scoring

*Goal: a player can go out; the round ends, a winner is stamped, everyone sees the
end-of-game state.*

- [ ] Rules: **going out** — hand empty after a legal discard (all remaining cards
      melded/laid off). `play_turn` returns the winning `Player` so the base
      `Game#end_game` stamps the winning `Participant` + `finished_at`.
- [ ] Scoring model: deadwood/round score for the scoreboard (decide the exact scheme;
      keep it in the presenter's `score_for` like the other games).
- [ ] `RummyGamePresenter#score_label` / `score_for` / `score_order`.
- [ ] Reuse the shared **end-of-game modal** (`games/_end_of_game_modal`).
- [ ] System spec: drive a game to a win; assert the modal + winner.
- [ ] Tighten the `winning_turn` lambda in the contract spec to a real going-out move.

---

## Milestone 5 — Docs & hardening

- [ ] `docs/games/rummy.md` — rules + how `Rummy::Game` implements them (mirror the
      go-fish / crazy-eights docs).
- [ ] Note Rummy in `AGENTS.md` "two card games" → three, and anywhere `Game::TYPES` is
      described.
- [ ] Edge cases: empty stock recycle, no legal meld, disconnect/reload mid-turn
      (jsonb reload), 3–4 player games.

---

## Least important — small visual polish (do last, non-blocking)

- [ ] **Bubble message feed** animation — older messages slide up and ghost/fade
      (`_bubble_stack`); directive bubble in accent for the current instruction.
- [ ] **Turn timer** countdown in the hand dock (`Your turn — 0:22`).
- [ ] Opponent strip niceties: accurate face-down **mini-card counts**, meld-count
      chips, `← turn` marker driven by real state.
- [ ] **Light/dark theme parity** pass — verify both schemes on the real page (watch
      the Optics plus/minus token flip, per project notes).
- [ ] Meld owner labels, zone hover/hot affordances, micro-transitions.
- [ ] Mobile/responsive: hand-dock scroll + board-row height (a known platform-wide
      grid gotcha — fold in with the general fix, not Rummy-specific).

---

## Where to start tomorrow

1. Write `spec/system/playing_rummy_spec.rb` (Milestone 1 RED) — it won't even reach a
   turn until Milestone 0's skeleton exists, so let its failures pull Milestone 0 into
   being (register the type, PORO/STI skeleton, presenter, factory).
2. Unit-spec `Rummy::Game#play_turn` for draw+discard and make it green.
3. Wire the Stimulus phase controller so the piles/hand buttons drive real turns.
4. Add the `it_behaves_like "a platform game"` line and confirm the jsonb round-trip.
