#!/bin/bash
# Shows available contexts and useful commands.

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
WHITE='\033[1;37m'
BOLD='\033[1m'
B='\033[0;94m'
NC='\033[0m'

TARGET_ALIAS="${1:-}"
IS_OWNER="${2:-}"

current_ctx="$(kubectl config current-context 2>/dev/null || echo '')"

# Collect all relevant contexts
all_ctxs=()
while IFS= read -r ctx; do
    all_ctxs+=("$ctx")
done < <(kubectl config get-contexts -o name 2>/dev/null \
    | grep -E "^wehive-|^devops$" | sort)

# Calculate max width for column alignment
max_len=0
for ctx in "${all_ctxs[@]}"; do
    [ ${#ctx} -gt $max_len ] && max_len=${#ctx}
done
col=$((max_len + 2))

_row() {
    local ctx="$1" color="$2" desc="$3"
    local marker pad
    marker="$( [ "${ctx}" = "${current_ctx}" ] && echo "${WHITE}*${NC}" || echo ' ' )"
    pad=$(printf '%*s' $((col - ${#ctx})) '')
    echo -e "    ${marker} ${color}${ctx}${NC}${pad}— ${desc}"
}

echo -e ""
echo -e "  ${BOLD}Contextos disponíveis agora:${NC}"
echo -e ""

if [ ${#all_ctxs[@]} -eq 0 ]; then
    echo -e "    ${YELLOW}Nenhum contexto configurado ainda.${NC}"
    echo -e "    Execute: ${BOLD}make k8s.init${NC}"
else
    for ctx in "${all_ctxs[@]}"; do
        case "$ctx" in
            wehive-*)
                alias="${ctx#wehive-}"
                if [ -n "${IS_OWNER}" ] && [ "${alias}" = "${TARGET_ALIAS}" ]; then
                    prod_desc="production: exec liberado (owner)"
                else
                    prod_desc="production: logs e pods, sem exec"
                fi
                _row "${ctx}" "${GREEN}" "staging: acesso total | ${prod_desc}"
                ;;
            devops) _row "${ctx}" "${RED}" "acesso total ao cluster (use com cuidado)" ;;
        esac
    done
fi

echo -e ""
echo -e "  ${BOLD}Comandos úteis:${NC}"
echo -e ""
echo -e "    ${BOLD}make k8s.context${NC}                   — trocar contexto"
echo -e "    ${BOLD}make k8s.context.list${NC}              — listar contextos e summary"
echo -e "    ${BOLD}make k8s.pods.staging${NC}              — listar pods de staging"
echo -e "    ${BOLD}make k8s.pods.production${NC}           — listar pods de production"
echo -e "    ${BOLD}make console.staging${NC}               — shell no pod de staging"
echo -e "    ${BOLD}make console.production${NC}            — shell no pod de produção"
echo -e "    ${YELLOW}${BOLD}make console.staging.fullaccess${NC}    — shell com acesso total ao DB (staging)"
echo -e "    ${YELLOW}${BOLD}make console.production.fullaccess${NC} — shell com acesso total ao DB (produção)"
echo -e ""
echo -e "  ${B}┌──────────────────────────────────────────────┐${NC}"
echo -e "  ${B}│${NC}  k9s abre na lista de namespaces             ${B}│${NC}"
echo -e "  ${B}│${NC}  k9s: /staging — filtrar e entrar no seu app ${B}│${NC}"
echo -e "  ${B}│${NC}  k9s: :ctx — trocar contexto                 ${B}│${NC}"
echo -e "  ${B}└──────────────────────────────────────────────┘${NC}"
echo -e ""
echo -e "  ${YELLOW}Sem acesso ao namespace \`default\`? É normal.${NC}"
echo -e "  Você acessa apenas ${BOLD}<app>--staging${NC} e ${BOLD}<app>--production${NC} dos seus projetos."
echo -e "  \`access denied\` em ${BOLD}default${NC} ou em namespace de outro projeto é isolamento — não erro de setup."
echo -e ""
echo -e "  ${YELLOW}Precisa de acesso a um sistema que não aparece aqui?${NC}"
echo -e "  Fale com o ${BOLD}tech lead${NC} ou ${BOLD}devops${NC} para ser adicionado ao projeto."
echo -e ""
