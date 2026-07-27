---
name: Game Platform
description: A dark-first, lamp-lit card room for playing turn-based card games live with friends.
colors:
  accent-coral: "hsl(16 85% 62%)"
  accent-coral-deep: "hsl(16 90% 42%)"
  accent-coral-tint: "color-mix(in srgb, hsl(16 85% 62%) 20%, hsl(41 14% 100%))"
  on-accent: "#ffffff"
  warm-neutral-page: "light-dark(hsl(41 14% 100%), hsl(41 26% 13%))"
  warm-neutral-raised: "light-dark(hsl(41 14% 98%), hsl(41 21% 17%))"
  warm-neutral-recessed: "light-dark(hsl(41 14% 96%), hsl(41 14% 21%))"
  warm-neutral-card-face: "light-dark(hsl(41 14% 90%), hsl(41 10% 27%))"
  border: "light-dark(hsl(41 14% 90%), hsl(41 10% 27%))"
  ink: "light-dark(hsl(41 14% 0%), hsl(41 14% 100%))"
  muted-text: "light-dark(hsl(41 14% 24%), hsl(41 14% 52%))"
  felt-green: "light-dark(#bfd2c6, #1b2a22)"
  felt-green-raised: "light-dark(#e6f5ea, #274035)"
  felt-green-translucent: "light-dark(rgb(255 255 255 / 0.55), rgb(255 255 255 / 0.05))"
  lobby-slate: "light-dark(#eef1f5, hsl(215 14% 26%))"
  card-face-selected: "hsl(16 45% 20%)"
  card-ink-red: "#dc4d38"
  overlay: "rgb(0 0 0 / 0.5)"
typography:
  display:
    fontFamily: "Noto Sans, sans-serif"
    fontSize: "3.2rem"
    fontWeight: 600
    lineHeight: "normal"
  headline:
    fontFamily: "Noto Sans, sans-serif"
    fontSize: "2.4rem"
    fontWeight: 700
    lineHeight: "normal"
  title:
    fontFamily: "Noto Sans, sans-serif"
    fontSize: "1.8rem"
    fontWeight: 600
    lineHeight: "normal"
  body:
    fontFamily: "Noto Sans, sans-serif"
    fontSize: "1.6rem"
    fontWeight: 400
    lineHeight: "normal"
  label:
    fontFamily: "Noto Sans, sans-serif"
    fontSize: "1.2rem"
    fontWeight: 700
    letterSpacing: "0.07em"
  micro:
    fontFamily: "Noto Sans, sans-serif"
    fontSize: "1.0rem"
    fontWeight: 700
    letterSpacing: "0.03em"
rounded:
  small: "2px"
  medium: "4px"
  large: "8px"
  x-large: "12px"
  2x-large: "20px"
  pill: "9999px"
spacing:
  3x-small: "2px"
  2x-small: "4px"
  x-small: "8px"
  small: "12px"
  medium: "16px"
  large: "20px"
  x-large: "24px"
  2x-large: "28px"
  3x-large: "40px"
  4x-large: "80px"
components:
  button-primary:
    backgroundColor: "{colors.accent-coral}"
    textColor: "{colors.on-accent}"
    rounded: "{rounded.medium}"
    padding: "8px 16px"
  cta-view:
    backgroundColor: "{colors.accent-coral}"
    textColor: "{colors.on-accent}"
    rounded: "{rounded.large}"
    padding: "8px 12px"
  cta-join:
    backgroundColor: "{colors.accent-coral-tint}"
    textColor: "{colors.accent-coral-deep}"
    rounded: "{rounded.large}"
    padding: "8px 12px"
  cta-full:
    backgroundColor: "transparent"
    textColor: "{colors.muted-text}"
    rounded: "{rounded.large}"
    padding: "8px 12px"
  turn-badge:
    backgroundColor: "{colors.accent-coral-tint}"
    textColor: "{colors.accent-coral-deep}"
    typography: "{typography.micro}"
    rounded: "{rounded.pill}"
    padding: "2px 8px"
  lobby-tray:
    backgroundColor: "{colors.warm-neutral-raised}"
    rounded: "{rounded.2x-large}"
    padding: "16px 20px"
  game-bar:
    backgroundColor: "{colors.lobby-slate}"
    rounded: "{rounded.x-large}"
    padding: "12px 16px"
  felt:
    backgroundColor: "{colors.felt-green}"
    rounded: "{rounded.2x-large}"
    padding: "16px"
  felt-zone:
    backgroundColor: "{colors.felt-green-raised}"
    rounded: "{rounded.x-large}"
    padding: "12px 16px"
  playing-card:
    backgroundColor: "{colors.warm-neutral-card-face}"
    rounded: "{rounded.medium}"
  playing-card-selected:
    backgroundColor: "{colors.card-face-selected}"
    rounded: "{rounded.medium}"
  feed-bubble:
    backgroundColor: "{colors.warm-neutral-page}"
    textColor: "{colors.ink}"
    typography: "{typography.label}"
    rounded: "{rounded.x-large}"
    padding: "12px 16px"
  feed-bubble-directive:
    backgroundColor: "{colors.accent-coral}"
    textColor: "{colors.on-accent}"
    rounded: "{rounded.x-large}"
    padding: "12px 16px"
---

# Design System: Game Platform

## Overview

**Creative North Star: "The Warm Card Room"**

A lamp-lit room in a warm house, late in the evening — and **the lights are low**. This is
a dark-first system: dark is the scheme that gets designed and judged. The chrome is the
room itself, an amber-tinged linen gray that never announces itself, because it is walls
and furniture, not the event. Coral is the single lit signal in that room, everywhere in
the house: it means *act* — your turn, this button, this link, this name. Nothing else
glows.

**The lamp is literal.** One warm pool of light sits high and to the left of the main column
and falls off into the corners, and the neutral ramp's saturation climbs as its surfaces
darken so the low light actually reads as warm. Both exist because "lights low" and "lights
off" are the same picture without them: flat fills at 8% lightness and 14% saturation
rendered a five-level channel spread — a warm room that was true on paper and neutral black
on screen. See The Lamp Rule and The Tapered Chroma Rule.

**Each major room may be its own color.** Coral is the constant, site-wide; on top of it, a
major page may claim one accent of its own so that arriving there feels like arriving
somewhere. The game page claimed green and became a felt table. The games index claimed a
cool slate and became the hallway. Neither color is allowed anywhere else, and neither is
the whole list — the next page that earns one picks its own. Pages that don't claim a color
are not unfinished; warm chrome plus coral is a complete page.

The room is **physical, not flat**. Trays are recessed into surfaces and bars sit raised
on top of them; cards cast real shadows and lift when you touch them; the felt has
brighter panels laid over it. Depth here is literal furniture logic, not decoration —
if two things are stacked, the stack is visible. Density is comfortable rather than
compressed: this is a room you spend an evening in, not a dashboard you scan.

The system's one hard discipline is **color scarcity**. Every color is ours and defined in one
file; Optics supplies the non-color measurements and nothing else. One brand accent, at
most one page accent per page, and nothing else. A screen with coral in three unrelated
places, or with a second page's color bleeding into it, has broken the world.

**Key Characteristics:**

- Dark-first: dark is the designed scheme; light mode is not yet a designed surface
- Warm linen-gray chrome (hue 41°) that reads as room, not as UI
- One permanent coral accent (hue 16°), site-wide, reserved for action, turn, and identity
- Page accents: a major page may claim one color of its own, and it never leaves that page
- Literal, stacked depth: recessed trays, raised bars, drop-shadowed cards
- Cards are real elements with real stock, not images
- Comfortable density on a desktop-first canvas

## Colors

A warm-neutral room with one permanent hot accent, plus at most one color per page — the
palette is small on purpose, and its restraint is what makes coral legible as a signal.

### Color Ownership

**Every color in this app is ours. None of it comes from Optics.** Color lives in
`core/theme.css` as `--gp-color-*` (Game Platform), and no stylesheet outside that file may
reference an `--op-color-*` token. Optics remains the foundation and is not replaceable — it
still owns every *non-color* measurement (spacing, type, radii, shadows, border widths),
which stay on `--op-*` and are used directly.

*Why.* The palette had already drifted into being hand-picked in practice — coral, the felt,
the lobby slate — while the neutral chrome was still borrowed from Optics' ramp. That split
was the source of the flat, cold room: the values that mattered most were the ones nobody had
chosen, and fixing them meant fighting a vendor's scale rather than editing our own. Naming
what we own makes the boundary checkable instead of a matter of memory: a `--gp-` prefix means
we decided it, an `--op-` prefix means we inherited it, and a color on `--op-` is a bug.

*The plus/minus structure is kept deliberately.* Optics' ramp shape is genuinely good and
survives the move: `plus-*` steps are **surfaces**, climbing from `plus-max` (the page floor)
toward the viewer; `minus-*` steps are **ink** on those surfaces; `base` sits between them;
and `on-*` pairs name the ink that belongs on a given surface. We adopted the shape and
replaced the values. A new surface picks a `plus-*` step, not a new one-off color.

*How Optics still gets painted.* Optics' own components — buttons, sidebar, inputs,
dropdowns, dialogs — read `--op-color-*` internally, and we cannot rewrite their stylesheets.
So `theme.css` has one **bridge** block that points those tokens at our values. The flow is
one-directional and lives in exactly one place: our palette feeds Optics, never the reverse.
Without it, hand-written components would use our room while Optics-rendered chrome used
Optics' defaults — one screen in two color systems.

*The one exception, named honestly.* `--gp-color-warning-*` transcribes Optics' alert hue
(47° at full saturation) so that no color resolves through an Optics token. Those five values
were never chosen for this room — they are a hot yellow in a warm amber house. They are the
only undesigned corner of the palette; pick real ones when a warning state next gets
attention.

**Color scheme: dark is the designed scheme.** Every value below is authored and judged in
dark mode. Light mode currently renders only because Optics' scale and this project's
tokens are `light-dark()` pairs — **those light values are incidental, not designed**. A
deliberate light palette is planned as a later, hand-picked set that will replace the
dynamic switching with explicit values; until then, don't treat what light mode shows today
as intent, and don't spend design effort tuning it. See The Dark-First Rule below.

### Primary

Coral is **permanent** and **site-wide** — it is the identity, not a phase.

- **Accent Coral** (`hsl(16 85% 62%)`): the one brand accent, and the *only* color that
  means "act." Solid fills for primary buttons, the lobby's View CTA, the directive feed
  bubble, the hand's lock badge, and the turn-badge outline. One hue, hand-picked — never
  a derived ramp, because a ramp-darkened coral reads as muddy copper.
- **Accent Coral Deep** (`hsl(16 90% 42%)` in light, falls back to Accent Coral in dark):
  coral as *text*, contrast-safe on either page background. Carries the brand wordmark,
  section headings, the History link, meld owners, the "your turn" icon, and the Join CTA's
  label. Use this whenever coral is ink rather than fill.
- **Accent Coral Tint** (20% Accent Coral over the page): a soft coral surface for things
  that should read as accent-adjacent without shouting — the turn badge, the Join CTA, the
  active opponent card.

### Secondary

**Page accents.** A major page may claim one color of its own. It is that page's alone and
appears nowhere else in the app. Two pages have claimed one so far; the list is open.

*Game page — green:*

- **Felt Green** (`#1b2a22` dark / `#bfd2c6` light): the card table surface. Green exists
  only on the game page — never on chrome, never in the lobby, never on a button.
- **Felt Green Raised** (`#274035` / `#e6f5ea`): the brighter panels laid on the felt —
  the pile zone and the shared-meld zone.
- **Felt Green Translucent** (`rgb(255 255 255 / 0.05)` / `rgb(255 255 255 / 0.55)`): a
  wash over the felt for melds, letting the table read through.

*Games index — slate:*

- **Lobby Slate** (`hsl(215 14% 26%)` / `#eef1f5`): the cool blue-gray of the raised game bars on
  the home dashboard, and only those bars. The tray beneath them stays warm neutral.

*Unclaimed:* stats, history, and rules have no page accent, and that is a complete state —
warm chrome plus coral. Give one a color only when the page benefits from feeling like its
own place, never to fill in the pattern.

**How much of the page an accent covers is that page's own decision.** Green took the whole
stage and let its children sit brighter on top; slate took only the raised rows and left
the tray beneath it neutral. Both are correct. Don't standardize this — a new page picks
the deployment that fits it.

### Tertiary

- **Card Face Selected** (`hsl(16 45% 20%)`): a dark, muted coral used as the *face* of a
  selected card. Deliberately desaturated so the card's own rank/suit ink still reads over
  it.
- **Card Ink Red** (`#dc4d38`): red-suit ink on the simplified meld chips, matched to the
  red inside the card-face SVGs. There is no Optics red, so this stays hand-picked.

### Neutral

All chrome comes from one warm hue (41°) — an amber-tinged gray, deliberately decoupled from
the coral hue it would otherwise track. 41° rather than a yellower 49°, which reads faintly
olive at these saturations instead of like lamplight.

**Saturation tapers as lightness rises, and the pairing is load-bearing.** Chroma is nearly
imperceptible at 13% lightness and very visible at 40%, so a single saturation cannot serve
both ends of the ramp: the dark surfaces need ~21–26% before they read warm at all, while the
lighter ones turn to khaki cardboard anywhere near that. Each surface step therefore carries
its own saturation, high at the floor and low at the top. See The Tapered Chroma Rule.

Values below read **dark / light**, dark first, because dark is the designed scheme. (Note
this is the reverse of CSS `light-dark()` argument order, which the frontmatter necessarily
follows.) The light values are Optics' incidental output, not chosen tones.

- **Warm Neutral Page** (`hsl(41 26% 13%)` / `hsl(41 14% 100%)`): the page and the game
  shell. Set one step off Optics' default so raised surfaces read as raised.
- **Warm Neutral Raised** (`hsl(41 21% 17%)` / `hsl(41 14% 98%)`): panel headers, the
  lobby tray, the sidebar, the Rummy hand dock, opponent cards. The "chrome surface" tone.
- **Warm Neutral Recessed** (`hsl(41 14% 21%)` / `hsl(41 14% 96%)`): stats grid, modal
  dialogs, the request form, the winner row — surfaces set slightly *into* the page.
- **Warm Neutral Card Face** (`hsl(41 10% 27%)` / `hsl(41 14% 90%)`): the playing-card
  face and meld chip stock; doubles as the default border tone.
- **Ink** (`hsl(41 14% 100%)` / `hsl(41 14% 0%)`): headings and primary text.
- **Muted Text** (`hsl(41 14% 52%)` / `hsl(41 14% 24%)`): counts, captions, section
  labels, metadata, the empty-state line.

### Named Rules

**The No-Ramp Rule.** Never color a component from Optics' primary ramp
(`--op-color-primary-*`). Its lightness knob is inert and its base is locked mid-dark in
both schemes, so it cannot reach a bright hand-picked accent. Optics owns neutrals and
non-color tokens; every actual color is hand-picked. The primary hue is pointed at coral
for one reason only — so Optics' own internal chrome (focus rings, focused inputs) reads
coral instead of a stray default.

**The One Page, One Color Rule.** A major page may claim exactly one accent of its own, and
that color may not appear on any other page. One is the ceiling, not the target: pages with
no accent are complete. Where the color lands within the page — the stage, the rows, a
single surface — is that page's own call and is deliberately not systematized. If a page
color shows up in shared chrome or on a second page, it has leaked; remove it rather than
spreading it further.

**The One Signal Rule.** Coral means "act." Turn state, primary actions, links, focus, and
brand identity — nothing else, on every page. A page accent never takes over an action, and
coral never becomes a page's decoration. A screen where coral also decorates a heading, a
border, and a divider has spent the signal.

**The Owned Color Rule.** Color is `--gp-color-*` and nothing else. Never reference an
`--op-color-*` token outside `theme.css`'s bridge block, and never introduce a raw color value
in a component when a ramp step or accent already covers it. Non-color values are the
opposite: take them from `--op-*` and don't restate them under `--gp-*`. The prefix is the
contract — `--gp-` is what we decided, `--op-` is what we inherited.

**The Tapered Chroma Rule.** In dark mode, saturation and lightness move in opposite
directions across the neutral surface ramp: the page floor sits near 26% saturation, the
lightest surfaces near 7%. This is not a stylistic flourish — it is the only way one warm hue
can read as warm at 13% lightness without going olive at 40%. If you add or re-point a
surface step, give it a saturation that fits its lightness rather than copying a neighbour's.
Never flatten the ramp to one saturation; that was the original bug, and it produced a page
whose "warmth" was a five-level channel spread, i.e. neutral black.

**The Lamp Rule.** The room has exactly one light source: a single warm pool, high and left,
declared on the page shell (`components/layout/room.css`) and echoed on the lobby tray so the
light continues across the furniture. It is the reason the darkness reads as *lights low*
rather than *lights off*. Do not add a second light, do not give a component its own glow,
and do not animate this one. Opaque surfaces laid over it correctly mask it — furniture blocks
light.

**The Dark-First Rule.** Dark is the designed scheme. Author, review, and screenshot in
dark mode; that is what "correct" means here. Light mode is currently incidental output
from Optics' `light-dark()` pairs, so a light-mode oddity is a known state, not a bug worth
chasing — a hand-picked light palette is planned and will replace the dynamic switching
with explicit values. Until then, don't tune light values, and don't block on them.

**The Pair Rule.** Even though only dark is designed, keep every color a `light-dark()`
pair or an Optics pair — never substitute a raw hex for one. Hard-coding a fixed color both
breaks light mode outright *and* forfeits the seam the future light palette will be written
into. Note that Optics' `plus-N` steps trade direction between schemes (a lower number is
darker in light mode but *lighter* in dark mode, Material-style elevation), so "one step
darker" is not one thing — pick the step that's right in **dark**, and let light fall where
it falls.

## Typography

**Display Font:** Noto Sans (with `sans-serif` fallback) — Optics' default, used
throughout.
**Body Font:** Noto Sans — same family. There is no display/body pairing; hierarchy is
carried entirely by size and weight.
**Label/Mono Font:** none. Numerals in counts, stats, and metadata use
`font-variant-numeric: tabular-nums` so live-updating figures don't jitter.

**Character:** Neutral, quiet, and entirely deferential. The type is a plain
sans that gets out of the way so the cards and the felt are what you look at — expression
lives in surfaces and color, not in letterforms. The one voice it does have is *label
voice*: small, bold, wide-tracked uppercase, used to name a zone without competing with it.

Note the root is set to `62.5%` (1rem = 10px), so every rem value below reads as
tenths of its pixel size.

### Hierarchy

- **Display** (600, `3.2rem` / 32px): the single big number on a stat block. One per tile,
  centered.
- **Headline** (700, `2.4rem` / 24px): the lobby greeting and the board panel's title —
  the one thing that names the screen you're on.
- **Title** (600, `1.8rem` / 18px): panel headers throughout the game shell.
- **Body** (400, `1.6rem` / 16px): default text, message bubbles, form content.
- **Small** (400–600, `1.4rem` / 14px): the workhorse secondary size — game type,
  counts, CTA labels, empty states, feed bubbles.
- **Label** (700, `1.2rem` / 12px, `0.07em` tracking, uppercase): zone and section names —
  the lobby's section head, the felt zone labels. Also the un-tracked size for captions,
  meta, and timers.
- **Micro** (700, `1.0rem` / 10px, `0.03em` tracking, uppercase): the turn badge and phase
  stepper steps only.

### Named Rules

**The Label Voice Rule.** Uppercase + bold + letter-spacing is reserved for *naming a
region* (section heads, felt zone labels, scoreboard columns, status chips). Never use it
for a sentence, a button, or body copy.

**The Tabular Rule.** Any figure that updates live — card counts, player counts, stats —
gets `font-variant-numeric: tabular-nums`. Digits changing width mid-game reads as jitter.

## Layout

**The game shell is a named-area grid, one per game type.** `.game` fills `100dvh` and
divides into `board` / `feed` / `hand` / `books` areas with a fixed side column
(`332px`) and a fixed base row (`260px`). Go Fish uses all four areas; Crazy Eights lets
the feed span both rows; Rummy collapses to a single column of `board` over `hand` and
floats its feed as an absolutely-positioned bubble stack instead of occupying an area.
Adding a game means adding a `grid-template-areas` variant, not a new layout system.

**The lobby is a vertical stack**, comfortably padded (`24px 28px`), with a recessed tray
that flexes to fill remaining height so the dashboard always reaches the bottom of the
viewport.

**Content pages use a three-column grid** (`1fr 4fr 1fr`) with a full-width header row —
a centered main column with symmetric gutters, the left gutter right-aligned for
supporting content.

**Spacing rhythm** is Optics' scale on a 1rem (10px) unit: `2px · 4px · 8px · 12px ·
16px · 20px · 24px · 28px · 40px · 80px`. Component internals sit at 8–16px, panels at
16px, page padding at 24–28px, modals at 40px. Gaps between sibling cards are `12px`; gaps
between sections are `20px`.

**Responsive** — desktop-first, with one breakpoint at **768px**. Below it, the game grid
collapses to a single column stacking board → hand → books → feed, and the sidebar becomes
an icon rail (labels hidden, content centered). The breakpoint is documented as a token
but **CSS custom properties cannot be read inside `@media` conditions**, so every query
repeats the literal `768px` and is kept in sync by hand.

### Named Rules

**The Definite Height Rule.** Card sizing cascades down from a definite height, not up
from content. `.hand-wrap` establishes the band, `.hand-fan` fills it, `.hand-card` carries
`height: 100%`, and the card resolves its width from `aspect-ratio: 5 / 7`. Rummy's hand
panel is capped to `clamp(140px, 22vh, 220px)` plus the hover-lift allowance for exactly
this reason. Break the chain and cards collapse.

**The Reserved Lift Rule.** Wherever a card can lift, the room for the lift is reserved in
advance — `.hand-fan` pads its top by the lift distance (`50px`) so a raised card isn't
clipped by its own scroll container.

## Elevation & Depth

This system is **physically layered, not flat**. Depth is the primary way surfaces are
distinguished, and it is expressed as literal stacking: a recessed container holds raised
children, and cards float above everything they sit on. Tonal shifts alone are used only
for the subtlest chrome distinctions (panel header vs. panel body); anything that is
meaningfully "on top of" something else gets a shadow.

The signature move is the **recessed-tray / raised-bar pair** on the lobby: the tray
carries an inset shadow plus a bright inner bottom edge (so it reads as pressed into the
page), and each bar on it carries a bright inner *top* edge plus an outward drop shadow
(so it reads as lifted off the tray). The two shadows are designed as a matched set;
changing one without the other flattens the effect.

### Shadow Vocabulary

- **Recessed tray** (`inset 0 3px 9px <warm dark>, inset 0 -1px 0 <bright>`): a container
  pressed into the page — the lobby tray. Paired with a 1px warm border. In dark mode the
  lit inner edges do most of the work: a black shadow on a near-black surface has little
  tone left to darken, so the dark values are deliberately stronger than the light ones.
- **Raised bar** (`inset 0 1px 0 <bright>, 0 3px 10px <warm dark>`): an interactive row
  lifted off a recessed tray — lobby game bars, and reused for melds on the felt. A `--live`
  variant (`0 5px 16px`) takes the top of the stack for the one row waiting on the viewer.
- **Card lift** (`filter: drop-shadow(0 3px 4px rgb(0 0 0 / 0.6))`): the playing card's own
  shadow. Applied as a `filter`, not `box-shadow`, so it follows the card's rounded
  silhouette rather than its box.
- **Panel inset** (`inset` Optics x-large): the deep inner shadow on a panel body, marking
  it as the well inside its header.
- **Ambient small** (Optics small): felt zones and feed bubbles resting on their
  background.

### Named Rules

**The Matched-Pair Rule.** Recessed and raised shadows ship together. A raised bar with no
recessed tray beneath it, or a tray with flat children, loses the entire effect.

**The Filter-Not-Box Rule.** Card shadows use `filter: drop-shadow(...)`. Cards are
rounded, occasionally rotated, and layered — a `box-shadow` would trace the wrong outline.

## Shapes

**A soft, consistently rounded form language** with radius mapped to surface size — the
bigger the surface, the rounder its corners.

- **2px / 4px** — the smallest chips and the playing card itself. Cards are only gently
  rounded, matching real card stock.
- **8px** — buttons, CTAs, melds, piles, and the section divider's neighbors.
- **12px** — game bars, felt zones, message bubbles, feed bubbles.
- **20px** — the largest surfaces: the felt, the lobby tray, the stats grid, modals. This
  is a deliberate override of Optics' 16px ceiling, taken from the mockups.
- **Pill** — status chips only: the turn badge and its dot.

**Borders are hairline and warm.** The base width is `1.8px` (an override of Optics'
default) with `3px` for emphasis; the color is the warm neutral card-face tone. Borders
divide chrome; they never carry accent color except on a coral status chip or an active
step.

**The card silhouette is the recurring geometry.** A `5 / 7` portrait rectangle appears at
four scales — full cards in hand, large cards on piles, simplified rank+suit chips in
melds, and tiny face-down slivers on opponent cards. Anything representing a card uses that
ratio.

### Named Rules

**The Radius-Tracks-Size Rule.** Pick radius by surface scale, not by taste: chip 2–4px,
control 8px, container 12px, stage 20px. A 20px radius on a small chip reads as a lozenge;
a 4px radius on the felt reads as a bug.

**The One Aspect Rule.** Every card representation is `5 / 7`, at every scale. Never
free-size a card.

## Components

### Buttons

- **Shape:** gently rounded (`4px` for Optics' base button, `8px` for the lobby CTAs).
- **Primary:** solid Accent Coral fill with white ink and a matching inset border. It
  deliberately overrides Optics' own primary at equal specificity, winning on load order.
- **Hover / Active:** the coral **dims in place** via `filter: brightness(0.94)` / `0.88`.
  It never shifts hue — a ramp-darkened coral reads as muddy copper, which this system
  rejects outright.
- **Tri-state CTA (lobby):** three variants that share one `min-width` (`4.5rem`) so rows
  stay aligned whichever renders — **View** (solid coral, primary), **Join** (coral tint
  with a coral outline, secondary), **Full** (transparent with a muted border and
  `cursor: default` — deliberately inert, not a disabled button).

### Chips

- **Turn badge:** pill-shaped, coral-tint fill, coral outline, coral-deep micro-uppercase
  label, with a `0.45em` dot in `currentColor`. The canonical "it's your turn" object.
- **Phase stepper step:** `20px`-radius pill-ish chip, muted by default; the active step
  takes a coral border, coral-deep bold ink, and a raised chrome fill.
- **Lock badge:** a coral glyph pinned to a card's top-right corner, marking the card that
  can't be discarded this turn. It travels with the card on select, sharing the card's
  offset and easing.

### Cards / Containers

- **Panel** (the game shell's building block): a header/body pair. The header is raised
  chrome with a hairline bottom border; the body is the inset well beneath it. Variants
  reshape it per area (`--board`, `--feed`, `--hand`, `--books`), and Rummy's board and
  hand panels drop the boxed header entirely.
- **Lobby tray:** `20px` radius, raised-chrome fill, warm hairline border, recessed inset
  shadow. Flexes to fill the dashboard's height.
- **Game bar:** `12px` radius, Lobby Slate fill, raised shadow. Name leads, game type sits
  muted beneath it, count and CTA cluster right. Its secondary text takes one ramp step
  lighter than the page's muted tone — slate is the app's one cool surface and the shared
  step lands under 4.5:1 on it.
  - *Your-turn variant:* the bar waiting on the viewer drops slate for a 32% coral tint over
    the page tone and takes the highest lift on the tray, so the actionable game reads before
    any text does. It does *not* mix coral into slate — the two are near-complements and any
    blend of them desaturates to plum-brown instead of reading lit. This is coral as turn
    state, and it is the reason the lobby needs no other ranking device. Its turn badge sits
    one step deeper than the row with room ink rather than coral ink, because coral-on-coral-
    tint measures ~3.2:1 at 10px; the badge's coral border and the row's wash carry the accent
    instead. Rows waiting on the viewer also sort to the top of their section.
- **Felt zone** (the game page's accent in use): `12px` radius, Felt Green Raised fill,
  ambient shadow, with a
  label-voice caption. The piles zone sizes to content; the melds zone takes the rest and
  wraps.
- **Modal:** `20px` radius, recessed-chrome fill, `40px` padding, capped at `90vw`, over a
  50%-black backdrop. Enters with a backdrop fade (`0.2s`) plus a dialog pop that
  overshoots to `1.03` before settling (`0.3s ease-out`).

### Inputs / Fields

- **Text fields:** Optics' Simple Form defaults. Focus reads coral because the Optics
  primary hue is pointed there.
- **Card selection** is the distinctive input: a visually-hidden but fully real checkbox
  wrapped by the entire card as its label. Never a click handler on a div — the control
  stays focusable and toggleable.
  - *Enabled:* a neutral inset outline marks the card as selectable.
  - *Focus-visible:* the outline lightens and the face brightens a step.
  - *Checked:* the card lifts by `20px`, its face swaps to the dark muted coral, and it
    takes a coral inset outline. Because `:checked` is a stable pseudo-class on a node that
    never remounts, the transition animates both select *and* deselect.
  - *Disabled:* the **face darkens a shade** rather than fading — opacity would skew the
    card's ink off-color. A *locked* card is not disabled; it stays selectable for melding.

### Navigation

Optics' sidebar, with the brand wordmark in Accent Coral Deep — the one place coral acts
as identity rather than action. Below `768px` it collapses to an icon rail: the wordmark
hides, content centers, and labels drop to `font-size: 0`.

### Signature Component: The Playing Card

**The card face is a real CSS element; only the rank/suit ink is an image.** The face is a
`5 / 7` div with a neutral fill, a warm hairline border, `4px` radius, and a `drop-shadow`
filter; the SVG paints its ink on top. This is what makes the selected state a one-line
background swap instead of an image swap — and it's why the ink must carry its own
theme-awareness (page CSS can't reach inside an `<img>`).

Two hands, two deliberately opposite overflow strategies — do not port one to the other:

- **Go Fish / Crazy Eights:** the row *never* scrolls. Cards overlap harder as the hand
  grows, driven by a measured overlap variable, and never shrink.
- **Rummy:** cards keep a fixed size and a flat gap, packed flush left, and the row scrolls
  horizontally on overflow.

### Signature Component: The Feed

Two forms of the same message trail:

- **Side panel** (Go Fish, Crazy Eights): a column-reverse list on a near-white ground,
  with a `linear-gradient` mask fading the oldest entries out at the top.
- **Bubble stack** (Rummy): bubbles pinned over the board's top-right corner with an
  asymmetric radius (the bottom-right corner tightens, giving the stack a tail). Age is
  expressed as opacity — `0.6` fading, `0.3` ghost. A **directive** bubble inverts to solid
  coral with white ink and a `➜` prefix; it is the loudest object on the screen and there
  is never more than one.

## Do's and Don'ts

### Do:

- **Do** take every surface, border, and body-text color from the `--gp-color-neutral-*` ramp,
  and every non-color value (spacing, type, radius, shadow) from an `--op-*` token.
- **Do** reach for a `plus-*` step for a new surface and a `minus-*` step for new ink, rather
  than inventing a one-off color.
- **Do** name page accents as project tokens too: `--gp-color-accent*` for coral, `--gp-felt*`
  for the game page, `--gp-lobby-bar` for the games index.
- **Do** use Accent Coral Deep whenever coral is *text* and Accent Coral whenever coral is
  a *fill*. The deep pair is the one that stays legible on either page background.
- **Do** design, review, and screenshot in **dark mode** — that is the scheme that counts.
- **Do** keep colors as `light-dark()` pairs anyway, so the future light palette has a seam
  to be written into.
- **Do** give a new page its own accent when it genuinely benefits from feeling like its own
  place — and put it wherever suits that page.
- **Do** pair recessed and raised shadows as a set.
- **Do** give every card representation the `5 / 7` ratio, at every scale.
- **Do** use `filter: drop-shadow()` for card shadows and `box-shadow` for boxes.
- **Do** reserve space for a lift before animating one.
- **Do** put live-updating numerals in `tabular-nums`.
- **Do** dim coral with a `brightness()` filter for hover and active states.
- **Do** keep one BEM block per file, elements and modifiers nested under the block.

### Don't:

- **Don't** reference any `--op-color-*` token outside `theme.css`'s bridge block — color is
  `--gp-color-*`. In particular, don't color anything from `--op-color-primary-*`: the ramp
  cannot reach this coral, and the primary hue is pointed at coral only so Optics' own
  internal chrome reads coral instead of a stray default.
- **Don't** restate an Optics *non-color* value under `--gp-*`. Optics still owns spacing,
  type, radii, shadows, and border widths; duplicating them forfeits the upstream scale for
  values we aren't choosing.
- **Don't** let a page's accent appear on another page: green belongs to the game page,
  Lobby Slate to the games index, and neither belongs in shared chrome.
- **Don't** give one page two accents, and don't assign a color to stats, history, or rules
  just to complete the pattern — no accent is a finished state.
- **Don't** spend coral on decoration. If it isn't action, turn state, focus, or brand, it
  isn't coral. And never let a page accent take over a coral job.
- **Don't** treat a light-mode oddity as a bug to fix today. Light is undesigned until it
  gets its hand-picked palette.
- **Don't** substitute a raw hex for an Optics `plus-N`/`minus-N` token — those are
  `light-dark()` pairs, and hard-coding one forfeits the seam the light palette needs.
- **Don't** wrap a full shadow or border shorthand in `light-dark()`. It accepts two
  `<color>` arguments only; a shorthand silently invalidates the whole declaration to
  `none` with no console warning. Wrap only the color portion of each layer.
- **Don't** derive a coral ramp. Coral is a few chosen shades at 16°; a generated ramp
  drifts toward muddy copper.
- **Don't** fade a disabled card with opacity — darken its face instead, so the ink stays
  true.
- **Don't** replace the hidden-checkbox card selection with a click handler on a div.
- **Don't** port one game's hand-overflow strategy to another. Go Fish and Crazy Eights
  overlap and never scroll; Rummy scrolls and never overlaps. Both choices are load-bearing.
- **Don't** reference a `--_gp-*` private token from outside its own component file.
- **Don't** use label voice (uppercase + bold + tracking) for anything but naming a region.
