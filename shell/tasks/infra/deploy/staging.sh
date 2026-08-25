#!/bin/bash
set -e

PROJECT_ROOT=$(git rev-parse --show-toplevel)
cd "${PROJECT_ROOT}"

[ -f .env ] && set -a && . ./.env && set +a

[ -z "${COMMONS_DIR:-}" ] && echo "COMMONS_DIR is not set. Run: source ~/.zshrc" && exit 1

CONTAINER_REGISTRY="${CONTAINER_REGISTRY:?CONTAINER_REGISTRY is not set. Add it to your .env file}"
K8S_DIR="${K8S_DIR:-.infra/k8s}"

REGISTRY_HOST=$(echo "${CONTAINER_REGISTRY}" | cut -d'/' -f1)
REGISTRY_NAME=$(echo "${CONTAINER_REGISTRY}" | cut -d'/' -f2)
APP=$(basename "${PROJECT_ROOT}")

ECR_REGION=$(echo "${REGISTRY_HOST}" | grep -oP '(?<=dkr\.ecr\.)[\w-]+(?=\.amazonaws\.com)' || echo "us-east-1")
ECR_PASSWORD=$(aws ecr get-login-password --region "${ECR_REGION}" 2>/dev/null)
[ -z "${ECR_PASSWORD}" ] && echo "Could not get ECR credentials. Run: aws configure" && exit 1

BEARER=$(echo "${ECR_PASSWORD}" | base64 | tr -d '\n' | xargs -I{} curl -sf \
  -H "Authorization: Basic AWS:{}" \
  "https://${REGISTRY_HOST}/v2/token?service=${REGISTRY_HOST}&scope=repository:${REGISTRY_NAME}/${APP}:pull" \
  2>/dev/null | jq -r '.token // empty')

[ -z "${BEARER}" ] && BEARER=$(printf "AWS:%s" "${ECR_PASSWORD}" | base64 | tr -d '\n')

_digest() {
  curl -sf \
    -H "Authorization: Basic $(printf "AWS:%s" "${ECR_PASSWORD}" | base64 | tr -d '\n')" \
    -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
    -I "https://${REGISTRY_HOST}/v2/${REGISTRY_NAME}/${APP}/manifests/$1" \
    | tr -d '\r' | grep -i "^docker-content-digest:" | awk '{print $2}'
}

# All v* tags sorted descending
ALL_TAGS=()
while IFS= read -r tag; do
  ALL_TAGS+=("${tag}")
done < <(curl -sf \
  -H "Authorization: Bearer ${BEARER}" \
  "https://${REGISTRY_HOST}/v2/${REGISTRY_NAME}/${APP}/tags/list" \
  | jq -r '[.tags[] | select(test("^v[0-9]"))] | sort_by(split(".") | map(tonumber? // 0)) | reverse | .[]')

[ ${#ALL_TAGS[@]} -eq 0 ] && echo "No versioned tags found in registry for ${APP}." && exit 1

# Fetch staging/latest digests in background, write matching v* tag names to tmp files
PAGE=10
TMP_DIR=$(mktemp -d)
TMP_STAGING="${TMP_DIR}/tag_staging"
TMP_LATEST="${TMP_DIR}/tag_latest"
TMP_DONE="${TMP_DIR}/done"
TMP_DIGESTS="${TMP_DIR}/digests"
mkdir -p "${TMP_DIGESTS}"

(
  ds=$(_digest staging 2>/dev/null)
  dl=$(_digest latest  2>/dev/null)

  # Fetch digests of first PAGE tags in parallel
  for tag in "${ALL_TAGS[@]:0:${PAGE}}"; do
    ( _digest "${tag}" 2>/dev/null > "${TMP_DIGESTS}/${tag}" ) &
  done
  wait

  for tag in "${ALL_TAGS[@]:0:${PAGE}}"; do
    d=$(cat "${TMP_DIGESTS}/${tag}" 2>/dev/null)
    [ -n "${dl}" ] && [ "${d}" = "${dl}" ] && echo "${tag}" > "${TMP_LATEST}"
    [ -n "${ds}" ] && [ "${d}" = "${ds}" ] && echo "${tag}" > "${TMP_STAGING}"
  done
  touch "${TMP_DONE}"
) &
BG_PID=$!

loaded=0
MENU=()
HAS_MORE=0
LABEL_STAGING=""
LABEL_LATEST=""
LABELS_CHECKED=0

_load_page() {
  local end=$(( loaded + PAGE ))
  [ $end -gt ${#ALL_TAGS[@]} ] && end=${#ALL_TAGS[@]}
  for (( i=loaded; i<end; i++ )); do
    MENU+=("${ALL_TAGS[$i]}")
  done
  loaded=$end
  [ $loaded -lt ${#ALL_TAGS[@]} ] && HAS_MORE=1 || HAS_MORE=0
}

_check_labels() {
  [ $LABELS_CHECKED -eq 1 ] && return
  [ ! -f "${TMP_DONE}" ] && return
  [ -f "${TMP_LATEST}"  ] && LABEL_LATEST=$(cat "${TMP_LATEST}")
  [ -f "${TMP_STAGING}" ] && LABEL_STAGING=$(cat "${TMP_STAGING}")
  LABELS_CHECKED=1
}

_load_page

CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
YELLOW='\033[0;33m'
RESET='\033[0m'

selected=0

_draw_menu() {
  _check_labels
  tput clear
  echo -e "${BOLD}Select version to deploy to staging (${APP}):${RESET}\n"
  local total=${#MENU[@]}
  for (( i=0; i<total; i++ )); do
    local tag="${MENU[$i]}"
    local suffix=""
    [ "${tag}" = "${LABEL_LATEST}"  ] && suffix="${suffix}   ${DIM}← latest${RESET}"
    [ "${tag}" = "${LABEL_STAGING}" ] && suffix="${suffix}   ${YELLOW}← staging${RESET}"
    if [ "$i" -eq "$selected" ]; then
      echo -e "  ${CYAN}▶ ${tag}${suffix}${RESET}"
    else
      echo -e "    ${tag}${suffix}"
    fi
  done
  # "load more" as a selectable item
  if [ $HAS_MORE -eq 1 ]; then
    local load_idx=${#MENU[@]}
    if [ "$selected" -eq "$load_idx" ]; then
      echo -e "  ${CYAN}▶ ... (load more)${RESET}"
    else
      echo -e "  ${DIM}  ... (load more)${RESET}"
    fi
  fi
  echo -e "\n  ${BOLD}↑↓${RESET} navigate   ${BOLD}Enter${RESET} confirm   ${BOLD}q${RESET} quit"
}

_draw_menu

while true; do
  IFS= read -rsn1 -t 1 key || { _draw_menu; continue; }

  if [ "${key}" = $'\x1b' ]; then
    read -rsn2 key
    load_idx=${#MENU[@]}
    max_idx=$(( HAS_MORE ? load_idx : load_idx - 1 ))
    case "${key}" in
      '[A') [ $selected -gt 0 ] && ((selected--)) ;;
      '[B')
        if [ $selected -lt $max_idx ]; then
          ((selected++))
          # Auto-load when landing on "load more"
          if [ $HAS_MORE -eq 1 ] && [ "$selected" -eq "${#MENU[@]}" ]; then
            prev_loaded=$loaded
            _load_page
            selected=$prev_loaded
          fi
        fi
        ;;
    esac
  elif [ "${key}" = '' ]; then
    load_idx=${#MENU[@]}
    if [ $HAS_MORE -eq 1 ] && [ "$selected" -eq "$load_idx" ]; then
      # Enter on "load more"
      prev_loaded=$loaded
      _load_page
      selected=$prev_loaded  # move to first newly loaded tag
    else
      break
    fi
  elif [ "${key}" = 'q' ]; then
    kill $BG_PID 2>/dev/null || true
    rm -rf "${TMP_DIR}"
    tput clear
    echo "Aborted."
    exit 0
  fi
  _draw_menu
done

kill $BG_PID 2>/dev/null || true
rm -rf "${TMP_DIR}"
tput clear

CHOSEN_TAG="${MENU[$selected]}"

echo "Deploying ${CONTAINER_REGISTRY}/${APP}:${CHOSEN_TAG} to staging..."

cd "${PROJECT_ROOT}/${K8S_DIR}/overlays/staging"
kustomize edit set image "${CONTAINER_REGISTRY}/${APP}=${CONTAINER_REGISTRY}/${APP}:${CHOSEN_TAG}"
K8S_NS=$(grep -m1 'namespace:' kustomization.yaml | awk '{print $2}')
kubectl delete job migrate --ignore-not-found ${K8S_NS:+-n "${K8S_NS}"} 2>/dev/null || true
kubectl apply -k .
git checkout kustomization.yaml
