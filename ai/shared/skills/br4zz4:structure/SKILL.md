---
name: br4zz4:structure
description: Use to understand WeHive project structure.
version: 2.0.0
---

# commons:structure

> **TLDR**: All projects live under `wehive/`. Each project symlinks `commons` as `.commons` and follows a strict layout. Run scripts go in `run/`. Tasks go in `tasks/` (project-specific) or `.commons/shell/tasks/` (shared). Shared bins live in `.commons/bin/`; project `bin/` holds only stack-native binstubs.

## Workspace layout

```
wehive/
├── commons/                   # Shared tooling repo
│   ├── shell/tasks/           # Shared shell tasks (reused across projects)
│   ├── make/                  # Shared makefiles (core/, stacks/, shared/)
│   ├── bin/                   # Shared bins (e.g. bin/db/load, bin/db/drop)
│   ├── docker/                # Shared docker-compose dev files
│   └── ai/                    # AI rules and skills
│
├── gateway/                   # Example project (Elixir)
├── checkout-api/              # Example project (Ruby)
├── marketing-automation/      # Example project (N8N)
└── ...                        # Other projects
```

## Per-project layout

```
<project>/
├── .commons -> /path/to/wehive/commons   # Symlink — never a git submodule
├── compose.yml                            # Extends .commons/docker/<stack>/compose.dev.yml
├── Makefile                               # Includes .commons/make/<stack>.makefile
├── .project/
│   ├── make/                              # Project-specific makefile targets
│   │   └── main.mk                        # Included by Makefile
│   ├── ai/                                # AI config — rules/, skills/, commands/
│   └── docs/                              # ALL documentation — closed set, see below
├── .infra/                                # Infrastructure (only if project deploys)
│   ├── .sops.yaml
│   ├── k8s/
│   └── terraform/
├── tasks/                                 # Project-specific shell tasks
│   └── <domain>/<name>.sh
├── run/                                   # WeHive run scripts (server, test, lint, ...)
│   └── <name>
└── bin/                                   # Stack-native binstubs only (rails, rake, ...)
```

## `.project/docs/` — closed set

All documentation lives in `.project/docs/`, and its first level is a **closed set** of 8
directories plus 3 reserved files. Nothing else is valid at that level.

```
.project/docs/
├── README.md              # index of all docs           (reserved)
├── RULES.md               # business-rule index, R-XXX   (reserved)
├── modules.md             # module convention, multi-module only (reserved)
├── specs/  (+ drafts/)    # planned or executed changes
├── plans/                 # implementation steps for a spec
├── features/              # user stories + Gherkin
├── learnings/             # retrospective learnings
├── architecture/          # architectural decisions + consequences
├── guides/                # operational how-to (setup, deploy, access, debug)
├── reference/<scope>/     # how the system works: flows, APIs, contracts
└── rules/<scope>/         # business rules in Given/When/Then
```

`<scope>` (business domain: `billing`, `membership`, `habits`, …) exists **only** inside
`reference/` and `rules/`. For routing a specific file to its destination, use `skill:docs`
— it carries the ordered routing table.

**Never valid:**

| ❌ | ✅ |
|---|---|
`docs/` at the repo root | `.project/docs/` |
`.project/specs/`, `.project/plans/`, `.project/features/` | `.project/docs/<same>/` |
`.project/rules/` | `.project/ai/rules/` (AI config, not docs) |
`.project/changes/`, `.project/docs/changes/`, `.project/ai/changes/` | `.project/docs/specs/` |
`.project/docs/dev_tooling/`, `.project/docs/patterns/` | `.project/docs/guides/` |
any free-form directory at level 1 of `.project/docs/` | one of the 8 closed directories |
`.project/docs/CLAUDE.md` | `CLAUDE.md` at the repo root |

File names are English `snake_case`; document content is Portuguese.

## The .commons symlink

Each project has `.commons` as a **symlink** pointing to the `commons` repo:

```
.commons -> /Users/<user>/workspace/wehive/commons
```

- Created/refreshed by: `make commons.projects.symlink` (run from commons)
- Tracked in git as a submodule pointer (SHA), not as a symlink
- Updated across all projects by: `make commons.projects.commit`

This means `.commons/shell/tasks/` in any project resolves to `commons/shell/tasks/`.

## compose.yml

Every project's `compose.yml` extends the shared stack file from commons:

```yaml
# compose.yml
include:
  - .commons/docker/<stack>/compose.dev.yml
```

Never duplicate docker-compose configuration that already exists in `.commons/docker/`. Only add project-specific services or overrides.

## Makefile structure

```makefile
# Always first: include the commons stack makefile
include $(COMMONS_DIR)/make/main.makefile

# Always second: include project-specific targets
include .project/make/main.mk

# Then: project-specific targets
domain.action:
    @bash tasks/<domain>/<action>.sh
```

The stack is **auto-detected** by `_contract.mk` based on file presence — no explicit include needed in `Makefile`:

| File present | Stack |
|---|---|
| `Gemfile` | Ruby/Rails |
| `package.json` | React/Node |
| `mix.exs` | Elixir/Phoenix |
| `pyproject.toml` / `requirements.txt` | Python/Django |

The `Makefile` only needs:
```makefile
include $(COMMONS_DIR)/make/main.makefile
# DO NOT INCLUDE RULES ON THIS MAKEFILE
```

Project customizations go in `.project/make/overrides.mk` (included automatically by `main.makefile`).

## Where scripts live

| Location | Purpose | Extension |
|---|---|---|
| `run/<name>` | WeHive run scripts — the project command surface (`server`, `test`, `lint`, ...). Exposed as `make run.<name>`. | none |
| `tasks/<domain>/<name>.sh` | Project-specific tasks. Only meaningful inside this repo. | `.sh` |
| `bin/` | Stack-native binstubs only (`rails`, `rake`, `manage.py`, ...). | none |
| `.commons/shell/tasks/<domain>/<name>.sh` | Shared tasks reused across multiple projects. | `.sh` |
| `.commons/bin/<domain>/<name>` | Shared executables reused across multiple projects. | none |

**Decision rule:**
- Is it one of the project's standard operations (server, test, lint, migrate, ...)? → `run/`
- Does it use this project's env vars, kubectl context, or docker compose? → `tasks/`
- Is it generic enough to work in any project? → `.commons/bin/`
- Is it already used by another project? → `.commons/shell/tasks/` or `.commons/bin/`
- Is it only for this project? → `tasks/` or `run/`

**Never:**
- Put project-specific logic in `.commons/`
- Duplicate in `tasks/` what already exists in `.commons/shell/tasks/`
- Reference `.commons/bin/` for tasks that live in `.commons/shell/tasks/`

## Temporary artifacts and backups — always `./tmp`

Any file a script writes that is not source — DB dumps, exported workflows,
backups, generated output, scratch files — goes under `./tmp` (project root or
module root), never in a bespoke directory like `tasks/.../backups/`. `./tmp` is
gitignored once; a per-purpose backup dir tends to get committed by accident.

- Scripts write to `$APP_ROOT/tmp/<purpose>-<timestamp>/` (e.g.
  `tmp/exported-production-20260731_101500/`).
- The module/project `.gitignore` lists `tmp/` and nothing else for artifacts.
- Never add a second ignore pattern for a new backup folder — reuse `./tmp`.

## .infra/ layout

Only present in projects that have their own kubernetes deployment and/or terraform-managed infrastructure. See `skill:infra` for details.

```
.infra/
├── .sops.yaml
├── k8s/
│   ├── base/specs/
│   └── overlays/staging/ + production/
└── terraform/
    ├── main.tf, data.tf, versions.tf, backend.tf
    ├── secrets/staging.enc.yml, production.enc.yml
    └── ...
```

## Environment vs setup

- **environment init** = configura a máquina e todos os projetos (ferramentas globais + clone dos repos)
  - Script: `environment/init.sh`
  - Run: `gh api repos/ibft-corp/commons/contents/environment/init.sh --jq '.content' | base64 -d | bash`
- **project.init** = inicializa este projeto na máquina pela primeira vez (`.commons`, `.env`, asdf)
  - Script: `.commons/shell/tasks/setup/project/init.sh`
  - Run: `make project.init`
- **setup** = reconfigura este projeto (`.env`, asdf)
  - Script: `.commons/shell/tasks/setup/project.sh`
  - Run: `make setup`

## Commons shared tasks reference

Key shared tasks available via `.commons/shell/tasks/`:

```
setup/
  project.sh            # Setup do projeto (.project, .claude, .codex, .env)
  env.sh                # Substituição de PROMPT_USER no .env
commons/
  setup-symlink.sh      # Create .commons symlinks in all projects
  projects-commit.sh    # Sync commons SHA across all projects
  projects-push.sh      # Push main branch across all projects
release/
  create.sh             # Create a release
git/
  branch-cleanup.sh     # Delete merged branches
deploy/                 # Deployment tasks
terraform/              # Terraform secret management
```

```
environment/init/
  tools.sh              # Verifica ferramentas da máquina
  asdf.sh               # Instala asdf + versões de linguagens
  wehive.sh             # Instala wehive CLI globalmente
```

## `run/` — container entrypoints

The shared compose services (`app`, `worker`, `beat`, `migrations`, `seed`) call `run/` scripts as their `command`. Each `run/` script is the source of truth for that operation — self-contained, no delegation to `.commons/`.

```bash
# run/server
#!/bin/bash -e
if [ -z "${LD_PRELOAD+x}" ]; then
  LD_PRELOAD=$(find /usr/lib -name libjemalloc.so.2 -print -quit)
  export LD_PRELOAD
fi
exec bin/rails server -p "${PORT:-3000}" -b 0.0.0.0

# run/worker
#!/bin/bash -e
exec bundle exec good_job start --enable-cron

# run/migrate
#!/bin/bash -e
exec bundle exec rails db:migrate

# run/lint
#!/bin/bash -e
exec bundle exec rubocop "$@"

# run/runtime — reads RUNTIME_MODE and routes to the correct process
#!/bin/bash -e
if [ "${RUNTIME_MODE}" = "worker" ]; then
  exec bundle exec good_job start --enable-cron
elif [ "${RUNTIME_MODE}" = "seed" ]; then
  exec bundle exec rails db:seed
else
  bin/rails db:prepare
  exec run/server
fi
```

**Rules:**
- Only create the scripts for services the project actually uses
- All must be executable (`chmod +x run/*`)
- Every `run/` script is self-contained — no `.commons` dependency, no delegation
- The stack's `setup.sh` in `.commons/shell/tasks/docker/<stack>/setup.sh` installs stack tooling inside the Dockerfile

## Multi-module projects

Some projects have multiple independent runtimes (frontend + backend, or frontend + backend + worker). These group all modules under a `modules/` directory at the root — never put modules directly at the project root.

```
<project>/
├── modules/
│   ├── frontend/
│   │   ├── .module/               # module metadata — like .project/ but scoped to the module
│   │   │   └── make/main.mk       # module-specific make targets (APP_SERVICE, MODULE_DIR)
│   │   ├── .infra/                # k8s + terraform + build-args for this module
│   │   │   ├── build-args         # STACK, STACK_VERSION, DISTRO, LOCK_FILES
│   │   │   ├── k8s/base/ + overlays/staging/ + production/
│   │   │   └── terraform/
│   │   ├── Makefile               # includes commons stack + .module/make/main.mk
│   │   ├── src/
│   │   └── package.json
│   └── backend/
│       ├── .module/
│       │   └── make/main.mk
│       ├── .infra/
│       │   ├── build-args
│       │   └── k8s/
│       └── Makefile
├── .project/
│   └── docs/                      # ALL docs here — never in .module/
│       ├── specs/  plans/  features/  learnings/
│       └── architecture/  guides/  reference/  rules/
├── .commons -> ...
├── Makefile                       # delegates: frontend.%, backend.%
├── compose.yml                    # includes commons stack + .module/docker/ per module
├── .env.example
└── .gitignore
```

**Why `modules/` and not `apps/` or `packages/`:** `apps/` implies only user-facing apps; `packages/` implies npm libs. `modules/` is generic — workers, jobs, mobile apps, APIs all fit. It also never conflicts with Rails' `app/` directory.

**`.module/` convention:**
- `.module/` is to the module what `.project/` is to the repo.
- `make/main.mk` — declares `APP_SERVICE` and `MODULE_DIR`, included by the module's `Makefile`.
- Docs and specs **never** go in `.module/` — always in `.project/docs/` at the repo root.
- Change records **never** go in `.module/` — they are specs: `.project/docs/specs/` at the repo root.
- AI commands **never** go in `.module/` — always in `.project/ai/` or `.claude/` at the repo root.
- A `.project/` directory **never** goes inside a module — modules have `.module/`, not `.project/`.
- Infrastructure never goes in `.module/` — it lives in `.infra/` inside the module.

**`.infra/` in multi-module projects:**
- Every module owns its own `.infra/` — never a shared `.infra/` at the project root.
- `build-args` lives inside the module's `.infra/` — the `push.sh` reads it from `PWD` when `make -C modules/<name>` runs.
- `k8s/` and `terraform/` also live inside the module's `.infra/`.
- The project root has **no** `.infra/` in multi-module projects.

**Root `Makefile` delegation pattern:**
```makefile
include $(COMMONS_DIR)/make/main.makefile

frontend.%:
    @$(MAKE) -C modules/frontend $*

backend.%:
    @$(MAKE) -C modules/backend $*
```

**Root `compose.yml` pattern:**
```yaml
name: <project>
include:
  - path:
      - ${COMMONS_DIR}/docker/compose/shared/database.yml
      - .project/docker/compose/services.yml
```

**Rules:**
- Every module lives inside `modules/` — never at the project root.
- Each module is self-contained: its own manifest (`package.json`, `mix.exs`, `Gemfile`), its own tooling config, its own `.infra/`.
- No cross-module source imports at the language level.
- The project root holds only: `modules/`, `.project/`, `.commons` symlink, `Makefile`, `compose.yml`, `.env.example`, `.gitignore`, `.tool-versions`.
- No `.infra/` at the project root — infra lives inside each module.
- No `.project/` inside a module — that is a repo-level concept only.
- Docker compose for local dev (`n8n.yml`, stack overrides) lives in `.project/docker/compose/` at the root, not inside a module.
- Legacy docker swarm files go in `.project/docker/swarm/` at the root — never inside a module.
- A placeholder module (stack not yet chosen) has only `Makefile` and `.module/` with empty stubs — no `.gitkeep`.
- Stack auto-detection by `_contract.mk` looks at the project root. In multi-module projects, detection files (`package.json`, etc.) live inside `modules/<name>/` — add explicit paths in `.project/make/overrides.mk` if needed.

For the full convention see `.project/docs/modules.md` in the project.

## Checklist when creating a new project

- [ ] Create `.commons` symlink via `make commons.projects.symlink`
- [ ] Add `Makefile` with only `include $(COMMONS_DIR)/make/main.makefile`
- [ ] Add `.project/make/overrides.mk` with project-specific vars (if needed)
- [ ] Add `compose.yml` using `include: path:` array with commons shared + stack files
- [ ] Add `.project/docker/compose/services.yml` defining all services
- [ ] Add `run/server`, `run/migrate`, etc. for each compose service used
- [ ] Add the `.project/docs/` directories the project actually needs (closed set — see above)
- [ ] Add `.infra/` if single-module and project deploys independently
- [ ] For multi-module: add `.infra/` inside each module (never at project root)
- [ ] Put project-specific tasks in `tasks/<domain>/<name>.sh`
- [ ] Never duplicate what's already in `.commons/`
