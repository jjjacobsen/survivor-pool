from pymongo import MongoClient
from pymongo.collection import Collection

from ..core.config import DATABASE_NAME, MONGO_URL

client = MongoClient(MONGO_URL)
db = client[DATABASE_NAME]

users_collection: Collection = db.users
pools_collection: Collection = db.pools
pool_memberships_collection: Collection = db.pool_memberships
seasons_collection: Collection = db.seasons
picks_collection: Collection = db.picks


def ping_database() -> None:
    client.admin.command("ping")
