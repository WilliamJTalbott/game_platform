# Frontend mechanics

**This file covers the CSS *pipeline* — how stylesheets load, where files live, how classes
are named, and the gotchas that have cost real time. It does not describe the visual
system.**

> **The visual system lives in [DESIGN.md](../DESIGN.md)** — the color model, the palette
> and its roles, typography, layout grammar, elevation vocabulary, shapes, component
> specs, and the named rules that govern all of them. Read DESIGN.md before deciding *what
> something should look like*; read this file before deciding *where the code goes*.

Three pillars: the **Optics** design system, **design tokens** (CSS custom properties), and
**BEM** class naming.

## How CSS loads (there is no CSS bundler)

CSS is **not** run through webpack. Webpack builds the JS only; its `application.css`
entry is empty and its build output is inert. Styling is served entirely by
**Propshaft**, which fingerprints and serves each stylesheet file individually.

The layout links every local stylesheet with one helper call, in
`app/views/application/_head.html.slim`:

```slim
= stylesheet_link_tag "optics-phosphor-icons.min.css"
= stylesheet_link_tag :app, "data-turbo-track": "reload"
```

- **Line 1** loads **Optics** (and Phosphor icons) — vendored locally at
  `vendor/optics/optics-phosphor-icons.min.css`, not from a CDN. This is where the
  `--op-*` tokens and `.op-*` component classes Optics still supplies come from; see
  "Optics" below for what that's shrunk to.
- **Line 2** uses a Propshaft feature: `:app` is a **bulk-include symbol**, not a
  filename. It emits a separate `<link>` for **every** stylesheet under `app/assets`
  — it globs `app/assets/**/*.css` **recursively**, so `core/*.css` and every file in
  the `components/` subfolders are all picked up (order is by sorted logical path).
  Propshaft also offers `:all`, which additionally includes gem-provided stylesheets —
  we use `:app` so only our own CSS is linked.

**Consequence for daily work:** to add styles, just drop a `.css` file in
`app/assets/stylesheets/` and Propshaft serves it automatically. There is **no
manifest to update, no `@import` to add, and no build step to run.** (A common source
of confusion: an empty `application.css` and a stale webpack build look broken but are
irrelevant — the styles you see come from Propshaft serving the files directly.)

Load order matters in exactly one way: our files are linked *after* the Optics link,
so a selector of equal specificity to an Optics one wins. That's how
`components/ui/button.css` overrides `.btn.btn--primary` without `!important`.

## Directory layout

```
app/assets/stylesheets/
  application.css          # empty; the webpack CSS entry, unused for styling
  core/
    base.css               # element resets / global defaults
    theme.css              # ALL color tokens + the neutral ramp live here
    tokens/
      scale.css            # non-color primitives (space, font, radius, shadow, …) as --gp-*
  components/              # one BEM block per file, grouped by domain
    layout/                # app structure & chrome: page, panel, sidebar, menu, banner, body, overlay
    game/                  # in-game screens: game, felt, cards, hand, pile, meld, feed, opponents, …
    lobby/                 # home/lobby & account: lobby, game_card, info_card, profile, stats, login
    ui/                    # generic reusable widgets: button, dialog, popup
```

The subfolders are purely for navigation — Propshaft's recursive glob loads every
file regardless of depth, so a block can move between folders without touching any
link tag or manifest. Pick the folder by the block's domain; when in doubt, `game/`.

## Optics

**Optics is being phased out.** `@rolemodel/optics` (v2.4.0) used to supply every non-color
token and every component class; it's being replaced piece by piece with our own —
see `docs/plans/own-the-tokens.md` for the full migration and its current phase. What's
still true today:

- **Component classes** used directly in markup — e.g. `.op-page`, `.op-page__main` in the
  layouts, and the not-yet-replaced components (`button`, `sidebar`, `form`, `dialog`, …).
  Reach for one of these before writing a new component, but expect them to keep shrinking.
- **Optics' own internal `--op-*` tokens** — its bundled components still read their own
  copies of spacing/type/radii/shadows internally, which is why `theme.css`'s bridge feeds
  them our *color* values but our non-color primitives live independently in
  `core/tokens/scale.css` as `--gp-*` (see Design tokens below).

**We vendor Optics locally, not from a CDN.** `vendor/optics/optics-phosphor-icons.min.css`
is a copy of `node_modules/@rolemodel/optics/dist/css/optics+phosphor_icons.min.css`,
registered on `config.assets.paths` (`config/initializers/assets.rb`) so Propshaft serves it.
**The file is renamed** (`+` → `-`) because Rack/Propshaft decodes a literal `+` in a request
path as a space, 404ing on a filename a CDN would serve without issue — re-vendoring a new
Optics version needs the same rename. Bump the version in `package.json`, copy the new
bundle over, and re-apply the rename.

Optics sets `html { font-size: 62.5% }`, so **1rem = 10px** — every `--op-font-*` and
`--op-space-*` value (and their `--gp-*` equivalents) reads as tenths of its pixel size
(`--gp-font-medium: 16px` is declared directly; Optics' own `--op-font-medium: 1.6rem`
computes to the same 16px).

## Design tokens

Tokens are CSS custom properties. There are three tiers:

| Prefix     | Meaning                          | Defined where                     | Example |
|------------|----------------------------------|-----------------------------------|---------|
| `--op-*`   | Optics' own internal tokens, read only by Optics' not-yet-replaced components | the vendored bundle | `--op-border-all` (used correctly in `button.css`) |
| `--gp-*`   | Project tokens — **all color, and non-color primitives too** | `core/theme.css` (color, the ramp) and `core/tokens/scale.css` (space/font/radius/border-width/shadow) | `--gp-n-plus-6`, `--gp-color-accent`, `--gp-space-medium`, `--gp-radius-2x-large` |
| `--_gp-*`  | Component-**private** tokens      | inside the block that uses them   | `--_gp-playing-card-shadow` |

**Color is always `--gp-*`; never `--op-*`.** All color belongs to the project (see DESIGN.md's
Color Ownership section and Owned Color Rule). The only `--op-color-*` references in the
codebase are inside `theme.css`'s bridge block, which points Optics' internal color tokens at
our values so its own components are painted from our palette. A color on `--op-*` anywhere
else is a bug; `grep -rn -- '--op-color-' app/assets/stylesheets/ | grep -v core/theme.css`
should return nothing.

**Non-color is also `--gp-*` now.** `core/tokens/scale.css` declares the 38 space/font/
weight/radius/border-width/shadow primitives our own components use, transcribed from
Optics' values. This is additive, not a replacement of Optics' internal tokens: Optics'
*own* bundled components (button, sidebar, form, dialog) still read their own `--op-*`
copies, and `theme.css`'s non-color overrides (`--op-border-width`, `--op-border-width-large`,
`--op-radius-2x-large`) still feed *those* so Optics-rendered chrome keeps matching. A new
component reaches for `--gp-*` first; only `--op-border-all` (a genuinely Optics-internal
composite, see DESIGN.md/§8 of the plan) and a couple of not-yet-migrated one-offs still
read `--op-*` directly. The leading underscore (`--_gp-…`) marks a token as **local to one
component** — do not reference it from another file.

Note `--gp-*` replaced an earlier `--gf-*` prefix (a leftover from when this app was only Go
Fish); if you find `--gf-` anywhere, it is stale.

Tokens may also be scoped to a block rather than `:root` when only that block needs them
(e.g. `--gp-navbar-height` is declared on `.panel`, `--gp-feed-background` on
`.panel--feed`).

### The Optics bridge

`core/theme.css` ends its color section with a **bridge**: it points Optics' internal
`--op-color-*` tokens at our `--gp-color-*` values. This exists because Optics' own components
— buttons, sidebar, inputs, dropdowns, dialogs — read `--op-color-*` from inside stylesheets we
can't edit. Left alone they would paint themselves from Optics' defaults while our hand-written
components used our palette: one screen in two color systems.

The flow is one-directional and lives in exactly one place — our palette feeds Optics, never
the reverse. The bridge covers the `plus-*` surface steps, `base`, `background`,
`on-background`, `border`, `neutral-h/s`, and — since these were found missing and caused a
real bug (an un-bridged sidebar link and body text reading Optics' own colors instead of
ours) — the surface **contrast pairs** (`on-plus-max`, `on-plus-eight`, `on-plus-seven`) and
`--op-color-primary-original` (every un-overridden `<a>`). A bridge that covers a surface but
not its contrast pair looks correct in a screenshot and is wrong in the DOM; when replacing
another Optics component, diff the tokens it reads against what the bridge covers. It also
sets `--op-color-primary-h/s/l` at coral's hue, purely so Optics' internal chrome (focus
rings, focused Simple Form inputs) reads coral instead of a stray default — never color a
component from that ramp.

Non-color overrides are separate and few: `--op-border-width` (1.8px),
`--op-border-width-large` (3px), and `--op-radius-2x-large` (20px, up from Optics' 16px).
These exist only to keep Optics' *own* rendered components matching our values — our own
components read the `--gp-*` equivalents in `core/tokens/scale.css` instead. Overriding an
Optics token affects every Optics component that reads it — prefer a new `--gp-*` token
unless the global change is the point.

**The ramp is generated, not typed.** Five knobs (hue, a per-step hue drift, a flat chroma,
a lightness floor, and a step size) produce all 17 OKLCH steps as `calc()` expressions —
change a knob and every step moves together. This replaced Optics' `light-dark()` `hsl()`
pairs entirely; `color-scheme: dark` is set once and there is no light arm left to fall back
to.

- **`--op-color-neutral-l` is inert.** Optics defines it but its own steps never read it —
  they hardcode their lightness internally. Setting it does nothing.
- **Chroma is flat across the whole ramp** (a single knob, `--gp-n-chroma`), not tapered by
  step — OKLCH chroma is perceptually uniform, unlike the HSL saturation it replaced. See
  DESIGN.md's (retired) Tapered Chroma Rule for why the old taper existed and why OKLCH no
  longer needs it.

**What each token *means* visually — which color carries actions, which surface tone goes
where, which radius belongs to which surface size — is DESIGN.md's job, not this file's.**

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
  --_gp-playing-card-shadow: drop-shadow(0 3px 4px rgb(0 0 0 / 0.6));

  filter: var(--_gp-playing-card-shadow);
  transition: transform 0.2s ease-in-out;

  &.playing-card--playable:hover {
    transform: translateY(calc(-1 * var(--gp-card-hover-lift)));
  }

  img { width: 100%; }
}
```

(SCSS nesting is handled by PostCSS at Propshaft-serve time via the configured
`postcss-*` plugins — you write nested `&` selectors, not literal descendant CSS.)

## Adding a new styled component

1. Create `app/assets/stylesheets/components/<domain>/<block-name>.css`, picking the
   domain subfolder (`layout/`, `game/`, `lobby/`, `ui/`) by what the block is for.
2. Name the root class after the block; add elements/modifiers with `__`/`--`, nested
   under the block with `&`.
3. Color and shape it per **[DESIGN.md](../DESIGN.md)** — its Colors, Shapes, and
   Elevation sections decide which token to reach for. Mechanically: `--gp-*` first — color
   from `core/theme.css`, non-color primitives from `core/tokens/scale.css` — and `--_gp-*`
   for one-off private values inside the block. Reach for `--op-*` only when styling an
   Optics component class directly (its internal tokens, not ours).
4. That's it — Propshaft serves the file automatically via `:app`. No registration.

## Gotchas

- **Don't try to "fix" the empty `application.css` or the webpack CSS build.** CSS is not
  bundled here; those artifacts are unused. Styles load through Propshaft's `:app`.
- **Bump Optics in both places** (`vendor/optics/` and `package.json`) or they drift. Copy
  the new `dist/css` bundle over the vendored one and re-apply the `+` → `-` filename
  rename below.
- **A literal `+` in a vendored asset filename 404s.** Rack/Propshaft decodes it as a space
  in the request path. Optics' own bundle names (`optics+phosphor_icons.min.css`) have to be
  renamed (`optics-phosphor-icons.min.css`) once vendored locally — a CDN serves the
  original name fine, which is why this only surfaced when the CDN was dropped.
- **Keep one block per file.** Splitting a block across files or mixing blocks in one
  file defeats the file-per-component convention.
- Optics token names use scales like `--op-space-small … 3x-large` and
  `--op-font-small … 4x-large`; the `--gp-*` equivalents in `core/tokens/scale.css` use the
  same scale names.
- **The app is dark-only; there is no light mode to design against.** `color-scheme: dark`
  is set on `:root` and the neutral ramp has no `light-dark()` left in it — every value is
  a single OKLCH literal. This applies to *our* tokens; Optics' own not-yet-replaced
  components may still carry `light-dark()` internally for whatever they haven't been
  overridden for (e.g. the alert colors), so a screenshot should still be taken with
  `page.driver.with_playwright_page { |p| p.emulate_media(colorScheme: "dark") }` in a
  system spec to be certain.
- **Card face SVGs (`app/assets/images/dark_cards/*.svg`) carry their own theme-aware ink.**
  They're loaded via `<img>`, so page CSS (and `--op-*` tokens) can't reach inside them.
  The card *face* is a real CSS element (`.playing-card` / `.meld__card` background), but the
  rank/suit ink lives in the SVG. Black-suit cards (spades/clubs) bake a light-mode dark ink
  (`hsl(49 14% 20%)`, matching `--op-color-neutral-on-plus-five`) as the `fill` attribute plus
  an embedded `<style>@media (prefers-color-scheme: dark){text{fill:hsl(49 14% 80%)}}</style>`
  to flip it in dark mode; red-suit cards stay `#dc4d38` (legible on both faces). This tracks
  the **OS** color scheme only — the app has no manual theme toggle. If one is ever added
  (`[data-theme-mode]`), these `<img>` SVGs won't follow it and would need inlining +
  `currentColor`. The two card-back SVGs are decorative and left untouched.
- **`light-dark()` only accepts two `<color>` arguments — never a full shadow/border
  shorthand**, if one is ever reintroduced (our own tokens no longer use it at all — see
  the dark-only gotcha above — but Optics' own not-yet-replaced components might still).
  `light-dark(inset 0 2px 5px rgb(...), inset 0 2px 7px rgb(...))` or
  `light-dark(1px solid rgb(...), 1px solid rgb(...))` are invalid values: the whole
  `box-shadow`/`border` declaration silently drops to its initial value (`none`), with
  no console warning — it just looks like the style was never applied. Wrap `light-dark()`
  around only the color portion of each layer instead (e.g.
  `inset 0 2px 5px light-dark(rgb(...), rgb(...))`), or wrap the entire value if every
  argument truly is a plain color. Check `getComputedStyle(el).boxShadow`/`.border` when a
  shadow/border token seems to have no effect. This is how `--gp-lobby-tray-shadow`/
  `--gp-lobby-bar-shadow`/`--gp-lobby-tray-border` shipped invisibly broken for a full
  session before being caught — they're flat dark-only values now, not `light-dark()`.
- **CSS custom properties can't be read inside `@media` conditions.** Breakpoint values
  (e.g. `--gp-breakpoint-tablet` in `core/theme.css`) are documentation only — every
  `@media (max-width: …)` query using that breakpoint must repeat the literal pixel value
  and is kept in sync by hand.
- **Watch for duplicate `.sidebar` class names.** `application.html.slim` wraps the sidebar
  partial in a generic `div.sidebar`, and the partial's own root renders Optics'
  `nav.sidebar.sidebar--drawer`. A bare `.sidebar {}` selector matches *both* nested
  elements. To override an Optics `.sidebar--drawer`-scoped property, match
  `.sidebar.sidebar--drawer` (same specificity, loads later) — see `components/layout/sidebar.css`.
- **Go Fish / Crazy Eights' hand row never scrolls, and that's load-bearing.**
  `hand_controller.js` (Stimulus, `data-controller="hand"`) measures rendered card
  width via `ResizeObserver` and sets `--gp-card-overlap` (consumed by
  `.card-container`'s `margin-left` in `playing_card.css`) so cards overlap *more*
  than the 40% default whenever the hand is too wide to fit — never scroll, never
  shrink cards. This is why `.panel--hand .panel__body` is `overflow: visible`: the
  CSS Overflow spec forces `overflow-y` to compute as `auto` (clipping) whenever
  `overflow-x` is anything but `visible`, which would clip the
  `.playing-card--playable:hover` lift at the row instead of letting it rise over
  the header. Don't reintroduce `overflow-x: auto` here without re-solving that clip.
  **Rummy's hand-dock deliberately does the opposite** (see `hand_dock.css`): cards
  are fixed-size and packed with a flat gap, `.hand-fan` scrolls horizontally on
  overflow, and neither `data-controller="hand"` nor `--gp-card-overlap` computation
  is wired up — `.hand-fan`'s own `padding-top` (sized to `--gp-card-hover-lift`)
  reserves the lift headroom instead. Don't port one game's hand-overflow strategy
  to the other without re-reading why it was chosen.
