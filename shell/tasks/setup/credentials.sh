#!/bin/bash
#
# Verifica e configura credentials Rails (master.key / production.key)
# Usage: bash "${COMMONS_DIR}/shell/tasks/setup/credentials.sh [--no-prompt]
#

set -euo pipefail

BLUE='\033[0;34m'
YELLOW='\033[1;33m'
GRAY='\033[0;90m'
NC='\033[0m'

NO_PROMPT=false
for arg in "$@"; do
    [ "$arg" = "--no-prompt" ] && NO_PROMPT=true
done

if [ ! -f "Gemfile" ] || ! grep -q "rails" "Gemfile"; then
    exit 0
fi

MISSING_KEYS=()
[ -f "config/credentials.yml.enc" ] && [ ! -f "config/master.key" ] && \
    MISSING_KEYS+=("config/master.key")
[ -f "config/credentials/production.yml.enc" ] && [ ! -f "config/credentials/production.key" ] && \
    MISSING_KEYS+=("config/credentials/production.key")

if [ ${#MISSING_KEYS[@]} -eq 0 ]; then
    exit 0
fi

_ward_key_for_file() {
    local file="$1"
    local project; project="$(basename "$(pwd)")"
    case "$file" in
        config/master.key)                 echo "bootstrap:${project}.master_key" ;;
        config/credentials/production.key) echo "bootstrap:${project}.production_key" ;;
    esac
}

_try_ward() {
    local ward_path="$1"
    command -v ward &>/dev/null || return 1
    WARD_KEY_BOOTSTRAP="${WARD_KEY_BOOTSTRAP}" ward get "$ward_path" 2>/dev/null
}

STILL_MISSING=()
if [ -n "${WARD_KEY_BOOTSTRAP:-}" ]; then
    for file in "${MISSING_KEYS[@]}"; do
        ward_path="$(_ward_key_for_file "$file")"
        value="$(_try_ward "$ward_path" || true)"
        if [ -n "$value" ]; then
            mkdir -p "$(dirname "$file")"
            echo "$value" > "$file"
            chmod 600 "$file"
            echo -e "  ${GRAY}–${NC} $file (from ward)"
        else
            STILL_MISSING+=("$file")
        fi
    done
else
    STILL_MISSING=("${MISSING_KEYS[@]}")
fi

if [ ${#STILL_MISSING[@]} -eq 0 ]; then
    exit 0
fi

if [ "$NO_PROMPT" = true ] || [ "${CI:-}" = "true" ]; then
    echo -e "  ${GRAY}–${NC} skipping credentials (no-prompt mode)"
    exit 0
fi

echo ""
echo -e "      ${YELLOW}Credentials do projeto${NC}"
echo -e "      ──────────────────────────────────────────"
echo -e "      💡 Veja os valores em: cd \$BOOTSTRAP_DIR && ward tree"
echo ""
for file in "${STILL_MISSING[@]}"; do
    dir=$(dirname "$file")
    mkdir -p "$dir"
    printf "          ${BLUE}%s:${NC} " "$file"
    read -r value </dev/tty
    while [ -z "$value" ]; do
        printf "\033[1A\r          ${YELLOW}(required)${NC} ${BLUE}%s:${NC} " "$file"
        read -r value </dev/tty
    done
    echo "$value" > "$file"
    chmod 600 "$file"
done
