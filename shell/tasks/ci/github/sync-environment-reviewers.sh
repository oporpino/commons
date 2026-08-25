#!/bin/bash
set -e

# Usage: sync-environment-reviewers.sh <config_file> <org>
# Reads config/access.yml and for each project:
#   - Finds users in `owners` list
#   - Creates/updates `production` environment on each app repo with those reviewers
# Requires: gh CLI authenticated with admin access to the org
CONFIG="${1:?Usage: sync-environment-reviewers.sh <config_file> <org>}"
ORG="${2:?Usage: sync-environment-reviewers.sh <config_file> <org>}"

command -v yq >/dev/null 2>&1 || { echo "yq is required"; exit 1; }
command -v gh >/dev/null 2>&1 || { echo "gh is required"; exit 1; }

echo "Syncing GitHub environment reviewers from $CONFIG..."

projects=$(yq e '.projects | keys | .[]' "$CONFIG")

for project in $projects; do
  apps=$(yq e ".projects.$project.apps[]" "$CONFIG")

  reviewer_ids=()
  owner_aliases=$(yq e ".projects.$project.owners[]" "$CONFIG" 2>/dev/null || true)

  for alias in $owner_aliases; do
    github_username=$(yq e ".users.$alias.github" "$CONFIG")
    echo "  Resolving GitHub user ID for: $github_username"
    gh_user_id=$(gh api "users/$github_username" --jq '.id')
    reviewer_ids+=("$gh_user_id")
  done

  if [ ${#reviewer_ids[@]} -eq 0 ]; then
    echo "  No owners for project $project, skipping"
    continue
  fi

  reviewers_json=$(printf '%s\n' "${reviewer_ids[@]}" | jq -R '{type:"User",id:(.|tonumber)}' | jq -sc '.')
  body=$(jq -n --argjson reviewers "$reviewers_json" '{"reviewers": $reviewers}')

  for app in $apps; do
    repo="$ORG/$app"
    echo "  Updating $repo environment: production"

    echo "$body" | gh api \
      --method PUT \
      "repos/$repo/environments/production" \
      --input - \
      --silent
  done
done

echo "Done."
