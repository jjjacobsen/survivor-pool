from datetime import datetime
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
