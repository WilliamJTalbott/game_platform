# Dynamic hand-card overlap (and the CSS rabbit hole it opened)

## What we were working on

The user wanted the Go Fish hand's card overlap to be computed dynamically
(via JS) instead of a hardcoded `-20px` CSS margin, so cards overlap by a
consistent *ratio* of their rendered width regardless of screen size/hand
size. That landed cleanly (see `app/javascript/controllers/hand_controller.js`,
committed in `c1327bc`), but fixing it surfaced a chain of CSS sizing bugs in
`.card-container`/`.playing-card` that we're still mid-fix:

1. Container width could diverge from the card's true aspect ratio under
   `flex-shrink` → card art got squished into a non-5:7 box.
2. Fixing that with `aspect-ratio` (height derived from a possibly-shrunk
   width) caused cards to render *taller* than the row, overflowing
   vertically and adding a page-level scrollbar / covering the hand header.
3. Fixing *that* by switching to "cards never shrink, row scrolls
   horizontally instead" (`overflow-x: auto` on `.panel--hand .panel__body`)
   broke the hover-raise effect: `.playing-card--playable:hover`'s
   `translateY(-50px)` now gets clipped at the row's own boundary instead of
   rising above the "Your Hand" header like it used to.

## What's done this session

- `hand_controller.js` (Stimulus): measures rendered card width via
  `ResizeObserver`, sets `--gf-card-overlap` to 40% of it. Recalculates on
  resize and (for the opponent accordion) on the native `toggle` event, since
  `ResizeObserver` never fires for a closed `<details>`'s hidden descendants.
  Wired up in `_go_fish_game.html.slim` (own hand) and `_opponent.html.slim`
  (opponent hands, newly wrapped in `.card-container` — they had none before).
- `playing_card.css`: `.card-container--large` now uses `flex: 0 0 auto;
  height: 100%; aspect-ratio: var(--gf-card-aspect-ratio)` instead of a fixed
  `flex-basis` width — cards never shrink/distort, they're always sized off
  the row's actual height.
- `panel.css`: `.panel--hand .panel__body` got `overflow-x: auto` (was
  mobile-only before; now unconditional) so an oversized hand scrolls instead
  of shrinking cards.
- Removed now-dead tokens `--gf-card-height-large`, `--gf-card-width-large`,
  `--gf-card-width-min` from `theme.css` (nothing reads them anymore).
- System specs in `spec/system/games_spec.rb` under `"[ Card overlap ]"`
  cover: overlap ratio at normal + narrow viewports, opponent hand overlap,
  aspect ratio holding under a large (7-card) hand, and the hand scrolling
  horizontally instead of growing the page vertically.
- **Uncommitted right now** (small, unproven fix — see below):
  `panel.css` adds `overflow-y: visible` alongside `overflow-x: auto`, and
  `theme.css`/`games_spec.rb` have minor follow-on tweaks. **This
  `overflow-y: visible` addition does not work** — see next section.

## What's left

**The hover-clip bug (point 3 above) is unsolved.** Diagnosed via an
empirical debug spec (a throwaway `_hover_debug_spec.rb`, deleted — not
committed) that screenshotted a hovered card and read `getComputedStyle`:
even with `overflow-y: visible` explicitly set, the *computed* value stays
`auto`. This isn't a mistake in the CSS — it's the CSS Overflow spec itself:
if `overflow-x` computes to anything other than `visible`, the UA is required
to force `overflow-y` to compute as `auto` too (and vice versa). **You cannot
have "scrolls horizontally, clips nothing vertically" on the same element.**
So the uncommitted `overflow-y: visible` line in `panel.css` should probably
just be reverted — it has no effect and is misleading to read later.

We were mid-discussion on bigger structural fixes when the session ended.
Ideas surfaced, roughly in order of how "big" they are:

- **CSS/HTML-drawn card faces instead of `<img>`** (user's own suggestion):
  if the card visual is text + CSS (border, shadow, suit glyph in `em`/`cqw`)
  instead of a fixed-5:7-ratio image, shrinking is safe again (no
  distortion), which means we might not need horizontal scroll at all —
  which removes the overflow-x/y conflict, which fixes the hover bug, for
  free. This was the most promising direction when we stopped: it doesn't
  just patch the hover bug, it removes the reason we needed scroll in the
  first place. Two sub-flavors discussed: full CSS cards, or a hybrid (CSS
  frame + small suit icon only).
- **Reserve headroom for the hover-raise** (padding-top ≈
  `--gf-card-hover-lift`, cards shrink slightly to fit): both directions the
  agent proposed here (shrink the 50px lift down to fit existing padding, or
  add padding and let cards get slightly shorter) were explicitly rejected by
  the user as "suboptimal" — don't re-propose these as-is.
- **Let the hand overflow to the page instead of a nested scroll
  container**: investigated and ruled out — Optics sets `html { overflow:
  hidden }` globally, so this app's page never scrolls by design; every panel
  manages its own overflow. Not available without overriding a
  framework-wide convention.
- User's last idea, **"remove the hand being boxed in a container"** — was
  about to be clarified (offered "row takes full panel height, header
  becomes an overlay" vs. "hand floats above other panels" as concrete
  readings) when the user picked "something else" and then ended the session
  before describing it. **Ask the user what they meant here before doing
  anything** — don't guess and implement.

Separately, still open and out of scope for this thread per the user
("don't worry about mobile right now"): the mobile responsive layout (someone
else's concurrent work, `game.css`'s `@media (max-width: 768px)` block) sets
`grid-template-rows: 1fr auto auto auto` — the hand row is `auto`-sized there,
which breaks the `height: 100%` → `aspect-ratio` chain (no definite height to
derive from). Whatever we land on for desktop, revisit whether it also needs
to work on that mobile layout.

## Decisions made

- **40% overlap, computed off rendered card width, recalculated on resize +
  hand mutation** (confirmed with the user across several rounds) — hand
  mutation recalculation is free because Turbo Stream turn updates replace
  the *entire* `.game` DOM node, which reconnects the Stimulus controller.
- **Cards shrink to always fit, no scroll** was the user's answer earlier in
  the session, but the very next round ("scroll-based, but only horizontal
  scroll") **reversed that** — horizontal-scroll-only is the current target,
  not shrink-to-fit. If you're tempted to reintroduce shrinking, don't,
  without re-confirming.
- **No minimum card-size floor** — cards can shrink arbitrarily small rather
  than ever triggering scroll (this was answered before the scroll-based
  pivot above; may be moot now that scroll is the direction, but the
  `--gf-card-width-min` token was removed on the assumption shrinking is no
  longer how overflow is handled at all).
- CSS container queries were picked over JS-measured height for sizing "in
  principle," but in practice we ended up using plain `height: 100%`
  (equivalent for this case, simpler, no new CSS feature surface) — flagged
  to the user as a substitution, not re-asked.
- Opponent's compact (non-`--large`) `.card-container` was deliberately left
  untouched throughout — it was empirically confirmed (via the debug script)
  to already render at the correct 5:7 ratio at every viewport tested,
  because it's fully content/intrinsic-sized with no competing width/height
  constraint. Don't "fix" it without a reason.
