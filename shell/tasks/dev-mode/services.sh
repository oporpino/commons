#!/usr/bin/env bash

set -euo pipefail

commons_dir="${COMMONS_DIR:-}"
if [ -z "$commons_dir" ]; then
  echo "COMMONS_DIR is not set" >&2
  exit 1
fi

. "${commons_dir}/shell/helpers/paths.sh"

project_dir="${PROJECT_DIR:-$(pwd)}"
services_file="$(resolve_metadata_path "$project_dir" "docker/compose/services.yml")"

[ -f "$services_file" ] || exit 0

awk '
  /^services:/ { in_services=1; next }
  in_services && /^  [A-Za-z0-9_.-]+:$/ {
    service=$1
    sub(/:$/, "", service)
    print service
  }
' "$services_file"
