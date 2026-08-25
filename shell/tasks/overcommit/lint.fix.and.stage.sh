#!/bin/bash

echo "Running install..."
make run.install
install_exit_code=$?

if [ $install_exit_code -ne 0 ]; then
  echo "Install failed!"
  exit 1
fi

# Run lint and fix with auto-correct
make run.lint.fix

# Check if lint and fix made any changes
if [ $? -eq 0 ] || [ $? -eq 1 ]; then # lint and fix returns 0 for no offenses, 1 for offenses (even if autocorrected)
  # Get a list of files that were modified by lint and fix and are currently staged
  MODIFIED_STAGED_FILES=$(git diff --name-only --cached)

  # Get a list of files that were modified by lint and fix but are not staged
  MODIFIED_UNSTAGED_FILES=$(git diff --name-only)

  # Add all modified files (staged and unstaged) to the stage
  if [ -n "$MODIFIED_STAGED_FILES" ] || [ -n "$MODIFIED_UNSTAGED_FILES" ]; then
    git add "$MODIFIED_STAGED_FILES" "$MODIFIED_UNSTAGED_FILES"
    echo "lint corrections added to stage."
  fi
fi

# Return lint and fix's exit code
exit $?