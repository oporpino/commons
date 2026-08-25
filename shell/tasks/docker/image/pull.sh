#!/usr/bin/env bash
set -euo pipefail

CONTAINER_REGISTRY="${CONTAINER_REGISTRY:?CONTAINER_REGISTRY is not set. Add it to your .env file (e.g. CONTAINER_REGISTRY=616795656532.dkr.ecr.us-east-1.amazonaws.com/wehive)}"
STACK="${STACK:-}"
STACK_VERSION="${STACK_VERSION:-}"
DISTRO="${DISTRO:-alpine}"

for pair in "ruby:ruby" "elixir:elixir" "nodejs:node" "python:python"; do
  tool="${pair%:*}"; s="${pair#*:}"
  [ -n "$STACK" ] && [ "$s" != "$STACK" ] && continue
  v=$(grep "^$tool " .tool-versions 2>/dev/null | awk '{print $2}' || true)
  [ -z "$v" ] && continue
  [ -z "$STACK" ] && STACK=$s
  [ -z "$STACK_VERSION" ] && STACK_VERSION=$v
  break
done

if [ -z "$STACK" ] || [ -z "$STACK_VERSION" ]; then
  echo "Usage: make image.dev.pull [STACK=ruby|elixir|node|python] [STACK_VERSION=x.x] [DISTRO=alpine]"
  echo "       or add the stack to .tool-versions"
  exit 1
fi

IMAGE="${CONTAINER_REGISTRY}/${STACK}:${STACK_VERSION}-${DISTRO}.dev"

docker pull --quiet "$IMAGE"
echo "Pulled $IMAGE"
