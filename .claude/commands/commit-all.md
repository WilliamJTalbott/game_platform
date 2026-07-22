---
description: Stage and commit ALL uncommitted changes with a short description
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*), Bash(git log:*)
---

Commit **everything** in the working tree — no session filtering.

1. Run `git status` and `git diff` to see all changes.
2. Stage everything with `git add -A` (tracked, untracked, and deletions).
3. Commit with a single-line, imperative header stating the change's intent,
   not a literal description of the diff. No body unless the *why* is truly
   non-obvious.

End the commit message with:

```
Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
```

Do not push. After committing, show `git status` to confirm a clean tree.
