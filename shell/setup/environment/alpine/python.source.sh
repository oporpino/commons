#!/bin/bash -e

. "${COMMONS_DIR}/shell/helpers/setup.sh"

venv_dir="${PROJECT_DIR:-$(pwd)}"/.venv
if [ "${SETUP_CONTEXT:-local}" = "docker" ]; then
  venv_dir="/source/.venv"
fi

if [ -d "$venv_dir" ]; then
  printf "  ✔ installing python venv\n"
elif [ "${SETUP_CONTEXT:-local}" = "docker" ]; then
  python3 -m venv "$venv_dir"
  printf "  ✔ installing python venv\n"
else
  setup_step "installing python venv" python3 -m venv "$venv_dir"
fi

export VIRTUAL_ENV="${venv_dir}"
export PATH="${venv_dir}/bin:${PATH}"
