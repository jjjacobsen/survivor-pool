from pymongo.database import Database

from .db.mongo import db


def get_db() -> Database:
    return db
