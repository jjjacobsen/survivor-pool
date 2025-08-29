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

### 2. `pools` Collection

Stores pool information with a reference to the pool owner.

```javascript
{
  _id: ObjectId("..."),
  name: "NFL 2024 Pool",
  ownerId: ObjectId("..."), // reference to user who owns the pool
  createdAt: ISODate("..."),
  settings: {
    // pool-specific configuration
  }
  // ... other pool fields
}
```

### 3. `pool_memberships` Collection (Junction Collection)

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
- A user can be a member of multiple pools
- A pool can have multiple members
- Each pool has exactly one owner (who is also implicitly a member)

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

## Benefits of This Design

1. **Scalability**: No document size limits - pools can have unlimited members
2. **Flexibility**: Easy to add membership metadata (join date, role, permissions, etc.)
3. **Query Performance**: Efficient queries in all directions (user→pools, pool→users)
4. **Data Integrity**: Clear separation of concerns between entities
5. **MongoDB Best Practice**: Follows recommended patterns for many-to-many relationships

## Indexes

Recommended indexes for optimal query performance:

```javascript
// On pool_memberships collection
db.pool_memberships.createIndex({ userId: 1 })
db.pool_memberships.createIndex({ poolId: 1 })
db.pool_memberships.createIndex({ userId: 1, poolId: 1 }, { unique: true })

// On pools collection
db.pools.createIndex({ ownerId: 1 })
```
