#!/bin/sh
# Starts CI services using compose files from ${COMMONS_DIR}.
# Generates .env.ci with connection URLs for the test container.
# Usage: sh start.sh database,cache,messagebroker
set -e

SERVICES="${1:-}"
[ -z "$SERVICES" ] && exit 0

[ -z "${COMMONS_DIR:-}" ] && echo "COMMONS_DIR is not set." && exit 1
COMPOSE_FILES=""
ENV_FILE=".env.ci"

> "$ENV_FILE"

export DATABASE_NAME=test
export DATABASE_USERNAME=test
export DATABASE_PASSWORD=test
export DATABASE_PORT=5432
export CACHE_PORT=6379

for service in $(echo "$SERVICES" | tr ',' ' '); do
  service=$(echo "$service" | tr -d ' ')
  [ -z "$service" ] && continue
  file="$COMMONS_DIR/docker/compose/shared/$service.yml"
  if [ ! -f "$file" ]; then
    echo "Unknown service: $service (no $file)"
    exit 1
  fi
  COMPOSE_FILES="$COMPOSE_FILES -f $file"

  case "$service" in
    database)
      echo "DATABASE_URL=postgres://${DATABASE_USERNAME}:${DATABASE_PASSWORD}@localhost:${DATABASE_PORT}/${DATABASE_NAME}" >> "$ENV_FILE"
      ;;
    cache)
      echo "REDIS_URL=redis://localhost:${CACHE_PORT}/0" >> "$ENV_FILE"
      ;;
    messagebroker)
      echo "CELERY_BROKER_URL=amqp://guest:guest@localhost:5672/" >> "$ENV_FILE"
      ;;
  esac
done

docker compose $COMPOSE_FILES up -d --wait
echo "Services ready. Environment written to $ENV_FILE"
