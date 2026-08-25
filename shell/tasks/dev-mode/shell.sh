#!/usr/bin/env bash

set -euo pipefail

commons_dir="${COMMONS_DIR:-}"
if [ -z "$commons_dir" ]; then
  echo "COMMONS_DIR is not set" >&2
  exit 1
fi

service="${1:-}"
if [ -z "$service" ]; then
  echo "usage: shell.sh <service>" >&2
  exit 1
fi
shift || true

. "${commons_dir}/shell/helpers/devmode/compose.lib.sh"

load_build_args
load_project_env

ensure_docker_daemon

build_flag="$(load_build_flag)"

exec docker compose run ${build_flag} --rm --entrypoint sh "$service" "$@"
