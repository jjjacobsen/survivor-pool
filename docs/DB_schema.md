# Database Schema

## Overview

This document describes the MongoDB schema design for the survivor pool application, focusing on the many-to-many relationship between users and pools.

## Collections

### 1. `users` Collection (Existing)

Stores user account information.

```javascript
{
  _id: ObjectId("..."),
  name: "John Doe",
  email: "john@example.com"
  // ... other user fields
}
```

### 2. `season_templates` Collection

Stores master template data for Survivor seasons. These are immutable reference templates used to create new pools.

```javascript
{
  _id: ObjectId("..."),
  season_name: "Survivor 49",
  season_number: 49,
  air_date: ISODate("2025-09-24"),
  location: "Fiji",
  format: "new_era", // 26 days format
  created_at: ISODate("..."),

  tribes: [
    {
      name: "Kele",
      color: "blue",
      initial_members: ["alex_moore", "annie_davis", "jake_latimer", "jeremiah_ing", "nicole_mazullo", "sophi_balerdi"]
    },
    {
      name: "Uli",
      color: "red",
      initial_members: ["nate_moore", "savannah_louie", "rizo_velovic", "shannon_fairweather", "sage_ahrens_nichols", "jawan_pitts"]
    },
    {
      name: "Hina",
      color: "yellow",
      initial_members: ["steven_ramm", "kristina_mills", "matt_williams", "sophie_segreti", "michelle_chukwujekwu", "jason_treul"]
    }
  ],

  contestants: [
    {
      id: "alex_moore",
      name: "Alex Moore",
      age: 27,
      occupation: "Political Communications Director",
      hometown: "Washington, D.C.",
      photo_url: "/images/contestants/alex_moore.jpg",
      bio: "Political strategist ready to outwit and outplay...",
      initial_tribe: "Kele"
    },
    {
      id: "nate_moore",
      name: "Nate Moore",
      age: 47,
      occupation: "Film Producer",
      hometown: "Hermosa Beach, CA",
      photo_url: "/images/contestants/nate_moore.jpg",
      bio: "Former Marvel executive producer bringing strategic thinking...",
      initial_tribe: "Uli"
    }
    // ... 16 more contestants
  ]
}
```

### 3. `pools` Collection

Stores pool information with embedded cast data copied from season templates. Pool owners can modify cast data as the season progresses.

```javascript
{
  _id: ObjectId("..."),
  name: "Family Survivor Pool",
  ownerId: ObjectId("..."), // reference to user who owns the pool
  season_template_id: ObjectId("..."), // reference to source season template
  created_at: ISODate("..."),
  settings: {
    // pool-specific configuration
  },

  // Embedded cast data (copied from template, then modified by pool owner)
  cast: {
    season_name: "Survivor 49",
    current_episode: 3,
    last_updated: ISODate("..."),

    contestants: [
      {
        id: "alex_moore",
        name: "Alex Moore",
        age: 27,
        occupation: "Political Communications Director",
        hometown: "Washington, D.C.",
        photo_url: "/images/contestants/alex_moore.jpg",
        bio: "Political strategist ready to outwit and outplay...",
        status: "active", // active, eliminated, winner
        eliminated_episode: null,
        current_tribe: "Kele"
      },
      {
        id: "some_contestant",
        name: "Some Contestant",
        age: 25,
        occupation: "Teacher",
        hometown: "City, State",
        photo_url: "/images/contestants/some_contestant.jpg",
        bio: "Ready to play the game...",
        status: "eliminated",
        eliminated_episode: 2,
        current_tribe: null // null when eliminated
      }
      // ... other contestants
    ],

    tribes: [
      {
        name: "Kele",
        color: "blue",
        status: "active", // active, merged, dissolved
        current_members: ["alex_moore", "annie_davis"] // updated as contestants move/get eliminated
      },
      {
        name: "Uli",
        color: "red",
        status: "active",
        current_members: ["savannah_louie", "rizo_velovic"]
      }
      // tribes can be added/modified by pool owner as season progresses
    ]
  }
}
```

### 4. `pool_memberships` Collection (Junction Collection)

Manages the many-to-many relationship between users and pools. This is the recommended approach for handling many-to-many relationships in MongoDB.

```javascript
{
  _id: ObjectId("..."),
  poolId: ObjectId("..."), // reference to pools collection
  userId: ObjectId("..."), // reference to users collection
  role: "member", // "owner" or "member"
  joinedAt: ISODate("...")
  // ... other membership metadata
}
```

## Relationships

- **Users ↔ Pools**: Many-to-many relationship managed through the `pool_memberships` junction collection
- **Pool Owner**: One-to-many relationship via `ownerId` field in pools collection
- **Season Templates ↔ Pools**: One-to-many relationship via `season_template_id` field in pools collection
- **Cast Data**: Embedded within each pool (copied from season template, then modified independently)
- A user can be a member of multiple pools
- A pool can have multiple members
- Each pool has exactly one owner (who is also implicitly a member)
- Each pool is based on one season template but has independent cast data
- Pool owners can modify their pool's cast data as the season progresses

## Key Query Patterns

### Find all pools for a user

```javascript
db.pool_memberships.find({userId: userId})
```

### Find all members of a pool

```javascript
db.pool_memberships.find({poolId: poolId})
```

### Check if user owns a pool

```javascript
db.pools.findOne({_id: poolId, ownerId: userId})
```

### Get pool with member count

```javascript
db.pools.aggregate([
  { $match: { _id: poolId } },
  {
    $lookup: {
      from: "pool_memberships",
      localField: "_id",
      foreignField: "poolId",
      as: "memberships"
    }
  },
  {
    $addFields: {
      memberCount: { $size: "$memberships" }
    }
  }
])
```

### Get all available season templates

```javascript
db.season_templates.find({}).sort({season_number: -1})
```

### Get pools using a specific season template

```javascript
db.pools.find({season_template_id: templateId})
```

### Get active contestants in a pool

```javascript
db.pools.findOne(
  {_id: poolId},
  {"cast.contestants": {$elemMatch: {status: "active"}}}
)
```

### Update contestant status (elimination)

```javascript
db.pools.updateOne(
  {_id: poolId, "cast.contestants.id": contestantId},
  {
    $set: {
      "cast.contestants.$.status": "eliminated",
      "cast.contestants.$.eliminated_episode": episodeNumber,
      "cast.contestants.$.current_tribe": null,
      "cast.last_updated": new Date()
    }
  }
)
```

## Benefits of This Design

### Template/Instance Pattern Benefits

1. **Easy Pool Creation**: Users can quickly create pools by copying from pre-made season templates
2. **Data Consistency**: All pools start with standardized, validated season data
3. **Flexibility**: Pool owners can modify their cast data independently without affecting other pools
4. **Atomic Updates**: Embedded cast data allows for atomic contestant status updates and tribe changes

### Overall Design Benefits

1. **Scalability**: No document size limits - pools can have unlimited members
2. **Query Performance**: Efficient queries in all directions (user→pools, pool→users, season→pools)
3. **Data Integrity**: Clear separation of concerns between entities
4. **MongoDB Best Practice**: Follows recommended patterns for many-to-many relationships and embedded documents

### Cast Data Management Benefits

1. **Single Query Access**: Pool and cast data retrieved together, no joins required
2. **Version Independence**: Each pool's cast evolves independently from the original template
3. **Easy Modifications**: Pool owners can eliminate contestants, change tribes, add custom data
4. **Audit Trail**: `last_updated` timestamp tracks when cast was modified

## Indexes

Recommended indexes for optimal query performance:

```javascript
// On pool_memberships collection
db.pool_memberships.createIndex({ userId: 1 })
db.pool_memberships.createIndex({ poolId: 1 })
db.pool_memberships.createIndex({ userId: 1, poolId: 1 }, { unique: true })

// On pools collection
db.pools.createIndex({ ownerId: 1 })
db.pools.createIndex({ season_template_id: 1 })
db.pools.createIndex({ "cast.contestants.id": 1 }) // for contestant lookups
db.pools.createIndex({ "cast.contestants.status": 1 }) // for active/eliminated queries

// On season_templates collection
db.season_templates.createIndex({ season_number: 1 })
db.season_templates.createIndex({ season_name: 1 })
```

## Design Pattern Notes

This schema uses the **Template/Instance Pattern** where:

- **Templates** (`season_templates`): Immutable master data for each Survivor season
- **Instances** (`pools.cast`): Mutable copies that start from templates and evolve independently

The embedded cast data follows MongoDB's **Embedded Document Pattern** because:

- Cast data is always queried with pool data
- Cast size is bounded (~18-20 contestants max)
- Enables atomic updates for eliminations and tribe changes
- Eliminates need for complex joins
