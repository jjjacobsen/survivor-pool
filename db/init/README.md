Place MongoDB initialization scripts in this directory.
Use idempotent operations (e.g., `updateOne` with `upsert: true`).

Manual load

- One-liner: `docker exec -it dev-mongo mongosh --eval 'load("/app/mongo-init/init.js")'`
- Alt: `docker exec -it dev-mongo mongosh --file /app/mongo-init/init.js`

Interactive mongosh

- `docker exec -it dev-mongo mongosh`
- `load("/app/mongo-init/init.js")`
- Verify: `db.getSiblingDB('survivor_pool').seasons.findOne({season_number:48},{season_name:1})`
