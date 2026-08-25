#!/usr/bin/env bash

set -euo pipefail

dev_mode="${DEV_MODE:-container}"
dependencies="start"

if [ "$dev_mode" = "local" ]; then
  dependencies="${DEV_DEPENDENCIES:-start}"
fi

printf "Development Context .........................................................\n"
printf "dev mode: %s\n" "$dev_mode"
printf "dependencies: %s\n" "$dependencies"
