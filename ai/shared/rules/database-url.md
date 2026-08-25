# DATABASE_URL Contract

## Secret names (k8s / terraform)

| Secret key | Value | Purpose |
|---|---|---|
| `DATABASE_URL_READONLY` | URL with read-only user | Default for all pods |
| `DATABASE_URL_FULLACCESS` | URL with write user | Runtime pods only |

## How it works

The commons entrypoint (`shell/tasks/docker/entrypoint.sh`) runs before every container command.

- If `DATABASE_URL_FULLACCESS` is set → exports `DATABASE_URL=$DATABASE_URL_FULLACCESS` and logs **orange**: `[db] full access`
- If not set → keeps `DATABASE_URL=$DATABASE_URL_READONLY` and logs **cyan**: `[db] readonly mode`

The app always reads only `DATABASE_URL`. It never references `DATABASE_URL_READONLY` or `DATABASE_URL_FULLACCESS` directly.

## Pod behavior

| Pod | DATABASE_URL_FULLACCESS injected? | Effective DATABASE_URL |
|---|---|---|
| web, worker, beat | ✅ yes (via k8s secret) | full access |
| console (`mk console.staging`) | ❌ no (override by console.sh) | readonly |
| shell (`mk shell.staging`) | ❌ no | readonly |
| console admin (`mk console.staging.admin`) | ✅ yes (via k8s secret) | full access |

## console.sh override

`shell/tasks/infra/k8s/console.sh` overrides `DATABASE_URL` with `DATABASE_URL_READONLY` from the k8s secret, regardless of what the entrypoint would do.

## Terraform pattern (staging)

```hcl
DATABASE_URL_READONLY   = "postgresql://onion_readonly:...@host/db"
DATABASE_URL_FULLACCESS = "postgresql://onion:...@host/db"
```

## Terraform pattern (production — with replica)

```hcl
DATABASE_URL_READONLY   = "postgresql://onion:...@pool-replica-host/db"  # connection pool replica
DATABASE_URL_FULLACCESS = "postgresql://onion:...@primary-host/db"        # primary direct
```
