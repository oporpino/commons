## Port Convention

All ports follow a 4-digit pattern: `<service><variation><app (2 digits)>`.
This allows all projects and services to run simultaneously without conflicts.

### Service digit

| Type            | Digit |
|-----------------|-------|
| Frontend        | 3     |
| API server      | 4     |
| Database        | 5     |
| Cache           | 6     |
| Message broker  | 7     |

### Variation digit

| Role                        | Digit |
|-----------------------------|-------|
| Main                        | 0     |
| Secondary (e.g. management) | 1     |

### Application (2 digits)

| Project              | Code |
|----------------------|------|
| Checkout             | 01   |
| CITRG                | 02   |
| Backoffice           | 03   |
| TRG Club             | 05   |
| Internship           | 06   |
| Onion                | 07   |
| Marketing Automation | 08   |
| Artificial Intelligence | 09   |
| Gateway              | 10   |
| Messenger            | 11   |
| Sistema de Cobrança  | 12   |

### Examples for Onion (07)

| Service                    | Port |
|----------------------------|------|
| Frontend                   | 3007 |
| API server                 | 4007 |
| Database                   | 5007 |
| Cache                      | 6007 |
| Message broker (AMQP)      | 7007 |
| Message broker (management)| 7107 |

### Examples for Messenger (11)

| Service    | Port |
|------------|------|
| API server | 4011 |
| Database   | 5011 |

### Port variable names

| Service | Variable |
|---|---|
| Frontend / web | `WEB_PORT` |
| API server | `API_PORT` |
| Database | `DATABASE_PORT` |
| Cache | `CACHE_PORT` |
| Message broker (AMQP) | `MESSAGEBROKER_PORT` |
| Message broker (management) | `MESSAGEBROKER_MANAGEMENT_PORT` |

### Rules

- Always use `WEB_PORT` and `API_PORT` — never `PORT` or `BACKEND_PORT`
- Never use `${VAR:-default}` in compose files — if a var is missing, the project must fail loudly
- Never hardcode default ports (5432, 6379, 5672, etc.) — always read from `.env`
- All vars must be declared in `.env` and `.env.example` — no fallbacks anywhere
- In `run/` scripts, use `${VAR:?VAR is not set}` to fail with a clear message if missing
