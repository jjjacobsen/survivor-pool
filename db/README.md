Place MongoDB initialization scripts in this directory.
Use idempotent operations (e.g., `updateOne` with `upsert: true`).
Season canon lives in `./seasons` and should be copied alongside `init.js` inside the container (default root: `/app/mongo-init`).

Update (container `survivor-mongo` must already be running)

- Dev/local: `mise run db-update -- --dev` (uses `.env.dev`)
- Prod compose: `mise run db-update -- --prod` (uses `.env.prod`; same container name)

Manual load

- Dev: `docker exec -e SPACE_PASSWORD_HASH="$SPACE_PASSWORD_HASH" -it survivor-mongo mongosh --file /app/mongo-init/init.js`
- Prod: `docker exec -e SPACE_PASSWORD_HASH="$SPACE_PASSWORD_HASH" survivor-mongo sh -c 'mongosh --username "$MONGO_INITDB_ROOT_USERNAME" --password "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin --file /app/mongo-init/init.js"'`

Interactive mongosh

- Dev: `docker exec -it survivor-mongo mongosh`
- Prod: `docker compose exec -it mongo mongosh`
- Load dev script: `load("/app/mongo-init/init.js")`
- Load prod script: `load("/app/mongo-init/init.js")`
- Verify: `db.getSiblingDB('survivor_pool').seasons.findOne({season_number:48},{season_name:1})`
- Prod auth inside container:

  ```bash
  mongosh --username "$MONGO_INITDB_ROOT_USERNAME" \
    --password "$MONGO_INITDB_ROOT_PASSWORD" \
    --authenticationDatabase admin \
    mongodb://127.0.0.1:27017/survivor_pool
  ```

Indexes

- List indexes on current DB: `db.getCollectionInfos().forEach(c => print(c.name, JSON.stringify(db.getCollection(c.name).getIndexes(), null, 2)))`
- Specific collection example: `db.getCollection('picks').getIndexes()`
