# Rummy turn feedback, the flash popup, and the card token family

## What we were working on

Two threads, driven by "what is Rummy missing, and how do we better show the
player what to do at any given point":

1. **Rejected turns failed silently.** `RummyForm` already validated everything
   (invalid meld, the lay-off gate, the locked card, one-card discard) with
   good human-readable copy, and `TurnsController#render_invalid_turn` already
   re-rendered the game with the errors-laden form attached — but **no game view
   in the app ever rendered `form.errors`**. Every reason was computed, plumbed
   through the presenter, and dropped. Platform-wide: Go Fish and Crazy Eights
   had the same hole.
2. **Retiring "dim on disable"** across cards/piles/melds, and giving cards
   their own `--gp-card-*` color family instead of spending surface roles.

Steps 1–4 of a 6-step plan are done. Steps 5 and 6 are not.

## What's done

- **A designed amber warning tone** replaces the transcribed Optics lemon in
  `core/theme.css`. Three consumers: the popup, and `message.css`'s
  `.response--alert` bubble. Both verified visually in dark mode.
- **`.popup` rewritten** (`components/ui/popup.css`) — transition-driven in both
  directions, actually centred, slides back out.
- **Turn-rejection flash** — `shared/_flash.html.slim`, `flash_controller.js`,
  `components/ui/flash.css`, and a two-stream `render_invalid_turn`.
- **`core/tokens/cards.css`** — the `--gp-card-*` family; `playing_card`,
  `hand_card`, `pile`, and `meld` all migrated off surface roles. Stale role
  comments in `roles.css` corrected.
- **Dimming gone**; piles get a coral ring + corner `+`; melds sit inset when
  they can't be laid off onto.
- **Melds gate on selection, not phase** — rendered `disabled`, enabled by
  `rummy_turn_controller#refresh` once ≥1 card is picked.

## Gotchas worth not rediscovering

- **`.op-page` is a grid and `.sidebar` is one of its items.** Adding the flash
  slot as a plain `<div>` in the layout claimed the first grid cell and pushed
  the sidebar to the right-hand side of *every page in the app*. Fixed with
  `.flash { display: contents }`. Nothing in 468 specs caught it — hence the new
  `spec/system/application_shell_spec.rb`, which asserts the sidebar's left edge
  is at x=0. It's a real guard: remove `flash.css` and it fails with `got: 1184`.
- **A transition only fires on a change.** The flash partial deliberately renders
  `.popup` *without* `.show`; the controller adds it a frame later (nested rAF).
  Server-rendering it with `.show` on gives no entry animation at all.
- **`visibility` in `.popup` is load-bearing beyond opacity.** Capybara ignores
  `opacity: 0` but honours `visibility: hidden`, and `spec/system/games_spec.rb`
  asserts the offline notice is *absent* until you go offline. Opacity alone
  makes that spec see the parked text and fail.
- **`--gp-font-size-x-large` is not a token in this app** (`scale.css` defines
  `--gp-font-x-large`; `--op-font-size-x-large` is Optics' name). The hand card's
  lock badge referenced it, so its `font-size` was invalid and silently
  inheriting. Fixed.
- **`.playing-card` carries its own `z-index: 1`.** A badge placed *before* it in
  the DOM loses the paint-order tie and is invisible — which is exactly why
  `.hand-card__lock` works (it's rendered after the card). The pile's `+` now
  does both: rendered after, and `z-index: 2`.
- **`ph-bold` is already Phosphor's heaviest stroke family.** The weight classes
  map to separate font files, so `font-weight` does nothing and `ph-fill` swaps
  to a solid glyph. `-webkit-text-stroke` is what thickens a Phosphor icon.
- **`login_user` has a pre-existing order-dependent flake**, unrelated to this
  work — `have_current_path(root_path)` in
  `spec/support/helpers/login_helper.rb:7` sees `/leaderboard` left over from a
  prior example. Reproduced with this session's work stashed, on the same seed.
  It failed on two *different* examples across four full runs, so expect
  occasional phantom failures until the helper is fixed.

## Decisions made

- **Rejection reasons come from the server, not a JS copy of the rules.** The `+`
  placeholder still appears at 3+ cards selected regardless of validity; clicking
  it submits and the flash explains. Rationale: `Meld.build` stays the single
  definition of a legal meld. This was chosen over porting `set?`/`run?` to JS.
- **The card family is a sanctioned exception to "components spend roles."** It
  reaches `--gp-n-*`/`--gp-w-*` directly because it *is* the naming layer. The
  bar for another such family is "several components must render the same
  material and cannot drift," not "this component has colors." Before, the meld
  chips matched real cards only because both referenced `--gp-surface-card`.
- **Two tokens beyond the agreed eight**: `--gp-card-face-focus` (DESIGN.md
  specifies the face brightens on focus; had no name) and `--gp-card-ring-live`
  (the pile's coral actionable ring, distinct from "selected").
- **Disabled things get no negative treatment at all.** Positive-only signalling:
  mark what you can touch. Fading skewed card ink off-colour; darkening the face
  read as damage. In the hand this costs nothing — during the meld phase every
  card is selectable, so a per-card mark would stamp all ten identically.
- **Hand cards get no new affordance cue** (explicitly deferred).
- **Melds render `disabled` unconditionally rather than from `can_select`** — a
  fresh render never has a selection, and it fails closed, so a broken JS bundle
  leaves melds unclickable rather than clickable-but-useless. `can_select` was
  dropped from `_meld`/`_felt`; the presenter's `can_select?` still serves the hand.
- **`opponent_strip.css`'s mini-cards stayed on surface roles.** Card-shaped and
  they use `--gp-card-aspect-ratio`, but they're 20px count pips with a
  deliberately different border (`--gp-color-border`). Open question, not an
  oversight.

## What's left

**Step 5 — the phase stepper.** Step 3 "Discard" can never light up: `phase` only
holds `"draw"`/`"meld"` and `_phase_stepper.html.slim` hardcodes step 3 with no
active branch. Agreed fix: derive it in Stimulus from
`checkedInputs.length === 1`, which also teaches the discard gesture (select one
card, the stepper moves to 3, the pile is where it goes). No state change.

**Step 6 — docs.** Both need updating and currently contradict the code:
- `DESIGN.md` still says a disabled card's "face darkens a shade," and its
  Card-selection spec describes the retired states.
- `DESIGN.md` + `docs/frontend.md` both state components spend roles and never a
  raw primitive — the card family is a real doctrine addition and should be
  written down rather than silently contradicted.
- The meld's new pressed elevation isn't in DESIGN.md's shadow vocabulary.

**Open questions for the user**

- The meld-phase discard pile shows a `+` when enabled, but there you're putting
  a card *down*, not taking one. Fix would be a phase-dependent glyph (plus when
  drawing, down-arrow when discarding) — phase is known server-side, visibility
  stays CSS-driven.
- The inset/raised meld states are **subtle**. The lever is the shadow pair, not
  the background: `--gp-lobby-bar-shadow` was tuned for the lobby's slate rows and
  the felt is darker and lower-contrast.
- The hand card's lock badge is still at the original `--gp-space-x-small` inset
  and plain `ph-bold`; the pile's `+` was padded and thickened past it, so the two
  have drifted despite being designed to mirror.
- A rejected turn **wipes the player's selection** (`render_invalid_turn` replaces
  the game partial, resetting the checkboxes), so you must re-pick all three cards
  to act on the advice. Pre-existing, but sharper now that the error is visible
  enough to act on.

**Not in scope, still missing from Rummy**: no hand sorting (see the separate
`2026-07-28-rummy-hand-sorting-investigation.md`), no stock count, and no notice
when the discard is recycled into the stock.
