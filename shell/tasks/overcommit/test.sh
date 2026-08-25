#!/bin/bash

echo "Running install..."
make run.install
install_exit_code=$?

if [ $install_exit_code -ne 0 ]; then
  echo "Install failed!"
  exit 1
fi

# Use retest to run tests for changed files
# Try to run tests for files changed from the last commit
echo "Running tests for changed files using retest..."

# Run retest with diff from last commit and capture the output
output=$(make run.test 2>&1)
retest_exit_code=$?

echo "$output"

# Check if retest found and ran tests
if echo "$output" | grep -q "Tests selected:"; then
  # Tests were run, check if they passed
  if echo "$output" | grep -q "[1-9][0-9]* failures" || echo "$output" | grep -q "Failed examples:"; then
    echo "Tests failed!"
    exit 1
  else
    echo "All tests passed!"
    exit 0
  fi
else
  # No tests were found/run
  echo "No tests found for changed files"
  exit 0
fi