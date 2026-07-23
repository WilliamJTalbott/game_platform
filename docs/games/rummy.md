# Rummy — Rules & Implementation Notes

Meld-and-lay-off shedding game, 2+ players (built and tested with 2). Implemented
under `app/models/rummy/`.

## Rules

- **Pack:** standard 52 cards. Each player is dealt a **10-card hand**; the rest form
  the stock, with one card flipped onto the discard pile to start it.
- **Goal:** be the first to empty your hand.
- **A turn:**
  1. **Draw** — take the top card of the stock, or the top card of the discard.
  2. **Meld / lay off** (any number of times) — set aside 3+ cards from your hand as
     a new **meld** (a run or a set), or add cards from your hand onto *any* player's
     existing meld, including your own or an opponent's. Melds are shared, public
     state on the felt — there's no private "meld pile" per player.
  3. **Discard** — end your turn by discarding one card from your hand.
- **Melds:**
  - A **run** = 3+ same-suit, consecutive ranks (e.g. `4♥ 5♥ 6♥`).
  - A **set** = 3+ same rank, distinct suits (capped at 4 by suit uniqueness).
- **Going out:** if melding, laying off, or discarding empties your hand, you win
  **immediately** — you don't need to reach the discard step first.
- **Stock exhaustion:** when the stock runs out, the discard pile (minus its top
  card) is reshuffled back into the stock.
- **Scoring:** win/loss only — the scoreboard's "Cards left" column is a card count,
  not deadwood points. (Deadwood/point scoring was considered for Milestone 4 and
  deliberately deferred, not an oversight.)

## How the code models it (`Rummy::Game`)

- `deal` shuffles, deals `HAND_SIZE` (10) cards to each player, then flips one card
  onto the discard.
- `play_turn(action, cards = [], meld_index = nil)` dispatches on `action`:
  `draw_stock`, `draw_discard`, `meld`, `lay_off`, `discard`.
  - `draw_stock` / `draw_discard` move a card into the active player's hand and
    advance `phase` to `"meld"`.
  - `meld` builds a `Rummy::Meld` from the selected cards (rejecting the action if
    they don't form a valid run/set), removes them from the hand, and appends the
    meld to the shared `melds` array.
  - `lay_off` looks up the target meld by `meld_index` (its position in the
    serialized `melds` array — melds have no persisted id) and extends it via
    `Meld#can_add?` / `#add`.
  - `discard` removes the chosen card from the hand and places it on the discard.
  - **Going out:** `meld`, `lay_off`, and `discard` each call `finish_if_out`, which
    checks `active_player.out_of_cards?` and, if true, ends the turn by returning
    the winning `Player` (via `declare_winner`) instead of continuing the phase/turn
    as normal. This is the same "return the winning `Player`" contract every other
    `Game` subclass uses — the base `Game#play_turn` stamps the winner and `save!`s.
  - Melding/laying off keep `phase` at `"meld"` (you can act again); only `discard`
    calls `advance_turn`, which resets `phase` to `"draw"` and moves to the next player.
- **Stock exhaustion:** `recycle_discard_if_depleted` (checked before drawing from
  stock) reshuffles the discard's non-top cards back into the deck via
  `Discard#recycle`.
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
