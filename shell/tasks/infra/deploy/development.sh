#!/bin/bash
set -e

PROJECT_ROOT=$(git rev-parse --show-toplevel)
cd "${PROJECT_ROOT}"

[ -f .env ] && set -a && . ./.env && set +a

[ -z "${COMMONS_DIR:-}" ] && echo "COMMONS_DIR is not set. Run: source ~/.zshrc" && exit 1

CONTAINER_REGISTRY="${CONTAINER_REGISTRY:?CONTAINER_REGISTRY is not set. Add it to your .env file (e.g. CONTAINER_REGISTRY=616795656532.dkr.ecr.us-east-1.amazonaws.com/wehive)}"
IMAGE_NAME="${CONTAINER_REGISTRY}/$(basename "$PROJECT_ROOT")"
K8S_DIR="${K8S_DIR:-.infra/k8s}"

GIT_USER=$(git config user.name | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
GIT_HASH=$(git rev-parse --short HEAD)
DEPLOY_TAG="dev-${GIT_USER}-${GIT_HASH}"

# Read build config from .infra/build-args
DOCKERFILE="./Dockerfile"
BUILD_ARGS=""
if [ -f .infra/build-args ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      "#"*|"") continue ;;
      DOCKERFILE=*) DOCKERFILE="$(echo "${line#DOCKERFILE=}" | envsubst)" ;;
      LOCK_FILES=*) continue ;;
      *) BUILD_ARGS="${BUILD_ARGS} --build-arg ${line}" ;;
    esac
  done < .infra/build-args
fi

# Prepare lockfiles context
LOCK_FILES=""
if [ -f .infra/build-args ]; then
  LOCK_FILES=$(grep "^LOCK_FILES=" .infra/build-args | sed 's/^LOCK_FILES=//' || true)
fi
rm -rf .lockfiles && mkdir -p .lockfiles
for f in $LOCK_FILES; do
  [ -f "$f" ] && cp "$f" ".lockfiles/$f"
done

docker buildx build --platform linux/amd64 \
    -f "${DOCKERFILE}" \
    --target runtime \
    --build-context commons-source="${COMMONS_DIR}" \
    --build-context lockfiles=.lockfiles \
    ${BUILD_ARGS} \
    -t "${IMAGE_NAME}:${DEPLOY_TAG}" \
    --push .

cd "${PROJECT_ROOT}/${K8S_DIR}/overlays/staging"
kustomize edit set image "${IMAGE_NAME}=${IMAGE_NAME}:${DEPLOY_TAG}"

NAMESPACE=$(grep "^namespace:" kustomization.yaml | awk '{print $2}')
if [ -n "${NAMESPACE}" ]; then
  kubectl delete job migrate -n "${NAMESPACE}" --ignore-not-found
fi

kubectl apply -k .
git checkout kustomization.yaml
