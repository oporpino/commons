---
name: br4zz4:tdd
description: Use when implementing any feature or bugfix, before writing implementation code.
version: 1.0.0
---

# commons:tdd

> **TLDR**: Write the test first, watch it fail, write minimal code to pass, refactor, commit. Repeat.

---

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Write code before the test? Delete it. Start over.

No exceptions:
- Don't keep it "as reference"
- Don't "adapt" it while writing tests
- Delete means delete

---

## The cycle

```
RED → verify RED → GREEN → verify GREEN → REFACTOR → commit → repeat
```

### RED — Write the failing test

Write one minimal test showing what should happen. One behavior, one clear name, real code (no mocks unless unavoidable).

```
test('rejects empty email', async () => {
  const result = await submitForm({ email: '' })
  expect(result.error).toBe('Email required')
})
```

### Verify RED — Watch it fail (MANDATORY, never skip)

```bash
<test command> <path>
```

Confirm:
- Test fails (not errors)
- Failure message is expected
- Fails because feature is missing (not a typo)

If the test passes immediately: you are testing existing behavior. Fix the test.

### GREEN — Write minimal implementation

Write the simplest code that makes the test pass. Duplicate logic, hardcoded values, naive loops — all acceptable. Correctness first.

Do not add features, refactor other code, or optimize beyond the test.

### Verify GREEN — Watch it pass (MANDATORY)

```bash
<test command> <path>
```

Confirm:
- Test passes
- Other tests still pass
- Output pristine (no errors, no warnings)

If another test breaks: fix now, before proceeding.

### REFACTOR — Clean up

After GREEN only:
- Remove duplication
- Improve names
- Extract helpers where intent is obscured
- Apply SOLID, DRY, KISS

Tests must stay green. Do not add behavior.

### Commit

```bash
git add <files>
git commit -m "<type>: <description>"
```

Commit at phase boundaries:

| When | Prefix |
|------|--------|
| Tests written, all RED | `test:` |
| Tests passing, GREEN | `feat:` or `fix:` |
| Refactor done | `refactor:` |
| Measured bottleneck fixed | `perf:` |

---

## Coverage requirement

Every logical branch must have a test:
- `if` → test truthy path AND falsy path
- `switch` → test every `case`
- Edge cases (empty input, nil, boundary values, error paths) each get their own test

---

## Executing a plan

When working from a `.project/docs/plans/` file, execute tasks in order:

1. Mark task `in_progress`
2. Follow the steps exactly — the plan has full code and exact commands
3. If a step is wrong or unclear, stop and raise it rather than improvising
4. Mark task `completed` only after tests green and commit done
5. Move to next task

After each task, apply `commons:verify` before claiming it complete.

---

## Red flags — stop and correct

| Thought | Reality |
|---------|---------|
| "I'll write the test after, it's faster" | Tests written after pass immediately — they prove nothing |
| "This is too simple to test" | Simple code breaks. The test takes 30 seconds. Write it. |
| "I'll refactor while making it work" | Finish GREEN first |
| "The test is hard to write" | The design is hard to use. Simplify the interface |
| "I only need one test for this function" | Count the branches. One test per branch |
| "I already manually tested it" | Manual is ad-hoc. No record, can't re-run |
| "Tests after achieve the same goals" | Tests-after answer "what does this do?" Tests-first answer "what should this do?" |

---

## When stuck

| Problem | Solution |
|---------|----------|
| Don't know how to test | Write the wished-for API. Assert first, then implement |
| Test too complicated | Design too complicated. Simplify interface |
| Must mock everything | Code too coupled. Use dependency injection |
| Test setup huge | Extract helpers. Still complex? Simplify design |

---

## Verification checklist (before marking any task complete)

- [ ] Every new function/method has a test
- [ ] Watched each test fail before implementing
- [ ] Each test failed for expected reason (feature missing, not typo)
- [ ] Wrote minimal code to pass each test
- [ ] All tests pass
- [ ] Output pristine (no errors, no warnings)
- [ ] Tests use real code (mocks only if unavoidable)
- [ ] Edge cases and error paths covered

Can't check all boxes? You skipped TDD. Start over.

Apply `commons:verify` before any completion claim.
