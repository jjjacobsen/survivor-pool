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
  ping_cmd="mongosh --username \"$MONGO_INITDB_ROOT_USERNAME\" --password \"$MONGO_INITDB_ROOT_PASSWORD\" --authenticationDatabase admin --quiet --eval \"db.runCommand({ ping: 1 })\""
  load_cmd="mongosh --username \"$MONGO_INITDB_ROOT_USERNAME\" --password \"$MONGO_INITDB_ROOT_PASSWORD\" --authenticationDatabase admin --file /app/mongo-init/init.js"
else
  ping_cmd="mongosh --quiet --eval \"db.runCommand({ ping: 1 })\""
  load_cmd="mongosh --file /app/mongo-init/init.js"
fi

for _ in seq 1 10; do
  eval "$ping_cmd" >/dev/null 2>&1 && break
  sleep 1
done
echo "mongosh ready"

eval "$load_cmd"
echo "init.js completed"
'
