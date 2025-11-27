// Initialize Survivor season data (idempotent)
(function () {
  const now = new Date();
  // bind to app database
  var dbApp = db.getSiblingDB("survivor_pool");

  function collectionExists(dbConn, name) {
    return dbConn.getCollectionInfos({ name }).length > 0;
  }

  function ensureValidator(collectionName, validator) {
    if (collectionExists(dbApp, collectionName)) {
      dbApp.runCommand({
        collMod: collectionName,
        validator,
        validationLevel: "strict",
        validationAction: "error"
      });
    } else {
      dbApp.createCollection(collectionName, {
        validator,
        validationLevel: "strict",
        validationAction: "error"
      });
    }
  }

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

  const userValidator = {
    $jsonSchema: {
      bsonType: "object",
      required: ["username", "email", "password_hash", "account_status", "email_verified", "created_at"],
      properties: {
        username: { bsonType: "string" },
        email: { bsonType: "string" },
        password_hash: { bsonType: "string" },
        account_status: { bsonType: "string" },
        email_verified: { bsonType: "bool" },
        created_at: { bsonType: "date" },
        default_pool: { bsonType: ["objectId", "null"] },
        verification_token: { bsonType: ["string", "null"] },
        verification_sent_at: { bsonType: ["date", "null"] },
        verification_verified_at: { bsonType: ["date", "null"] },
        token_invalidated_at: { bsonType: ["date", "null"] },
        failed_login_attempts: { bsonType: ["int", "long"] },
        locked_until: { bsonType: ["date", "null"] },
        reset_token: { bsonType: ["string", "null"] },
        reset_token_expires_at: { bsonType: ["date", "null"] }
      }
    }
  };

  const poolValidator = {
    $jsonSchema: {
      bsonType: "object",
      required: ["name", "ownerId", "seasonId", "created_at", "current_week", "start_week", "status"],
      properties: {
        name: { bsonType: "string" },
        ownerId: { bsonType: "objectId" },
        seasonId: { bsonType: "objectId" },
        created_at: { bsonType: "date" },
        current_week: { bsonType: ["int", "long"] },
        start_week: { bsonType: ["int", "long"] },
        settings: { bsonType: "object" },
        status: { bsonType: "string" },
        is_competitive: { bsonType: "bool" },
        competitive_since_week: { bsonType: ["int", "long", "null"] },
        completed_week: { bsonType: ["int", "long", "null"] },
        completed_at: { bsonType: ["date", "null"] },
        winners: { bsonType: "array", items: { bsonType: "objectId" } }
      }
    }
  };

  const poolMembershipValidator = {
    $jsonSchema: {
      bsonType: "object",
      required: ["poolId", "userId", "role", "status", "score"],
      properties: {
        poolId: { bsonType: "objectId" },
        userId: { bsonType: "objectId" },
        role: { bsonType: "string" },
        status: { bsonType: "string" },
        joinedAt: { bsonType: ["date", "null"] },
        invitedAt: { bsonType: ["date", "null"] },
        elimination_reason: { bsonType: ["string", "null"] },
        eliminated_week: { bsonType: ["int", "long", "null"] },
        eliminated_date: { bsonType: ["date", "null"] },
        available_contestants: { bsonType: "array", items: { bsonType: "string" } },
        score: { bsonType: ["int", "long"] },
        final_rank: { bsonType: ["int", "long", "null"] },
        finished_week: { bsonType: ["int", "long", "null"] },
        finished_date: { bsonType: ["date", "null"] }
      }
    }
  };

  const picksValidator = {
    $jsonSchema: {
      bsonType: "object",
      required: ["poolId", "userId", "contestant_id", "week", "result", "created_at"],
      properties: {
        poolId: { bsonType: "objectId" },
        userId: { bsonType: "objectId" },
        contestant_id: { bsonType: "string" },
        week: { bsonType: ["int", "long"] },
        created_at: { bsonType: "date" },
        result: { bsonType: "string" },
        result_date: { bsonType: ["date", "null"] }
      }
    }
  };

  const seasonsValidator = {
    $jsonSchema: {
      bsonType: "object",
      required: ["season_name", "season_number", "air_date", "location", "format", "contestants", "eliminations", "tribe_timeline"],
      properties: {
        season_name: { bsonType: "string" },
        season_number: { bsonType: ["int", "long", "double"] },
        air_date: { bsonType: "date" },
        location: { bsonType: "string" },
        format: { bsonType: "string" },
        created_at: { bsonType: "date" },
        contestants: {
          bsonType: "array",
          items: {
            bsonType: "object",
            required: ["id", "name"],
            properties: {
              id: { bsonType: "string" },
              name: { bsonType: "string" },
              age: { bsonType: ["int", "long", "double", "null"] },
              occupation: { bsonType: ["string", "null"] },
              hometown: { bsonType: ["string", "null"] }
            }
          }
        },
        eliminations: {
          bsonType: "array",
          items: {
            bsonType: "object",
            required: ["week"],
            properties: {
              week: { bsonType: ["int", "long", "double"] },
              eliminated_contestant_id: { bsonType: ["string", "null"] }
            }
          }
        },
        tribe_timeline: {
          bsonType: "array",
          items: {
            bsonType: "object",
            required: ["week", "tribes"],
            properties: {
              week: { bsonType: ["int", "long", "double"] },
              event: { bsonType: ["string", "null"] },
              tribes: {
                bsonType: "array",
                items: {
                  bsonType: "object",
                  required: ["name", "members"],
                  properties: {
                    name: { bsonType: "string" },
                    color: { bsonType: ["string", "null"] },
                    members: { bsonType: "array", items: { bsonType: "string" } }
                  }
                }
              }
            }
          }
        },
        advantages: {
          bsonType: "array",
          items: {
            bsonType: "object",
            required: ["id", "advantage_type", "contestant_id", "obtained_week", "status"],
            properties: {
              id: { bsonType: "string" },
              advantage_type: { bsonType: "string" },
              advantage_display_name: { bsonType: ["string", "null"] },
              contestant_id: { bsonType: "string" },
              obtained_week: { bsonType: ["int", "long", "double"] },
              status: { bsonType: "string" },
              played_week: { bsonType: ["int", "long", "double", "null"] },
              transferred_to: { bsonType: ["string", "null"] },
              notes: { bsonType: ["string", "null"] }
            }
          }
        }
      }
    }
  };

  ensureValidator("users", userValidator);
  ensureValidator("pools", poolValidator);
  ensureValidator("pool_memberships", poolMembershipValidator);
  ensureValidator("picks", picksValidator);
  ensureValidator("seasons", seasonsValidator);

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
  users.createIndex(
    { reset_token: 1 },
    {
      name: "users_reset_token_unique",
      unique: true,
      partialFilterExpression: { reset_token: { $type: "string" } }
    }
  );

  seasons.createIndex({ season_number: 1 }, { name: "seasons_season_number_unique", unique: true });
  seasons.createIndex({ season_name: 1 }, { name: "seasons_season_name_idx" });
  seasons.createIndex({ "contestants.id": 1 }, { name: "seasons_contestant_id_idx" });
  seasons.createIndex({ "advantages.contestant_id": 1 }, { name: "seasons_advantage_holder_idx" });
  seasons.createIndex({ "advantages.status": 1 }, { name: "seasons_advantage_status_idx" });

  pools.createIndex({ ownerId: 1 }, { name: "pools_owner_idx" });
  pools.createIndex({ seasonId: 1 }, { name: "pools_season_idx" });

  poolMemberships.createIndex(
    { poolId: 1, userId: 1 },
    { name: "pool_memberships_pool_user_unique", unique: true }
  );
  poolMemberships.createIndex({ userId: 1 }, { name: "pool_memberships_user_idx" });
  poolMemberships.createIndex({ poolId: 1 }, { name: "pool_memberships_pool_idx" });
  poolMemberships.createIndex({ poolId: 1, status: 1 }, { name: "pool_memberships_pool_status_idx" });

  picks.createIndex(
    { poolId: 1, userId: 1, week: 1 },
    { name: "picks_pool_user_week_unique", unique: true }
  );
  picks.createIndex({ poolId: 1, week: 1 }, { name: "picks_pool_week_idx" });
  picks.createIndex({ userId: 1, poolId: 1 }, { name: "picks_user_pool_idx" });
  picks.createIndex({ poolId: 1, contestant_id: 1 }, { name: "picks_pool_contestant_idx" });
  picks.createIndex({ result: 1 }, { name: "picks_result_idx" });

  const spacePasswordHash = process.env.SPACE_PASSWORD_HASH;
  if (!spacePasswordHash) {
    throw new Error("SPACE_PASSWORD_HASH is required");
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
