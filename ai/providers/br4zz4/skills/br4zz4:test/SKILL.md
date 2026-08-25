---
name: skill:test
description: Use this skill when the user asks to create or write tests for the files changed in the current diff.
version: 1.0.0
---

Create tests for the files changed in the current diff following the steps below.

## 1. Identify changed files

Run `git diff --name-only HEAD` and `git diff --name-only --cached` to list modified files.
Filter only code files (exclude test files, configs, assets).

## 2. Critical rules before starting

- If test files already exist for the changed files, **do NOT modify them** without asking the user for explicit permission
- If the user asks to fix an existing test, **do NOT change production code** to make it pass
- These rules exist to prevent false positives and bugs introduced by adjusting tests

## 3. For each changed code file

Analyze the diff (`git diff HEAD -- <file>`) and identify:

- **Happy path**: the success flow of the changed function/module
- **Alternative flows**: errors, edge cases, validations, different return conditions
- **Boundary inputs**: null, empty, limit values

## 4. Write the tests

For each identified flow, create a test following the rules in `@../../rules/shared/testing.md`:

- Triple A pattern with explicit comments (`# arrange`, `# act`, `# assert`)
- Atomic tests — everything instantiated inside the test
- One assert per test (maximum 3)
- Use mocks for external dependencies in unit tests
- Do NOT use mocks in integration tests

If you need to modify an existing test file, **ask the user for confirmation first**, describing exactly what will be changed and why.

## 5. Verify tests pass

After creating/updating tests, run:

```
make t
```

If any test fails:
- Analyze the error
- If the issue is in the test → fix the test
- If the issue indicates a real bug in the code → **report to the user, do not fix the code automatically**
