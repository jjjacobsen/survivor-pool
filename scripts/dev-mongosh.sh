#!/usr/bin/env bash
set -euo pipefail

container=${1:-dev-mongo}
target_db=${2:-survivor_pool}
seed_file=${3:-/app/mongo-init/init.js}
host_seed=${4:-db/init/init.js}

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

if [ ! -f "$host_seed" ]; then
  echo "Seed file not found on host at $host_seed" >&2
  exit 1
fi

docker exec "$container" mkdir -p "$(dirname "$seed_file")"
docker cp "$host_seed" "$container":"$seed_file"

echo "Running Mongo init script: $seed_file"
docker exec "$container" mongosh --file "$seed_file"

until docker exec "$container" \
  mongosh --quiet --eval "$db_exists_eval" >/dev/null 2>&1; do
  sleep 1
done

exec docker exec -it "$container" mongosh "$target_db"
