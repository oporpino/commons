#!/bin/bash

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

[ -z "${COMMONS_DIR:-}" ] && echo "COMMONS_DIR is not set. Run: source ~/.zshrc" && exit 1

echo -e "${BLUE}Updating commons from ${COMMONS_DIR}${NC} "
(cd "${COMMONS_DIR}" && git pull origin main)
echo -e "${GREEN}Done${NC}"
