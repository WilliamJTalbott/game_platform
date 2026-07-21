# Plan: End-of-Game Modal Redesign (visual polish)

## Purpose & scope

This plan is about **how the end-of-game modal looks and feels**, not what it
does. The behavior — when it appears, per-user framing, durability on refresh,
turn-blocking — is already covered by
[docs/plans/end-of-game.md](end-of-game.md) and its specs. **Do not change that
behavior.** This is a presentation-layer pass: layout, styling, animation, and a
real scoreboard table.

Read [docs/frontend.md](../frontend.md) first — CSS is served by Propshaft (no
bundler), one BEM block per file in `app/assets/stylesheets/components/`, using
Optics `--op-*` tokens plus project `--gf-*`/`--_gf-*` tokens.

---

## Current state (what it looks like today)

The partial `app/views/games/_end_of_game_modal.html.slim` renders
`.modal-wrapper` → `.modal` → `.modal__header / __body / __footer` and a bare
`table.scoreboard`. **None of these classes have any CSS** — there is no
`modal.css` or `scoreboard.css` in `app/assets/stylesheets/components/`. So the
modal currently displays as unstyled default-block HTML: no card, no backdrop
dimming, no animation, footer buttons in source order (primary "Return to main
page" first/left), and the scoreboard is an unstyled two-column row list.

Render/delivery paths (must keep working, do not touch the wiring):

- `app/views/games/show.html.slim` renders it inside
  `turbo_frame_tag "end_of_game_modal"` when `@game_info.finished?` — the
  refresh-durable path.
- `GameTurboUpdate.broadcast_end_of_game_modal` and
  `TurnsController#render_finished_game` replace that same frame — the live path.

Both feed the **same partial** the same `game_info` presenter. This redesign
changes only the partial's markup + new CSS (+ one small presenter helper). The
`game_info` contract stays: `won?`, `winner`, `scoreboard` (each entry →
`name`, `score`, `winner?`), all defined in
`app/presenters/game_presenter.rb` / `scoreboard_entry.rb`.

---

## Target design

### 1. Layout & button placement

**Header** — title on one side, a secondary action on the other:

- Left/center: `h1` "You win" / "You lose" (+ "`<winner>` wins!" line on a loss).
- Right (opposite the title): **"View stats"** as a small/ghost link, moved up
  out of the footer.

**Footer** — primary highlighted button pinned **far right**, reversing today's
order:

| Position | Label | Style | Destination |
|---|---|---|---|
| Left | Create a new game | secondary (`btn`) | `new_game_path` |
| Far right | Return to main page | primary (`btn btn--primary`) | `root_path` |

Implementation note: pin the primary right with `margin-left: auto` (or a
flex/space-between footer) so the DOM keeps the primary readable but it renders
rightmost. Header uses `justify-content: space-between`.

### 2. Entrance animation — scale + fade pop

- Backdrop fades in (opacity 0 → 1).
- Modal card scales `0.9 → 1.0` **with a slight ease-out overshoot** while fading
  in — lively/celebratory, not jarring.
- Pure CSS `@keyframes` triggered by the `.modal-wrapper--active` class already on
  the partial's root; no JS required.

### 3. Scoreboard — real table

Replace the bare row list with a proper `<table>` (`<thead>` + `<tbody>`):

| Column | Notes |
|---|---|
| Rank | 1st / 2nd / 3rd… placement. **Ranking respects per-game direction** — Go Fish: higher `score` (books) is better; Crazy Eights: lower `score` (cards remaining) is better. Each subclass presenter declares its direction (see §Ranking below). Every player gets a **distinct** rank (1, 2, 3, 4) — ties are broken arbitrarily/stably, no shared ranks. |
| Player | Player name. Winner gets a **crown/medal icon** (👑 or medal). The **current viewer's** row shows a "(You)" indicator. |
| Score | The `score` value, under a **game-aware** header (see below). |

- **Winner row highlight**: color the winning row like the **Optics table header**
  used on the history page (`table--primary`'s header). Pull the same
  `--op-*` token(s) that style that header so the two match.
- **Column headers dim & minimal**: `<thead>` labels in a muted color
  (`--op-color-neutral-*`), small/uppercase-ish, low emphasis — present for
  structure, not shouting.
- **Game-aware score header**: "Books" for Go Fish, "Cards left" for Crazy
  Eights (Rank/Player stay generic). This adds a `score_label` to the presenter
  contract (see Ranking below).

**Ranking (settled).** The scoreboard is currently sorted winner-first in the
base presenter (`game_presenter.rb`), which is not score order for non-winners.
Resolution:

- Each **subclass presenter declares its score direction** — e.g.
  `score_order` → `:desc` for Go Fish (most books wins), `:asc` for Crazy Eights
  (fewest cards wins). The base presenter reads it to sort entries and assign
  rank, so no game-type branching leaks into the base.
- Ranks are **distinct and sequential** (1, 2, 3, 4). If two non-winners tie on
  score, order between them is arbitrary but stable — one simply gets the higher
  rank. No shared/tied ranks, no skipped numbers.
- The winner is always rank 1 (consistent with winner-first + the direction).

### Explicitly out of scope (declined)

The author declined the broader polish pass. **Do not build these** as part of
this work:

- Win-vs-lose accent color / `--win`/`--lose` modifiers.
- Confetti or any celebration effect.
- Accessibility additions beyond what already exists (no new `role`/`aria`,
  focus-trap, or `prefers-reduced-motion` work).
- Responsive/mobile layout changes.

---

## Work items

1. **New `app/assets/stylesheets/components/modal.css`** — BEM `.modal` block:
   backdrop, centered card, header (space-between), body, footer (primary pinned
   right), and `@keyframes` scale+fade pop. One block per file per project
   convention.
2. **New `app/assets/stylesheets/components/scoreboard.css`** — `.scoreboard`
   table: dim minimal `<thead>`, row styling, `.scoreboard__row--winner` matching
   the history `table--primary` header color, "(You)" / crown accents.
3. **Rewrite `app/views/games/_end_of_game_modal.html.slim`** — new header (title
   + "View stats"), footer (Create new game / Return to main page), real
   `<table>` with rank + crown + "(You)" + `<thead>`. Keep the `game_info`
   contract unchanged.
4. **Presenter changes for rank, "(You)", and label.**
   - Add `score_order` to each subclass presenter (`GoFishGamePresenter` →
     `:desc`, `CrazyEightsGamePresenter` → `:asc`) and `score_label`
     ("Books" / "Cards left").
   - In `game_presenter.rb#scoreboard`, sort by `score_order` and assign each
     `ScoreboardEntry` a **distinct sequential `rank`**, plus a per-user `you?`
     flag (compare entry's player/user to the viewing user). Extend
     `ScoreboardEntry` with `rank` and `you?`. Keep all logic in the presenter,
     not the view (project norm).
5. **Verify both delivery paths** still render identically (refresh via
   `games#show`, live via `GameTurboUpdate` / `TurnsController`) — no wiring
   changes expected.

---

## Acceptance / how to check

- **Existing behavior specs stay green** — this is a visual change; do not weaken
  `spec/requests/*`, `spec/presenters/*`, or `spec/system/end_of_game_spec.rb`.
  The system spec asserts the button labels and "You win" text — keep those exact
  strings ("Return to main page", "View stats", "Create a new game", "You win").
- If `ScoreboardEntry` gains `you?` / `rank`, add presenter specs
  (`spec/presenters/*_game_presenter_spec.rb`) covering rank direction for both
  games (Go Fish high-wins, Crazy Eights low-wins) and the per-user `you?` flag.
- Manual check in-browser (`/run`): finish a Go Fish and a Crazy Eights game;
  confirm animation, header/footer layout, table (rank/crown/you/dim headers),
  win-vs-lose accent, reduced-motion, and mobile width.

---

## Settled decisions

1. **Ranking direction** — each subclass presenter declares `score_order`
   (`:desc` Go Fish, `:asc` Crazy Eights); the base presenter sorts + assigns
   rank from it. No game-type branching in the base presenter.
2. **Score header label** — game-aware via a `score_label` on the presenter:
   "Books" (Go Fish) / "Cards left" (Crazy Eights). Rank/Player headers stay
   generic.
3. **Ties** — no shared ranks. Every player gets a distinct sequential rank
   (1, 2, 3, 4); a score tie between non-winners is broken arbitrarily but
   stably.
