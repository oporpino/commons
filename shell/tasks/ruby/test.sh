#!/bin/bash

# Generic Ruby test runner script that supports both RSpec and Minitest
# Supports both sequential and parallel test execution
#
# Usage:
#   test.sh --framework [rspec|minitest] [--parallel] [test paths/files...]
#
# Examples:
#   test.sh --framework rspec
#   test.sh --framework rspec spec/models
#   test.sh --framework rspec --parallel
#   test.sh --framework rspec --parallel spec/models
#   test.sh --framework minitest test/models/user_test.rb

set -e

# Initialize variables
framework=""
parallel=false
test_args=()

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --framework)
      framework="$2"
      shift 2
      ;;
    --parallel)
      parallel=true
      shift
      ;;
    *)
      test_args+=("$1")
      shift
      ;;
  esac
done

# Validate framework argument
if [[ -z "$framework" ]]; then
  echo "Error: --framework argument is required (rspec or minitest)"
  exit 1
fi

if [[ "$framework" != "rspec" && "$framework" != "minitest" ]]; then
  echo "Error: --framework must be either 'rspec' or 'minitest', got: $framework"
  exit 1
fi

# Validate test path arguments (must be existing files or directories)
for arg in "${test_args[@]}"; do
  if [[ ! -e "$arg" ]]; then
    echo "Error: test path not found: '$arg' (expected a file or directory)"
    exit 1
  fi
done

# Determine the test type for parallel_test command
if [[ "$framework" == "rspec" ]]; then
  test_type="rspec"
  sequential_command="bundle exec rspec"
elif [[ "$framework" == "minitest" ]]; then
  test_type="test"
  sequential_command="bundle exec rails test"
fi

# Execute tests
if [[ "$parallel" == true ]]; then
  # Run tests in parallel
  echo "Running tests in parallel mode with framework: $framework"
  bundle exec parallel_test -t "$test_type" "${test_args[@]}"
else
  # Run tests sequentially
  echo "Running tests sequentially with framework: $framework"
  $sequential_command "${test_args[@]}"
fi
