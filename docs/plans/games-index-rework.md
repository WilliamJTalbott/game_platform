# Games Index Rework — Home Dashboard + Richer Lobby

Goal: turn the site root (`games#index`) from a bare two-list page into a
**home dashboard** — a place that greets you, shows the game info we already have
at a glance, and updates live. The lobby stays the centerpiece.

Status legend: 🟡 planned · 🟢 in progress · ✅ done

**All design decisions below were reviewed and approved element-by-element with the
author.** Where a decision differs from a "typical" choice, the author's pick is
the source of truth.

---

## 1. Where we are today

**View** (`app/views/games/index.html.slim`) renders two stacked `.collection`s:
- **Your Games** — `Current.games.where(finished_at: nil, deleted_at: nil)`
- **All Games** — `Game.where(started_at: nil, deleted_at: nil) - @user_games`

**Each row** (`_game_bar.html.slim`) shows **only** `game.name` + one button
(`View` for your games, `Join` for others).

**Rough edges to fix along the way:**
1. `@other_games = Game.where(...) - @user_games` — Ruby array subtraction pulls
   every record into memory. Replace with SQL (`where.not`).
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

### Page structure — *actionable-first, single column* (`container--sm/md`)

```
Welcome back, Will
12 played · 7 won · 58% win rate                    [ ♠ + New Game ]
──────────────────────────────────────────────────────────────────
♠ YOUR GAMES
  ┌────────────────────────────────────────────────┐
  │ Friday Night              ● Your turn           │
  │ Go Fish                              4/6  [View]│
  └────────────────────────────────────────────────┘
  (empty → "No active games.")
──────────────────────────────────────────────────────────────────
♠ OPEN GAMES TO JOIN
  ┌────────────────────────────────────────────────┐
  │ Lunch Match                                     │
  │ Crazy Eights                         2/7  [Join]│
  └────────────────────────────────────────────────┘
  (empty → "No open games.")
──────────────────────────────────────────────────────────────────
                                                    View History →
```

**Element-by-element (as approved):**

| Element | Decision |
|---|---|
| **Section order** | Actionable-first: greeting+stats → Your Games → Open Games → History link. |
| **Greeting** | Simple "Welcome back, {name}". |
| **Stats** | **Inline one-liner** ("12 played · 7 won · 58% win rate"), *not* tiles. From existing `User#games_played/games_won/win_percentage`. |
| **Spade icon** | **Decorative brand accent only** (matches sidebar "Go Fish ♠"). Used on section headers / New Game button. *Not* a per-game-type indicator. |
| **Card — name** | Primary element, largest text, leftmost. |
| **Card — type** | Subtle, secondary, beneath the name ("Go Fish" / "Crazy Eights"). |
| **Card — count** | Compact `current/max` (e.g. `4/6`), grouped with the button on the right. |
| **Card — "Your turn"** | Badge on the name row, **badge only — no re-sorting** of the list. Shown only on your started games when it's your turn. |
| **Card — CTA** | **View** (your games) / **Join** (open games). No Start-from-card, no Resume. |
| **Join when full** | When `current == max`, the game is full → Join disabled/hidden. |
| **Max players** | **Per-game-type constant** in code: `GoFishGame MAX_PLAYERS = 6`, `CrazyEightsGame MAX_PLAYERS = 7`. No DB column, no host input. |
| **Recent results** | **Just a "View History →" link** — no list on the dashboard. |
| **Empty states** | **Minimal one-line text** ("No active games." / "No open games."), no button. |
| **Live updates** | **Silent morph** — counts/badges/cards update in place via the existing broadcast; no flash, toast, or "live" indicator. |

**Explicitly out of scope:** spectating in-progress games you're not in, player-name
lists / avatars on cards, sorting your-turn games to the top, a recent-results list,
start-from-card, leaderboards, and any change to the gameplay (`show`) screen.

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
  "game is full" validation (belt), and hide/disable Join in the view (suspenders).
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
  `player_count` → `"#{count}/#{max}"`, `full?`, `your_turn?`, and `cta`
  (label + path + method: View→GET link, Join→POST).
  - `type_label`: `game.type.delete_suffix("Game").titleize` (same concept as the
    game-type registry in `improvement-plan.md` Item 3 — swap to `game.class.label`
    if that lands first).
  - `your_turn?`: guard for waiting games — `game.state` (the PORO) only exists once
    started, so `false` when `status == "waiting"`.

### 3d. Views
- Rewrite `index.html.slim` into the structure in §2 (keep `turbo_stream_from
  'games'`). Sections: greeting/stats header, Your Games, Open Games, History link.
- New **`_game_card.html.slim`** driven by a `GameRowPresenter` (replaces
  `_game_bar`; confirm no other view uses `_game_bar` before deleting it).
- `link_to` for View; `button_to` (POST) for Join, hidden/disabled when `full?`.
- Inline minimal empty-state text per section.

### 3e. CSS & frontend conventions (non-negotiable for this work)
Follow the house rules in [docs/frontend.md](../frontend.md); concretely:
- **Prefer Optics first.** Reach for existing **@rolemodel/optics** components and
  utility classes (`.btn`/`.btn--primary`, `.card`, `.badge`, `.divider`, layout/
  spacing helpers, phosphor `.ph` icons) before writing any custom CSS. Only add a
  new component when Optics has no fit.
- **Design tokens only** — style with `--op-*` (Optics) and project `--gf-*`/`--_gf-*`
  tokens. No hardcoded colors, spacing, radii, or font sizes.
- **BEM, one block per file.** Each new component is its own `.css` file in
  `app/assets/stylesheets/components/` (`block`, `block__element`, `block--modifier`).
  Propshaft `:app` auto-includes it — no manifest, `@import`, or build step.

**Files:**
- New **`components/game_card.css`** — name (primary), type (subtle/secondary),
  count + CTA cluster (right), "Your turn" badge. Built from Optics `.card`/`.badge`
  where possible; `--op-*` tokens throughout.
- New/extend **`components/dashboard.css`** — greeting, inline stat line, section
  headers with the spade accent, spacing (Optics spacing tokens).
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
    while waiting), correct CTA (View vs Join, Join suppressed when full).
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
2. **`GameRowPresenter` + `_game_card`** — rich cards, count, type, "Your turn"
   badge, View/Join CTA (Join hidden when full). The visible core.
3. **`GamesDashboardPresenter` + header** — greeting, inline stat line, section
   layout, History link, empty states.
4. **Live updates** — join/start broadcasts + the one system spec.
5. **CSS polish** — spade accent, badge, spacing, responsive check.

---

## 6. Notes / assumptions

- Max players is code-only (per-type constant); if capacity ever needs to be
  host-configurable, the card `count/max` display is already the place it surfaces.
- `game.name` remains user-provided and is the card's title.
- History link points at the existing `history_index_path`; the History page itself
  is unchanged by this rework.
