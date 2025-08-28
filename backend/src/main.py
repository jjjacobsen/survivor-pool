import os

from fastapi import FastAPI
from pymongo import MongoClient

app = FastAPI()

# MongoDB connection
MONGO_URL = os.getenv("MONGO_URL", "mongodb://localhost:27017")
client = MongoClient(MONGO_URL)
db = client.survivor_pool


@app.get("/")
def read_root():
    return {"message": "Hello, FastAPI + uv + MongoDB!"}


@app.get("/health")
def health_check():
    try:
        # Test database connection
        client.admin.command("ping")
        return {"status": "healthy", "database": "connected"}
    except Exception as e:
        return {"status": "unhealthy", "database": "disconnected", "error": str(e)}
