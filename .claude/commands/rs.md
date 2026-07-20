---
description: Run the RSpec suite and report failures + their likely underlying issue — fast, no source digging
allowed-tools: Bash(bundle exec rspec:*)
---

Run the full test suite:

```
bundle exec rspec
```

Then report the failures. **Speed is the priority — do NOT open, read, or search the source code to build this report.** Work only from what RSpec already gives you: the failure message, the expectation diff, the backtrace, and the test's own description (the `describe`/`context`/`it` strings that RSpec prints).

For each failure, report:
- **What the test wanted** — paraphrase the failing example's description (the full nested `describe > context > it` string) so it's clear what behavior was being asserted.
- **What actually happened** — the failure message / diff (expected vs. got, the exception class + message, etc.).
- **Likely underlying issue** — a one-line hypothesis inferred *from the failure message alone*. If the message isn't enough to guess, say so rather than going to read the code.

Rules:
- Do not use Read, Grep, Glob, or Edit. Do not go hunting through app/ or spec/ files.
- If the whole suite passes, just say so — one line.
- Group related failures if several share an obvious root cause, but keep it terse.
- End with a count: `N failures / M examples`.
