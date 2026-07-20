---
description: Commit only the working-tree changes this session worked on, with a short message
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*), Bash(git log:*)
---

Commit the changes **this session** made — and only those.

1. Run `git status` and `git diff` to see what's in the working tree.
2. Select **only** the files that correspond to what you worked on in *this*
   conversation. Use your own memory of what you created or edited this session as
   the source of truth. If a changed file has nothing to do with what you did this
   session, **leave it unstaged** — assume it belongs to another session or the user.
3. If you're unsure whether a file is yours, do NOT commit it. List the ones you're
   skipping and why, so the user can decide.
4. Stage the selected files explicitly by path (`git add <path> ...`) — never
   `git add -A` or `git add .`.
5. Commit with a short, imperative description of what these changes add.

End the commit message with:

```
Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
```

Do not push. After committing, show `git status` so the user can see what was left
uncommitted.
