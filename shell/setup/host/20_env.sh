#!/bin/bash -e

. "${COMMONS_DIR}/shell/helpers/setup.sh"

if [ ! -f ".env" ] && [ -f ".env.example" ]; then
  cp ".env.example" ".env"
fi

if [ -f ".env" ]; then
  bash "${COMMONS_DIR}/shell/tasks/setup/env.sh" "$@" ".env"
fi

printf "  ✔ configure .env\n"
