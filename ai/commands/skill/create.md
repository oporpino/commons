# Skill Create

Create a new skill file in the correct location.

## Default: always use .commons

```
.commons/ai/skills/<name>/SKILL.md
```

Skills in `.commons` are shared across all projects in the org. This is the default.

## Exception: project-level skill

```
.project/ai/skills/<name>/SKILL.md
```

Only when the user explicitly says "create a project skill" or "skill only for this project". Project skills take priority over commons skills with the same name.

## SKILL.md format

```markdown
---
name: skill:<name>
description: Use this skill when the user asks to X.
version: 1.0.0
---

# Skill Title

> **TLDR**: One sentence summary.

## Rules / Steps
...
```

## Rules

- Always start content with `> **TLDR**`
- Write `description` as a trigger: "Use this skill when the user asks to X"
- Keep it concise — skills are quick reference, not documentation
- Write everything in English

## Commit workflow

1. Create the skill file
2. If in `.commons`: commit inside `.commons` first, then update submodule pointer in project root
3. If in `.project/ai/skills/`: commit directly to the project repo
