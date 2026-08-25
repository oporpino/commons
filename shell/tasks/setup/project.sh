#!/bin/bash
#
# Project setup runner.
# Executes shared and project setup scripts in a predictable order.
#

set -euo pipefail

[ -z "${COMMONS_DIR:-}" ] && echo "COMMONS_DIR is not set" >&2 && exit 1
stack="${STACK:-}"

. "${COMMONS_DIR}/shell/helpers/setup.sh"
. "${COMMONS_DIR}/shell/helpers/paths.sh"

setup_project_name="${SETUP_PROJECT_NAME:-$(basename "${PROJECT_DIR:-$(pwd)}")}"
setup_project_header "$setup_project_name"


setup_section "host"
host_setup_dir="${COMMONS_DIR}/shell/setup/host"
if [ -d "$host_setup_dir" ]; then
  for script in "$host_setup_dir"/*.sh; do
    [ -e "$script" ] || continue
    SETUP_CONTEXT=local bash "$script"
  done
fi

project_env="$(resolve_metadata_path "${PROJECT_DIR:-$(pwd)}" "shell/setup/environment.base.sh")"

if [ -f "$project_env" ]; then
  setup_section "environment"
  SETUP_CONTEXT=local bash "$project_env"
fi
