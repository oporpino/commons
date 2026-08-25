#!/usr/bin/env bash

ensure_docker_daemon() {
  docker info > /dev/null 2>&1 && return 0
  if command -v colima > /dev/null 2>&1; then
    colima start 2>&1 || true
  fi
  for _ in $(seq 1 15); do
    docker info > /dev/null 2>&1 && return 0
    sleep 1
  done
  echo "error: docker daemon unavailable — try: colima delete && colima start" >&2
  exit 1
}

load_build_args() {
  eval "$(sh "${COMMONS_DIR}/shell/helpers/devmode/load-build-args.sh")"
}

load_project_env() {
  project_dir="${PROJECT_DIR:-$(pwd)}"
  if [ -f "${project_dir}/.env" ]; then
    set -a
    . "${project_dir}/.env"
    set +a
  fi
}

load_local_env() {
  project_dir="${PROJECT_DIR:-$(pwd)}"
  if [ -f "${project_dir}/.env" ]; then
    has_dev_dependencies=0
    if grep -Eq '^[[:space:]]*DEV_DEPENDENCIES=' "${project_dir}/.env"; then
      has_dev_dependencies=1
    fi
    set -a
    . "${project_dir}/.env"
    set +a
    if [ "$has_dev_dependencies" -eq 0 ]; then
      export DEV_DEPENDENCIES=skip
    fi
  fi
}

load_build_flag() {
  sh "${COMMONS_DIR}/shell/helpers/devmode/build-flag.sh"
}

localize_service_host() {
  local value="$1"
  local service_host="$2"
  [ -n "$value" ] || return 0
  printf '%s\n' "${value//$service_host:/localhost:}"
}

localize_env_var() {
  local name="$1"
  local service_host="$2"
  local value="${!name:-}"
  [ -n "$value" ] || return 0
  value="$(localize_service_host "$value" "$service_host")"
  export "$name=$value"
}
