#!/bin/bash
# WeHive Helpers Module
# Commands: wehive helpers env:load

wehive_helpers_env_load() {
    # Idempotent: skip if already loaded
    if [ -n "$WEHIVE_ENV_LOADED" ]; then
        return 0
    fi

    # Priority 1: Use PROJECT_ROOT if set by Makefile
    if [ -z "$PROJECT_ROOT" ]; then
        # Priority 2: Try git root from current directory
        if git rev-parse --show-toplevel &>/dev/null 2>&1; then
            PROJECT_ROOT="$(git rev-parse --show-toplevel)"
        else
            # Priority 3: Walk up from script location (wehive location)
            local dir="$(cd "$(dirname "$WEHIVE_SCRIPT")" && pwd)"
            while [ "$dir" != "/" ]; do
                if [ -f "$dir/.env" ] || [ -d "$dir/.git" ]; then
                    PROJECT_ROOT="$dir"
                    break
                fi
                dir="$(dirname "$dir")"
            done
        fi
    fi

    if [ -z "$PROJECT_ROOT" ]; then
        echo "❌ Could not find project root" >&2
        return 1
    fi

    # Echo all .env exports for eval
    if [ -f "$PROJECT_ROOT/.env" ]; then
        while IFS= read -r line; do
            # Skip empty lines and comments
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
            # Remove inline comments (everything after # outside quotes)
            line=$(echo "$line" | sed 's/[[:space:]]*#.*$//')
            # Echo the line (it already has 'export')
            echo "$line"
        done < "$PROJECT_ROOT/.env"
    fi

    # Echo special variables (set after .env to allow overrides if needed)
    echo "export PROJECT_ROOT='$PROJECT_ROOT'"
    echo "export WEHIVE_ENV_LOADED=1"
}

wehive_helpers() {
    local subcommand="$1"
    shift

    case "$subcommand" in
        env:load)
            wehive_helpers_env_load "$@"
            ;;
        *)
            echo "Unknown helpers subcommand: $subcommand" >&2
            echo "Available: env:load" >&2
            return 1
            ;;
    esac
}
