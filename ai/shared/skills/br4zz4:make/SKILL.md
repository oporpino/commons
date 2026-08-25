---
name: br4zz4:make
description: Use when writing or modifying Makefile targets.
version: 2.0.0
---

# commons:make

> **TLDR**: Make targets must be simple. Shared command behavior goes in `make/commands/`, shared orchestration goes in `tasks/`, and project execution stays in `run/`. Project `bin/` holds only stack-native binstubs.

## Rules

- Every target calls either a **simple one-liner** or delegates to a `run/`, `tasks/`, or `.commons/bin/` script
- **One-liner rule**: a target may have logic inline only if it is a single command (excluding `echo`/`printf` messages). Two or more real commands → extract to a script.
- Never put multi-line logic or conditionals inline in a Makefile
- Choose the right script type before creating anything (see below)

## Correct patterns

```makefile
# Simple one-liner — OK
deploy:
	@docker compose up -d

# Delegates to task — OK
n8n.workflows.promote:
	@bash tasks/n8n/workflows/promote.sh

# Delegates to a shared bin — OK
db.load:
	@.commons/bin/db/load /data/dump.sql

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
		kubectl rollout ...; \
	fi
```

## Script types

| Type | Nature | Location |
|---|---|---|
| **run** | Project run script — the public command surface (`server`, `test`, `lint`, `migrate`, ...), exposed as `make run.<name>` | `run/<name>` |
| **bin** | Generic executable — could be installed on the system, usable outside the project without context | `.commons/bin/<domain>/<name>` |
| **task** | Project-scoped script — executes a task within the project context, even if it accepts parameters | `tasks/<domain>/<name>.sh` |

**How to decide:**
- Is it one of the project's standard operations (start, test, lint, install, migrate, ...)? → **run**
- Would this script make sense installed as a system command, used by any project? → **bin**
- Does it depend on project structure, env vars, kubectl context, docker compose, or project paths? → **task**
- Does it orchestrate other scripts in sequence? → **task** (recipe)

**Naming:**
- **bin** → no extension (e.g. `.commons/bin/db/load`, `.commons/bin/db/drop`) — called like a system command
- **task** → `.sh` extension (e.g. `tasks/n8n/workflows/export.sh`) — explicitly a shell script

**Examples:**
- `.commons/bin/db/load` — loads a SQL dump into any postgres instance. Generic. **bin**
- `tasks/n8n/workflows/export.sh` — exports from the project's n8n instance. **task**
- `tasks/n8n/workflows/deploy.sh` — deploys to the project's k8s cluster. **task**
- `tasks/n8n/workflows/promote.sh` — backup + deploy sequence. **task** (recipe)

**Additional rules:**
- A task may call other tasks or bins
- A recipe task orchestrates other tasks/bins in sequence — never duplicates their logic
- A recipe calling another recipe is a smell — flatten or extract

## Where scripts live

| Location | Purpose |
|---|---|
| `run/` | Project run scripts — the public command surface, exposed as `make run.<name>`. |
| `tasks/` | Project-specific tasks. Belong to this repo only. |
| `bin/` | Stack-native binstubs only (`rails`, `rake`, `bundle`, `manage.py`, ...). |
| `.commons/shell/tasks/` | Shared tasks reused across multiple projects. |
| `.commons/bin/` | Shared bins reused across multiple projects. (e.g. `db/load`, `db/drop`) |

- Never put project-specific logic in `.commons/`
- Never duplicate in `run/` or `tasks/` what already exists in `.commons/`
- Scripts must be executable (`chmod +x`)
- `run/` scripts are the **source of truth** — never delegate to `.commons/shell/tasks/` from a project `run/` script. Write the commands directly.
- `make code.*` targets do not exist — use `run/` scripts directly (`run/test`, `run/lint`, `run/audit`) or their `make run.*` targets

## Commons make structure

```
.commons/make/
  main.makefile          ← único entry point (.makefile só aqui)
  core/
    _main.mk             ← loads shared core modules
    commands.mk          ← scans run/*, generates run.<name> targets, loads matching command files
    help.mk, release.mk, compose.mk, setup.mk
  commands/
    <name>.mk            ← command-owned rules only when a run/ script needs special behavior
```

**Como usar num projeto:**

O `Makefile` do projeto inclui `main.makefile`:

```makefile
include $(COMMONS_DIR)/make/main.makefile
```

- `main.makefile` delegates run/ discovery to `make/core/commands.mk`
- `make/core/commands.mk` scans `run/*` (subdirectories like `run/terraform/` excluded) and loads only the `make/commands/<name>.mk` files that match existing run/ scripts
- `make/commands/<name>.mk` is keyed by script name (e.g. `run/test` → `test.mk`) and defines the `run.<name>` target — it exists only when a run/ script needs special behavior beyond the default runner path
- generic `run/*` scripts are exposed as `run.<name>` targets through the shared devmode runner
- the devmode runner chooses `exec` for local and `docker compose run` for container when the command needs a service
- no automatic stack discovery: only run-matched command files and generated `run.<name>` targets are loaded from the entrypoint

## Commons make targets and run/

Commons make targets must delegate to `run/` scripts in the project when the command is not command-file owned, **not** inline the command themselves.

The project owns the implementation. Commons owns the invocation path.

```makefile
# commons/make — CORRECT: delegates to project run/
run.migrate:
	run/migrate

# commons/make — WRONG: implements logic directly
run.migrate:
	$(_django) python manage.py migrate
```

The `run/` script is the single source of truth for how a task runs — Make, CI, k8s Jobs, and other callers all use it.

## Alignment rule

Makefile targets and scripts are a pair — they must always stay in sync.

- Script **moved or renamed** → update every Makefile target that references it
- Target **renamed** → update the script call and any docs referencing the old name
- Script **deleted** → remove the corresponding target
- Script **created** → add a corresponding target in the Makefile

Never leave a target pointing to a path that doesn't exist, and never leave a script with no target.
