---
name: br4zz4:local-development
description: Use when testing local apps with subdomains.
version: 1.0.0
---

# commons:local-development

> **TLDR**: Prefer `lvh.me` over `localhost` when testing local apps that rely on subdomains or host-based multi-tenancy.

## Rule

When manually testing a local application that uses subdomains or host-based routing, use:

```
http(s)://<subdomain>.lvh.me:<port>
```

## Why

- `lvh.me` resolves every subdomain to `127.0.0.1`.
- `localhost` does **not** expose subdomains in most browsers and frameworks.
- Using a real subdomain keeps multi-tenant detection, host authorization, and cookies working exactly like production.

## Examples

| Scenario | URL |
|---|---|
| Plain local server | `http://lvh.me:4009` |
| With subdomain `escolamagica` | `http://escolamagica.lvh.me:4009` |
| With custom subdomain | `http://<subdomain>.lvh.me:<SERVER_PORT>` |

## Port

Always use the project's actual local dev port (e.g. `SERVER_PORT` from `.env`).

## Caveat

`lvh.me` requires DNS resolution. If you are fully offline and the DNS cache is empty, it may fail. In that rare case, add an entry to `/etc/hosts` or use `nip.io`.
