#!/bin/sh

set -eu

if [ "${DEV_MODE:-container}" != "local" ]; then
  echo "test helper is for local mode only" >&2
  exit 1
fi

"${COMMONS_DIR:?COMMONS_DIR is not set.}/shell/tasks/dev-mode/context.sh"
"${COMMONS_DIR}/shell/tasks/dev-mode/dependencies/start.sh"
printf "Run Tests .................................................................\n"
exec run/test "$@"
