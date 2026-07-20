# Go Fish — Rules & Implementation Notes

Family card game, 2–5+ players. Implemented under `app/models/go_fish/`.

## Rules

- **Pack:** standard 52 cards. Some are dealt; the rest form the stock pile.
- **Goal:** win the most **books**. A book is four of a kind (four Kings, four Aces, …). Thirteen books exist.
- **Deal:** 2–3 players → **7 cards** each; 4–5 players → **5 cards** each. Remainder becomes the stock.
- **A turn:** the active player asks a specific opponent for a rank they already hold at least one of ("Give me your Kings").
  - If the opponent has cards of that rank, they hand over **all** of them and the active player **goes again**.
  - If not, the opponent says "Go fish!" and the active player draws the top stock card, then the turn passes left.
  - Completing a book (4th card) sets it aside; play continues.
- **Empty hand:** a player with no cards draws from stock on their turn and asks for that rank. If the stock is also empty, they are out.
- **End:** when all thirteen books are won. Most books wins.

## How the code models it (`GoFish::Game`)

- `hand_amount` → `LARGE_HAND` (7) when fewer than `MIN_PLAYERS_SMALL_HAND` (4), else `SMALL_HAND` (5).
- `play_turn(target, rank)`:
  - `get_matches` — if the target has the rank, transfer the cards to the active player and they repeat the turn.
  - `go_fish` — otherwise draw from the deck; if the drawn card happens to match the asked rank, the player repeats; otherwise the turn ends.
  - `repeat_turn` / `end_turn` both call `draw_on_empty` so a player who empties their hand refills before play continues; `switch_turn` skips players who have no cards.
- **Books** are formed automatically inside `Player#process_card`: receiving the 4th card of a rank triggers `make_book`, which removes those cards and appends a `Book`.
- **Winner** (`decide_winner`): most books; ties broken by the highest-ranked book (`Card::RANKS` order, 2 low → A high).
- **`TurnResult`** appends narration `Message`s to every player from their own perspective (asked / got / go-fish / drew / winner), so each player's log reads in the second or third person appropriately.

## Card model note

`GoFish::Card` ranks are `2..10, J, Q, K, A` (ace high). Suits exist but are irrelevant to matching — only rank matters for asking and for books.
