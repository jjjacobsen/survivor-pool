from pymongo import MongoClient

from ..core.config import DATABASE_NAME, MONGO_URL

client = MongoClient(MONGO_URL)
db = client[DATABASE_NAME]

users_collection = db.users
pools_collection = db.pools
pool_memberships_collection = db.pool_memberships
seasons_collection = db.seasons
picks_collection = db.picks


def ping_database():
    client.admin.command("ping")
