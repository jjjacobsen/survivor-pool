import re
from datetime import datetime
from difflib import SequenceMatcher
from typing import Any

from bson import ObjectId
from fastapi import HTTPException, status

from ..core.security import hash_password, verify_password
from ..db.mongo import (
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
from .common import parse_object_id


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
    }

    result = users_collection.insert_one(user_doc)
    if not result.inserted_id:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create user",
        )

    return UserResponse(
        id=str(result.inserted_id),
        username=user_data.username,
        email=user_data.email,
        display_name=user_data.display_name,
        account_status="active",
        created_at=user_doc["created_at"],
        default_pool=None,
    )


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

    return UserResponse(
        id=user_id,
        username=updated_user["username"],
        email=updated_user["email"],
        display_name=updated_user["display_name"],
        account_status=updated_user["account_status"],
        created_at=updated_user["created_at"],
        default_pool=(
            str(updated_user.get("default_pool"))
            if isinstance(updated_user.get("default_pool"), ObjectId)
            else None
        ),
    )


def list_user_pools(user_id: str) -> list[PoolResponse]:
    user_oid = parse_object_id(user_id, "user_id")

    memberships = pool_memberships_collection.find(
        {"userId": user_oid, "status": {"$in": ["active", "eliminated"]}}
    )
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


def _fuzzy_score(query: str, candidate: str) -> float:
    if not query or not candidate:
        return 0.0
    return SequenceMatcher(a=query, b=candidate).ratio()


def search_active_users(
    query: str, pool_id: str | None = None
) -> list[UserSearchResult]:
    trimmed = query.strip()
    if len(trimmed) < 2:
        return []

    pool_membership_status: dict[ObjectId, str] = {}
    if pool_id:
        pool_oid = parse_object_id(pool_id, "pool_id")
        membership_cursor = pool_memberships_collection.find({"poolId": pool_oid})
        for membership in membership_cursor:
            member_id = membership.get("userId")
            if isinstance(member_id, ObjectId):
                pool_membership_status[member_id] = membership.get("status", "")

    pieces = trimmed.split()
    escaped = ".*".join(re.escape(part) for part in pieces)
    pattern = f"{escaped}"

    selector = {
        "account_status": "active",
        "$or": [
            {"display_name": {"$regex": pattern, "$options": "i"}},
            {"email": {"$regex": pattern, "$options": "i"}},
            {"username": {"$regex": pattern, "$options": "i"}},
        ],
    }

    projection = {"display_name": 1, "email": 1, "username": 1}
    cursor = users_collection.find(selector, projection).limit(40)

    lower_query = trimmed.lower()
    ranked: list[tuple[float, str, dict[str, Any]]] = []

    for doc in cursor:
        display_name = doc.get("display_name") or ""
        email = doc.get("email") or ""
        username = doc.get("username") or ""
        score = max(
            _fuzzy_score(lower_query, display_name.lower()),
            _fuzzy_score(lower_query, email.lower()),
            _fuzzy_score(lower_query, username.lower()),
        )
        tie_break = display_name.lower() or username.lower() or email.lower()
        ranked.append((score, tie_break, doc))

    ranked.sort(key=lambda item: (-item[0], item[1]))

    results: list[UserSearchResult] = []
    for score, _, doc in ranked[:10]:
        if score <= 0.0:
            continue
        user_id = doc.get("_id")
        if not isinstance(user_id, ObjectId):
            continue
        status = pool_membership_status.get(user_id)
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
