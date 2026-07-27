---
name: implement
description: Execute a written plan from docs/plans/ — read the plan (the latest one, or the one named after the command), read the code it touches, interview the user one question at a time until the ambiguity is gone, present the attack order, and only build after they approve. Use this whenever the user says /implement, or asks to "implement the plan", "build out the plan", "start on the waiting-room plan", "pick up <plan-name>", "let's do the plan we wrote", or otherwise points at a plan document and asks for it to become code.
allowed-tools: Bash, Read, Glob, Grep, Edit, Write, AskUserQuestion, TodoWrite, Skill
---

Turn a written plan into working code without the two failure modes that make
plan execution go wrong: **building the wrong thing** (the plan was ambiguous and
you guessed) and **building more than was asked** (the plan was a menu and you
ate the whole thing).

The guard against both is the same: read everything first, resolve ambiguity out
loud with the user, then state the attack order and stop until they say go.

---

## 1. Find and read the plan

Plans live in `docs/plans/*.md`. If the user named one after the command
(`/implement game-lobby-waiting-room`, or "the rummy popup plan"), match it by
filename fragment or title — fuzzy is fine, plans have distinctive names.

Otherwise take the **most recently modified** file:

```
ls -t docs/plans/
```

Mtime beats git history here because plans get edited far more than they get
committed — a plan the user was revising ten minutes ago is the one they mean,
even if its last commit is a week old.

State which plan you picked in one line before going further, so a wrong guess
costs a sentence instead of an hour. If two are plausibly "the latest," that's
your first question (see §3) — don't silently pick.

Read the plan in full. Plans in this repo carry a **status legend**
(🟡 planned · 🟢 in progress · ✅ done). Sections already marked ✅ are finished
work, not your job — reread them for context, then leave them alone. If the plan
has no markers, treat all of it as 🟡.

## 2. Read the code the plan touches

Plans here quote real files and line numbers. Open every file the plan names,
plus the specs that cover them, plus the immediate neighbours (the presenter for
a model, the partial for a controller action, the other two game subclasses when
one is changing).

You are reading for three things:

- **Has the code moved?** Plans go stale. A line number that no longer says what
  the plan claims, or a defect the plan describes that's already fixed, changes
  the work — surface it rather than implementing against a world that's gone.
- **What's the existing pattern?** This codebase has strong conventions
  (presenters, form objects, `Serializable`, BEM one-block-per-file CSS, the
  shared `"a platform game"` contract spec). The plan usually assumes them
  without restating them. AGENTS.md and `docs/` are the reference.
- **Where does the seam actually go?** The plan says what; the code says where.

Skim rather than exhaustively read files the plan only mentions in passing —
the point is enough grounding to ask sharp questions, not a full audit.

## 3. Interview — one question at a time

Now ask the user what the plan doesn't say. **One question per turn**, using
AskUserQuestion, and *wait for the answer before asking the next one* — each
answer usually reshapes what's worth asking next, and a batch of four questions
written before any of them are answered is mostly wasted.

Ask about the things where two readings lead to genuinely different code:

- Scope boundaries — the plan lists five sections; is this all five or just §1?
- Choices the plan left open, or where it offers alternatives without picking.
- Contradictions between the plan and the current code (from §2).
- Anything the plan defers ("later," "eventually," "nice to have") that you'd
  otherwise be tempted to build — AGENTS.md's Scope Discipline is explicit that
  deferred polish stays deferred.

Do **not** manufacture questions to look thorough. If the plan is clear and the
code matches it, ask nothing and go straight to §4 — an interview for its own
sake wastes the user's turn. Two or three real questions is a normal ceiling;
if you're on your fifth, the plan probably needs rewriting more than executing,
and saying so is more useful than continuing to interrogate.

Prefer questions with concrete options over open-ended ones. "Sections 1–3 now
and 4–5 later, or all five?" gets an answer; "how would you like to approach
this?" gets a shrug.

## 4. Present the attack order — then stop

Lay out how you'll tackle it, ordered the way you'll actually work. For each
step, name the files and the spec that proves it. Keep it scannable:

```
**Plan:** `docs/plans/<file>.md` — <one line on what it delivers>
**Scope:** <which sections; what's explicitly out>

1. <step> — spec: `spec/<path>_spec.rb` · code: `app/<path>.rb`
2. ...

**Assumptions:** <anything you decided rather than asked>
**Not doing:** <deferred items you're deliberately leaving>
```

Steps are TDD-shaped by default — this project is spec-first — so a step that
can't name the spec that will prove it is a step worth questioning aloud.

Then **stop and wait for approval.** This is the whole point of the command: the
user gets to redirect before code exists, when redirecting is free. Don't start
"just the first step" while waiting.

## 5. Build it

Once approved, work the steps in order, TDD-first per AGENTS.md: failing spec →
implementation → green. Track progress with TodoWrite so the user can see where
you are in a long run.

Two habits specific to plan execution:

- **Update the plan's status markers as you go** — 🟡 → 🟢 when you start a
  section, 🟢 → ✅ when its specs are green. The plan is the shared record of
  what's done; leaving it stale is how the next session redoes finished work.
- **Come back if the plan is wrong.** If a step turns out to be impossible or
  clearly mistaken once you're inside it, stop and say so rather than
  improvising a different feature. The approved attack order is the contract.

Finish with `bundle exec rspec` and `bin/rubocop`, and report the result
honestly — failures named, anything skipped called out. Don't commit unless
asked; `/commit` exists for that.
