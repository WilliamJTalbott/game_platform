# Game Lobby — Waiting Room

**Goal: make the gap between *creating* a game and *starting* it a real, live place.**
A player who lands on a game that hasn't started should immediately know who's here,
how many more are needed, and who is going to press Start — and should see all of
that change the moment someone else joins, without touching the page.

Status legend: 🟡 planned · 🟢 in progress · ✅ done

---

## 1. Where we are today

There is no waiting state. There's a **card floating over an empty game board**,
copy-pasted into all three game partials:

```slim
- unless game_info.started?
  .overlay.card
    h1 Waiting for players...
    = button_to "Start Game", start_game_path(game_info.game), method: :post, class: "btn btn--primary"
```

`_go_fish_game.html.slim`, `_crazy_eights_game.html.slim`, `_rummy_game.html.slim`.
Behind it the real board renders with every section blanked by `- if game_info.started?`
guards.

**Defects this plan closes:**

1. **The game page has no shared stream.** `games/show.html.slim:1` subscribes to
   `turbo_stream_from @game, Current.session.user` — a *per-user* channel. Joining and
   starting broadcast only to `"games"` (`game.rb:6-7`, `participant.rb:5`), which is the
   **index** page's stream. Nobody sitting on the game page hears anything. This is the
   reported "starting doesn't refresh for other users."
2. **`GamesController#start` crashes on its failure path.** `render :show,
   status: :unprocessable_content` never assigns `@game_info`, and `show.html.slim` calls
   `@game_info.finished?` → `NoMethodError` on nil. Any failed start hits this. Untested,
   which is how it survived.
3. **Crazy Eights' overlay is outside the broadcast target.** In `_go_fish_game` and
   `_rummy_game` the overlay nests inside `.game id=dom_id(game)`; in
   `_crazy_eights_game` the `- unless game_info.started?` sits at column 0, **outside**
   it. A `replace` of `dom_id(game)` would swap in the board and strand the overlay.
4. **Zero information.** No player count, no capacity (`MAX_PLAYERS` is 6/7/5 and already
   exposed via `Game#max_players`), no roster, no "you need 2 to start", no invite path.
   Start is always enabled, even when `can_start?` is false.

**Already in place — reuse, don't rebuild:**

- `meta name="turbo-refresh-method" content="morph"` + `turbo-refresh-scroll preserve`
  are set globally in `application/_head.html.slim`. A `broadcast_refresh_to` re-render is
  seamless and silent — this is what the index lobby already relies on.
- `Participant` already validates `not_started` and `not_full` on create, so joins can't
  land mid-game.
- `Participant#winner` is an existing boolean-on-participant precedent for `#host`.
- The index system spec already tests a live broadcast **in one session** by creating a
  `Participant` record mid-test and asserting the page updated (`spec/system/games_spec.rb:75-80`).
  Same trick works here.

---

## 2. Decisions (settled)

| Question | Decision |
| --- | --- |
| Who can start? | **Host only.** Non-hosts see "Waiting for *host* to start…" |
| Host modeling | **`Participant#host` boolean** — mirrors the existing `winner` column |
| Leaving a lobby | **Out of scope.** No `participants#destroy`, no roster shrink, no host reassignment |
| Auto-start when full | **No.** Host presses Start, always |
| Visual treatment | **Simple list** — roster list + count, leaning on existing card/panel styles |

### Approved layout

```
┌────────────────────────────────┐
│  Will's Rummy Game             │
│  Rummy · 2 / 5 players         │
│                                │
│  • Will  (host) (you)          │
│  • Ana                         │
│                                │
│  Waiting for more players…     │
│                                │
│  [ Copy invite link ]          │
│  [    Start Game     ]         │
└────────────────────────────────┘
```

**Status line + button, by viewer:**

| State | Status line | Start button |
| --- | --- | --- |
| < 2 players | "Waiting for more players…" | hidden (host) / hidden (guest) |
| ≥ 2, viewer is host | "Ready when you are." | **enabled** |
| ≥ 2, viewer is not host | "Waiting for *Will* to start…" | hidden |
| Lobby full | "Lobby is full." | enabled (host) / hidden (guest) |

Non-hosts never see a Start button at all — a permanently disabled button is noise. The
status line carries the explanation.

---

## 3. Live-update strategy

**Both lobby events use `broadcast_refresh_to game` on a new shared game stream.**

The waiting room is *nearly* user-independent, but "(you)" and the host-only Start button
make it per-user — so a shared-stream `replace` would leak the wrong view to everyone.
Rather than fanning out a per-user render (the `BroadcastGameJob` pattern), broadcast a
**refresh**: each client re-GETs `show` and renders its own correct waiting room. Morph is
already enabled globally, so it's silent. Lobby joins are rare; a full fetch per client per
join is cheap, and it's the pattern the index already proves.

```
join   → Participant  after_create_commit  → broadcast_refresh_to game
start  → Game         after_update_commit  → broadcast_refresh_to game   (if saved_change_to_started_at?)
```

**This cannot interfere with in-progress play:** `Participant` validates `not_started`, so
no participant is ever created mid-game; and `saved_change_to_started_at?` fires exactly
once, at start. Turns keep using the existing per-user `GameTurboUpdate` replace path,
untouched.

`show.html.slim` subscribes to **both** streams — the new shared one for lobby events, the
existing per-user one for gameplay.

---

## 4. Implementation

Spec-first throughout, per `AGENTS.md`. Each step: failing spec → implement → green.

### Step 1 — Host on Participant ✅

**Migration** `add_host_to_participants`:
- `add_column :participants, :host, :boolean, default: false, null: false`
- Backfill in the same migration (reversible `up`/`down`): mark the earliest participant
  of each existing game as host —
  `UPDATE participants SET host = true WHERE id IN (SELECT DISTINCT ON (game_id) id FROM participants ORDER BY game_id, created_at)`

**`Participant`**
- `validates :host, uniqueness: { scope: :game_id }, if: :host?` — one host per game, enforced

**`Game`**
- `def host = participants.find_by(host: true)&.user`
- `def host?(user) = host == user`

**`GamesController#create`** — `@game.participants.new(user: Current.session.user, host: true)`

**Factories**
- `spec/factories/participants.rb`: add `trait :host { host { true } }`
- `spec/factories/games.rb`: `has_user` builds the participant with `host: true`
  (in every existing use, `user:` *is* the game's creator, so this is semantically right
  and harmless to the `started_game`/`users_turn` paths)

**Specs** — `spec/models/game_spec.rb`: `#host` returns the hosting user; `#host?` is true
only for them. `spec/models/participant_spec.rb`: a second host on the same game is invalid.

### Step 2 — `GameLobbyPresenter` ✅

New `app/presenters/game_lobby_presenter.rb`. Sibling to `GameRowPresenter`, not a
`GamePresenter` subclass — there is no `state` to present yet, so it shares nothing with
the gameplay presenter hierarchy.

```ruby
GameLobbyPresenter.new(game, user)

  #name            # game.name
  #type_label      # game.class.label
  #player_count    # "2 / 5"
  #players         # roster rows: name, host?, you?
  #host_name
  #can_start?      # game.can_start?
  #host?           # game.host?(user)
  #show_start?     # host? && can_start?
  #status_line     # the table in §2
  #invite_url      # game_url(game)
```

`player_count`/capacity logic currently lives in `GameRowPresenter#player_count` and
`#full?` — pull the shared shape from `Game` (`max_players`, a `seat_count`) rather than
duplicating the string building in two presenters.

**Spec** `spec/presenters/game_lobby_presenter_spec.rb` — Given/Context/It per convention.
Cover each row of the status-line table, the roster's host/you markers, and `show_start?`
for host vs guest.

### Step 3 — Move the waiting state out of the game partials ✅

**`GamesController#show`**

```ruby
@game = Game.find(params[:id])
if @game.started_at
  @game_info = @game.presenter(Current.session.user)
else
  @lobby = GameLobbyPresenter.new(@game, Current.session.user)
end
```

**`games/show.html.slim`**

```slim
= turbo_stream_from @game                        / shared — lobby events
= turbo_stream_from @game, Current.session.user  / per-user — gameplay

div data-controller="offline-alert" ...          / unchanged

- if @lobby
  = render "games/waiting_room", lobby: @lobby
- else
  = render @game_info, game_info: @game_info
  = turbo_frame_tag "end_of_game_modal", target: "_top" do
    - if @game_info.finished?
      = render "games/end_of_game_modal", game_info: @game_info
```

**New `app/views/games/_waiting_room.html.slim`** — the §2 layout.

**Delete the three overlay blocks.** This fixes defect 3 by construction.

**Then remove the now-dead `- if game_info.started?` guards** inside the three game
partials — the partial can no longer render for an unstarted game. Keep `playable?`
guards (those are about *finished*, not *started*). Low-risk but touches all three files;
do it as its own commit so a regression is easy to bisect.

### Step 4 — Wire the broadcasts ✅

- `Participant`: add `after_create_commit -> { broadcast_refresh_to game }` alongside the
  existing `broadcast_refresh_to "games"`
- `Game`: extend the existing started_at callback to also `broadcast_refresh_to self`

### Step 5 — Guard and fix `#start` ✅

```ruby
def start
  @game = Game.find(params[:id])
  return redirect_to game_path(@game), alert: "Only the host can start this game." unless @game.host?(current_user)
  return redirect_to game_path(@game), alert: "Need at least 2 players to start." unless @game.start

  redirect_to game_path(@game)
end
```

Replaces the nil-crashing `render :show` (defect 2). Keep it to ~7 lines.

**Spec** `spec/requests/games_spec.rb`:
- non-host POST → redirected, `game.reload` not started
- host with 1 player → redirected with alert, not started *(this is the crash regression test)*
- host with 2 players → started

### Step 6 — Copy invite link ✅

New `app/javascript/controllers/clipboard_controller.js` (none exists). Reads a
`value`, writes via `navigator.clipboard.writeText`, swaps the button label to "Copied!"
briefly. Register in `controllers/index.js` following the existing pattern.

### Step 7 — Styles ✅

New `app/assets/stylesheets/components/lobby/waiting_room.css`, BEM, one block per file —
Propshaft picks it up automatically, no manifest edit. Reuse the existing card/panel
treatment and the `--gf-*` felt/coral tokens.

**Verify with a screenshot system spec**, per `AGENTS.md` — drive to the lobby, call
`screenshot("waiting-room", fullPage: true)`, Read the PNG. Check **both** color schemes
(see [light-dark gotcha](../frontend.md)). Delete the spec afterward if it was only
scaffolding to look at the page.

### Step 8 — System specs ✅

Existing `spec/system/games_spec.rb` `[ Start ]` contexts **will break** — the copy
changed and start is now host-only. Update them, and add the live cases using the
one-session pattern already proven at `games_spec.rb:75-80`:

- **Join updates the lobby live** — host visits the game page, test does
  `create(:participant, game: game)`, expect the count and roster to update with no
  navigation
- **Start reaches other players live** — a *non-host* visits the game page, test calls
  `game.start`, expect the board to appear and the waiting room to be gone

Both stay single-session per the multiplayer convention
([handoff](../handoffs/2026-07-23-rummy-multiplayer-system-spec-gotchas.md)). Use
`have_no_css` / `have_css` to assert presence, not `visible: false`.

---

## 5. Out of scope

Explicitly **not** doing (raise before adding any of these):

- Leaving a lobby (`participants#destroy`), host reassignment, empty-game cleanup
- Auto-start when the lobby fills
- Seat-slot / avatar visual treatment — simple list only
- Kicking players, lobby chat, ready-checks, private/invite-only games
- Spectators

**Adjacent cleanup, optional, mention before doing:** `resources :participants, only:
[:create, :show]` — there is no `show` action and no `app/views/participants/`. Dead route.

---

## 6. Done when

- A player who joins an unstarted game sees the game's name, type, `n / max` count, and
  the full roster with the host marked and themselves marked.
- A second player joining updates every lobby-watcher's roster and count live, no reload.
- Only the host sees a Start button; it appears only at 2+ players. Everyone else sees who
  they're waiting on.
- The host pressing Start drops **every** player into their own board live.
- A failed start redirects with a readable message instead of raising.
- `bundle exec rspec` green, `bin/rubocop` clean.
