#!/usr/bin/env bash
set -euo pipefail

container=${1:-dev-mongo}
target_db=${2:-survivor_pool}
container_db_dir=${5:-/app/mongo-init}
seed_file=${3:-"$container_db_dir/init.js"}
host_db_dir=${4:-db}
host_init="$host_db_dir/init.js"
host_seasons_dir="$host_db_dir/seasons"

env_file=${ENV_FILE:-.env.dev}

if [ ! -f "$env_file" ]; then
  echo "Missing $env_file for Mongo env vars" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$env_file"

space_password_hash=${SPACE_PASSWORD_HASH:-}

if [ -z "$space_password_hash" ]; then
  echo "Missing SPACE_PASSWORD_HASH in $env_file" >&2
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

until docker exec "$container" \
  mongosh --quiet --eval "$ping_eval" >/dev/null 2>&1; do
  sleep 1
done

if [ ! -d "$host_db_dir" ]; then
  echo "DB directory not found on host at $host_db_dir" >&2
  exit 1
fi

if [ ! -f "$host_init" ]; then
  echo "Seed file not found on host at $host_init" >&2
  exit 1
fi

if [ ! -d "$host_seasons_dir" ]; then
  echo "Seasons directory not found on host at $host_seasons_dir" >&2
  exit 1
fi

docker exec "$container" mkdir -p "$container_db_dir"
docker cp "$host_db_dir"/. "$container":"$container_db_dir"

echo "Running Mongo init script: $seed_file"
docker exec -e SPACE_PASSWORD_HASH="$space_password_hash" "$container" mongosh --file "$seed_file"

until docker exec "$container" \
  mongosh --quiet --eval "$db_exists_eval" >/dev/null 2>&1; do
  sleep 1
done

exec docker exec -it "$container" mongosh "$target_db"
