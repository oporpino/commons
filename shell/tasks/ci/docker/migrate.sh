#!/bin/bash
set -eu

# Mirrors an app's existing images from DOCR to the shared ECR, so a
# DOCKER_REGISTRY flip does not leave running pods pointing at tags that
# never got pushed to ECR. Run once per app before the flip.
#
# Usage:
#   migrate.sh <app_name> [tags]
#
#   app_name : image name segment (matches the ECR repo, e.g. gateway,
#              marketing-automation, insights-mcp)
#   tags     : comma-separated tags to copy (default: staging,production,latest)
#
# Env:
#   DOCR_REGISTRY  source registry host   (default: 616795656532.dkr.ecr.us-east-1.amazonaws.com/wehive)
#   ECR_REGISTRY   target registry host   (required, e.g. 616795656532.dkr.ecr.us-east-1.amazonaws.com)
#
# Auth: both registries must already be logged in (creds in ~/.docker/config.json).
#   DOCR: docker/login-action against registry.digitalocean.com
#   ECR:  aws-actions/amazon-ecr-login

APP_NAME="${1:?Usage: migrate.sh <app_name> [tags]}"
TAGS="${2:-staging,production,latest}"

DOCR_REGISTRY="${DOCR_REGISTRY:-616795656532.dkr.ecr.us-east-1.amazonaws.com/wehive}"
ECR_REGISTRY="${ECR_REGISTRY:?ECR_REGISTRY is required (e.g. <account>.dkr.ecr.<region>.amazonaws.com)}"

SOURCE="${DOCR_REGISTRY}/${APP_NAME}"
TARGET="${ECR_REGISTRY}/${APP_NAME}"
AUTHFILE="${HOME}/.docker/config.json"

for tag in $(echo "${TAGS}" | tr ',' ' '); do
  if skopeo inspect --authfile "${AUTHFILE}" "docker://${SOURCE}:${tag}" >/dev/null 2>&1; then
    echo "→ ${SOURCE}:${tag} => ${TARGET}:${tag}"
    skopeo copy \
      --preserve-digests \
      --authfile "${AUTHFILE}" \
      "docker://${SOURCE}:${tag}" \
      "docker://${TARGET}:${tag}"
  else
    echo "· skip ${SOURCE}:${tag} (not found in DOCR)"
  fi
done
