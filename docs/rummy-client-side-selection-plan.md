# Plan: make Rummy card selection a client-side interaction

## North-star goal

Selecting/deselecting a hand card is a **local, client-only** interaction with a
stable DOM node — so CSS transitions animate both ways — while **draw, meld,
lay-off, and discard stay real, server-persisted, broadcast turns**. Selection
stops touching the `state` jsonb column and stops broadcasting to anyone.

## Why it breaks today (one paragraph)

`rummy_turn_controller#toggleSelect` submits a full turn. `TurnsController`
persists `Rummy::Player#selected` into `state`, then `BroadcastGameJob` replaces
the entire `.game` div for **every** participant. So a click that only affects
the actor's own view remounts the whole board — there is no stable node for a
`transition` to animate from, which is why we resorted to a `@keyframes` lift and
why deselect can't be animated (every non-selected card also remounts and replays
the settle keyframe together). Removing selection from the turn loop deletes the
remount that caused all of this.

## Target design

Selection lives entirely in the DOM/Stimulus. On **commit** (meld / lay-off /
discard) the currently-selected card keys are sent as a `cards[]` array param;
the server validates and applies them. `toggle_select` as a turn action, and
`Rummy::Player#selected` as persisted state, both go away.

### Use native checkboxes — recommended

Make each hand card a visually-hidden `<input type="checkbox">` inside a
`<label class="hand-card">`. This buys us, for free:

- **Native selection state** — no manual JS Set, no class bookkeeping.
- **`:checked` styling** — `.hand-card__input:checked ~ .playing-card { … }`
  toggles on a stable node, so `transition` animates select *and* deselect. The
  `@keyframes gf-card-select-lift` hack and the "swaps the whole hand partial in"
  comment in `playing_card.css` both get deleted.
- **Free form serialization** — checked boxes named `turn[cards][]` land in
  params automatically on `requestSubmit()`; no gathering step in Stimulus.
- **Accessibility** — real focusable, toggleable controls.

`disabled` on the input (bound to `can_select?`) covers the draw-phase "can't
select yet" state. Stimulus shrinks to: on `change`, recompute the count-driven
affordances (below); commit actions set the hidden `action`/`meld_index` and
`requestSubmit()`.

## Where `player.selected` is read today → what it becomes

| Location | Today | After |
|---|---|---|
| `Rummy::Game#toggle_select` | mutates `selected`, persists | **deleted** (action removed) |
| `Rummy::Game#meld/#lay_off/#discard_card` | consume `active_player.selected`, reset it | take a `cards` argument passed in from the turn |
| `Rummy::Player#selected` + `serializes selected:` | persisted jsonb field | **deleted** from the class and the schema |
| `RummyForm` meld/discard/lay_off validations | read `game.active_player.selected` | read a resolved `cards` list from the submitted keys |
| `RummyForm#card_is_in_hand` (toggle_select) | validates the toggled card | **deleted** (no toggle action) |
| `RummyGamePresenter#hand_cards` `selected:` | `player.selected.include?(card)` | dropped — cards render unselected; JS owns selected state |
| `RummyGamePresenter#can_meld?/#can_discard?/#selected_count` | derive confirm-pop from persisted selection | **deleted** — confirm-pop is client-driven |
| `RummyGamePresenter` meld `faded`/`can_lay_off`/`selecting?` | fade non-candidate melds from persisted selection | **see open decision below** |
| `RummyGamePresenter#can_select?` | user turn && meld phase | **kept** — gates whether checkboxes are enabled |

## Server changes

- **`Rummy::Player`** — remove `attr_accessor :selected`, the `@selected = []` in
  `initialize`, and `serializes selected: [ CardGame::Card ]`. (In-flight games
  drop any persisted selection; it's ephemeral, so this is fine. A missing key
  already loads as `[]` per `docs/serialization.md`, so nothing else breaks.)
- **`Rummy::Game`** — delete `toggle_select` and its `case` branch. Change
  `play_turn(action, card = nil, meld_index = nil)` →
  `play_turn(action, cards = [], meld_index = nil)`. `meld`, `lay_off`,
  `discard_card` take `cards` explicitly instead of reading/clearing
  `active_player.selected`; they still remove the cards from the hand and (meld/
  lay_off) append to `melds`.
- **`RummyGame`** — `permitted_turn_params` → `[:action, :meld_index, { cards: [] }]`
  (drops `:card`). `turn_target(action:, meld_index: nil, cards: [])` resolves each
  `"rank-suit"` key against the active player's hand (reuse the existing
  `card_from_key` logic, mapped over the array) and returns `[action, resolved, meld_index]`.
- **`RummyForm`** — replace `attr_accessor :card` with `:cards`. Add a private
  `selected_cards` that maps keys → hand cards (compact). Rewrite
  `selection_forms_a_valid_meld` (`Meld.valid?(selected_cards)`),
  `exactly_one_card_is_selected` (`selected_cards.size == 1`), and
  `lay_off_targets_a_valid_meld` (`target_meld.can_add?(selected_cards)`) to use it.
  Drop `toggle_select` from `ACTIONS` and delete `card_is_in_hand`.
- **`TurnsController`** — no change; `game_params` already splats
  `permitted_turn_params` and merges `game: @game.state`.

## View / CSS / Stimulus changes

- **`_hand_card.html.slim`** — render a `<label>` wrapping
  `input type=checkbox name="turn[cards][]" value="rank-suit" disabled=(!can_select)`,
  plus the existing `.playing-card`. Drop the `--selected` server class and the
  `data-rummy-turn-card-param`; add `data-action="change->rummy-turn#refresh"`.
- **`_confirm_pop.html.slim`** — always render both buttons; hide via a Stimulus
  target/class and let `refresh` show "Discard" at exactly 1 checked and "Create
  meld" at ≥3 checked. It stops depending on `can_meld?`/`can_discard?`.
- **`rummy_turn_controller.js`** — remove `toggleSelect`. Add `refresh` (reads
  `this.checkedInputs.length`, toggles confirm-pop buttons). `meld`, `layOff`,
  `discardSelected` keep setting `action`/`meldIndex` and `requestSubmit()` — the
  checked `cards[]` ride along automatically. Remove the `card` hidden field/target.
- **`playing_card.css` / `hand_card.css`** — drive `--selected` styling from
  `:checked` (sibling/`:has()` selector on the label), restore a normal
  `transition` for lift/settle, and delete the `@keyframes gf-card-select-lift`
  workaround and its explanatory comment.

## Broadcast question — narrow it?

**Recipient set: keep broadcasting to everyone.** The four remaining moves all
change shared state (draw changes counts + phase; meld/lay-off change the public
melds; discard changes the pile and passes the turn), so every participant still
needs them. What changes is **volume**: selection was by far the chattiest action
(one broadcast per click), and it disappears entirely.

The full-`.game`-replace on real moves still remounts the board, so those moves
still can't CSS-animate. That's out of scope here — but worth a follow-up: switch
`broadcast_replace_to` to Turbo **morph** so real moves preserve stable nodes too.
Not part of this change.

## Test migration

**Selection *mechanics* move to the system spec** (it's now pure client behavior,
untestable below the browser):

- `spec/system/playing_rummy_spec.rb` — assert clicking a hand card toggles
  `--selected` **with no round-trip**, and clicking again removes it (the deselect
  case that broke — add it explicitly). Drop the `Capybara.using_wait_time(5)`
  workaround and the per-toggle broadcast waits; selection is now instant. The
  draw→select→discard, meld-three, and lay-off flows stay but their select steps
  no longer wait on the server.

**Rules validation stays at model / form / request**, re-expressed to pass cards
explicitly instead of via persisted `selected`:

- `spec/forms/rummy_form_spec.rb` — delete the three `toggle_select` contexts.
  Meld/discard/lay-off contexts set `let(:cards) { ["9-Hearts", …] }` instead of
  `active_player.selected = …`.
- `spec/models/rummy/game_spec.rb` — delete the `toggle_select` examples. Meld/
  lay-off/discard examples pass cards as an argument to `play_turn` rather than
  setting `active_player.selected` first.
- `spec/models/games/rummy_game_spec.rb` — replace the "resolves a toggle_select
  card key" example with one asserting `turn_target`/`play_turn` resolves a
  `cards` array of keys to real cards. Update `permitted_turn_params` expectation
  to `[:action, :meld_index, { cards: [] }]`. In the `winning_turn` lambda, drop
  `champion.selected = …` and instead return `{ action: "discard", cards: [key] }`.
- `spec/requests/rummy_turns_spec.rb` — collapse the multi-post select sequences
  into single posts: discard → `{ action: "discard", cards: [key] }`; meld →
  `{ action: "meld", cards: [3 keys] }`; lay-off →
  `{ action: "lay_off", cards: [key], meld_index: "0" }`.
- `spec/presenters/rummy_game_presenter_spec.rb` — delete the `hand_cards`
  `selected:` flag examples, the `selected_count`/`can_meld?`/`can_discard?`
  describes, and (per the open decision) the meld `faded` examples.

## Rules-aware affordances — interim vs. future (decided)

Two affordances today are *rules-aware*, not just count-aware: the "Create meld"
button only shows for a **valid** run/set, and non-candidate melds **fade** during
selection (`meld.can_add?`). Once selection is client-only, the server no longer
knows the selection, so it **cannot** compute either — they can only come back by
running the Rummy rules in the browser.

**Future direction (not this change):** replace the confirm-pop "Create meld"
button with a little **`+` shown in the melds zone** when the current selection
forms a valid meld, and **dim existing melds** by whether the selection can lay off
onto them. Both require a JS port of `Meld.valid?` + `can_add?` (run/set
detection). This is deferred; client-side selection is the foundation it builds on,
so nothing here is throwaway.

**Interim (this change) — thin client:**

- Create-meld/discard stay in the count-driven confirm-pop (meld at ≥3 selected,
  discard at exactly 1). A ≥3 selection that isn't a valid run/set is rejected on
  submit via the existing `render_invalid_turn` error path.
- **All existing melds stay clickable lay-off targets during the meld phase**
  (decided). Clicking one whose selection can't legally extend it is rejected the
  same way. No fade in the interim.
- Delete the presenter's `faded`/`can_lay_off`/`selecting?` logic and its specs
  now; they'll be reintroduced client-side with the future work. `_meld.html.slim`
  keys its `disabled` off the meld phase (`can_select?`) instead of `can_lay_off`.

## Suggested TDD order

1. Model layer: `Rummy::Game`/`Rummy::Player` (drop `selected`/`toggle_select`,
   thread `cards`) + their specs.
2. Glue: `RummyGame#turn_target`/`permitted_turn_params` + spec; `RummyForm` +
   spec; request spec.
3. Presenter: strip selection methods + spec.
4. Views/CSS/Stimulus: checkboxes, `:checked` styling, confirm-pop, controller.
5. System spec: assert client-side select/deselect with no round-trip.
