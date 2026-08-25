---
name: feature
description: Use when creating or updating user stories and Gherkin acceptance criteria in .project/docs/features/.
version: 2.0.0
---

# commons:feature

> **TLDR**: Create or update a user story file in `.project/docs/features/` with user stories in standard format and acceptance criteria in Gherkin notation.

This skill is independent of `commons:spec` but consistency is required — always review existing specs and features before writing to avoid duplication or contradiction.

---

## When to use

- Documenting a new product feature before or during implementation
- Adding Gherkin scenarios to an existing feature file
- Updating a feature file to reflect implementation decisions made during a spec or plan

---

## Phase 1 — Read existing documentation

Before writing anything:

1. Read `.project/docs/README.md` — the single index — for the current feature set and numbering
2. Read any feature files referenced by or related to the current topic
3. Read related specs in `.project/docs/specs/` for technical decisions that constrain the behavior
4. Read `.project/docs/rules/<scope>/` for business rules that must be reflected in the Gherkin

---

## Phase 2 — Determine the feature ID

- If updating an existing feature: use its current `USER-NNN` ID
- If creating a new feature: use the next available number

`USER-NNN` is sequential **per project**. Derive the next number from the files themselves,
never from a local index:

```bash
ls .project/docs/features/USER-*.md 2>/dev/null | sed 's/.*USER-0*\([0-9]*\)-.*/\1/' | sort -n | tail -1
```

**Never create `features/INDEX.md`.** The index is single and lives in
`.project/docs/README.md` — see `commons:docs`. A per-category index creates sources that
diverge, and the uppercase name violates the naming rule.

---

## Phase 3 — Write the feature file

### File location

```
<project-root>/.project/docs/features/USER-NNN-short_name.md
```

- `short_name` = **`snake_case`**, max 5 words, in **English** — like every filename under `.project/docs/`
- Never overwrite an existing feature — update it in place
- Create `.project/docs/features/` if it does not exist

### Feature file format

Filename and frontmatter keys in English; **title, body, headings and Gherkin in Portuguese** —
this is the `commons:docs` language rule and it applies here. Technical terms and code
identifiers are never translated.

```markdown
---
id: USER-NNN
title: <título em português>
scope: <domínio>
created: YYYY-MM-DD
updated: YYYY-MM-DD
certainty: high | medium | low
---

# USER-NNN — <Título>

> **TLDR**: uma frase — o que a feature entrega e para quem.

> **Fase:** F#  ·  **Tipo:** BE | FE | INT | FULL
> **Depende de:** USER-XXX, USER-YYY  ·  **Habilita:** USER-ZZZ
> **Telas / rotas:** <páginas ou rotas afetadas, se aplicável>

## Contexto

Por que esta feature existe? Que problema ela resolve para o usuário?

## História

Como <persona>, quero <ação>, para <benefício>.

## Critérios de aceite

```gherkin
# language: pt
Funcionalidade: <nome da funcionalidade>

  Contexto:
    Dado <pré-condição comum a todos os cenários>

  Cenário: <título do happy path>
    Dado <pré-condição específica>
    Quando <ação>
    Então <resultado esperado>
    E <expectativa adicional>

  Cenário: <título do caso de erro ou borda>
    Dado <pré-condição>
    Quando <ação>
    Então <resultado esperado>
```

`certainty` is mandatory, same as every other category. Use `low` when the feature text and
the code contradict each other — that is a product call, not yours.

**The template above is a minimum, not a straitjacket.** When the real feature carries a data
model, endpoints and RBAC, keep those sections — just add the frontmatter, the TLDR, the
`## História` and real Gherkin on top. Do not delete domain content to fit the template.

## State machine (if applicable)

| From | Event | To | Guard |
|------|-------|----|-------|
| STATE_A | event_x | STATE_B | condition |

## Non-goals

What this feature explicitly does NOT handle.

## Dependencies & references

- Spec: `.project/docs/specs/<filename>.md`
- Blueprint / product doc: §N
- Related features: USER-XXX
```

### Types

| Type | Meaning |
|------|---------|
| `BE` | Back-end only |
| `FE` | Front-end only |
| `INT` | Integration (FE ↔ BE) |
| `FULL` | Full-stack, single deliverable |

---

## Phase 4 — Update the index

After writing or updating the feature file, add or update its line in
`.project/docs/README.md`, in the `features/` table:

```markdown
| ID | Tipo | Feature | Status | Arquivo |
|---|---|---|---|---|
| USER-001 | BE | Fundação do serviço backend | done | [USER-001-…](features/USER-001-backend_service_foundation.md) |
```

Status values: `proposed` · `in_progress` · `done`

If the project needs to record **phasing and dependencies between features** — the order in
which they fit and why — that belongs in `.project/docs/features/roadmap.md`, which is a
document in its own right, not an index: phase table, dependency graph, locked architectural
decisions, domain glossary. Create it only when there is real content for it; the per-feature
index stays in `.project/docs/README.md` either way.

---

## Phase 5 — Commit

```bash
git add .project/docs/features/USER-NNN-*.md .project/docs/README.md
git commit -m "docs: feature USER-NNN <short description>"
```

Commit message: one line, ≤60 chars, no AI mention.

---

## Gherkin rules

- Use **Portuguese** in Gherkin keywords and step text, with `# language: pt` on the first line
- One scenario per behavior — do not combine independent behaviors
- `Background` only for steps shared by ALL scenarios in the feature
- Avoid implementation details in steps — describe behavior, not code
- Each `Then` asserts one observable outcome
- Use `Scenario Outline` + `Examples` for data-driven scenarios
- State machine tables are required whenever the feature has status transitions

---

## Consistency check (always run before committing)

- [ ] User stories use the format "Como `<persona>`, quero `<ação>`, para `<benefício>`"
- [ ] Filename is `USER-NNN-short_name.md` in `snake_case`, not kebab-case
- [ ] Frontmatter carries `certainty`
- [ ] Every acceptance criterion has at least one Gherkin scenario
- [ ] Gherkin scenarios match the business rules in `.project/docs/rules/<scope>/`
- [ ] Feature ID is unique and indexed in `.project/docs/README.md`
- [ ] No `features/INDEX.md` was created
- [ ] Dependencies list reflects the actual `USER-NNN` IDs that must exist first
