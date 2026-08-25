---
name: br4zz4:review-request
description: Use when completing tasks or before merging to verify work meets requirements.
version: 1.0.0
---

# commons:review-request

> **TLDR**: Dispatch a code reviewer subagent with precise context — not your session history. The reviewer evaluates the work product, not your thought process.

---

## When to request review

**Mandatory:**
- Before merging to `main`
- After completing a major feature

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing a complex bug

---

## How to request

### Step 1 — Get the SHAs

```bash
BASE_SHA=$(git rev-parse origin/main)
HEAD_SHA=$(git rev-parse HEAD)
```

Or for a specific range:

```bash
BASE_SHA=$(git log --oneline | grep "<task N description>" | head -1 | awk '{print $1}')
HEAD_SHA=$(git rev-parse HEAD)
```

### Step 2 — Prepare context

Gather:
- What was built (one paragraph summary)
- The spec or requirements (path to `.project/docs/specs/<file>.md`)
- The plan (path to `.project/docs/plans/<file>.md`, if exists)
- `BASE_SHA` and `HEAD_SHA`

### Step 3 — Dispatch a general-purpose subagent

Prompt the subagent with:

```
You are a code reviewer. Review the changes between BASE_SHA and HEAD_SHA.

## What was built
<one paragraph description>

## Requirements
<paste the spec or link to .project/docs/specs/<file>.md>

## Diff
Run: git diff <BASE_SHA>..<HEAD_SHA>

## Your task
Review for:
1. Correctness — does the implementation match the requirements?
2. Test quality — are tests meaningful? Do they test behavior, not mocks?
3. Code quality — SOLID, DRY, KISS applied? No unnecessary complexity?
4. Wehive rules — commits atomic? No comments explaining what the code does?
5. Missing coverage — any branch or edge case not tested?

## Output format
For each finding:
- **Severity:** Critical | Important | Minor
- **File:** `path/to/file.ext:line`
- **Issue:** what is wrong
- **Suggestion:** how to fix it

End with: **Assessment:** Ready to merge | Needs fixes
```

### Step 4 — Act on feedback

| Severity | Action |
|----------|--------|
| Critical | Fix immediately before any other step |
| Important | Fix before merging |
| Minor | Note for later; decide with the user |

If you disagree with a finding: push back with technical reasoning. Do not implement suggestions that break functionality, violate YAGNI, or conflict with prior architectural decisions. Apply `commons:review-receive` for complex feedback.

---

## Rules

- Never skip review because "it's simple"
- Never ignore Critical findings
- Never merge with unfixed Important findings
- Push back with evidence, not defensiveness
