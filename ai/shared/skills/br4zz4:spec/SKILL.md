---
name: br4zz4:spec
description: Use when the user asks to plan or document a change.
version: 2.1.0
---

# commons:spec

> **TLDR**: Understand the problem through dialogue, propose approaches, write the spec, get approval, then hand off to `commons:plan`.

## Model suggestion — start

Before Phase 1, **check the current model first**. If already on Opus, skip this entirely — don't ask. Only if on a lighter model, suggest switching, presenting the exact command as a copyable block so it's one paste away:

> "Spec e brainstorm rendem mais no Opus. Rode:
> ```
> /model opus
> ```
> antes de começarmos."

Suggest once; don't insist. Continue regardless of the choice.

---

## The Iron Gate

**NEVER write a spec, code, scaffold, or take any implementation action until you have completed the dialogue and the user has approved the spec.**

---

## Checklist (complete in order)

1. **Explore context** — read existing docs, recent commits, project structure
2. **Infer Asana task** — search for related task, ask if found, offer to create if not
3. **Dialogue** — one question at a time until the problem is fully understood
4. **Propose 2–3 approaches** — with trade-offs and your recommendation
5. **Write spec** — save to `.project/docs/specs/`, commit
6. **Self-review** — scan for gaps, contradictions, ambiguity; fix inline
7. **User approval gate** — wait for explicit approval before handing off
8. **Hand off** — invoke `commons:plan` to create the implementation plan

---

## Phase 1 — Explore context

Before asking anything, read:

- `.project/docs/` — business rules, learnings, architecture of the current project
- `.project/docs/features/` — existing user stories and Gherkin criteria (if they exist)
- `.commons/.project/docs/` — cross-project guides, architecture and reference
- `.project/docs/specs/` — existing specs so you don't duplicate decisions
- Recent git log: `git log --oneline -10`

For multi-module projects, read `.project/docs/modules.md` to understand boundaries before scoping.

---

## Phase 2 — Infer Asana context

Derive the product from the working directory (e.g. `onion-backend` → `onion`). Search for a related task using `asana_search_tasks`.

- Found a relevant task → show it, ask: "Encontrei essa task — quer usar ela ou criar uma nova?"
- Nothing found → ask: "Não encontrei task relacionada — quer que eu crie uma?"

Only create a task if the user confirms. Never ask for a task ID.

---

## Phase 3 — Dialogue

Ask one question at a time. Wait for the answer before asking the next.

Sequence:
1. "What problem are you solving or what do you want to change?" (overview)
2. "Which files or areas are involved?" — skip if already clear
3. Per part of the change: "What is part 1?" → "What is part 2?" → until the user says there are no more
4. "How do we verify this works?" — or infer it if obvious

During the dialogue, the user may raise doubts or explore trade-offs — engage, help them decide, incorporate conclusions into the spec. You are co-authoring, not just collecting answers.

**Scope check:** if the request describes multiple independent subsystems, flag it immediately. Don't spend questions refining an over-scoped problem — help the user decompose first, then brainstorm the first part.

---

## Phase 4 — Propose approaches

Present 2–3 distinct approaches with trade-offs. Lead with your recommendation and explain why.

Example structure:
- **Option A (recommended):** ...reason... trade-off: ...
- **Option B:** ...reason... trade-off: ...
- **Option C:** ...reason... trade-off: ...

Ask which to proceed with before writing the spec.

### Optional: visual companion

Some decisions are understood better seen than read. When a question is genuinely visual — UI layout/wireframe, architecture diagram, side-by-side comparison of two directions, spatial/flow relationships — offer the browser companion instead of describing options in text. Skip it for conceptual, requirements, or tradeoff questions: those stay in the terminal.

**When to reach for it:** "which of these layouts feels right?" is visual. "What kind of screen do you want?" is conceptual — stay in the terminal. Decide per question, not per session, and always offer it — never force it.

**Start the server** (after the user agrees):

```bash
.commons/shell/tasks/visual/start-server.sh --project-dir "$HOME/workspace/.worktrees" --open
```

It returns JSON with `url`, `port`, `screen_dir`, and `state_dir`. Save `screen_dir` and `state_dir`. Give the user the **complete** `url` (it carries a session key — never strip the query string). Point `--project-dir` at a path outside any repo (e.g. `$HOME/workspace/.worktrees`) so mockups never pollute the project — the server writes under `<project-dir>/.br4zz4-visual/`.

**The loop:**

1. Write an HTML **content fragment** to a fresh file in `screen_dir` (semantic name: `layout.html`, `visual-style.html`). Never reuse a filename; the server serves the newest file and wraps your fragment in the frame template. Use your file tool — never `cat`/heredoc.
2. Tell the user what's on screen in one line, remind them of the URL, and ask them to look and respond in the terminal (clicking to select is optional). End your turn.
3. Next turn: read `$STATE_DIR/events` (JSONL of their clicks) if it exists, and merge it with their terminal reply. The terminal text is primary; events add structure.
4. Iterate (`layout-v2.html`) until the choice is validated; only then move on.
5. When the next question is not visual, push a `waiting.html` fragment ("Continuing in terminal…") so a resolved choice isn't left on screen.

**Fragment shape** — write just the inner content; the frame provides CSS and interactivity:

```html
<h2>Which layout works better?</h2>
<p class="subtitle">Consider readability and hierarchy</p>
<div class="options">
  <div class="option" data-choice="a" onclick="toggleSelect(this)">
    <div class="letter">A</div>
    <div class="content"><h3>Single column</h3><p>Focused reading</p></div>
  </div>
  <div class="option" data-choice="b" onclick="toggleSelect(this)">
    <div class="letter">B</div>
    <div class="content"><h3>Two column</h3><p>Sidebar + content</p></div>
  </div>
</div>
```

Available classes: `.options` (add `data-multiselect` for multi), `.cards`, `.mockup` / `.mockup-header` / `.mockup-body`, `.split` (side-by-side), `.pros-cons`, wireframe blocks (`.mock-nav`, `.mock-sidebar`, `.mock-content`, `.mock-button`, `.mock-input`, `.placeholder`), and typography (`h2`, `h3`, `.subtitle`, `.section`, `.label`). Keep mockups simple; 2–4 options per screen; explain the question on every page.

**Stop the server** when the visual part is done:

```bash
.commons/shell/tasks/visual/stop-server.sh "$SESSION_DIR"
```

---

## Phase 5 — Write the spec

### File location

Always inside the **primary project root** (never in `.commons`):

```
<project-root>/.project/docs/specs/YYYYMMDDHHMMSS_short_description.md
```

- `YYYYMMDDHHMMSS` = current timestamp
- `short_description` = English, snake_case, max 5 words
- Create `.project/docs/specs/` and `.project/docs/specs/drafts/` if they don't exist
- Always **create a new file** — never overwrite a previous spec

### File format

Filename and frontmatter keys in English; **title, body and headings in Portuguese** — this
is the `commons:docs` language rule and it applies to every doc under `.project/docs/`.
Technical terms and code identifiers are never translated.

```markdown
---
title: <título em português>
status: proposed
created: YYYY-MM-DD
updated: YYYY-MM-DD
owner: "@<resolvido via `gh api user --jq '.login'`>"
certainty: high
---

# <Título>

> **TLDR**: uma frase — o que muda e por quê.

## Contexto

Por que esta mudança? Que problema ela resolve?

## Objetivos

- Objetivo 1
- Objetivo 2

## Fora de escopo

- O que esta mudança explicitamente NÃO faz.

## Mudanças

Arquivos a criar ou modificar e o que muda em cada um.

## Como verificar

Como confirmar que a mudança funciona ponta a ponta.

## Documentação

Arquivos a criar ou atualizar em `.project/docs/`, `ai/shared/rules/` ou `ai/shared/skills/`.
Se nenhum: "Nenhuma mudança de documentação necessária."
```

`certainty: high` for a spec written now — the content comes from the dialogue with the user,
not from reconstruction. Use `medium` or `low` only when you inferred something from code that
the user did not state.

`status` values: `proposed` · `in_progress` · `done` · `superseded`. Never write `superseded`
without confirming the successor was actually implemented.

### Commit the spec

```bash
git add .project/docs/specs/<filename>.md
git commit -m "docs: spec <short_description>"
```

---

## Phase 6 — Self-review

After writing, read the spec with fresh eyes:

1. **Placeholder scan:** any "TBD", "TODO", vague requirements? Fix them.
2. **Consistency:** do any sections contradict each other?
3. **Scope:** is this focused enough for one plan, or does it need decomposition?
4. **Ambiguity:** can any requirement be interpreted two ways? Pick one and make it explicit.

Fix issues inline. No need to re-review — just fix and move on.

---

## Phase 7 — User approval gate

Show the user where the spec was saved, then:

> "Spec commitada em `.project/docs/specs/<filename>.md`. Revise e me diz se quer alguma mudança antes de criar o plano de implementação."

Wait for explicit approval. If changes requested, update the spec, re-commit, run self-review again.

---

## Phase 8 — Optional: create or update the feature file

If the change corresponds to a product feature (user-visible behavior), ask:

> "Quer criar ou atualizar o arquivo de feature em `.project/docs/features/` com as user stories e critérios de aceite em Gherkin? Isso é separado da spec técnica e fica no histórico de produto."

If yes, invoke `commons:feature` before handing off to `commons:plan`.

---

## Phase 9 — Hand off

After approval (and optional feature file), invoke `commons:plan` to create the implementation plan. `commons:plan` handles the model suggestion for the implementation phase — do NOT suggest `/model sonnet` here when you're about to hand off, or the user gets it twice.

**Only if the flow ends at the spec** (the user does not want a plan now, or asked to stop here) *and* you're still on Opus do you suggest switching to the lighter model. If already on Sonnet, skip it. Present the exact command as a copyable block:

> "Spec aprovada. Se for implementar direto (sem plano), a parte de código roda bem no Sonnet:
> ```
> /model sonnet
> ```"

Suggest once; don't insist.

Do NOT write any code. Do NOT create branches. When handing off, `commons:plan` handles everything from here.

---

## Draft specs

Specs approved but not yet started go in `.project/docs/specs/drafts/`:
- Status: `draft`
- Move to `.project/docs/specs/` and change status to `in_progress` when implementation begins
- Never implement from a draft without moving it first

---

## Rules

- One question at a time during dialogue
- YAGNI: remove unnecessary scope from all specs
- Docker: before scoping any service change, apply `@../../skills/docker/SKILL.md`
- Seeds: if the change introduces or changes models, apply `@../../skills/seed/SKILL.md`
- Ports: follow `@rules/shared/ports.md` when defining ports
- Infra: if the change touches infrastructure (k8s, ingress, DNS, terraform, `.infra/`), apply `@../../skills/infra/SKILL.md`. Infra is **self-declared in the project's own `.infra/`** — the `infrastructure` repo owns ONLY base/shared resources, never app manifests, DNS, or secrets. Scope infra changes to the project's `.infra/` (`.infra/k8s/`, `.infra/terraform/`), never to the `infrastructure` repo
- If the change targets GitHub Actions, reusable workflows live in `ibft-corp/pipelines`, not commons
