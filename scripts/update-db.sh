#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DEV_CONTAINER=${DEV_CONTAINER:-dev-mongo}
PROD_SERVICE=${PROD_SERVICE:-mongo}
TARGET_DB=${TARGET_DB:-survivor_pool}
CONTAINER_SEED=${CONTAINER_SEED:-/app/mongo-init/init.js}
HOST_SEED=${1:-"$ROOT_DIR/db/init/init.js"}

COMPOSE_CMD=(docker compose -f "$ROOT_DIR/compose.yml" --project-directory "$ROOT_DIR")

if [ ! -f "$HOST_SEED" ]; then
  echo "Seed file not found at $HOST_SEED" >&2
  exit 1
fi

ping_eval=$(cat <<'JS'
const ok = db.runCommand({ ping: 1 }).ok === 1;
if (!ok) {
  quit(1);
}
JS
)

db_exists_eval=$(cat <<EOF
const names = db.getSiblingDB('admin')
  .runCommand({ listDatabases: 1 })
  .databases.map(d => d.name);
if (!names.includes('$TARGET_DB')) {
  quit(1);
}
EOF
)

run_dev_update() {
  echo "Detected dev Mongo container '$DEV_CONTAINER'"

  until docker exec "$DEV_CONTAINER" \
    mongosh --quiet --eval "$ping_eval" >/dev/null 2>&1; do
    sleep 1
  done

  docker exec "$DEV_CONTAINER" mkdir -p "$(dirname "$CONTAINER_SEED")"
  docker cp "$HOST_SEED" "$DEV_CONTAINER":"$CONTAINER_SEED"

  echo "Running Mongo init script in '$DEV_CONTAINER'"
  docker exec "$DEV_CONTAINER" mongosh --file "$CONTAINER_SEED"

  until docker exec "$DEV_CONTAINER" \
    mongosh --quiet --eval "$db_exists_eval" >/dev/null 2>&1; do
    sleep 1
  done

  echo "Database '$TARGET_DB' updated (dev)"
}

run_prod_update() {
  echo "Detected docker compose Mongo service '$PROD_SERVICE'"

  local env_file="$ROOT_DIR/.env.prod"
  if [ ! -f "$env_file" ]; then
    echo "Missing $env_file for Mongo credentials" >&2
    exit 1
  fi

  # shellcheck disable=SC1090
  source "$env_file"

  local mongo_user=${MONGO_INITDB_ROOT_USERNAME:-}
  local mongo_pass=${MONGO_INITDB_ROOT_PASSWORD:-}

  if [ -z "$mongo_user" ] || [ -z "$mongo_pass" ]; then
    echo "Missing MONGO_INITDB_ROOT_USERNAME or MONGO_INITDB_ROOT_PASSWORD in $env_file" >&2
    exit 1
  fi

  until "${COMPOSE_CMD[@]}" exec -T "$PROD_SERVICE" \
    mongosh --username "$mongo_user" --password "$mongo_pass" --authenticationDatabase admin \
      --quiet --eval "$ping_eval" >/dev/null 2>&1; do
    sleep 1
  done

  "${COMPOSE_CMD[@]}" exec -T "$PROD_SERVICE" mkdir -p "$(dirname "$CONTAINER_SEED")"
  "${COMPOSE_CMD[@]}" cp "$HOST_SEED" "$PROD_SERVICE":"$CONTAINER_SEED"

  echo "Running Mongo init script in compose service '$PROD_SERVICE'"
  "${COMPOSE_CMD[@]}" exec -T "$PROD_SERVICE" \
    mongosh --username "$mongo_user" --password "$mongo_pass" --authenticationDatabase admin \
      --file "$CONTAINER_SEED"

  until "${COMPOSE_CMD[@]}" exec -T "$PROD_SERVICE" \
    mongosh --username "$mongo_user" --password "$mongo_pass" --authenticationDatabase admin \
      --quiet --eval "$db_exists_eval" >/dev/null 2>&1; do
    sleep 1
  done

  echo "Database '$TARGET_DB' updated (prod)"
}

dev_container_id=$(docker ps --filter "name=$DEV_CONTAINER" --filter "status=running" --format '{{.ID}}' | head -n1 || true)
if [ -n "$dev_container_id" ]; then
  run_dev_update
  exit 0
fi

compose_container_id=$("${COMPOSE_CMD[@]}" ps -q "$PROD_SERVICE" 2>/dev/null || true)
compose_container_id=${compose_container_id//$'\n'/}
if [ -n "$compose_container_id" ]; then
  run_prod_update
  exit 0
fi

echo "No running Mongo container detected. Start '$DEV_CONTAINER' or docker compose '$PROD_SERVICE' service first." >&2
exit 1
