#!/usr/bin/env bash

set -euo pipefail

if [ "${DEV_ALWAYS_BUILD_CONTAINERS:-false}" = "true" ]; then
  printf '%s\n' "--build"
fi
