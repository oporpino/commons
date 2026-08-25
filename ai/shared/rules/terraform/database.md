## connection pools

- sempre provisionar connection pools PgBouncer junto com o cluster de banco — nunca expor conexão direta para pods de aplicação
- usar modo `transaction` para todos os pools de aplicação
- criar dois pools por ambiente: um fullaccess (`onion` user) e um readonly (`onion_readonly` user)
- tamanho do pool: `floor(max_connections * 0.8 / num_deployments)` — deixar margem para superuser e jobs
- os secrets `DATABASE_URL_FULLACCESS` e `DATABASE_URL_READONLY` devem sempre apontar para os pools (porta PgBouncer), nunca direto ao banco
- a única exceção é o `migrate-job`: deve usar conexão direta ao banco (porta PostgreSQL) pois DDL e prepared statements não são suportados em modo `transaction`
- os jobs de grant SQL (`onion_readonly_grant`) devem ter `depends_on` nos pools — eles rodam com `doadmin` e precisam de slots livres que só existem após os pools absorverem as conexões da aplicação

## ports

| Port | Purpose |
|---|---|
| `25060` | Direct PostgreSQL — migrate-job only |
| `25061` | PgBouncer — all application pods |

## terraform resource pattern

```hcl
resource "digitalocean_database_connection_pool" "app" {
  cluster_id = digitalocean_database_cluster.app.id
  name       = "app"
  mode       = "transaction"
  size       = 10
  db_name    = digitalocean_database_db.app.name
  user       = digitalocean_database_user.app.name
}

resource "digitalocean_database_connection_pool" "app_readonly" {
  cluster_id = digitalocean_database_cluster.app.id
  name       = "app-readonly"
  mode       = "transaction"
  size       = 10
  db_name    = digitalocean_database_db.app.name
  user       = digitalocean_database_user.app_readonly.name
}
```

## depends_on para jobs SQL

jobs que executam SQL direto no banco (grants, timezone, etc.) devem depender dos pools para garantir que slots estejam disponíveis:

```hcl
depends_on = [
  digitalocean_database_connection_pool.app,
  digitalocean_database_connection_pool.app_readonly,
]
```
