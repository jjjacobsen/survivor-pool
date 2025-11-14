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
    { name: "Kyle Fraser", age: 30, hometown: "Brooklyn, NY", occupation: "Digital Strategist" },
    { name: "Eva Erickson", age: 23, hometown: "Providence, RI", occupation: "Biotech Researcher" },
    { name: "Joe Hunter", age: 45, hometown: "West Sacramento, CA", occupation: "Firefighter" },
    { name: "Kamilla Karthigesu", age: 30, hometown: "Foster City, CA", occupation: "Product Manager" },
    { name: "David Kinne", age: 38, hometown: "Buena Park, CA", occupation: "Elementary Teacher" },
    { name: "Chrissy Sarnowsky", age: 54, hometown: "Chicago, IL", occupation: "Tax Consultant" },
    { name: "Mitch Guerra", age: 34, hometown: "Waco, TX", occupation: "Fitness Coach" },
    { name: "Shauhin Davari", age: 37, hometown: "Costa Mesa, CA", occupation: "Sports Agent" },
    { name: "Mary Zheng", age: 30, hometown: "Philadelphia, PA", occupation: "Data Analyst" },
    { name: "Star Toomey", age: 27, hometown: "Augusta, GA", occupation: "Graphic Designer" },
    { name: "Cedrek McFadden", age: 45, hometown: "Greenville, SC", occupation: "Youth Pastor" },
    { name: "Saiounia Hughley", age: 29, hometown: "Simi Valley, CA", occupation: "Marketing Specialist" },
    { name: "Charity Nelms", age: 33, hometown: "St. Petersburg, FL", occupation: "Real Estate Broker" },
    { name: "Bianca Roses", age: 32, hometown: "Arlington, VA", occupation: "Public Defender" },
    { name: "Thomas Krottinger", age: 34, hometown: "Los Angeles, CA", occupation: "Entrepreneur" },
    { name: "Justin Pioppi", age: 29, hometown: "Winthrop, MA", occupation: "Bartender" },
    { name: "Kevin Leung", age: 33, hometown: "Livermore, CA", occupation: "Mechanical Engineer" },
    { name: "Stephanie Berger", age: 37, hometown: "Brooklyn, NY", occupation: "Nurse Practitioner" }
  ].map(c => ({
    id: idOf(c.name),
    name: c.name,
    age: c.age,
    occupation: c.occupation,
    hometown: c.hometown
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
          idOf("Mary Zheng"), idOf("Shauhin Davari"), idOf("Star Toomey"), idOf("Thomas Krottinger"), idOf("Charity Nelms")
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

  // Initialize Survivor Season 49 (data current through week 3)
  const season49Number = 49;

  const contestants49 = [
    { name: "Nicole Mazullo", age: 26, hometown: "Philadelphia, PA", occupation: "Financial crime consultant" },
    { name: "Kimberly \"Annie\" Davis", age: 49, hometown: "Austin, TX", occupation: "Musician" },
    { name: "Sage Ahrens-Nichols", age: 30, hometown: "Olympia, WA", occupation: "Clinical social worker" },
    { name: "Sophia \"Sophi\" Balerdi", age: 27, hometown: "Miami, FL", occupation: "Entrepreneur" },
    { name: "Michelle \"MC\" Chukwujekwu", age: 29, hometown: "San Diego, CA", occupation: "Fitness trainer" },
    { name: "Shannon Fairweather", age: 28, hometown: "Boston, MA", occupation: "Wellness specialist" },
    { name: "Jeremiah Ing", age: 39, hometown: "Toronto, Ontario", occupation: "Global events manager" },
    { name: "Jake Latimer", age: 36, hometown: "St. Albert, Alberta", occupation: "Correctional officer" },
    { name: "Savannah Louie", age: 31, hometown: "Atlanta, GA", occupation: "Former reporter" },
    { name: "Kristina Mills", age: 36, hometown: "Edmond, OK", occupation: "MBA career coach" },
    { name: "Alex Moore", age: 27, hometown: "Washington, DC", occupation: "Political comms director" },
    { name: "Nate Moore", age: 47, hometown: "Hermosa Beach, CA", occupation: "Film producer" },
    { name: "Jawan Pitts", age: 28, hometown: "Los Angeles, CA", occupation: "Video editor" },
    { name: "Steven Ramm", age: 35, hometown: "Denver, CO", occupation: "Rocket scientist" },
    { name: "Sophia \"Sophie\" Segreti", age: 31, hometown: "New York City, NY", occupation: "Strategy associate" },
    { name: "Jason Treul", age: 32, hometown: "Santa Ana, CA", occupation: "Law clerk" },
    { name: "Rizo Velovic", age: 25, hometown: "Yonkers, NY", occupation: "Tech sales" },
    { name: "Matthew \"Matt\" Williams", age: 52, hometown: "St. George, UT", occupation: "Airport ramp agent" }
  ].map(c => ({
    id: idOf(c.name),
    name: c.name,
    age: c.age,
    occupation: c.occupation,
    hometown: c.hometown
  }));

  const eliminations49 = [
    { week: 1, eliminated_contestant_id: idOf("Nicole Mazullo") },
    { week: 2, eliminated_contestant_id: idOf("Kimberly \"Annie\" Davis") },
    { week: 3, eliminated_contestant_id: idOf("Jake Latimer") },
    { week: 3, eliminated_contestant_id: idOf("Jeremiah Ing") }
  ];

  const tribeTimeline49 = [
    {
      week: 1,
      event: "start",
      tribes: [
        {
          name: "Kele",
          color: "#32AAD6",
          members: [
            idOf("Nicole Mazullo"),
            idOf("Kimberly \"Annie\" Davis"),
            idOf("Sophia \"Sophi\" Balerdi"),
            idOf("Jeremiah Ing"),
            idOf("Jake Latimer"),
            idOf("Alex Moore")
          ]
        },
        {
          name: "Uli",
          color: "#F26B52",
          members: [
            idOf("Sage Ahrens-Nichols"),
            idOf("Shannon Fairweather"),
            idOf("Savannah Louie"),
            idOf("Nate Moore"),
            idOf("Jawan Pitts"),
            idOf("Rizo Velovic")
          ]
        },
        {
          name: "Hina",
          color: "#FEDA47",
          members: [
            idOf("Michelle \"MC\" Chukwujekwu"),
            idOf("Kristina Mills"),
            idOf("Steven Ramm"),
            idOf("Sophia \"Sophie\" Segreti"),
            idOf("Jason Treul"),
            idOf("Matthew \"Matt\" Williams")
          ]
        }
      ]
    }
  ];

  const advantages49 = [
    {
      id: "idol_alex_moore_1",
      advantage_type: "hidden_immunity_idol",
      contestant_id: idOf("Alex Moore"),
      obtained_week: 2,
      status: "active",
      played_week: null,
      transferred_to: null,
      notes: "Alex completed the beware activation steps on Kele in week 2; idol currently active"
    },
    {
      id: "idol_mc_chukwujekwu_1",
      advantage_type: "hidden_immunity_idol",
      contestant_id: idOf("Michelle \"MC\" Chukwujekwu"),
      obtained_week: 3,
      status: "active",
      played_week: null,
      transferred_to: null,
      notes: "MC unearthed Hina's beware idol in week 3; activation tasks still underway"
    },
    {
      id: "idol_rizo_velovic_1",
      advantage_type: "hidden_immunity_idol",
      contestant_id: idOf("Rizo Velovic"),
      obtained_week: 3,
      status: "active",
      played_week: null,
      transferred_to: null,
      notes: "Rizo located Uli's beware idol in week 3; activation tasks still underway"
    }
  ];

  const season49Doc = {
    season_name: "Survivor 49",
    season_number: season49Number,
    air_date: new Date("2025-09-24T00:00:00Z"),
    location: "Fiji",
    format: "new_era",
    created_at: now,
    contestants: contestants49,
    eliminations: eliminations49,
    tribe_timeline: tribeTimeline49,
    advantages: advantages49
  };

  dbApp.seasons.updateOne(
    { season_number: season49Number },
    {
      $set: {
        season_name: season49Doc.season_name,
        air_date: season49Doc.air_date,
        location: season49Doc.location,
        format: season49Doc.format,
        contestants: season49Doc.contestants,
        eliminations: season49Doc.eliminations,
        tribe_timeline: season49Doc.tribe_timeline,
        advantages: season49Doc.advantages
      },
      $setOnInsert: { created_at: now }
    },
    { upsert: true }
  );

  const users = dbApp.users;
  const pools = dbApp.pools;
  const poolMemberships = dbApp.pool_memberships;
  const picks = dbApp.picks;
  const seasons = dbApp.seasons;

  users.createIndex({ email: 1 }, { name: "users_email_unique", unique: true });
  users.createIndex({ username: 1 }, { name: "users_username_unique", unique: true });
  users.createIndex({ default_pool: 1 }, { name: "users_default_pool_idx" });

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
          account_status: "active",
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
    default_pool: null,
    token_invalidated_at: now
  });
})();
