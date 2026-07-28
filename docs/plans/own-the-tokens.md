# Own the Tokens

**Goal: every value this app renders is declared in this repo, and components spend
*role names* instead of raw scale positions — so changing "the raised surface" or "the
comfortable pad" is one edit in one file, not a grep across thirty-nine stylesheets.**

Dropping Optics is the occasion, not the point. The point is the second half: today the
project has a beautifully designed *primitive* layer (a 19-step neutral ramp, hand-tuned
per the Tapered Chroma Rule) and almost no *role* layer, so components reach past the
vocabulary straight into the numbers. There are **52 direct references to raw ramp steps**
from `components/` against **39 to semantic tokens** — the primitives are winning, which
is backwards. Optics removal is what makes fixing that unavoidable rather than optional.

Status legend: 🟡 planned · 🟢 in progress · ✅ done

---

## 1. Decisions

Proposed below. The four marked **⚠️ your call** are genuine forks; the rest are
recommendations I'd implement unless you say otherwise.

| Question | Decision |
|---|---|
| Keep Optics at all? | **No.** Full removal, vendored-first so it's incremental |
| Vendor before deleting? | **Yes.** Copy `dist/css` into `vendor/optics/`, load locally, then delete file-by-file. Turns one big-bang into ~10 reviewable commits |
| Token prefix | **`--gp-*` everywhere.** `--op-*` disappears entirely. `--_gp-*` stays for component-private |
| Two tiers or three? | **Three, but only two are public.** Primitives (scale) → Roles (meaning) → component-private. Components may only spend Roles |
| Enforce tier discipline? | **Yes, by grep guard in `bin/ci`** — same shape as the existing `--op-color-` guard that already works |
| `1rem = 10px`? | **Keep it.** Optics' `html { font-size: 62.5% }` is load-bearing for all 330 token references. Our reset must restate it |
| Font family | **Keep Noto Sans/Serif**, loaded via our own `<link>` instead of through Optics' `@import` |
| Icons | **Keep Phosphor**, `@import`ed direct from unpkg. It was never Optics' — Optics just re-imported it |
| **Color space** | **OKLCH.** Chroma is perceptually uniform there — which is the entire reason the HSL taper had to exist |
| **Ramp direction** | **`plus` = darker, always.** One directional scale: `plus-8` near-black → `base` → `minus-8` white |
| **Ramp size** | **17 steps** (`plus-8` … `base` … `minus-8`). One step = **4.81 OKLCH points** |
| **Generation** | **Derived from 5 knobs**, at runtime. Still 17 emitted tokens — but each is a formula, not a typed color |
| **Light mode** | **Dropped.** `color-scheme: dark` on `:root`; ~50 light halves deleted. A light palette, if it ever ships, is a separate hand-picked set — never an inversion of this one |
| **Elevation order** | **Swapped.** Recessed is now *darker* than raised, matching dark-mode convention |
| **`on-*` pairs** | **Retired.** All 7 collapse onto 5 ramp positions; replaced by 3 ink roles |
| **Tapered Chroma Rule** | **Retired.** It was HSL compensation. Measured OKLCH chroma is already flat at ~0.010 |
| **Pair Rule** | **Retired.** No `light-dark()` survives in the ramp |
| Dead code | Delete the 5 unused Simple Form inputs, `IconHelper`/`IconBuilder`/`PhosphorIconBuilder`, and the `rolemodel-rails` gem |
| Type roles | Promote DESIGN.md's existing six (display/headline/title/body/label/micro) into real CSS tokens |
| Spacing roles | Keep the t-shirt scale *and* add ~5 rhythm roles on top. Not a replacement |
| Semantic-only guard | **Warn-only at first**, hard-fail once components are migrated |

**Out of scope:** a hand-picked light palette, redesigning any component's *appearance*
beyond the raised/recessed swap, the undesigned warning colors, and touching Slim markup
beyond class renames.

**Non-goal:** this migration is **visually neutral in dark mode except for two deliberate
changes** — the raised/recessed swap, and `base` moving to its correct position. Any other
visible difference is a bug.

---

## 2. What Optics actually supplies — the real inventory

One line hooks it up: `app/views/application/_head.html.slim:14`.

| Layer | Used by us | Optics source | Our replacement |
|---|---|---|---|
| Non-color tokens | **40 distinct, 330 refs** | `core/tokens/base_tokens.css` (345 ln) | ~70 ln, exact values in §6 |
| **Color tokens** | **zero** — all color is already `--gp-color-*` | `scale_color_tokens.css` (1,498 ln) | **nothing. Pure deletion** |
| Reset + `62.5%` | `html`/`body`/`button`/`label`/`a` defaults | `core/base.css` (94 ln) | ~35 ln |
| Layout shell | `.op-page`, `.op-page__main`, `.op-page__sidebar` | `core/layout.css` (150 ln) | ~45 ln grid |
| Utilities | `.op-stack`, `.gap-xs`, `.items-stretch` | `core/utilities.css` (601 ln) | ~12 ln |
| `.btn` ×6 modifiers | primary, secondary, medium, small, no-border, active | `button.css` (273 ln) | ~90 ln |
| `.sidebar` | + `__brand`, `__content`, `--drawer`, `--padded` | `sidebar.css` (141 ln) | ~70 ln (half already overridden) |
| `.table` | + `--sticky-header`, `--primary` | `table.css` (133 ln) | ~50 ln |
| Forms | `form-group`, `form-label`, `input`, `form-hint`, `form-error` | `form.css` (360 ln) | ~110 ln — **only `:select` + text are used** |
| `.dialog` / modal | 1 usage | `modal.css` (131 ln) | ~40 ln (`ui/dialog.css` exists) |
| `.icon` | sizing/weight wrapper around `ph-*` | `icon.css` (121 ln) | ~25 ln |
| `.divider` | 1 usage | `divider.css` (56 ln) | ~8 ln |
| `.alert` | 1 usage | `alert.css` (171 ln) | ~30 ln |
| Fonts + Phosphor | Noto Sans/Serif, `ph ph-*` | `@import`s to Google/unpkg | our own `<link>`s |

**~2,000 lines of Optics replaced by ~600 of ours** — because we use a thin slice of a
general-purpose system. `.card`, `.avatar`, `.badge`, `.tag`, `.tab`, `.tooltip`,
`.breadcrumbs`, `.pagination`, `.navbar`, `.accordion`, `.spinner`, `.switch`,
`.segmented-control`, `.tom-select` are all shipped and **all unused**.

### Already ours — don't touch
`.panel`, `.card-container`, `.game-card`, `.hand-card`, `.felt`, `.meld`, `.pile`,
`.message`, `.scoreboard`, `.opponent-strip`, `.waiting-room`, `.leaderboard`,
`.stat-block`, `.hand-dock`, `.hand-fan`, `.bubble-stack`, `.phase-stepper`,
`.player-dropdown`, `.popup`, `.banner`, `.menu`, `.room`, `.lobby`, `.info-card`,
`.login`, `.profile`, `.end-of-game-modal`. That's 2,055 lines of CSS you already own.

---

## 3. The token architecture

This is the part worth getting right; the Optics deletion is mechanical by comparison.

### Three tiers, one direction

```
core/tokens/scale.css   ─┐  Tier 1 · PRIMITIVES  · "what values exist"
core/tokens/palette.css ─┘  named by position:  --gp-space-medium, --gp-color-neutral-plus-eight
                             │
                             ▼   (only roles.css may read primitives)
core/tokens/roles.css       Tier 2 · ROLES       · "what things mean"
                             named by job:  --gp-surface-raised, --gp-pad, --gp-type-title
                             │
                             ▼   (components may ONLY read roles)
components/**/*.css         Tier 3 · PRIVATE     · --_gp-* , local to one block
```

**You already invented this pattern.** The Optics bridge in `theme.css` is exactly a
one-directional indirection layer with a grep guard behind it, and it works. This
generalizes it — the bridge stops pointing outward at a vendor and starts pointing inward
at your own roles.

### Tier 1a — non-color primitives

Straight rename of what exists. No new thinking, no value changes:

| From | To |
|---|---|
| `--op-space-*` | `--gp-space-*` (same 10-step scale, same values) |
| `--op-font-*` | `--gp-font-*` |
| `--op-font-weight-*` | `--gp-weight-*` |
| `--op-radius-*` | `--gp-radius-*` |
| `--op-border-width*` | `--gp-border-width*` |
| `--op-shadow-*` | `--gp-shadow-*` |

### Tier 1b — the neutral ramp, generated

> **⚠️ SUPERSEDED — this section records the original design, not the current one.**
> The ramp shipped as planned and was then restructured twice. It is now anchored on
> `--gp-n-l-base` (the room) rather than a floor, runs `plus-2`…`minus-10` (13 steps, not 17),
> and **white and black are no longer ramp steps** — they are named absolutes (`--gp-white`,
> `--gp-black`) alongside a three-step warmed-white family (`--gp-w-1..3`) that all ink comes
> from. `--gp-n-l-floor` no longer exists, and `--gp-n-l-step` is now a free knob because
> nothing depends on where the ramp ends. Chroma is flat except a two-step cellar taper.
> **The authority is `core/theme.css` + DESIGN.md's Neutral section; read those, not this.**
> Kept for the reasoning behind OKLCH, the knob-driven approach, and the retired HSL taper.

Five knobs replace twenty hand-typed colors. `plus` is darker, always:

```css
:root {
  color-scheme: dark;                /* required — native controls follow this */

  --gp-n-hue:        67.5;   /* the room's hue. ONE edit re-hues every neutral   */
  --gp-n-hue-drift:  0.8;    /* degrees redder per step toward the floor         */
  --gp-n-chroma:     0.014;  /* flat in OKLCH — no taper needed                  */
  --gp-n-l-floor:    23.1%;  /* plus-8                                           */
  --gp-n-l-step:     4.81%;  /* one step                                         */
}
```

Each of the 17 steps is emitted as a named token whose value is a `calc()` over those
knobs — CSS has no cross-browser `@function` yet, and Propshaft gives us no build step, so
the lines are still written out. The difference is that they are *derived*: changing
`--gp-n-hue` moves all seventeen.

**"Redder the darker" is `--gp-n-hue-drift`.** At 0.8 the floor sits at 55.5° (red-orange)
and white at 67.5° (amber). Set it to 0 for a hue-flat ramp.

The generated ramp reproduces today's hand-picked values where they carry load:

| Step | L | Replaces | Δ |
|---|---|---|---|
| `plus-8` | 23.1% | `plus-max` — page floor, 11 uses | **0.0** |
| `plus-7` | 27.9% | *recessed* — modals, stats, scoreboard (was `plus-seven`) | swap |
| `plus-6` | 32.7% | *raised* — sidebar, panel headers, hand dock (was `plus-eight`) | swap |
| `plus-5` | 37.5% | `plus-five` — card face + border, 21 uses | **0.2** |
| `base` | 61.6% | `minus-four` → `--gp-color-muted`, 20 uses | **0.5** |
| `minus-8` | 100% | `minus-max` — ink | **0.0** |

Three things this fixes for free:

1. **`base` lands at its true midpoint.** Today it's at 42.2% — *darker* than both
   `plus-one` (50.4%) and `minus-one` (47.9%), i.e. running backwards through its own
   neighbours. DESIGN.md claims "base sits between them"; it does not.
2. **The seam stops interleaving.** Today `plus-two` 46.8 → `minus-one` 47.9 → `plus-one`
   50.4 → `minus-two` 51.5. One directional scale can't overlap itself.
3. **Relative stepping becomes arithmetic.** An outline one step lighter than its fill is
   `plus-5` on `plus-6` — and one step (4.81 pts) sits squarely between this app's two
   real border deltas today (the sidebar line at 4.1, `--gp-color-border` at 6.9).

**Why the raised/recessed swap.** `plus-eight` (raised) and `plus-seven` (recessed) are
**1.0 OKLCH point apart** — the same lightness. They only read as distinct because
`plus-eight` carries 2× the chroma (0.0232 vs 0.0110), so today's "elevation" is really a
*warmth* difference wearing a lightness name. Under flat chroma they must separate; we
took the opportunity to put them in convention order (nearer the viewer = lighter), which
also makes the Lamp Rule coherent — surfaces closer to the light are brighter.

### Tier 2 — roles

**Surfaces** — six names over seventeen steps. Components spend these, never an index:

```css
--gp-surface-floor:    var(--gp-n-plus-8);   /* the page itself      */
--gp-surface-recessed: var(--gp-n-plus-7);   /* sunk in — modals, stats grid, scoreboard */
--gp-surface-raised:   var(--gp-n-plus-6);   /* sidebar, panel headers, hand dock        */
--gp-surface-card:     var(--gp-n-plus-5);   /* card faces, meld chips  */
```

**Ink** — the 7 coupled `on-*` pairs collapse onto 5 ramp positions, so the whole
surface-coupled vocabulary retires into three names:

```css
--gp-ink:       var(--gp-n-minus-8);  /* was on-plus-max, on-base            */
--gp-ink-dim:   var(--gp-n-minus-6);  /* was on-plus-eight, on-plus-five-alt */
--gp-ink-muted: var(--gp-n-base);     /* was on-plus-eight-alt + --gp-color-muted (20 uses) */
```

`--gp-color-neutral-on-plus-eight-alt` — 36 characters, coupled to a step number that just
moved — becomes `--gp-ink-muted`.

**Lines** — `--gp-color-border` already exists and is used 15×. Keep it, add `-strong`.

### Tier 2 — roles (the new work, and the actual goal)

Every role below is backed by a value already in use somewhere — this is *naming what's
already there*, not inventing a design.

**Surfaces** — DESIGN.md's Elevation section already speaks this language ("recessed
tray", "raised bar", "the room"). Right now those concepts have no tokens, so
`--gp-color-neutral-plus-eight` appears in 8 files each meaning "raised":

```css
--gp-surface-floor:    var(--gp-color-neutral-plus-max);    /* the page itself */
--gp-surface-recessed: var(--gp-color-neutral-plus-ten);    /* trays sunk into a surface */
--gp-surface-raised:   var(--gp-color-neutral-plus-eight);  /* sidebar, panel headers, the lit shade */
--gp-surface-lifted:   var(--gp-color-neutral-plus-seven);  /* bars sitting on a tray */
--gp-surface-card:     var(--gp-color-neutral-plus-five);   /* card faces */
```

**Ink** — the `-on-*` contrast pairs already exist but are spelled as surface names, which
couples the ink to a ramp step. Re-point them at the surface roles:

```css
--gp-ink:              var(--gp-color-neutral-on-plus-eight);
--gp-ink-muted:        var(--gp-color-muted);
--gp-ink-on-raised:    var(--gp-color-neutral-on-plus-eight);
--gp-ink-on-raised-alt: var(--gp-color-neutral-on-plus-eight-alt);
--gp-ink-on-accent:    var(--gp-color-on-accent);
--gp-ink-accent:       var(--gp-color-accent-text);
```

**Lines** — `--gp-color-border` already exists and is used 15×. Keep it, add `-strong`.

**Depth** — the four `--gp-lobby-*-shadow` tokens are already role tokens wearing a
page's name. The Matched-Pair Rule says the tray/bar shadows ship together; the *names*
should say so too, and melds already reuse them off-lobby:

```css
--gp-elevation-tray:     /* was --gp-lobby-tray-shadow */
--gp-elevation-bar:      /* was --gp-lobby-bar-shadow */
--gp-elevation-bar-live: /* was --gp-lobby-bar-shadow-live */
--gp-elevation-tray-line:/* was --gp-lobby-tray-border */
```

**Rhythm** — the highest-leverage reuse win. `--op-space-medium` (39×) and
`--op-space-small` (30×) are doing many unrelated jobs. The scale stays; roles sit on top:

```css
--gp-pad-tight:  var(--gp-space-x-small);   /* chips, dense rows */
--gp-pad:        var(--gp-space-medium);    /* the default component pad */
--gp-pad-roomy:  var(--gp-space-x-large);   /* page shells — DESIGN.md's 24px/28px lobby */
--gp-gutter:     var(--gp-space-medium);    /* between siblings in a row */
--gp-stack-gap:  var(--gp-space-small);     /* between stacked blocks */
```

**Type** — DESIGN.md's frontmatter *already declares six named roles*
(display/headline/title/body/label/micro) with size + weight + letter-spacing each. They
exist as design intent but have no CSS. Promote them:

```css
--gp-type-title-size:   var(--gp-font-x-large);
--gp-type-title-weight: var(--gp-weight-semi-bold);
--gp-type-label-size:   var(--gp-font-x-small);
--gp-type-label-weight: var(--gp-weight-bold);
--gp-type-label-tracking: var(--gp-letter-spacing-label);
/* …display, headline, body, micro */
```

That alone collapses the 14 scattered `--op-font-weight-semi-bold` +
11 `--op-font-small` pairings into one name per role.

### The rule that makes it stick

> **Components spend roles. Only `roles.css` reads primitives.**
> If a component needs a raw ramp step, a role is missing — add the role.

Enforced in `bin/ci`, mirroring the guard that already exists for `--op-color-`:

```sh
# no ramp index or raw scale may be referenced outside the roles layer
grep -rn -- '--gp-\(n-\(plus\|minus\|base\)\|space-\|font-\|radius-\|shadow-\|weight-\)' \
  app/assets/stylesheets/components/ && exit 1
# no Optics token may survive anywhere
grep -rn -- '--op-' app/assets/stylesheets/ app/views/ && exit 1
# the ramp is generated: no literal color outside palette.css
grep -rn -E '#[0-9a-fA-F]{3,8}|rgb\(|hsl\(|oklch\(' app/assets/stylesheets/components/ && exit 1
# light-dark() is retired
grep -rn -- 'light-dark(' app/assets/stylesheets/ && exit 1
```

**Escape hatch, deliberately:** the Tapered Chroma Rule means some components genuinely
need one specific step (the felt, the card faces). Those get a role even if only one
component spends it — a role with one consumer is still a name, and it's where the *next*
consumer will look. Run the guard warn-only through Phase 2, hard-fail from Phase 3.

---

## 4. Phases

Each phase ends green (`bundle exec rspec`, `bin/rubocop`, `bin/ci`) and is one commit.

### Phase 0 — Vendor and freeze ✅
1. Copied `node_modules/@rolemodel/optics/dist/css/optics+phosphor_icons.min.css` →
   `vendor/optics/` — **only the bundle we actually load**, not the full `dist/css`
   (feather/lucide/tabler/material/no-icon variants and the unbundled `core`/`components`/
   `addons` source trees are unused; keeping only the self-contained bundle cut it from
   2.7MB to 140KB). Registered `vendor/optics` on `config.assets.paths`
   (`config/initializers/assets.rb`) so Propshaft serves it.
2. Swapped the CDN `stylesheet_link_tag` for the local copy. **Zero visual change**,
   confirmed via `spec/system/ramp_preview_spec.rb`.
   **Gotcha:** the file had to be renamed `optics+phosphor_icons.min.css` →
   `optics-phosphor-icons.min.css` — Rack/Propshaft decodes a literal `+` in a request
   path as a space, so the CDN's filename 404s once served locally even though jsdelivr
   handles it fine. Any future re-vendor of an Optics bundle needs the same rename.
3. **Not done as written** — bundling already merged `core/tokens/scale_color_tokens.css`
   into the single minified file, so there is no separate file to delete. The dead color
   tokens live on inside the bundle; deleting them would mean hand-editing minified CSS,
   which isn't worth the fragility for ~1,500 lines that cost nothing at runtime. Revisit
   in Phase 3 if the bundle is ever unbundled into its component files.
4. Baseline captured via the existing `ramp_preview_spec.rb` (8 of the 11 pages from §7;
   sign-up/end-of-game-modal/profile weren't added — out of scope for this pass).

*Vendoring done, CDN gone, safety net in place. Color-token deletion deferred (see above).*

### Phase 1a — Own the non-color primitives ✅
1. Wrote `core/tokens/scale.css` with the 38 real values (§6, transcribed exactly;
   z-index tokens excluded — they're a separate category not covered by this table and
   the app's one use already has a safe fallback).
2. Mechanical rename of all `--op-*` non-color refs (space/font/weight/radius/
   border-width/shadow/letter-spacing/size-unit/input-height) → `--gp-*` across the 32
   component files that used them. `--op-border-all` (a composite Optics-internal token,
   used correctly as a box-shadow value in `button.css`) and `--op-z-index-modal`
   (fallback default, not one of the 6 primitive categories) were deliberately left alone.
3. **Not done** — same reason as Phase 0.3: `base_tokens.css` isn't a separate file in the
   vendored bundle to delete.
4. The bridge (theme.css §6, non-color overrides) is unchanged: it still feeds
   `--op-border-width` / `--op-border-width-large` / `--op-radius-2x-large` from our
   values so Optics' *own* rendered components (button, sidebar, form) keep matching —
   this was additive, not inverted, since Optics' internal CSS still reads its own `--op-*`
   copies internally regardless of our rename.

*Every non-color value our own components use is declared in-repo. Screenshots unchanged
(verified). `bundle exec rspec` shows the same 23 pre-existing failures as before this
session's changes (login-redirect/leaderboard issues unrelated to CSS) — no new ones.*

### Phase 1b — Generate the ramp ✅ *(shipped, then restructured — see the note in §3)*
1. Write `core/tokens/palette.css`: the 5 knobs + 17 derived steps + the accents.
   Accents (coral, felt, lobby slate, card ink) stay **hand-picked** — the No-Ramp Rule
   still holds; only the *neutral* ramp is generated.
2. Set `color-scheme: dark` on `:root`. Strip `light-dark()` from every neutral; take the
   dark arm. ~50 light values are deleted.
3. Re-point the 4 shadow composites and the page accents to their dark arms.
4. Re-screenshot. **Expect exactly two visible changes**: raised/recessed swapped, and
   `base` correctly positioned. Anything else is a regression — chase it.

*Ends: one knob re-hues the room. ~half a day, mostly verification.*

### Phase 2 — Introduce roles ✅
1. Wrote `core/tokens/roles.css`: **6 surface roles** (`floor`/`recessed`/`raised`/`card`/
   `outline`/`dim`, plus a `--gp-wash-lamp` for the page gradient, which was deliberately off
   the surface scale — since removed along with the gradients themselves, see The Lamp Rule —
   retired) and **5 ink roles**, not 3 — measuring actual usage found 5 distinct
   contrast-pair values in play (`--gp-ink`, `--gp-ink-on-raised`, `--gp-ink-muted`,
   `--gp-ink-on-card`, `--gp-ink-dim`), not the 3 originally guessed in §3. Lines and muted
   text keep their existing names (`--gp-color-border`, `--gp-color-muted`) — already
   role-shaped, no rename needed.
2. Migrated all 23 component files that referenced a raw ramp step (not 39 — the other 16
   never did). Values one-off enough to not warrant a shared role (a banner label
   background, a hand-card focus outline, a scoreboard-only ink, game-card's already-private
   muted variable) became `--_gp-*` component-private tokens instead of roles, per the
   plan's own escape-hatch guidance.
3. Turned the guard on, warn-only, in `bin/ci` (`config/ci.rb`) — no such guard existed to
   "mirror" as the plan assumed; this is the first one. It greps for raw `--gp-n-*` or
   `--op-color-*` outside a `--_gp-*` private-token declaration.
4. Deleted the "Legacy aliases" block from `theme.css` now that nothing references it.
5. Re-screenshot: **empty diff**, confirmed via `spec/system/ramp_preview_spec.rb` and a
   full `rspec` run (same pre-existing, unrelated failures as before this phase).

*Ends: the actual goal. Everything after this is deletion. ~1 day, the most careful one.*

### Phase 3 — Replace the components 🟡
One commit per component, smallest first — delete the vendored file, write ours in
`components/ui/`, re-screenshot the pages that use it:

`divider` → `icon` → `alert` → `table` → `dialog` → `button` → `sidebar` → `form`

`button`, `sidebar`, and `dialog` are the easy ones despite their size — we already
override the visible parts. `form` is the real work, but only `:select` and text inputs
ship, so ~110 lines covers it.

*Ends: `vendor/optics/` holds only base + layout + utilities. ~1.5 days.*

### Phase 4 — Cut the cord 🟡
1. `core/reset.css` — ~35 lines. **Must restate `html { font-size: 62.5% }`** (§5).
2. `.op-page` grid → `components/layout/page.css`. Rename `.op-page` → `.page`,
   `.op-page__main` → `.page__main`, `.op-page__sidebar` → `.page__sidebar` across the
   3 layouts and `_sidebar.html.slim`.
3. `.op-stack` / `.gap-xs` / `.items-stretch` → a 12-line `core/utilities.css`.
4. Own `<link>`s for Noto Sans/Serif and Phosphor in `_head.html.slim`.
5. Delete `vendor/optics/`, drop `@rolemodel/optics` from `package.json`, `yarn install`.

*Ends: zero Optics. ~half a day.*

### Phase 5 — Sweep 🟡
- Delete `app/inputs/{switch_checkbox,segmented_control,tailored_select,collection_check_boxes,grouped_collection_select,collection_select}_input.rb` — **verify each against
  `spec/support/helpers/select_helper.rb`, which references `tailored-select`**, then
  prune the helper too if dead.
- Delete `app/helpers/icon_helper.rb` + `app/icon_builders/` — never called from any view
  (views hand-write `i.ph.ph-*`).
- Drop `gem "rolemodel-rails"` — generators only, zero runtime reach.
- Fix the four bugs in §8.
- Rewrite `docs/frontend.md` §"Token tiers" for the new scheme; update DESIGN.md's stale
  frontmatter (§8); add a `docs/handoffs/` entry.

---

## 5. The one thing that will bite

**`html { font-size: 62.5% }`.** Optics sets it in `core/base.css`; it makes `1rem = 10px`,
which is why `--op-font-medium: 1.6rem` means 16px. Every one of the 330 token references
and every raw `rem` in your 2,055 lines of CSS assumes it.

Delete Optics' base without restating this and **every rem-based dimension in the app
grows 60% at once** — and it'll look like a hundred unrelated layout bugs, not one root
cause. Write `core/reset.css` in Phase 0, not Phase 4, so it's already in place and proven
before the thing it replaces goes away.

Secondary risks, all lower:
- `html { overflow: hidden }` / `body { overflow: auto }` — Optics' comment says it stops
  "flash messages and panels from causing overflow". Carry it over verbatim.
- `.op-page__sidebar` is `position: fixed` with a `--op-z-index-sidebar` that we never
  define. Check the stacking order against `end_of_game_modal.css`'s `z-index: 1000`.
- Optics ships `light-dark()` pairs throughout. Our reset must set `color-scheme` on
  `:root` or every pair collapses to its light value.

---

## 6. Exact values to transcribe

Verified against `node_modules/@rolemodel/optics/dist/css/core/tokens/base_tokens.css`.
Use literal px in comments as now; keep `calc()` off the scale unit if you prefer flat values.

```
space:  scale-unit 1rem · 3x-small 2px · 2x-small 4px · x-small 8px · small 12px
        medium 16px · large 20px · x-large 24px · 2x-large 28px · 3x-large 40px
size-unit: 0.4rem (4px)
font:   2x-small 10px · x-small 12px · small 14px · medium 16px · large 18px
        x-large 20px · 2x-large 24px · 4x-large 32px
weight: normal 400 · medium 500 · semi-bold 600 · bold 700
letter-spacing-label: 0.04rem
radius: small 2px · medium 4px · large 8px · x-large 12px · 2x-large 20px* · pill 9999px
border-width: 1.8px* · large 3px* · x-large 4px
shadow-small:   0 1px 2px hsl(0deg 0% 0% / 3%),  0 2px 6px hsl(0deg 0% 0% / 15%)
shadow-medium:  0 4px 8px hsl(0deg 0% 0% / 15%), 0 1px 3px hsl(0deg 0% 0% / 3%)
shadow-x-large: 0 8px 12px hsl(0deg 0% 0% / 15%), 0 4px 4px hsl(0deg 0% 0% / 3%)
line-height-densest: 1
input-height-large: 4rem (40px)
```
`*` = already overridden by us; take **our** value, not Optics'.

**Do not transcribe `--op-border-all`** (`0 0 0 var(--op-border-width)`). It is a
*box-shadow* value, not a border value — see §8.

---

## 7. Verification

Per AGENTS.md: screenshot system specs, dark mode, `emulate_media(colorScheme: "dark")`
**before `visit`** (emulating after load leaves computed values stale).

One throwaway spec, `spec/system/token_migration_baseline_spec.rb`, driving all 11 pages:

| Page | Route | Covers |
|---|---|---|
| Login | `/session/new` | form, inputs, `.login` |
| Sign up | `/users/new` | form-group, labels, errors |
| Games index | `/games` | tray/bar elevation pair, lobby slate, `.game-card` |
| Waiting room | `/games/:id` (unstarted) | `.waiting-room`, host CTA |
| Go Fish | `/games/:id` | felt, panels, `:select` inputs, hand fan |
| Crazy Eights | `/games/:id` | same + suit picker |
| Rummy | `/games/:id` | hand dock, melds, phase stepper, lock icon |
| End of game | modal state | `.dialog`, z-index |
| Stats | `/stats` | stat blocks, `.btn.btn--medium` row, icons |
| History | `/history` | `.table` |
| Leaderboard | `/leaderboard` | `.table--sticky-header`, `--primary`, own-row highlight |
| Rules | `/rules` | long-form type scale |
| Profile | `/users/:id/edit` | country/state selects (the only dynamic form) |

Capture at Phase 0, re-capture at the end of every phase, Read and compare. **Delete the
spec at the end** — it's scaffolding, it asserts nothing.

The sidebar appears on all of them, so it's continuously covered for free.

---

## 7b. The bridge was incomplete — measured, not guessed

Found while checking why the sidebar looked off. The bridge covered every neutral
*surface* step but none of the **contrast pairs**, so Optics-rendered text was never ours:

| Token Optics reads | Was | Now |
|---|---|---|
| `--op-color-neutral-on-plus-eight` | `hsl(30 8% 88%)` — sidebar text | `--gp-n-minus-6` |
| `--op-color-on-background` | `hsl(30 8% 88%)` — body text | `--gp-color-on-background` |
| `--op-color-neutral-on-plus-max` / `-on-plus-seven` | Optics' own | `--gp-n-minus-8` / `--gp-n-minus-5` |
| `--op-color-primary-original` | `hsl(16 70% 40%)` — **every un-overridden `<a>`** | `--gp-color-accent` |

The link one was the visible bug: `rgb(173,69,31)` vs our `rgb(240,120,76)`. It hit the
login page's "Sign up" / "Forgot password?" and a history header link — a muddy dark coral
where the accent belonged. Exactly the "ramp-darkened coral reads as muddy copper" failure
the No-Ramp Rule warns about, arriving through a token nobody had bridged.

Also fixed: `sidebar.css`'s `--_gp-sidebar-line` was a hand-written `hsl(30 23% 22%)`. It is
now `--gp-n-plus-5` — literally one step lighter than the `plus-6` surface it sits on.

**Still unbridged, deliberately:** the whole `--op-color-alerts-*` family (44 tokens).
`--op-color-alerts-danger-base` is `hsl(0 99% 40%)`, pure Optics red, and it reaches Simple
Form's validation error states. It belongs with the undesigned warning corner (§8) — pick
real values for both at once rather than bridging a palette nobody chose.

**Generalisable lesson for Phase 3:** a bridge that covers surfaces but not their contrast
pairs looks correct in a screenshot and is wrong in the DOM. When each Optics component is
replaced, diff the tokens it reads against the bridge — `grep -ohE '\-\-op-color-[a-z0-9-]+'`
on the component, `comm -23` against the bridge list.

## 8. Bugs found while scoping

Fix in Phase 5 (or now — all are independent of the migration):

1. **`components/lobby/leaderboard.css:45`** — `border-bottom: var(--op-border-all) var(--gp-color-border)` expands to `border-bottom: 0 0 0 1px <color>`, an invalid
   `border-bottom` shorthand. **The rule is silently dropped; leaderboard rows have no
   separator today.** `--op-border-all` is a box-shadow value (`button.css` uses it
   correctly, as `box-shadow: inset var(--op-border-all) …`).
2. **`components/game/hand_card.css:68`** — `font-size: var(--gp-font-size-x-large)`. That
   token does not exist; the correct name is `--gp-font-x-large`. Declaration is invalid,
   font-size silently inherits. **Still open** — the typo survived the `--op-*` → `--gp-*`
   rename intact.
3. ~~**`core/theme.css:~150`** — `--gp-color-accent-secondary` is a `color-mix()`~~ ✅ done;
   resolved to the literal `#4b2e22` it produced. **But it was not the only one:**
   `components/lobby/game_card.css:45` still mixes coral into `--gp-surface-floor` for its
   live-row tint. That one is still open.
4. **`app/icon_builders/icon_builder.rb:52`** — emits `var(--op-color-#{color}-base)`
   inline, violating the bridge rule. Currently unreachable (helper never called), and
   Phase 5 deletes the file — but if you keep the builders, fix it.

Also: **DESIGN.md's YAML frontmatter is stale.** Its colors are on hue **41** at 14–26%
saturation; `theme.css` has moved to hue **30** at 8–23% with the Tapered Chroma pairing.
The frontmatter is the machine-readable contract, so it should be regenerated from
`palette.css` at the end of Phase 1 — and probably wants a note saying which file wins.

---

## 9. Cost

| Phase | Effort |
|---|---|
| 0 · Vendor & freeze | 0.5 day |
| 1a · Own non-color primitives | 0.5 day |
| 1b · Generate the ramp | 0.5 day |
| 2 · Roles + migrate components | 1 day |
| 3 · Replace components | 1.5 days |
| 4 · Cut the cord | 0.5 day |
| 5 · Sweep & docs | 0.5 day |
| **Total** | **~5 days** |

### DESIGN.md rules that change

Three of the eight named colour rules are retired by these decisions and must be rewritten
in Phase 5 — leaving them in place would be worse than having no rules, since they'd
describe a system that no longer exists:

| Rule | Fate |
|---|---|
| **Tapered Chroma** | **Retired.** It was HSL compensation; OKLCH chroma is flat at ~0.010 already. Replace with a one-line note that chroma is a single knob |
| **Pair** | **Retired.** No `light-dark()` survives. Replace with: every neutral is a ramp index; every accent is hand-picked and dark-only |
| **Dark-First** | **Rewrite.** Dark is no longer "the designed scheme, light is incidental" — light mode is *gone*. Say so plainly |
| **No-Ramp** | **Keep, re-aim.** Still true, but the target changes: never derive an *accent* from the neutral ramp. Accents stay hand-picked |
| **Owned Color / One Page One Color / One Signal / Lamp** | Unchanged |

Also in Phase 5: DESIGN.md's Colors section is a full revision stale (hue 41 vs 30, four
named surfaces all wrong, `plus-nine`/`plus-ten` undocumented — see §8). It should be
regenerated from `palette.css` rather than patched.

Phases 0–2 deliver the goal you actually asked for — a token system you own, with roles
components can reuse. Phases 3–5 are the Optics deletion, and they're **stoppable**: if
you stop after Phase 2 you have owned tokens, a role layer, a 1,500-line-lighter payload,
and a vendored Optics with no CDN dependency. That's a legitimate resting place.
