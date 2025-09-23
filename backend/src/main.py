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
picks_collection = db.picks


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
    identifier: str
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


class UserDefaultPoolUpdate(BaseModel):
    default_pool: str | None = None


class AvailableContestantResponse(BaseModel):
    id: str
    name: str
    subtitle: str | None = None


class CurrentPickSummary(BaseModel):
    pick_id: str
    contestant_id: str
    contestant_name: str
    week: int
    locked_at: datetime


class AvailableContestantsResponse(BaseModel):
    pool_id: str
    user_id: str
    current_week: int
    contestants: list[AvailableContestantResponse]
    current_pick: CurrentPickSummary | None = None


class ContestantDetail(BaseModel):
    id: str
    name: str
    age: int | None = None
    occupation: str | None = None
    hometown: str | None = None


class ContestantDetailResponse(BaseModel):
    pool_id: str
    user_id: str
    contestant: ContestantDetail
    is_available: bool
    eliminated_week: int | None = None
    already_picked_week: int | None = None
    current_pick: CurrentPickSummary | None = None


class PickRequest(BaseModel):
    user_id: str
    contestant_id: str


class PickResponse(BaseModel):
    pick_id: str
    pool_id: str
    user_id: str
    contestant_id: str
    week: int
    locked_at: datetime


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
    identifier = user_data.identifier.strip()
    if not identifier:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Identifier is required",
        )

    user = users_collection.find_one(
        {"$or": [{"email": identifier}, {"username": identifier}]}
    )
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username/email or password",
        )

    if not verify_password(user_data.password, user["password_hash"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username/email or password",
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

    users_collection.update_one(
        {"_id": owner_id},
        {"$set": {"default_pool": pool_id}},
    )

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
            season_name=season["season_name"],
            season_number=season.get("season_number"),
        )
        for season in seasons
    ]


@app.patch("/users/{user_id}/default_pool", response_model=UserResponse)
def update_default_pool(user_id: str, payload: UserDefaultPoolUpdate):
    user_oid = parse_object_id(user_id, "user_id")

    user = users_collection.find_one({"_id": user_oid})
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    update_doc: dict[str, Any]
    if payload.default_pool is None:
        update_doc = {"$set": {"default_pool": None}}
    else:
        pool_oid = parse_object_id(payload.default_pool, "default_pool")
        pool = pools_collection.find_one({"_id": pool_oid})
        if not pool:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Pool not found",
            )

        membership = pool_memberships_collection.find_one(
            {"poolId": pool_oid, "userId": user_oid}
        )
        if not membership:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="User is not a member of this pool",
            )

        update_doc = {"$set": {"default_pool": pool_oid}}

    users_collection.update_one({"_id": user_oid}, update_doc)

    updated_user = users_collection.find_one({"_id": user_oid})
    if not updated_user:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update user",
        )

    return UserResponse(
        id=user_id,
        username=updated_user["username"],
        email=updated_user["email"],
        display_name=updated_user["display_name"],
        account_status=updated_user["account_status"],
        created_at=updated_user["created_at"],
        default_pool=(
            str(updated_user.get("default_pool"))
            if updated_user.get("default_pool")
            else None
        ),
    )


@app.get("/users/{user_id}/pools", response_model=list[PoolResponse])
def list_user_pools(user_id: str):
    user_oid = parse_object_id(user_id, "user_id")

    memberships = pool_memberships_collection.find({"userId": user_oid})
    pool_ids = {membership["poolId"] for membership in memberships}
    if not pool_ids:
        return []

    pools = pools_collection.find({"_id": {"$in": list(pool_ids)}})

    responses: list[PoolResponse] = []
    for pool in pools:
        responses.append(
            PoolResponse(
                id=str(pool["_id"]),
                name=pool.get("name", ""),
                owner_id=(str(pool.get("ownerId")) if pool.get("ownerId") else ""),
                season_id=(str(pool.get("seasonId")) if pool.get("seasonId") else ""),
                created_at=pool.get("created_at", datetime.now()),
                current_week=pool.get("current_week", 1),
                settings=pool.get("settings", {}),
                invited_user_ids=[],
            )
        )

    return responses


@app.get(
    "/pools/{pool_id}/available_contestants",
    response_model=AvailableContestantsResponse,
)
def get_available_contestants(pool_id: str, user_id: str):
    pool_oid = parse_object_id(pool_id, "pool_id")
    user_oid = parse_object_id(user_id, "user_id")

    pool = pools_collection.find_one({"_id": pool_oid})
    if not pool:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pool not found",
        )

    membership = pool_memberships_collection.find_one(
        {"poolId": pool_oid, "userId": user_oid}
    )
    if not membership:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User is not a member of this pool",
        )

    season_id = pool.get("seasonId")
    if not season_id:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Pool season not configured",
        )

    season = seasons_collection.find_one(
        {"_id": season_id},
        {"contestants": 1, "eliminations": 1},
    )
    if not season:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Season not found",
        )

    raw_week = pool.get("current_week")
    current_week: int
    if isinstance(raw_week, int):
        current_week = raw_week if raw_week > 0 else 1
    elif isinstance(raw_week, float):
        current_week = int(raw_week) if raw_week > 0 else 1
    elif isinstance(raw_week, str):
        current_week = int(raw_week) if raw_week.isdigit() else 1
    else:
        current_week = 1

    prior_picks_cursor = picks_collection.find(
        {"userId": user_oid, "poolId": pool_oid},
        {"contestant_id": 1},
    )
    picked_contestants = {
        pick.get("contestant_id")
        for pick in prior_picks_cursor
        if pick.get("contestant_id")
    }

    eliminated_contestants = {
        elimination["eliminated_contestant_id"]
        for elimination in season.get("eliminations", [])
        if elimination.get("eliminated_contestant_id")
        and elimination["week"] < current_week
    }

    contestant_catalog: dict[str, dict[str, Any]] = {
        contestant["id"]: contestant for contestant in season.get("contestants", [])
    }

    contestants: list[AvailableContestantResponse] = []
    for contestant_id, contestant in contestant_catalog.items():
        if (
            contestant_id in picked_contestants
            or contestant_id in eliminated_contestants
        ):
            continue

        contestants.append(
            AvailableContestantResponse(
                id=contestant_id,
                name=contestant.get("name") or contestant_id,
                subtitle=None,
            )
        )

    contestants.sort(key=lambda c: c.name.lower())

    current_pick_summary: CurrentPickSummary | None = None
    current_pick_doc = picks_collection.find_one(
        {"userId": user_oid, "poolId": pool_oid, "week": current_week}
    )
    if current_pick_doc and current_pick_doc.get("contestant_id"):
        c_id = current_pick_doc.get("contestant_id")
        raw_created_at = current_pick_doc.get("created_at")
        locked_at = (
            raw_created_at if isinstance(raw_created_at, datetime) else datetime.now()
        )
        contestant = contestant_catalog.get(c_id, {})
        current_pick_summary = CurrentPickSummary(
            pick_id=str(current_pick_doc.get("_id")),
            contestant_id=c_id,
            contestant_name=contestant.get("name") or c_id,
            week=current_week,
            locked_at=locked_at,
        )

    return AvailableContestantsResponse(
        pool_id=str(pool_oid),
        user_id=str(user_oid),
        current_week=current_week,
        contestants=contestants,
        current_pick=current_pick_summary,
    )


def _extract_week_value(raw_week: Any) -> int | None:
    if isinstance(raw_week, int):
        return raw_week
    if isinstance(raw_week, float):
        return int(raw_week)
    if isinstance(raw_week, str):
        try:
            return int(raw_week)
        except ValueError:
            return None
    return None


@app.get(
    "/pools/{pool_id}/contestants/{contestant_id}",
    response_model=ContestantDetailResponse,
)
def get_contestant_detail(pool_id: str, contestant_id: str, user_id: str):
    pool_oid = parse_object_id(pool_id, "pool_id")
    user_oid = parse_object_id(user_id, "user_id")

    pool = pools_collection.find_one({"_id": pool_oid})
    if not pool:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pool not found",
        )

    membership = pool_memberships_collection.find_one(
        {"poolId": pool_oid, "userId": user_oid}
    )
    if not membership or membership.get("status") == "eliminated":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User is not an active member of this pool",
        )

    season_id = pool.get("seasonId")
    if not season_id:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Pool season not configured",
        )

    season = seasons_collection.find_one(
        {"_id": season_id},
        {"contestants": 1, "eliminations": 1},
    )
    if not season:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Season not found",
        )

    contestants_by_id = {
        contestant["id"]: contestant for contestant in season.get("contestants", [])
    }
    target_contestant = contestants_by_id.get(contestant_id)

    if not target_contestant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Contestant not found",
        )

    raw_week = pool.get("current_week")
    current_week = _extract_week_value(raw_week) or 1

    eliminated_week: int | None = None
    for elimination in season.get("eliminations", []):
        if elimination.get("eliminated_contestant_id") == contestant_id:
            eliminated_week = elimination["week"]
            break

    prior_pick = picks_collection.find_one(
        {"userId": user_oid, "poolId": pool_oid, "contestant_id": contestant_id}
    )
    already_picked_week = (
        _extract_week_value(prior_pick.get("week")) if prior_pick else None
    )

    visible_eliminated_week: int | None = None
    if eliminated_week is not None and eliminated_week < current_week:
        visible_eliminated_week = eliminated_week

    current_pick_doc = picks_collection.find_one(
        {"userId": user_oid, "poolId": pool_oid, "week": current_week}
    )
    current_pick_summary: CurrentPickSummary | None = None
    if current_pick_doc and current_pick_doc.get("contestant_id"):
        pick_contestant_id = current_pick_doc.get("contestant_id")
        raw_created_at = current_pick_doc.get("created_at")
        locked_at = (
            raw_created_at if isinstance(raw_created_at, datetime) else datetime.now()
        )
        current_pick_summary = CurrentPickSummary(
            pick_id=str(current_pick_doc.get("_id")),
            contestant_id=pick_contestant_id,
            contestant_name=(
                contestants_by_id.get(pick_contestant_id, {}).get("name")
                or pick_contestant_id
            ),
            week=current_week,
            locked_at=locked_at,
        )

    can_pick = (
        (current_pick_summary is None)
        and (already_picked_week is None)
        and not (eliminated_week is not None and eliminated_week < current_week)
        and membership.get("status") == "active"
    )

    detail = ContestantDetail(
        id=contestant_id,
        name=target_contestant.get("name") or contestant_id,
        age=target_contestant.get("age"),
        occupation=target_contestant.get("occupation"),
        hometown=target_contestant.get("hometown"),
    )

    return ContestantDetailResponse(
        pool_id=str(pool_oid),
        user_id=str(user_oid),
        contestant=detail,
        is_available=can_pick,
        eliminated_week=visible_eliminated_week,
        already_picked_week=already_picked_week,
        current_pick=current_pick_summary,
    )


@app.post(
    "/pools/{pool_id}/picks",
    response_model=PickResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_pick(pool_id: str, payload: PickRequest):
    pool_oid = parse_object_id(pool_id, "pool_id")
    user_oid = parse_object_id(payload.user_id, "user_id")

    pool = pools_collection.find_one({"_id": pool_oid})
    if not pool:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pool not found",
        )

    membership = pool_memberships_collection.find_one(
        {"poolId": pool_oid, "userId": user_oid}
    )
    if not membership or membership.get("status") != "active":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User is not active in this pool",
        )

    season_id = pool.get("seasonId")
    if not season_id:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Pool season not configured",
        )

    season = seasons_collection.find_one(
        {"_id": season_id},
        {"contestants": 1, "eliminations": 1},
    )
    if not season:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Season not found",
        )

    raw_week = pool.get("current_week")
    current_week = _extract_week_value(raw_week) or 1

    existing_pick = picks_collection.find_one(
        {"userId": user_oid, "poolId": pool_oid, "week": current_week}
    )
    if existing_pick:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Pick already locked for this week",
        )

    contestant = None
    for candidate in season.get("contestants", []):
        if candidate.get("id") == payload.contestant_id:
            contestant = candidate
            break

    if not contestant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Contestant not found",
        )

    prior_pick = picks_collection.find_one(
        {"userId": user_oid, "poolId": pool_oid, "contestant_id": payload.contestant_id}
    )
    if prior_pick:
        prior_week = _extract_week_value(prior_pick.get("week"))
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Contestant already picked"
                + (f" in week {prior_week}" if prior_week else "")
            ),
        )

    eliminated_week: int | None = None
    for elimination in season.get("eliminations", []):
        if elimination.get("eliminated_contestant_id") == payload.contestant_id:
            eliminated_week = elimination["week"]
            break

    if eliminated_week is not None and eliminated_week < current_week:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Contestant already eliminated",
        )

    now = datetime.now()
    pick_doc = {
        "poolId": pool_oid,
        "userId": user_oid,
        "contestant_id": payload.contestant_id,
        "week": current_week,
        "created_at": now,
        "result": "pending",
    }

    insert_result = picks_collection.insert_one(pick_doc)
    inserted_id = insert_result.inserted_id
    if not inserted_id:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to lock pick",
        )

    return PickResponse(
        pick_id=str(inserted_id),
        pool_id=str(pool_oid),
        user_id=str(user_oid),
        contestant_id=payload.contestant_id,
        week=current_week,
        locked_at=now,
    )
