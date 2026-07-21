# Front-End Improvements Plan

**Status: all three efforts complete.** Spec plans and checklists live in
`docs/plans/fix-books-and-broken-images-spec-plan.md` and
`docs/plans/responsive-mobile-layout-spec-plan.md`. Effort 3 (cleanup) had no
dedicated spec plan — verified via the existing suite + rubocop + manual visual
diffs, per its own "Testing" section below.

**North-star goal:** the game screen should feel *complete and polished on any device* — nothing broken, nothing missing, and it should hold up equally on desktop and on a phone (it ships as a PWA).

Three efforts get us there, ordered so each builds on the last:

1. **Fix Books + broken images** — make the screen complete (no broken/missing content).
2. **Responsive / mobile layout** — make that complete screen work on any device.
3. **Front-end code cleanup** — pay down the small debt uncovered along the way.

Testing follows the project's layering (see `AGENTS.md`): prove per-user view data in `spec/presenters`, and reserve `spec/system` (Playwright) for the live-rendered behavior a browser is actually needed to see. Write the failing spec first.

---

## 1. Fix Books + broken images — ✅ DONE

Implemented. `book.slim` → `_book.html.slim` (renders via `image_tag`), presenter gained `#books`, and both the player's `.panel--books` and each opponent's `expanded__books` now render collected books. Covered by `spec/presenters/go_fish_game_presenter_spec.rb` (`#books`) and a `[ Books ]` context in `spec/system/games_spec.rb`. See `docs/plans/fix-books-and-broken-images-spec-plan.md`. Detail below kept for reference.

**Problem**

- **Broken image paths.** `book.slim:2` and `_opponent.html.slim:17` use raw `src="src/dark_cards/..."` strings, which don't resolve through the asset pipeline. The correct pattern is `image_tag("dark_cards/...")`, as `crazy_eights_games/_table.html.slim:3` already does. Result: opponent card-backs and any book art render as broken images.
- **Books are never displayed.** `book.slim` is an **orphaned partial** — nothing renders it. The player's Books panel (`_go_fish_game.html.slim:64` `.panel--books .panel__body`) is empty, and each opponent's `expanded__books` div (`_opponent.html.slim:19`) is empty. The data exists (`GoFish::Player#books` → array of `Book`, each with `#rank`) but the presenter only exposes the count (`score_for → player.book_count`).

**Changes**

- Replace every `src="src/dark_cards/..."` with `image_tag("dark_cards/...")` (`book.slim`, `_opponent.html.slim`).
- Add a `books` accessor to `GoFishGamePresenter` for the current player (and confirm opponents expose `books` for the opponent partial — they're `GoFish::Player` objects, so they do).
- Render the `book` partial as a collection into the empty `.panel--books` body and into each opponent's `expanded__books`.
- Style collected books (fan/stack of card faces) in `components/panel.css` (`.panel--books`) and `components/player_dropdown.css` (`.expanded__books`), using Optics tokens + existing `--gf-*` card tokens. Reuse `.playing-card` sizing rather than inventing new dimensions.

**Testing**

- `spec/presenters/go_fish_game_presenter_spec.rb`: the new `books` method returns the current player's books.
- `spec/system`: after a book is completed, the player's Books panel and the opponent dropdown show book art (one coarse example — this is the browser-only rendering).

**Files:** `app/views/go_fish_games/book.slim`, `_opponent.html.slim`, `_go_fish_game.html.slim`, `app/presenters/go_fish_game_presenter.rb`, `app/assets/stylesheets/components/panel.css`, `components/player_dropdown.css`.

---

## 2. Responsive / mobile layout

**Problem**

There are **zero media queries** in the stylesheets. Two fixed grids drive the game experience:

- `components/game.css` — `.game` is a 2×2 grid (`board feed / hand books`, and `board feed / hand feed` for Crazy Eights) locked to `100dvh` with fixed side/base track sizes.
- The app shell is Optics' `.op-page` grid (`sidebar-left main sidebar-right`) with `.sidebar` at a fixed drawer width (~216px) and no built-in responsive collapse (`layouts/application.html.slim` + `application/_sidebar.html.slim`).

> Correction to an earlier draft: `components/body.css`'s `.body` grid is **not** the app shell — it's only used by the Rules page (`rules/index.html.slim`). The real shell to make responsive is `.op-page`/`.sidebar`.

On a narrow viewport the side/base columns crush the board and hand, and the fixed sidebar leaves almost no room for main content.

**Changes**

- Define breakpoints as tokens (project prefix, e.g. `--gf-breakpoint-*`) so they're consistent and not magic numbers.
- **App shell (`.op-page`/`.sidebar`):** below a tablet breakpoint, drop the sidebar rails so main content gets full width; move the sidebar to a top bar or an off-canvas drawer (`_sidebar.html.slim`). (Optics has no built-in collapse, so this is a project override.)
- **Game screen (`game.css`):** below the breakpoint, restack the grid areas into a single column — board → hand → feed (with books folded into the board or hand area). The hand should scroll horizontally rather than shrink cards below a legible size (`components/playing_card.css` already has `--gf-card-width-min`).
- Verify tap targets: the move form's `<select>`s and the Start/Ask buttons must stay comfortably tappable.

**Testing**

- `spec/system`: one narrow-viewport example (resize the Playwright page) asserting the board, hand, and move form are all visible and the layout is single-column — kept coarse.
- Manual: spot-check both games at ~375px and ~768px widths.

**Files:** `app/assets/stylesheets/components/game.css`, `components/panel.css`, `components/playing_card.css`, a sidebar/`.op-page` override, `core/theme.css` (breakpoint tokens), `app/views/application/_sidebar.html.slim`.

---

## 3. Front-end code cleanup

**Problem**

Small debt surfaced while auditing the front end. Low effort, keeps the codebase honest.

**Changes**

- **Misspelled BEM block.** `summery__name` / `summery__details` should be `summary__*` (or fold into the `player-dropdown` block per BEM — these are parts of it, so `player-dropdown__name` / `player-dropdown__details` is the more correct fix). Update `_opponent.html.slim` and `components/player_dropdown.css` together.
- **Dead file.** `app/assets/stylesheets/application.css` is empty and unused (Propshaft serves `:app`; see `docs/frontend.md`). Remove it if nothing references it.
- **Hard-coded values → tokens.** Replace the remaining literals with Optics tokens or documented project tokens:
  - `panel.css:68` `--gf-feed-background: #2d0808;` — promote to a named token or map to an Optics color.
  - `panel.css:99` `linear-gradient(to top, black 85%, transparent 100%)` (mask) — use `currentColor`/a token; masks don't need a literal color.
  - `popup.css:14`, `end_of_game_modal.css:24`, `playing_card.css:20-21` — `rgba/rgb(0 0 0 / …)` shadows/overlays → Optics shadow tokens or a defined `--gf-*` shadow token.

**Testing**

Visual regression only — confirm the dropdown, feed mask, popup, modal, and card shadows look unchanged. No new specs; run the existing suite (`bundle exec rspec`) and `bin/rubocop` to confirm nothing breaks.

**Files:** `app/views/go_fish_games/_opponent.html.slim`, `app/assets/stylesheets/components/player_dropdown.css`, `components/panel.css`, `components/popup.css`, `components/end_of_game_modal.css`, `components/playing_card.css`, and remove `application.css`.

---

## Suggested order

Do them top-to-bottom. #1 makes the screen *right*, #2 makes it *work everywhere*, #3 tidies up. #3's BEM rename touches the same opponent/dropdown files as #1, so doing #1 first avoids re-editing them.
