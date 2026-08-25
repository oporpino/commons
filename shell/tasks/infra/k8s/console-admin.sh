#!/bin/bash
set -e

# Usage: console-admin.sh <namespace>
# Creates a temporary pod with full DB access (emergencies only).
# Requires: console-admin permission (project-admin-production ClusterRole).
NAMESPACE="${1:?Usage: console-admin.sh <namespace>}"
APP_NAME="${APP_NAME:?APP_NAME required}"

IMAGE="${CONTAINER_REGISTRY:-616795656532.dkr.ecr.us-east-1.amazonaws.com/wehive}/${APP_NAME}:${ENVIRONMENT:-production}"
CONSOLE="${CONSOLE_COMMAND:-run/console}"
SECRET="${APP_NAME}-secrets"

echo "Starting admin console in ${NAMESPACE} (full DB access)..."
echo "Pod will be deleted automatically when you exit."

kubectl run console-admin \
  --rm -it \
  --image="${IMAGE}" \
  --env-from="secret/${SECRET}" \
  --restart=Never \
  -n "${NAMESPACE}" \
  -- ${CONSOLE}
