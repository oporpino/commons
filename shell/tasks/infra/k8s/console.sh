#!/bin/bash
set -e

# Usage: console.sh <environment> [--admin]
# Creates a temporary pod connected to the database.
# Default: readonly (uses DATABASE_URL_READONLY from secret)
# --admin: full access (uses DATABASE_URL_FULLACCESS from secret)
ENVIRONMENT="${1:?Usage: console.sh <environment> [--admin]}"
APP_NAME="${APP_NAME:?APP_NAME required}"
ADMIN="${2:-}"

if [ "${ADMIN}" = "--admin" ] && [ "${ENVIRONMENT}" = "production" ]; then
    if ! command -v gh &>/dev/null || ! command -v yq &>/dev/null; then
        echo "gh and yq are required for fullaccess console"
        exit 1
    fi
    GH_USER=$(gh api user --jq '.login' 2>/dev/null || true)
    if [ -z "${GH_USER}" ]; then
        echo "Not logged in to GitHub (gh auth login)"
        exit 1
    fi
    ACCESS_CONFIG=$(gh api repos/ibft-corp/infrastructure/contents/config/access.yml \
        --jq '.content' 2>/dev/null | base64 -d 2>/dev/null || true)
    PROJECT=$(echo "${ACCESS_CONFIG}" | yq e \
        '.projects | to_entries | .[] | select(.value.apps[] == "'"${APP_NAME}"'") | .key' - 2>/dev/null || true)
    if [ -z "${PROJECT}" ]; then
        echo "App '${APP_NAME}' not found in access.yml"
        exit 1
    fi
    USER_ALIAS=$(echo "${ACCESS_CONFIG}" | yq e \
        '.users | to_entries | .[] | select(.value.github == "'"${GH_USER}"'") | .key' - 2>/dev/null || true)
    IS_OWNER=$(echo "${ACCESS_CONFIG}" | yq e \
        '.projects.'"${PROJECT}"'.owners[] | select(. == "'"${USER_ALIAS}"'")' - 2>/dev/null || true)
    if [ -z "${IS_OWNER}" ]; then
        echo "Access denied: ${GH_USER} is not an owner of project '${PROJECT}'"
        exit 1
    fi
fi

NAMESPACE="${APP_NAME}--${ENVIRONMENT}"
IMAGE="${CONTAINER_REGISTRY:-616795656532.dkr.ecr.us-east-1.amazonaws.com/wehive}/${APP_NAME}:${ENVIRONMENT}"
CONSOLE="${CONSOLE_COMMAND:-run/console}"
SECRET="${K8S_SECRET_NAME:-${APP_NAME}-secrets}"

SUFFIX="$(whoami | tr '.' '-' | cut -c1-10)-$(head -c4 /dev/urandom | xxd -p)"

if [ "${ADMIN}" = "--admin" ]; then
  POD_NAME="console-admin-${SUFFIX}"
  DB_KEY="DATABASE_URL_FULLACCESS"
  SANDBOX_VALUE="false"
else
  POD_NAME="console-readonly-${SUFFIX}"
  DB_KEY="DATABASE_URL_READONLY"
  SANDBOX_VALUE="true"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
sh "${SCRIPT_DIR}/db-mode.sh" "${DB_KEY}"
echo "Pod will be deleted automatically when you exit."

DB_VALUE=$(kubectl get secret "${SECRET}" -n "${NAMESPACE}" -o jsonpath="{.data.${DB_KEY}}" | base64 -d)

OVERRIDES=$(cat <<EOF
{
  "spec": {
    "activeDeadlineSeconds": 1800,
    "containers": [{
      "name": "${POD_NAME}",
      "image": "${IMAGE}",
      "imagePullPolicy": "Always",
      "command": ["sh", "/source/${CONSOLE}"],
      "workingDir": "/source",
      "stdin": true,
      "tty": true,
      "envFrom": [{"secretRef": {"name": "${SECRET}"}}],
      "env": [{"name": "DATABASE_URL", "value": "${DB_VALUE}"},{"name": "CONSOLE_SANDBOX", "value": "${SANDBOX_VALUE}"}]
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
