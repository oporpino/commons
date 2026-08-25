---
name: docker
description: Use when creating or reviewing Docker files.
version: 2.0.0
---

# commons:docker

> **TLDR**: Every project has a thin `compose.yml` that delegates to `.project/docker/compose/services.yml`. The stacks in `.commons/docker/compose/stacks/` expose `x-stack-base` — projects extend it to define their services. `depends_on` always goes on the service, never on the base. Volumes of installed deps belong to the stack file; project-specific volumes belong to the service.

## The pattern

### `compose.yml` — root, always thin

```yaml
name: <project-name>

include:
  - path:
      - ${COMMONS_DIR}/docker/compose/shared/database.yml  # if needed
      - .project/docker/compose/services.yml
```

- Only declares what shared infrastructure the project needs
- Never defines services here
- Always uses `${COMMONS_DIR}` (not `.commons/`)

### `.project/docker/compose/services.yml` — all project services

This is the only place services are defined. It includes the stacks it needs and extends `x-stack-base` from them.

**Single-module (Ruby + database):**

```yaml
include:
  - path:
      - ${COMMONS_DIR}/docker/compose/stacks/ruby.yml

x-service-base: &service-base
  extends:
    file: ${COMMONS_DIR}/docker/compose/stacks/ruby.yml
    service: x-stack-base

services:
  app:
    <<: *service-base
    ports:
      - "${PORT}:${PORT}"
    depends_on:
      database:
        condition: service_healthy

  worker:
    <<: *service-base
    environment:
      RUNTIME_MODE: worker
    depends_on:
      database:
        condition: service_healthy
```

**Multi-module (Ruby backend + React frontend):**

```yaml
include:
  - path:
      - ${COMMONS_DIR}/docker/compose/stacks/ruby.yml
      - ${COMMONS_DIR}/docker/compose/stacks/react.yml

x-backend-base: &backend-base
  extends:
    file: ${COMMONS_DIR}/docker/compose/stacks/ruby.yml
    service: x-stack-base
  working_dir: /source/modules/backend

x-frontend-base: &frontend-base
  extends:
    file: ${COMMONS_DIR}/docker/compose/stacks/react.yml
    service: x-stack-base
  working_dir: /source/modules/frontend
  volumes:
    - node_modules:/source/modules/frontend/node_modules

services:
  backend-api:
    <<: *backend-base
    environment:
      PORT: ${API_PORT}
    ports:
      - "${API_PORT}:${API_PORT}"
    depends_on:
      database:
        condition: service_healthy

  backend-worker:
    <<: *backend-base
    environment:
      RUNTIME_MODE: worker
    depends_on:
      database:
        condition: service_healthy

  frontend-web:
    <<: *frontend-base
    ports:
      - "${WEB_PORT}:${WEB_PORT}"

volumes:
  node_modules:
    driver: local
```

## Stack files — what they provide

Stack files live in `.commons/docker/compose/stacks/` and expose `x-stack-base` — a YAML anchor projects extend. They define only what belongs to the stack: build args, installed-deps volume, and mount path.

| Stack file | `STACK` | Volume it defines |
|---|---|---|
| `_base.yml` | — | `x-base` (build context, env_file, source mount) |
| `ruby.yml` | `ruby` | `bundle_cache:/usr/local/bundle` |
| `react.yml` | `node` | `node_modules:/source/node_modules` |
| `elixir.yml` | `elixir` | `build_cache:/_build`, `deps_cache:/deps` |
| `python.yml` | `python` | `.venv` volume |

Projects never re-declare these volumes — they come from the stack file via `include`.

**Exception — multi-module node_modules:** When a React module lives under `modules/frontend/`, the default volume path (`/source/node_modules`) is wrong. Override only the volume mount in the base anchor:

```yaml
x-frontend-base: &frontend-base
  extends:
    file: ${COMMONS_DIR}/docker/compose/stacks/react.yml
    service: x-stack-base
  working_dir: /source/modules/frontend
  volumes:
    - node_modules:/source/modules/frontend/node_modules  # override path only
```

And declare the volume in the project file:

```yaml
volumes:
  node_modules:
    driver: local
```

## Rules

| Rule | Detail |
|---|---|
| `depends_on` goes on the service | Never on the base anchor — the base doesn't know what dependencies the project has |
| Installed-deps volumes go in the stack | `bundle_cache`, `node_modules` (default path) belong in the stack file |
| Project-specific volumes go on the service | Path overrides for multi-module, or project-specific mounts |
| `working_dir` goes on the base anchor | When all services of a module share the same working dir |
| Never define infrastructure services in `.project/` | PostgreSQL, Redis, RabbitMQ always come from `.commons/docker/compose/shared/` |
| Always use `${COMMONS_DIR}` | Never `.commons/` — the var is exported by `~/.zshrc` |
| Always use `path:` array in `include:` | Never bare strings |
| Never use `${VAR:-default}` in compose | If a var is missing the project must fail loudly — no silent fallbacks |
| Use `WEB_PORT` and `API_PORT` | Never `PORT` or `BACKEND_PORT` — see `@rules/shared/ports.md` |
| Use `${VAR:?VAR is not set}` in `run/` scripts | Fail with a clear message when a required env var is missing |
| All vars in `.env` and `.env.example` | Follow the structure in `@rules/shared/env.md` — never omit a var used in compose |

## Shared infrastructure services

| File | Service | Required env vars |
|---|---|---|
| `shared/database.yml` | `database` (PostgreSQL 16) | `DATABASE_NAME`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`, `DATABASE_PORT` |
| `shared/cache.yml` | `cache` (Redis 7) | `CACHE_PORT` |
| `shared/messagebroker.yml` | `messagebroker` (RabbitMQ 3.13) | `MESSAGEBROKER_PORT` |
| `shared/mailcatcher.yml` | `mailcatcher` | none (ports: 1025 SMTP, 1080 UI) |
| `shared/monitoring.yml` | `datadog` | `DD_API_KEY`, `DD_SITE` (profile: monitoring) |

## Multi-module projects

See `.commons/.project/docs/guides/compose.md` for the full multi-module pattern including `APP_SERVICE`, root `Makefile` delegation, and parallel `run.test`.

## `run/` scripts — container entrypoints

| Script | Called by | Purpose |
|---|---|---|
| `run/server` | compose service, `dev` Dockerfile CMD, `make run.server` | Basic server |
| `run/runtime` | `runtime` Dockerfile CMD | Production entrypoint |
| `run/install` | compose service, `source` stage, `make run.install` | Install dependencies |
| `run/test` | compose service, `test` Dockerfile CMD, `make run.test` | Run tests |
| `run/worker` | `worker`/`backend-worker` service, `make run.worker` | Background worker |
| `run/migrate` | compose service, `make run.migrate` | Run migrations |
| `run/seed` | compose service, `make run.seed` | Seed database |
| `run/lint` | `make run.lint` | Run linter |

`run/server` and `run/runtime` must use `#!/bin/sh` and be self-contained — production has no `.commons/`.

## Build args (`.infra/build-args`)

```bash
DOCKERFILE=${COMMONS_DIR}/docker/Dockerfile
STACK=ruby          # ruby | node | elixir | python
STACK_VERSION=3.4.4
DISTRO=alpine
DEPS_PATH=/usr/local/bundle
LOCK_FILES=Gemfile Gemfile.lock .ruby-version
```

## `.dockerignore` required entries

```
.commons
.lockfiles
.claude
.git
```

## Dockerfile stages

| Stage | FROM | Purpose |
|---|---|---|
| `base` | `stack:version-distro` | Shared foundation (runtime + dev) |
| `builder` | `base` | Build tools |
| `source` | `builder` | Code + installed deps |
| `test` | `source` | CI (lint, audit, test) |
| `dev` | `builder` (or registry) | Local development |
| `runtime` | `base` | Production |
