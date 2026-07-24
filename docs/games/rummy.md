# Rummy — Rules & Implementation Notes

Meld-and-lay-off shedding game, 2+ players (built and tested with 2). Implemented
under `app/models/rummy/`.

## Rules

- **Pack:** standard 52 cards. Hand size scales with the table: **2 players → 10
  cards, 3–4 → 7, 5–6 → 6** (`Rummy::Game#hand_size`), so the single deck always
  leaves a workable stock. The rest form the stock, with one card flipped onto the
  discard pile to start it. (5–6 players traditionally use two decks; we stay
  single-deck and just shrink the hand.)
- **Goal:** be the first to empty your hand.
- **A turn:**
  1. **Draw** — take the top card of the stock, or the top card of the discard.
  2. **Meld / lay off** (any number of times) — set aside 3+ cards from your hand as
     a new **meld** (a run or a set), or add cards from your hand onto *any* player's
     existing meld. Melds are shared, public state on the felt — there's no private
     "meld pile" per player. **You must lay down a meld of your own before you're
     allowed to lay off** onto anyone's meld (including your own additions).
  3. **Discard** — end your turn by discarding one card from your hand. **You can't
     discard the card you just drew from the discard pile this turn** — *unless* it's
     the only card left in your hand (otherwise the turn would soft-lock).
- **Melds:**
  - A **run** = 3+ same-suit, consecutive ranks (e.g. `4♥ 5♥ 6♥`).
  - A **set** = 3+ same rank, distinct suits (capped at 4 by suit uniqueness).
- **Going out:** if melding, laying off, or discarding empties your hand, you win
  **immediately** — you don't need to reach the discard step first.
- **Stock exhaustion:** when the stock runs out, the discard pile (minus its top
  card) is reshuffled back into the stock.
- **Blocked game:** if the stock is empty *and* the discard can't be recycled (only
  its top card remains), no card can be drawn — the hand is dead. Rather than track a
  draw/tie, the game ends immediately with a **random player declared the winner**.
- **Scoring:** win/loss only — the scoreboard's "Cards left" column is a card count,
  not deadwood points. (Deadwood/point scoring was considered for Milestone 4 and
  deliberately deferred, not an oversight.)

## How the code models it (`Rummy::Game`)

- `deal` shuffles, deals `hand_size` cards to each player (10 for 2 players, 7 for
  3–4, 6 for 5–6), then flips one card onto the discard.
- `play_turn(action, cards = [], meld_index = nil)` dispatches on `action`:
  `draw_stock`, `draw_discard`, `meld`, `lay_off`, `discard`.
  - `draw_stock` / `draw_discard` move a card into the active player's hand and
    advance `phase` to `"meld"`.
  - `meld` builds a `Rummy::Meld` from the selected cards (rejecting the action if
    they don't form a valid run/set), removes them from the hand, and appends the
    meld to the shared `melds` array.
  - `lay_off` looks up the target meld by `meld_index` (its position in the
    serialized `melds` array — melds have no persisted id) and extends it via
    `Meld#can_add?` / `#add`. It first checks `active_player_has_meld?`
    (`melds.any? { |m| m.owner == active_player.user_id }`) and no-ops otherwise, so
    a player can't lay off before laying down their own meld.
  - `discard` removes the chosen card from the hand and places it on the discard.
    `draw_from_discard` records the taken card in the serialized `locked_card`
    field; `Game#locked?(card)` reports it as undiscardable while the hand still holds
    another card, and `RummyForm` rejects discarding it. `advance_turn` clears
    `locked_card` at the end of the turn. The presenter flags the locked card
    (`HandCardView#locked`) so the hand renders a lock badge on it.
  - **Going out:** `meld`, `lay_off`, and `discard` each call `finish_if_out`, which
    checks `active_player.out_of_cards?` and, if true, ends the turn by returning
    the winning `Player` (via `declare_winner`) instead of continuing the phase/turn
    as normal. This is the same "return the winning `Player`" contract every other
    `Game` subclass uses — the base `Game#play_turn` stamps the winner and `save!`s.
  - Melding/laying off keep `phase` at `"meld"` (you can act again); only `discard`
    calls `advance_turn`, which resets `phase` to `"draw"` and moves to the next player.
- **Stock exhaustion:** `recycle_discard_if_depleted` (checked before drawing from
  stock) reshuffles the discard's non-top cards back into the deck via
  `Discard#recycle` — but only when the discard has more than its top card to give.
  If the stock is still empty afterward, `draw_from_stock` calls `declare_blocked`,
  which picks `players.sample` as the winner and returns it through the normal
  winning-`Player` contract (so no `nil` card is ever dealt into a hand).
- **`Rummy::Meld`** (`app/models/rummy/meld.rb`) is a value object — `kind`, `owner`
  (user_id, so the felt can label it), `cards`. `Meld.build` returns `nil` for an
  invalid group instead of raising, so callers just check for a falsy return.
- **`TurnResult`** appends narration `Message`s to every player from their own
  perspective (drew / melded / laid off / discarded / won).

## Difference from Go Fish / Crazy Eights worth noting

Rummy's "meld phase" isn't a persisted third phase distinct from discarding —
there's no separate discard-phase state. `phase` only ever toggles between `"draw"`
and `"meld"`; discarding is just one of the actions available during `"meld"`, and
which cards are selected is just per-submit form input (`RummyForm`) rather than
anything persisted in `state`. Also unlike Crazy Eights (single winner condition: hand empty) or
Go Fish (winner decided by book count once all books are claimed), Rummy's win check
runs after *three* different actions (`meld`, `lay_off`, `discard`), not just one.
