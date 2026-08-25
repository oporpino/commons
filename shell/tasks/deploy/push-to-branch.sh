#!/bin/bash
set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Validar parâmetros obrigatórios
BRANCH_NAME="${_BRANCH_NAME:-${BRANCH_NAME:-}}"
if [ -z "${BRANCH_NAME:-}" ]; then
  echo "Error: BRANCH_NAME environment variable is required"
  exit 1
fi

# Configurar Git
git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"

# Detectar tag
if [ -n "${GITHUB_REF:-}" ] && [[ "$GITHUB_REF" == refs/tags/* ]]; then
  # Workflow triggered por tag push
  TAG_NAME="${GITHUB_REF#refs/tags/}"
else
  # Workflow triggered manualmente
  TAG_NAME=$(git describe --tags --exact-match 2>/dev/null || echo "")

  if [ -z "$TAG_NAME" ] && [ "${REQUIRE_TAG:-false}" = "true" ]; then
    echo "Error: Current commit is not tagged"
    exit 1
  fi
fi

# Validar formato semver (se tag existe)
if [ -n "$TAG_NAME" ] && [[ ! "$TAG_NAME" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: Tag must follow semantic versioning (e.g., v1.5.2)"
  echo "Current tag: $TAG_NAME"
  exit 1
fi

# Push para branch de deployment
echo "Pushing to branch: $BRANCH_NAME"
if [ -n "$TAG_NAME" ]; then
  echo "Tag: $TAG_NAME"
fi

git push origin "HEAD:refs/heads/$BRANCH_NAME" --force

# Force webhook via GitHub API so Heroku always receives a push event,
# even when the SHA is already up-to-date on the target branch.
if [ -n "${GITHUB_TOKEN:-}" ] && [ -n "${GITHUB_REPOSITORY:-}" ]; then
  CURRENT_SHA=$(git rev-parse HEAD)
  echo "Triggering GitHub push webhook via API..."
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -X PATCH \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/${GITHUB_REPOSITORY}/git/refs/heads/${BRANCH_NAME}" \
    -d "{\"sha\":\"${CURRENT_SHA}\",\"force\":true}")

  if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "✓ Webhook triggered successfully"
  else
    echo "Warning: GitHub API returned HTTP $HTTP_STATUS — Heroku may not receive push event"
  fi
fi

echo "✓ Successfully pushed to $BRANCH_NAME branch"
if [ -n "$TAG_NAME" ]; then
  echo "  Tag: $TAG_NAME"
fi
