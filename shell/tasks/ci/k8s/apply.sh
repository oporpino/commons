#!/bin/bash
set -e

# Usage: apply.sh <environment> <app_name>
ENVIRONMENT="${1:?Usage: apply.sh <environment> <app_name>}"
APP_NAME="${2:?Usage: apply.sh <environment> <app_name>}"

NAMESPACE="${APP_NAME}--${ENVIRONMENT}"
OVERLAY_PATH=".infra/k8s/overlays/${ENVIRONMENT}"

kubectl delete jobs -l component=migrate -n "${NAMESPACE}" --ignore-not-found
kubectl apply -k "${OVERLAY_PATH}" --validate=false
kubectl get deployments -n "${NAMESPACE}" -o name | xargs -I{} kubectl rollout status {} -n "${NAMESPACE}" --timeout=2m
