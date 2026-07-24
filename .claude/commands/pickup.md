---
description: Resume from the latest handoff — read it, run the suite, briefly report what's broken, and stand ready to continue
allowed-tools: Bash(ls:*), Bash(bundle exec rspec:*), Bash(git status:*), Bash(git log:*), Bash(git diff:*), Read, Glob, Grep
---

Reorient at the start of a session that continues someone else's (or past-you's)
work. The goal is to get from cold start to "I know where we are and what's
next" in one screen of output — not to fix anything yet.

## 1. Find and read the latest handoff

Handoffs live in `docs/handoffs/` named `YYYY-MM-DD-<slug>.md`, so the newest
sorts last by filename:

```
ls docs/handoffs/
```

Take the highest date. If two share a date, prefer the one whose content matches
the current branch and most recent commits — the filename date is coarser than
the work. Read it in full; it's short, and its *Decisions made* section exists
specifically so you don't re-litigate settled choices.

If `docs/handoffs/` is empty or missing, say so and fall back to `git log` +
`git status` for orientation, then skip to step 3.

## 2. Run the suite

```
bundle exec rspec
```

Then build the failure report the way `/rs` does — **from RSpec's own output
only**. Don't open source files to explain a failure. The reason is that this
report is for *deciding*, not fixing: a hypothesis from the failure message is
enough to tell you whether a failure is the work in progress or a surprise, and
digging into `app/` turns a 30-second orientation into a 10-minute one. There'll
be time to read code once you've picked a direction.

The single most useful judgment here is **sorting failures into expected vs.
unexpected**, because this project is TDD-first — a handoff that stopped
mid-feature will legitimately leave red specs, and those are a to-do list, not a
regression. Use the handoff's *What's left* section as the key: failures it
predicts are expected; anything else is a surprise and matters more, even if
there's only one.

If a large number of unrelated specs fail at once, suspect environment before
code — a seeded test DB is the classic cause here (see AGENTS.md on never
running `rails db:seed` against the test DB, and on `Game.finished` exact-match
scopes). Name the suspicion in one line rather than triaging each failure.

## 3. Report

Be ruthlessly brief — this is a status glance, not a document. Use this shape:

```
**Handoff:** `docs/handoffs/<file>` — <one line: what it was doing>
**Suite:** N failures / M examples

<omit this block entirely if green>
🔴 Unexpected
- <spec description> — <what happened> → <one-line hypothesis>

🟡 Expected (handoff's remaining work)
- <spec description> — <what happened>

**Next:** <the single next step, from the handoff's "What's left">
```

Omit either failure group when it's empty; drop both when the suite is green and
just report the count. Keep each bullet to one line. Group failures sharing an
obvious root cause into a single bullet.

## 4. Stand ready — don't start

End after the report. Don't edit files, don't fix failures, don't begin the next
step — the user is choosing what to work on, and the point of this command is to
hand them that choice with the context loaded. If the handoff's next step is
ambiguous, or the suite reveals something that changes what the next step should
be, say which in one sentence and ask.
