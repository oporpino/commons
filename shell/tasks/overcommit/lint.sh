#!/bin/bash

echo "Running install..."
make run.install
install_exit_code=$?

if [ $install_exit_code -ne 0 ]; then
  echo "Install failed!"
  exit 1
fi

# Run lint with auto-correct
make run.lint

# Return lint's exit code
exit $?