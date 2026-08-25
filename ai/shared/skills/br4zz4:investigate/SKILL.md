---
name: investigate
description: Use when asked to investigate or fix a bug.
version: 2.0.0
---

# commons:investigate

> **TLDR**: Investigate first, fix second, document third. Never assume — always verify. Root cause before any fix.

---

## Model suggestion — start

Before investigating, **check the current model first**. If already on Opus, skip this entirely — don't ask. Only if on a lighter model, suggest switching (root-cause work rewards it), presenting the exact command as a copyable block:

> "Investigação de bug rende mais no Opus. Rode:
> ```
> /model opus
> ```
> antes de começarmos."

Suggest once; don't insist. Continue regardless of the choice.

---

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

Quick patches mask underlying issues. If you haven't completed Phase 1, you cannot propose fixes.

---

## Phase 0 — Asana task

Before investigating, ask: "Qual o ID ou link da task pai no Asana?" Store the GID — it will be used when creating the subtask after the fix.

---

## Phase 1 — Investigate

**Goal:** Understand the root cause. Do not assume anything — verify everything.

### Steps

1. **Read error messages carefully**
   - Don't skip past errors or warnings
   - They often contain the exact solution
   - Read stack traces completely — note line numbers, file paths, error codes

2. **Read business rules** — scan `.project/docs/rules/` for relevant rules (check `.project/docs/RULES.md` index if it exists)

3. **Understand the code path** — trace the bug from entry point to failure; read all involved files before drawing conclusions

4. **Reproduce consistently**
   - Can you trigger it reliably? What are the exact steps?
   - If not reproducible → gather more data, don't guess

5. **Check recent changes**
   - `git log --oneline -20` and `git diff` to understand what changed recently
   - New dependencies, config changes, environmental differences

6. **Gather evidence in multi-component systems**

   When the system has multiple components (API → service → database, CI → build → signing):

   Before proposing fixes, add diagnostic instrumentation at each boundary:
   - Log what data enters each component
   - Log what data exits each component
   - Verify config propagation at each layer

   Run once to gather evidence showing WHERE it breaks, then analyze.

7. **Trace data flow for deep failures**

   When the error is deep in the call stack:
   - Where does the bad value originate?
   - What called this with the bad value?
   - Keep tracing up until you find the source
   - Fix at source, not at symptom

8. **Query production data if needed** (read-only only):
   - Run `make code.console.on_production_database` — sandbox enabled (no writes persisted)
   - Ask the user to run and paste output if you cannot run it yourself
   - **Never run commands that write, update, or delete data**
   - Plan what you need before querying — avoid redundant queries

9. **When uncertain** — investigate more or ask the user. Never fill gaps with assumptions.

### Deliverable — Investigation Summary

Present a clear summary:

| Field | Detail |
|---|---|
| **Symptom** | What the user observed |
| **Root cause** | The actual code/data/logic reason |
| **Affected scope** | Files, models, services, jobs impacted |
| **Side effects** | Other behaviors affected by this bug |
| **Proposed fix** | High-level description of the solution |

### Pattern analysis (when root cause not yet clear)

1. Find working examples — locate similar working code in the same codebase
2. Compare against references — what is different between working and broken?
3. List every difference, however small — don't assume "that can't matter"
4. Understand dependencies — config, environment, what does this assume?

### Hypothesis testing

1. Form a single hypothesis: "I think X is the root cause because Y"
2. Test minimally — the smallest possible change to test the hypothesis
3. One variable at a time — don't fix multiple things at once
4. If hypothesis fails: form a NEW hypothesis, don't add more fixes on top
5. If 3+ hypotheses fail: stop and question the architecture before trying more

### Techniques

**Root-cause tracing** — when the error surfaces deep in the call stack, trace *backward* through the call chain to the original trigger (the code that first introduced the bad value or wrong path), and fix there. Fixing where the error appears treats a symptom; fixing at the trigger removes the class of bug.

**Defense-in-depth** — after fixing at the source, consider validating at every layer the bad data passes through (entry point, business logic, environment guard). One check can be bypassed by another code path or a refactor; layered validation makes the bug structurally impossible. Apply when the invalid value could re-enter through a different path — don't over-guard scenarios that can't happen (see Phase 2 rules).

**Condition-based waiting** — a flaky test that uses `sleep`/`setTimeout` with an arbitrary delay is a race condition, not a real failure. Replace the guess with a wait on the actual condition you care about (poll until the state is true, with a timeout). Only keep an arbitrary delay when the test is *about* timing (debounce/throttle) — and then document why.

---

## Phase 1.5 — Write and commit the spec

After presenting the investigation summary and before writing any code:

1. Apply `commons:spec` to write the spec file (status `proposed`) describing the fix
2. Commit the spec immediately:
   ```bash
   git add .project/docs/specs/<filename>.md
   git commit -m "docs: spec <short_description>"
   ```
3. Show the spec to the user and wait for approval before proceeding

After approval, **check the current model first**. If already on Sonnet, skip this — don't ask. Only if on Opus, suggest switching for the fix ahead (it's mechanical), presenting the exact command as a copyable block:

> "Root cause fechado e spec aprovada. O fix daqui é mecânico e roda bem no Sonnet. Rode:
> ```
> /model sonnet
> ```"

Suggest once; don't insist.

---

## Phase 2 — Fix (minimal, targeted)

**Goal:** Resolve the bug with the smallest correct change. No refactoring, no extras.

### Before you start

1. **Try to fix in the database first** — if the bug is a data inconsistency, correct the production records via `make code.console.on_production_database.unsafe`. Only move to a code fix if a data fix is not possible or not sufficient.
2. **Create a branch** from `main`:
   ```bash
   git pull --rebase origin main
   git checkout -b fix/<short-description>
   ```
   Wait for confirmation before implementing.
3. **Ask the user** whether they want one PR per bug or a single PR for all fixes — decide based on context. Wait for the answer before proceeding.

### Steps

1. **Write the failing test first** (using `commons:tdd`) — the test must fail before the fix
2. **Implement the fix** — the smallest correct change
3. **Run tests**: `make run.test path=<path>` — must go green
4. **Apply `commons:verify`** before claiming the fix is done
5. **Commit test + fix together** following `commons:commit` rules

### Rules

- Fix only what is broken — do not clean up surrounding code
- Do not add error handling for scenarios that cannot happen
- Do not add features or configurability beyond what is needed
- If existing tests fail, fix the test only if the test was wrong — otherwise fix the code

### Deliverable

- Test + fix committed together, all green
- Apply `commons:finish` to open PRs or merge
- Apply `commons:asana` to create a subtask under the parent task with the PR link

---

## Phase 3 — Document the learning

Apply `commons:docs` for this phase.

- Create a learning file in `.project/docs/learnings/` following the learning format defined in `commons:docs`
- If the learning reveals a general pattern applicable to other WeHive projects, also create or update `.commons/ai/shared/rules/<topic>.md`

---

## Phase 4 — Update project documentation

Apply `commons:docs` for this phase.

1. If the bug involved a documented business rule in `.project/docs/RULES.md`: update the rule file and set `updated:` to today
2. If the fix changes how a rule behaves: rewrite the Given/When/Then block to reflect the correct behavior
3. If no rule exists yet for the fixed behavior: create one following `commons:docs` rules

---

## Red flags — stop and follow the process

| Thought | Reality |
|---------|---------|
| "Quick fix for now, investigate later" | Root cause first — always |
| "Just try changing X and see" | Guessing creates new bugs |
| "Add multiple changes, run tests" | Can't isolate what worked |
| "It's probably X, let me fix that" | Seeing symptoms ≠ understanding root cause |
| "One more fix attempt" (after 2+) | 3+ failures = question the architecture |
| Each fix reveals a new problem | Architectural issue — stop and discuss |

---

## Console safety rules

| Situation | Command | Safe? |
|---|---|---|
| Read production data | `make code.console.on_production_database` | Yes — sandbox mode |
| Write production data (fix) | `make code.console.on_production_database.unsafe` | Ask user first |
| Local dev console | `make run.console` | Yes |

- Always use sandbox-enabled console when reading production data
- Never call `.save`, `.update`, `.destroy`, `.delete`, `.create`, or any method that writes
- If you are unsure whether a method writes: ask before running it
