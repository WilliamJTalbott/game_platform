# Rummy hand sorting — feasibility investigation

## What we were working on

The Rummy hand renders in draw order with no way to organize it. Goal: sort
buttons for the player's hand, plus (if practical) manual client-side reordering.
This session was **investigation only — no code was written.**

Note: the working tree carries unrelated in-progress leaderboard / token-migration
changes. None of them belong to this effort.

## What's done

Traced the hand path — `RummyGamePresenter#hand_cards`,
`app/views/rummy_games/_hand_dock.html.slim` / `_hand_card.html.slim`,
`RummyForm`, `RummyGame#card_from_key`, `GameTurboUpdate`, and the
`components/game/hand_*.css` trio — and established the constraints below.
Nothing implemented.

## Decisions made

**Hand order is cosmetic; the server is indifferent to it.** Verified three ways:
selection submits by `"#{rank}-#{suit}"` value rather than position (both
`RummyForm#selected_cards` and `RummyGame#card_from_key` look up by rank+suit);
`Rummy::Meld.consecutive_ranks?` sorts before validating, so an out-of-order run
still melds; and the single 52-card deck makes `rank-suit` a stable identity key.
So client-side reordering is safe and needs no server change.

**Client-side + `localStorage`, not server-side hand order.** Persisting order in
the jsonb state would need a new non-turn endpoint that bypasses
`TurnsController`'s `check_user_turn` guard (you want to sort off-turn) — a DB
write for a cosmetic preference. Rejected.

**Sort keys come from Ruby, not JS.** `Rummy::Meld::RANK_VALUES` is Ace-low
(A=1); `CardGame::Card::RANKS` is Ace-high. They disagree, and a hand sorted
A-high while runs validate A-low will read as wrong. Plan: expose
`rank_value` / `suit_order` on `HandCardView`, render as data attributes, sort on
integers in JS. Also what makes a "Groups" sort (cluster existing melds) possible
without porting `Meld` logic to JS.

**Sort buttons first; drag reorder as a separate follow-up.** Drag has two real
hazards that the buttons don't: each card is a `<label>` wrapping a hidden
checkbox, so a drag also toggles selection (needs a movement threshold +
`preventDefault` on the synthetic click); and `.hand-fan` is `overflow-x: auto`,
so dragging past an edge needs auto-scroll. No drag library in `package.json`.

## What's left

Everything. Recommended first slice:

- Button group in `.hand-dock__top` (By rank / By suit / Groups) + a `hand-sort`
  Stimulus controller reordering `.hand-card` children of `.hand-fan`.
- Presenter emits the sort-key data attributes described above.

Constraints the implementation must respect:

- **`GameTurboUpdate.broadcast` replaces the whole `dom_id(game)` div** — hand dock
  included — on every turn by any player. Order must live in `localStorage`
  (keyed by game + user) and be re-applied in the controller's `connect()`, which
  fires again after each Turbo Stream replace.
- **The buttons sit inside `simple_form_for`** (`_rummy_game.html.slim` wraps the
  hand dock), so they need `type="button"` or a click submits a turn.
- Newly drawn cards won't be in a saved manual order — appending at the end is the
  desirable behavior there.
- Verify with a `:js` system spec + dark-mode `screenshot(...)` per AGENTS.md.

Open questions: is "Groups" wanted as a third mode, or just rank/suit? Is manual
drag still wanted once buttons ship? Reorder animation (FLIP) deliberately left out
of scope unless asked for.
