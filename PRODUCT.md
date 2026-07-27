# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Small groups of friends and family playing remotely from separate locations. One person
hosts a game, shares it, and the others join; sessions are short and social rather than
competitive or anonymous. There is no matchmaking with strangers and no co-located
"shared table" mode.

Primary device for design and verification is **desktop**; mobile must remain usable but
is not the target the play surface is tuned for.

## Product Purpose

A web platform for playing turn-based card games — **Go Fish**, **Crazy Eights**, and an
in-progress **Rummy** — live against other people. Users register, host or join a game
lobby, and take turns that broadcast to every participant in real time. It also keeps
per-user stats, game history, and rules pages, and ships as an offline-capable PWA.

Success is a group of remote friends getting into a game quickly and playing it through
without friction or confusion about whose turn it is.

Secondary but real: this is a skill-development project for the author, built to
production standards rather than as a throwaway.

## Positioning

Three things a neighboring card-game site could not truthfully copy as a set:

1. **A multi-game shared platform, not a game.** One account, one lobby, one
   turn/broadcast engine. New games plug into the existing STI + presenter + Turbo
   Stream contract rather than becoming a separate app. The platform itself is the
   product.
2. **Zero-friction live play.** No download, no install, no client configuration — sign
   in, join, play. Turns arrive live over Turbo Streams / Action Cable, and the app is
   an installable, offline-capable PWA.
3. **The craft of the play surface.** The tactile card table — felt, hand dock, card
   faces, real-time presence and message feed — is a deliberate reason to choose it over
   a plain functional web card game.

## Operating Context

- Play is remote and asynchronous-feeling but live: a turn taken by one player must
  appear on every other player's screen without a refresh.
- A game's life cycle is: someone creates it → others join a **waiting room** → the host
  starts it → turns alternate until a winner is stamped → it lands in history and stats.
- Surfaces in use today: home/lobby dashboard (`/`, `games#index`), game show (per game
  type), waiting room, stats, history, rules, offline page, plus auth
  (session/passwords) and user profile.
- Live turn broadcasts and cron work require a running GoodJob worker; a dev session is
  `bin/dev` plus `bundle exec good_job start`.

## Capabilities and Constraints

- **Rails 8.1 / Ruby 3.4 / PostgreSQL / Puma**, Hotwire (Turbo + Stimulus), Slim
  templates, Simple Form, GoodJob for jobs and cron, Kamal + Docker deploy, Honeybadger
  for errors.
- **Auth is hand-rolled** — cookie-backed `Session` model plus a `Current` object. No
  Devise. `Current.session` / `current_user`.
- **Two layers both contain a class named `Game`.** Persistence is ActiveRecord STI
  (`Game` → `GoFishGame` / `CrazyEightsGame` / `RummyGame`, joined to `User` through
  `Participant`); rules are plain Ruby (`GoFish::Game`, `CrazyEights::Game`,
  `Rummy::Game`). The bridge is the `state` jsonb column. See `docs/architecture.md`.
- **Rendering always goes through a presenter** (`app/presenters/`) so each player sees
  only their own hand and message log. Validation lives in form objects
  (`app/forms/`); controllers validate then delegate.
- **CSS is served by Propshaft, not bundled.** Drop a `.css` file under
  `app/assets/stylesheets/components/<domain>/` and it is included automatically. The
  empty `application.css` and the webpack CSS build are inert and must not be "fixed."
- **Rummy is in progress** — it is a real game type with UI, not a stub, but not finished.
- Card face art is `<img>`-loaded SVG (`app/assets/images/dark_cards/*.svg`) that carries
  its own theme-aware ink; page CSS cannot reach inside it.
- **Dark mode is the supported scheme.** The app is designed and judged in dark mode. Light
  mode renders today only as incidental output from Optics' `light-dark()` pairs — those
  light values were never chosen. A deliberate light palette is planned as a later,
  hand-picked color set that replaces the dynamic switching with explicit values; it is not
  built yet. Today the app tracks the OS color scheme and has no manual toggle.
- **Undecided:** when the hand-picked light palette gets built, and whether a manual theme
  toggle ships with it.

## Brand Commitments

- Product name in the UI is **Game Platform**.
- **`DESIGN.md` is the binding visual contract** (with `docs/frontend.md` as the CSS
  pipeline reference) and must be read before any styling work. Its non-negotiable parts:
  - **`@rolemodel/optics` (v2.4.0, CDN) is the foundation** and is not replaceable. It
    owns all non-color tokens (spacing, type, radii, shadows, border widths).
  - **Optics contributes no color.** Every color is ours, defined as a `--gp-color-*` token in
    `core/theme.css`, and no stylesheet outside that file references an `--op-color-*` token.
    Optics' plus/minus *ramp structure* is kept (surfaces climb `plus-*`, ink steps down
    `minus-*`) with our own values, and a bridge block in `theme.css` feeds those values back
    to the `--op-color-*` tokens Optics reads internally so its own components are painted from
    our palette. Never color a component from the Optics *primary* ramp
    (`--op-color-primary-*`) — the ramp's
    lightness knob is inert and its base is locked mid-dark in both schemes.
  - **Coral is the permanent site-wide accent** (`--gp-color-accent*`), carrying every CTA,
    link, focus affordance, wordmark, and "it's your turn" signal on every page.
  - **Page accents:** on top of coral, a major page *may* claim one color of its own, and
    it never appears on another page. Green is the game page (`--gp-felt*`); slate-blue is
    the games index (`--gp-lobby-bar`). The list is open — a future page may claim its own.
    Pages with no accent (stats, history, rules) are complete as they are, and how much of
    a page its color covers is that page's own call.
  - **Dark-first.** Design, review, and screenshot in dark mode. Keep colors as
    `light-dark()` pairs regardless, so the future light palette has a seam to land in.
  - **Token tiers:** `--op-*` (Optics, non-color only) → `--gp-*` (shared project, defined in
    `core/theme.css`; all color lives here) → `--_gp-*` (private to one component). For
    non-color values prefer the outermost tier
    that covers the need.
  - **BEM, one block per file**, elements/modifiers nested under the block with `&`.
- `docs/mockups/*.html` (`games-index-final.html`, `rummy-final.html`) are the visual
  source of truth for the color model.

## Evidence on Hand

- Real, working implementations of Go Fish and Crazy Eights end to end; Rummy partially
  built.
- Design documentation: `DESIGN.md` (+ `.impeccable/design.json`),
  `docs/architecture.md`, `docs/frontend.md`,
  `docs/serialization.md`, per-game rules docs in `docs/games/`.
- Static mockups in `docs/mockups/` and written plans in `docs/plans/`.
- Session handoff notes in `docs/handoffs/`.
- **No** testimonials, customers, usage numbers, pricing, press, or public deployment
  claims exist. Future work must not fabricate any.

## Product Principles

1. **The platform is the artifact.** Anything built for one game should either be
   genuinely game-specific or be hoisted for every game — never incidental overlap.
2. **Every player sees only their own truth.** Per-user rendering through presenters is
   not an implementation detail; it is the product.
3. **Liveness is the promise.** If a change breaks the turn's broadcast round-trip, it
   breaks the product regardless of how it looks.
4. **Build only what was asked.** No accessibility, responsive, animation, or polish
   extras beyond the stated scope — ask first.
5. **Production standards on a learning project.** Spec-first TDD, small methods, real
   conventions, no shortcuts justified by "it's just practice."

## Accessibility & Inclusion

No formal conformance bar established. Don't ship anything actively broken, but do not
spend effort pursuing WCAG conformance unless it is requested.
