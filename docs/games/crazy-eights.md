# Crazy Eights — Rules & Implementation Notes

Shedding game, 2+ players. Implemented under `app/models/crazy_eights/`.

## Rules

- **Pack:** standard 52 cards.
- **Goal:** be the first to get rid of all your cards.
- **Deal:** fewer than 4 players → **7 cards** each; 4+ players → **5 cards** each. One card is flipped to start the discard pile; the rest is the stock (deck).
- **A turn:** play one card that matches the **active card** by **rank or suit**.
  - **8s are wild** — an 8 may be played on anything, and the player nominates the new active suit.
  - If you can't (or don't) play a matching card, you draw until you can play one.
- **Win:** the first player to empty their hand wins.

## How the code models it (`CrazyEights::Game`)

- `hand_amount` → 7 for fewer than 4 players, else 5 (`MIN_PLAYERS_SMALL_HAND = 4`).
- `deal` deals hands, then places one card on the `Discard` pile as the opening active card.
- `play_turn(card, suit = nil)`:
  1. Removes `card` from the active player's hand and places it on the discard (with a chosen `suit` if it's an 8).
  2. Records a `TurnResult`; if the card is wild, logs the suit change.
  3. If the player's hand is now empty → they win (returns the winning player).
  4. Otherwise `switch_turn`.
- **`switch_turn`** advances `turn_index`, then — if the new active player has **no playable card** (`found_playable_card`) — calls `dig_for_card`, which draws until a playable card appears. The player keeps whatever they drew.
- **Deck exhaustion:** `replenish_deck` recycles the discard pile back into the deck (keeping the top/active card) and reshuffles when the deck is depleted mid-dig.
- **`Discard#valid_play?`** encodes the match rule: any wild (8), or same rank, or same suit as `active_card`.

## Card model notes

- `CrazyEights::Card::WILD = "8"`; `card.wild?` checks rank `== "8"`.
- `Card.from_s` / `to_s` convert to/from strings like `"8♥"` — the controller receives the played card as a string and rebuilds it via `Card.from_s`.
- `Deck`, `Discard` both extend `Pile` (shared `cards` + JSON round-trip).

## Difference from Go Fish worth noting

Crazy Eights ends immediately when a player empties their hand, so `CrazyEightsGame#play_turn` marks the winning `Participant` and calls `finish` right away. Go Fish instead runs until all books are won and decides the winner by book count.
