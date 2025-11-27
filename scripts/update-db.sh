#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DEV_CONTAINER=${DEV_CONTAINER:-dev-mongo}
PROD_SERVICE=${PROD_SERVICE:-mongo}
TARGET_DB=${TARGET_DB:-survivor_pool}
CONTAINER_DB_DIR=${CONTAINER_DB_DIR:-/app/mongo-init}
CONTAINER_SEED=${CONTAINER_SEED:-"$CONTAINER_DB_DIR/init.js"}
HOST_DB_DIR=${1:-${HOST_DB_DIR:-"$ROOT_DIR/db"}}
HOST_SEED=${HOST_SEED:-"$HOST_DB_DIR/init.js"}
HOST_SEASONS_DIR=${HOST_SEASONS_DIR:-"$HOST_DB_DIR/seasons"}

COMPOSE_CMD=(docker compose -f "$ROOT_DIR/compose.yml" --project-directory "$ROOT_DIR")

if [ ! -d "$HOST_DB_DIR" ]; then
  echo "DB directory not found at $HOST_DB_DIR" >&2
  exit 1
fi

if [ ! -f "$HOST_SEED" ]; then
  echo "Seed file not found at $HOST_SEED" >&2
  exit 1
fi

if [ ! -d "$HOST_SEASONS_DIR" ]; then
  echo "Seasons directory not found at $HOST_SEASONS_DIR" >&2
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

  local env_file=${ENV_FILE:-"$ROOT_DIR/.env.dev"}

  if [ ! -f "$env_file" ]; then
    echo "Missing $env_file for Mongo env vars" >&2
    exit 1
  fi

  # shellcheck disable=SC1090
  source "$env_file"

  local space_password_hash=${SPACE_PASSWORD_HASH:-}

  if [ -z "$space_password_hash" ]; then
    echo "Missing SPACE_PASSWORD_HASH in $env_file" >&2
    exit 1
  fi

  until docker exec "$DEV_CONTAINER" \
    mongosh --quiet --eval "$ping_eval" >/dev/null 2>&1; do
    sleep 1
  done

  docker exec "$DEV_CONTAINER" mkdir -p "$CONTAINER_DB_DIR"
  docker cp "$HOST_DB_DIR"/. "$DEV_CONTAINER":"$CONTAINER_DB_DIR"

  echo "Running Mongo init script in '$DEV_CONTAINER'"
  docker exec -e SPACE_PASSWORD_HASH="$space_password_hash" "$DEV_CONTAINER" mongosh --file "$CONTAINER_SEED"

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
  local space_password_hash=${SPACE_PASSWORD_HASH:-}

  if [ -z "$mongo_user" ] || [ -z "$mongo_pass" ]; then
    echo "Missing MONGO_INITDB_ROOT_USERNAME or MONGO_INITDB_ROOT_PASSWORD in $env_file" >&2
    exit 1
  fi

  if [ -z "$space_password_hash" ]; then
    echo "Missing SPACE_PASSWORD_HASH in $env_file" >&2
    exit 1
  fi

  until "${COMPOSE_CMD[@]}" exec -T "$PROD_SERVICE" \
    mongosh --username "$mongo_user" --password "$mongo_pass" --authenticationDatabase admin \
      --quiet --eval "$ping_eval" >/dev/null 2>&1; do
    sleep 1
  done

  "${COMPOSE_CMD[@]}" exec -T "$PROD_SERVICE" mkdir -p "$CONTAINER_DB_DIR"
  "${COMPOSE_CMD[@]}" cp "$HOST_DB_DIR"/. "$PROD_SERVICE":"$CONTAINER_DB_DIR"

  echo "Running Mongo init script in compose service '$PROD_SERVICE'"
  "${COMPOSE_CMD[@]}" exec -T -e SPACE_PASSWORD_HASH="$space_password_hash" "$PROD_SERVICE" \
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
