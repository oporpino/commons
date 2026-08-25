#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_ROOT=$(git rev-parse --show-toplevel)
cd "${PROJECT_ROOT}"

[ -f .env ] && set -a && . ./.env && set +a

CONTAINER_REGISTRY="${CONTAINER_REGISTRY:?CONTAINER_REGISTRY is not set. Add it to your .env file (e.g. CONTAINER_REGISTRY=616795656532.dkr.ecr.us-east-1.amazonaws.com/wehive)}"
APP_NAME="${APP_NAME:-$(basename "$PROJECT_ROOT")}"
IMAGE_NAME="${CONTAINER_REGISTRY}/${APP_NAME}"
K8S_DIR="${K8S_DIR:-.infra/k8s}"
NAMESPACE="${APP_NAME}-production"

# RBAC check
if ! kubectl auth can-i create deployments -n "${NAMESPACE}" 2>/dev/null; then
    echo -e "${RED}❌ Sem permissão para deploy em ${NAMESPACE}${NC}"
    exit 1
fi

# Warn: manual deploy to production — recommend make release instead
GIT_USER=$(git config user.name | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
GIT_HASH=$(git rev-parse --short HEAD)
DEPLOY_TAG="dev-${GIT_USER}-${GIT_HASH}"

echo -e "${RED}⚠️  ATENÇÃO: deploy manual em production com tag temporária (${DEPLOY_TAG})${NC}"
echo -e "${RED}   Use ${YELLOW}make release${RED} para deploys normais via CI/CD.${NC}"
echo -e "${RED}   Continue apenas em caso de urgência.${NC}"
echo ""
read -p "Confirmar deploy de emergência em production? [s/N] " confirm
if [[ ! "$confirm" =~ ^[sS]$ ]]; then
    echo -e "${YELLOW}Cancelado.${NC}"
    exit 0
fi

docker buildx build --platform linux/amd64 \
    -t "${IMAGE_NAME}:${DEPLOY_TAG}" \
    --target runtime . --push

cd "${PROJECT_ROOT}/${K8S_DIR}/overlays/production"
kustomize edit set image "${IMAGE_NAME}=${IMAGE_NAME}:${DEPLOY_TAG}"
kubectl apply -k .
git checkout kustomization.yaml
