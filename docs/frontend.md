# Frontend styling

How CSS is organized and loaded in this app. Three pillars: the **Optics** design
system, **design tokens** (CSS custom properties), and **BEM** class naming. Read this
before writing or moving any styles.

## The color model (read this first)

The single most important thing to understand about styling here: **Optics contributes
only the neutral chrome — every actual *color* on the site is hand-picked and applied
explicitly.** No component of ours derives its color from the Optics *primary* ramp; we
do not use `--op-color-primary-*` tinted surfaces at all.

There are exactly two kinds of color:

1. **Coral — the one brand accent.** It carries every call-to-action, link, focus
   affordance, brand wordmark, and "it's your turn" signal, on every page. Coral is a
   handful of **hand-picked shades** (`--gf-color-accent*`), *not* a derived ramp.
2. **Zone accents — one hand-picked color owned by a single context.** Green is the
   game **felt** (`--gf-felt*`); blue is the games-index **lobby** (`--gf-lobby-bar`,
   consumed by the raised game bars in `components/game_card.css`). A zone accent is
   applied only inside its zone and never leaks out — green appears *only* on the card
   table, never on chrome.

Everything that is not coral or a zone accent is **warm-neutral chrome** drawn from
Optics' neutral scale (`--op-color-neutral-*`). That's the yellow-tinged gray of panels,
feeds, borders, the sidebar, stat tiles, dropdowns, and message bubbles.

**Why it's built this way:** Optics derives all its color from two hue scales — primary
(accent) and neutral (chrome) — with no secondary/accent scale, and its primary ramp is
awkward to bend to a bright hand-picked color (see the gotchas below). Rather than fight
that, we let Optics own the neutrals and hand-pick every color ourselves. This keeps the
palette deliberate: coral means "act," green means "you're at the table," and nothing is
accidentally tinted by whatever hue the primary ramp happens to be.

The **mockups** (`docs/mockups/*.html`, e.g. `games-index-final.html` and the Rummy page)
are the source of truth for this model — they hand-pick every value and use no Optics at
all. `core/theme.css` reproduces that model in the real app on top of Optics' neutrals.

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
- **The `--op-*` token system** — spacing, typography, radii, borders, shadows, and the
  **neutral color scale**. Build with these tokens rather than hard-coded values wherever
  one exists.

**We use Optics for the chrome, not the color.** Take Optics' neutral scale
(`--op-color-neutral-*`) for every surface, border, and body-text color; take its
non-color tokens freely. But do **not** reach for the Optics *primary* ramp
(`--op-color-primary-*`) to color a component — accents are hand-picked (see the color
model above). The one exception is Optics' *own* internal chrome (focus rings, focused
Simple Form inputs): those read `--op-color-primary-*` internally and we can't stop them,
so `theme.css` points the primary hue at coral to keep them on-brand — that's the only
reason the primary knobs are set.

Because Optics is loaded from a CDN, its version is pinned in **two** places that must
stay in sync: the CDN URL in `_head.html.slim` and the `@rolemodel/optics` entry in
`package.json`.

## Design tokens

Tokens are CSS custom properties. There are three tiers:

| Prefix     | Meaning                          | Defined where                     | Example |
|------------|----------------------------------|-----------------------------------|---------|
| `--op-*`   | Optics tokens                    | Optics CDN (some overridden below)| `--op-color-neutral-plus-seven`, `--op-space-large`, `--op-radius-2x-large` |
| `--gf-*`   | Project tokens, shared/reusable  | `core/theme.css` (or a block)     | `--gf-card-aspect-ratio`, `--gf-navbar-height` |
| `--_gf-*`  | Component-**private** tokens      | inside the block that uses them   | `--_gf-playing-card-shadow` |

**Rule of thumb (per project convention):** prefer an Optics `--op-*` token. When Optics
doesn't cover something and the value is shared across features, define a project token
(`--gf-…`) in `core/theme.css`. The leading underscore (`--_gf-…`) marks a token as
**local to one component** — do not reference it from another file.

`core/theme.css` configures Optics' neutral scale and defines every hand-picked color.
Optics derives its color from just **two** hue scales — `--op-color-primary-*` (accent)
and `--op-color-neutral-*` (chrome/surfaces); there is no built-in secondary/accent
scale, which is the root reason we hand-pick accents. `--op-color-neutral-h` tracks
`primary-h` by default, so it's set explicitly to give the chrome its own warm
(yellow-gray) hue independent of the coral accent.

How each color in the model maps to tokens (see the annotated `core/theme.css`):

- **Chrome is Optics neutral.** `--op-color-neutral-h/s` are tuned to a warm low-sat
  gray; every panel, feed, border, dropdown, stat tile, and message bubble draws from
  the `--op-color-neutral-*` `plus-N`/`minus-N`/`on-*` scale. No component pulls the
  primary ramp for a surface.
- **Coral is hand-picked project tokens.** `--gf-color-accent` (flat bright fill) +
  `--gf-color-on-accent` (ink on it) for fills like primary buttons
  (`components/button.css`) and the directive bubble; `--gf-color-accent-text` (a
  `light-dark()` pair, contrast-safe on either page background) for accent text/headings/
  brand (`body`/`info_card`/`profile`/`sidebar`/`meld`); `--gf-color-accent-secondary`
  (a soft tint) for "accent" surfaces that shouldn't be full-strength. All one hue (16°) —
  coral is a few chosen shades, never a derived ramp that could drift toward muddy copper.
- **Green is the felt zone accent.** `--gf-felt`/`--gf-felt-bright`/`--gf-felt-brighter`
  (`light-dark()` pairs) paint the card table only. Green appears nowhere else.
- **Blue is the lobby zone accent.** `--gf-lobby-bar` (`light-dark()` pair) is the
  games-index's raised game-bar surface, consumed by `components/game_card.css`. Its tray
  (`components/lobby.css`) stays warm-neutral chrome; only the bars carry blue. The
  recessed-tray/raised-bar elevation pair is `--gf-lobby-tray-shadow`/`--gf-lobby-bar-shadow`.
- **The Optics primary hue is pointed at coral** — solely so Optics' own internal chrome
  (focus rings, focused inputs) reads coral. Our CSS never reads `--op-color-primary-*`.

**Two Optics gotchas that shaped this model** (learned the hard way — they're *why*
accents are hand-picked project tokens rather than a re-skin of the primary ramp):
- `--op-color-primary-l` is **nearly inert** — the scale hardcodes a lightness ramp per
  step, so the `-l` knob barely does anything. You cannot lighten/flatten the accent
  through it, so a bright hand-picked coral is unreachable via the ramp.
- `--op-color-primary-base` is a `light-dark()` pair fixed at ~40%/38% lightness — Optics
  **keeps the accent mid-dark in both schemes** and never lifts it to a light tone in
  dark mode. This is why pointing primary at coral yields a *muted* coral for Optics
  internals, and why the bright CTA coral must be its own project token. (An earlier
  attempt overrode `base` directly to coral; it worked but hijacked a token many Optics
  components read — hence the cleaner project-token approach.)

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
3. Color it per the color model: **neutrals** (surfaces, borders, body text) come from
   `--op-color-neutral-*`; **accent** color comes from the hand-picked tokens
   (`--gf-color-accent*` for coral, `--gf-felt*` for the table) — never from
   `--op-color-primary-*`. For non-color values (spacing, radii, type, shadows) use
   `--op-*` first, adding a `--gf-*` token in `core/theme.css` only if Optics has no
   equivalent and the value is reused. Keep one-off private values as `--_gf-*` inside
   the block.
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
