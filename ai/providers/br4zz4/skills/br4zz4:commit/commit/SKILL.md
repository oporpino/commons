---
name: skill:commit
description: Use this skill when the user asks to commit, create a commit, or stage and commit changes. Enforces atomic, single-line commits with no AI mentions.
version: 1.0.0
---

# Commit Skill

## Mandatory rules

1. **Atomic**: a single logical context per commit (easy to revert in isolation)
2. **One line**: no body, no bullet points, no paragraphs
3. **Maximum 60 characters** in the message
4. **No AI mentions**, co-authors, tools or assistants — never include `Co-Authored-By` or similar
5. **Separated by context**, not by file — changes with the same purpose go in the same commit

## Format

```
type: short description
```

Valid types: `feat`, `fix`, `refactor`, `docs`, `style`, `test`, `chore`, `perf`, `ci`

## How to proceed

1. Run `git status` to understand what changed
2. Check if any submodule is listed as `modified` — if so, follow the **Submodule flow** below first
3. Analyze the diff and identify groups of changes by logical context
4. If there are multiple contexts, create separate commits with selective staging
5. Stage the files for the context → commit with a message within the rules
6. Never use `git add .` or `git add -A` without checking what is being included

## Submodule flow

When `git status` shows a submodule as modified (dirty or new commits):

1. `cd` into the submodule directory
2. Run `git status` and `git diff` to understand what changed inside
3. Commit the changes inside the submodule following the same rules
4. Push the submodule: `git push origin main`
5. Go back to the root project
6. Stage the submodule pointer: `git add <submodule-path>`
7. Commit the pointer update: `chore: update <submodule-name> pointer`
8. Never commit the pointer update without pushing the submodule first

## Valid examples

```
feat: add support for multiple mirrors
fix: fix duplicate package check
refactor: extract privilege logic to helper
docs: update installation examples
test: add tests for proxy use case
chore: update .commons submodule pointer
```
