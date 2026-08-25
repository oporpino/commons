---
name: skill:pr
description: Use this skill when the user asks to create a pull request, open a PR, or submit changes for review.
version: 1.0.0
---

# PR Skill

> **TLDR**: Create a PR from current branch to `main` (or a specified branch), filling the project's PR template.

## Default behavior

- Target branch: `main`
- Override: user says "pr to `staging`" or "pr para `branch-name`" → use that branch

## Steps

1. **Check for PR template**
   - If `.github/PULL_REQUEST_TEMPLATE.md` exists → use it
   - If not → copy `.commons/ai/templates/PULL_REQUEST_TEMPLATE.md` to `.github/PULL_REQUEST_TEMPLATE.md`, then use it

2. **Analyze the diff**
   ```bash
   git log <base>...HEAD --oneline
   git diff <base>...HEAD --stat
   ```

3. **Fill the template sections**
   - **TLDR**: 1-2 lines summarizing what changed
   - **CONTEXT**: why this change was needed
   - **CHANGES**: bullet list of files/areas modified
   - **HOW TO TEST**: concrete steps to validate

4. **Create the PR**
   ```bash
   gh pr create --base <base> --title "<title>" --body "<filled template>"
   ```

## Rules

- Title: max 70 chars, no AI mentions
- Keep CHANGES objective — list modified files and what changed
- HOW TO TEST must be actionable steps, not vague descriptions
- Never include Co-Authored-By or AI references in the PR body
