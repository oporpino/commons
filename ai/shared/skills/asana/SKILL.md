---
name: asana
description: Use when creating or updating Asana tasks, subtasks, or linking PRs to tasks.
version: 1.0.0
---

# commons:asana

> **TLDR**: Every PR must have a linked Asana subtask. Use this skill to create subtasks, update descriptions, and keep Asana in sync with the work.

## Core rule: 1 PR = 1 task

- Every new branch → every new PR → must have a corresponding Asana subtask
- If you open a PR without knowing the parent task, ask: "Qual o ID ou link da task pai no Asana?"
- Never open a PR without linking it to a task

## Task title format

The title must describe the **problem or symptom**, not the solution. Write it as if you don't know the solution yet — from the perspective of someone who just discovered the issue or need.

- **Bug**: `fix: <description of the broken behavior>` — describes what is failing, not what was changed
- **Feature**: `feat: <user-facing capability being added>` — describes what users gain, not implementation details

Rules:
- Write in past tense for bugs (something broke/happened), present for features (user needs/wants)
- Never mention the solution, the file changed, or the technical approach in the title
- The title is written before the solution is known — it describes the problem, not the fix

Examples:
- Bad: `fix: add 401 interceptor to apiClient` (describes the solution)
- Good: `fix: sessão expirada causa loop infinito de erros no app` (describes the problem)
- Bad: `fix: configurar RDS Proxy para read replica` (describes the solution)
- Good: `fix: app fora do ar por esgotamento de conexões no read replica` (describes the symptom)
- Bad: `feat: add description field to habits model` (describes implementation)
- Good: `feat: terapeuta pode adicionar descrição ao hábito` (describes user value)

## Task description format

All task descriptions must use `html_notes` (rich text) AND `notes` (plain text fallback).

### Bug format

For bugs, `[ o que ]` is a user story of what is broken and `[ por que ]` explains the user impact (not the root cause). Use `[ como ]` for the technical fix.

The `<user>` in `[ o que ]` must match who actually experiences the problem. Each project has its own personas — discover them before writing:

1. **Look for personas in the project**: check `.project/docs/`, `CLAUDE.md`, model names, or app names in the codebase (e.g. `apps/accounts/`, `apps/students/`) to identify the real roles (e.g. `aluno`, `terapeuta`, `assinante`, `coach`)
2. **If unclear**, ask the user: "Quem é o usuário afetado nesse caso?" before writing the story
3. **Fall back** to generic only when no specific persona exists:

| Who feels it | Use |
|---|---|
| Named end-user role (found in project context) | `Como <role>` — e.g. `Como aluno`, `Como terapeuta` |
| Generic end-user (no named role found) | `Como usuário` |
| Engineer/ops (infra anomaly, deploy failure, connection issue) | `Como engenheiro` |
| Admin (backoffice, dashboard issue) | `Como administrador` |

Rules:
- Always prefer the specific persona over `Como usuário` when the project has named roles
- For `Como engenheiro`: describe the problematic behavior, not what you observed. Bad: "vejo gráfico X com padrão Y". Good: "cada request abre e fecha uma conexão, gerando overhead desnecessário"
- Never use `Como usuário` for a problem the end-user cannot see or feel

```html
<body>
<h2><strong>[ o que ]</strong></h2>
Como <user>, quando <action>, <broken behavior happens> — impactando <consequence>.
<h2><strong>[ por que ]</strong></h2>
one or two sentences describing the business/user impact of the bug (not the technical cause).
<h2><strong>[ como ]</strong></h2>
<ul>
  <li>em <file>, <action with specific method/value></li>
  <li>em <file>, <action></li>
</ul>
<h2><strong>[ detalhamento ]</strong></h2>
PR: <a href="<pr_url>"><pr_url></a>
serie: X/N — <context label>
</body>
```

### Feature format

For features, `[ o que ]` is a user story and `[ por que ]` explains the business motivation.

```html
<body>
<h2><strong>[ o que ]</strong></h2>
Como <user>, quero <capability>, para que <benefit>.
<h2><strong>[ por que ]</strong></h2>
one or two sentences explaining the business reason this feature is needed.
<h2><strong>[ como ]</strong></h2>
<ul>
  <li>em <file>, <action with specific method/value></li>
  <li>em <file>, <action></li>
</ul>
<h2><strong>[ detalhamento ]</strong></h2>
PR: <a href="<pr_url>"><pr_url></a>
serie: X/N — <context label>
</body>
```

### notes structure (plain text fallback)

```
[ o que ]

Como <user>, <story>.

[ por que ]

<business impact or motivation — not technical root cause>

[ como ]

    em <file>, <action>
    em <file>, <action>

[ detalhamento ]
PR: <pr_url>
serie: X/N — <context label>
```

### Rules

- Section titles always lowercase: `[ o que ]`, `[ por que ]`, `[ como ]`, `[ detalhamento ]`
- All headings use `<h2><strong>` — never `<h1>` or plain text for section headers
- `[ o que ]` must be a user story (bug or feature) — never a technical description
- `[ por que ]` must describe the business/user impact — never the technical root cause or solution
- `[ como ]` is where technical details live — files changed, methods added, values set
- `[ como ]` uses `<ul><li>` bullet list — each item cites the file and the action
- `[ detalhamento ]` is for useful context that doesn't fit in `[ como ]`: PR link, incident date, serie, related tasks, architectural decisions. If there is nothing meaningful to add, **omit the section entirely** — never leave it with placeholder content like "Task criada em YYYY-MM-DD"
- Always send both `html_notes` and `notes` in the same update call
- Never use attributes on HTML elements other than `<a>` — Asana rejects them
- Allowed HTML elements: `<body>`, `<h1>`, `<h2>`, `<strong>`, `<em>`, `<u>`, `<s>`, `<code>`, `<ol>`, `<ul>`, `<li>`, `<a>`, `<blockquote>`, `<pre>`, `<hr/>`, `<img>`
- **No whitespace between tags** — never put newlines or spaces between `<ul>` and `<li>`, or between `</li>` and `</ul>`. Asana renders whitespace nodes as empty bullet points. Write HTML compact: `<ul><li>item</li></ul>`

## Default project

All tasks must be added to the **Backlog - WeHive** project:

- **Project GID**: `1214395788660507`
- **Workspace GID**: `1208104128529800`

Always pass `projects: ["1214395788660507"]` when creating any task or subtask. Without this, the task will not appear in the backlog and will be invisible to the team.

## Task sections (workflow state)

Tasks move through sections as work progresses. Always set the section when creating or updating a task using `section_id`:

| Section | When to use |
|---|---|
| `todo` | Task created, not yet started |
| `refinement` | Being refined/planned |
| `in_progress` | Implementation started |
| `review` | PR open, awaiting review |
| `testing` | In QA/testing |
| `ready_for_deploy` | Approved, waiting deploy |
| `done` | Deployed and complete |

To set the section on creation: pass `section_id` to `asana_create_task` (requires `project_id` to be set too). Always place new tasks in `todo` unless context says otherwise.

To find section GIDs: call `asana_get_project_sections` with the sprint project GID (not the Backlog GID `1214395788660507` — the sprint project has the workflow sections). The task's `projects` field lists all projects it belongs to; use the non-Backlog one.

**Moving an existing task to a different section is not supported by MCP tools** — `asana_update_task` has no section field. Moving must be done manually in Asana.

Track section transitions as work progresses:
- Task created → `todo`
- Implementation started → `in_progress` *(move manually)*
- PR opened → `review` *(move manually)*
- PR merged → `ready_for_deploy` *(move manually)*
- Deployed → `done` *(move manually)*

## Creating a subtask

When a new PR is opened, create a subtask under the parent task:

1. Ask the user for the parent task ID or URL if not known
2. Resolve the task GID from the URL (last numeric segment) or use it directly
3. Create the subtask with `asana_create_task` using `parent: <parent_gid>` AND `projects: ["1214395788660507"]`
4. Set name to match the PR title (same convention: `<type>: <description>`)
5. Fill description using the format above
6. Update with `html_notes` after creation (creation only supports `notes`)

## Multiple PRs in a series

When a set of related changes produces multiple PRs (e.g. independent fixes for the same initiative):

- **Create PRs in order** — open them sequentially, not all at once
- **Chain bases** — the first PR targets `main`; each subsequent PR targets the previous PR's branch:
  ```
  PR 1: branch-a  → base: main
  PR 2: branch-b  → base: branch-a
  PR 3: branch-c  → base: branch-b
  ...
  ```
- Use `gh pr create --base <previous-branch>` when creating, or `gh pr edit <number> --base <previous-branch>` to fix after the fact
- Include `serie: X/N — <context label>` in `[ detalhamento ]` of each subtask so the sequence is visible in Asana
- Merge in order: merge PR 1 first, then PR 2 automatically retargets to `main`, and so on

## Updating an existing task

Use `asana_update_task` with both `html_notes` and `notes` in the same call.

## Finding custom field GIDs

Custom fields vary per workspace. To populate a custom field:
1. Call `asana_get_task` with `opt_fields=custom_fields` on any task in the same project
2. Find the field by `name` and note its `gid`
3. For enum fields, find the desired option's `gid` from `enum_options`
4. Pass `custom_fields: {"<field_gid>": "<option_gid>"}` to the update call

## PR link field

If a "PR" custom field exists in the project, populate it after creating the PR:
1. Get the field GID using the method above
2. Update the task with the PR URL as the field value
