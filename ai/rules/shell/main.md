## general

- always use `#!/bin/bash` shebang
- use `set -euo pipefail` at the top of every script
- prefer functions over inline logic
- unset environment variables at the end of scripts that set them
- always quote variables: `"$var"`, `"${var}"`

## naming

- functions: snake_case verbs (e.g. `check_dependency`, `install_package`)
- variables: UPPER_CASE for env/global, lower_case for local
- files: snake_case or kebab-case

## structure

- one responsibility per script
- check for existing installations before proceeding
- use meaningful exit codes (0 = success, 1 = error)
- organize related scripts in subdirectories

## best practices

- prefer `[[ ]]` over `[ ]` for conditionals
- use `$(command)` instead of backticks
- avoid parsing `ls` output — use globs
- use `printf` instead of `echo` for formatted output
- use `local` for function-scoped variables
- avoid global state — pass values via parameters or return codes
