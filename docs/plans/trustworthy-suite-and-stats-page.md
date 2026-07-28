# Trustworthy suite, honest stats page

**Goal: `bundle exec rspec` goes green and the stats page looks like the rest of the
house — so a green suite means "working" and a screenshot means "designed."**

Right now neither is true, and both failures are the same *kind* of problem: the
project's two fastest feedback loops each report something false. The suite reports 22
failures that nobody is expected to fix. The stats page renders a layout nobody chose.
Until both are fixed, every session starts by re-deriving which red is real.

Status legend: 🟡 planned · 🟢 in progress · ✅ done

---

## 1. The suite reports 22 failures that are not bugs 🟡

`bundle exec rspec` → **456 examples, 22 failures**, every one of them:

```
Bullet::Notification::UnoptimizedQueryError:
  GET /games
  Need Counter Cache with Active Record size
    GoFishGame => [:participants]
```

They surface as four shapes — `get games_path`, `get history_index_path`,
`click_button 'Log in'` (the login helper's redirect lands on the games index), and
`have_current_path(root_path)` — but there is one cause.

**This is load-bearing context:** `spec/system/ramp_preview_spec.rb` already sets
`Bullet.enable = false` in an `around` hook *specifically* to dodge this, with a comment
calling it pre-existing and unrelated. So the workaround is in the codebase but the
underlying issue is written down nowhere, and a newcomer running the suite has no way to
know the red is expected.

Pick one and commit to it:

1. **Add the counter cache** — `participants_count` on `games`, and let Bullet's advice
   stand. Correct, and the games index really does `.size` a `has_many` per row.
2. **Scope the advisory off** for the games index if the counter cache isn't wanted yet
   (`Bullet.add_safelist`), which turns 22 false failures into zero without pretending
   the query is optimal.

Option 1 is the real fix. Either way, delete the `Bullet.enable = false` hook from
`ramp_preview_spec.rb` afterwards — it exists only to work around this.

*Note:* the presenters (`game_lobby_presenter.rb`, `history_presenter.rb`) have
uncommitted changes on this branch; check whether they already move in this direction
before starting.

## 2. The stats page's blocks stretch to the full viewport 🟡

`/stats` renders its three stat blocks ("Number of Games Played", "Number of Games Won",
"Win Percentage") as columns that grow to the **entire** viewport height, with the value
(`1`, `0`, `0.0%`) stranded as a tiny number near the top-left of each. See
`tmp/screenshots/ramp-06-stats.png` from any run of `ramp_preview_spec.rb`.

The colors are correct — this is purely a flex/grid sizing bug, so it is *not* fallout
from the token work. Suspect `components/lobby/stat_block.css` and/or the surrounding
grid in `stats.css`, both of which have uncommitted changes on this branch.

## 3. `.impeccable/design.json` still carries pre-OKLCH values 🟡

The narrative rules were corrected (the retired Pair Rule now says so, and the dos/donts
point at the three neutral families) — but the **data** blocks were not, and they still
describe a palette this app no longer has:

- `extensions/colorMeta/*/canonical` — every neutral is still a `light-dark()` HSL pair
  from before the OKLCH migration (`warm-neutral-page` is `light-dark(hsl(49 14% 100%),
  hsl(49 14% 8%))`; it is now `oklch(18.29% 0.0105 53.9)`, dark-only).
- `extensions/shadows[*].value` — still `light-dark()` composites.
- `components[*].css` — the reference snippets still hard-code `light-dark()` fills.

Regenerating these is a mechanical pass against DESIGN.md's frontmatter, but it is a
wholesale rewrite of the file's data rather than a line fix, which is why it was left.
Worth doing before anyone treats `design.json` as a source of truth again.

## 4. Two known token bugs live in the other plan

Both are tracked in [own-the-tokens.md](own-the-tokens.md) §8 and are still open — listed
here only so this file isn't mistaken for the whole picture:

- `components/game/hand_card.css:68` — `var(--gp-font-size-x-large)` does not exist (the
  token is `--gp-font-x-large`); the declaration is invalid and the `font-size` silently
  inherits.
- `components/lobby/game_card.css:45` — a `color-mix()`, which AGENTS.md and DESIGN.md
  both forbid.
