# Feature: Responsive / mobile layout (front-end improvements plan, effort 2)

## Feature summary

The game screen must hold up on a narrow (phone-width) viewport, not just desktop. Today there are zero media queries in the project stylesheets, and two fixed-track grids drive the layout:

- The app shell is Optics' `.op-page` grid (`sidebar-left main sidebar-right`, `app/views/layouts/application.html.slim` + `app/views/application/_sidebar.html.slim`) — `.sidebar` renders at a fixed drawer width (~216px) with no responsive collapse built into Optics itself.
- The game screen is `.game` (`components/game.css`), a 2×2 grid (`board feed / hand books`, or `hand feed` for Crazy Eights) locked to `100dvh` with fixed side/base track sizes.

Correction to the written plan doc: it names `components/body.css`'s `.body` grid as the app-shell target. That grid is only used by the Rules page (`app/views/rules/index.html.slim`) — the actual game screen shell is `.op-page`/`.sidebar`, which is what this effort targets instead.

After this change: below a defined breakpoint, the sidebar no longer crowds out the main content, and the game grid restacks to a single column (board → hand → feed, books folded in) with the hand scrolling horizontally rather than shrinking cards below `--gf-card-width-min`.

## Test coverage

### `spec/system/games_spec.rb` (modify existing — add a `[ Responsive ]`, `:js` context)

Uses the existing `resize_page(width, height) { ... }` helper (`spec/support/helpers/capybara_helper.rb`) — written but not yet used anywhere, exactly for this. Needs a JS-capable driver (CSS reflow doesn't happen under `rack_test`), so these examples are tagged `:js`.

#### go_fish game on a narrow viewport
- [x] does not let the sidebar crowd out the main content (main content occupies the majority of viewport width)
- [x] stacks the board, hand, and feed panels in a single column (each panel's top is below the previous one's bottom)
- [x] keeps the move form's player/rank selects and "Ask for card" button tappable (visible, not clipped)
- [x] lets the hand scroll horizontally instead of clipping cards below `--gf-card-width-min`

## Related specs (regression check)

- `spec/system/games_spec.rb` — full file, especially `[ Start ]`/`[ Turn ]` contexts (default desktop viewport must still render correctly after breakpoint styles are added)

## Out of scope for this effort

- `components/body.css` / `app/views/rules/index.html.slim` (Rules page shell) — not touched here; only the game screen's `.op-page`/`.sidebar`/`.game` grid are in scope, per the north star.

## Manual verification (not automated per the plan)

- [x] Spot-checked both Go Fish and Crazy Eights at ~375px and ~768px widths via Playwright screenshots — confirmed clean single-column stacking, no overlapping sidebar brand text, no stray Books-panel fragment overflowing the viewport.
