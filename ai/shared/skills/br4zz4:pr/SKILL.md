---
name: pr
description: Use when creating a pull request.
version: 1.1.0
---

# commons:pr

> **TLDR**: Create a PR from current branch to `main` (or a specified branch), filling the project's PR template.

## Default behavior

- Target branch: `main`
- Override: user says "pr to `staging`" or "pr para `branch-name`" → use that branch

## Steps

0. **Update documentation first**
   Apply `commons:docs` before opening any PR:
   - If the change introduces or modifies a business rule: update the rule file and `RULES.md`
   - If the change reveals a learning: create a learning file in `.project/docs/learnings/`
   - If nothing to document: confirm "No documentation changes needed" and proceed
   Commit any doc changes before opening the PR.

1. **Check for PR template**
   - If `.github/PULL_REQUEST_TEMPLATE.md` exists → use it
   - If not → copy `.commons/ai/templates/PULL_REQUEST_TEMPLATE.md` to `.github/PULL_REQUEST_TEMPLATE.md`, then use it

2. **Analyze the diff**
   ```bash
   git log <base>...HEAD --oneline
   git diff <base>...HEAD --stat
   ```

   **Count only code files** — exclude documentation and specs from the count:
   - Exclude: `*.md`, `*.txt`, `.project/docs/**`, `ai/shared/rules/**`, `ai/shared/skills/**`
   - Count everything else as a code file.

   **Check file count before proceeding:**
   - If ≤ 5 code files → proceed normally.
   - If 6–10 code files → explain the rule ("PRs devem ter no máximo 5 arquivos de código, idealmente menos"), show the list of files, and ask: "Quer abrir em um PR só ou dividir em dois?"
     - If one PR → proceed, note the exception in the TLDR.
     - If two PRs → propose the split by **well-defined context** (not random grouping). Two PRs may touch the same file as long as each PR remains consistent and atomic. Present the proposed split and wait for confirmation before opening any PR.
   - If > 10 code files and it is a rename/move refactor → proceed, note it in the TLDR.
   - If > 10 code files and it is not a rename refactor → stop. Tell the user the hard limit was exceeded and propose a split into sequential PRs grouped by well-defined context. Wait for confirmation before opening any PR.

3. **Fill the template sections**
   - **TLDR**: 1-2 lines summarizing what changed
   - **CONTEXT**: why this change was needed
   - **CHANGES**: bullet list of files/areas modified
   - **HOW TO TEST**: concrete steps to validate
   - **RELATED**: Asana task links (see below)

4. **Create the PR**
   ```bash
   gh pr create --base <base> --title "<title>" --body "<filled template>"
   ```

## Asana task link

Every PR must be linked to an Asana task. After creating the PR:

1. Apply `skill:asana` to create or update the subtask under the parent task
2. If the parent task GID is not known, ask: "Qual o ID ou link da task pai no Asana?"
3. Set the subtask name to match the PR title
4. Fill the description following the format in `skill:asana`
5. Include the PR URL in `[ detalhamento ]`

## Related section

Every PR body must end with a `## Related` section linking to the Asana tasks:

```markdown
## Related

- story/task: [<parent task name>](<parent task url>)
  - subtask: [<subtask name>](<subtask url>)
```

- Use `story` or `task` as the label depending on what the parent is
- The subtask is the Asana task that directly corresponds to this PR
- If there is no parent task (standalone), just list the task without nesting

## PR sequence

When a change spans multiple dependent PRs that must merge in a fixed order, add
a `## SEQUENCE` section (uppercase) **immediately after the TLDR** (or after the
first summary block if the template has no TLDR) — not at the top, not at the
bottom.

Format: a numbered list of the PRs in merge order using bare `#<n>` references
(GitHub auto-expands each into a link with the PR title). Mark the current PR with
`(este)`. Below the list, a single line `Merge in this order: #<n1> #<n2> #<n3>`
with bare references too.

```markdown
> TLDR: ...

## SEQUENCE

1. #<n1>
2. #<n2> (este)
3. #<n3>

Merge in this order: #<n1> #<n2> #<n3>
```

- Same-repo PRs only — bare `#<n>` auto-links within the repo. For cross-repo,
  use the full `owner/repo#<n>` reference instead.
- Keep the same list on every PR in the group; only `(este)` moves per PR.

## After PR is open

After opening the PR, always ask:

> "PR aberto. Quer chamar `commons:finish` para decidir o próximo passo (merge local, manter branch, ou revisar)?"

## Rules

- Title: max 70 chars, no AI mentions
- Keep CHANGES objective — list modified files and what changed
- HOW TO TEST must be actionable steps, not vague descriptions
- Never include Co-Authored-By or AI references in the PR body
- Never open a PR without a linked Asana subtask
- Always include a `## Related` section with Asana links
- **File count excludes docs** — `*.md`, `.project/docs/**`, `ai/shared/rules/**`, `ai/shared/skills/**` do not count toward the limit
- **Target: max 5 code files per PR** — above 5 is already too much; explain the rule and ask
- **Hard limit: 10 code files** — never exceed; propose a split by well-defined context
- When splitting, two PRs may touch the same file — what matters is that each PR is consistent and atomic, not that files are exclusive
- Prefer sequential, focused PRs over one large PR
