---
name: br4zz4:find-in-root
description: Use when searching for files across all br4zz4 projects.
version: 1.0.0
---

# commons:find-in-root

> **TLDR**: The br4zz4 root is at `~/workspace/br4zz4.tech/`. When you need a file, script, config, or workflow that belongs to another project, search there — not just the current working directory.

## When to use

Use this skill before assuming a file doesn't exist or asking the user to paste content:

- Looking for a `deploy.sh`, `Makefile`, CI workflow, or config that lives in another project
- Investigating a bug that crosses project boundaries
- Understanding how a shared pattern is implemented in a sibling project

## How to find the root

The workspace root is always: `~/workspace/br4zz4.tech/`

Resolve it at runtime:

```bash
br4zz4_ROOT="$(cd "$(dirname $(git rev-parse --git-dir 2>/dev/null || echo .))" && cd .. && pwd)"
# or simply:
br4zz4_ROOT=~/workspace/br4zz4.tech
```

## Search patterns

### Find a file by name across all projects

```bash
find ~/workspace/br4zz4.tech -name "<filename>" \
  -not -path "*/.git/*" \
  -not -path "*/.venv/*" \
  -not -path "*/node_modules/*" \
  -not -path "*/__pycache__/*"
```

### Find a file in a specific project

```bash
find ~/workspace/br4zz4.tech/<project-name> -name "<filename>" \
  -not -path "*/.git/*"
```

### Grep for a pattern across all projects

```bash
grep -r "<pattern>" ~/workspace/br4zz4.tech \
  --include="*.sh" --include="*.yml" --include="*.py" \
  --exclude-dir=".git" --exclude-dir=".venv" \
  --exclude-dir="node_modules" -l
```

### List all project directories

```bash
ls ~/workspace/br4zz4.tech/
```

## Common locations

| What | Where |
|------|-------|
| CI workflows | `<project>/.github/workflows/*.yml` |
| Deploy scripts | `<project>/scripts/deploy*.sh` |
| Supervisor confs | `<project>/supervisor/*.conf` |
| Makefile targets | `<project>/Makefile`, `<project>/.project/make/*.mk` |
| Commons skills | `.commons/ai/shared/skills/` |
| Commons shell tasks | `.commons/shell/tasks/` |

## Rules

- Always search the br4zz4 root before asking the user to paste a file
- Exclude `.git`, `.venv`, `node_modules`, `__pycache__` from searches to avoid noise
- If `.commons` exists as a symlink in the current project, it resolves to `~/workspace/br4zz4.tech/.commons` — but search the real path directly
