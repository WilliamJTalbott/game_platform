---
name: Game Platform
description: A dark, lamp-lit card room for playing turn-based card games live with friends.
colors:
  accent-coral: "hsl(16 85% 62%)"
  accent-coral-tint: "#4b2e22"
  on-accent: "#ffffff"
  warm-neutral-page: "oklch(18.29% 0.0105 53.9)"
  warm-neutral-raised: "oklch(27.91% 0.014 55.5)"
  warm-neutral-recessed: "oklch(23.1% 0.014 54.7)"
  warm-neutral-card-face: "oklch(37.53% 0.014 57.1)"
  border: "oklch(37.53% 0.014 57.1)"
  white: "oklch(100% 0 0)"
  black: "oklch(0% 0 0)"
  ink: "oklch(90.38% 0.007 65.9)"
  muted-text: "oklch(61.58% 0.014 61.1)"
  felt-green: "#1b2a22"
  felt-green-raised: "#274035"
  felt-green-translucent: "rgb(255 255 255 / 0.05)"
  lobby-slate: "hsl(215 14% 26%)"
  lobby-mine: "#5c3222"
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
    textColor: "{colors.accent-coral}"
    rounded: "{rounded.large}"
    padding: "8px 12px"
  cta-full:
    backgroundColor: "transparent"
    textColor: "{colors.muted-text}"
    rounded: "{rounded.large}"
    padding: "8px 12px"
  turn-badge:
    backgroundColor: "{colors.accent-coral-tint}"
    textColor: "{colors.accent-coral}"
    typography: "{typography.micro}"
    rounded: "{rounded.pill}"
    padding: "2px 8px"
  lobby-tray:
    backgroundColor: "{colors.warm-neutral-recessed}"
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
a dark-only system: there is no light mode to fall back to, so dark is simply what
"correct" means here. The chrome is the room itself, an amber-tinged linen gray that never
announces itself, because it is walls and furniture, not the event. Coral is the single lit
signal in that room, everywhere in the house: it means *act* — your turn, this button, this
link, this name. Nothing else glows.

**The lamp is in the color, not in a gradient.** The neutral ramp drifts warmer (redder) as its
surfaces darken toward the floor, so the low light reads as warm rather than as a flat gray
turned down — that hue drift is what keeps "lights low" from becoming "lights off." There was
once a literal warm wash over the page as well; it is retired, and every background is a flat
ramp step. Depth now comes entirely from the elevation vocabulary. See The Lamp Rule — retired.

**Each major room may be its own color.** Coral is the constant, site-wide; on top of it, a
major page may claim one accent of its own so that arriving there feels like arriving
somewhere. The game page claimed green and became a felt table. The games index claimed a
cool slate and became the hallway. Neither color is allowed anywhere else, and neither is
the whole list — the next page that earns one picks its own. Pages that don't claim a color
are not unfinished; warm chrome plus coral is a complete page.

The room is **physical, not flat**. Trays stand off the page and bars sit raised
on top of them; cards cast real shadows and lift when you touch them; the felt has
brighter panels laid over it. Depth here is literal furniture logic, not decoration —
if two things are stacked, the stack is visible. Density is comfortable rather than
compressed: this is a room you spend an evening in, not a dashboard you scan.

The system's one hard discipline is **color scarcity**. Every color is ours and defined in one
file; Optics supplies only the non-color measurements it hasn't yet been replaced for
(see docs/frontend.md). One brand accent, at most one page accent per page, and nothing
else. A screen with coral in three unrelated places, or with a second page's color bleeding
into it, has broken the world.

**Key Characteristics:**

- Dark-only: there is no light mode; `color-scheme: dark` is set app-wide
- Warm linen-gray chrome (a generated neutral ramp, hue ~54.7° in OKLCH at the room,
  drifting to ~67.5° at white) that reads as room, not as UI
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
reference an `--op-color-*` token. Non-color measurements (spacing, type, radii, shadows,
border widths) are also ours now, declared in `core/tokens/scale.css` as `--gp-*` — Optics
is being phased out entirely (see docs/frontend.md and docs/plans/own-the-tokens.md); its
own bundled components still read their own internal `--op-*` copies until each is replaced.

*Why.* The palette had already drifted into being hand-picked in practice — coral, the felt,
the lobby slate — while the neutral chrome was still borrowed from Optics' ramp. That split
was the source of the flat, cold room: the values that mattered most were the ones nobody had
chosen, and fixing them meant fighting a vendor's scale rather than editing our own. Naming
what we own makes the boundary checkable instead of a matter of memory: a `--gp-` prefix means
we decided it, an `--op-` prefix means we inherited it, and a color on `--op-` is a bug.

*The plus/minus direction is kept; the anchoring is not.* Optics' convention that `plus-*`
is darker and `minus-*` lighter survives, and so does `on-*` naming the ink that belongs on
a given surface. What did not survive is Optics' idea of where `base` sits. Optics anchors
its ramp on a neutral midpoint and runs eight steps either way; this app is dark-only, and
under that arrangement the page tone landed on `plus-8` — the scale's *last* step — while
`base` landed on a mid-gray whose only consumer was caption text. Two costs followed: the
room could not be deepened without moving every step with it, and any surface meant to sit
*below* the page had to be built by going lighter, inverting the elevation model.

So `base` is now **the room's own tone**, and the scale runs both ways from it — but it stops
short of both extremes, because **white and black are not on the ramp.**

*Why they aren't.* A ramp holds one color and its lighter and darker shades. White and black
hold no color at all; they are where hue and chroma stop existing. When they were ramp steps
the file had to admit it twice over: both had to special-case their chroma to `0`, and the
step size stopped being a knob — it was pinned to exactly `(100% − base) / 16`, whatever it
took for sixteen steps to land on white. Changing the step either dimmed every heading or
forced a renumber. A scale whose two extremes must opt out of the scale's defining property
is telling you they were never members.

*The three families.* `--gp-white` and `--gp-black` are named absolutes. The **warmed whites**
(`--gp-w-1..3`) are white pulled back toward the room, and they are what all ink is made of —
which is how they were already authored, as the ramp's top four steps with chroma scaled
`0 / 0.25 / 0.50 / 0.75`. The **ramp** (`--gp-n-*`) is then only the room: `plus-2` … `minus-10`,
thirteen steps, flat chroma throughout except the two cellar steps that run near black. The
page floor is `plus-1`, one step sunk into the room.

*What that bought.* The ramp's step is now a free knob — nothing downstream depends on where
the ramp ends. Its chroma went flat, which is what OKLCH promised before the endpoints forced
a correction. And "how warm is our ink" became one legible question with its own two knobs
(`--gp-w-l-step`, `--gp-w-hue`) instead of an emergent property of ramp arithmetic. A new
surface still picks a step rather than a one-off color; ink picks a warmed white.

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

**Color scheme: dark only.** `color-scheme: dark` is set on `:root` and there is no
`light-dark()` left anywhere in the neutral ramp — every value below is the only value,
not one arm of a pair. A hand-picked light palette may exist someday, but it would be a
separate, deliberately chosen set of colors, never an inversion of this one. See The
Dark-First Rule below.

### Primary

Coral is **permanent** and **site-wide** — it is the identity, not a phase.

- **Accent Coral** (`hsl(16 85% 62%)`): the one brand accent, and the color that means
  "act." Solid fills for primary buttons, the lobby's View CTA, the directive feed bubble,
  the hand's lock badge, and the lobby turn badge — and, as ink, the brand wordmark, section
  headings, the History link, meld owners, and the "your turn" icon. One hue, hand-picked —
  never a derived ramp, because a ramp-darkened coral reads as muddy copper. (There used to
  be a separate, lighter "Accent Coral Deep" for text on a light background; now that light
  mode is gone, ink and fill are the same value.) The three solid-fill-plus-white-ink objects
  — primary button, directive bubble, turn badge — are one deliberate family: this is what
  the system does when something must be the loudest thing on screen.
- **Accent Coral Tint** (`#4b2e22`, a hand-picked dark muted coral): a soft coral surface for
  things that should read as accent-adjacent without shouting — the Join CTA and the active
  opponent card. (The lobby turn badge used to be here; it was promoted to the solid fill
  when the row beneath it stopped carrying turn state.) Resolved to this literal after
  retiring a `color-mix()` that used to produce it — see The Owned Color Rule.

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

- **Lobby Slate** (`hsl(215 14% 26%)`): the cool blue-gray of the raised game bars on the home
  dashboard — and only the bars for games the viewer has **not** joined. The tray beneath them
  stays warm neutral.
- **Lobby Mine** (`#5c3222`, `--gp-lobby-bar-mine`): the same bars for games that *are* the
  viewer's. A picked coral tint, not a shade of slate — the two are near-complements and any
  blend of them desaturates to plum-brown instead of reading lit, so these rows leave the page
  accent behind rather than tinting it.

  *The pair is the point.* Slate alone was the page's accent; now slate and this tint are a
  two-tone axis, and the axis is ownership. Because the lobby's two sections split on exactly
  that condition, each section comes out one temperature — your games warm, open games cool —
  which is the fastest thing on the page to read. This is the One Signal Rule's single
  documented exception; see it for why coral is allowed to mean "yours" here.

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

All chrome comes from one warm hue, generated rather than hand-typed: five knobs in
`core/theme.css` (hue, a per-step hue drift, a flat chroma, the room's lightness, and a step
size) produce all 13 ramp steps as OKLCH `calc()` expressions, and two more (`--gp-w-l-step`,
`--gp-w-hue`) produce the three warmed whites. Change a knob and every step derived from it
moves together. `--gp-n-l-base` is the one that says how dark this app is — every ramp step is
measured from it. The two families share a chroma and a hue drift, because both describe the
same warmth, but **not** a lightness step: the ink's distance from white and the room's
contrast per step of elevation are unrelated questions, and coupling them was the bug. The hue sits at 54.7° (red-orange) at the room and drifts 0.8° toward
amber per step lighter, reaching 67.5° at white — OKLCH's hue numbers don't correspond to
HSL's, so this is a different-looking number for the same amber-tinged gray the app has
always had.

**Chroma is flat across the ramp, and the cellar is the one exception.** OKLCH chroma is
perceptually uniform, so one value (`0.014`) reads equally warm across the whole ramp —
unlike HSL saturation, which needed a hand-tuned taper to avoid going olive at one end or
khaki at the other. See The Tapered Chroma Rule below for why *that* taper is gone.

Chroma is *absolute colorfulness*, not saturation, so as lightness runs out toward an endpoint
a flat chroma becomes a larger and larger **proportion** of the tone. The two cellar steps
(`plus-1`, `plus-2`) run close enough to black to need correcting, and scale chroma by
0.75 / 0.50. Without it the page read 30.5% HSL-saturated against the sidebar's 20.1% one step
above it — same hue, same red-over-blue spread, visibly redder.

The white end used to need the mirror of that. It no longer does, because the ramp no longer
reaches white: the fade from white became the warmed-white family's whole definition rather
than a correction bolted onto a scale's last four steps. That is the practical payoff of
taking the endpoints off the ramp — a patch turned into a structure.

Every step below is a single, dark-only value — there is no light arm.

- **Warm Neutral Page** (`oklch(18.29% 0.0105 53.9)`, `plus-1`): the page and the game shell —
  the floor you stand on, one step sunk into the room.
- **Warm Neutral Recessed** (`oklch(23.1% 0.014 54.7)`, `base`): the sidebar, the Rummy hand
  dock, the lobby tray, stats grid, modal dialogs, the request form, the winner row. The room's
  own tone, and the first surface above the floor. "Recessed" names the intent, not the
  direction — it is a step *lighter* than the page, which is what makes the sidebar read as a
  lit panel. The dock shares it deliberately, so the sidebar and the hand read as one
  continuous band of chrome; the lobby tray joined it for the same reason, so the app's large
  chrome slabs are one tone rather than three.

*A note on the cellar.* `plus-2` (`oklch(13.48% 0.007 53.1)`) is currently unused. The game
page briefly took it as a deeper floor, to open a tone between the floor and the sidebar for
the hand dock — but at 13.48% that shell read too stark against the felt and the cards, and
the dock came back up to the sidebar's tone. The step remains in the ramp because a page that
wants to sink below the house floor is a reasonable future want; nothing has earned it yet.
- **Warm Neutral Raised** (`oklch(27.91% 0.014 55.5)`, `minus-1`): panel headers, opponent
  cards. The "chrome surface" tone; one step above the room, directly adjacent to Recessed —
  so the sidebar/dock band and the panel headers sitting on it are a single step apart.
- **Warm Neutral Card Face** (`oklch(37.53% 0.014 57.1)`): the playing-card face and meld
  chip stock; doubles as the default border tone.
- **Muted Text** (`oklch(61.58% 0.014 61.1)`, `minus-8`): counts, captions, section labels,
  metadata, the empty-state line. The one ink still taken from the ramp — at 61.58% it really
  is a mid-tone of the room rather than a warmed white, and filing it with the others would be
  a tidy-looking lie.

**The ink comes from white, not from the ramp.** Every other ink tone is white pulled a step
or two back toward the room, so it lives in its own family with its own knobs:

- **White** (`oklch(100% 0 0)`, `--gp-white`): headings on the floor. A named absolute.
- **Ink One Off White** (`oklch(95.19% 0.0035 66.7)`, `--gp-w-1`): the dimmest ink — muted
  captions on a card face.
- **Ink Two Off White** (`oklch(90.38% 0.007 65.9)`, `--gp-w-2`): ink on a raised surface, and
  body text on the page.
- **Ink Three Off White** (`oklch(85.57% 0.0105 65.1)`, `--gp-w-3`): ink on a recessed surface
  or a card face. The warmest of them, closest to the room.
- **Black** (`oklch(0% 0 0)`, `--gp-black`): not a surface. It is the overlay scrim and every
  drop shadow, which were already literal `rgb(0 0 0 / …)` and now spend it by name. There is
  deliberately **no** warmed-black family — the surfaces that are genuinely near-black are the
  room in low light, not black seen warm. Add one when something actually wants it.

### Named Rules

**The No-Ramp Rule.** Never derive an accent from the neutral ramp, and never color a
component from Optics' primary ramp (`--op-color-primary-*`) either — its lightness knob is
inert and its base is locked mid-dark, so it cannot reach a bright hand-picked accent. Every
accent (coral, felt, lobby slate, card ink) is a hand-picked, dark-only value; only the
*neutral* ramp is generated. Optics' primary hue is pointed at coral for one reason only —
so Optics' own internal chrome (focus rings, focused inputs) reads coral instead of a stray
default.

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

*One documented exception: the lobby's game bars.* There, a coral **tint surface** means "this
game is yours," and turn state is carried by lift, badge, and sort order instead. Coral is
still not decoration — it is still answering a question about the viewer — but the question is
*whose* rather than *when*. The exception is granted because the lobby's central job is telling
your games apart from strangers' games, that split is binary, and temperature reads faster than
any label: your half of the page is warm, the other half is cool. Coral-as-action survives
intact in the same rows' CTAs, which is why the row can say "mine" without the column losing
its meaning.

Do not generalize this. The exception is a *tint surface on one component*, not a license for
coral to mean ownership anywhere else, and a second page claiming it would put the app back to
having no reliable signal at all. If a third fact ever needs stating in these rows, it gets a
channel that isn't color.

**The Owned Color Rule.** Color is `--gp-color-*` and nothing else — never a raw hex/hsl in a
component when a ramp step or accent already covers it, and never a `color-mix()` (it hides
the resulting color behind an opaque formula and desaturates toward gray instead of staying
in the ramp's hue — this is why Accent Coral Tint is now a picked literal, not a mix). Never
reference an `--op-color-*` token outside `theme.css`'s bridge block, either. Non-color
values used to be the opposite — read from `--op-*` — but that's now also being migrated to
`--gp-*` (`core/tokens/scale.css`); see docs/frontend.md for where that migration stands.

**The Tapered Chroma Rule — retired.** The ramp used to taper HSL saturation from ~26% at
the floor to ~7% at the top, because HSL saturation isn't perceptually uniform: a flat value
read olive at the dark end or khaki at the light end. Converting to OKLCH removed the need
entirely — chroma is a single flat knob (`--gp-n-chroma`) that reads evenly warm across the
ramp's working middle.

*The rule asked to be told if chroma ever needed to vary by step again, and it now does — in
the two cellar steps only, and for a different reason than the HSL taper had.* HSL's taper
corrected the **middle**, because HSL saturation isn't perceptually uniform and a flat value
drifted olive-to-khaki along the ramp. The endpoint taper corrects the **ends**, because
chroma is absolute colorfulness and near black there is no lightness left to dilute it — a
flat 0.014 reads as rising saturation, which is what made the page look redder than the
sidebar. Everything above the cellar is still flat, and OKLCH is still uniform there. (The
white end needed the same correction until white came off the ramp entirely; now that fade is
the warmed-white family's definition, not a taper.) If a *middle* step ever needs its own
chroma, that would be the signal the original rule was watching for.

**The Lamp Rule — retired.** The room used to carry one authored light: a top-to-bottom warm
wash declared on the page shell (`components/layout/room.css`) and echoed on the lobby tray, so
the light continued across the furniture. It was there because "lights low" and "lights off" are
the same picture without it.

*It is gone, and every background in this app is now a flat ramp step.* No `linear-gradient` fill
survives outside `panel.css`'s feed `mask-image`, which is a fade of content, not of a surface.
The half-step lamp tone (`--gp-n-lamp`) and its `--gp-wash-lamp` role are deleted, `room.css` with
them.

*What now carries the low light.* The warmth itself — the ramp's own hue and its per-step drift —
and the elevation vocabulary below, which was always doing more of the work than the wash was: a
tray is legible because it takes a ramp step of its own and casts onto the page, not because it
sat under a gradient. Removing the wash is in fact what surfaced the lobby tray's real problem:
it had been sharing the page's exact tone and leaning on the gradient to separate the two. It is
now a step lighter and raised. See the Matched-Pair Rule.

If a wash is ever wanted again, it returns as a rule first — one light, high and left, never a
second one, never a per-component glow, never animated — and the token comes back with it, not
ahead of it.

**The Dark-First Rule — now Dark-Only.** There is no light mode. `color-scheme: dark` is set
on `:root` and no `light-dark()` pair survives in the neutral ramp — author, review, and
screenshot in dark mode because it's the only mode there is, not because it's the one that
"counts" more. If a hand-picked light palette ever ships, it will be a separate, deliberately
chosen set of colors, never a light arm re-added to this ramp.

**The Pair Rule — retired.** Every neutral used to be a `light-dark()` pair so a future light
palette would have a seam to slot into; none of that survived the OKLCH conversion. Every
neutral is now a single ramp index and every accent is a single hand-picked, dark-only value.
If light mode is ever built, it starts over as its own palette rather than filling in the
other half of an existing pair.

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

The signature move is the **two-step raised stack** on the lobby: the tray sits a ramp step
above the page with a bright inner top edge and a wide outward drop shadow, and each bar on
it repeats the same treatment at a smaller scale — same lit-edge-plus-drop-shadow
vocabulary, a tighter blur, a brighter edge. Page → tray → bar reads as three surfaces
stacked front to back, each one lighter and each one casting onto what's behind it.

*It used to be a recessed tray holding raised bars* — the tray on the page's own tone with an
inset shadow and a lit inner *bottom* edge, so it read as pressed into the page. That worked,
but it made the tray's edge depend entirely on the shadow (there was no tonal difference to
fall back on) and it put the lobby's largest surface at the bottom of the stack while every
other big chrome slab in the app — Rummy's hand dock, the sidebar — sits above the floor. The
tray now takes the dock's exact tone, and the two read as the same kind of object.

The two shadows are still designed as a matched set at two scales; changing one without the
other flattens the effect.

### Shadow Vocabulary

- **Raised tray** (`inset 0 1px 0 <bright>, 0 6px 20px <warm dark>`): a large chrome slab
  standing off the page — the lobby tray. No border: it is already a ramp step lighter than
  the page, and a hairline under a wide soft shadow states the same edge a third time. Its
  lit top edge is deliberately fainter than a bar's, because it is the calmer surface and the
  bars have to read as the brighter things sitting on it.
- **Raised bar** (`inset 0 1px 0 <bright>, 0 3px 10px <warm dark>`): an interactive row
  lifted off the tray — lobby game bars, and reused for melds on the felt. The same
  vocabulary as the raised tray at a smaller scale: blur tracks surface size. A `--live`
  variant (`0 5px 16px`) takes the top of the stack for the one row waiting on the viewer.
- **Card lift** (`filter: drop-shadow(0 3px 4px rgb(0 0 0 / 0.6))`): the playing card's own
  shadow. Applied as a `filter`, not `box-shadow`, so it follows the card's rounded
  silhouette rather than its box.
- **Panel inset** (`inset` Optics x-large): the deep inner shadow on a panel body, marking
  it as the well inside its header.
- **Ambient small** (Optics small): felt zones and feed bubbles resting on their
  background.

### Named Rules

**The Matched-Pair Rule.** A stack's shadows ship together and are tuned against each other.
The lobby's tray and bars are one effect at two scales: blur tracks surface size, and the
brighter lit edge belongs to the smaller, nearer surface. A bar sitting on a flat tray, or a
tray with flat children, loses the entire effect. Never re-level one without re-checking the
other — the whole point is that each surface is legibly in front of the one behind it.

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

- **Turn badge:** pill-shaped, **solid Accent Coral fill, white micro-uppercase label**, no
  border, with a `0.45em` dot in `currentColor` (so the dot is white too). The canonical
  "it's your turn" object, and the loudest thing on the lobby — deliberately, since the row
  it sits on now marks ownership rather than turn state.
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
- **Lobby tray:** `20px` radius, recessed-chrome fill (a step above the page, the same tone
  as Rummy's hand dock), no border, raised-tray shadow. Flexes to fill the dashboard's
  height.
- **Game bar:** `12px` radius, raised shadow. Name leads, game type sits muted beneath it,
  count and CTA cluster right. **It states two independent facts on two independent channels,
  and that separation is the component's whole design:**
  - *Surface = whose game.* **Lobby Mine** (`#5c3222`, `--gp-lobby-bar-mine`) for the viewer's
    own; **Lobby Slate** for one they haven't joined. Since the lobby's two sections split on
    exactly this, each section reads as a single temperature. (It was a `color-mix()` of coral
    over the page tone until the Owned Color Rule caught it; it is now the literal that mix
    produced.)
  - *Badge and height = whose move.* Turn state used to own the coral surface; once ownership
    took it, the signal was rebuilt on two other channels. The **solid-coral turn badge** is
    the loud half — see Chips. The **lift** is the quiet structural half: the deepest shadow on
    the tray (`0 5px 16px`, `--gp-lobby-bar-shadow-live`), plus sorting to the top of the
    section. **Don't give the your-turn row a brighter coral instead** — a third tone in one
    column reads as a heat map, *and* it would close the lightness gap the badge depends on to
    pop off the row. The row's tint has to stay dim for the badge to stay loud; those two are
    now a pair.
  - *Secondary text* takes one ramp step lighter than the page's muted tone (`--gp-n-minus-10`),
    measured at **4.2:1 on Lobby Mine and 4.0:1 on slate** — both just under 4.5:1. Deliberate
    and unresolved; see Accessibility in PRODUCT.md for why it isn't being chased.
  - *The turn badge* is **solid Accent Coral with white ink** and no border — the same
    treatment as a primary button and the feed's directive bubble, which is this system's
    vocabulary for the loudest object on a screen. Against the row's dim coral tint that is a
    3.9:1 surface jump, which is what lets it carry turn state by itself now that the tint
    marks ownership. It was previously a *deeper* tint with room ink and a coral outline,
    reading as recessed into the row — correct while the coral row was itself the signal,
    wrong once it became the only one. The fill now carries the accent, so the outline is
    gone (coral on coral is invisible). **Cost, stated:** white on coral is ~2.8:1 at 10px,
    the lowest-contrast text on the page. That is the app's standing white-on-coral trade,
    not a new exception — but if the badge is ever revisited, this is the number to revisit.
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

Optics' sidebar, with the brand wordmark in Accent Coral — the one place coral acts
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

- **Do** take every surface, border, and body-text color from the generated neutral ramp
  (`--gp-n-*`), and every non-color value (spacing, type, radius, shadow) from `--gp-*`
  primitives in `core/tokens/scale.css` — see docs/frontend.md for where Optics' own `--op-*`
  is still read directly (its own bundled components, not yet replaced).
- **Do** reach for a `plus-*` ramp step for a new surface and a `minus-*` step for new ink,
  rather than inventing a one-off color.
- **Do** name page accents as project tokens too: `--gp-color-accent*` for coral, `--gp-felt*`
  for the game page, `--gp-lobby-bar` for the games index.
- **Do** design, review, and screenshot in dark mode — it's the only mode there is.
- **Do** give a new page its own accent when it genuinely benefits from feeling like its own
  place — and put it wherever suits that page.
- **Do** tune a stack's shadows as a set — blur tracks surface size, and the brighter lit edge
  belongs to the nearer surface.
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
- **Don't** hard-code a raw color value when a ramp step or accent already covers it, and
  never use `color-mix()` — pick the literal it would have produced instead (see The Owned
  Color Rule).
- **Don't** let a page's accent appear on another page: green belongs to the game page,
  Lobby Slate to the games index, and neither belongs in shared chrome.
- **Don't** give one page two accents, and don't assign a color to stats, history, or rules
  just to complete the pattern — no accent is a finished state.
- **Don't** spend coral on decoration. If it isn't action, turn state, focus, or brand, it
  isn't coral. And never let a page accent take over a coral job.
- **Don't** derive a coral ramp, or any other accent, from the neutral ramp. Coral is a few
  chosen shades at 16°; a generated ramp drifts toward muddy copper.
- **Don't** fade a disabled card with opacity — darken its face instead, so the ink stays
  true.
- **Don't** replace the hidden-checkbox card selection with a click handler on a div.
- **Don't** port one game's hand-overflow strategy to another. Go Fish and Crazy Eights
  overlap and never scroll; Rummy scrolls and never overlaps. Both choices are load-bearing.
- **Don't** reference a `--_gp-*` private token from outside its own component file.
- **Don't** use label voice (uppercase + bold + tracking) for anything but naming a region.
