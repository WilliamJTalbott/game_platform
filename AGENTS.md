# AGENTS.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is & why it exists

A Rails 8 web platform for playing turn-based card games (**Go Fish** and **Crazy Eights**) against other people in real time. Users register, host or join a game lobby, and take turns that broadcast live to every participant via Turbo Streams / Action Cable. It also tracks per-user stats, game history, rules pages, and ships as an offline-capable PWA.

This is primarily a **skill-development project** for the author, but it should be built to real-world production standards — treat it as a real app, not a throwaway.

## Tech stack

- **Ruby 3.4.4**, **Rails 8.1**, **PostgreSQL**, **Puma**
- **Hotwire** (Turbo + Stimulus) front end; **Slim** templates; **Simple Form**; **@rolemodel/optics** design system
- **Webpack + esbuild** for JS, **PostCSS/SCSS** for CSS
- **GoodJob** for background jobs + cron
- **RSpec** + **FactoryBot** + **Capybara/Playwright** for tests
- **Kamal** + Docker for deploy; **Honeybadger** for errors
- **Auth is hand-rolled** (cookie-backed `Session` model + a `Current` object) — **no Devise**. Use `Current.session` / `current_user`.

## Run / develop

```sh
bin/setup            # install deps, prepare DB
bin/dev              # web server + JS build watcher (see Procfile.dev)
bundle exec good_job start   # background worker — needed for live turn broadcasts & cron
```

## Test & lint

```sh
bundle exec rspec                                   # full suite (the default day-to-day command)
bundle exec rspec spec/models/go_fish/game_spec.rb  # one file
bundle exec rspec spec/models/go_fish/game_spec.rb:42  # one example by line
bin/rubocop                                         # Ruby style (rubocop-rails-omakase)
bin/ci                                              # full CI: setup, rubocop, bundler-audit, brakeman
```

- **TDD-first is the goal.** Write the failing spec before the code. Feel free to recommend stronger/missing tests at any time.
- **Use FactoryBot for test setup wherever possible** rather than hand-building records.
- **Test at the lowest layer that can prove the behavior.** PORO game rules → `spec/models/{go_fish,crazy_eights}` (unit-tested exhaustively, no DB); persistence/`play_turn` glue → `spec/models/games`; per-user view data → `spec/presenters`; HTTP + authorization → `spec/requests`; live wiring only (Turbo broadcasts, JS) → `spec/system` (Playwright). Heuristic: a scenario that's still true with the browser off does **not** belong in a system spec — keep those few and coarse.
- **Request specs authenticate via `sign_in(user)`** (`spec/support/request_auth_helpers.rb`), which logs in through the real session endpoint. Note `cookies.signed[:session_id]` does *not* work in Rack::Test request specs — that's why the helper posts to `session_path` instead.

## Architecture (big picture)

Two layers **both contain a class named `Game`** — do not conflate them. The persistence layer is ActiveRecord (`Game` STI base → `GoFishGame` / `CrazyEightsGame`, joined to `User` through `Participant`). The game-logic layer is plain Ruby (`GoFish::Game`, `CrazyEights::Game`, and their `Player`/`Deck`/`Card`/`TurnResult`), holding the rules and mutable state with no DB awareness.

The bridge is the **`state` jsonb column**: each `*Game` subclass `serialize`s its PORO game into `state` via custom `dump`/`load` (`as_json` / `from_json`). A turn = load PORO from jsonb → mutate → `save!` → re-render per-user through a presenter → broadcast over Turbo Streams.

See **[docs/architecture.md](docs/architecture.md)** for the full model map, the turn cycle, and how to add a new game type.

## Conventions worth knowing

These are things you would *not* infer from a quick read:

- **7-line methods.** Keep every method to ~7 lines or fewer — this is the dominant norm, broken only where a longer method is genuinely clearer. Treat each `it` block in specs the same way (~7 lines ideally). If a method runs long, extract a well-named private method.
- **Structure specs as Given/When/Then.** The *given* (the subject and its baseline state) belongs in the `describe` block; the *when* (the action or condition under test) belongs in an inner `context` block (prefer `context` over nested `describe` for this); the *then* (the expectation) belongs in the `it` block. Read top-to-bottom, a spec should say "describe X, given …; context when …; it then …".
- **Instance variables:** fine in Rails code (controllers, models, views). Avoid them in plain Ruby scripts — prefer passing values through arguments and return values.
- **The jsonb round-trip is a trap.** Every PORO implements `as_json` + `self.load`. Add a field to one without the other and it silently vanishes on reload. And `play_turn` only persists because the STI subclass calls `save!` — mutating the PORO alone changes nothing.
- **Keep controllers skinny.** Validation lives in **Form objects** (`app/forms/`, `ActiveModel::Model` wrappers over PORO state); rules live in the POROs. Controllers just validate-then-delegate.
- **Always render through a Presenter** (`app/presenters/`), never a model directly — presenters build the *per-user* view so each player sees only their own hand and message log. Use them correctly and as the norm.
- **CSS is served by Propshaft, not bundled.** Styling uses the **Optics** design system (via CDN) + **design tokens** (`--op-*` from Optics, `--gf-*`/`--_gf-*` for the project) + **BEM** class naming, one block per file in `app/assets/stylesheets/components/`. To add styles you just drop a `.css` file there — `stylesheet_link_tag :app` auto-includes it; there is no manifest, `@import`, or CSS build step. The empty `application.css` and webpack CSS build are unused — don't "fix" them. See [docs/frontend.md](docs/frontend.md).

## Key context

- **[docs/architecture.md](docs/architecture.md)** — the two `Game` layers, jsonb serialization, the turn/broadcast cycle, adding a game type.
- **[docs/frontend.md](docs/frontend.md)** — how CSS loads (Propshaft `:app`, no bundler), Optics, design tokens, and BEM conventions.
- **[docs/games/go-fish.md](docs/games/go-fish.md)** — Go Fish rules and how `GoFish::Game` implements them.
- **[docs/games/crazy-eights.md](docs/games/crazy-eights.md)** — Crazy Eights rules and how `CrazyEights::Game` implements them.
