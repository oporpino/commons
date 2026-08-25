#!/usr/bin/env bash
set -euo pipefail

[ -z "${COMMONS_DIR:-}" ] && echo "COMMONS_DIR is not set. Run: source ~/.zshrc" && exit 1
CONTAINER_REGISTRY="${CONTAINER_REGISTRY:?CONTAINER_REGISTRY is not set. Add it to your .env file (e.g. CONTAINER_REGISTRY=616795656532.dkr.ecr.us-east-1.amazonaws.com/wehive)}"
STACK="${STACK:-}"
STACK_VERSION="${STACK_VERSION:-}"
DISTRO="${DISTRO:-alpine}"

if [ -f ".infra/build-args" ]; then
  [ -z "$STACK" ]         && STACK=$(grep        "^STACK="         .infra/build-args | cut -d= -f2)
  [ -z "$STACK_VERSION" ] && STACK_VERSION=$(grep "^STACK_VERSION=" .infra/build-args | cut -d= -f2)
  [ -z "$DISTRO" ]        && DISTRO=$(grep        "^DISTRO="        .infra/build-args | cut -d= -f2)
fi

if [ -z "$STACK" ] || [ -z "$STACK_VERSION" ]; then
  echo "Usage: make image.push [STACK=ruby|elixir|node|python] [STACK_VERSION=x.x] [DISTRO=alpine]"
  echo "       or add the stack to .infra/build-args"
  exit 1
fi

IMAGE="${CONTAINER_REGISTRY}/${STACK}:${STACK_VERSION}-${DISTRO}.dev"
MINOR_VERSION=$(echo "$STACK_VERSION" | cut -d. -f1-2)
IMAGE_MINOR="${CONTAINER_REGISTRY}/${STACK}:${MINOR_VERSION}-${DISTRO}.dev"

if echo "$CONTAINER_REGISTRY" | grep -q "ghcr.io"; then
  gh auth token | docker login ghcr.io -u "$(gh api user --jq .login)" --password-stdin
fi

docker build -f "${COMMONS_DIR}/docker/Dockerfile" \
  --target dev \
  --build-arg STACK="$STACK" \
  --build-arg STACK_VERSION="$STACK_VERSION" \
  --build-arg DISTRO="$DISTRO" \
  --build-context commons-source="${COMMONS_DIR}" \
  -t "$IMAGE" \
  -t "$IMAGE_MINOR" \
  "${PWD}"

docker push "$IMAGE"
docker push "$IMAGE_MINOR"
