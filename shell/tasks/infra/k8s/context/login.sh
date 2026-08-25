#!/bin/bash
set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMMONS_DIR="$(cd "${SCRIPT_DIR}/../../../../.." && pwd)"

if [ -z "${WARD_KEY_COMMONS:-}" ]; then
    if [ -f "${COMMONS_DIR}/.ward/commons.key" ]; then
        WARD_KEY_COMMONS=$(cat "${COMMONS_DIR}/.ward/commons.key")
        export WARD_KEY_COMMONS
    else
        echo -e "  ${RED}✗${NC} WARD_KEY_COMMONS não configurado." >&2
        exit 1
    fi
fi

aws_bin=$(command -v aws 2>/dev/null) || {
    echo -e "  ${RED}✗${NC} aws CLI não encontrado no PATH." >&2
    exit 1
}

result=$(cd "${COMMONS_DIR}" && ward exec commons:infra -- sh -c '
    printf "%s\n%s\n%s" \
        "$eks_access_key" \
        "$eks_secret_key" \
        "$eks_role_arn"
' 2>/dev/null) || {
    echo -e "  ${RED}✗${NC} Falha ao decriptar vault commons." >&2
    exit 1
}

base_ak=$(echo "${result}" | sed -n '1p')
base_sk=$(echo "${result}" | sed -n '2p')
base_role=$(echo "${result}" | sed -n '3p')

_tmp=$(mktemp)
sed '/^# --- Entry point ---/,$d' "${SCRIPT_DIR}/setup.sh" > "${_tmp}"
# shellcheck source=/dev/null
source "${_tmp}"
rm -f "${_tmp}"
_ensure_wehive_eks_profile "${base_ak}" "${base_sk}" "${base_role}"

echo -e "${GREEN}✓ Credenciais EKS renovadas.${NC}"
