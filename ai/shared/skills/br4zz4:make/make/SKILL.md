---
name: skill:make
description: Use this skill when writing or modifying Makefile targets or scripts. Enforces conventions for target simplicity, folder structure, and where to place new files.
version: 1.1.0
---

# Make Skill

> **TLDR**: Make targets must be simple. Logic goes in `scripts/make/`, not in Makefiles. Project-specific make files go in `.project/make/`.

## Rules

- Every target calls either a **simple command** or a **`scripts/make/` script**
- Never put multi-line logic or conditionals inline in a Makefile
- Scripts that support make targets go in `scripts/make/` — mirroring the make structure
- Project-specific make files go in `.project/make/`, never in the project root `make/`

## Folder structure

Make files and their scripts mirror each other:

```
make/
  core/
    ai.mk          → scripts/make/core/ai/setup
    git.mk         → scripts/make/core/git/add, commit, ...
    release.mk     → scripts/make/core/release.sh
    main.mk        (includes all core/*.mk)
  shell.makefile   (stack entry point — includes core/main.mk)

scripts/
  make/
    core/
      ai/setup
      git/add, commit, pull, update, status
      release.sh
```

## Where to place new files

| What | Where |
|------|-------|
| Shared make target | `.commons/make/core/<name>.mk` |
| Script for shared target | `.commons/scripts/make/core/<name>/` |
| Stack-specific make target | `.commons/make/stacks/<stack>/<name>.mk` |
| Script for stack target | `.commons/scripts/make/stacks/<stack>/<name>/` |
| Project-specific make target | `.project/make/<name>.mk` |
| Project-specific script | `.project/scripts/make/<name>/` |

Include new `.mk` files in `make/core/main.mk` (shared) or the stack entry point.

## Correct patterns

```makefile
# Simple one-liner — OK
deploy:
	@docker compose up -d

# Delegates to script — OK
ai.setup:
	@bash .commons/scripts/make/core/ai/setup.sh

# Named make target calling another — OK
staging.deploy:
	$(MAKE) deploy ENV=staging
```

## Wrong patterns

```makefile
# Logic inline — NOT OK
deploy:
	@if [ "$(ENV)" = "production" ]; then \
		echo "deploying..."; \
		terraform apply; \
	fi

# Script outside scripts/make/ — NOT OK
release:
	@bash scripts/release.sh

# Stack-specific script in core/ — NOT OK
db.migrate:
	@bash .commons/scripts/make/core/db/migrate.sh
```
