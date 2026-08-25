#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

CMD="${1:-list}"

_list_namespaces() {
    local current_ns
    current_ns=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null || echo "default")
    [ -z "$current_ns" ] && current_ns="default"

    local ctx
    ctx=$(kubectl config current-context 2>/dev/null || echo "")

    echo -e ""
    echo -e "  ${BOLD}Namespaces acessíveis${NC} (contexto: ${GREEN}${ctx}${NC})"
    echo -e ""

    while IFS= read -r ns; do
        if [ "${ns}" = "${current_ns}" ]; then
            echo -e "    ${WHITE}*${NC} ${GREEN}${ns}${NC}"
        else
            echo -e "      ${ns}"
        fi
    done < <(kubectl get namespaces --no-headers -o custom-columns=NAME:.metadata.name 2>/dev/null \
        | grep -- "--" | sort)

    echo -e ""
    echo -e "  ${YELLOW}Trocar namespace:${NC} make k8s.namespaces.use NS=<namespace>"
    echo -e ""
}

_use_namespace() {
    local ns="${2:-}"

    if [ -z "$ns" ]; then
        echo -e "\n  ${BOLD}Escolher namespace:${NC}\n"

        local namespaces=()
        while IFS= read -r n; do
            namespaces+=("$n")
        done < <(kubectl get namespaces --no-headers -o custom-columns=NAME:.metadata.name 2>/dev/null \
            | grep -- "--" | sort)

        if [ ${#namespaces[@]} -eq 0 ]; then
            echo -e "  Nenhum namespace encontrado."
            exit 1
        fi

        local current_ns
        current_ns=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null || echo "default")

        local i=1
        for n in "${namespaces[@]}"; do
            local marker=" "
            [ "$n" = "$current_ns" ] && marker="${WHITE}*${NC}"
            echo -e "    ${marker} ${GREEN}${i})${NC} ${n}"
            ((i++))
        done
        echo -e ""
        printf "  Escolha [1-$((i-1))]: "
        read -r choice </dev/tty

        ns="${namespaces[$((choice-1))]}"
        if [ -z "$ns" ]; then
            echo -e "  Opção inválida."
            exit 1
        fi
    fi

    local ctx
    ctx=$(kubectl config current-context 2>/dev/null)
    kubectl config set-context "${ctx}" --namespace="${ns}" >/dev/null
    echo -e "\n  ${GREEN}✓${NC} Namespace ativo: ${BOLD}${ns}${NC} (contexto: ${ctx})\n"
}

case "$CMD" in
    list) _list_namespaces ;;
    use)  _use_namespace "$@" ;;
    *)
        echo "Uso: namespace.sh [list|use] [NS=namespace]"
        exit 1
        ;;
esac
