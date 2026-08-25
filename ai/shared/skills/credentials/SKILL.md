---
name: credentials
description: Use when handling Rails credentials or ward secrets.
version: 3.0.0
---

# commons:credentials

> **TLDR**: Rails encrypts secrets in `*.yml.enc`, decrypted by ignored `*.key` files. Each project has its own **ward** vault for runtime env secrets; **bootstrap**'s ward vault is the single source of truth for every project's base keys (Rails `master_key`/`production_key`, `WARD_KEY_COMMONS`). A fresh clone restores its keys from bootstrap during `make setup`.

Whenever you need to read, write, or inspect any secret — use the **ward MCP tools** directly instead of running shell commands. They are always available and require no additional setup.

## The two layers

There are two independent secret systems. Do not conflate them.

| Layer | What it holds | Decrypted by | Lives in |
|-------|---------------|--------------|----------|
| **Rails credentials** | app secrets (SMTP, tokens) baked into the image | `master.key` / `production.key` | each project repo |
| **ward** | runtime env secrets (`DATABASE_URL`, API keys) | age key (`.ward.key` / `WARD_KEY_*`) | each project + `.commons` + `bootstrap` |

Rails keys are themselves stored as ward secrets in **bootstrap** — that is the bridge between the two layers.

## Scope convention

Every ward command targets secrets via a **scope**, either `secret-path` (all
vaults, unioned) or `vault:secret-path` (one vault).

```
infra.staging                           # every vault's infra.staging, unioned
trgclub:infra.staging.TF_VAR_api_url    # vault=trgclub, secret-path=infra.staging.TF_VAR_api_url
commons:infra.eks_access_key            # vault=commons,  secret-path=infra.eks_access_key
bootstrap:trgclub-api.master_key        # vault=bootstrap, secret-path=trgclub-api.master_key
```

- **Unqualified** (`secret-path` only) — **the default form**. Overlays the same
  path across every vault and unions the result, which is how a project picks up
  the shared `commons` values. Valid for `exec`/`secrets`/`tree`; ambiguous for `get`.
- **Qualified** (`vault:secret-path`) — targets one vault. Use it for the specific
  cases: reading a single value with `get`, or deliberately reaching into one vault
  (e.g. `bootstrap:trgclub-api.master_key`).
- A plain dot-separated string (`trgclub.infra.AWS_KEY`) is a **bare secret-path**, NOT a vault selector. Use `:` to qualify the vault.

### Ancestors are NOT inherited (ward 0.2.x)

Resolving a scope returns **only the values at that exact node**. Nothing from the
levels above it is included — not across vaults, not within one vault, not across
file ancestry:

```
commons.infra.TF_VAR_cloudflare_api_token     # shared
trgclub.infra.TF_VAR_rails_master_key         # cross-env
trgclub.infra.staging.TF_VAR_api_url          # env-specific

ward secrets infra.staging   →  ONLY TF_VAR_api_url
                                the two values above it are silently dropped
```

So a value only reaches a consumer if it sits at **exactly** the requested depth.
Two consequences when laying out a vault:

- Anything needed by `infra.<env>` must live at `<vault>.infra.<env>.*`, even if it
  is identical across environments.
- The unqualified union only works when both vaults put the values at the same
  depth (`commons.infra.X` unions with `<app>.infra.X`).

Do not model "shared at the parent, overrides one level deeper" — it does not
resolve. Tracked upstream in br4zz4/ward#19.

Colliding names are a **hard error** with no precedence: ward refuses to pick a
winner, and scope order does not break the tie. Duplicating a `commons` value into
a project vault therefore breaks the union rather than overriding it.

When calling MCP tools, pass the scope as-is via the `path` parameter. `dir` tells ward where to find `config.yaml` (vault paths and decrypt keys) — it does not change the scope syntax.

## Using ward MCP tools (preferred over shell)

All ward operations are available as MCP tools. Always pass `dir` when not in the project root.

### Read operations

```
ward_tree        → merged tree with source file and line per value
ward_get         → value at a dot-path (or full tree if no path)
ward_envs        → env vars that would be injected (useful to verify before exec)
ward_raw         → decrypted raw YAML of .ward file(s)
ward_inspect     → ancestry chain showing where each value comes from
ward_vaults      → list configured vault paths from .ward/config.yaml
ward_export      → merged secrets as shell export statements
```

### Write operations

```
ward_set         → set a single secret at a dot-path
ward_unset       → remove a single secret at a dot-path
ward_import      → encrypt YAML content into a .ward file
ward_new         → create a new vault (.ward file)
ward_config      → read or write a ward configuration value
```

### File secrets

```
ward_file_add    → store a file's raw content as a single encrypted secret
ward_file_extract → retrieve a file secret's raw content by filename
```

### Run with secrets

```
ward_exec        → execute a command with ward secrets injected as env vars
```

### Common patterns

```
# See everything in a project vault
ward_tree { "dir": "/path/to/trgclub" }

# Read a staging secret  (scope: trgclub:infra.staging.TF_VAR_api_url)
ward_get { "path": "trgclub:infra.staging.TF_VAR_api_url", "dir": "/path/to/trgclub" }

# Read a cross-env shared secret  (scope: trgclub:infra.AWS_ACCESS_KEY_ID)
ward_get { "path": "trgclub:infra.AWS_ACCESS_KEY_ID", "dir": "/path/to/trgclub" }

# Read from commons vault mounted by trgclub  (scope: commons:infra.eks_access_key)
ward_get { "path": "commons:infra.eks_access_key", "dir": "/path/to/trgclub" }

# Set a value
ward_set { "path": "trgclub:infra.staging.TF_VAR_api_url", "value": "https://...", "dir": "/path/to/trgclub" }

# Run a command with secrets injected for one env
ward_exec { "command": "terraform apply", "dir": "/path/to/trgclub" }

# Inspect bootstrap (single source of truth for all project keys)
ward_tree { "dir": "/path/to/bootstrap" }
ward_get  { "path": "bootstrap:trgclub-api.master_key", "dir": "/path/to/bootstrap" }
```

## Rails credentials

Each project encrypts secrets into committed `*.yml.enc` files. The matching `.key` files are **git-ignored** — losing them means losing the secrets.

```
config/
  credentials.yml.enc              ← base credentials
  master.key                       ← decrypts credentials.yml.enc      (gitignored)
  credentials/
    production.yml.enc             ← production-scoped credentials
    production.key                 ← decrypts production.yml.enc        (gitignored)
    development.yml.enc            ← development-scoped (key optional)
```

Edit credentials with the key present:

```sh
bin/rails credentials:edit                              # base
bin/rails credentials:edit --environment production     # production
```

## Setting up ward in a new project

Every new project gets two vaults by default: its own vault and the shared commons vault.

```yaml
# .ward/config.yaml
vaults:
  - name: <project-name>
    path: .ward/vaults/<project-name>

  - name: commons
    path: $COMMONS_DIR/.ward/vaults/commons
    encryption:
      key_env: WARD_KEY_COMMONS
```

Steps:

1. Create `.ward/config.yaml` with the template above (replace `<project-name>`).
2. Run `ward new <project-name>` to generate the first vault file and key.
3. Add `.ward/*.key` to `.gitignore`.
4. The commons vault is read-only for the project — secrets live in `$COMMONS_DIR/.ward/vaults/commons/` and are decrypted with `WARD_KEY_COMMONS`.

## ward per project

Each project has its own ward vault resolved from `.ward/config.yaml`. It holds runtime secrets injected at runtime — never Rails `.key` files.

The project's vault key resolves from `.ward/<project>.key` (local, gitignored) or `WARD_KEY_<NAME>` in CI. The commons vault is always mounted and decrypted with `WARD_KEY_COMMONS`.

## The bootstrap vault — base keys for every project

`bootstrap/.ward/vaults/bootstrap/` is the **single source of truth** for the keys that bootstrap every other project. Decrypted with the bootstrap key (`bootstrap/.ward/bootstrap.key` locally, or `WARD_KEY_BOOTSTRAP` in CI).

One `.ward` file per project, each under the `bootstrap.<project>` path:

```yaml
# bootstrap/.ward/vaults/bootstrap/checkout-api.ward
bootstrap:
  checkout-api:
    master_key: <value for config/master.key>
    production_key: <value for config/credentials/production.key>
```

Plus the keys that unlock the other vaults:

- `bootstrap.commons.key` → becomes `WARD_KEY_COMMONS` (unlocks the shared commons vault)
- `bootstrap.<project>.ward_key` → the project's own ward vault key (where present)
- `bootstrap.<project>.env.*` → extra bootstrap-time env

## How a fresh clone gets its keys

`make setup` invokes `.commons/shell/tasks/setup/credentials.sh`. For a Rails project it:

1. Detects missing `config/master.key` / `config/credentials/production.key`.
2. Maps each to a bootstrap path: `config/master.key → bootstrap.<project>.master_key`, `production.key → bootstrap.<project>.production_key`.
3. With `WARD_KEY_BOOTSTRAP` set, reads the value from bootstrap's vault, writes the `.key` file, and `chmod 600`s it.
4. If a value is missing and not in `--no-prompt`/CI mode, prompts interactively.

Flow: **bootstrap vault → `.key` files in the project → Rails decrypts `*.yml.enc`.**

## Rules

- **Never commit `.key` files or ward vault keys.** They are gitignored — keep it so.
- **Never print or paste a key value** into logs, PRs, or chat.
- When you generate or rotate a Rails key, store the new value under `bootstrap.<project>.master_key` / `production_key` in the bootstrap vault.
- Adding a new Rails project: create `bootstrap/.ward/vaults/bootstrap/<project>.ward` with its `master_key`/`production_key` before others clone it.
- Project-runtime secrets go in the **project's** ward vault; base/bootstrap keys go in **bootstrap's** vault. Do not mix them.
- In CI, provide keys via env (`WARD_KEY_BOOTSTRAP`, `WARD_KEY_COMMONS`, `RAILS_MASTER_KEY`), never files in the repo.
