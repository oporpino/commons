## .env and .env.example

Both files must always exist and stay in sync. `.env` is gitignored; `.env.example` is committed and is the source of truth for onboarding.

### Structure

Use `─` separators and section headers. Sections must appear in this order:

```bash
# ─────────────────────────────────────────────
# Dev mode
# ─────────────────────────────────────────────
# DEV_MODE options:
#   container: run the app and dependencies with docker compose
#   local: run the app on the host and use dependencies through localhost
DEV_MODE=container

# DEV_DEPENDENCIES options when DEV_MODE=local:
#   start: start dependencies before the local app
#   skip: assume dependencies are already running (default)
DEV_DEPENDENCIES=start

# DEV_ALWAYS_BUILD_CONTAINERS options:
#   true: always pass --build to docker compose run in container mode
#   false: do not pass --build (default)
DEV_ALWAYS_BUILD_CONTAINERS=false

# ─────────────────────────────────────────────
# Stack versions
# ─────────────────────────────────────────────
RUBY_VERSION=3.4.4
NODE_VERSION=22        # include only stacks the project uses

# ─────────────────────────────────────────────
# Frontend  (include only if project has a frontend module)
# ─────────────────────────────────────────────
WEB_PORT=3012          # follow ports convention — see @rules/shared/ports.md

# ─────────────────────────────────────────────
# Backend / API  (adjust section name to match the project)
# ─────────────────────────────────────────────
APP_NAME=<project>-api
CONTAINER_REGISTRY=616795656532.dkr.ecr.us-east-1.amazonaws.com/wehive
API_PORT=4012          # follow ports convention — see @rules/shared/ports.md

DATABASE_URL_STAGING=
DATABASE_URL_PRODUCTION=

# ─────────────────────────────────────────────
# Banco de dados (PostgreSQL)
# ─────────────────────────────────────────────
DATABASE_HOST=database
DATABASE_PORT=5012
DATABASE_NAME=<project>_development
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=postgres
DATABASE_POOL=5

# ─────────────────────────────────────────────
# Integrações externas
# ─────────────────────────────────────────────
SOME_API_KEY=
SOME_BASE_URL=https://sandbox.example.com/api/v1

# ─────────────────────────────────────────────
# Datadog (staging e production apenas)
# Para testar local: COMPOSE_PROFILES=monitoring make up
# ─────────────────────────────────────────────
DD_API_KEY=
DD_SITE=us5.datadoghq.com
DD_ENV=staging
DD_SERVICE=<project>-api
DD_VERSION=
```

### Rules

- **Always** include the Dev mode section first, with all three vars and their option comments
- **Always** include Stack versions — only the stacks the project actually uses
- **Always** use `WEB_PORT` and `API_PORT` — never `PORT` or `BACKEND_PORT`
- **Never** use `${VAR:-default}` in compose files — missing vars must fail loudly
- **Never** omit a var from `.env.example` that is used anywhere in the project
- **Always** leave external API keys empty in `.env.example` — never commit real credentials
- **Always** provide the sandbox/staging URL as the default for external `BASE_URL` vars
- **Always** include `DATABASE_URL_STAGING` and `DATABASE_URL_PRODUCTION` in backend projects (empty)
- **Always** include the Datadog section in backend projects (empty keys)
- Single-module projects: one `.env` at the root
- Multi-module projects: one `.env` at the root — never per-module `.env` files

### .env.example vs .env

`.env.example` is the committed template:
- Include explanatory comments for non-obvious vars (options, usage, where to get the value)
- Leave sensitive values empty (`KEY=`)
- Provide safe defaults for local dev (ports, localhost URLs, postgres credentials)

`.env` is the local copy (gitignored):
- Same structure as `.env.example`
- Comments are optional but sections must match
- Fill in real values for local development
