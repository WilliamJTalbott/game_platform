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
| `--gf-*`   | Project tokens, shared/reusable  | `core/theme.css` (or a block)     | `--gf-card-height-large`, `--gf-navbar-height` |
| `--_gf-*`  | Component-**private** tokens      | inside the block that uses them   | `--_gf-playing-card-shadow` |

**Rule of thumb (per project convention):** prefer an Optics `--op-*` token. When Optics
doesn't cover something and the value is shared across features, define a project token
(`--gf-…`) in `core/theme.css`. The leading underscore (`--_gf-…`) marks a token as
**local to one component** — do not reference it from another file.

`core/theme.css` also **re-skins Optics** by overriding Optics' primitive tokens. For
example, setting the primary hue/saturation/lightness remaps every color Optics derives
from primary:

```css
:root {
  --op-color-primary-h: 0;
  --op-color-primary-s: 79%;
  --op-color-primary-l: 38%;

  --gf-card-height-large: 250px;      /* project token */
  --gf-card-aspect-ratio: 5 / 7;
}
```

Tokens may also be scoped to a block rather than `:root` when only that block needs them
(e.g. `--gf-navbar-height` is declared on `.panel`, `--gf-feed-background` on
`.panel--feed`).

## BEM naming

Classes follow **`block__element--modifier`**, one block per file in `components/`:

- **Block** — the component root: `.playing-card`, `.panel`, `.stat-block`.
- **Element** — a part of the block, joined with `__`: `.stat-block__header`,
  `.panel__body`, `.feed__messages`.
- **Modifier** — a variant, joined with `--`: `.playing-card--playable`,
  `.panel--board`, `.game--crazy`.

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
