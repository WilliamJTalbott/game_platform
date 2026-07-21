# Feature: Fix Books + broken images (front-end improvements plan, effort 1)

## Feature summary

The Go Fish screen currently has two visible defects: opponent card-backs and any book art render as broken images because `book.slim` and `_opponent.html.slim` use raw `src="src/dark_cards/..."` strings instead of `image_tag`; and the Books panel (both the current player's `.panel--books` and each opponent's `expanded__books`) is always empty because `book.slim` is an orphaned partial that nothing renders, even though `GoFish::Player#books` already holds the data.

After this change: broken-image `src` strings are replaced with `image_tag`, the current player sees their own completed books rendered as card faces in the Books panel, and each opponent's dropdown shows their completed books too.

## Test coverage

### `spec/presenters/go_fish_game_presenter_spec.rb` (modify existing)

#### #books
- [x] returns the current player's books

### `spec/system/games_spec.rb` (modify existing — add a `[ Books ]` context alongside the existing `[ View ]`/`[ Start ]`/`[ Turn ]` contexts)

#### player completes a book
- [x] shows the completed book's card art in the player's Books panel
- [x] shows the completed book's card art in the opponent's expanded dropdown

## Related specs (regression check)

- `spec/presenters/go_fish_game_presenter_spec.rb` — existing scoreboard/score_label examples must keep passing (score_for still reads `player.book_count`, untouched)
- any existing Go Fish system spec covering the opponent dropdown or hand rendering, to confirm the `image_tag` swap for card-backs doesn't break existing broken-image-tolerant assertions
