---
name: skill:rules
description: Use this skill when the user asks to load, review, or apply project rules.
version: 1.0.0
---

# Rules

> **TLDR**: Load all rules from `.commons/ai/rules/` and `.project/ai/rules/` and apply them as constraints for the current task.

## Steps

1. Read every file under `.commons/ai/rules/**/*.md`
2. Read every file under `.project/ai/rules/**/*.md` (skip if directory does not exist)
3. Project rules (`.project/`) take priority over commons rules when they conflict
4. Apply all loaded rules as active constraints — do not wait to be asked, enforce them now
5. If the user asked for a review: report violations grouped by rule file, severity first

## Rules

- Never summarize rules back to the user unless asked — just apply them
- If a project rule contradicts a commons rule, follow the project rule
