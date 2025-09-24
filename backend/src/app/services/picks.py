from datetime import datetime

from fastapi import HTTPException, status

from ..db.mongo import (
    picks_collection,
    pool_memberships_collection,
    pools_collection,
    seasons_collection,
)
from ..schemas.picks import PickRequest, PickResponse
from .common import parse_object_id


def create_pick(pool_id: str, payload: PickRequest) -> PickResponse:
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

    current_week = pool["current_week"]

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
        prior_week = prior_pick.get("week")
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
