#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

PROFILE="${1:-}"

# If profile passed directly, switch without menu
if [ -n "${PROFILE}" ]; then
    kubectl config use-context "${PROFILE}"
    echo -e "\n${GREEN}✓ Contexto ativo: ${PROFILE}${NC}"
    bash "${SCRIPT_DIR}/summary.sh"
    exit 0
fi

# List existing wehive contexts only
contexts=()
while IFS= read -r ctx; do
    contexts+=("$ctx")
done < <(kubectl config get-contexts -o name 2>/dev/null | grep -E "^wehive-|^devops$" | sort)

if [ ${#contexts[@]} -eq 0 ]; then
    echo -e "${RED}Nenhum contexto configurado. Execute: make k8s.init${NC}"
    exit 1
fi

current_ctx="$(kubectl config current-context 2>/dev/null || echo '')"

echo -e "\n  ${BOLD}Trocar contexto:${NC}\n"
i=1
for ctx in "${contexts[@]}"; do
    marker="$( [ "${ctx}" = "${current_ctx}" ] && echo "${WHITE}*${NC}" || echo ' ' )"
    case "$ctx" in
        wehive-*)  echo -e "    ${marker} ${GREEN}${i})${NC} ${ctx}" ;;
        devops)    echo -e "    ${marker} ${RED}${i})${NC} ${ctx}" ;;
        *)                 echo -e "    ${marker} ${i}) ${ctx}" ;;
    esac
    ((i++))
done
echo -e ""
printf "  Escolha [1-$((i-1))]: "
read -r choice </dev/tty

selected="${contexts[$((choice-1))]}"
if [ -z "${selected}" ]; then
    echo -e "${RED}Opção inválida.${NC}"
    exit 1
fi

kubectl config use-context "${selected}"
echo -e "\n${GREEN}✓ Contexto ativo: ${selected}${NC}"
bash "${SCRIPT_DIR}/summary.sh"
