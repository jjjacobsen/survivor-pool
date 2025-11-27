Place MongoDB initialization scripts in this directory.
Use idempotent operations (e.g., `updateOne` with `upsert: true`).
Season canon lives in `../seasons` and must sit next to `init.js` inside the container (default: `/app/mongo-init/seasons`).

Manual load

- Dev one-liner: `docker exec -it dev-mongo mongosh --eval 'load("/app/mongo-init/init.js")'` (with `/app/mongo-init/seasons` copied)
- Dev alt: `docker exec -it dev-mongo mongosh --file /app/mongo-init/init.js`
- Prod: `docker compose exec mongo mongosh --file /app/mongo-init/init.js`

Interactive mongosh

- Dev: `docker exec -it dev-mongo mongosh`
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
