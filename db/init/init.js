// Initialize Survivor Season 48 static TV facts (idempotent)
// Uses upsert to be safe on repeated container starts
(function () {
  const seasonNumber = 48;
  const now = new Date();
  // bind to app database
  var dbApp = db.getSiblingDB("survivor_pool");

  // helper to slugify names to ids
  function idOf(name) { return name.toLowerCase().replace(/[^a-z0-9]+/g, "_").replace(/^_|_$/g, ""); }

  const contestants = [
    { name: "Kyle Fraser", age: 30, hometown: "Brooklyn, NY", initial_tribe: "Civa" },
    { name: "Eva Erickson", age: 23, hometown: "Providence, RI", initial_tribe: "Lagi" },
    { name: "Joe Hunter", age: 45, hometown: "West Sacramento, CA", initial_tribe: "Lagi" },
    { name: "Kamilla Karthigesu", age: 30, hometown: "Foster City, CA", initial_tribe: "Vula" },
    { name: "David Kinne", age: 38, hometown: "Buena Park, CA", initial_tribe: "Civa" },
    { name: "Chrissy Sarnowsky", age: 54, hometown: "Chicago, IL", initial_tribe: "Civa" },
    { name: "Mitch Guerra", age: 34, hometown: "Waco, TX", initial_tribe: "Civa" },
    { name: "Shauhin Davari", age: 37, hometown: "Costa Mesa, CA", initial_tribe: "Lagi" },
    { name: "Mary Zheng", age: 30, hometown: "Philadelphia, PA", initial_tribe: "Vula" },
    { name: "Star Toomey", age: 27, hometown: "Augusta, GA", initial_tribe: "Lagi" },
    { name: "Cedrek McFadden", age: 45, hometown: "Greenville, SC", initial_tribe: "Vula" },
    { name: "Saiounia Hughley", age: 29, hometown: "Simi Valley, CA", initial_tribe: "Vula" },
    { name: "Charity Nelms", age: 33, hometown: "St. Petersburg, FL", initial_tribe: "Civa" },
    { name: "Bianca Roses", age: 32, hometown: "Arlington, VA", initial_tribe: "Lagi" },
    { name: "Thomas Krottinger", age: 34, hometown: "Los Angeles, CA", initial_tribe: "Lagi" },
    { name: "Justin Pioppi", age: 29, hometown: "Winthrop, MA", initial_tribe: "Vula" },
    { name: "Kevin Leung", age: 33, hometown: "Livermore, CA", initial_tribe: "Vula" },
    { name: "Stephanie Berger", age: 37, hometown: "Brooklyn, NY", initial_tribe: "Vula" }
  ].map(c => ({
    id: idOf(c.name),
    name: c.name,
    age: c.age,
    occupation: null,
    hometown: c.hometown,
    photo_url: null,
    bio: null,
    initial_tribe: c.initial_tribe
  }));

  // Elimination order by air week (double boots share the same week number)
  const eliminations = [
    { week: 1, eliminated_contestant_id: idOf("Stephanie Berger") },
    { week: 2, eliminated_contestant_id: idOf("Kevin Leung") },
    { week: 3, eliminated_contestant_id: idOf("Justin Pioppi") },
    { week: 4, eliminated_contestant_id: idOf("Thomas Krottinger") },
    { week: 5, eliminated_contestant_id: idOf("Bianca Roses") },
    { week: 6, eliminated_contestant_id: idOf("Charity Nelms") },
    { week: 7, eliminated_contestant_id: idOf("Saiounia Hughley") },
    { week: 7, eliminated_contestant_id: idOf("Cedrek McFadden") },
    { week: 8, eliminated_contestant_id: idOf("Chrissy Sarnowsky") },
    { week: 9, eliminated_contestant_id: idOf("David Kinne") },
    { week: 10, eliminated_contestant_id: idOf("Star Toomey") },
    { week: 11, eliminated_contestant_id: idOf("Mary Zheng") },
    { week: 12, eliminated_contestant_id: idOf("Shauhin Davari") },
    { week: 13, eliminated_contestant_id: idOf("Mitch Guerra") },
    // Fire-making elimination at Final 4 (treated as elimination for completeness)
    { week: 13, eliminated_contestant_id: idOf("Kamilla Karthigesu") }
  ];

  // Tribe timeline (start, swap (best-effort), merge)
  const tribeTimeline = [
    {
      week: 1,
      event: "start",
      tribes: [
        { name: "Lagi", color: "purple", members: [
          idOf("Joe Hunter"), idOf("Eva Erickson"), idOf("Thomas Krottinger"), idOf("Star Toomey"), idOf("Shauhin Davari"), idOf("Bianca Roses")
        ]},
        { name: "Civa", color: "orange", members: [
          idOf("Kyle Fraser"), idOf("Kamilla Karthigesu"), idOf("David Kinne"), idOf("Chrissy Sarnowsky"), idOf("Mitch Guerra"), idOf("Charity Nelms")
        ]},
        { name: "Vula", color: "green", members: [
          idOf("Saiounia Hughley"), idOf("Cedrek McFadden"), idOf("Mary Zheng"), idOf("Kevin Leung"), idOf("Justin Pioppi"), idOf("Stephanie Berger")
        ]}
      ]
    },
    {
      week: 4,
      event: "swap",
      notes: "Three-tribe swap to 5-5-5; membership best-effort from aired data",
      tribes: [
        { name: "Lagi", color: "purple", members: [
          idOf("Joe Hunter"), idOf("Eva Erickson"), idOf("Kyle Fraser"), idOf("Kamilla Karthigesu"), idOf("David Kinne")
        ]},
        { name: "Civa", color: "orange", members: [
          idOf("Mitch Guerra"), idOf("Chrissy Sarnowsky"), idOf("Bianca Roses"), idOf("Saiounia Hughley"), idOf("Cedrek McFadden")
        ]},
        { name: "Vula", color: "green", members: [
          idOf("Mary Zheng"), idOf("Shauhin Davari"), idOf("Star Toomey"), idOf("Thomas Krottinger")
          // fifth member uncertain from public summaries; omitted intentionally
        ]}
      ]
    },
    {
      week: 7,
      event: "merge",
      tribes: [
        { name: "Niu Nai", color: "blue", members: [
          idOf("Joe Hunter"), idOf("Eva Erickson"), idOf("Kyle Fraser"), idOf("Kamilla Karthigesu"), idOf("David Kinne"), idOf("Chrissy Sarnowsky"), idOf("Mitch Guerra"), idOf("Shauhin Davari"), idOf("Mary Zheng"), idOf("Star Toomey"), idOf("Cedrek McFadden"), idOf("Saiounia Hughley")
        ]}
      ]
    }
  ];

  // Advantages timeline (key events captured from episode summaries)
  const advantages = [
    {
      id: "idol_saiounia_1",
      advantage_type: "hidden_immunity_idol",
      contestant_id: idOf("Saiounia Hughley"),
      obtained_week: 1,
      status: "played",
      played_week: 2,
      transferred_to: null,
      notes: "Found via Beware Advantage on Vula; played to negate Kevin's vote"
    },
    {
      id: "idol_kyle_1",
      advantage_type: "hidden_immunity_idol",
      contestant_id: idOf("Kyle Fraser"),
      obtained_week: 2,
      status: "played",
      played_week: 4,
      transferred_to: null,
      notes: "Found on Civa with Kamilla's help; played after swap to blindside Thomas"
    },
    {
      id: "idol_star_1",
      advantage_type: "hidden_immunity_idol",
      contestant_id: idOf("Star Toomey"),
      obtained_week: 2,
      status: "transferred",
      played_week: null,
      transferred_to: idOf("Eva Erickson"),
      notes: "Star found Beware Advantage on Lagi; gave idol to Eva around week 5"
    },
    {
      id: "block_vote_mitch_1",
      advantage_type: "block_a_vote",
      contestant_id: idOf("Mitch Guerra"),
      obtained_week: 2,
      status: "played",
      played_week: 7,
      transferred_to: null,
      notes: "Won on journey; played against Saiounia at merge (she couldn't vote)"
    },
    {
      id: "steal_vote_thomas_1",
      advantage_type: "steal_a_vote",
      contestant_id: idOf("Thomas Krottinger"),
      obtained_week: 2,
      status: "expired",
      played_week: null,
      transferred_to: null,
      notes: "Won on journey; left the game with it unused"
    },
    {
      id: "extra_vote_kamilla_1",
      advantage_type: "extra_vote",
      contestant_id: idOf("Kamilla Karthigesu"),
      obtained_week: 3,
      status: "transferred",
      played_week: null,
      transferred_to: idOf("Kyle Fraser"),
      notes: "Secretly gave Kyle an extra vote pre-merge"
    },
    {
      id: "safety_without_power_eva_1",
      advantage_type: "safety_without_power",
      contestant_id: idOf("Eva Erickson"),
      obtained_week: 10,
      status: "expired",
      played_week: null,
      transferred_to: null,
      notes: "Cascading risk game at night; kept SWOP, not used"
    }
  ];

  const seasonDoc = {
    season_name: "Survivor 48",
    season_number: seasonNumber,
    air_date: new Date("2025-02-26T00:00:00Z"),
    location: "Fiji",
    format: "new_era",
    created_at: now,
    contestants,
    eliminations,
    tribe_timeline: tribeTimeline,
    advantages
  };

  dbApp.seasons.updateOne(
    { season_number: seasonNumber },
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

  const users = dbApp.users;
  const pools = dbApp.pools;
  const poolMemberships = dbApp.pool_memberships;
  const spacePasswordHash = "$2b$12$dCJv2DzGaDpGDNkat1ohn.21VPhwo0H/pXvuXOGhKbmHpSmHhQ.DK";

  function collectionExists(dbConn, name) {
    return dbConn.getCollectionInfos({ name }).length > 0;
  }

  [
    {
      username: "test1",
      email: "test1@email.com",
      display_name: "test1",
      id: ObjectId("68ccc555f763780fad79e575")
    },
    {
      username: "test2",
      email: "test2@email.com",
      display_name: "test2",
      id: ObjectId("68ccc555f763780fad79e576")
    },
    {
      username: "test3",
      email: "test3@email.com",
      display_name: "test3",
      id: ObjectId("68ccc555f763780fad79e577")
    }
  ].forEach((account) => {
    users.updateOne(
      { username: account.username },
      {
        $set: {
          email: account.email,
          password_hash: spacePasswordHash,
          display_name: account.display_name,
          account_status: "active"
        },
        $setOnInsert: {
          _id: account.id,
          created_at: now,
          default_pool: null
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
    display_name: resetUsername,
    account_status: "active",
    created_at: now,
    default_pool: null
  });
})();
