---
name: change-multi-repo
description: Use when applying structural changes across multiple repos.
version: 1.0.0
---

# commons:change-multi-repo

> **TLDR**: Apply a single structural change consistently across multiple WeHive repos, ensuring CI stays green, no leftovers remain, and everything lands on main before closing.

## When to activate

- User asks to apply a change across multiple repos
- User mentions "align", "standardize", or "structural change" across projects
- User wants to propagate a pattern, config, or convention to multiple repos

## Rule: one change per session

**This skill enforces a strict one-change-per-session rule.**

If the user attempts to introduce a second, unrelated change in the same session:

- Refuse clearly and firmly
- Explain why: mixing changes across multiple repos creates confusion, increases the risk of leftovers, and makes rollback nearly impossible
- Do not proceed, even partially
- Ask the user to start a new session for the second change

There are no exceptions to this rule.

## Phase 1: understand before acting

Before touching any file or repo:

1. Ask the user to describe the change in detail if it's not already clear
2. Ask if there is a **reference repo** already implementing the pattern — use it as the source of truth for the change
3. Map every repo that will be affected — list them explicitly
3. For each repo, describe exactly what will change (files, configs, patterns, commands)
4. Note repos that have a different current pattern — these are higher risk for leftovers
5. Present the full plan to the user and wait for explicit confirmation before proceeding

Do not skip this phase. Do not start coding while mapping is incomplete.

## Phase 2: apply the change

Apply the change repo by repo, in sequence (not in parallel):

- Use the same branch name across all repos if branching is needed
- In each repo:
  1. Pull `main` first: `git pull --rebase origin main`
  2. Create the branch from the updated main (if applicable)
  3. Apply the change
  3. Remove any old patterns, configs, or files that are no longer valid — especially in repos that had a different convention before
  4. Commit (follow commit rules: one line, 60 chars, no AI mention)
  5. Verify CI is passing before moving to the next repo (see CI rule below)
  6. Open PR and wait for merge (or flag to user if manual review is needed)

## Rule: CI must stay green

- After each repo's changes are applied, check if CI is passing
- If CI is broken — even if it was already broken before — **fix it before moving to the next repo**
- Never leave a repo with broken CI and move on
- If the breakage is unrelated and complex, flag it to the user with a clear explanation, but still do not proceed until resolved

## Rule: no leftovers

Before marking a repo as done, verify:

- Old config files, patterns, or scripts that were replaced are deleted
- No half-migrated state (e.g., both old and new pattern coexisting)
- Repos that had a different convention before are fully aligned with the new one
- No temporary files, commented-out blocks, or migration notes left behind

This is especially important for repos that had a divergent pattern before the change.

## Phase 3: close properly

The change is only considered **done** when all of the following are true:

1. Every affected repo has the change merged into `main`
2. Every local repo checkout is on `main` (not on a feature branch)
3. CI is green in all repos
4. No leftovers remain in any repo

Do not declare the task complete until all conditions above are met. If something is pending (e.g., a PR waiting for review), state it explicitly and do not close the session silently.

## Branch naming

If branches are used:

- Use the **exact same branch name** in every repo
- Suggested format: `feature/<short-description>` or `refactor/<short-description>`
- Never use different branch names across repos for the same change

## Checklist (use at the end of each repo)

- [ ] Change applied correctly
- [ ] Old patterns/files removed
- [ ] CI passing
- [ ] PR opened (or committed directly if no PR needed)
- [ ] PR merged into main
- [ ] Local checkout is on main

## Checklist (use at the end of the full session)

- [ ] All repos are done
- [ ] All local checkouts are on main
- [ ] CI is green everywhere
- [ ] No leftovers in any repo
- [ ] One single logical change was applied — nothing else
