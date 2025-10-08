Place MongoDB initialization scripts in this directory.
Use idempotent operations (e.g., `updateOne` with `upsert: true`).

Manual load

- Dev one-liner: `docker exec -it dev-mongo mongosh --eval 'load("/app/mongo-init/init.js")'`
- Dev alt: `docker exec -it dev-mongo mongosh --file /app/mongo-init/init.js`
- Prod: `docker compose exec mongo mongosh --file /init-scripts/init.js`

Interactive mongosh

- Dev: `docker exec -it dev-mongo mongosh`
- Prod: `docker compose exec -it mongo mongosh`
- Load dev script: `load("/app/mongo-init/init.js")`
- Load prod script: `load("/init-scripts/init.js")`
- Verify: `db.getSiblingDB('survivor_pool').seasons.findOne({season_number:48},{season_name:1})`
