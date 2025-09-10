Place MongoDB initialization scripts in this directory.
Files with `.js` or `.sh` extensions run at first-time DB init via `/docker-entrypoint-initdb.d`.
Use idempotent operations (e.g., `updateOne` with `upsert: true`).

Manual load (when volume already exists)

- One-liner: `docker exec -it dev-mongo mongosh --eval 'load("/docker-entrypoint-initdb.d/season48.js")'`
- Alt: `docker exec -it dev-mongo mongosh --file /docker-entrypoint-initdb.d/season48.js`

Interactive mongosh

- `docker exec -it dev-mongo mongosh`
- `load("/docker-entrypoint-initdb.d/season48.js")`
- Verify: `db.getSiblingDB('survivor_pool').seasons.findOne({season_number:48},{season_name:1})`
