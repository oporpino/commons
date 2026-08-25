#!/usr/bin/env bash
# Open a socat tunnel through a kubectl pod to a private RDS instance, so you can
# reach it from localhost. Generic across wehive apps.
#
# Usage:
#   db-tunnel.sh -a marketing.automation -e staging -d leads -p 15432
#   db-tunnel.sh --app marketing.automation            # env defaults to staging
#
# Flags:
#   -a, --app        (required) ward app path, e.g. marketing.automation
#   -e, --env        (default: staging)
#   -d, --db         (default: leads)         database name shown in the URL
#   -p, --port       (default: 15432)         local port to bind
#   -n, --namespace  (default: <app-dashed>--<env>, e.g. marketing-automation--staging)
#
# Ward keys read: <vault>:<context>.<env>.TF_VAR_<db>_db_host / _user / _password
set -euo pipefail

APP=""; ENV="staging"; DB="leads"; LOCAL_PORT="15432"; NAMESPACE=""
while [ $# -gt 0 ]; do
  case "$1" in
    -a|--app)       APP="$2"; shift 2 ;;
    -e|--env)       ENV="$2"; shift 2 ;;
    -d|--db)        DB="$2"; shift 2 ;;
    -p|--port)      LOCAL_PORT="$2"; shift 2 ;;
    -n|--namespace) NAMESPACE="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

[ -z "$APP" ] && { echo "Error: --app/-a is required (e.g. -a marketing.automation)" >&2; exit 1; }

# marketing.automation → marketing-automation ; namespace → marketing-automation--<env>
APP_DASHED="${APP//./-}"
NAMESPACE="${NAMESPACE:-${APP_DASHED}--${ENV}}"
POD_NAME="db-tunnel-$(whoami)-$$"

# ward 0.2.x selects the vault with `:`; everything after it is the secret-path.
# APP is "<vault>[.<context>]" (e.g. marketing.automation -> marketing:automation).
if [[ "$APP" == *.* ]]; then
  WARD_SCOPE="${APP%%.*}:${APP#*.}.${ENV}"
else
  WARD_SCOPE="${APP}:${ENV}"
fi

DB_HOST=$(ward get "${WARD_SCOPE}.TF_VAR_${DB}_db_host")
DB_USER=$(ward get "${WARD_SCOPE}.TF_VAR_${DB}_db_user")
DB_PASSWORD=$(ward get "${WARD_SCOPE}.TF_VAR_${DB}_db_password")

SOCAT_OVERRIDES="{\"spec\":{\"containers\":[{\"name\":\"${POD_NAME}\",\"image\":\"alpine/socat\",\"command\":[\"socat\",\"TCP-LISTEN:5432,fork,reuseaddr\",\"TCP:${DB_HOST}:5432\"]}]}}"

cleanup() {
  echo ""
  echo "Closing tunnel..."
  kubectl delete pod "$POD_NAME" -n "$NAMESPACE" --ignore-not-found &>/dev/null || true
}
trap cleanup EXIT INT TERM

echo "Starting database tunnel for ${APP} ${ENV} (${DB})..."

kubectl run "$POD_NAME" \
  --image=alpine/socat \
  --restart=Never \
  --namespace="$NAMESPACE" \
  --overrides="$SOCAT_OVERRIDES" &>/dev/null

echo -n "Waiting for proxy pod to be ready..."
kubectl wait pod "$POD_NAME" \
  --for=condition=Ready \
  --timeout=30s \
  --namespace="$NAMESPACE" &>/dev/null
echo " ready."

kubectl port-forward "pod/$POD_NAME" "${LOCAL_PORT}:5432" \
  --namespace="$NAMESPACE" \
  --pod-running-timeout=5m &
PF_PID=$!

sleep 1

echo ""
echo "  Host:     127.0.0.1"
echo "  Port:     $LOCAL_PORT"
echo "  Database: $DB"
echo "  User:     $DB_USER"
echo "  Password: $DB_PASSWORD"
echo "  URL:      postgresql://${DB_USER}:${DB_PASSWORD}@127.0.0.1:${LOCAL_PORT}/${DB}"
echo ""
echo "Press Ctrl+C to close the tunnel."

while kill -0 $PF_PID 2>/dev/null; do
  sleep 5
done
