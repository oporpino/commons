#!/usr/bin/env bash

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find .commons directory by going up until we find it
COMMONS_ROOT="$(cd "$SCRIPT_DIR" && while [ ! -d ".commons" ] && [ "$(pwd)" != "/" ]; do cd ..; done; pwd)"

# Detect if we're running from inside .commons or from root
IS_COMMONS=$(basename $(pwd) | grep -q "^.commons$" && echo "true" || echo "false")

# Source print functions with correct path
source "$COMMONS_ROOT/.commons/scripts/shell/print"
source "$COMMONS_ROOT/.commons/scripts/shell/logger"

# Function to process submodules
process_submodules() {
    local base_dir="$1"
    local command="$2"
    for submodule in $(cd "$base_dir" && git submodule | awk '{print $2}'); do
        # Skip .commons when we're inside it
        [ "$IS_COMMONS" = "true" ] && [ "$submodule" = ".commons" ] && continue

        if [ -d "$base_dir/$submodule" ]; then
            print blue bold "Processing submodule"
            print "Executing command $(code "$command") in $base_dir/$submodule"
            new_line
            (cd "$base_dir/$submodule" && $command)
        fi
    done
}

# Function to process parent directory
process_parent() {
    local command="$1"
    print blue bold "Processing parent directory"
    print bold "Executing command $(code "$command") in $(basename $(cd .. && pwd))"
    new_line
    (cd .. && $command)
}

# Function to process current directory
process_current() {
    local command="$1"
    print blue bold "Processing current directory"
    print bold "Executing command $(code "$command") in $(basename $(pwd))"
    new_line
    $command
}

# Get command from parameter
command="$1"
h1 "Git Command Execution"
info "Processing $command in submodules and parent directories"
hr

# Always execute in current directory
process_current "$command"

if [ "$IS_COMMONS" = "true" ]; then
    # Inside .commons
    process_parent "$command"
    process_submodules ".." "$command"
else
    # In root directory
    process_submodules "." "$command"
fi

hr
success "Command execution completed"
