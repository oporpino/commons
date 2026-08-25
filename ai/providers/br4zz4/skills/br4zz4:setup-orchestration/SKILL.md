---
name: setup-orchestration
description: Use when designing or changing project/bootstrap setup structure across commons and project scopes.
version: 1.0.0
---

# commons:setup-orchestration

Use this skill when working on the setup/bootstrap layout for WeHive projects.

## Canonical split

- `setup/environment/*`
  - environment/tooling/bootstrap
  - must work in host and container
- `setup/dev/*`
  - dev configuration
  - `.env`, AI folders, local defaults, project-specific dev wiring

## Scope rules

- `.commons` owns shared mechanisms and shared setup steps.
- `.project` owns project-specific setup steps.
- Keep the same conceptual split in both places.
- Keep `shell/` as the technical namespace for shell implementation.

## Execution model

- `make setup` runs the shared project setup runner.
- Docker build runs the same setup contract in the build context.
- Shared setup should be discovered and executed by the runner, not hardcoded per project.

## Decision rules

- Put something in `.commons/setup/environment/*` when it is truly shared across projects.
- Put something in `.commons/setup/dev/*` when it is shared development configuration.
- Put something in `.project/setup/environment/*` when it is project-specific bootstrap that must work in host and container.
- Put something in `.project/setup/dev/*` when it is project-specific dev configuration.

## Notes

- Avoid creating `.project/bin/`.
- `run/` is the app entrypoint surface; `bin/` holds stack binstubs only.
- Prefer small scripts with one responsibility each.
