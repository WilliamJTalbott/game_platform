---
description: End-of-session doc hygiene — fix stale docs/AGENTS.md, persist what was learned, and surface uncaptured plans
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(wc:*), Read, Edit, Write, Glob, Grep
---

Run this at the end of a session to leave the project's memory better than you
found it. The point isn't to write more — it's to make sure the next agent starts
from something true. The deliverable is a short report built from exactly 3 fixed,
emoji-tagged sections, in this order. Work through them in that order too, since
each step's investigation feeds the next.

**Only include a section if it has real content.** Sections 1-2 are omitted
entirely when nothing relevant happened this session — no "nothing to report"
placeholder, just skip straight to the next section. Section 3 always appears.
This applies everywhere in the report, not just at the section level: don't
explain *why* a section was skipped, note that you checked and found nothing,
or otherwise reference an omitted section from within Status or anywhere else.
An omission should be silent — the reader shouldn't be able to tell whether you
checked and found nothing or forgot to check.

**Every section that does appear must be extremely brief.** A few bullets, not
paragraphs — a future agent (or you, next session) should be able to read the
whole report in a few seconds. Do the investigating and thinking silently;
report only the conclusion. If a section is tempted to run long, that's a sign
to cut it down, not a sign the content deserves the space.

## 📄 Stale Docs

Before adding anything, find what's now *wrong*. Skim `AGENTS.md` and `docs/`
against what actually changed this session (a quick `git diff`/`git log` helps).
Flag lines that the code, tests, or file layout no longer match — a stale line
costs a future agent more than a missing one, so this is the highest-value part
of wrap-up. List what should be updated. If a doc looks like it should be
*deleted* outright (rare — e.g. it describes something fully removed this
session), name it and ask permission before deleting; don't delete unilaterally.
Omit this section if docs still hold up.

## 📌 AGENTS.md Updates

Propose only what a future agent would genuinely need and *couldn't* infer from
the code, tests, or git history — non-obvious conventions, gotchas, or decisions.
List out each proposed addition/change explicitly and ask for permission before
making it — don't edit AGENTS.md until the user confirms. Prefer editing or
removing a stale line over appending a new one.

**AGENTS.md hard cap: 200 lines.** It's a curated index a future agent reads
top-to-bottom, not a changelog — bloat makes it stop being read. Check with
`wc -l AGENTS.md`. If a proposed addition would push it over, name what you'd
cut or tighten lower down to stay under budget. Omit this section if there's
nothing worth proposing.

## 🟢 Status

Always include this section, headed with a circle emoji — 🟢, 🟡, or 🔴 — rating
how good a place this session is at to stop. Favor 🟢: reserve 🟡 for a loose
end that's worth naming but not blocking, and 🔴 for something genuinely unresolved
that's a real reason not to wrap up yet (a broken test, a half-applied refactor,
a contradiction you introduced and haven't reconciled). **Uncommitted changes are
never on their own a reason to downgrade from 🟢** — that's normal end-of-session
state.

Summarize what was accomplished this session and name the likely next step, so
anyone picking this up — including future-you — can reorient in a few seconds
without replaying the whole conversation. If the rating is 🟡 or 🔴, lead with
what's unresolved before the summary.

Also use this moment to surface any planned, deferred, or "we should
eventually…" work that came up but isn't written down anywhere (`docs/plans/`,
an issue, a TODO) — these evaporate when the session closes. Fold that into
this section, and offer to jot it into `docs/plans/` if it isn't already.
