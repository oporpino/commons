---
name: br4zz4:commit
description: Use when the user asks to commit changes.
version: 1.0.0
---

# commons:commit

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
3. For every untracked file, evaluate whether it should be committed or ignored — follow the **Untracked files flow** below
4. Analyze the diff and identify groups of changes by logical context
5. If there are multiple contexts, create separate commits with selective staging
6. Stage the files for the context → commit with a message within the rules
7. Never use `git add .` or `git add -A` without checking what is being included

## Untracked files flow

For each untracked file or directory in `git status`:

1. Classify it:
   - **Commit**: source code, config files, lock files (`.lock`, `.lock.hcl`), scripts, manifests, encrypted secrets (`.enc.yml`)
   - **Ignore**: local state, build artifacts, binaries, downloaded dependencies, generated files, credentials (e.g. `.terraform/`, `node_modules/`, `*.pyc`, `dist/`, `*.key`)
   - **Unsure**: anything that doesn't clearly fit either category
2. For files classified as **Ignore**: add to the nearest relevant `.gitignore` before committing
3. For files classified as **Unsure**: ask the user before proceeding — do not assume

## .commons flow

`.commons` is a symlink — there is no submodule pointer to update.

If changes are needed in `.commons`:

1. `cd` into `.commons`
2. `git pull origin main`
3. If there are local changes: commit them following the same rules
4. `git push origin main`
5. Go back to the root project — no pointer commit needed

## Amend vs new commit

Use `git commit --amend` instead of a new commit when:
- Correcting or reversing something done in the **immediately preceding commit**
- The fix is part of the same logical change — not a new intent
- The branch is feature/non-main (safe to rewrite)

Never amend if the commit has already been pulled by others or is on `main`/`master`.

If the amended commit was already pushed, a force push is required — **always ask the user before running any force push**. Use `--force-with-lease` instead of `--force`.

## After pushing

Only check GitHub Actions after pushing to a branch that updates an open pull
request or after pushing to `main`.

Do not check runs for local-only commits or branches that are not attached to a
pull request.

When the push updates a pull request or `main`, run:

```bash
gh run list --limit=3 --json databaseId,workflowName,status,conclusion,url
```

Report the latest run status to the user. If a run is `in_progress` or `queued`,
watch it:

```bash
gh run watch <run-id>
```

## Valid examples

```
feat: add support for multiple mirrors
fix: fix duplicate package check
refactor: extract privilege logic to helper
docs: update installation examples
test: add tests for proxy use case
chore: update .commons submodule pointer
```
