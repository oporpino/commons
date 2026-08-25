#!/bin/sh

set -eu

if [ "${DEV_MODE:-container}" != "local" ]; then
  exit 0
fi

if [ "${DEV_DEPENDENCIES:-start}" != "start" ]; then
  exit 0
fi

printf "Starting Development Dependencies ..........................................\n"
docker compose up -d --wait database cache messagebroker
