from datetime import datetime
from typing import Any

from bson import ObjectId
from fastapi import HTTPException, status
from pymongo import ReturnDocument

from ..db.mongo import (
    picks_collection,
    pool_memberships_collection,
    pools_collection,
    seasons_collection,
    users_collection,
)
from ..schemas.pools import (
    AvailableContestantResponse,
    AvailableContestantsResponse,
    ContestantDetail,
    ContestantDetailResponse,
    CurrentPickSummary,
    PendingInvitesResponse,
    PendingInviteSummary,
    PoolAdvanceMissingMember,
    PoolAdvanceRequest,
    PoolAdvanceResponse,
    PoolAdvanceStatusResponse,
    PoolCreateRequest,
    PoolInviteDecisionRequest,
    PoolInviteDecisionResponse,
    PoolInviteRequest,
    PoolInviteResponse,
    PoolMembershipListResponse,
    PoolMemberSummary,
    PoolResponse,
)
from .common import parse_object_id


def create_pool(pool_data: PoolCreateRequest) -> PoolResponse:
    name = pool_data.name.strip()
    if not name:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Pool name is required",
        )

    owner_id = parse_object_id(pool_data.owner_id, "owner_id")
    if not users_collection.find_one({"_id": owner_id}):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Owner not found",
        )

    season_id = parse_object_id(pool_data.season_id, "season_id")
    if not seasons_collection.find_one({"_id": season_id}):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Season not found",
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
        pool_memberships_collection.find_one_and_update(
            {"poolId": pool_id, "userId": invitee_id},
            {
                "$set": {
                    "role": "member",
                    "status": "invited",
                    "invitedAt": now,
                    "joinedAt": None,
                    "eliminated_week": None,
                    "eliminated_date": None,
                },
                "$setOnInsert": {
                    "total_picks": 0,
                    "score": 0,
                    "available_contestants": [],
                },
            },
            upsert=True,
            return_document=ReturnDocument.AFTER,
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


def _coerce_datetime(value: Any) -> datetime | None:
    return value if isinstance(value, datetime) else None


def _build_member_summary(
    membership: dict[str, Any], user_doc: dict[str, Any]
) -> PoolMemberSummary:
    raw_user_id = membership.get("userId") or user_doc.get("_id")
    if isinstance(raw_user_id, ObjectId):
        user_id = str(raw_user_id)
    else:
        user_id = str(raw_user_id)

    display_name = user_doc.get("display_name") or ""
    email = user_doc.get("email") or ""
    if not display_name:
        display_name = email or user_id

    return PoolMemberSummary(
        user_id=user_id,
        display_name=display_name,
        email=email,
        role=membership.get("role", "member"),
        status=membership.get("status", "active"),
        joined_at=_coerce_datetime(membership.get("joinedAt")),
        invited_at=_coerce_datetime(membership.get("invitedAt")),
    )


def get_available_contestants(
    pool_id: str, user_id: str
) -> AvailableContestantsResponse:
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
    if not membership or membership.get("status") != "active":
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

    current_week = pool["current_week"]

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


def get_contestant_detail(
    pool_id: str, contestant_id: str, user_id: str
) -> ContestantDetailResponse:
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
    if not membership or membership.get("status") != "active":
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

    current_week = pool["current_week"]

    eliminated_week: int | None = None
    for elimination in season.get("eliminations", []):
        if elimination.get("eliminated_contestant_id") == contestant_id:
            eliminated_week = elimination["week"]
            break

    prior_pick = picks_collection.find_one(
        {"userId": user_oid, "poolId": pool_oid, "contestant_id": contestant_id}
    )
    already_picked_week = prior_pick.get("week") if prior_pick else None

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


def get_pool_advance_status(pool_id: str, user_id: str) -> PoolAdvanceStatusResponse:
    pool, pool_oid, _ = _require_pool_owner(pool_id, user_id)
    current_week = pool["current_week"]
    status_payload, _ = _compute_pool_advance_status(pool_oid, current_week)
    return status_payload


def advance_pool_week(pool_id: str, payload: PoolAdvanceRequest) -> PoolAdvanceResponse:
    pool, pool_oid, _ = _require_pool_owner(pool_id, payload.user_id)

    current_week = pool["current_week"]

    missing_ids: list[ObjectId] = []
    if payload.skip:
        picks_collection.delete_many({"poolId": pool_oid, "week": current_week})
    else:
        _, missing_ids = _compute_pool_advance_status(pool_oid, current_week)
        if missing_ids:
            now = datetime.now()
            pool_memberships_collection.update_many(
                {
                    "poolId": pool_oid,
                    "userId": {"$in": missing_ids},
                    "status": "active",
                },
                {
                    "$set": {
                        "status": "eliminated",
                        "eliminated_week": current_week,
                        "eliminated_date": now,
                    }
                },
            )

    update_filter: dict[str, Any] = {
        "_id": pool_oid,
        "current_week": current_week,
    }

    updated_pool = pools_collection.find_one_and_update(
        update_filter,
        {"$inc": {"current_week": 1}},
        return_document=ReturnDocument.AFTER,
    )

    if not updated_pool:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Pool week changed, retry",
        )

    new_week = updated_pool["current_week"]

    return PoolAdvanceResponse(new_current_week=new_week)


def list_pool_memberships(pool_id: str, owner_id: str) -> PoolMembershipListResponse:
    _, pool_oid, _ = _require_pool_owner(pool_id, owner_id)

    membership_docs = list(pool_memberships_collection.find({"poolId": pool_oid}))
    if not membership_docs:
        return PoolMembershipListResponse(pool_id=str(pool_oid), members=[])

    user_ids: list[ObjectId] = []
    for membership in membership_docs:
        member_id = membership.get("userId")
        if isinstance(member_id, ObjectId):
            user_ids.append(member_id)

    if not user_ids:
        return PoolMembershipListResponse(pool_id=str(pool_oid), members=[])

    users_cursor = users_collection.find(
        {"_id": {"$in": user_ids}},
        {"display_name": 1, "email": 1},
    )
    users_by_id: dict[ObjectId, dict[str, Any]] = {
        user["_id"]: user for user in users_cursor
    }

    summaries: list[PoolMemberSummary] = []
    for membership in membership_docs:
        member_id = membership.get("userId")
        if not isinstance(member_id, ObjectId):
            continue
        user_doc = users_by_id.get(member_id)
        if not user_doc:
            continue
        summaries.append(_build_member_summary(membership, user_doc))

    summaries.sort(
        key=lambda member: (
            0 if member.role == "owner" else 1,
            0 if member.status == "active" else 1,
            member.display_name.lower(),
        )
    )

    return PoolMembershipListResponse(pool_id=str(pool_oid), members=summaries)


def invite_user_to_pool(pool_id: str, payload: PoolInviteRequest) -> PoolInviteResponse:
    _, pool_oid, owner_oid = _require_pool_owner(pool_id, payload.owner_id)

    invited_oid = parse_object_id(payload.invited_user_id, "invited_user_id")
    if invited_oid == owner_oid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Owner is already in this pool",
        )

    target_user = users_collection.find_one(
        {"_id": invited_oid, "account_status": "active"},
        {"display_name": 1, "email": 1},
    )
    if not target_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    existing = pool_memberships_collection.find_one(
        {"poolId": pool_oid, "userId": invited_oid}
    )
    if existing and existing.get("status") == "active":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User already in this pool",
        )

    now = datetime.now()
    updated = pool_memberships_collection.find_one_and_update(
        {"poolId": pool_oid, "userId": invited_oid},
        {
            "$set": {
                "role": "member",
                "status": "invited",
                "invitedAt": now,
                "joinedAt": None,
                "eliminated_week": None,
                "eliminated_date": None,
            },
            "$setOnInsert": {
                "total_picks": 0,
                "score": 0,
                "available_contestants": [],
            },
        },
        upsert=True,
        return_document=ReturnDocument.AFTER,
    )

    member = _build_member_summary(updated, target_user)
    return PoolInviteResponse(member=member)


def delete_pool(pool_id: str, owner_id: str) -> None:
    _, pool_oid, _ = _require_pool_owner(pool_id, owner_id)

    picks_collection.delete_many({"poolId": pool_oid})
    pool_memberships_collection.delete_many({"poolId": pool_oid})

    delete_result = pools_collection.delete_one({"_id": pool_oid})
    if delete_result.deleted_count != 1:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pool not found",
        )

    users_collection.update_many(
        {"default_pool": pool_oid},
        {"$set": {"default_pool": None}},
    )


def respond_to_invite(
    pool_id: str, payload: PoolInviteDecisionRequest
) -> PoolInviteDecisionResponse:
    pool_oid = parse_object_id(pool_id, "pool_id")
    user_oid = parse_object_id(payload.user_id, "user_id")

    action = payload.action.strip().lower()
    if action not in {"accept", "decline"}:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Unsupported action",
        )

    membership = pool_memberships_collection.find_one(
        {"poolId": pool_oid, "userId": user_oid}
    )
    if not membership or membership.get("status") != "invited":
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invite not found",
        )

    now = datetime.now()
    update_doc: dict[str, Any]
    if action == "accept":
        update_doc = {
            "$set": {
                "status": "active",
                "joinedAt": now,
                "invitedAt": membership.get("invitedAt") or now,
                "eliminated_week": None,
                "eliminated_date": None,
            }
        }
    else:
        update_doc = {
            "$set": {
                "status": "declined",
                "joinedAt": None,
                "invitedAt": membership.get("invitedAt") or now,
            }
        }

    updated_membership = pool_memberships_collection.find_one_and_update(
        {"poolId": pool_oid, "userId": user_oid, "status": "invited"},
        update_doc,
        return_document=ReturnDocument.AFTER,
    )
    if not updated_membership:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Invite already handled",
        )

    user_doc = users_collection.find_one(
        {"_id": user_oid},
        {"display_name": 1, "email": 1},
    )
    if not user_doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    member = _build_member_summary(updated_membership, user_doc)
    return PoolInviteDecisionResponse(member=member)


def get_pending_invites_for_user(user_id: str) -> PendingInvitesResponse:
    user_oid = parse_object_id(user_id, "user_id")

    membership_docs = list(
        pool_memberships_collection.find({"userId": user_oid, "status": "invited"})
    )
    if not membership_docs:
        return PendingInvitesResponse(invites=[])

    pool_ids: set[ObjectId] = set()
    for membership in membership_docs:
        pool_id = membership.get("poolId")
        if isinstance(pool_id, ObjectId):
            pool_ids.add(pool_id)

    if not pool_ids:
        return PendingInvitesResponse(invites=[])

    pools_cursor = pools_collection.find(
        {"_id": {"$in": list(pool_ids)}},
        {"name": 1, "ownerId": 1, "seasonId": 1},
    )
    pools_by_id: dict[ObjectId, dict[str, Any]] = {
        pool["_id"]: pool for pool in pools_cursor
    }

    owner_ids: set[ObjectId] = set()
    season_ids: set[ObjectId] = set()
    for pool in pools_by_id.values():
        owner = pool.get("ownerId")
        if isinstance(owner, ObjectId):
            owner_ids.add(owner)
        season = pool.get("seasonId")
        if isinstance(season, ObjectId):
            season_ids.add(season)

    owners_cursor = users_collection.find(
        {"_id": {"$in": list(owner_ids)}},
        {"display_name": 1, "email": 1},
    )
    owners_by_id: dict[ObjectId, dict[str, Any]] = {
        owner["_id"]: owner for owner in owners_cursor
    }

    seasons_cursor = seasons_collection.find(
        {"_id": {"$in": list(season_ids)}},
        {"season_number": 1},
    )
    seasons_by_id: dict[ObjectId, int | None] = {
        season["_id"]: season.get("season_number") for season in seasons_cursor
    }

    invites: list[PendingInviteSummary] = []
    for membership in membership_docs:
        pool_oid = membership.get("poolId")
        if not isinstance(pool_oid, ObjectId):
            continue
        pool = pools_by_id.get(pool_oid)
        if not pool:
            continue
        owner_id = pool.get("ownerId")
        owner_doc = (
            owners_by_id.get(owner_id) if isinstance(owner_id, ObjectId) else None
        )
        owner_display = ""
        if owner_doc:
            owner_display = (
                owner_doc.get("display_name") or owner_doc.get("email") or ""
            )

        season_id = pool.get("seasonId")
        season_number: int | None = None
        season_id_str = ""
        if isinstance(season_id, ObjectId):
            season_number = seasons_by_id.get(season_id)
            season_id_str = str(season_id)

        invited_at = _coerce_datetime(membership.get("invitedAt"))

        invites.append(
            PendingInviteSummary(
                pool_id=str(pool_oid),
                pool_name=pool.get("name", ""),
                owner_display_name=owner_display,
                season_id=season_id_str,
                season_number=season_number,
                invited_at=invited_at,
            )
        )

    invites.sort(
        key=lambda invite: (
            invite.invited_at is None,
            invite.pool_name.lower(),
        )
    )

    return PendingInvitesResponse(invites=invites)


def _require_pool_owner(
    pool_id: str, user_id: str
) -> tuple[dict[str, Any], ObjectId, ObjectId]:
    pool_oid = parse_object_id(pool_id, "pool_id")
    owner_oid = parse_object_id(user_id, "user_id")

    pool = pools_collection.find_one({"_id": pool_oid})
    if not pool:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pool not found",
        )

    if pool.get("ownerId") != owner_oid:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User is not the pool owner",
        )

    return pool, pool_oid, owner_oid


def _compute_pool_advance_status(
    pool_oid: ObjectId, current_week: int
) -> tuple[PoolAdvanceStatusResponse, list[ObjectId]]:
    active_cursor = pool_memberships_collection.find(
        {"poolId": pool_oid, "status": "active"},
        {"userId": 1},
    )

    active_user_ids: list[ObjectId] = []
    for membership in active_cursor:
        member_user_id = membership.get("userId")
        if isinstance(member_user_id, ObjectId):
            active_user_ids.append(member_user_id)

    active_member_count = len(active_user_ids)
    if not active_user_ids:
        empty_status = PoolAdvanceStatusResponse(
            current_week=current_week,
            active_member_count=0,
            locked_count=0,
            missing_count=0,
            missing_members=[],
        )
        return empty_status, []

    picks_cursor = picks_collection.find(
        {
            "poolId": pool_oid,
            "week": current_week,
            "userId": {"$in": active_user_ids},
        },
        {"userId": 1},
    )

    locked_user_ids = {
        pick.get("userId")
        for pick in picks_cursor
        if isinstance(pick.get("userId"), ObjectId)
    }

    missing_user_ids = [
        user_id for user_id in active_user_ids if user_id not in locked_user_ids
    ]

    missing_members: list[PoolAdvanceMissingMember] = []
    if missing_user_ids:
        users_cursor = users_collection.find(
            {"_id": {"$in": missing_user_ids}},
            {"display_name": 1},
        )
        display_names: dict[ObjectId, str] = {}
        for user in users_cursor:
            display_names[user["_id"]] = user.get("display_name", "")

        for user_id in missing_user_ids:
            name = display_names.get(user_id, "") or str(user_id)
            missing_members.append(
                PoolAdvanceMissingMember(
                    user_id=str(user_id),
                    display_name=name,
                )
            )

    missing_members.sort(key=lambda member: member.display_name.lower())

    status_payload = PoolAdvanceStatusResponse(
        current_week=current_week,
        active_member_count=active_member_count,
        locked_count=active_member_count - len(missing_user_ids),
        missing_count=len(missing_user_ids),
        missing_members=missing_members,
    )

    return status_payload, missing_user_ids
