#!/usr/bin/env bash
set -euo pipefail
source .env.prod

service=${1:-mongo}
target_db=${2:-survivor_pool}
seed_file=${3:-/app/mongo-init/init.js}
host_seed=${4:-db/init/init.js}

mongo_user=${MONGO_INITDB_ROOT_USERNAME:-}
mongo_pass=${MONGO_INITDB_ROOT_PASSWORD:-}

if [ -z "$mongo_user" ] || [ -z "$mongo_pass" ]; then
  echo "Missing MONGO_INITDB_ROOT_USERNAME or MONGO_INITDB_ROOT_PASSWORD" >&2
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
if (!names.includes('$target_db')) {
  quit(1);
}
EOF
)

until docker compose exec -T "$service" \
  mongosh --username "$mongo_user" --password "$mongo_pass" --authenticationDatabase admin \
    --quiet --eval "$ping_eval" >/dev/null 2>&1; do
  sleep 1
done

if [ ! -f "$host_seed" ]; then
  echo "Seed file not found on host at $host_seed" >&2
  exit 1
fi

docker compose exec -T "$service" mkdir -p "$(dirname "$seed_file")"
docker compose cp "$host_seed" "$service":"$seed_file"

echo "Running Mongo init script: $seed_file"
docker compose exec -T "$service" \
  mongosh --username "$mongo_user" --password "$mongo_pass" --authenticationDatabase admin \
    --file "$seed_file"

until docker compose exec -T "$service" \
  mongosh --username "$mongo_user" --password "$mongo_pass" --authenticationDatabase admin \
    --quiet --eval "$db_exists_eval" >/dev/null 2>&1; do
  sleep 1
done

echo "Database '$target_db' updated"
