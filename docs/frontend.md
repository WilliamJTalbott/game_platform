# Frontend styling

How CSS is organized and loaded in this app. Three pillars: the **Optics** design
system, **design tokens** (CSS custom properties), and **BEM** class naming. Read this
before writing or moving any styles.

## How CSS loads (there is no CSS bundler)

CSS is **not** run through webpack. Webpack builds the JS only; its `application.css`
entry is empty and its build output is inert. Styling is served entirely by
**Propshaft**, which fingerprints and serves each stylesheet file individually.

The layout links every local stylesheet with one helper call, in
`app/views/application/_head.html.slim`:

```slim
= stylesheet_link_tag "https://cdn.jsdelivr.net/npm/@rolemodel/optics@2.4.0/dist/css/optics+phosphor_icons.min.css"
= stylesheet_link_tag :app, "data-turbo-track": "reload"
```

- **Line 1** loads **Optics** (and Phosphor icons) from a CDN — this is where all the
  `--op-*` tokens and `.op-*` component classes come from.
- **Line 2** uses a Propshaft feature: `:app` is a **bulk-include symbol**, not a
  filename. It emits a separate `<link>` for **every** stylesheet under `app/assets`
  (`core/base.css`, `core/theme.css`, and all of `components/*.css`). Propshaft also
  offers `:all`, which additionally includes gem-provided stylesheets — we use `:app`
  so only our own CSS is linked.

**Consequence for daily work:** to add styles, just drop a `.css` file in
`app/assets/stylesheets/` and Propshaft serves it automatically. There is **no
manifest to update, no `@import` to add, and no build step to run.** (A common source
of confusion: an empty `application.css` and a stale webpack build look broken but are
irrelevant — the styles you see come from Propshaft serving the files directly.)

## Directory layout

```
app/assets/stylesheets/
  application.css          # empty; the webpack CSS entry, unused for styling
  core/
    base.css               # element resets / global defaults
    theme.css              # ALL design tokens live here (see below)
  components/
    playing_card.css       # one BEM block per file
    panel.css
    stat_block.css
    ...
```

## Optics

`@rolemodel/optics` (v2.4.0) is the RoleModel design system. It provides:

- **Component classes** used directly in markup — e.g. `.op-page`, `.op-page__main`
  in the layouts. Reach for an Optics class before writing a new component.
- **The `--op-*` token system** — colors, spacing, typography, radii, borders, shadows.
  Build with these tokens rather than hard-coded values wherever one exists.

Because Optics is loaded from a CDN, its version is pinned in **two** places that must
stay in sync: the CDN URL in `_head.html.slim` and the `@rolemodel/optics` entry in
`package.json`.

## Design tokens

Tokens are CSS custom properties. There are three tiers:

| Prefix     | Meaning                          | Defined where                     | Example |
|------------|----------------------------------|-----------------------------------|---------|
| `--op-*`   | Optics tokens                    | Optics CDN (some overridden below)| `--op-color-primary-base`, `--op-space-large`, `--op-radius-2x-large` |
| `--gf-*`   | Project tokens, shared/reusable  | `core/theme.css` (or a block)     | `--gf-card-aspect-ratio`, `--gf-navbar-height` |
| `--_gf-*`  | Component-**private** tokens      | inside the block that uses them   | `--_gf-playing-card-shadow` |

**Rule of thumb (per project convention):** prefer an Optics `--op-*` token. When Optics
doesn't cover something and the value is shared across features, define a project token
(`--gf-…`) in `core/theme.css`. The leading underscore (`--_gf-…`) marks a token as
**local to one component** — do not reference it from another file.

`core/theme.css` also **re-skins Optics** by overriding Optics' primitive tokens.
Optics derives every color from just **two** hue scales — `--op-color-primary-*`
(accent) and `--op-color-neutral-*` (chrome/surfaces); there is no built-in
secondary/accent scale. `--op-color-neutral-h` tracks `primary-h` by default, so set
it explicitly to decouple the chrome hue from the accent.

The current theme is a **two-color model** (see the annotated `core/theme.css`):

- **Green is the genuine Optics primary** — `--op-color-primary-h/s` are green, so the
  whole ramp (base, hover/active, `plus-N` surface tints, `minus-N` accent text) derives
  natively. No Optics primitive is overridden; the ramp does the "colorful lifting."
- **Coral is a project token**, not an Optics primary. Since Optics has no secondary
  hue, coral lives as `--gf-color-*` and is applied *explicitly* to the things that
  should be coral (primary buttons in `components/button.css`; accent text/headings/
  brand in `body`/`info_card`/`profile`/`sidebar`). Two variants exist because coral is
  light: `--gf-color-accent` (flat bright fill) + `--gf-color-on-accent` (dark ink on
  it), and `--gf-color-accent-text` (a `light-dark()` pair, contrast-safe for text on
  either page background). Everything *not* explicitly painted coral stays green.
- `--gf-felt`/`--gf-felt-bright` are the game-board felt (green), also independent of
  Optics.

**Two Optics gotchas that shaped this** (learned the hard way — they're *why* coral is a
project token rather than a re-skin of primary):
- `--op-color-primary-l` is **nearly inert** — the scale hardcodes a lightness ramp per
  step, so the `-l` knob barely does anything. You cannot lighten/flatten the accent
  through it.
- `--op-color-primary-base` is a `light-dark()` pair fixed at ~40%/38% lightness — Optics
  **keeps the accent mid-dark in both schemes** and never lifts it to a light tone in
  dark mode. (An earlier attempt overrode `base` to a coral; it worked but hijacked a
  token many Optics components read — hence the cleaner project-token approach.)

Tokens may also be scoped to a block rather than `:root` when only that block needs them
(e.g. `--gf-navbar-height` is declared on `.panel`, `--gf-feed-background` on
`.panel--feed`).

## BEM naming

Classes follow **`block__element--modifier`**, one block per file in `components/`:

- **Block** — the component root: `.playing-card`, `.panel`, `.stat-block`.
- **Element** — a part of the block, joined with `__`: `.stat-block__header`,
  `.panel__body`, `.feed__messages`.
- **Modifier** — a variant, joined with `--`: `.playing-card--playable`,
  `.panel--board`, `.game--crazy_eights`, `.game--rummy`.

Elements and modifiers are **nested inside the block** using SCSS `&`, so one file reads
as one component:

```css
.playing-card {
  --_gf-playing-card-shadow: drop-shadow(0 3px 4px rgb(0 0 0 / 0.6));

  filter: var(--_gf-playing-card-shadow);
  transition: transform 0.2s ease-in-out;

  &.playing-card--playable:hover {
    transform: translateY(calc(-1 * var(--gf-card-hover-lift)));
  }

  img { width: 100%; }
}
```

(SCSS nesting is handled by PostCSS at Propshaft-serve time via the configured
`postcss-*` plugins — you write nested `&` selectors, not literal descendant CSS.)

## Adding a new styled component

1. Create `app/assets/stylesheets/components/<block-name>.css`.
2. Name the root class after the block; add elements/modifiers with `__`/`--`, nested
   under the block with `&`.
3. Style with `--op-*` tokens first; add a `--gf-*` token in `core/theme.css` only if
   Optics has no equivalent and the value is reused. Keep one-off private values as
   `--_gf-*` inside the block.
4. That's it — Propshaft serves the file automatically via `:app`. No registration.

## Gotchas

- **Don't try to "fix" the empty `application.css` or the webpack CSS build.** CSS is not
  bundled here; those artifacts are unused. Styles load through Propshaft's `:app`.
- **Bump Optics in both places** (CDN URL and `package.json`) or they drift.
- **Keep one block per file.** Splitting a block across files or mixing blocks in one
  file defeats the file-per-component convention.
- Optics token names use scales like `--op-space-small … 3x-large` and
  `--op-font-small … 4x-large`; check Optics for the exact token before hard-coding.
- **Optics color scale tokens (`--op-color-*-plus-N`/`-minus-N`) are `light-dark()` pairs,
  not fixed colors.** `plus-N` = surface/background tokens (light in light mode, dark in
  dark mode); `minus-N` = text/foreground tokens (the opposite). Moving to a lower `plus-N`
  number is darker in light mode but *lighter* in dark mode (Material-style elevation: more
  "elevated" surfaces get lighter in dark mode) — the two modes trade off in opposite
  directions along the same scale, so "one token darker" doesn't mean darker in both
  schemes simultaneously. Never substitute a raw hex/rgb for one of these tokens expecting
  a fixed color — it will look wrong in the color scheme you didn't test. Always verify
  both schemes (`page.driver.with_playwright_page { |p| p.emulate_media(colorScheme: "dark") }`
  in a system spec) before shipping a color-token change.
- **CSS custom properties can't be read inside `@media` conditions.** Breakpoint values
  (e.g. `--gf-breakpoint-tablet` in `core/theme.css`) are documentation only — every
  `@media (max-width: …)` query using that breakpoint must repeat the literal pixel value
  and is kept in sync by hand.
- **Watch for duplicate `.sidebar` class names.** `application.html.slim` wraps the sidebar
  partial in a generic `div.sidebar`, and the partial's own root renders Optics'
  `nav.sidebar.sidebar--drawer`. A bare `.sidebar {}` selector matches *both* nested
  elements. To override an Optics `.sidebar--drawer`-scoped property, match
  `.sidebar.sidebar--drawer` (same specificity, loads later) — see `components/sidebar.css`.
- **Go Fish / Crazy Eights' hand row never scrolls, and that's load-bearing.**
  `hand_controller.js` (Stimulus, `data-controller="hand"`) measures rendered card
  width via `ResizeObserver` and sets `--gf-card-overlap` (consumed by
  `.card-container`'s `margin-left` in `playing_card.css`) so cards overlap *more*
  than the 40% default whenever the hand is too wide to fit — never scroll, never
  shrink cards. This is why `.panel--hand .panel__body` is `overflow: visible`: the
  CSS Overflow spec forces `overflow-y` to compute as `auto` (clipping) whenever
  `overflow-x` is anything but `visible`, which would clip the
  `.playing-card--playable:hover` lift at the row instead of letting it rise over
  the header. Don't reintroduce `overflow-x: auto` here without re-solving that clip.
  **Rummy's hand-dock deliberately does the opposite** (see `hand_dock.css`): cards
  are fixed-size and packed with a flat gap, `.hand-fan` scrolls horizontally on
  overflow, and neither `data-controller="hand"` nor `--gf-card-overlap` computation
  is wired up — `.hand-fan`'s own `padding-top` (sized to `--gf-card-hover-lift`)
  reserves the lift headroom instead. Don't port one game's hand-overflow strategy
  to the other without re-reading why it was chosen.
