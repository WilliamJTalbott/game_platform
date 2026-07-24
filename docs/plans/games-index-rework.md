# Games Index Rework — Home Dashboard + Richer Lobby

Goal: turn the site root (`games#index`) from a bare two-list page into a
**home dashboard** — a place that greets you, shows the game info we already have
at a glance, and updates live. The lobby stays the centerpiece.

Status legend: 🟡 planned · 🟢 in progress · ✅ done

**The design is finalized in a full-page mockup:
[docs/mockups/games-index-final.html](../mockups/games-index-final.html)** (open it,
toggle light/dark). That file is the visual source of truth for layout, the felt
treatment, the button hierarchy, and exact colors. This plan is the *implementation*
map; where prose and mockup disagree, the mockup wins.

---

## 1. Where we are today

**View** (`app/views/games/index.html.slim`) renders two stacked `.collection`s:
- **Your Games** — `Current.games.where(finished_at: nil, deleted_at: nil)`
- **All Games** — `Game.where(started_at: nil, deleted_at: nil) - @user_games`

**Each row** (`_game_bar.html.slim`) shows **only** `game.name` + one button
(`View` for your games, `Join` for others).

**Rough edges to fix along the way:**
1. ✅ Done — `@other_games` now uses `where.not(id: Current.games.select(:id))`
   (SQL) instead of Ruby array subtraction. Pinned by a `GET /games` request spec.
2. `button_to "View", ..., method: :get` — a `<form>` masquerading as a link →
   `link_to`.
3. **N+1** rendering participants per row → `includes(:participants, :users)`.
4. No empty states, no player counts, no game type, no turn info.

**Already in place (reuse, don't rebuild):**
- `turbo_stream_from 'games'` is in the view and `Game#after_create_commit`
  already `broadcast_refresh_to "games"`, so **new games appear live**.
- Layout sets `turbo-refresh-method = morph` + scroll-preserve, so a
  `broadcast_refresh_to "games"` re-render is seamless and silent.
- Optics + design tokens + BEM, one block per file in
  `app/assets/stylesheets/components/`.

---

## 2. Approved design

### Page structure — *actionable-first, single column*

```
Welcome back, Will
12 played · 7 won · 58% win rate                       [ ♠ New Game ]
╭──────────────────────────── felt tray ─────────────────────────────╮
│ ♠ YOUR GAMES                                             2 active   │
│  ┌── raised bar ──────────────────────────────────────────────┐    │
│  │ Friday Night  ● Your turn                                   │    │
│  │ Go Fish                                    4/6   [ View ]   │    │
│  └─────────────────────────────────────────────────────────────┘   │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │ Rematch                                                     │    │
│  │ Crazy Eights                               3/7   [ View ]   │    │
│  └─────────────────────────────────────────────────────────────┘   │
│  ────────────────────────── divider ──────────────────────────      │
│ ♠ OPEN GAMES TO JOIN                                     3 open    │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │ Lunch Match                                                 │    │
│  │ Crazy Eights                               2/7   [ Join ]   │    │
│  └─────────────────────────────────────────────────────────────┘   │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │ Full Table                                                  │    │
│  │ Crazy Eights                               7/7    Full      │    │
│  └─────────────────────────────────────────────────────────────┘   │
╰─────────────────────────────────────────────────────────────────────╯
                                                        View History →
(empty section → minimal one-line text: "No active games." / "No open games.")
```

**Element-by-element (as approved / finalized in the mockup):**

| Element | Decision |
|---|---|
| **Section order** | Actionable-first: greeting+stats → Your Games → Open Games → History link. |
| **Greeting** | Simple "Welcome back, {name}". |
| **Stats** | **Inline one-liner** ("12 played · 7 won · 58% win rate"), *not* tiles. From existing `User#games_played/games_won/win_percentage`. |
| **Spade icon** | **Decorative brand accent only** (coral ♠). Used on section headers + New Game button. *Not* a per-game-type indicator. |
| **Both sections in one tray** | Your Games and Open Games live inside a **single felt tray**, separated by just a section header (label + count) and a thin divider — **no per-section wrapping panel**. See Visual direction. |
| **Card — name** | Primary element, largest text, leftmost. |
| **Card — type** | Subtle, secondary, beneath the name ("Go Fish" / "Crazy Eights"). |
| **Card — count** | Compact `current/max` (e.g. `4/6`), clustered with the CTA on the right. |
| **Card — "Your turn"** | **Coral** badge on the name row, **badge only — no re-sorting** of the list. Shown only on your started games when it's your turn. |
| **Card — CTA hierarchy** | **View leads** (you're more likely to return to a game you're in): View = **solid coral** primary. Join = **coral-tint fill + coral outline** secondary. All CTAs share one width (equal `min-width`, centered). |
| **Full game** | When `current == max`: **no button at all** — an inert muted **"Full"** status chip (Join's shape, gray outline, not clickable) fills the CTA slot so the row stays aligned. |
| **Max players** | **Per-game-type constant** in code: `GoFishGame MAX_PLAYERS = 6`, `CrazyEightsGame MAX_PLAYERS = 7`. No DB column, no host input. |
| **Recent results** | **Just a "View History →" link** (coral) — no list on the dashboard. |
| **Empty states** | **Minimal one-line text** ("No active games." / "No open games."), no button. |
| **Live updates** | **Silent morph** — counts/badges/cards update in place via the existing broadcast; no flash, toast, or "live" indicator. |

**Explicitly out of scope:** spectating in-progress games you're not in, player-name
lists / avatars on cards, sorting your-turn games to the top, a recent-results list,
start-from-card, leaderboards, and any change to the gameplay (`show`) screen.

### Visual direction — a lobby that pops without stealing the table's thunder

The Rummy board's green felt is what makes gameplay *feel* like arrival. If every
page wears green felt, that impact is diluted. So:

- **Green felt is reserved for the game table** (the `show` screens). The lobby gets
  its **own material** in the same elevation grammar, so the two pages read as one
  system but are clearly different rooms.
- **Same pop-out grammar as Rummy, two layers only:** a **recessed muted tray**
  (inset shadow) holding **raised, brighter game bars** (drop shadow). The bars sit
  **directly on the tray** — there is no intermediate "zone panel". This is a
  deliberate reduction from an earlier three-layer draft (tray → panel → card).
- **Palette (the lobby's identity):** the tray uses the **sidebar's warm neutral
  tone**; the raised game bars are a **cool blue-gray**. That warm-tray / cool-bar
  contrast is what reads as "raised", and the whole thing is intentionally a
  **softer pop** (gentler contrast + lighter shadows) than the green board so
  gameplay still out-pops the lobby.
- **Coral (the brand accent) carries all the action/identity color:** New Game,
  View (solid), Join (tint + outline), the active sidebar item, the "Your turn"
  badge, and the History link. Green appears nowhere in the lobby chrome.

Exact hex values (light + dark) live in the mockup's `:root` token blocks — use those.

---

## 3. Implementation

Convention-aligned: skinny controller → **presenter builds the per-user view** →
Slim partials → BEM CSS (one block per file). No model rendered directly.

### 3a. Models
- **`MAX_PLAYERS` constant** on each STI subclass (`GoFishGame` = 6,
  `CrazyEightsGame` = 7). Expose via an instance reader so the presenter/`can_start?`
  don't hardcode it.
- **Full-game guard.** Add a `full?` (`participants.count >= max_players`) check.
  Enforce on join: extend `Participant`'s `not_started` validation area with a
  "game is full" validation (belt), and drop the Join button in the view (suspenders).
- **Scopes** for clarity + reuse: `Game.waiting` (`started_at: nil, deleted_at: nil`),
  `Game.active` (started, not finished), `Game.finished`. Small and testable.

### 3b. Controller (`GamesController#index`)
```ruby
def index
  @dashboard = GamesDashboardPresenter.new(Current.user)
end
```
- Replace the array subtraction with SQL inside the presenter/scope
  (`Game.waiting.where.not(id: user.game_ids)`).
- `includes(:participants, :users)` on both collections (N+1 fix).

### 3c. Presenters (`app/presenters/`)
- **`GamesDashboardPresenter`** (top-level, per user): `greeting_name`,
  `stats_line` (the inline string), `your_games` / `open_games` (each as
  `GameRowPresenter`s), `history_path`. Buckets exclude finished/deleted.
- **`GameRowPresenter`** (per game, per user): `title` (name), `type_label`,
  `player_count` → `"#{count}/#{max}"`, `full?`, `your_turn?`, and `cta`.
  - **`cta` is tri-state**, mirroring the mockup: `:view` (your games, solid coral,
    GET link), `:join` (open + not full, coral-tint/outline, POST), `:full` (open +
    full → **no button**, render the inert "Full" chip instead).
  - `type_label`: `game.type.delete_suffix("Game").titleize` (swap to `game.class.label`
    if a game-type registry lands first).
  - `your_turn?`: guard for waiting games — `game.state` (the PORO) only exists once
    started, so `false` when `status == "waiting"`.

### 3d. Views
- Rewrite `index.html.slim` into the structure in §2 (keep `turbo_stream_from
  'games'`): greeting/stats header + New Game button, then **one felt tray** holding
  the Your Games header + bars, a divider, the Open Games header + bars, and the
  History link below.
- New **`_game_card.html.slim`** driven by a `GameRowPresenter` (replaces
  `_game_bar`; confirm no other view uses `_game_bar` before deleting it). The card is
  a **bare bar directly on the tray** — no section wrapper.
- `link_to` for View; `button_to` (POST) for Join; render the **"Full" chip** (a
  non-interactive `span`, not a disabled button) when `cta == :full`.
- Inline minimal empty-state text per section (the mockup shows the populated state;
  the empty one-liner still ships).

### 3e. CSS & frontend conventions (non-negotiable for this work)
Follow the house rules in [docs/frontend.md](../frontend.md). The mockup is
self-contained CSS; translating it to the app means:
- **Prefer Optics first** for anything Optics covers (buttons, badges, spacing,
  layout, phosphor icons). The **felt tray + raised-bar elevation is custom** —
  Optics has no felt — so it becomes a small BEM component set backed by project
  tokens.
- **Design tokens only.** Optics `--op-*` where they fit; add **project `--gf-*`
  tokens in `core/theme.css`** for the lobby material (tray tone, blue-gray bar tone,
  the inset/drop shadow pair), keeping green-felt tokens separate and reserved for the
  game board. Component-private one-offs stay `--_gf-*`. Copy exact values from the
  mockup's `:root` / `:root[data-theme="dark"]` blocks. **Verify both light and dark**
  (Optics `plus-N`/`minus-N` tokens flip meaning between schemes).
- **BEM, one block per file** in `app/assets/stylesheets/components/`. Likely blocks:
  - a **dashboard/lobby** block — the recessed tray, the on-felt section header
    (label + count), the divider.
  - a **game-card** block — the raised bar: name (primary), type (subtle), the
    count + CTA cluster, the coral "Your turn" badge, and the three CTA treatments
    (`--view` solid, `--join` tint+outline, `--full` inert chip; shared `min-width`).
- Retire `game_bar.css` **only** if `_game_bar` is fully removed.

### 3f. Live updates (Turbo, silent morph)
Reuse `broadcast_refresh_to "games"` + morph:
- **Join** → broadcast from `Participant` `after_create_commit` (or
  `ParticipantsController#create`) so counts/`full?` update everywhere.
- **Start** → broadcast in the start path so waiting→started leaves the open-games
  list live.
- New games already broadcast — verify no double-fire.
- **Per-user caveat:** the "Your turn" badge is user-specific; a shared
  `broadcast_refresh_to` re-renders per each viewer's own authenticated morph
  request, so it *should* stay correct per user — confirm in the one system spec;
  fall back to per-user stream targets only if it proves wrong.

---

## 4. Testing (TDD-first, lowest layer that proves it)

- **Presenters** (`spec/presenters/`) — bulk of the logic:
  - `GameRowPresenter`: `type_label`, `player_count` = `count/max` per game type,
    `full?` boundary, `your_turn?` true only on your started+active turn (false
    while waiting), and the **tri-state `cta`** (`:view` / `:join` / `:full`).
  - `GamesDashboardPresenter`: correct buckets (your vs open; excludes
    finished/deleted/started-not-yours), `stats_line` matches `User` methods.
- **Models** — `MAX_PLAYERS`/`full?`, the full-game join validation, and the new
  scopes.
- **Request** (`spec/requests/`) — `index` 200 authed / redirect unauthed; open
  game appears, started game you're not in does not; joining a full game is
  rejected.
- **System** (`spec/system/`, coarse, one spec) — a second player joining updates
  the first player's lobby live (broadcast wiring) and the "Your turn" badge
  renders for the right user. Only thing needing a browser.

---

## 5. Sequencing (vertical slices, each independently shippable)

1. **Models + query fix** — `MAX_PLAYERS`, `full?`, join validation, scopes, kill
   array subtraction, `includes`. Refactor under existing green suite.
2. **`GameRowPresenter` + `_game_card`** — rich bars, count, type, coral "Your turn"
   badge, tri-state CTA (View / Join / Full chip). The visible core.
3. **`GamesDashboardPresenter` + header** — greeting, inline stat line, section
   layout, History link, empty states.
4. **Live updates** — join/start broadcasts + the one system spec.
5. **CSS polish** — the felt tray + blue-gray bars per the mockup, spade accent,
   coral CTAs, responsive + both-schemes check.

---

## 6. Notes / assumptions

- Max players is code-only (per-type constant); if capacity ever needs to be
  host-configurable, the card `count/max` display is already the place it surfaces.
- `game.name` remains user-provided and is the card's title.
- History link points at the existing `history_index_path`; the History page itself
  is unchanged by this rework.
- **Reserve green felt for the game table.** If a future page wants the "pop" look,
  give it its own material in this same elevation grammar rather than reusing either
  the green board or this lobby's blue-gray — one material per "room."
