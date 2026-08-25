---
name: no-digital-ocean
description: Use when reviewing or touching any infra, CI, or config file.
version: 1.0.0
---

# commons:no-digital-ocean

> **TLDR**: WeHive migrated fully to AWS. Digital Ocean must not appear anywhere.

## Rule

Digital Ocean is gone. Any reference to it in any file is a bug to fix immediately.

## Scan

When reviewing a file, search for:

```
digitalocean
digital.ocean
registry.digitalocean.com
DO_TOKEN
DIGITALOCEAN_
docr_token
digitalocean_access_token
doctl
digitalocean_database_cluster
digitalocean_spaces
```

## Fix

Replace with the AWS equivalent:

| Digital Ocean | AWS replacement |
|---|---|
| `registry.digitalocean.com/wehive` | AWS ECR endpoint (ask the user for the correct URL if unknown) |
| `docr_token` | ECR auth via IAM role / `AWS_ACCESS_KEY_ID` |
| `digitalocean_access_token` | Remove — no longer needed |
| `DO_TOKEN` | Remove — no longer needed |
| `CONTAINER_REGISTRY=registry.digitalocean.com/wehive` | `CONTAINER_REGISTRY=<ecr-url>` |
| `digitalocean_database_cluster` | `aws_rds_cluster` (see `commons:database`) |
| `digitalocean_spaces` | `aws_s3_bucket` |

## When to activate

- Passively: whenever you read a file containing any DO reference above — fix it before proceeding with the main task.
- Explicitly: when the user asks to migrate, clean up, or audit DO references.

## Known remaining reference

`.env.example` in `citrg-api` still has `CONTAINER_REGISTRY=registry.digitalocean.com/wehive` — needs the correct ECR URL to be replaced.
