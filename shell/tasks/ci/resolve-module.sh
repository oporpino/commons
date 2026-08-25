#!/bin/sh
set -e

APP_NAME="${1:?APP_NAME is required}"
MODULE="${2:-}"
WORKING_DIR="${3:-}"
# Registry: prefer env var, fallback to positional arg (for backwards compat)
REGISTRY="${DOCKER_REGISTRY:-${4:-}}"

if [ -z "$REGISTRY" ]; then
  echo "DOCKER_REGISTRY env var or registry argument is required" >&2
  exit 1
fi

IMAGE="${APP_NAME}${MODULE:+-${MODULE}}"
RESOLVED_DIR="${WORKING_DIR:-${MODULE:+modules/${MODULE}}}"
RESOLVED_DIR="${RESOLVED_DIR:-.}"

echo "SERVICE_NAME=${IMAGE}" >> "$GITHUB_ENV"
echo "IMAGE_NAME=${REGISTRY}/${IMAGE}" >> "$GITHUB_ENV"
echo "WORKING_DIR=${RESOLVED_DIR}" >> "$GITHUB_ENV"

# Also expose as step outputs for cross-job sharing
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "image_name=${REGISTRY}/${IMAGE}" >> "$GITHUB_OUTPUT"
  echo "service_name=${IMAGE}" >> "$GITHUB_OUTPUT"
fi
