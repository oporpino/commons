---
name: br4zz4:plan
description: Use when the user asks to plan something, or after commons:spec approval to create an implementation plan.
version: 2.1.0
---

# commons:plan

> **TLDR**: Given an approved spec, create a detailed TDD implementation plan in `.project/docs/plans/`, then offer execution options.

## Prerequisites

This skill expects an approved spec in `.project/docs/specs/`. If no spec exists yet, invoke `commons:spec` first.

---

## Phase 0 — Pre-flight check

Before reading the spec or writing anything, run `make check` (lint/test/audit) **in the background**, in parallel with reading the spec. This surfaces pre-existing failures so you know the baseline before you start.

```bash
make check &
```

If `make check` does not exist, run whatever the project uses (e.g. `make lint && make test`). Report failures immediately — do not proceed past Phase 1 if baseline is broken unless the user explicitly says to continue anyway.

---

## Checklist (complete in order)

0. **Pre-flight check** — run `make check` in parallel while reading the spec
1. **Read the spec** — fully, before writing anything
2. **Map files** — which files are created or modified, one responsibility each
3. **Scope check** — if the spec spans multiple independent subsystems, propose splitting into separate plans
4. **Write the plan** — with bite-sized TDD tasks, full code, exact commands
5. **Self-review** — spec coverage, placeholder scan, type consistency
6. **Save and commit** the plan file
7. **Branch** — `git checkout -b <type>/<description>` (a branch de trabalho; worktrees de subagents paralelos partem dela)
8. **Offer execution** — subagent-driven em paralelo (preferido) ou inline com `commons:tdd`

---

## Phase 1 — Read the spec

Read the spec file in full. Note:
- Objectives and non-goals
- Files listed in Changes
- Verification criteria
- Documentation requirements

Do not write a single task until you understand every section.

---

## Phase 2 — Map files

Before defining tasks, map which files will be created or modified and what each one does.

- Each file should have one clear responsibility
- Files that change together should live together
- Prefer smaller, focused files over large multi-concern ones
- In existing codebases, follow established patterns — do not unilaterally restructure
- If a file you are modifying has grown unwieldy, including a split in the plan is reasonable

This map informs task decomposition. Each task should produce self-contained changes.

---

## Phase 3 — Scope check

If the spec covers multiple independent subsystems: propose splitting into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

---

## Phase 4 — Write the plan

### File location

```
<project-root>/.project/docs/plans/YYYYMMDDHHMMSS_short_description.md
```

- Create `.project/docs/plans/` if it does not exist
- Always create a new file — never overwrite a previous plan

### Plan header (mandatory)

Filename and frontmatter keys in English; **title, body and headings in Portuguese** — the
`commons:docs` language rule applies to every doc under `.project/docs/`.

```markdown
---
title: <título em português>
spec: specs/<arquivo-da-spec>.md
created: YYYY-MM-DD
updated: YYYY-MM-DD
certainty: high
---

# <Título> — Plano de implementação

> **TLDR**: uma frase — o que este plano constrói.

> **Spec:** `.project/docs/specs/<spec-filename>.md`
> **Branch:** `<type>/<short-description>`

**Arquitetura:** 2–3 frases sobre a abordagem.

**Stack:** tecnologias e bibliotecas principais.

## Restrições globais

Uma linha cada — requisitos do projeto vindos da spec (versões mínimas, regras de nome,
requisitos de plataforma).

---
```

`spec:` points at the spec this plan implements, or `null` when there is none.

The `### Task N` structure below is the **expansion** of `## Fases` in the `commons:docs`
plan template — use it, not a flat phase list. When a plan is long enough that the tasks are
already a coherent checklist, keep them; do not compress into two sections just to match the
minimal template.

### Task structure

Each task = one TDD cycle. Right-size: fold setup and scaffolding into the task that needs them; split only where a reviewer could meaningfully reject one task while approving its neighbor.

````markdown
### Task N: <Component Name>

**Files:**
- Create: `exact/path/to/file.ext`
- Modify: `exact/path/to/existing.ext`
- Test: `tests/exact/path/to/test.ext`

**Interfaces:**
- Consumes: [what this task uses from earlier tasks — exact signatures]
- Produces: [what later tasks rely on — exact function names and types]

- [ ] **Step 1: Write the failing test**

```language
// test code here — real behavior, minimal, one thing
```

- [ ] **Step 2: Run to verify it fails**

```bash
<test command> <path>
```

Expected: FAIL — `<expected error message>`

- [ ] **Step 3: Write minimal implementation**

```language
// production code here — just enough to pass
```

- [ ] **Step 4: Run to verify it passes**

```bash
<test command> <path>
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add <files>
git commit -m "<type>: <description>"
```
````

### TDD phase commits

| When | Commit prefix |
|------|---------------|
| All tests written, all RED | `test:` |
| All tests GREEN | `feat:` or `fix:` |
| Refactor complete | `refactor:` |
| Performance (only if measured bottleneck) | `perf:` |

### No placeholders

Never write:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" without showing the code
- "Write tests for the above" without the actual test
- "Similar to Task N" — repeat the code; the implementer may read tasks out of order
- Steps that describe what to do without showing how

Every step must contain the actual content an engineer needs.

---

## Phase 5 — Self-review

After writing the full plan:

1. **Spec coverage:** can you point to a task that implements each spec requirement? List any gaps.
2. **Placeholder scan:** search for "TBD", "TODO", vague steps. Fix them.
3. **Type consistency:** do function names and types in later tasks match what earlier tasks define?

Fix issues inline.

---

## Phase 6 — Save and commit

```bash
git add .project/docs/plans/<filename>.md
git commit -m "docs: plan <short_description>"
```

---

## Phase 7 — Branch and offer execution

Before any code, create the feature branch:

```bash
git pull --rebase origin main
git checkout -b <type>/<short-description>
```

If still on Opus (e.g. the user entered `commons:plan` directly, without coming through `commons:spec`), suggest switching to the lighter model for the mechanical implementation ahead — present the exact command as a copyable block. If already on Sonnet, skip this (don't nag):

> "Plano pronto. A implementação daqui é mais mecânica e roda bem no Sonnet. Antes de seguir, rode:
> ```
> /model sonnet
> ```"

Suggest once; don't insist. Then offer execution:

> "Plano salvo em `.project/docs/plans/<filename>.md`. Duas opções:
>
> **1. Subagent-driven (recomendado)** — despacho um implementador por task + reviewer automático; tasks independentes rodam em paralelo em worktrees para ir mais rápido (`commons:subagent`).
> **2. Inline** — executo as tasks nesta sessão usando `commons:tdd`, com checkpoints entre tasks.
>
> Qual prefere?"

---

## Rules

- Never start on `main` or `master` without explicit user consent
- Prefer decomposing into independent tasks so `commons:subagent` can run them in parallel — split aggressively for speed
- Parallel subagents run in worktrees branched from the work branch, under `$HOME/workspace/.worktrees/<project>/`, removed when integrated
- Commits must follow `commons:commit` rules (one line, max 60 chars, no AI mentions)
- Each task ends with tests green before moving to the next
- **Infra:** if any task touches infrastructure (k8s manifests, ingress, DNS, terraform, `.infra/`), apply `@../../skills/infra/SKILL.md` first. Infra is **self-declared in the project's own `.infra/`** (`.infra/k8s/` for manifests, `.infra/terraform/dns.tf` for app DNS) — the `infrastructure` repo owns ONLY base/shared resources and must never receive app-specific manifests, DNS, or secrets. The only link to shared infra is `terraform_remote_state` outputs.
