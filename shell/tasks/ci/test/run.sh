#!/bin/sh
# Runs tests inside a Docker image with optional .env.ci.
# Usage: sh run.sh <image>
set -e

IMAGE="$1"

ENV_FILE_FLAG=""
[ -f .env.ci ] && ENV_FILE_FLAG="--env-file .env.ci"

docker run --rm \
  --network host \
  $ENV_FILE_FLAG \
  "$IMAGE" \
  run/test
