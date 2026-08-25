---
name: commands:machine:setup
description: Install machine tools and fix missing dependencies.
---

# Machine Setup

Fix missing tools or failed commands due to missing dependencies.

## When to invoke

- A command fails with `command not found` or `not found`
- User asks how to install a tool
- A prerequisite is missing before running a task

## Fix

Run the environment init script to install all machine-level tools:

```bash
gh api repos/ibft-corp/commons/contents/environment/init.sh --jq '.content' | base64 -d | bash
```

If only one tool is missing:

| Tool | Install |
|------|---------|
| `sops` | `brew install sops` |
| `age` | `brew install age` |
| `kubectl` | `brew install kubectl` |
| `terraform` | managed via `.tool-versions` + `asdf install` |
| `docker` | `brew install --cask docker` |
| `asdf` | `brew install asdf` |

## Note

For project setup (`.env`, `.claude`, `.commons`), use `make project.init` (first time) or `make setup` (reconfigure).
