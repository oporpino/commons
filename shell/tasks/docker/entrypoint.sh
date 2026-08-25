#!/bin/sh
# WeHive entrypoint — routes by RUNTIME_MODE, injects DATABASE_URL for db processes.

GREEN='\033[0;32m'
ORANGE='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

if [ "${RUNTIME_MODE}" = "web" ]; then
  printf "${GREEN}[web] frontend process${RESET}\n"
else
  if [ -n "${DATABASE_URL_FULLACCESS}" ]; then
    export DATABASE_URL="${DATABASE_URL_FULLACCESS}"
    printf "${ORANGE}[db] full access — DATABASE_URL set from DATABASE_URL_FULLACCESS${RESET}\n"
  else
    printf "${CYAN}[db] readonly mode — DATABASE_URL_FULLACCESS not set${RESET}\n"
  fi
fi

exec "$@"
