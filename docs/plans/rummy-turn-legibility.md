# Rummy: a turn you can play by looking

## North star

**A Rummy turn should be readable at a glance, and should never punish you for
exploring it.**

Today the turn works but it interrogates you. You select cards and the UI won't
say whether they mean anything until you commit; when it refuses, it wipes your
selection and you start over. Your hand arrives unsorted. The card you just drew
vanishes into it. And you cannot see how close anyone else is to going out —
which in Rummy is the only number that matters.

Five changes, all serving that one goal:

| | Serves |
|---|---|
| Illegal moves become unclickable, not rejected | never punished |
| A refused turn keeps your selection | never punished |
| Hand sorted by rank on arrival | readable at a glance |
| An arriving card settles into the hand | readable at a glance |
| Opponent hand size is visible | readable at a glance |

Non-goals, explicitly: no drag-and-drop, no new error surfaces, no words
explaining why a selection is invalid, no accessibility or responsive work
beyond not regressing what exists.

---

## 1 · A refused turn keeps your selection ✅

**The problem.** `TurnsController#render_invalid_turn`
(`app/controllers/turns_controller.rb:38`) streams two things: the flash, and a
full game re-render via `GameTurboUpdate.stream`, which replaces
`dom_id(game)` — the entire `.game` div, hand included
(`app/services/game_turbo_update.rb:4-11`). A Turbo re-render resets the
checkboxes (as `_meld.html.slim:1` already notes). So select four cards, click
`+`, get refused, and all four deselect.

The re-render buys nothing. On an invalid turn the form never runs, state is
unmutated, and the re-rendered DOM is byte-identical to what's on screen apart
from the wiped selection. Its comment claims the re-render exists so the form's
errors reach the presenter — but nothing renders them: `grep -rn errors
app/views/rummy_games app/views/games` is empty, and `form` is only ever read at
`game_presenter.rb:10` to build a default.

**The change.** `render_invalid_turn` streams the flash only. Drop the
`GameTurboUpdate.stream` line and the now-false comment.

**Spec** — `spec/requests/rummy_turns_spec.rb`, extending the existing
"selects cards that don't form a meld" context: assert the response body
replaces `flash` and does *not* target `dom_id(game)`.

**Watch for.** `GameTurboUpdate.stream`'s `form:` parameter becomes unused by
this path. Leave the service alone — `broadcast` is the hot path and this is not
a refactoring pass.

---

## 2 · Illegal moves become unclickable ✅

**The problem.** `rummy_turn_controller#refresh` gates purely on *count*: `+`
appears at 3 selected cards, and **every** meld enables at 1 selected card.
Legality is discovered only by submitting.

**Why this is cheap.** `Rummy::Meld`'s whole rule set is four short predicates
(`app/models/rummy/meld.rb:52-68`) — a set is "≥3, one rank, distinct suits", a
run is "≥3, one suit, consecutive distinct ranks", and `can_add?` is just "does
`existing + new` still build to the same kind". The hand already carries
`data-rank-value` (the `Meld::RANK_VALUES` number) and `data-suit-index`
(`_hand_card.html.slim:1`).

**The change.**

- New `app/javascript/rummy_melds.js` — a direct port of `Meld`'s predicates:
  `isSet`, `isRun`, `kindOf`, `canAdd`. Pure functions over
  `{rankValue, suitIndex}`, no DOM.
- `_meld.html.slim` — its cards get `data-rank-value` / `data-suit-index` so the
  client can evaluate `canAdd` against each meld. Per the always-render-through-
  a-presenter rule, `RummyGamePresenter#meld_view` maps `cards` through a small
  `MeldCardView(card:, rank_value:, suit_index:)` rather than the template
  reaching into `Rummy::Meld::RANK_VALUES`. The view keeps using
  `meld_card.card.red?` and `.card.to_s`.
- `RummyGamePresenter` — add `can_lay_off?` (`user_turn? && melds.any? { owner
  == user.id }`), mirroring `RummyForm#player_owns_a_meld`. Threaded through
  `_felt` into `_meld`; when false, `_meld` renders **without** its
  `data-rummy-turn-target="meld"`, so the controller structurally cannot enable
  it. Fails closed, no JS branch.
- `rummy_turn_controller#refresh` — `+` is hidden unless `isMeld(selection)`;
  each meld enables only when `canAdd(thatMeld.cards, selection)`. Discard
  gating is already correct; leave it.

**No words.** Purely `hidden`/`disabled` toggling. `.feed-bubble--directive`
keeps its current static phase text, untouched. Server rejections keep going to
the global flash exactly as `turns_controller` does today.

**The real cost, stated plainly.** Meld validity is now encoded in two places,
Ruby and JS. The mitigation is that JS is advisory only — the server stays
authoritative and `RummyForm` is unchanged — which is the stance
`_meld.html.slim:1` already takes. But a future rule change must touch both, and
nothing enforces that. Accepted deliberately; the alternative (a validate
endpoint) means a round-trip per checkbox click.

**Specs.**
- `spec/javascript/` doesn't exist; the ported predicates are covered
  indirectly. If you want them covered directly, say so and I'll add a JS test
  setup — otherwise coverage is the system spec below plus the untouched
  `spec/forms/rummy_form_spec.rb`, which still proves the server rules.
- `spec/presenters/rummy_game_presenter_spec.rb` — `can_lay_off?` false before
  you own a meld, true after; `meld_view` cards expose rank value and suit index.
- `spec/system/playing_rummy_spec.rb`, one coarse `:js` example: select three
  cards that don't form a meld → `+` stays hidden; select a run → `+` appears.
  Reuses the existing `click_hand_card` / `draw_from_stock!` helpers.

---

## 3 · Hand sorted on arrival ✅

`hand_sort_controller.js:12` only applies a sort when localStorage already holds
a preference, so a first-time player gets a shuffled hand and has to discover the
sort buttons. An unsorted hand is the single largest cognitive load in Rummy.

**The change.** `this.applySort(savedMode || "rank")`. One line.

**Spec** — extend an existing `:js` example in
`spec/system/playing_rummy_spec.rb` to assert the rendered `.hand-card` order is
ascending by `data-rank-value` on first visit with no stored preference.

---

## 4 · Opponent hand size is visible 🟡

**The problem.** `app/views/rummy_games/_opponent.html.slim:11` renders
`3.times do` — three hardcoded silhouettes, identical for a player holding ten
cards and one holding one. `OpponentView` doesn't even carry a count, though
`RummyGamePresenter#score_for` already returns `player.cards.size` and
`score_label` already reads "Cards left".

**The design** (your call, confirmed): one silhouette per card, heavily
overlapped so ten still fit, with a count badge on the topmost card. Stack width
becomes the glanceable threat read; the badge gives the exact figure. Picture and
number can never disagree.

```
  ★ Dana                 Wes
  ──────────────         ──────────────
  ▓▓▓▓▓▓▓▓▓▓▓█9█         ▓▓▓█3█
  ╰─ 10 cards ─╯         ╰ 3 ╯
```

**The change.** `OpponentView` gains `card_count`. `_opponent.html.slim`
renders `card_count.times`, with the last silhouette carrying the number.
`opponent_strip.css` swaps `gap: var(--gp-space-3x-small)` on
`.opponent-card__hand` for a negative inline margin on
`.opponent-card__mini-card`.

**Three real risks here — this is the item most likely to look wrong before it
looks right.**

1. **The digit may not fit.** `.opponent-card__mini-card` is
   `width: var(--gp-space-medium)` — far too small for a legible numeral. The
   badge card likely has to grow, or the number sits half-outside it. Expect to
   tune.
2. **Width budget.** `.opponent-card` is `min-width: calc(11 *
   var(--gp-space-scale-unit))` and the strip is a centered flex row. Ten
   overlapped cards plus a badge may force the card wider, which at four players
   pushes the strip's total width. Needs checking at 3 and 4 players, not just 2.
3. **The `--turn` state inverts the fill.** `opponent_strip.css:52-56` paints
   mini-cards `currentColor` — a solid ink block — for the active player. A
   number drawn *on* that is invisible; the badge card needs its own treatment in
   that state. Also: if the badge needs `position: relative`, that creates a
   stacking context, which is exactly the paint-order trap `_pile.html.slim:7`
   warns about. Overlap alone needs no z-index — later siblings already paint on
   top.

**Specs.** `spec/presenters/rummy_game_presenter_spec.rb` for `card_count`
(that's the layer that can prove it). Then a screenshot `:js` spec per the
project convention — dark mode via `emulate_media(colorScheme: "dark")`, at 4
players, `screenshot("opponent-strip-counts")` — and I read the PNG to confirm
all three risks above are actually resolved. That scaffolding spec gets deleted
once it's confirmed; the presenter spec stays.

---

## 5 · An arriving card settles into the hand 🟡

**The trigger is membership, not drawing.** Any card in your hand that wasn't
there before the last render settles in. In Rummy that happens to mean "a draw",
since drawing is the only way to gain a card — but the implementation diffs the
hand rather than listening for a draw, so it can't miss a path.

Scoped to Rummy for now. Generalizing to Go Fish (where cards arrive from an
opponent's response, with no draw involved) would need a card key on
`go_fish_games/_hand_card`, which has no identifier today. Deferred.

### Reuse the existing motion — do not author a keyframe

The animation is already built. `playing_card.css:44` transitions
`transform 0.2s ease-in-out`, and `hand_card.css:83` lifts a selected card by
`translateY(calc(-1 * var(--gp-space-large)))`. The comment there is explicit:
that transition animates **both** select and deselect, "no keyframe or remount
workaround needed." The lower-into-hand motion we want *is* the deselect
direction of that transition, with a distance that's already a designed value.

So an arriving card gets a class applying that same `translateY`, and the class is
removed on the next animation frame — the existing transition carries it down,
identically to a deselect. One source of truth for both the distance and the
easing.

```css
/* hand_card.css — the raised START state only. The lowering itself is the
   transform transition already declared on .playing-card. */
.hand-card--arriving .card-container .playing-card {
  transform: translateY(calc(-1 * var(--gp-space-large)));
}
```

**Why the rAF is load-bearing, and not removable.** The existing lift works
because, as `hand_card.css:80` says, `:checked` is a stable pseudo-class on a
stable node — the input never remounts, so there's a previous value to transition
*from*. An arriving card is a brand-new node, and a transition cannot fire on
first paint. Applying the class, then removing it one frame later, is what
manufactures the "from" state. Anyone who "simplifies" the `requestAnimationFrame`
away will get a card that simply appears in place, with no error.

### Identifying arrivals

`hand_arrival_controller.js`, added to `.hand-dock` alongside `hand-sort`. Named
for the trigger (a card arrived), not the effect or the cause.

There is no existing controller that watches the player's hand, and neither
candidate fit: `hand_controller` is, despite its name, Go Fish's *opponent
dropdown* overlap calculator (`go_fish_games/_hand_card.html.slim` is not
involved — see `go_fish_games/_opponent.html.slim:1`), and folding arrival into
`hand_sort_controller` would put it behind a name that means sorting.

It stores the hand's card keys in localStorage under
`rummy-hand:${gameId}:${userId}` — the same game/user-scoped pattern
`hand_sort_controller` already uses, and for the same reason: every Turbo render
replaces the whole `.game`, so the controller's element is destroyed and
in-memory state cannot survive. On connect, any key absent from the stored set
gets `.hand-card--arriving`; the set is then stored, and the class dropped on the
next frame.

Keys come free from the existing `.hand-card__input` `value`
(`_hand_card.html.slim:2`), so **no view changes at all** — the whole item is one
new controller, one `data-controller` token on `.hand-dock`, and the CSS rule
above.

Correct on every path: a draw adds one key → it settles. A reload finds stored ==
current → nothing moves. Melding or discarding only removes keys → nothing moves.
An opponent's broadcast leaves your hand untouched → nothing moves. The first
render ever stores without marking, so the hand doesn't cascade on page load.

### Two ordering subtleties

- `hand_sort_controller#applySort` reorders via `fan.append(...cards)`, and
  re-appending a node can reset an in-flight transition. Because the arrival
  class is dropped in a `requestAnimationFrame`, sort's synchronous reorder
  always completes first. This resolves itself — but only by luck of timing, so
  it's written down here.
- A `transform` on `.playing-card` is already how selection works, and
  `.playing-card` already carries `position: relative; z-index: 1`
  (`playing_card.css:31-32`). So arrival paints exactly like a selected card
  does, and the `_pile.html.slim:7` stacking-order trap doesn't apply.

### Verification: by running the app, not by a spec

The arrival class exists for about one frame, which no Capybara matcher can
observe without racing, and a mid-transition screenshot is worse. Given this
project's flake history (two handoff docs on exactly that), I'd rather have no
spec than a flaky one. Confirm with `bin/dev`: draw a card and watch it settle.

This is a deliberate exception to the house spec-first rule, so it is yours to
reject — if you want it locked in, the honest way is to hold the class until
`transitionend` instead of one frame, accept a ~200ms assertion window, and know
that it is a flake risk rather than a guarantee.

---

## Flagged for your call, not assumed

- **`prefers-reduced-motion`.** Three lines in `hand_card.css` to skip the
  settle for users who ask for less motion. Scope Discipline says I don't add
  unrequested extras, so I'm asking: in or out?
- **A stale client submitting out of turn fails invisibly.**
  `TurnsController#check_user_turn:21` renders `json:` with a 422, which a Turbo
  form submit does nothing visible with. Adjacent to item 1 and a genuine bug,
  but outside what you asked for. Flagging, not folding in.

## Build order

1. **Item 1** — server-only, isolated, smallest diff. Do it first so the rest of
   the work stops eating your selection while you test it by hand.
2. **Item 3** — one line.
3. **Item 2** — the bulk of the work; depends on the `_meld` data attributes and
   `can_lay_off?`.
4. **Item 5** — independent.
5. **Item 4** — last, because it's the one that needs screenshot iteration.

`bundle exec rspec` green and `bin/rubocop` clean at each step.
