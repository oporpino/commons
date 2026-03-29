# Check

Review code against the project's rules and standards.

## Input

Called as `/commons:check` optionally followed by a file path or branch name:

- `/commons:check` → review the current diff (staged + unstaged)
- `/commons:check path/to/file` → review a specific file
- `/commons:check feature/branch-name` → fetch the branch and review its diff against main

## 1. Determine scope

Check the argument passed:

- **No argument**: run `git diff HEAD` and `git diff --cached` — review all current changes
- **File path** (argument contains `/` or `.`): read the file directly
- **Branch name**: run `git fetch origin <branch>` then `git diff main...origin/<branch>` to get the diff

## 2. Load project rules

Always load shared rules:

- `@../rules/shared/main.md`
- `@../rules/shared/testing.md`

Then detect which language-specific rules apply by looking at file extensions in the diff or file path, and load the matching rule files:

- `.sh`, `.bash`, `.zsh` → `@../rules/shell/main.md`
- `.ex`, `.exs` → `@../rules/elixir/development.md` + `@../rules/elixir/testing.md`
- `.py` → `@../rules/django/main.md` + `@../rules/django/testing.md`
- `.rb` → `@../rules/ruby/main.md`
- `.tsx`, `.ts`, `.jsx`, `.js` → `@../rules/react/main.md` + `@../rules/react/testing.md`
- `.tf` → `@../rules/terraform/main.md`

If no matching rules exist, apply only the shared rules and use general best practices.

## 3. Review

Evaluate each changed file against the loaded rules. Focus on:

- Code quality and size limits
- Style and naming conventions
- Architecture and layer boundaries
- Documentation requirements
- Test structure (if test files are in scope)

## 4. Report

Group findings by file. For each issue:

- State the rule violated
- Quote the offending code
- Suggest the fix

End with a summary: **X issues found** across Y files, grouped by severity (blocking / warning).

Only report actual violations — do not praise compliant code.
