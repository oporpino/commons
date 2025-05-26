#!/usr/bin/env bash

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find .commons directory by going up until we find it
COMMONS_ROOT="$(cd "$SCRIPT_DIR" && while [ ! -d ".commons" ] && [ "$(pwd)" != "/" ]; do cd ..; done; pwd)"

# Source print functions with correct path
source "$COMMONS_ROOT/.commons/scripts/shell/print"
source "$COMMONS_ROOT/.commons/scripts/shell/logger"

# Get commit message from command line argument
commit_message="$1"

if [ -z "$commit_message" ]; then
    error "Commit message is required"
    info "Usage: make git.commit message=\"your commit message\""
    exit 1
fi

# Use execute script to handle the commit
"$(dirname "$0")/execute" "git commit -m \"$commit_message\""
