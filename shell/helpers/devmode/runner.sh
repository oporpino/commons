#!/usr/bin/env bash

set -euo pipefail

commons_dir="${COMMONS_DIR:-}"
if [ -z "$commons_dir" ]; then
  echo "COMMONS_DIR is not set" >&2
  exit 1
fi

mode="${1:-}"
command="${2:-}"
if [ -z "$mode" ] || [ -z "$command" ]; then
  echo "usage: runner.sh <mode> <command> [args...]" >&2
  exit 1
fi

shift 2 || true

"${commons_dir}/shell/tasks/dev-mode/context.sh"

. "${commons_dir}/shell/helpers/devmode/compose.lib.sh"

load_build_args
load_project_env

if [ "$mode" = "local" ]; then
  load_local_env
  project_dir="${PROJECT_DIR:-$(pwd)}"
  if [ "${DEV_DEPENDENCIES:-skip}" = "start" ]; then
    ensure_docker_daemon
    "${commons_dir}/shell/tasks/dev-mode/dependencies/start.sh"
  fi

  if [ -d "${project_dir}/.venv/bin" ]; then
    export VIRTUAL_ENV="${project_dir}/.venv"
    export PATH="${project_dir}/.venv/bin:${PATH}"
  fi

  localize_env_var DATABASE_URL database
  localize_env_var DB_URL database
  localize_env_var REDIS_URL cache
  localize_env_var CELERY_BROKER_URL messagebroker
fi

label="$(basename "$command")"
printf "Running %s (%s) ................................................\n" "$label" "$mode"

if [ "$mode" = "container" ]; then
  ensure_docker_daemon
  build_flag="$(load_build_flag)"
  service="${APP_SERVICE:-app}"
  exec docker compose run ${build_flag} --rm --remove-orphans --service-ports "$service" "$command" "$@"
fi

exec "$command" "$@"
