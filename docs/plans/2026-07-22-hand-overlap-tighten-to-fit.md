# Plan: hand overlap tightens to fit (kill the scroll, restore the hover lift)

**Status: implemented.** See `docs/frontend.md` ("The hand row never scrolls…" gotcha)
for the mechanism as shipped. Two deviations from this plan, discovered by running
the specs rather than assumed: the narrow-viewport 40%-ratio example was moved to a
700×700 viewport (at 375px no real Go Fish hand — minimum 5 cards — ever fits at 40%,
so that assertion's premise didn't hold), and the `pageHasNoVerticalOverflow`
assertion was dropped from the "fits without scrolling" example (it was tripping on a
pre-existing, unrelated mobile-grid bug — see "Uncaptured / follow-up" below).

## North-star goal

**A hovered hand card rises up over the "Your Hand" header — at every hand size — and the hand never scrolls sideways.**

Everything below serves that one outcome. If a step doesn't move us toward it, drop it.

## Why this works (read this before touching code)

The hover-lift was breaking because the hand row scrolls horizontally, and a
horizontal scroll container is *required by the CSS Overflow spec* to clip
vertically too (if `overflow-x` computes to anything but `visible`, the UA
forces `overflow-y` to `auto`). So the 50px `translateY` lift got clipped at
the top of the panel instead of rising over the header. You cannot have
"scrolls sideways" and "lets a card escape the top" on the same element.

Previous sessions treated the wide-hand problem as **scroll vs. shrink the
cards**. Both of those are what *forced* the clip. The fix is a third axis:
**when a hand is too wide, the cards just overlap *more*** — like squeezing more
cards into a real hand. If the hand always fits, we never need `overflow-x`, so
the container never clips, so the lift always escapes. We don't patch the clip
bug; we delete the condition that causes it.

**Locked decision:** overlap tightens with *no floor* — the hand always fits,
even down to thin slivers on an absurdly large hand. It never scrolls and never
shrinks the cards. (Go Fish hands realistically stay small, so slivers are a
non-issue in practice.) Overlap never gets *looser* than the current 40%.

## Current state (as of this branch)

- `app/javascript/controllers/hand_controller.js` — a Stimulus `hand`
  controller measures rendered card width via `ResizeObserver` and sets
  `--gf-card-overlap` to a flat `-40%` of it. Recalcs on resize and (for the
  opponent accordion) on the native `toggle` event.
- `app/assets/stylesheets/components/playing_card.css` — cards are
  `.card-container--large { flex: 0 0 auto; height: 100%; aspect-ratio: 5/7 }`
  (never shrink, never distort — sized off the row's height). Each
  `.card-container` gets `margin-left: var(--gf-card-overlap, -20px)`; first
  child gets `0`. Hover: `.playing-card--playable:hover { transform:
  translateY(calc(-1 * var(--gf-card-hover-lift))) }` (`--gf-card-hover-lift:
  50px`).
- `app/assets/stylesheets/components/panel.css` — `.panel--hand .panel__body`
  has `overflow-x: auto` **and** an uncommitted, no-op `overflow-y: visible`
  (see git diff). This is the scroll container causing the clip.
- Own hand markup: `app/views/go_fish_games/_go_fish_game.html.slim`
  (`.panel__body.hand data-controller="hand"`) rendering
  `app/views/go_fish_games/_card.html.slim`.
- Opponent hand markup: `app/views/go_fish_games/_opponent.html.slim`
  (`details ... data-controller="hand"`, cards inside `.expanded__hand`).
- Specs: `spec/system/games_spec.rb`, contexts `[ Card overlap ]` and the
  mobile block that asserts the hand scrolls.

## The changes

### 1. `hand_controller.js` — tighten overlap to fit

Replace the flat-40% logic with "40% when it fits, tighter when it doesn't."
Keep the connect/disconnect/`ResizeObserver` wiring and the `toggle` action
untouched. Keep methods ~7 lines (project norm).

```js
import { Controller } from "@hotwired/stimulus"

const MIN_OVERLAP_RATIO = 0.4

// Connects to data-controller="hand"
export default class extends Controller {
  static targets = [ "card" ]

  connect() {
    this.resizeObserver = new ResizeObserver(() => this.updateOverlap())
    this.resizeObserver.observe(this.element)
  }

  disconnect() {
    this.resizeObserver.disconnect()
  }

  updateOverlap() {
    if (this.cardTargets.length === 0) return

    const cardWidth = this.cardTargets[0].getBoundingClientRect().width
    if (cardWidth === 0) return

    const overlap = this.overlapFor(this.cardTargets.length, cardWidth)
    this.element.style.setProperty("--gf-card-overlap", `${-overlap}px`)
  }

  overlapFor(count, cardWidth) {
    const min = MIN_OVERLAP_RATIO * cardWidth
    if (count < 2) return min

    const needed = cardWidth - (this.rowWidth() - cardWidth) / (count - 1)
    return Math.min(cardWidth, Math.max(min, needed))
  }

  rowWidth() {
    const row = this.cardTargets[0].parentElement
    const styles = getComputedStyle(row)
    const padding = parseFloat(styles.paddingLeft) + parseFloat(styles.paddingRight)
    return row.clientWidth - padding
  }
}
```

**The math.** Cards are `flex: 0 0 auto`, so `cardWidth` is constant
regardless of overlap (overlap is a negative margin, not a size). The step
between adjacent card lefts is `cardWidth - overlap`. Total laid-out width for
`n` cards is `cardWidth + (n-1)*(cardWidth - overlap)`. Setting that `<=`
available width and solving for `overlap` gives the `needed` value above.
`Math.max(min, needed)` means "never spread looser than 40%"; `Math.min(cardWidth, …)`
caps at fully-stacked (step 0) for the pathological case.

**Why `rowWidth()` reads `cardTargets[0].parentElement`, not `this.element`:**
for the own hand `this.element` *is* the flex row, but for the opponent
accordion `this.element` is the `<details>` while the cards live in
`.expanded__hand`. Measuring the card's actual parent is correct for both. The
`--gf-card-overlap` var is still set on `this.element` — it cascades down to the
`.card-container` descendants either way.

### 2. `panel.css` — stop clipping

In `.panel--hand .panel__body`, replace both overflow lines:

```css
    overflow-x: auto;
    overflow-y: visible;
```

with a single:

```css
    overflow: visible;
```

That's the whole fix on the CSS side — the lift now escapes upward over the
header (this is exactly how it behaved before scroll was ever added; grid
paint order already puts the hand panel above the board panel, so no z-index
work is needed — verify though).

**Do NOT add `justify-content: center`.** The hand is currently left-aligned
(flex-start) and the user likes the current layout. Preserve it. This is a
deliberate non-change.

### 3. No token changes needed

The uncommitted `theme.css` diff (removing dead `--gf-card-height-large`,
`--gf-card-width-large`, `--gf-card-width-min`) is fine — leave it removed.
`--gf-card-overlap`'s `-20px` fallback in `playing_card.css` stays as-is.

### 4. Specs — `spec/system/games_spec.rb`

Keep these unchanged (still true): the 40%-ratio examples at normal and narrow
viewports, the opponent-ratio example, and the aspect-ratio-holds example.

Rewrite the two that assert scrolling:

- **The mobile "lets the hand scroll horizontally" example (~line 224).** It
  asserts `overflowX === "auto"`. Flip it to assert the hand no longer clips:
  ```ruby
  it "keeps the hand un-clipped so a hovered card can lift past the row", :js do
    resize_page(375, 700) do
      visit game_path(game)

      overflow_x = page.evaluate_script(
        "getComputedStyle(document.querySelector('.panel--hand .panel__body')).overflowX"
      )

      expect(overflow_x).to eq "visible"
    end
  end
  ```

- **The "scrolls the hand horizontally instead of shrinking" example (~line
  280).** It asserts `rowScrollsHorizontally` is true. Invert it — a large hand
  must now *fit* by tightening, without scrolling and without shrinking cards:
  ```ruby
  it "tightens overlap so a large hand fits the row without scrolling", :js do
    large_hand_game = create(:started_game, :go_fish, :users_turn, :many_participants,
                              user: user, users_count: 2)

    resize_page(375, 700) do
      visit game_path(large_hand_game)

      fit = page.evaluate_script(<<~JS)
        (function() {
          var row = document.querySelector(".panel--hand .panel__body");
          return {
            fitsWithoutScroll: row.scrollWidth <= row.clientWidth + 1,
            pageHasNoVerticalOverflow: document.documentElement.scrollHeight <= window.innerHeight + 1
          };
        })()
      JS

      expect(fit["fitsWithoutScroll"]).to be true
      expect(fit["pageHasNoVerticalOverflow"]).to be true
    end
  end
  ```

- **Optional but recommended** — one example proving the tightening actually
  happens (the core new behavior). A large hand's gap should be *tighter* than
  the 40% baseline. Reuse the existing `card_pair_offset` helper:
  ```ruby
  it "tightens the overlap below 40% when the hand is too wide for 40%", :js do
    large_hand_game = create(:started_game, :go_fish, :users_turn, :many_participants,
                              user: user, users_count: 2)

    resize_page(375, 700) do
      visit game_path(large_hand_game)

      offset = card_pair_offset(".panel--hand .card-container")

      expect(offset["gap"]).to be < offset["width"] * 0.6
    end
  end
  ```
  (`gap == width * 0.6` is the 40%-overlap step; a tightened hand steps by
  less.) Confirm `:many_participants, users_count: 2` actually yields a hand
  wide enough to force tightening at 375px — if not, bump the hand size or drop
  this example rather than assert something that isn't triggered.

Follow the repo's lean-spec norm: let `describe`/`context`/`it` carry intent,
no comment scaffolding.

## Verification

1. `bundle exec rspec spec/system/games_spec.rb` — the `[ Card overlap ]` and
   mobile contexts pass.
2. `bin/rubocop` clean (Ruby only; JS/CSS unaffected).
3. Manual (`bin/dev` + a started Go Fish game, worker running for turns):
   - Small hand: 40% overlap, hover lifts a card clearly **above** the "Your
     Hand" header, unclipped.
   - Force a wide hand (2-player game deals more): cards bunch tighter, the row
     does **not** scroll and does **not** grow the page vertically, cards keep
     their 5:7 shape, and hover still lifts over the header.
   - Resize the window narrower/wider: overlap recomputes live and stays fitted.
   - Open an opponent accordion: their hand tightens to its own row too, no
     regression.

## Out of scope / flag, don't fix

- **Mobile layout** (`game.css` `@media (max-width: 768px)`): the hand grid row
  is `auto`-sized there, which breaks the `height: 100%` → `aspect-ratio`
  chain the card sizing depends on. This plan targets desktop; the mobile spec
  above only checks overflow/scroll behavior, which the CSS change fixes
  regardless. Don't rework the mobile grid here.
- **Crazy Eights:** `.panel--hand` CSS is shared. Verify the Crazy Eights hand
  view uses `data-controller="hand"` with `.card-container--large` cards; if so
  this fix applies to it for free — just eyeball it. If it renders its hand
  differently, note it and leave it for a follow-up rather than expanding scope.
- **The arc/fan hover** (Hearthstone-style) is a possible future evolution of
  this exact approach (same `overflow: visible` + spacing-absorbs-cards
  foundation, plus per-card rotation). Not part of this plan — don't build it.

## Related

- Supersedes the open thread in
  `docs/handoffs/2026-07-21-dynamic-hand-card-overlap.md` (the "what's left"
  section, where scroll-vs-clip was still unsolved). The scroll-based direction
  recorded there is intentionally reversed by this plan.
