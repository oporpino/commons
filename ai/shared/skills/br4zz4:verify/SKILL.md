---
name: br4zz4:verify
description: Use when about to claim work is complete, fixed, or passing — before committing or creating PRs.
version: 1.0.0
---

# commons:verify

> **TLDR**: Run the actual verification command, read the full output, then make the claim. Evidence before assertions, always.

---

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command in this message, you cannot claim it passes.

---

## The gate

```
BEFORE claiming any status:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the full command (fresh, complete — not from a previous run)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = making a claim without evidence
```

---

## Common claims and what they require

| Claim | Requires | Not sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, "looks good" |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Task complete | Re-read plan → checklist → every item verified | Tests pass |

---

## Required verifications by context

### After implementing a task

```bash
# Run the test file for the task
<test command> <path>

# Run the full suite to check regressions
<test command>
```

Both must pass before marking the task done.

### Before opening a PR

```bash
# Full test suite
<test command>

# Linter / type check (if applicable)
<lint command>

# Build (if applicable)
<build command>
```

All must pass. If any fails, fix and re-run — do not open the PR.

### After a bugfix

Verify the original symptom is gone:

```bash
# Run the test that reproduces the bug
<test command> <specific test>
```

Must pass. Then run full suite for regressions.

---

## Red flags — stop

- Using "should", "probably", "seems to"
- Expressing satisfaction before running verification ("Done!", "Fixed!", "Complete!")
- About to commit or open a PR without running the suite
- Trusting that a previous run is still valid
- Partial check ("tests for this file pass" ≠ "full suite passes")
- Thinking "just this once"

---

## Rationalization prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | Run the verification |
| "I'm confident" | Confidence ≠ evidence |
| "Linter passed" | Linter ≠ test suite |
| "I'm tired" | Exhaustion ≠ excuse |
| "Partial check is enough" | Partial proves nothing |

---

## After verification passes

State the result with evidence:

```
Tests: 47/47 pass (0 failures)
Linter: clean
Build: exit 0

Ready to open PR.
```

Never just say "done" or "looks good". Show the output.
