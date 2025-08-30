# Database Schema

## Overview

This document describes the MongoDB schema design for the survivor pool application. The design follows a clean separation of concerns with normalized data to eliminate duplication and ensure data integrity.

## Core Design Philosophy

- **Single Source of Truth**: Season data represents immutable facts about what happened on TV
- **Zero Duplication**: Shared data is referenced, not copied
- **Clean Separation**: Pools are game containers, seasons are data, picks are user actions
- **MongoDB Best Practices**: Proper use of references for shared data, embedding for ownership

## Collections

### 1. `users` Collection

Stores user account information.

```javascript
{
  _id: ObjectId("..."),
  name: "John Doe",
  email: "john@example.com",
  default_pool: ObjectId("..."), // reference to pools collection, null if no pools joined
  created_at: ISODate("..."),
  // ... other user fields
}
```

### 2. `seasons` Collection

Single source of truth for all Survivor season data. This data represents immutable facts about what actually happened on the show.

```javascript
{
  _id: ObjectId("..."),
  season_name: "Survivor 47",
  season_number: 47,
  air_date: ISODate("2024-09-18"),
  location: "Fiji",
  format: "new_era",
  created_at: ISODate("..."),

  contestants: [
    {
      id: "teeny_chirichillo",
      name: "Teeny Chirichillo",
      age: 24,
      occupation: "Freelance Writer",
      hometown: "Manahawkin, NJ",
      photo_url: "/images/contestants/teeny_chirichillo.jpg",
      bio: "Ready to outwit, outplay, and outlast in the ultimate game...",
      initial_tribe: "Lavo"
    },
    {
      id: "kishan_patel",
      name: "Kishan Patel",
      age: 28,
      occupation: "ER Doctor",
      hometown: "San Francisco, CA",
      photo_url: "/images/contestants/kishan_patel.jpg",
      bio: "Bringing strategic thinking and quick decision making...",
      initial_tribe: "Lavo"
    }
    // ... all 18 contestants
  ],

  episodes: [
    {
      episode_number: 1,
      air_date: ISODate("2024-09-18"),
      title: "One Million Dollars",
      eliminated_contestant_id: null, // no elimination in premiere
      immune_contestants: [],
      tribe_changes: []
    },
    {
      episode_number: 2,
      air_date: ISODate("2024-09-25"),
      title: "Scorpio Energy",
      eliminated_contestant_id: "aysha_welch",
      immune_contestants: ["teeny_chirichillo"],
      tribe_changes: []
    }
    // Episodes added as they air - represents what actually happened
  ],

  tribes: [
    {
      name: "Lavo",
      color: "red",
      initial_members: ["teeny_chirichillo", "kishan_patel", "rome_cooney", "aysha_welch", "sol_yi", "genevieve_mushaluk"]
    },
    {
      name: "Gata",
      color: "yellow",
      initial_members: ["sam_layco", "sierra_wright", "rachel_lamont", "anika_dhar", "andy_rueda", "jon_lovett"]
    },
    {
      name: "Tuku",
      color: "blue",
      initial_members: ["caroline_vidmar", "sue_smey", "gabe_ortis", "kyle_ostwald", "tiyana_hallums", "terran_causey"]
    }
  ]
}
```

### 3. `pools` Collection

Clean game containers that reference season data. No embedded cast data.

```javascript
{
  _id: ObjectId("..."),
  name: "Family Survivor Pool",
  ownerId: ObjectId("..."), // reference to user who owns the pool
  seasonId: ObjectId("..."), // reference to seasons collection
  created_at: ISODate("..."),
  current_week: 3,
  settings: {
    pick_deadline_hours: 2, // hours before episode airs
    max_members: 50,
    late_pick_penalty: false
    // other pool-specific configuration
  }
}
```

### 4. `picks` Collection

Individual pick tracking for users in pools. Each document represents one user's pick for one week.

```javascript
{
  _id: ObjectId("..."),
  userId: ObjectId("..."), // reference to users collection
  poolId: ObjectId("..."), // reference to pools collection
  week: 3,
  episode_number: 3,
  contestant_id: "teeny_chirichillo",
  pick_date: ISODate("..."),
  pick_deadline: ISODate("..."),
  result: "pending", // pending, safe, eliminated
  result_date: null,

  // Future analytics fields
  days_until_elimination: null // calculated when contestant is eliminated
}
```

### 5. `pool_memberships` Collection (Enhanced Junction Collection)

Manages the many-to-many relationship between users and pools, with added game status tracking.

```javascript
{
  _id: ObjectId("..."),
  poolId: ObjectId("..."), // reference to pools collection
  userId: ObjectId("..."), // reference to users collection
  role: "member", // "owner" or "member"
  joinedAt: ISODate("..."),

  // Game status tracking
  status: "active", // active, eliminated
  eliminated_week: null,
  eliminated_date: null,
  total_picks: 3,

  // Performance metrics (cached for leaderboard performance)
  score: 15, // number of remaining available contestants
  available_contestants: ["teeny_chirichillo", "sol_yi", "rachel_lamont"] // cached list
}
```

## Relationships

- **Users ↔ Pools**: Many-to-many relationship managed through `pool_memberships` junction collection
- **Pools → Seasons**: Many-to-one relationship via `seasonId` field (many pools can use same season)
- **Picks → Users/Pools**: Many-to-one relationships (many picks per user per pool)
- **Pool Owner**: One-to-many relationship via `ownerId` field in pools collection
- **Default Pool**: One-to-one relationship via `default_pool` field in users collection

## Key Query Patterns

### Get pool with season data

```javascript
db.pools.aggregate([
  { $match: { _id: poolId } },
  {
    $lookup: {
      from: "seasons",
      localField: "seasonId",
      foreignField: "_id",
      as: "season"
    }
  },
  { $unwind: "$season" }
])
```

### Get user's picks for a pool

```javascript
db.picks.find({
  userId: userId,
  poolId: poolId
}).sort({week: 1})
```

### Get leaderboard for a pool

```javascript
db.pool_memberships.find({
  poolId: poolId,
  status: "active"
}).sort({score: -1})
```

### Get all active pools for a user

```javascript
db.pool_memberships.aggregate([
  { $match: { userId: userId } },
  {
    $lookup: {
      from: "pools",
      localField: "poolId",
      foreignField: "_id",
      as: "pool"
    }
  },
  { $unwind: "$pool" }
])
```

### Get available contestants for user in pool

```javascript
// Get all contestants from season
db.seasons.findOne({_id: seasonId}, {contestants: 1})

// Get user's previous picks to exclude
db.picks.find({
  userId: userId,
  poolId: poolId
}, {contestant_id: 1})

// Filter contestants not yet eliminated and not previously picked
```

### Submit a new pick

```javascript
// Check pick is valid (contestant available, within deadline, etc.)
// Then insert
db.picks.insertOne({
  userId: userId,
  poolId: poolId,
  week: currentWeek,
  episode_number: episodeNumber,
  contestant_id: contestantId,
  pick_date: new Date(),
  pick_deadline: deadlineDate,
  result: "pending"
})
```

### Process elimination (when episode airs)

```javascript
// Update all picks for the eliminated contestant
db.picks.updateMany(
  {
    poolId: poolId,
    episode_number: episodeNumber,
    contestant_id: eliminatedContestantId,
    result: "pending"
  },
  {
    $set: {
      result: "eliminated",
      result_date: new Date()
    }
  }
)

// Update pool memberships for eliminated users
db.pool_memberships.updateMany(
  {
    poolId: poolId,
    userId: { $in: eliminatedUserIds }
  },
  {
    $set: {
      status: "eliminated",
      eliminated_week: currentWeek,
      eliminated_date: new Date()
    }
  }
)
```

### Update available contestants cache

```javascript
// Recalculate available contestants for all active users in pool
db.pool_memberships.updateMany(
  {
    poolId: poolId,
    status: "active"
  },
  {
    $set: {
      available_contestants: availableContestantsArray,
      score: availableContestantsArray.length
    }
  }
)
```

## Benefits of This Design

### Data Integrity Benefits

1. **Single Source of Truth**: Season data is authoritative and consistent across all pools
2. **Zero Data Duplication**: Massive storage savings and no sync issues
3. **Immutable Facts**: Users cannot accidentally modify what actually happened on TV
4. **Easy Season Updates**: Update one season document, all pools instantly reflect changes

### Performance Benefits

1. **Efficient Queries**: Proper indexing enables fast lookups across all query patterns
2. **Cached Metrics**: Leaderboard data cached in pool_memberships for instant access
3. **Bounded Growth**: No unbounded arrays or document size concerns
4. **Atomic Operations**: Pick submissions and eliminations are atomic

### Scalability Benefits

1. **Horizontal Scaling**: Clean separation enables easy sharding strategies
2. **Thousands of Pools**: Can handle massive scale per season efficiently
3. **Historical Data**: Easy to query across seasons and time periods
4. **Analytics Ready**: Clean data structure enables rich statistics

### Development Benefits

1. **Clear Ownership**: Each collection has single responsibility
2. **Easy Testing**: Mock data easy to create and manage
3. **Future Extensibility**: Easy to add features like custom rules, multiple seasons
4. **Data Migration**: Clean upgrade path from old schema

## Indexes

Recommended indexes for optimal query performance:

```javascript
// On picks collection
db.picks.createIndex({ userId: 1, poolId: 1 })
db.picks.createIndex({ poolId: 1, week: 1 })
db.picks.createIndex({ poolId: 1, episode_number: 1 })
db.picks.createIndex({ poolId: 1, contestant_id: 1 })
db.picks.createIndex({ result: 1 })

// On pool_memberships collection
db.pool_memberships.createIndex({ userId: 1 })
db.pool_memberships.createIndex({ poolId: 1 })
db.pool_memberships.createIndex({ poolId: 1, status: 1 })
db.pool_memberships.createIndex({ userId: 1, poolId: 1 }, { unique: true })

// On pools collection
db.pools.createIndex({ ownerId: 1 })
db.pools.createIndex({ seasonId: 1 })

// On users collection
db.users.createIndex({ email: 1 }, { unique: true })
db.users.createIndex({ default_pool: 1 })

// On seasons collection
db.seasons.createIndex({ season_number: 1 })
db.seasons.createIndex({ season_name: 1 })
db.seasons.createIndex({ "contestants.id": 1 })
```

## Design Pattern Notes

This schema follows MongoDB best practices:

- **Reference Pattern**: Used for shared data (seasons) accessed by multiple entities (pools)
- **Embedded Pattern**: Still used appropriately (contestants within seasons, settings within pools)
- **Junction Collection Pattern**: Clean many-to-many with additional status tracking
- **Computed Pattern**: Cached scores and available contestants for performance

The result is a clean, scalable, and maintainable database design that accurately models the problem domain while following MongoDB conventions.
