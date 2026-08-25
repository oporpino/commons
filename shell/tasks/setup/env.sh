#!/bin/bash
#
# Substitui valores PROMPT_USER no .env
# Usage: bash "${COMMONS_DIR}/shell/tasks/setup/env.sh [--no-prompt] [env_file]
#

set -euo pipefail

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
GRAY='\033[0;90m'
NC='\033[0m'

NO_PROMPT=false
ENV_FILE=".env"

for arg in "$@"; do
    case "$arg" in
        --no-prompt) NO_PROMPT=true ;;
        *) ENV_FILE="$arg" ;;
    esac
done

if [ ! -f "$ENV_FILE" ]; then
    exit 0
fi

PROMPT_KEYS=$(grep -E "=PROMPT_USER$" "$ENV_FILE" | sed 's/=.*//' || true)

if [ -z "$PROMPT_KEYS" ]; then
    exit 0
fi

_try_ward_env() {
    local key="$1"
    local project; project="$(basename "$(pwd)")"
    command -v ward &>/dev/null || return 1
    WARD_KEY_BOOTSTRAP="${WARD_KEY_BOOTSTRAP}" ward get "bootstrap:${project}.env.${key}" 2>/dev/null
}

STILL_MISSING=""
if [ -n "${WARD_KEY_BOOTSTRAP:-}" ]; then
    while IFS= read -r key; do
        [ -z "$key" ] && continue
        value="$(_try_ward_env "$key" || true)"
        if [ -n "$value" ]; then
            sed -i.bak "s|^${key}=PROMPT_USER$|${key}=${value}|" "$ENV_FILE"
            rm -f "${ENV_FILE}.bak"
            echo -e "  ${GRAY}–${NC} ${key} (from ward)"
        else
            STILL_MISSING="${STILL_MISSING}${key}"$'\n'
        fi
    done <<< "$PROMPT_KEYS"
else
    STILL_MISSING="$PROMPT_KEYS"
fi

STILL_MISSING="${STILL_MISSING%$'\n'}"

if [ -z "$STILL_MISSING" ]; then
    exit 0
fi

if [ "$NO_PROMPT" = true ] || [ "${CI:-}" = "true" ]; then
    echo -e "  ${GRAY}–${NC} skipping PROMPT_USER vars (no-prompt mode)"
    exit 0
fi

echo ""
echo -e "      ${YELLOW}Setup das envs do projeto${NC}"
echo -e "      ──────────────────────────────────────────"
echo -e "      💡 Veja os valores em: cd \$BOOTSTRAP_DIR && ward tree"
echo ""
while IFS= read -r key <&3; do
    [ -z "$key" ] && continue
    printf "          ${BLUE}%s:${NC} " "$key"
    read -r value </dev/tty
    while [ -z "$value" ]; do
        printf "\033[1A\r          ${YELLOW}(required)${NC} ${BLUE}%s:${NC} " "$key"
        read -r value </dev/tty
    done
    sed -i.bak "s|^${key}=PROMPT_USER$|${key}=${value}|" "$ENV_FILE"
    rm -f "$ENV_FILE.bak"
done 3<<< "$STILL_MISSING"
