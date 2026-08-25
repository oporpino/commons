---
name: br4zz4:check
description: Use when asked to review or check code against project rules.
version: 1.0.0
---

# commons:check

Review code against the project's rules and standards.

## Input

Invoke this skill optionally followed by a file path, branch name, or GitHub PR URL:

- No argument → review the current diff (staged + unstaged)
- `path/to/file` → review a specific file
- `feature/branch-name` → fetch the branch and review its diff against main
- `https://github.com/.../pull/123` → fetch the PR branch, check it out, and review its diff against main

## 1. Determine scope

Check the argument passed:

- **No argument**: run `git diff HEAD` and `git diff --cached` — review all current changes
- **File path** (argument contains `/` or `.` but not `github.com`): read the file directly
- **GitHub PR URL** (argument contains `github.com` and `/pull/`): extract the repo and PR number, then:
  1. Run `gh pr view <number> --repo <owner>/<repo> --json headRefName` to get the branch name
  2. Run `git fetch origin <branch>`
  3. Run `git checkout <branch>` to check out the PR branch locally
  4. Run `git diff main...HEAD` to get the diff for review
- **Branch name**: run `git fetch origin <branch>` then `git checkout <branch>`, then `git diff main...HEAD` to get the diff

## 2. Load project rules

Always load shared rules:

- `@../rules/shared/main.md`
- `@../rules/shared/testing.md`
- `@../rules/shared/seeds.md`

Then detect which language-specific rules apply by looking at file extensions in the diff or file path, and load the matching rule files:

- `.ex`, `.exs` → `@../rules/elixir/development.md` + `@../rules/elixir/testing.md`
- `.py` → `@../rules/django/main.md` + `@../rules/django/testing.md`
- `.rb` → `@../rules/ruby/main.md`
- `.tsx`, `.ts`, `.jsx`, `.js` → `@../rules/react/main.md` + `@../rules/react/testing.md`
- `.tf` → `@../rules/terraform/main.md`
- `compose.yml`, `compose.*.yml`, `docker-compose.yml` → `@../skills/docker/SKILL.md`

If no matching rules exist, apply only the shared rules and use general best practices.

## 3. Review

Evaluate each changed file against the loaded rules. Focus on:

- Code quality and size limits
- Style and naming conventions
- Architecture and layer boundaries
- Documentation requirements
- Test structure (if test files are in scope)
- Seeds and fixtures: if the diff introduces or changes models/entities, verify factories and seeds exist and are idempotent
- Docker compose: if `compose.yml` or any compose file is in scope, apply `@../skills/docker/SKILL.md` — verify the project uses the include pattern from `.commons/docker/compose/` and does not duplicate shared service definitions

## 4. Report

Group findings by file. For each issue:

- State the rule violated
- Quote the offending code
- Suggest the fix

End with a summary: **X issues found** across Y files, grouped by severity (blocking / warning).

Only report actual violations — do not praise compliant code.
