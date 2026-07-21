---
description: End-of-session doc hygiene — fix stale docs/AGENTS.md, persist what was learned, and surface uncaptured plans
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(wc:*), Read, Edit, Write, Glob, Grep
---

Run this at the end of a session to leave the project's memory better than you
found it. The point isn't to write more — it's to make sure the next agent starts
from something true. Work through these in order; keep every reply to the user
short and skimmable (bullets, not paragraphs).

## 1. Check for stale docs first

Before adding anything, find what's now *wrong*. Skim `AGENTS.md` and `docs/`
against what actually changed this session (a quick `git diff`/`git log` helps).
Flag lines that the code, tests, or file layout no longer match. A stale line
costs a future agent more than a missing one, so fixing or deleting these is the
highest-value part of wrap-up — do it before you consider new additions.

## 2. Update docs & AGENTS.md

Add only what a future agent would genuinely need and *couldn't* infer from the
code, tests, or git history — non-obvious conventions, gotchas, or decisions.
Prefer editing or removing a stale line over appending a new one. Put durable
project knowledge in the right place: architecture/convention notes in `docs/`
or `AGENTS.md`, game rules in `docs/games/`.

**AGENTS.md hard cap: 200 lines.** It's a curated index a future agent reads
top-to-bottom, not a changelog — bloat makes it stop being read. Check with
`wc -l AGENTS.md`. If an addition would push it over, cut or tighten something
lower-value first so it stays under budget.

## 3. Report what you learned

Give the user a short bulleted list of what you learned this session that's worth
persisting, and where you put it (or where you'd put it, if you want their nod
first). This is the moment for them to veto or redirect — keep it tight so it's
easy to react to.

## 4. Surface uncaptured future plans

Before the session ends, list any planned, deferred, or "we should eventually…"
work that came up but isn't written down anywhere (`docs/plans/`, an issue, a
TODO). These evaporate when the session closes, so naming them — and offering to
jot them into `docs/plans/` — is how they survive.
