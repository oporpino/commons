#!/bin/bash -e

. "${COMMONS_DIR}/shell/helpers/setup.sh"

if [ -f ".tool-versions" ]; then
  setup_step_if_cmd \
    "installing asdf stack" \
    'bash "${COMMONS_DIR}/shell/tasks/setup/asdf.sh" --check >/dev/null 2>&1' \
    bash "${COMMONS_DIR}/shell/tasks/setup/asdf.sh"
fi
