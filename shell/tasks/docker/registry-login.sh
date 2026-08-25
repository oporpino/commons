#!/usr/bin/env bash
set -euo pipefail

CYAN=$'\033[0;36m'
RED=$'\033[0;31m'
NC=$'\033[0m'

CONTAINER_REGISTRY="${CONTAINER_REGISTRY:-}"
[ -z "$CONTAINER_REGISTRY" ] && exit 0

registry_host="$(echo "$CONTAINER_REGISTRY" | cut -d'/' -f1)"

echo "$registry_host" | grep -q "amazonaws.com" || exit 0

if grep -q "$registry_host" "${HOME}/.docker/config.json" 2>/dev/null; then
  echo -e "  ${CYAN}✓ ${registry_host}${NC}"
  exit 0
fi

echo -e "  ${RED}✗ ${registry_host} not authenticated.${NC}"
echo "  Run the setup script first:"
echo ""
echo "    bash \"${COMMONS_DIR}/environment/init.sh\""
echo ""
exit 1
