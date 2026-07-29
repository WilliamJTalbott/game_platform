# Rummy hand sort buttons

## Goal

Let a player sort their Rummy hand by rank or by suit via two buttons above the
hand, client-side only, with no server/turn involvement. Follows on from
[docs/handoffs/2026-07-28-rummy-hand-sorting-investigation.md](../handoffs/2026-07-28-rummy-hand-sorting-investigation.md),
which established the constraints below as decisions, not open questions.

## Scope

- Two buttons: **By rank**, **By suit**. No "Groups" mode, no reset/"draw
  order" button, no active/pressed state on the buttons — each click is a
  one-shot re-sort; whichever was clicked most recently wins.
- No drag/manual reordering — separate future follow-up per the handoff.

## Sort key decisions

- **By rank** sorts ace-low (A, 2, 3, ... K) — matches `Rummy::Meld::RANK_VALUES`,
  the scale runs are actually validated against, so a hand sorted by rank reads
  the same way a run melds.
- **By suit** groups by `CardGame::Card::SUITS` order (Hearts, Spades, Clubs,
  Diamonds) and breaks ties within a suit ace-high (2..K, A) — matches
  `CardGame::Card::RANKS`, the deck's own gameplay order.
- These two rank conventions differ from each other and that's intentional per
  the user's explicit choice — do not "fix" one to match the other.

## Data flow

1. `RummyGamePresenter::HandCardView` gains two new fields:
   - `rank_value` — `Rummy::Meld::RANK_VALUES.fetch(card.rank)` (ace-low, 1..13)
   - `rank_index` — `CardGame::Card::RANKS.index(card.rank)` (ace-high, 0..12)
   - `suit_index` — `CardGame::Card::SUITS.index(card.suit)`
2. `_hand_card.html.slim` renders these as `data-*` attributes on `.hand-card`
   (the `<label>` element, since that's what the JS will reorder).
3. A new `hand-sort` Stimulus controller reads those data attributes, sorts the
   `.hand-card` children of `.hand-fan` in place (reordering DOM nodes — no
   re-render), and writes the applied mode to `localStorage` keyed by game id +
   user id.
4. On `connect()` (which fires again after `GameTurboUpdate` replaces the whole
   `dom_id(game)` div on every turn), the controller reads localStorage and
   re-applies the last-used mode if one is saved. If none is saved, the hand
   stays in server draw order.

## Files touched

- `app/presenters/rummy_game_presenter.rb` — extend `HandCardView` struct + a
  private `hand_card_view(card)`-style builder for the three new fields.
- `app/views/rummy_games/_hand_card.html.slim` — add the three `data-*`
  attributes.
- `app/views/rummy_games/_hand_dock.html.slim` — add the button group inside
  `.hand-dock__top`, and `data-controller="hand-sort"` +
  `data-hand-sort-game-id-value` / `data-hand-sort-user-id-value` on a
  wrapping element (localStorage key needs both to scope per game+user).
- `app/javascript/controllers/hand_sort_controller.js` — new Stimulus
  controller. Two actions (`sortByRank`, `sortBySuit`) plus `connect()`
  reapplying the saved mode.
- `app/javascript/controllers/index.js` — register it (or run
  `bin/rails stimulus:manifest:update` instead of hand-editing).
- CSS: reuse the existing button classes in `hand_dock.css` / whatever the
  phase stepper buttons already use — no new visual component expected, but
  confirm via screenshot.

## Constraints carried over from the investigation

- The buttons sit inside `simple_form_for` (`_rummy_game.html.slim` wraps the
  hand dock) — buttons need `type="button"` or a click submits a turn.
- Sorting must not touch selection state — each card's checkbox `<input>`
  moves with its `<label>` when the DOM nodes are reordered, so this is safe
  as long as the controller reorders existing nodes rather than replacing them.
- Newly drawn cards naturally slot into the correct sorted position on the
  next turn's re-render + re-sort (no special "append at end" handling needed
  here — that concern was specific to manual drag order, not button sorts).

## Test plan

- `spec/presenters/rummy_game_presenter_spec.rb` — new `#hand_cards` examples
  asserting `rank_value`, `rank_index`, `suit_index` on a `HandCardView` for a
  known card (e.g. Ace of Hearts → `rank_value: 1`, `rank_index: 12`,
  `suit_index: 0`).
- `spec/system/playing_rummy_spec.rb` — a `:js` example that visits a started
  game, clicks "By rank", and asserts `.hand-card` DOM order by reading each
  card's rendered rank (via `page.all(".hand-card")` order or data attribute);
  same for "By suit". Include a dark-mode `screenshot(...)` per AGENTS.md.
  Per the existing "one session, not two" convention, no second browser
  context needed — this is single-player DOM behavior.
- No JS unit test framework in this repo (no Jest in `package.json`) — Stimulus
  behavior is verified through the system spec only, consistent with how
  `hand_controller.js` (the overlap controller) is tested today.

## Out of scope (explicitly deferred)

- "Groups" sort mode.
- Manual drag reordering.
- A reset/"draw order" button.
- Active/pressed visual state on the sort buttons.
