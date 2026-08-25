#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

ENV="${1:-}"  # staging | production | (empty = current namespace)

_namespaces_for_env() {
    local env="$1"
    kubectl get namespaces --no-headers -o custom-columns=NAME:.metadata.name 2>/dev/null \
        | grep -- "--${env}$"
}

_print_pods() {
    local ns="$1"
    echo -e "\n  ${BOLD}${ns}${NC}"
    kubectl get pods -n "$ns" 2>/dev/null || true
}

# No env given — show pods in current namespace
if [ -z "${ENV}" ]; then
    current_ns=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null || echo "")
    [ -z "$current_ns" ] && current_ns="default"
    _print_pods "$current_ns"
    echo -e ""
    exit 0
fi

# List namespaces for the given env
namespaces=()
while IFS= read -r ns; do
    [ -n "$ns" ] && namespaces+=("$ns")
done < <(_namespaces_for_env "$ENV")

if [ ${#namespaces[@]} -eq 0 ]; then
    echo -e "  Nenhum namespace encontrado para ${ENV}."
    exit 0
fi

# Single namespace — list directly
if [ ${#namespaces[@]} -eq 1 ]; then
    _print_pods "${namespaces[0]}"
    echo -e ""
    exit 0
fi

# Multiple namespaces — ask which one
echo -e "\n  ${BOLD}Namespace (${ENV}):${NC}\n"
i=1
for ns in "${namespaces[@]}"; do
    echo -e "    ${GREEN}${i})${NC} ${ns}"
    ((i++))
done
echo -e "    ${GREEN}${i})${NC} todos"
echo -e ""
printf "  Escolha [1-${i}]: "
read -r choice </dev/tty

if [ "${choice}" = "${i}" ]; then
    for ns in "${namespaces[@]}"; do
        _print_pods "$ns"
    done
else
    NS="${namespaces[$((choice-1))]}"
    [ -z "${NS}" ] && echo "Opção inválida." && exit 1
    _print_pods "$NS"
fi
echo -e ""
