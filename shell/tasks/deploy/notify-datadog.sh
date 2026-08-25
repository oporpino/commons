#!/bin/bash
set -e

: "${DD_API_KEY:?DD_API_KEY is required}"
: "${DD_SITE:=us5.datadoghq.com}"
: "${DEPLOY_ENV:?DEPLOY_ENV is required}"
: "${DEPLOY_SERVICE:?DEPLOY_SERVICE is required}"
: "${DEPLOY_VERSION:?DEPLOY_VERSION is required}"
: "${DD_ALERT_TYPE:=info}"

curl -sf -X POST "https://api.${DD_SITE}/api/v1/events" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"title\": \"Deploy ${DEPLOY_SERVICE} @ ${DEPLOY_ENV}\",
    \"text\": \"${DEPLOY_VERSION}\",
    \"alert_type\": \"${DD_ALERT_TYPE}\",
    \"tags\": [
      \"env:${DEPLOY_ENV}\",
      \"service:${DEPLOY_SERVICE}\",
      \"version:${DEPLOY_VERSION}\"
    ]
  }"
