# Rummy feed: a stream, not a snapshot

## North star

**The message feed should behave like what it is — an append-only log — so that
showing a new message is an insertion, not a re-derivation.**

The visible ask is small: new bubbles slide in from the right, older ones move
up, and two messages never arrive at the same instant. The reason that ask is
expensive today is not the animation. It's that a stream is being delivered as a
repeated whole-page snapshot, so the client has to reconstruct "what's new?" by
diffing two consecutive renders of the same thing.

Fix the delivery and the animation is mostly CSS.

| | Serves |
|---|---|
| 1 · Decompose the broadcast; the feed becomes an `append` target | insertion, not re-derivation |
| 2 · Split the directive out of the feed | the feed is only history |
| 3 · The motion — keyframes on insert, CSS-only stagger | the visible ask |
| 4 · *(deferred)* Events instead of per-player strings | the log has identity |

Non-goals, explicitly: no scrollback or feed history UI, no timestamps rendered,
no sound, no work on Go Fish's or Crazy Eights' own message surfaces beyond not
regressing them.

---

## The diagnosis

Two facts drive everything below.

**There is no DOM continuity.** `GameTurboUpdate.broadcast`
(`app/services/game_turbo_update.rb`) replaces `dom_id(game)` — the entire
`.game--rummy` element — on every turn. Every bubble is a brand-new node each
render. So a CSS `transition` has no prior state to animate from, and "which
bubble is new" cannot be read off the DOM.

**Messages have no identity.** `CardGame::Message`
(`app/models/card_game/message.rb`) carries only `type` and `text`, and text is
not unique — `"#{actor.name} drew from the stock."`
(`app/models/rummy/turn_result.rb:11`) is byte-identical every time that
opponent draws. So identity can't be recovered from content either.

Together these are why the naive implementation needs sequence numbers, a
`localStorage` high-water mark, FLIP measurement, and a timer queue with
`disconnect()` cleanup. None of that is inherent to sliding a bubble in. It is
all the cost of the snapshot delivery.

`hand_arrival_controller.js` already pays this exact tax — it persists the
previous hand's card keys to `localStorage` purely to answer "which card is
new?" across the same replace. This is the second time the same wall has been
hit, which is the argument for fixing it at the source rather than a third time.

---

## 1 · Decompose the broadcast

**The change.** Stop replacing the whole game element. Split `GameTurboUpdate`
into targeted stream actions:

| Target | Action | Why |
|---|---|---|
| `board_<game>` | replace | genuinely a snapshot — who holds what, what's on the table |
| `hand_<game>_<user>` | replace | snapshot |
| `feed_<game>_<user>` | **append** | append-only by nature |
| `directive_<game>_<user>` | replace | snapshot — "what should I do now" |

Streams are already scoped per `(game, user)` via
`Turbo::StreamsChannel.broadcast_replace_to(game, user, target:, ...)`, so
`broadcast_append_to` slots in the same way.

**What this deletes.** Once the feed is an append target:

- New bubbles are *inserted*, so `@keyframes` fire on first paint — no `rAF`
  class-toggle trick.
- Surviving bubbles are the *same DOM nodes*, so ordinary CSS `transition`
  works on them. Smoother and interruptible, unlike keyframes.
- "Which one is new" is "the one just appended." Sequence numbers,
  `localStorage`, and the identity problem all evaporate.

**Initial page load still renders the container's existing contents** — the
partial renders the last N messages on a fresh `visit`, and only appends
thereafter. The server stops trimming to `first(2)`; retiring old bubbles moves
to the client (see §3).

**Files touched**

- `app/services/game_turbo_update.rb` — `broadcast` splits into per-target
  calls; `stream` (used by `TurnsController`) follows the same split.
- `app/views/rummy_games/_rummy_game.html.slim` — wrap board, feed, directive
  and hand in their own `id`'d containers.
- `app/views/rummy_games/_bubble_stack.html.slim` — becomes the feed container
  plus a `_feed_bubble` partial that a single append can render on its own.
- `app/presenters/rummy_game_presenter.rb` — likely a `new_messages` accessor
  so a broadcast can render only what this turn added.

**Watch for.** `Game#broadcast_refresh_to self` (`app/models/game.rb:8`) fires a
full page refresh on `started_at` change. That's game start, when the feed is
empty, so it's harmless — but it must stay that way, and any new
`broadcast_refresh_to` would wipe the feed.

**Watch for.** This touches the path all three games share. Go Fish and Crazy
Eights render a different message surface (`.message`, `message.css`) inside the
same replaced element, so their views need the same container split even if
their feeds stay replace-only. `spec/support/shared_examples/platform_game.rb`
asserts the STI contract and should be re-run early.

---

## 2 · Split the directive out of the feed

**The problem.** `.feed-bubble--directive` ("Waiting for opponent", "Draw from
the stock or discard pile") lives inside `.bubble-stack` alongside the message
bubbles, but it is *status*, not *history*. That conflation already cost real
time: styling the log required repeatedly deciding whether the directive counts
as a message, and an earlier `--ghost` / `--fade` split existed only to grade two
history entries against each other and was later removed as a distinction with
nothing behind it.

**The change.** The directive gets its own target and its own BEM block. The
feed becomes purely a log. The directive never animates — it just changes.

This also lets the feed be bottom-anchored independently, which keeps the
directive at a constant screen position instead of drifting as the feed fills.

**Files touched** — `_bubble_stack.html.slim`, `bubble_stack.css` (the
`--directive` modifier moves to a new `turn_directive.css`),
`_rummy_game.html.slim`.

---

## 3 · The motion

With §1 and §2 done, this is nearly all CSS.

**Entry.** A `@keyframes` slide-in-from-right, firing automatically on insert.
No JS.

**Stagger.** The server renders each newly appended bubble with an index custom
property, and CSS paces them:

```css
animation-delay: calc(var(--_gp-bubble-index) * 180ms);
```

No timers, no queue, no `disconnect()` cleanup, nothing to leak. "Never two at
once" becomes a one-line declaration.

**180ms, not a second.** Turns land back-to-back; a full-second hold makes the
second message feel broken. This is a decision, not a default — see below.

**Push-up.** `view-transition-name` per bubble, letting the browser compute the
FLIP. Verify current browser support before committing; the fallback is a
`grid-template-rows: 0fr → 1fr` row-expand on a wrapper div, where the upward
push comes free from layout and is automatically correct for one-line and
wrapped messages alike.

**Layout prerequisite.** `.bubble-stack` is `position: absolute; top: …` against
`.game--rummy`, which spans both the board *and* hand grid rows
(`game.css:29-35`) — so swapping `top` for `bottom` would land the stack down by
the hand dock. Instead give the stack a fixed height covering all slots plus
`justify-content: flex-end`, so items settle to the bottom of a reserved box.
This is DESIGN.md's "reserve space for a lift before animating one" (line 798).

**The `transform` collision.** `.feed-bubble--ghost` carries
`transform: scale(0.92)`. A keyframe animating `transform` overwrites it
wholesale and the bubble snaps to full size mid-animation. Use the independent
`scale:` and `translate:` properties instead — they compose without fighting.
Decide this before writing the keyframes; it changes how the ghost rule is
written.

**The only JS left** is a ~15-line Stimulus controller that plays an exit
animation and removes bubbles past N. This also kills the existing quirk where a
lone first message renders as `--ghost`, since the server no longer trims.

**Reduced motion.** There is no `prefers-reduced-motion` block anywhere in the
stylesheets today. Adding one here is a deliberate choice to make, not an
assumption — decide before building.

---

## 4 · Events, not per-player strings *(deferred)*

Recorded because it's the right end state, **not** part of the first pass.

`Rummy::TurnResult#broadcast` (`turn_result.rb:44`) takes both phrasings and
pushes a copy into every player:

```ruby
players.each { |p| p.add_normal_message(p == actor ? actor_message : onlooker_message) }
```

That is view logic in the model layer, and it stores N copies of one event inside
the jsonb blob, growing unboundedly, with no identity or timestamp.

The end state is a first-class `TurnEvent` — one event per action, stored once,
carrying a sequence and a timestamp — with per-viewer phrasing moved to the
presenter, which is where AGENTS.md already says per-user view construction
belongs. The `Messageable` duplication goes away, and stable DOM ids and
"how long ago" come free.

Keep events in the PORO/jsonb rather than promoting them to a table; the whole
architecture rests on that, and a table only earns its keep if game history
becomes a real product surface.

**Why it's deferred:** it's the largest change here, it touches serialization for
all three games plus the shared contract spec, and §§1–3 do not need it.

---

## Decisions to confirm before building

1. **Append vs. Turbo 8 morphing.** Morphing (`broadcast_refresh_to`, already
   used in `game.rb`) is the other credible path, but it diffs by `id` and so
   drags message identity back in. For an append-only stream, append is the
   honest primitive. Recommended: append.
2. **Stagger interval** — 180ms recommended, not the ~1s originally suggested.
3. **`prefers-reduced-motion`** — in or out of scope?
4. **View Transitions vs. `0fr → 1fr`** — pending a support check.

## Test plan

- `spec/services/game_turbo_update_spec.rb` (new) — the decomposition is the
  highest-value unit here: assert `broadcast` emits the expected targets and
  that the feed's action is `append`, not `replace`.
- `spec/requests/rummy_turns_spec.rb` — extend to assert a turn's response
  targets the feed with an append and does not target `dom_id(game)`.
- `spec/system/playing_rummy_spec.rb` — one coarse `:js` example: take a turn,
  assert the prior bubble is still present *and* a new one arrived. Do not
  assert animation timing. Per the "one session, not two" convention this stays
  single-session.
- A dark-mode `screenshot(...)` to eyeball the result, deleted afterward if it
  only served as scaffolding.
- Re-run `spec/support/shared_examples/platform_game.rb` consumers early —
  §1 touches the shared broadcast path.

## Out of scope

- Go Fish / Crazy Eights feed *behavior* (their containers change in §1; their
  motion does not).
- `TurnEvent` / the §4 refactor.
- Scrollback, timestamps, or any feed history UI.
- Sound.
- Accessibility or responsive work beyond not regressing what exists.

## Risks — what could argue against this

§1 touches all three games, not just Rummy. "One replace, always correct" is a
genuinely simpler thing to reason about, and there's a fair argument that a card
game with sub-second turns doesn't need surgical updates. The counter is that
the same wall has now been hit twice — `hand_arrival_controller`'s
`localStorage` diffing and this feed — and each targeted broadcast pays off
again for whatever animates next. But it isn't free, and it's worth giving up
the simpler model knowingly rather than by accident.
