#!/bin/bash
set -e

APP_NAME="${1:?Usage: run-migrate.sh <app_name> <environment> <version_tag> <registry> [working_directory] [namespace]}"
ENVIRONMENT="${2:?Usage: run-migrate.sh <app_name> <environment> <version_tag> <registry> [working_directory] [namespace]}"
VERSION_TAG="${3:?Usage: run-migrate.sh <app_name> <environment> <version_tag> <registry> [working_directory] [namespace]}"
REGISTRY="${4:?Usage: run-migrate.sh <app_name> <environment> <version_tag> <registry> [working_directory] [namespace]}"
WORKING_DIR="${5:-.}"
NAMESPACE="${6:-${APP_NAME}--${ENVIRONMENT}}"

IMAGE="${REGISTRY}/${APP_NAME}:${VERSION_TAG}"
PROJECT_MANIFEST="${WORKING_DIR}/.infra/k8s/base/specs/migrate-job.yaml"

if [ ! -f "$PROJECT_MANIFEST" ]; then
  echo -e "\033[31m[run-migrate] ERROR: migrate-job.yaml not found at ${PROJECT_MANIFEST}\033[0m"
  echo -e "\033[31m[run-migrate] Add the migrate job manifest to ${WORKING_DIR}/.infra/k8s/base/specs/migrate-job.yaml\033[0m"
  exit 1
fi

kubectl delete job migrate -n "$NAMESPACE" --ignore-not-found

echo "[run-migrate] applying migrate job for $APP_NAME in $NAMESPACE..."
sed -e "s|APP_NAME|$APP_NAME|g" \
    -e "s|MIGRATE_IMAGE|$IMAGE|g" \
    -e "s|MIGRATE_ENV|$ENVIRONMENT|g" \
    "$PROJECT_MANIFEST" \
  | kubectl apply -f - -n "$NAMESPACE"

echo "[run-migrate] waiting for migrate job to complete (database may take up to 60s to wake from pause)..."
kubectl wait --for=condition=complete job/migrate -n "$NAMESPACE" --timeout=300s
