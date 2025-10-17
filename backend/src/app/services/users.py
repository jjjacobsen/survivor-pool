import re
from datetime import datetime, timedelta
from difflib import SequenceMatcher
from typing import Any

from bson import ObjectId
from fastapi import HTTPException, status
from pymongo import ReturnDocument

from ..core.security import (
    DUMMY_PASSWORD_HASH,
    create_access_token,
    hash_password,
    verify_password,
)
from ..db.mongo import (
    picks_collection,
    pool_memberships_collection,
    pools_collection,
    users_collection,
)
from ..schemas.pools import PoolResponse
from ..schemas.users import (
    UserCreateRequest,
    UserDefaultPoolUpdate,
    UserLoginRequest,
    UserResponse,
    UserSearchResult,
)
from . import pools as pools_service
from .common import parse_object_id

MAX_FAILED_LOGIN_ATTEMPTS = 5
LOCKOUT_DURATION = timedelta(minutes=15)


def _build_user_response(
    user: dict[str, Any], *, token: str | None = None
) -> UserResponse:
    default_pool = user.get("default_pool")
    if isinstance(default_pool, ObjectId):
        default_pool_id: str | None = str(default_pool)
    elif isinstance(default_pool, str):
        default_pool_id = default_pool
    else:
        default_pool_id = None

    created_at = user.get("created_at")
    if not isinstance(created_at, datetime):
        created_at = datetime.now()

    return UserResponse(
        id=str(user["_id"]),
        username=user.get("username", ""),
        email=user.get("email", ""),
        display_name=user.get("display_name", ""),
        account_status=user.get("account_status", ""),
        created_at=created_at,
        default_pool=default_pool_id,
        token=token,
    )


def create_user(user_data: UserCreateRequest) -> UserResponse:
    if users_collection.find_one({"username": user_data.username}):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username already exists",
        )

    if users_collection.find_one({"email": user_data.email}):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already exists",
        )

    hashed_password = hash_password(user_data.password)

    user_doc = {
        "username": user_data.username,
        "email": user_data.email,
        "password_hash": hashed_password,
        "display_name": user_data.display_name,
        "account_status": "active",
        "created_at": datetime.now(),
        "default_pool": None,
        "failed_login_attempts": 0,
        "locked_until": None,
    }

    result = users_collection.insert_one(user_doc)
    if not result.inserted_id:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create user",
        )

    user_doc["_id"] = result.inserted_id
    token = create_access_token(str(result.inserted_id))
    return _build_user_response(user_doc, token=token)


def login_user(user_data: UserLoginRequest) -> UserResponse:
    identifier = user_data.identifier.strip()
    if not identifier:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Identifier is required",
        )

    user = users_collection.find_one(
        {"$or": [{"email": identifier}, {"username": identifier}]}
    )
    now = datetime.now()

    if user:
        locked_until = user.get("locked_until")
        if isinstance(locked_until, datetime) and locked_until > now:
            remaining_seconds = int((locked_until - now).total_seconds())
            minutes_remaining = max((remaining_seconds + 59) // 60, 1)
            plural = "s" if minutes_remaining != 1 else ""
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=(
                    f"Account locked. Try again in {minutes_remaining} minute{plural}."
                ),
            )
        if isinstance(locked_until, datetime) and locked_until <= now:
            users_collection.update_one(
                {"_id": user["_id"]},
                {"$set": {"failed_login_attempts": 0, "locked_until": None}},
            )
            user["failed_login_attempts"] = 0
            user["locked_until"] = None
        if locked_until and not isinstance(locked_until, datetime):
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Account locked. Try again soon.",
            )
        hashed_password = user["password_hash"]
    else:
        hashed_password = DUMMY_PASSWORD_HASH

    password_valid = verify_password(user_data.password, hashed_password)

    if not user or not password_valid:
        response_status = status.HTTP_401_UNAUTHORIZED
        detail_message = "Incorrect username/email or password"
        if user:
            updated_user = users_collection.find_one_and_update(
                {"_id": user["_id"]},
                {"$inc": {"failed_login_attempts": 1}},
                return_document=ReturnDocument.AFTER,
            )
            failed_attempts = int(
                (updated_user or {}).get("failed_login_attempts") or 0
            )
            if failed_attempts >= MAX_FAILED_LOGIN_ATTEMPTS:
                lockout_expires_at = now + LOCKOUT_DURATION
                users_collection.update_one(
                    {"_id": user["_id"]},
                    {"$set": {"locked_until": lockout_expires_at}},
                )
                detail_message = "Account locked due to too many failed attempts"
                response_status = status.HTTP_429_TOO_MANY_REQUESTS
        raise HTTPException(
            status_code=response_status,
            detail=detail_message,
        )

    if user["account_status"] != "active":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is not active",
        )

    if user.get("failed_login_attempts") or user.get("locked_until"):
        users_collection.update_one(
            {"_id": user["_id"]},
            {"$set": {"failed_login_attempts": 0, "locked_until": None}},
        )

    token = create_access_token(str(user["_id"]))
    return _build_user_response(user, token=token)


def update_default_pool(user_id: str, payload: UserDefaultPoolUpdate) -> UserResponse:
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

    return _build_user_response(updated_user)


def list_user_pools(user_id: str) -> list[PoolResponse]:
    user_oid = parse_object_id(user_id, "user_id")

    memberships = pool_memberships_collection.find(
        {
            "userId": user_oid,
            "status": {"$in": ["active", "eliminated", "winner"]},
        }
    )
    pool_ids = {membership["poolId"] for membership in memberships}
    if not pool_ids:
        return []

    pools = pools_collection.find({"_id": {"$in": list(pool_ids)}})

    def _parse_optional_int(value: Any) -> int | None:
        if isinstance(value, int):
            return value
        if isinstance(value, float):
            return int(value)
        return None

    responses: list[PoolResponse] = []
    for pool in pools:
        winners_raw = pool.get("winners", []) or []
        winner_user_ids = [
            str(candidate)
            for candidate in winners_raw
            if isinstance(candidate, ObjectId)
        ]

        status_value = pool.get("status")
        status_text = status_value if isinstance(status_value, str) else "open"
        competitive_since_week = _parse_optional_int(pool.get("competitive_since_week"))
        completed_week = _parse_optional_int(pool.get("completed_week"))
        completed_at = pool.get("completed_at")
        if not isinstance(completed_at, datetime):
            completed_at = None

        start_week = _parse_optional_int(pool.get("start_week")) or 1
        if start_week < 1:
            start_week = 1

        responses.append(
            PoolResponse(
                id=str(pool["_id"]),
                name=pool.get("name", ""),
                owner_id=(str(pool.get("ownerId")) if pool.get("ownerId") else ""),
                season_id=(str(pool.get("seasonId")) if pool.get("seasonId") else ""),
                created_at=pool.get("created_at", datetime.now()),
                current_week=pool.get("current_week", 1),
                start_week=start_week,
                settings=pool.get("settings", {}),
                invited_user_ids=[],
                status=status_text,
                is_competitive=bool(pool.get("is_competitive")),
                competitive_since_week=competitive_since_week,
                completed_week=completed_week,
                completed_at=completed_at,
                winner_user_ids=winner_user_ids,
            )
        )

    return responses


def get_user_profile(user_id: str) -> UserResponse:
    user_oid = parse_object_id(user_id, "user_id")
    user = users_collection.find_one({"_id": user_oid})
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )
    return _build_user_response(user)


def delete_user(user_id: str) -> None:
    user_oid = parse_object_id(user_id, "user_id")

    user = users_collection.find_one({"_id": user_oid})
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    owned_pools = list(pools_collection.find({"ownerId": user_oid}, {"_id": 1}))
    for pool in owned_pools:
        pool_id = pool.get("_id")
        if pool_id is None:
            continue
        pools_service.delete_pool(str(pool_id), user_id)

    pool_memberships_collection.delete_many({"userId": user_oid})
    picks_collection.delete_many({"userId": user_oid})

    delete_result = users_collection.delete_one({"_id": user_oid})
    if delete_result.deleted_count != 1:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to delete user",
        )


def _fuzzy_score(query: str, candidate: str) -> float:
    if not query or not candidate:
        return 0.0
    return SequenceMatcher(a=query, b=candidate).ratio()


def search_active_users(
    query: str, pool_id: str | None = None, limit: int = 10
) -> list[UserSearchResult]:
    trimmed = query.strip()
    if len(trimmed) < 2:
        return []

    effective_limit = max(1, min(limit, 25))

    pool_membership_status: dict[ObjectId, str] = {}
    if pool_id:
        pool_oid = parse_object_id(pool_id, "pool_id")
        membership_cursor = pool_memberships_collection.find({"poolId": pool_oid})
        for membership in membership_cursor:
            member_id = membership.get("userId")
            if isinstance(member_id, ObjectId):
                pool_membership_status[member_id] = membership.get("status", "")

    pieces = [part for part in trimmed.lower().split() if part]
    if not pieces:
        pieces = [trimmed.lower()]
    escaped = ".*".join(re.escape(part) for part in pieces)
    pattern = escaped if escaped else re.escape(trimmed.lower())

    selector = {
        "account_status": "active",
        "$or": [
            {"display_name": {"$regex": pattern, "$options": "i"}},
            {"email": {"$regex": pattern, "$options": "i"}},
            {"username": {"$regex": pattern, "$options": "i"}},
        ],
    }

    projection = {"display_name": 1, "email": 1, "username": 1}
    fetch_limit = max(effective_limit * 4, 40)
    cursor = users_collection.find(selector, projection).limit(fetch_limit)

    lower_query = trimmed.lower()

    def prefix_boost(value: str) -> float:
        if not value:
            return 0.0
        lowered = value.lower()
        if lowered.startswith(lower_query):
            return 1.0
        boost = 0.0
        for token in pieces:
            if lowered.startswith(token):
                boost = max(boost, 0.85)
            elif token and token in lowered:
                boost = max(boost, 0.6)
        return boost

    ranked: list[tuple[float, float, str, dict[str, Any]]] = []

    for doc in cursor:
        display_name = doc.get("display_name") or ""
        email = doc.get("email") or ""
        username = doc.get("username") or ""
        fuzzy_score = max(
            _fuzzy_score(lower_query, display_name.lower()),
            _fuzzy_score(lower_query, email.lower()),
            _fuzzy_score(lower_query, username.lower()),
        )
        boost = max(
            prefix_boost(display_name),
            prefix_boost(email),
            prefix_boost(username),
        )
        score = max(fuzzy_score, boost)
        if score <= 0.0:
            continue
        tie_break = display_name.lower() or username.lower() or email.lower()
        ranked.append((score, boost, tie_break, doc))

    ranked.sort(key=lambda item: (-item[0], -item[1], item[2]))

    results: list[UserSearchResult] = []
    for _, _, _, doc in ranked[:effective_limit]:
        user_id = doc.get("_id")
        if not isinstance(user_id, ObjectId):
            continue
        status = pool_membership_status.get(user_id)
        if status in {"active", "invited", "eliminated"}:
            continue
        username = doc.get("username") or ""
        results.append(
            UserSearchResult(
                id=str(user_id),
                display_name=(
                    doc.get("display_name") or username or doc.get("email", "")
                ),
                email=doc.get("email") or "",
                username=username,
                membership_status=status if status else None,
            )
        )

    return results
