import os
from datetime import datetime
from typing import Any

import bcrypt
from bson import ObjectId
from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr, Field
from pymongo import MongoClient

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1):\d+",
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

# MongoDB connection
MONGO_URL = os.getenv("MONGO_URL", "mongodb://localhost:27017")
client = MongoClient(MONGO_URL)
db = client.survivor_pool
users_collection = db.users
pools_collection = db.pools
pool_memberships_collection = db.pool_memberships
seasons_collection = db.seasons


class UserCreateRequest(BaseModel):
    username: str
    email: EmailStr
    password: str
    display_name: str


class UserResponse(BaseModel):
    id: str
    username: str
    email: str
    display_name: str
    account_status: str
    created_at: datetime
    default_pool: str | None = None


class UserLoginRequest(BaseModel):
    email: EmailStr
    password: str


class PoolCreateRequest(BaseModel):
    name: str
    season_id: str
    owner_id: str
    invite_user_ids: list[str] = Field(default_factory=list)


class PoolResponse(BaseModel):
    id: str
    name: str
    owner_id: str
    season_id: str
    created_at: datetime
    current_week: int
    settings: dict[str, Any] = Field(default_factory=dict)
    invited_user_ids: list[str] = Field(default_factory=list)


class SeasonResponse(BaseModel):
    id: str
    season_name: str
    season_number: int | None = None


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


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(password.encode("utf-8"), hashed_password.encode("utf-8"))


def parse_object_id(value: str, field_name: str) -> ObjectId:
    if not ObjectId.is_valid(value):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid {field_name}",
        )
    return ObjectId(value)


@app.post("/users", response_model=UserResponse)
def create_user(user_data: UserCreateRequest):
    # Check if username already exists
    if users_collection.find_one({"username": user_data.username}):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Username already exists"
        )

    # Check if email already exists
    if users_collection.find_one({"email": user_data.email}):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Email already exists"
        )

    # Hash password
    hashed_password = hash_password(user_data.password)

    # Create user document
    user_doc = {
        "username": user_data.username,
        "email": user_data.email,
        "password_hash": hashed_password,
        "display_name": user_data.display_name,
        "account_status": "active",
        "created_at": datetime.now(),
        "default_pool": None,
    }

    # Insert user into database
    result = users_collection.insert_one(user_doc)
    if not result.inserted_id:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create user",
        )

    # Return user response without password
    return UserResponse(
        id=str(result.inserted_id),
        username=user_data.username,
        email=user_data.email,
        display_name=user_data.display_name,
        account_status="active",
        created_at=user_doc["created_at"],
        default_pool=None,
    )


@app.post("/users/login", response_model=UserResponse)
def login_user(user_data: UserLoginRequest):
    user = users_collection.find_one({"email": user_data.email})
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
        )

    if not verify_password(user_data.password, user["password_hash"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
        )

    if user["account_status"] != "active":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is not active",
        )

    return UserResponse(
        id=str(user["_id"]),
        username=user["username"],
        email=user["email"],
        display_name=user["display_name"],
        account_status=user["account_status"],
        created_at=user["created_at"],
        default_pool=(
            str(user.get("default_pool")) if user.get("default_pool") else None
        ),
    )


@app.post("/pools", response_model=PoolResponse, status_code=status.HTTP_201_CREATED)
def create_pool(pool_data: PoolCreateRequest):
    name = pool_data.name.strip()
    if not name:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Pool name is required",
        )

    owner_id = parse_object_id(pool_data.owner_id, "owner_id")
    if not users_collection.find_one({"_id": owner_id}):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Owner not found"
        )

    season_id = parse_object_id(pool_data.season_id, "season_id")
    if not seasons_collection.find_one({"_id": season_id}):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Season not found"
        )

    now = datetime.now()
    pool_doc = {
        "name": name,
        "ownerId": owner_id,
        "seasonId": season_id,
        "created_at": now,
        "current_week": 1,
        "settings": {},
    }

    pool_result = pools_collection.insert_one(pool_doc)
    pool_id = pool_result.inserted_id
    if not pool_id:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create pool",
        )

    pool_memberships_collection.insert_one(
        {
            "poolId": pool_id,
            "userId": owner_id,
            "role": "owner",
            "joinedAt": now,
            "status": "active",
            "eliminated_week": None,
            "eliminated_date": None,
            "total_picks": 0,
            "score": 0,
            "available_contestants": [],
        }
    )

    invited_user_ids: list[str] = []
    seen_invites = {pool_data.owner_id}
    for invitee in pool_data.invite_user_ids:
        if invitee in seen_invites:
            continue
        seen_invites.add(invitee)
        invitee_id = parse_object_id(invitee, "invite_user_ids")
        if not users_collection.find_one({"_id": invitee_id}):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Invited user not found",
            )
        pool_memberships_collection.update_one(
            {"poolId": pool_id, "userId": invitee_id},
            {
                "$setOnInsert": {
                    "role": "member",
                    "joinedAt": None,
                    "status": "invited",
                    "eliminated_week": None,
                    "eliminated_date": None,
                    "total_picks": 0,
                    "score": 0,
                    "available_contestants": [],
                }
            },
            upsert=True,
        )
        invited_user_ids.append(invitee)

    return PoolResponse(
        id=str(pool_id),
        name=name,
        owner_id=pool_data.owner_id,
        season_id=pool_data.season_id,
        created_at=now,
        current_week=1,
        settings=pool_doc["settings"],
        invited_user_ids=invited_user_ids,
    )


@app.get("/seasons", response_model=list[SeasonResponse])
def list_seasons():
    seasons = seasons_collection.find(
        {},
        {
            "season_name": 1,
            "season_number": 1,
        },
    ).sort("season_number", -1)

    return [
        SeasonResponse(
            id=str(season["_id"]),
            season_name=season.get("season_name", ""),
            season_number=season.get("season_number"),
        )
        for season in seasons
    ]
