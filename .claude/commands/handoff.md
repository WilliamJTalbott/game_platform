---
description: Write a handoff summary of this session to docs/handoffs/
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(date:*), Read, Write, Glob, Grep
---

Write a handoff summary to a file in `docs/handoffs/`. Name it
`docs/handoffs/YYYY-MM-DD-<short-slug>.md` (use today's date and a short slug
describing the work). Create the `docs/handoffs/` folder if it doesn't exist.

Include:

- **What we were working on** — the goal and any relevant context.
- **What's done** — changes made this session, with file paths.
- **What's left** — remaining work and known open questions.
- **Decisions made** — choices and their rationale, so the next person doesn't
  re-litigate them.

Keep it concise and skimmable — enough for someone (or a future agent) to pick up
where we left off, no more. Don't restate what the diff or git history already
shows. After writing, print the file path.
