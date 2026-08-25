#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

PROFILE_DIR="${HOME}/.config/wehive"

_ensure_aws_profile() {
    local alias="$1"
    local profile="wehive-dev-${alias}"
    local role_arn="arn:aws:iam::${SHARED_ACCOUNT_ID}:role/eks-dev-${alias}"

    if grep -q "\[profile ${profile}\]" "${HOME}/.aws/config" 2>/dev/null; then
        return 0
    fi

    printf "\n[profile %s]\nrole_arn       = %s\nsource_profile = wehive-mgmt\nregion         = us-east-1\n" \
        "${profile}" "${role_arn}" >> "${HOME}/.aws/config"
    echo -e "  ${GREEN}✓${NC} Perfil AWS criado: ${profile}"
}

_ensure_wehive_eks_profile() {
    local access_key="$1"
    local secret_key="$2"
    local role_arn="$3"
    local base_profile="wehive-eks-base"
    local profile="wehive-eks"
    mkdir -p "${HOME}/.aws"

    # Base credentials profile (management account user)
    if grep -q "\[${base_profile}\]" "${HOME}/.aws/credentials" 2>/dev/null; then
        sed -i.bak "/^\[${base_profile}\]/,/^\[/{ s/aws_access_key_id.*/aws_access_key_id = ${access_key}/; s/aws_secret_access_key.*/aws_secret_access_key = ${secret_key}/; }" \
            "${HOME}/.aws/credentials" 2>/dev/null && rm -f "${HOME}/.aws/credentials.bak"
    else
        printf "\n[%s]\naws_access_key_id = %s\naws_secret_access_key = %s\n" \
            "${base_profile}" "${access_key}" "${secret_key}" >> "${HOME}/.aws/credentials"
    fi

    # Role-assuming profile (shared account TerraformRole)
    if ! grep -q "\[profile ${profile}\]" "${HOME}/.aws/config" 2>/dev/null; then
        printf "\n[profile %s]\nrole_arn = %s\nsource_profile = %s\nregion = us-east-1\n" \
            "${profile}" "${role_arn}" "${base_profile}" >> "${HOME}/.aws/config"
    else
        sed -i.bak "/^\[profile ${profile}\]/,/^\[/{ s|role_arn.*|role_arn = ${role_arn}|; }" \
            "${HOME}/.aws/config" 2>/dev/null && rm -f "${HOME}/.aws/config.bak"
    fi

    chmod 600 "${HOME}/.aws/credentials" 2>/dev/null || true
}

_eks_setup_session() {
    # Uses ward exec to inject commons:infra secrets, then assumes TerraformRole.
    # Exports session credentials + cluster config for use in _eks_run.

    # Verify ward can decrypt the commons vault before proceeding.
    local ward_check
    ward_check=$(cd "${COMMONS_DIR}" && ward exec commons:infra -- sh -c 'echo ok' 2>&1)
    if [ "${ward_check}" != "ok" ]; then
        echo -e "  ${RED}✗${NC} Falha ao decriptar vault commons. WARD_KEY_COMMONS incorreta ou desatualizada." >&2
        echo -e "  Execute o setup novamente ou atualize a key via 1Password (WARD KEY | COMMONS)." >&2
        return 1
    fi

    local result
    result=$(cd "${COMMONS_DIR}" && ward exec commons:infra -- sh -c '
        printf "%s\n%s\n%s\n%s\n%s\n%s" \
            "$eks_access_key" \
            "$eks_secret_key" \
            "$eks_role_arn" \
            "$eks_cluster_name" \
            "$eks_account_id" \
            "$eks_region"
    ' 2>/dev/null) || return 1

    local base_ak base_sk base_role
    base_ak=$(echo "${result}" | sed -n '1p')
    base_sk=$(echo "${result}" | sed -n '2p')
    base_role=$(echo "${result}" | sed -n '3p')

    # Create/update wehive-eks AWS profile so kubeconfig exec plugin uses it
    _ensure_wehive_eks_profile "${base_ak}" "${base_sk}" "${base_role}"

    # Resolve aws absolute path in the current shell (where PATH is correct) so
    # sh -c inside ward exec doesn't need to inherit a full login PATH.
    local aws_bin
    aws_bin=$(command -v aws 2>/dev/null) || {
        echo -e "  ${RED}✗${NC} aws CLI não encontrado no PATH." >&2
        return 1
    }

    # Now assume TerraformRole for the session
    result=$(cd "${COMMONS_DIR}" && ward exec commons:infra -- sh -c '
        CREDS=$(AWS_ACCESS_KEY_ID="$eks_access_key" \
                AWS_SECRET_ACCESS_KEY="$eks_secret_key" \
            "'"${aws_bin}"'" sts assume-role \
                --role-arn "$eks_role_arn" \
                --role-session-name k8s-init \
                --region "$eks_region" \
                --query "Credentials" \
                --output json 2>/dev/null) || exit 1
        printf "%s\n%s\n%s\n%s\n%s\n%s" \
            "$(echo $CREDS | jq -r .AccessKeyId)" \
            "$(echo $CREDS | jq -r .SecretAccessKey)" \
            "$(echo $CREDS | jq -r .SessionToken)" \
            "$eks_cluster_name" \
            "$eks_account_id" \
            "$eks_region"
    ' 2>/dev/null) || return 1

    export EKS_SESSION_AK EKS_SESSION_SK EKS_SESSION_ST EKS_CLUSTER_NAME EKS_SHARED_ACCOUNT_ID AWS_REGION
    EKS_SESSION_AK=$(echo "${result}" | sed -n '1p')
    EKS_SESSION_SK=$(echo "${result}" | sed -n '2p')
    EKS_SESSION_ST=$(echo "${result}" | sed -n '3p')
    EKS_CLUSTER_NAME=$(echo "${result}" | sed -n '4p')
    EKS_SHARED_ACCOUNT_ID=$(echo "${result}" | sed -n '5p')
    AWS_REGION=$(echo "${result}" | sed -n '6p')
}

_eks_run() {
    AWS_ACCESS_KEY_ID="${EKS_SESSION_AK}" \
    AWS_SECRET_ACCESS_KEY="${EKS_SESSION_SK}" \
    AWS_SESSION_TOKEN="${EKS_SESSION_ST}" \
    "$@"
}

_bootstrap_devops_context() {
    echo -e "  Atualizando contexto devops..."
    local err rc
    err=$(aws eks update-kubeconfig \
        --name "${EKS_CLUSTER_NAME}" \
        --region "${AWS_REGION}" \
        --alias devops \
        --profile "wehive-eks" 2>&1)
    rc=$?
    if [ "${rc}" -ne 0 ]; then
        echo -e "  ${RED}✗${NC} Falha ao obter kubeconfig do EKS (aws exit ${rc})"
        echo -e "  ${RED}  ${err}${NC}"
        return 1
    fi
    echo -e "  ${GREEN}✓${NC} Contexto: ${BOLD}devops${NC}"
}

_build_iam_context() {
    local alias="$1"
    local context_name="$2"
    local default_ns="$3"
    local role_arn="arn:aws:iam::${EKS_SHARED_ACCOUNT_ID}:role/eks-dev-${alias}"

    # Use wehive-eks profile (base credentials) + role-arn so the kubeconfig
    # exec plugin auto-refreshes tokens without depending on the shell environment.
    local err rc
    err=$(aws eks update-kubeconfig \
        --name "${EKS_CLUSTER_NAME}" \
        --region "${AWS_REGION}" \
        --alias "${context_name}" \
        --role-arn "${role_arn}" \
        --profile "wehive-eks" 2>&1)
    rc=$?
    if [ "${rc}" -ne 0 ]; then
        echo -e "  ${RED}✗${NC} Falha ao configurar contexto ${context_name} (aws exit ${rc})"
        echo -e "  ${RED}  ${err}${NC}"
        return 1
    fi

    [ -n "${default_ns}" ] && \
        kubectl config set-context "${context_name}" --namespace="${default_ns}" &>/dev/null

    echo -e "  ${GREEN}✓${NC} Contexto: ${BOLD}${context_name}${NC}"
}

_warn_elevated() {
    echo -e ""
    echo -e "  ${RED}${BOLD}⚠️  ATENÇÃO${NC}"
    echo -e ""
    echo -e "  Você está prestes a ativar acesso ${RED}${BOLD}admin total${NC} ao cluster."
    echo -e "  Este contexto permite qualquer operação em qualquer namespace."
    echo -e ""
    echo -e "  Erros cometidos neste contexto podem afetar usuários reais."
    echo -e "  Em caso de dúvida, consulte o ${BOLD}\033[0;35mtech-lead${NC} antes de continuar."
    echo -e ""
    printf "  Confirma? [y/N]: "
    read -r confirm </dev/tty
    if [ "${confirm}" != "y" ] && [ "${confirm}" != "Y" ]; then
        echo -e "  Cancelado."
        return 1
    fi
    return 0
}

_show_summary() {
    local target="${1:-}"
    local is_owner="${2:-}"
    bash "${SCRIPT_DIR}/summary.sh" "${target}" "${is_owner}"
}

_cleanup_stale_contexts() {
    local alias="${1:-}"
    local pattern
    if [ -z "${alias}" ]; then
        pattern="^wehive-|^developer-|^arn:aws:eks:"
    else
        pattern="^wehive-${alias}$|^wehive-${alias}-|^developer-|^arn:aws:eks:"
    fi
    while IFS= read -r ctx; do
        kubectl config delete-context "${ctx}" &>/dev/null || true
    done < <(kubectl config get-contexts -o name 2>/dev/null | grep -E "${pattern}" || true)
}

_ensure_k9s_default_view() {
    local config_dir="${K9S_CONFIG_DIR:-${HOME}/.config/k9s}"
    local config="${config_dir}/config.yaml"

    if ! command -v yq &>/dev/null; then
        echo -e "  ${YELLOW}!${NC} yq não encontrado — pulei o ajuste do k9s (defaultView)."
        return 0
    fi

    mkdir -p "${config_dir}"
    [ -f "${config}" ] || printf 'k9s:\n  defaultView: ns\n' > "${config}"

    if ! yq e -i '.k9s.defaultView = "ns"' "${config}" 2>/dev/null; then
        echo -e "  ${YELLOW}!${NC} Não consegui ajustar o k9s (defaultView) — siga usando :ns manualmente."
        return 0
    fi

    echo -e "  ${GREEN}✓${NC} k9s abre na lista de namespaces"
}

_setup_context_for() {
    local target_alias="$1"

    # Validate target exists in access.yml
    local exists
    exists=$(echo "${ACCESS_CONFIG}" | yq e \
        '.users | has("'"${target_alias}"'")' - 2>/dev/null || true)
    if [ "${exists}" != "true" ]; then
        echo -e "  ${RED}✗${NC} Usuário '${target_alias}' não encontrado no access.yml."
        exit 1
    fi

    echo -e "  Configurando contexto para ${BOLD}${target_alias}${NC}..."

    if ! _build_iam_context "${target_alias}" "wehive-${target_alias}" ""; then
        exit 1
    fi
    kubectl config use-context "wehive-${target_alias}" &>/dev/null || true
}

_cmd_init() {
    local impersonate="${1:-}"

    echo -e "\n${YELLOW}Configurando acesso ao cluster...${NC}"

    if ! command -v aws &>/dev/null; then
        echo -e "  ${RED}✗${NC} aws CLI não instalado."
        exit 1
    fi

    COMMONS_DIR="$(cd "${SCRIPT_DIR}/../../../../.." && pwd)"

    # Ensure WARD_KEY_COMMONS is available for ward exec (commons vault)
    if [ -z "${WARD_KEY_COMMONS:-}" ]; then
        if [ -f "${COMMONS_DIR}/.ward/commons.key" ]; then
            WARD_KEY_COMMONS=$(cat "${COMMONS_DIR}/.ward/commons.key")
            export WARD_KEY_COMMONS
        else
            echo -e "  ${RED}✗${NC} WARD_KEY_COMMONS não configurado."
            echo -e "  Exporte a variável ou coloque a key em ${COMMONS_DIR}/.ward/commons.key"
            echo -e "  Peça ao devops (1Password: WARD_KEY | COMMONS)"
            exit 1
        fi
    fi

    # Assume TerraformRole once — all subsequent aws calls use the session
    echo -e "  Conectando ao cluster..."
    _eks_setup_session || {
        echo -e "  ${RED}✗${NC} Falha ao assumir TerraformRole. Verifique as credenciais no ward commons."
        exit 1
    }

    # Resolve caller identity
    GITHUB_USERNAME=""
    USER_ALIAS=""
    ACCESS_CONFIG=""
    source "${COMMONS_DIR}/shell/helpers/access.sh"

    if [ -z "${USER_ALIAS}" ]; then
        echo -e "  ${RED}✗${NC} Identidade não resolvida — verifique access.yml."
        exit 1
    fi

    # Impersonation: only devops owners can configure another user's context
    if [ -n "${impersonate}" ]; then
        local is_devops
        is_devops=$(echo "${ACCESS_CONFIG}" | yq e \
            '.devops.owners[] | select(. == "'"${USER_ALIAS}"'")' - 2>/dev/null || true)
        if [ -z "${is_devops}" ]; then
            echo -e "  ${RED}✗${NC} Apenas devops pode configurar contexto para outro usuário."
            exit 1
        fi
        TARGET_ALIAS="${impersonate}"
        echo -e "  ${YELLOW}Impersonando:${NC} ${BOLD}${TARGET_ALIAS}${NC} (solicitado por ${USER_ALIAS})"
    else
        TARGET_ALIAS="${USER_ALIAS}"
    fi

    # Clean stale contexts before rebuilding:
    # - impersonation: only the target alias
    # - normal init: all wehive-* (removes any leftover from K8S_USER runs)
    if [ -n "${impersonate}" ]; then
        _cleanup_stale_contexts "${TARGET_ALIAS}"
    else
        _cleanup_stale_contexts ""
    fi

    # Devops context (only for the caller themselves, not when impersonating)
    if [ -z "${impersonate}" ]; then
        local is_devops
        is_devops=$(echo "${ACCESS_CONFIG}" | yq e \
            '.devops.owners[] | select(. == "'"${USER_ALIAS}"'")' - 2>/dev/null || true)
        if [ -n "${is_devops}" ]; then
            kubectl config delete-context devops &>/dev/null || true
            _bootstrap_devops_context || exit 1
        fi
    fi

    _setup_context_for "${TARGET_ALIAS}"

    # Determine if target is owner of any project (for summary description)
    local is_owner=""
    is_owner=$(echo "${ACCESS_CONFIG}" | yq e \
        '.projects | to_entries | .[] |
         select(.value.owners != null and
                (.value.owners[] | select(. == "'"${TARGET_ALIAS}"'")) != null) | .key' \
        - 2>/dev/null | head -1 || true)

    # Clean up old cached SA token files if they exist
    rm -f "${PROFILE_DIR}"/sa-*-token "${PROFILE_DIR}"/sa-*-ca "${PROFILE_DIR}"/sa-*-server 2>/dev/null || true

    _ensure_k9s_default_view

    echo -e "\n${GREEN}✓ Setup concluído.${NC}"
    _show_summary "${TARGET_ALIAS}" "${is_owner}"
}

_cmd_devops() {
    echo -e "\n${YELLOW}Configurando contexto devops...${NC}"
    _bootstrap_devops_context || exit 1
    kubectl config use-context devops
    echo -e "\n${GREEN}✓ Contexto ativo: devops${NC}"
}

# --- Entry point ---
PROFILE="${1:-}"

case "${PROFILE}" in
    init)    _cmd_init "${2:-}" ;;
    summary) _show_summary ;;
    devops)
        _warn_elevated || exit 0
        _cmd_devops
        ;;
    *)
        echo -e "${RED}Perfil desconhecido: ${PROFILE}${NC}"
        echo -e "Uso: context.sh [init|devops]"
        exit 1
        ;;
esac
