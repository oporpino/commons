---
name: templates
description: Use when a required project file may be missing.
version: 1.0.0
---

# commons:templates

> **TLDR**: Templates live in `templates/<scope>/` and mirror the destination path. Copy only if destination does not exist, then make executable.

## Convention

```
templates/<scope>/<path/to/file>.template.<ext>
```

- `<scope>` mirrors the context: `environment/`, `project/`, `infra/`, etc.
- The rest of the path mirrors where the file will land in the project
- Extension is always `.template.<original_ext>` (e.g. `.template.sh`, `.template.yml`)

**Example:**
```
shell/tasks/terraform/templates/.sops.yaml.template  →  .infra/.sops.yaml
```

## Rules

- **Never overwrite** — only apply if the destination does not exist
- Make the file executable after copying if it's a script: `chmod +x <destination>`
- Inform the user what was copied and where

## How to apply

```bash
[ -f <destination> ] || {
  mkdir -p <destination_dir>
  cp .commons/templates/<scope>/<path>.template.<ext> <destination>
  chmod +x <destination>   # if script
  echo "✅ <destination> created from template"
}
```

## Adding new templates

1. Place the file under `templates/<scope>/<path>.template.<ext>`
2. Document it wherever relevant (skill, command, or structure doc)
