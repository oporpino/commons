# Plan

Document a planned change in `.project/changes/`, get approval, then implement.

## Flow

1. **Write the change file** with status `proposed`
2. **Ask the user to review** before doing anything — do NOT implement yet
3. **Wait for approval** — only proceed after explicit confirmation
4. **Implement** and update status to `in_progress`
5. **Update status** to `completed` when done

## File location

```
.project/changes/YYYYMMDDHHMMSS_short_description.md
```

- `YYYYMMDDHHMMSS` = current timestamp at creation time (year, month, day, hour, minute, second)
- `short_description` = snake_case, max 5 words
- Always **create a new file** — never overwrite a previous plan
- Timestamp ensures no conflicts when multiple people work in parallel

## File format

```markdown
# Title

> TLDR: one sentence describing what this change does and why.

**Status:** proposed | in_progress | completed
**Created:** YYYY-MM-DD
**Owner:** @username

---

## Context

Why this change? What problem does it solve?

## Objectives

- Objective 1
- Objective 2

## Changes

Files to be modified/created and what will change.

## How to verify

How to confirm the change is working.
```

## Rules

- Write `short_description` in English, snake_case
- TLDR is mandatory — one sentence, placed right after the title
- Keep content concise — this is a record, not documentation
- Never start implementing before the user approves the change file
