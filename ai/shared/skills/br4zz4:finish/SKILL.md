---
name: br4zz4:finish
description: Use when implementation is complete and you need to decide how to integrate the work.
version: 1.0.0
---

# commons:finish

> **TLDR**: Verify tests → present integration options → execute the chosen one. No merge without green tests.

---

## When to use

- Implementation is complete, all tasks done
- About to integrate work back into main or hand it off via PR

---

## Step 1 — Verify tests

Run the full test suite:

```bash
<test command>
```

If tests fail:

> "Tests failing (`N` failures). Must fix before finishing:
>
> `[show failures]`
>
> Cannot proceed until tests pass."

Stop. Fix the failures, then restart from Step 1.

If tests pass: continue to Step 2.

---

## Step 2 — Update docs before opening PR

Apply `commons:docs` to ensure documentation is consistent with the code:

- If the change introduces or modifies a business rule: create or update the rule file in `.project/docs/rules/<scope>/` and update `.project/docs/RULES.md`
- If the change reveals a learning: create a learning file in `.project/docs/learnings/`
- If nothing to document: confirm "No documentation changes needed" and move on

Commit any doc changes:

```bash
git add .project/docs/
git commit -m "docs: update <topic> documentation"
```

---

## Step 3 — Present options

Ask the user:

> "Implementação completa e testes passando. O que você quer fazer?
>
> 1. Abrir PR (push + `commons:pr`)
> 2. Merge local direto em `main`
> 3. Manter a branch como está por enquanto
> 4. Descartar este trabalho"

Wait for the answer. Do not proceed until the user chooses.

---

## Step 4 — Execute the choice

### Option 1: Open PR

Push the branch and invoke `commons:pr`:

```bash
git push -u origin <branch>
```

Then apply `commons:pr` to create the pull request. After the PR is opened, ask:

> "PR aberto. Quer que eu chame `commons:review-request` para disparar uma revisão de código?"

### Option 2: Merge locally

```bash
git checkout main
git pull --rebase origin main
git merge <branch>
```

Run tests on the merged result:

```bash
<test command>
```

If green: delete the branch.

```bash
git branch -d <branch>
```

If tests fail after merge: investigate before pushing.

### Option 3: Keep as-is

> "Branch `<name>` mantida. Retome quando quiser."

Nothing else to do.

### Option 4: Discard

Confirm first:

> "Isso vai deletar permanentemente:
> - Branch `<name>`
> - Commits: `[list]`
>
> Digite 'descartar' para confirmar."

Wait for exact confirmation. Then:

```bash
git checkout main
git branch -D <branch>
```

---

## Step 5 — Clean up worktrees

If the work ran in parallel via `commons:subagent`, there may be worktrees under `$HOME/workspace/.worktrees/<project>/`. Remove them **only when the work is integrated** (merged / PR pushed) **or the worktree has no uncommitted changes**:

```bash
PROJECT=$(basename "$(git rev-parse --show-toplevel)")
WT_ROOT="$HOME/workspace/.worktrees/$PROJECT"

git worktree list | awk -v root="$WT_ROOT" '$1 ~ root {print $1}' | while read -r wt; do
  if [ -z "$(git -C "$wt" status --porcelain)" ]; then
    git worktree remove "$wt"
  else
    echo "Worktree com mudanças não commitadas, mantido: $wt"
  fi
done

git worktree prune
```

After cleanup, `git status` and the `.worktrees/` dir must have no leftovers. Never delete a worktree that still holds uncommitted work — warn and keep it.

---

## Rules

- Never merge with failing tests
- Never force-push without explicit user request
- Never delete work without typed confirmation
- Always run `commons:docs` before opening a PR
- After opening a PR, always offer to call `commons:review-request`
- Remove parallel worktrees from `$HOME/workspace/.worktrees/` only when integrated or clean — never delete uncommitted work
