// Initialize Survivor season data (idempotent)
(function () {
  const now = new Date();
  // bind to app database
  var dbApp = db.getSiblingDB("survivor_pool");

  // helper to slugify names to ids
  function idOf(name) { return name.toLowerCase().replace(/[^a-z0-9]+/g, "_").replace(/^_|_$/g, ""); }

  const seasonDocs = [];
  function registerSeason(doc) { seasonDocs.push(doc); }

  const seasonsDir = "/app/mongo-init/seasons";
  const seasonFiles = ["season48.js", "season49.js"];

  globalThis.idOf = idOf;
  globalThis.registerSeason = registerSeason;
  seasonFiles.forEach((file) => load(seasonsDir + "/" + file));
  delete globalThis.idOf;
  delete globalThis.registerSeason;

  seasonDocs.forEach((seasonDoc) => {
    dbApp.seasons.updateOne(
      { season_number: seasonDoc.season_number },
      {
        $set: {
          season_name: seasonDoc.season_name,
          air_date: seasonDoc.air_date,
          location: seasonDoc.location,
          format: seasonDoc.format,
          contestants: seasonDoc.contestants,
          eliminations: seasonDoc.eliminations,
          tribe_timeline: seasonDoc.tribe_timeline,
          advantages: seasonDoc.advantages
        },
        $setOnInsert: { created_at: now }
      },
      { upsert: true }
    );
  });

  const users = dbApp.users;
  const pools = dbApp.pools;
  const poolMemberships = dbApp.pool_memberships;
  const picks = dbApp.picks;
  const seasons = dbApp.seasons;

  users.createIndex({ email: 1 }, { name: "users_email_unique", unique: true });
  users.createIndex({ username: 1 }, { name: "users_username_unique", unique: true });
  users.createIndex({ default_pool: 1 }, { name: "users_default_pool_idx" });
  users.createIndex(
    { verification_token: 1 },
    {
      name: "users_verification_token_unique",
      unique: true,
      partialFilterExpression: { verification_token: { $type: "string" } }
    }
  );

  seasons.createIndex({ season_number: 1 }, { name: "seasons_season_number_unique", unique: true });

  pools.createIndex({ ownerId: 1 }, { name: "pools_owner_idx" });
  pools.createIndex({ seasonId: 1 }, { name: "pools_season_idx" });

  poolMemberships.createIndex(
    { poolId: 1, userId: 1 },
    { name: "pool_memberships_pool_user_unique", unique: true }
  );

  picks.createIndex(
    { poolId: 1, userId: 1, week: 1 },
    { name: "picks_pool_user_week_unique", unique: true }
  );
  picks.createIndex({ poolId: 1, week: 1 }, { name: "picks_pool_week_idx" });

  const spacePasswordHash = "$2b$12$dCJv2DzGaDpGDNkat1ohn.21VPhwo0H/pXvuXOGhKbmHpSmHhQ.DK";

  function collectionExists(dbConn, name) {
    return dbConn.getCollectionInfos({ name }).length > 0;
  }

  [
    {
      username: "test1",
      email: "test1@email.com",
      id: ObjectId("68ccc555f763780fad79e575")
    },
    {
      username: "test2",
      email: "test2@email.com",
      id: ObjectId("68ccc555f763780fad79e576")
    },
    {
      username: "test3",
      email: "test3@email.com",
      id: ObjectId("68ccc555f763780fad79e577")
    }
  ].forEach((account) => {
    users.updateOne(
      { username: account.username },
      {
        $set: {
          email: account.email,
          password_hash: spacePasswordHash,
          account_status: "active",
          email_verified: true,
          verification_token: null,
          verification_verified_at: now,
        },
        $setOnInsert: {
          _id: account.id,
          created_at: now,
          default_pool: null,
          verification_sent_at: now
        }
      },
      { upsert: true }
    );
  });

  const resetUsername = "test";
  const existingTest = users.findOne({ username: resetUsername });
  if (existingTest) {
    const testUserId = existingTest._id;
    const ownedPoolIds = pools
      .find({ ownerId: testUserId }, { _id: 1 })
      .toArray()
      .map((pool) => pool._id);

    if (ownedPoolIds.length) {
      poolMemberships.deleteMany({ poolId: { $in: ownedPoolIds } });
      pools.deleteMany({ _id: { $in: ownedPoolIds } });
      users.updateMany(
        { default_pool: { $in: ownedPoolIds } },
        { $set: { default_pool: null } }
      );
    }

    poolMemberships.deleteMany({ userId: testUserId });

    if (collectionExists(dbApp, "picks")) {
      const pickFilters = [{ userId: testUserId }];
      if (ownedPoolIds.length) {
        pickFilters.push({ poolId: { $in: ownedPoolIds } });
      }
      dbApp.picks.deleteMany({ $or: pickFilters });
    }

    users.deleteOne({ _id: testUserId });
  }

  users.insertOne({
    username: resetUsername,
    email: "test@email.com",
    password_hash: spacePasswordHash,
    account_status: "active",
    created_at: now,
    default_pool: null,
    token_invalidated_at: now,
    email_verified: true,
    verification_token: null,
    verification_verified_at: now,
    verification_sent_at: now
  });
})();
