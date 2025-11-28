#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
if [ "$1" = "--dev" ]; then
  ENV_FILE="$ROOT_DIR/.env.dev"
elif [ "$1" = "--prod" ]; then
  ENV_FILE="$ROOT_DIR/.env.prod"
else
  echo "usage: update.sh --dev|--prod" >&2
  exit 1
fi

DB_CONTAINER="${DB_CONTAINER:-survivor-mongo}"

set -a
. "$ENV_FILE"
set +a

docker exec "$DB_CONTAINER" mkdir -p /app/mongo-init
docker cp "$ROOT_DIR/db/." "$DB_CONTAINER":/app/mongo-init

docker exec -e SPACE_PASSWORD_HASH="$SPACE_PASSWORD_HASH" "$DB_CONTAINER" sh -c '
if [ -n "$MONGO_INITDB_ROOT_USERNAME" ]; then
  mongosh --username "$MONGO_INITDB_ROOT_USERNAME" --password "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin --file /app/mongo-init/init.js
else
  mongosh --file /app/mongo-init/init.js
fi
'
