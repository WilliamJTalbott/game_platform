---
description: Stage and commit ALL uncommitted changes with a short description
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*), Bash(git log:*)
---

Commit **everything** in the working tree — no session filtering.

1. Run `git status` and `git diff` to see all changes.
2. Stage everything with `git add -A` (tracked, untracked, and deletions).
3. Commit with a short, imperative description summarizing the changes.

End the commit message with:

```
Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
```

Do not push. After committing, show `git status` to confirm a clean tree.
