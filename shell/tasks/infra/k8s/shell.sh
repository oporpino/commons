#!/bin/bash
set -e

# Usage: shell.sh <environment>
# Creates a temporary pod with sh for debugging.
ENVIRONMENT="${1:?Usage: shell.sh <environment>}"
APP_NAME="${APP_NAME:?APP_NAME required}"

NAMESPACE="${APP_NAME}--${ENVIRONMENT}"
IMAGE="${CONTAINER_REGISTRY:-616795656532.dkr.ecr.us-east-1.amazonaws.com/wehive}/${APP_NAME}:${ENVIRONMENT}"
SECRET="${K8S_SECRET_NAME:-${APP_NAME}-secrets}"
SUFFIX="$(whoami | tr '.' '-' | cut -c1-10)-$(head -c4 /dev/urandom | xxd -p)"
POD_NAME="shell-${SUFFIX}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
sh "${SCRIPT_DIR}/db-mode.sh" "DATABASE_URL_READONLY"
echo "Pod will be deleted automatically when you exit."

OVERRIDES=$(cat <<EOF
{
  "spec": {
    "activeDeadlineSeconds": 1800,
    "containers": [{
      "name": "${POD_NAME}",
      "image": "${IMAGE}",
      "imagePullPolicy": "Always",
      "command": ["sh", "-c", "TMOUT=300 exec sh"],
      "workingDir": "/source",
      "stdin": true,
      "tty": true,
      "envFrom": [{"secretRef": {"name": "${SECRET}"}}]
    }],
    "restartPolicy": "Never"
  }
}
EOF
)

kubectl run "${POD_NAME}" \
  --rm -it \
  --image="${IMAGE}" \
  --restart=Never \
  --overrides="${OVERRIDES}" \
  -n "${NAMESPACE}" || kubectl delete pod "${POD_NAME}" -n "${NAMESPACE}" --ignore-not-found 2>/dev/null || true
