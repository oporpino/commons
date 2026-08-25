#!/usr/bin/env bash
# Authorize a public IP to reach the project's cloud database on its port.
#
# Reads resource identifiers from <project>/.infra/provider-args:
#   DB_SECURITY_GROUP, DB_REGION, CLOUD_PROFILE (DB_PORT optional, default 5432)
#
# Usage:
#   make db.ip.allow              # authorizes the caller's current public IP
#   make db.ip.allow IP=1.2.3.4   # authorizes an explicit IP or CIDR
set -euo pipefail

project_dir="${PROJECT_DIR:-$(pwd)}"
provider_args="${project_dir}/.infra/provider-args"

if [ ! -f "$provider_args" ]; then
  echo "error: ${provider_args} not found" >&2
  exit 1
fi

# shellcheck disable=SC1090
set -a
. "$provider_args"
set +a

: "${DB_SECURITY_GROUP:?DB_SECURITY_GROUP not set in provider-args}"
: "${DB_REGION:?DB_REGION not set in provider-args}"
: "${CLOUD_PROFILE:?CLOUD_PROFILE not set in provider-args}"
DB_PORT="${DB_PORT:-5432}"

ip="${1:-}"
if [ -z "$ip" ]; then
  ip="$(curl -s --max-time 5 https://checkip.amazonaws.com)"
fi

case "$ip" in
  */*) cidr="$ip" ;;
  *)   cidr="${ip}/32" ;;
esac

echo "Authorizing ${cidr} on ${DB_SECURITY_GROUP}:${DB_PORT} (${DB_REGION})..."

if AWS_PROFILE="$CLOUD_PROFILE" aws ec2 authorize-security-group-ingress \
  --region "$DB_REGION" \
  --group-id "$DB_SECURITY_GROUP" \
  --protocol tcp --port "$DB_PORT" \
  --cidr "$cidr" >/dev/null 2>&1; then
  echo "Done. ${cidr} can now reach the database."
else
  echo "Rule for ${cidr} already exists (or could not be added)."
fi
