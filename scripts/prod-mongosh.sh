#!/usr/bin/env bash
set -euo pipefail
source .env.prod

service=${1:-mongo}
target_db=${2:-survivor_pool}
seed_file=${3:-/app/mongo-init/init.js}
host_seed=${4:-db/init/init.js}
seasons_host_dir=${5:-db/seasons}
seasons_container_dir=${6:-/app/mongo-init/seasons}

mongo_user=${MONGO_INITDB_ROOT_USERNAME:-}
mongo_pass=${MONGO_INITDB_ROOT_PASSWORD:-}
space_password_hash=${SPACE_PASSWORD_HASH:-}

if [ -z "$mongo_user" ] || [ -z "$mongo_pass" ]; then
  echo "Missing MONGO_INITDB_ROOT_USERNAME or MONGO_INITDB_ROOT_PASSWORD" >&2
  exit 1
fi

if [ -z "$space_password_hash" ]; then
  echo "Missing SPACE_PASSWORD_HASH in .env.prod" >&2
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

if [ ! -d "$seasons_host_dir" ]; then
  echo "Seasons directory not found on host at $seasons_host_dir" >&2
  exit 1
fi

docker compose exec -T "$service" mkdir -p "$(dirname "$seed_file")"
docker compose cp "$host_seed" "$service":"$seed_file"
docker compose exec -T "$service" mkdir -p "$seasons_container_dir"
docker compose cp "$seasons_host_dir"/. "$service":"$seasons_container_dir"

echo "Running Mongo init script: $seed_file"
docker compose exec -T -e SPACE_PASSWORD_HASH="$space_password_hash" "$service" \
  mongosh --username "$mongo_user" --password "$mongo_pass" --authenticationDatabase admin \
    --file "$seed_file"

until docker compose exec -T "$service" \
  mongosh --username "$mongo_user" --password "$mongo_pass" --authenticationDatabase admin \
    --quiet --eval "$db_exists_eval" >/dev/null 2>&1; do
  sleep 1
done

echo "Database '$target_db' updated"
