#!/bin/sh
# Prints current DATABASE_URL mode based on which secret key is being used.
# Usage: . db-mode.sh <key>  (key = DATABASE_URL_READONLY or DATABASE_URL_FULLACCESS)
ORANGE='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m'
if [ "${1}" = "DATABASE_URL_FULLACCESS" ]; then
  printf "${ORANGE}[db] full access — DATABASE_URL_FULLACCESS${RESET}\n"
else
  printf "${CYAN}[db] readonly — DATABASE_URL_READONLY${RESET}\n"
fi
