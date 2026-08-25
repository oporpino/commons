#!/bin/bash
#
# WeHive Access Config Loader
# Resolves GitHub username → user alias and loads access.yml from infrastructure repo.
#
# Exports: GITHUB_USERNAME, USER_ALIAS, ACCESS_CONFIG
#
# Usage: source "${COMMONS_DIR}/shell/tasks/setup/access.sh"
#

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

GITHUB_USERNAME=""
USER_ALIAS=""
ACCESS_CONFIG=""

if ! command -v gh &>/dev/null; then
    echo -e "  ${RED}✗${NC} gh não instalado — acesso ao access.yml indisponível."
    return 0 2>/dev/null || exit 0
fi

if ! gh auth status &>/dev/null; then
    echo -e "  ${RED}✗${NC} gh não autenticado."
    echo -e "    Execute ${BOLD}gh auth login${NC} e rode o setup novamente."
    return 0 2>/dev/null || exit 0
fi

GITHUB_USERNAME=$(GH_PAGER=cat gh api user --jq '.login' 2>/dev/null || true)
if [ -z "${GITHUB_USERNAME}" ]; then
    echo -e "  ${RED}✗${NC} Não foi possível obter o usuário GitHub."
    return 0 2>/dev/null || exit 0
fi

ACCESS_CONTENT=$(GH_PAGER=cat gh api repos/ibft-corp/infrastructure/contents/config/access.yml \
    --jq '.content' 2>/dev/null || true)
if [ -z "${ACCESS_CONTENT}" ]; then
    echo -e "  ${RED}✗${NC} Não foi possível ler o access.yml do infrastructure."
    echo -e "    Verifique se ${BOLD}${GITHUB_USERNAME}${NC} tem acesso ao repo ibft-corp/infrastructure."
    return 0 2>/dev/null || exit 0
fi

ACCESS_CONFIG=$(echo "${ACCESS_CONTENT}" | base64 -d 2>/dev/null || true)
if [ -z "${ACCESS_CONFIG}" ]; then
    echo -e "  ${RED}✗${NC} Falha ao decodificar access.yml."
    return 0 2>/dev/null || exit 0
fi

if ! command -v yq &>/dev/null; then
    echo -e "  ${RED}✗${NC} yq não instalado — não é possível resolver alias."
    return 0 2>/dev/null || exit 0
fi

USER_ALIAS=$(echo "${ACCESS_CONFIG}" | yq e \
    '.users | to_entries | .[] | select(.value.github == "'"${GITHUB_USERNAME}"'") | .key' \
    - 2>/dev/null || true)

if [ -z "${USER_ALIAS}" ]; then
    echo -e "  ${YELLOW}!${NC} Usuário ${BOLD}${GITHUB_USERNAME}${NC} não encontrado no access.yml."
    echo -e "    Fale com o tech lead para ser adicionado."
    return 0 2>/dev/null || exit 0
fi

echo -e "  ${GREEN}✓${NC} Identidade: ${BOLD}${USER_ALIAS}${NC} (${GITHUB_USERNAME})"

export GITHUB_USERNAME USER_ALIAS ACCESS_CONFIG
