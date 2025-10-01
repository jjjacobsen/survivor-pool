# Database Schema

## Overview

This document describes the MongoDB schema design for the survivor pool application. The design follows a clean separation of concerns with normalized data to eliminate duplication and ensure data integrity.

## Core Design Philosophy

- **Single Source of Truth**: Season data represents immutable facts about what happened on TV
- **Zero Duplication**: Shared data is referenced, not copied
- **Clean Separation**: Pools are game containers, seasons are data, picks are user actions
- **MongoDB Best Practices**: Proper use of references for shared data, embedding for ownership
- **Embed Static TV Facts**: All immutable show facts for a season live inside a single season document (contestants, tribe timeline, eliminations, advantages)

## Terminology

- We use "week" instead of "episode" everywhere. They are synonymous for this app; "week" is chosen for consistency and clarity.

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

Single source of truth for all Survivor season data. This data represents immutable facts about what actually happened on the show. All static TV facts are embedded in the season document.

```javascript
{
  _id: ObjectId("..."),
  season_name: "Survivor 47",
  season_number: 47,
  air_date: ISODate("2024-09-18"),
  location: "Fiji",
  format: "new_era",
  created_at: ISODate("..."),

  // Cast roster (immutable identity details)
  contestants: [
    {
      id: "teeny_chirichillo",
      name: "Teeny Chirichillo",
      age: 24,
      occupation: "Freelance Writer",
      hometown: "Manahawkin, NJ"
    },
    {
      id: "kishan_patel",
      name: "Kishan Patel",
      age: 28,
      occupation: "ER Doctor",
      hometown: "San Francisco, CA"
    }
    // ... all contestants
  ],

  // Eliminations as they aired (week-based)
  eliminations: [
    { week: 1, eliminated_contestant_id: null },
    { week: 2, eliminated_contestant_id: "aysha_welch" }
    // ...
  ],

  // Tribe state over time; first entry represents initial tribes
  tribe_timeline: [
    {
      week: 1,
      event: "start", // start | swap | merge
      tribes: [
        { name: "Lavo", color: "red", members: ["teeny_chirichillo", "kishan_patel", "rome_cooney", "aysha_welch", "sol_yi", "genevieve_mushaluk"] },
        { name: "Gata", color: "yellow", members: ["sam_layco", "sierra_wright", "rachel_lamont", "anika_dhar", "andy_rueda", "jon_lovett"] },
        { name: "Tuku", color: "blue", members: ["caroline_vidmar", "sue_smey", "gabe_ortis", "kyle_ostwald", "tiyana_hallums", "terran_causey"] }
      ]
    },
    {
      week: 5,
      event: "swap",
      tribes: [
        // updated tribes and memberships after swap
      ]
    },
    {
      week: 7,
      event: "merge",
      tribes: [
        { name: "Mergia", color: "green", members: [/* all remaining contestants */] }
      ]
    }
  ],

  // Advantages timeline for the season (possession/use status)
  advantages: [
    {
      id: "idol_teeny_1",
      advantage_type: "hidden_immunity_idol", // hidden_immunity_idol, vote_steal, extra_vote, etc.
      contestant_id: "teeny_chirichillo", // holder when obtained
      obtained_week: 3,
      status: "active", // active | played | expired | transferred
      played_week: null,
      transferred_to: null, // contestant_id if transferred
      notes: "Found at reward challenge"
    }
    // ... additional advantages as they occur
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
    pick_deadline_hours: 2, // hours before weekly deadline
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
  status: "active", // invited, active, eliminated, declined
  elimination_reason: null, // missed_pick | contestant_voted_out | no_options_left
  eliminated_week: null,
  eliminated_date: null,

  // Performance metrics (cached for leaderboard performance)
  score: 15, // number of remaining available contestants
  available_contestants: ["teeny_chirichillo", "sol_yi", "rachel_lamont"] // cached list computed by backend recompute; GET /pools/{poolId}/available_contestants returns it as-is
}
```

`elimination_reason` captures why a member left the pool: `missed_pick`, `contestant_voted_out`, or `no_options_left`. Frontends use this field to tailor elimination messaging.

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
// Get season facts (contestants, eliminations, advantages)
const season = db.seasons.findOne({_id: seasonId}, {contestants: 1, eliminations: 1, advantages: 1})

// Get user's previous picks to exclude (in this pool)
const priorPicks = db.picks.find({ userId, poolId }, { contestant_id: 1 }).toArray().map(p => p.contestant_id)

// Compute available contestants client-side or with aggregation
// Optionally project active advantages only using $filter
db.seasons.aggregate([
  { $match: { _id: seasonId } },
  {
    $project: {
      contestants: 1,
      eliminations: 1,
      active_advantages: {
        $filter: {
          input: "$advantages",
          as: "a",
          cond: { $eq: ["$$a.status", "active"] }
        }
      }
    }
  }
])

// Filter contestants not yet eliminated and not previously picked
```

### Update season facts (when week ends)

```javascript
// Record elimination on the season document
db.seasons.updateOne(
  { _id: seasonId },
  { $push: { eliminations: { week: currentWeek, eliminated_contestant_id: eliminatedContestantId } } }
)

// Mark an advantage as played/transferred/expired on the season document
db.seasons.updateOne(
  { _id: seasonId, "advantages.id": advantageId },
  { $set: { "advantages.$.status": "played", "advantages.$.played_week": currentWeek } }
)
```

### Submit a new pick

```javascript
// Check pick is valid (contestant available, within deadline, etc.)
// Then insert
db.picks.insertOne({
  userId: userId,
  poolId: poolId,
  week: currentWeek,
  contestant_id: contestantId,
  pick_date: new Date(),
  pick_deadline: deadlineDate,
  result: "pending"
})
```

### Process elimination (when week ends)

```javascript
// Update all picks for the eliminated contestant
db.picks.updateMany(
  {
    poolId: poolId,
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

> `available_contestants` is never seeded with a default; backend recomputation must populate it and inconsistencies are treated as errors.

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

// On seasons collection (additional nested indexes)
db.seasons.createIndex({ "advantages.contestant_id": 1 })
db.seasons.createIndex({ "advantages.status": 1 })
// Note: Avoid compound indexes across multiple fields of the same array (multikey restriction)
```

## Design Pattern Notes

This schema follows MongoDB best practices:

- **Reference Pattern**: Used for shared data (seasons) accessed by multiple entities (pools)
- **Embedded Pattern**: Used for immutable show facts (contestants, eliminations, tribe timeline, advantages within seasons; settings within pools)
- **Junction Collection Pattern**: Clean many-to-many with additional status tracking
- **Computed Pattern**: Cached scores and available contestants for performance

The result is a clean, scalable, and maintainable database design that accurately models the problem domain while following MongoDB conventions.
