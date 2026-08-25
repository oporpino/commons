#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT=$(git rev-parse --show-toplevel)
cd "${PROJECT_ROOT}"

echo -e "${BLUE}Select environment:${NC}"
echo "  1) staging"
echo "  2) production"
read -p "Choice [1]: " choice
choice=${choice:-1}

if [ "$choice" = "1" ]; then
    make infra.staging.apply
elif [ "$choice" = "2" ]; then
    make infra.production.apply
else
    echo -e "${RED}Invalid choice${NC}"; exit 1
fi
