---
name: br4zz4:ci
description: Use when creating or reviewing GitHub Actions files.
version: 1.0.0
---

# commons:ci

## Mandatory rules

1. **Secrets always UPPERCASE** — e.g. `GH_ACTIONS_IBFTCORP_SSH_KEY`, never `gh_actions_ibftcorp_ssh_key`
2. **Never use `secrets: inherit`** — always pass secrets explicitly
3. **All secrets listed explicitly** in every job that calls a reusable workflow
4. **No long inline scripts** — a `run:` block with real logic (loops, conditionals, multi-command) belongs in a script under `tasks/<area>/<name>.sh`, called in one line. Inline `run:` is only for trivial one-liners.
   - CI-specific scripts go in `tasks/ci/<name>.sh` — e.g. resolving build args, preparing lockfiles, tagging images
   - Never copy files, run multi-step setup, or call commons scripts inline — extract to `tasks/ci/`
   - One-liner example: `run: sh tasks/ci/resolve-build-args.sh frontend`
   - Bad example: copying build-args, calling resolve.sh, and cleaning up inline in `run: |`
5. **One-word job names** — each job is a single lowercase word (`requirements`, `check`, `package`, `ship`), never `build-and-submit` or `resolve-type`.
6. **Canonical job order** — jobs chain via `needs` in the standard order below.

## Deploy files & job order

Every deployable project has two files:

- **`deploy-staging.yml`** — trigger `push` on tag `v*` **and** `workflow_dispatch`
- **`deploy-production.yml`** — trigger `workflow_dispatch` only (manual promotion)

Canonical job pipeline (use the subset the project needs, always in this order):

```
requirements → check → package → stamp → ship → delivery
```

- `requirements` — validate the trigger (e.g. `require-tag`)
- `check` — lint / tests / config verification
- `package` — build the artifact (Docker image, EAS build)
- `stamp` — tag/retag the artifact for an environment
- `ship` — release/submit the artifact
- `delivery` — post-release rollout when separate from ship

Common shapes in the org:

- **v1 (simple web/api):** `requirements → checks → deploy`
- **v2 (containerized):** `requirements → package → stamp → ship`
- **production:** manual subset, usually `requirements → stamp → ship`

Most projects delegate each job to a reusable workflow in `ibft-corp/pipelines`.

## Mobile (EAS/Expo) projects

Mobile apps are **not** containerized — they do not use the Docker/DO reusables
from `pipelines`. They keep the **same job names and order**, but each job
delegates to a **local** reusable workflow under `.github/workflows/` that runs EAS.

Delivery type is decided by version: **major (X) bump = native build; minor/patch
(Y/Z) = OTA update** (see `skill:commons:mobile-release`). The `check` job resolves
this via a script; `ship` fans out to the matching local reusable.

```yaml
# deploy-staging.yml
jobs:
  requirements:
    uses: ./.github/workflows/require-tag.yml

  check:
    needs: requirements
    uses: ./.github/workflows/check.yml       # resolves native|ota, verifies config
    with:
      tag: ${{ github.ref_name }}

  ship:
    needs: check
    uses: ./.github/workflows/ship.yml        # calls release-native or release-ota
    with:
      tag: ${{ github.ref_name }}
      type: ${{ needs.check.outputs.type }}
      environment: staging
```

- Local reusables run EAS (`eas build` / `eas submit` / `eas update`).
- Native/ota resolution lives in a script (`.project/shell/tasks/release/resolve.sh`),
  never inline (rule 4).
- One-word job names; canonical order preserved.

## Standard secrets per reusable workflow

### `check-ruby.yml`
```yaml
secrets:
  RAILS_MASTER_KEY: ${{ secrets.RAILS_MASTER_KEY }}
  GH_COMMONS_READ_TOKEN: ${{ secrets.GH_COMMONS_READ_TOKEN }}
  BUNDLE_PACKAGER__DEV: ${{ secrets.BUNDLE_PACKAGER__DEV }}  # only if project uses private gems from packager.dev
```

### `deploy.yml`
```yaml
secrets:
  GH_ACTIONS_IBFTCORP_SSH_KEY: ${{ secrets.GH_ACTIONS_IBFTCORP_SSH_KEY }}
  GH_COMMONS_READ_TOKEN: ${{ secrets.GH_COMMONS_READ_TOKEN }}
```

## When to include `BUNDLE_PACKAGER__DEV`

Only in projects that install private gems from `https://packager.dev/avo-hq/` (e.g. trgclub-api uses `avo-advanced`).
Check the `Gemfile` for a `source: "https://packager.dev/..."` block.

## Standard workflow structure (Ruby projects)

```yaml
jobs:
  requirements:
    uses: ibft-corp/pipelines/.github/workflows/require-tag.yml@v1

  checks:
    needs: requirements
    uses: ibft-corp/pipelines/.github/workflows/check-ruby.yml@v1
    secrets:
      RAILS_MASTER_KEY: ${{ secrets.RAILS_MASTER_KEY }}
      GH_COMMONS_READ_TOKEN: ${{ secrets.GH_COMMONS_READ_TOKEN }}

  deploy:
    needs: checks
    uses: ibft-corp/pipelines/.github/workflows/deploy.yml@v1
    with:
      environment: staging
      environment_url: https://...
    secrets:
      GH_ACTIONS_IBFTCORP_SSH_KEY: ${{ secrets.GH_ACTIONS_IBFTCORP_SSH_KEY }}
      GH_COMMONS_READ_TOKEN: ${{ secrets.GH_COMMONS_READ_TOKEN }}
```

## K8s deploy workflow (package → tag → ship)

For projects deploying to Kubernetes, the deploy workflow uses three reusable workflows from `ibft-corp/pipelines`:

```yaml
jobs:
  prepare:
    runs-on: ubuntu-latest
    outputs:
      version_tag: ${{ steps.tag.outputs.version_tag }}
    steps:
      - id: tag
        run: echo "version_tag=$(echo '${{ github.ref_name }}' | tr '/' '-')" >> "$GITHUB_OUTPUT"

  package:
    needs: prepare
    uses: ibft-corp/pipelines/.github/workflows/package.yml@feat/build-args-from-project
    with:
      app_name: <app-name>
      version_tag: ${{ needs.prepare.outputs.version_tag }}
      dockerfile_target: runtime
    secrets:
      GH_COMMONS_READ_TOKEN: ${{ secrets.GH_COMMONS_READ_TOKEN }}
      BUNDLE_PACKAGER__DEV: ${{ secrets.BUNDLE_PACKAGER__DEV }}
      docr_token: ${{ secrets.DOCR_TOKEN }}

  tag:
    needs: [prepare, package]
    uses: ibft-corp/pipelines/.github/workflows/tag.yml@v2
    with:
      app_name: <app-name>
      source_tag: ${{ needs.prepare.outputs.version_tag }}
      target_tags: staging
    secrets:
      docr_token: ${{ secrets.DOCR_TOKEN }}

  ship:
    needs: [prepare, tag]
    uses: ibft-corp/pipelines/.github/workflows/ship.yml@v2
    with:
      app_name: <app-name>
      version_tag: ${{ needs.prepare.outputs.version_tag }}
      ref: ${{ github.ref_name }}
      environment: staging
      environment_url: https://...
    secrets:
      GH_COMMONS_READ_TOKEN: ${{ secrets.GH_COMMONS_READ_TOKEN }}
      digitalocean_access_token: ${{ secrets.DIGITALOCEAN_ACCESS_TOKEN }}
```

### Key details

- **`prepare` job**: sanitizes `github.ref_name` (replaces `/` with `-`) because Docker tags cannot contain slashes. Branch names like `feat/my-feature` become `feat-my-feature`.
- **`ref` input in `ship`**: pass `${{ github.ref_name }}` explicitly — the `version_tag` (sanitized) is used for Docker image tagging, but `ref` is needed for `git checkout`.
- **`package.yml`**: reads `.infra/build-args` via `.commons/shell/tasks/ci/args/resolve.sh` to determine the Dockerfile, build args, and build contexts. Passes secrets as `env=KEY=VALUE` for the Dockerfile `--mount=type=secret,id=env`.
- **Build args per project**: declared in `.infra/build-args` (see `skill:docker` for format).

## Nomenclatura de imagem vs serviço (monorepo K8s)

Em projetos com múltiplos módulos, a imagem no ECR e o serviço K8s são conceitos distintos:

| Conceito | Exemplo | Onde aparece |
|----------|---------|--------------|
| **Imagem** (ECR repo) | `nectar-charges-backend` | `package.yml`, kustomization `images:`, ECR |
| **Serviço** (K8s deployment) | `backend-api`, `frontend-web` | `api-deployment.yaml`, `kubectl get deployments` |

**Regras:**
- O nome da imagem segue `<app_name>-<module>` — onde `module` é `backend` ou `frontend` (descreve o stack/código, não o processo)
- O nome do serviço K8s descreve o processo que roda: `api`, `worker`, `web`
- Um mesmo módulo (`backend`) pode gerar múltiplos serviços K8s (`backend-api`, `backend-worker`) usando a mesma imagem
- O kustomization `images:` deve referenciar o nome completo da imagem ECR com registry

**No pipeline (`deploy-staging.yml`):**
```yaml
backend-package:
  uses: ibft-corp/pipelines/.github/workflows/package.yml@main
  with:
    app_name: nectar-charges
    module: backend          # → imagem: nectar-charges-backend
```

**No kustomization:**
```yaml
images:
  - name: 616795656532.dkr.ecr.us-east-1.amazonaws.com/nectar-charges-backend
    newTag: staging
```

**No deployment base:**
```yaml
image: 616795656532.dkr.ecr.us-east-1.amazonaws.com/nectar-charges-backend:latest
```

O kustomize substitui `nectar-charges-backend:latest` → `nectar-charges-backend:<version_tag>` via `kustomize edit set image`.

**ECR:** repositórios criados via `make registry.create` (não gerenciados pelo Terraform de ambiente — são globais).

## Migrate Job (K8s)

O migrate roda como um Kubernetes Job temporário antes do deploy. Regras críticas:

### Arquivo obrigatório
O `migrate.yml` do pipelines procura por `.infra/k8s/base/specs/migrate-job.yaml` relativo ao `working_directory` do módulo. Se não existir, o pipeline falha com erro explícito. **Não é opcional — crie o arquivo ou remova o step do pipeline.**

### Estrutura do migrate-job.yaml
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: migrate
spec:
  ttlSecondsAfterFinished: 120
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: migrate
          image: MIGRATE_IMAGE        # substituído pelo script
          command: ["entrypoint"]     # SEMPRE usar entrypoint, não run/migrate direto
          args: ["run/migrate"]
          env:
            - name: RAILS_ENV
              value: "MIGRATE_ENV"    # substituído pelo script com o environment
          envFrom:
            - secretRef:
                name: <app>-secrets
```

### Por que usar `entrypoint` e não `run/migrate` direto
O entrypoint do commons (`.commons/shell/tasks/docker/entrypoint.sh`) injeta `DATABASE_URL` a partir de `DATABASE_URL_FULLACCESS` antes de executar o comando. Sem o entrypoint, o `run/migrate` não tem acesso ao banco — o Rails não encontra `DATABASE_URL`.

### DATABASE_URL nos projetos K8s
O k8s secret armazena `DATABASE_URL_FULLACCESS` e `DATABASE_URL_READONLY` (gerados pelo Terraform). O Rails lê `DATABASE_URL` automaticamente. O entrypoint faz o mapeamento:
```sh
export DATABASE_URL="${DATABASE_URL_FULLACCESS}"
exec "$@"
```

**No `database.yml`**, use `url:` em vez de host/user/password separados para staging e production:
```yaml
staging:
  <<: *default
  url: <%= ENV["DATABASE_URL_FULLACCESS"] %>

production:
  <<: *default
  url: <%= ENV["DATABASE_URL_FULLACCESS"] %>
```

### Placeholders substituídos pelo run-migrate.sh
- `MIGRATE_IMAGE` → imagem com tag da versão
- `MIGRATE_ENV` → environment (`staging` ou `production`)

## How to proceed

1. Read all existing workflow files in `.github/workflows/`
2. Check for `secrets: inherit` — replace with explicit secrets
3. Check for lowercase secret names — rename to UPPERCASE
4. Check if project uses `packager.dev` in `Gemfile` — add `BUNDLE_PACKAGER__DEV` if so
5. Ensure every job that calls a reusable workflow passes the correct secrets
