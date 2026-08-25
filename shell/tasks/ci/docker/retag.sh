#!/bin/bash
set -e

# Usage: retag.sh <image> <source_tag> <target_tags>
# target_tags: comma-separated list of tags (e.g. "staging,latest")
IMAGE="${1:?Usage: retag.sh <image> <source_tag> <target_tags>}"
SOURCE_TAG="${2:?Usage: retag.sh <image> <source_tag> <target_tags>}"
TARGET_TAGS="${3:?Usage: retag.sh <image> <source_tag> <target_tags>}"

REGISTRY=$(echo "${IMAGE}" | cut -d'/' -f1)
CREDS_FILE="${HOME}/.docker/config.json"

for tag in $(echo "${TARGET_TAGS}" | tr ',' ' '); do
  skopeo copy \
    --preserve-digests \
    --authfile "${CREDS_FILE}" \
    "docker://${IMAGE}:${SOURCE_TAG}" \
    "docker://${IMAGE}:${tag}"
done
