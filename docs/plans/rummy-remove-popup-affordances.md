# Plan: replace Rummy's confirm popup with in-place affordances

## North-star goal

Every Rummy action is **obvious from the board itself** — no intermediate popup
asks you to confirm. Selecting cards changes what the board offers:

- **1 card selected** → the discard pile lights up; click it to discard.
- **3+ cards selected** → a meld-shaped **`+` placeholder** appears at the end of
  the shared-melds zone; click it to try to form a meld (server validates).
- **Lay-off** stays as it is: click an existing meld with a selection.

When you're done, `_confirm_pop` and everything that fed it are gone, and the
board does all the talking.

## Why this is a small, front-end-only change

The client-side selection refactor already landed. Hand cards are checkboxes
posting `turn[cards][]`; `RummyForm` validates `meld` / `discard` / `lay_off`
straight from the submitted keys (`selected_cards`); there is no server-side
`selected` state left. The turn contract (`action` + `cards[]` + `meld_index`)
already supports every action we need.

So the only thing still standing is the popup: `_confirm_pop.html.slim`, rendered
by `_felt`, styled by `confirm_pop.css`, and driven by `rummy_turn_controller`'s
`refresh()` (which toggles the meld/discard buttons by checked count). **No
model, form, presenter, or route changes are required** — this is views + one
Stimulus controller + CSS.

## The one new wiring need: phase in the controller

The discard pile must behave differently per phase (draw source vs. discard
target), but the Stimulus controller can't currently see the phase. Add it as a
Stimulus **value** on the form:

- `_rummy_game.html.slim`: on the `simple_form_for … data:` hash add
  `"rummy-turn-phase-value": game_info.phase` alongside `controller: "rummy-turn"`.
- Controller: `static values = { phase: String }`.

`game_info.phase` already exists on the presenter (`"draw"` / `"meld"`).

## Changes

### 1. Delete the popup

- **`app/views/rummy_games/_confirm_pop.html.slim`** — delete the file.
- **`app/views/rummy_games/_felt.html.slim`** — remove the
  `= render "rummy_games/confirm_pop"` line (last line).
- **`app/assets/stylesheets/components/confirm_pop.css`** — delete the file
  (Propshaft `:app` auto-includes by presence, so removing the file is the whole
  job — no manifest edit).
- **`app/assets/stylesheets/core/theme.css`** — remove the `--gf-popup-surface`
  token + its comment block (~lines 147–152) **iff** grep shows confirm_pop.css
  was its only consumer. Verify with `grep -rn "gf-popup-surface" app/` before
  deleting.

### 2. Discard pile → phase-aware target

`_pile.html.slim` today hardcodes `action: "draw_discard"` and
`enabled: can_draw && discard_top.present?`. The discard pile needs a second
role. Keep the stock pile untouched.

Two workable shapes — **pick the data-attribute one**:

- Give the discard-pile render a marker the controller can find, e.g. pass a
  `discardable: true` local (only the discard pile gets it) and render
  `data-rummy-turn-target="discardPile"` on that `.pile` button. In `_felt`, the
  discard pile's `enabled:` stays `can_draw && discard_top.present?` (its draw-phase
  behavior); the controller owns the meld-phase enable.
- The button's `data-action` still calls `#draw`. The controller's `draw` handler
  branches on phase: during `"meld"`, treat a click on the discard pile as a
  **discard** (`action = "discard"`) instead of `draw_discard`. During `"draw"`,
  unchanged.

Controller `refresh()` gains: when `phaseValue === "meld"`, set the discard
pile's `disabled` to `count !== 1` (so it lights up only with exactly one card
selected); when `"draw"`, leave the server-rendered disabled state alone.

CSS: the pile's existing `&:not(:disabled) .playing-card` outline + accent hover
already give the "clickable" look, so an enabled discard pile reads as actionable
for free. No new pile CSS unless we want a distinct discard-target accent.

### 3. Meld `+` placeholder

Add a meld-shaped placeholder as the **last child** of the melds
`.felt-zone__body` in `_felt.html.slim`, after the `melds.each_with_index` loop:

```slim
button.meld.meld--new hidden="hidden" type="button" data-rummy-turn-target="meldPlaceholder" data-action="click->rummy-turn#meld"
  span.meld__plus +
```

- It reuses `.meld`'s shape (rounded felt chip) via a `.meld--new` modifier that
  centers a large `+` glyph and drops the header/cards. Give it a min-width/height
  close to a real meld chip so it reads as "a meld will go here."
- Controller `refresh()`: `this.meldPlaceholderTarget.hidden = count < 3`.
- Clicking calls the existing `meld()` method unchanged (`action = "meld"`,
  `requestSubmit()`); the server's `selection_forms_a_valid_meld` validation is the
  only validity gate (per decision: no client-side meld checking).

CSS: add a `.meld--new` block to `meld.css` (dashed/muted outline, centered `+`,
same radius + background family as `.meld`). Follow BEM + `--op-*`/`--gf-*` tokens.

### 4. Slim the Stimulus controller

`app/javascript/controllers/rummy_turn_controller.js`:

- **Remove targets** `confirmPop`, `confirmPopText`, `meldButton`, `discardButton`.
- **Add targets** `meldPlaceholder`, `discardPile`. **Add value** `phase`.
- **Delete** `discardSelected()` if the discard now routes through the phase-aware
  `draw`/click path; or keep a dedicated `discard()` method the discard pile calls
  — whichever reads cleaner. (Either is fine; prefer one clearly-named method per
  action.)
- **Rewrite `refresh()`** to drive the two affordances instead of the popup:
  - `meldPlaceholderTarget.hidden = count < 3`
  - meld-phase: `discardPileTarget.disabled = count !== 1`
- Keep `draw`, `meld`, `layOff`, `checkedInputs` as-is (meld/layOff already do the
  right thing).

Keep every method ≤ ~7 lines (extract helpers if `refresh` grows).

## Testing

Match the existing layering — most of this is verifiable with the browser off, so
it does **not** belong in system specs:

- **Request spec (`spec/requests`)** — already the right home for the turn
  contract, and likely already covers it: posting `turn[action]=discard` with one
  `cards[]` key discards; `action=meld` with 3 valid keys melds; an invalid meld
  selection is rejected. Confirm these exist; add any missing case. No new server
  behavior is introduced, so ideally no new request assertions are needed.
- **System spec (`spec/system`, Playwright)** — the popup's removal and the new
  affordances are genuinely browser-only, so add **coarse** coverage here, single
  session per the multiplayer convention:
  - selecting exactly one card enables the discard pile; clicking it discards.
  - selecting 3 cards reveals the meld `+` placeholder; clicking it forms the meld
    (use a hand that can legally meld).
  - assert the `.confirm-pop` element no longer exists.
  Keep these few and behavior-level; don't re-assert rules the request/model specs
  already own.

## Out of scope / non-goals

- No changes to draw, lay-off rules, or going-out logic.
- No client-side meld validity checking (server stays the judge).
- No lay-off highlight cues (melds stay visually static).
- No touching the already-shipped checkbox/selection mechanism.

## Definition of done

- `_confirm_pop.html.slim` and `confirm_pop.css` are deleted; no `.confirm-pop`
  renders anywhere.
- With one card selected in the meld phase, the discard pile is enabled and
  discards on click; in the draw phase it still draws.
- With 3+ cards selected, the `+` meld placeholder appears at the end of the melds
  zone and forms a meld on click (server-validated).
- Controller carries no popup targets/methods; RuboCop clean; specs green.
