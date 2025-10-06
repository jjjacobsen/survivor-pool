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
    PoolEliminatedMember,
    PoolInviteDecisionRequest,
    PoolInviteDecisionResponse,
    PoolInviteRequest,
    PoolInviteResponse,
    PoolLeaderboardEntry,
    PoolLeaderboardResponse,
    PoolMembershipListResponse,
    PoolMemberSummary,
    PoolResponse,
    PoolWinnerSummary,
)
from .common import parse_object_id

ELIMINATION_REASON_MISSED_PICK = "missed_pick"
ELIMINATION_REASON_CONTESTANT = "contestant_voted_out"
ELIMINATION_REASON_NO_OPTIONS = "no_options_left"

POOL_STATUS_OPEN = "open"
POOL_STATUS_COMPLETED = "completed"
MEMBERSHIP_STATUS_WINNER = "winner"


def _resolve_contestant_tribe(
    season: dict[str, Any], contestant_id: str, week: int
) -> tuple[str | None, str | None]:
    if week < 1:
        week = 1

    latest_week = -1
    latest_entry: dict[str, Any] | None = None
    for entry in season.get("tribe_timeline", []) or []:
        entry_week = entry.get("week")
        if not isinstance(entry_week, int) or entry_week > week:
            continue
        if entry_week >= latest_week:
            latest_week = entry_week
            latest_entry = entry

    if not latest_entry:
        return None, None

    for tribe in latest_entry.get("tribes", []) or []:
        members = tribe.get("members") or []
        if isinstance(members, list) and contestant_id in members:
            tribe_name = tribe.get("name")
            tribe_color = tribe.get("color")
            name_value = (
                tribe_name if isinstance(tribe_name, str) and tribe_name else None
            )
            color_value = (
                tribe_color if isinstance(tribe_color, str) and tribe_color else None
            )
            return name_value, color_value

    return None, None


def _collect_active_contestant_ids(season: dict[str, Any], week: int) -> set[str]:
    if week < 1:
        week = 1

    eliminated_before_week = {
        elimination.get("eliminated_contestant_id")
        for elimination in season.get("eliminations", [])
        if elimination.get("week", 0) < week
        and isinstance(elimination.get("eliminated_contestant_id"), str)
    }

    active_ids: set[str] = set()
    for contestant in season.get("contestants", []) or []:
        contestant_id = contestant.get("id")
        if (
            isinstance(contestant_id, str)
            and contestant_id not in eliminated_before_week
        ):
            active_ids.add(contestant_id)

    return active_ids


def _gather_used_contestants(
    pool_oid: ObjectId, upto_week: int
) -> dict[ObjectId, set[str]]:
    if upto_week < 1:
        upto_week = 1

    query: dict[str, Any] = {"poolId": pool_oid, "week": {"$lt": upto_week}}
    cursor = picks_collection.find(query, {"userId": 1, "contestant_id": 1})

    used: dict[ObjectId, set[str]] = {}
    for pick in cursor:
        pick_user = pick.get("userId")
        pick_contestant = pick.get("contestant_id")
        if isinstance(pick_user, ObjectId) and isinstance(pick_contestant, str):
            used.setdefault(pick_user, set()).add(pick_contestant)

    return used


def _recalculate_pool_scores(
    pool_oid: ObjectId, season: dict[str, Any], target_week: int
) -> None:
    if target_week < 1:
        target_week = 1

    active_contestants = _collect_active_contestant_ids(season, target_week)
    used_by_user = _gather_used_contestants(pool_oid, target_week)

    active_cursor = pool_memberships_collection.find(
        {"poolId": pool_oid, "status": "active"},
        {"_id": 1, "userId": 1},
    )

    for membership in active_cursor:
        membership_id = membership.get("_id")
        member_user = membership.get("userId")
        if not isinstance(membership_id, ObjectId) or not isinstance(
            member_user, ObjectId
        ):
            continue

        remaining_ids = sorted(
            active_contestants - used_by_user.get(member_user, set())
        )
        pool_memberships_collection.update_one(
            {"_id": membership_id},
            {
                "$set": {
                    "available_contestants": remaining_ids,
                    "score": len(remaining_ids),
                }
            },
        )

    pool_memberships_collection.update_many(
        {"poolId": pool_oid, "status": {"$ne": "active"}},
        {"$set": {"available_contestants": [], "score": 0}},
    )


def _maybe_mark_pool_competitive(pool_oid: ObjectId, pool_doc: dict[str, Any]) -> None:
    if pool_doc.get("is_competitive"):
        return

    active_count = pool_memberships_collection.count_documents(
        {"poolId": pool_oid, "status": "active"}
    )
    if active_count < 2:
        return

    current_week = pool_doc.get("current_week", 1)
    if not isinstance(current_week, int):
        current_week = 1

    pools_collection.update_one(
        {"_id": pool_oid, "is_competitive": False},
        {"$set": {"is_competitive": True, "competitive_since_week": current_week}},
    )


def _mark_members_as_winners(
    pool_oid: ObjectId, winner_ids: list[ObjectId], finished_week: int, now: datetime
) -> None:
    if not winner_ids:
        return

    pool_memberships_collection.update_many(
        {"poolId": pool_oid, "userId": {"$in": winner_ids}},
        {
            "$set": {
                "status": MEMBERSHIP_STATUS_WINNER,
                "elimination_reason": None,
                "eliminated_week": None,
                "eliminated_date": None,
                "finished_week": finished_week,
                "finished_date": now,
                "final_rank": 1,
                "score": 0,
                "available_contestants": [],
            }
        },
    )


def _load_winner_summaries(winner_ids: list[ObjectId]) -> list[PoolWinnerSummary]:
    if not winner_ids:
        return []

    users_cursor = users_collection.find(
        {"_id": {"$in": winner_ids}},
        {"display_name": 1, "email": 1},
    )
    names_by_id: dict[ObjectId, str] = {}
    for user in users_cursor:
        label = user.get("display_name") or user.get("email") or ""
        names_by_id[user["_id"]] = label

    winners: list[PoolWinnerSummary] = []
    for winner_id in winner_ids:
        label = names_by_id.get(winner_id, str(winner_id))
        winners.append(PoolWinnerSummary(user_id=str(winner_id), display_name=label))

    winners.sort(key=lambda winner: winner.display_name.lower())
    return winners


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
    season = seasons_collection.find_one(
        {"_id": season_id},
        {"contestants": 1, "eliminations": 1, "tribe_timeline": 1},
    )
    if not season:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Season not found",
        )

    start_week = pool_data.start_week if isinstance(pool_data.start_week, int) else 1
    if start_week < 1 or start_week > 6:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Start week must be between 1 and 6",
        )

    now = datetime.now()
    pool_doc = {
        "name": name,
        "ownerId": owner_id,
        "seasonId": season_id,
        "created_at": now,
        "current_week": start_week,
        "start_week": start_week,
        "settings": {},
        "status": POOL_STATUS_OPEN,
        "is_competitive": False,
        "competitive_since_week": None,
        "completed_week": None,
        "completed_at": None,
        "winners": [],
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
            "elimination_reason": None,
            "eliminated_week": None,
            "eliminated_date": None,
            "score": 0,
            "final_rank": None,
            "finished_week": None,
            "finished_date": None,
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
                    "score": 0,
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

    _recalculate_pool_scores(pool_id, season, pool_doc["current_week"])

    return PoolResponse(
        id=str(pool_id),
        name=name,
        owner_id=pool_data.owner_id,
        season_id=pool_data.season_id,
        created_at=now,
        current_week=start_week,
        start_week=start_week,
        settings=pool_doc["settings"],
        invited_user_ids=invited_user_ids,
        status=POOL_STATUS_OPEN,
        is_competitive=False,
        competitive_since_week=None,
        completed_week=None,
        completed_at=None,
        winner_user_ids=[],
    )


def _coerce_datetime(value: Any) -> datetime | None:
    return value if isinstance(value, datetime) else None


def _coerce_int(value: Any) -> int | None:
    if isinstance(value, int):
        return value
    if isinstance(value, float):
        return int(value)
    if isinstance(value, str):
        try:
            return int(value)
        except ValueError:
            return None
    return None


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

    final_rank_value = membership.get("final_rank")
    if isinstance(final_rank_value, int):
        final_rank = final_rank_value
    elif isinstance(final_rank_value, float):
        final_rank = int(final_rank_value)
    else:
        final_rank = None

    finished_week_value = membership.get("finished_week")
    if isinstance(finished_week_value, int):
        finished_week = finished_week_value
    elif isinstance(finished_week_value, float):
        finished_week = int(finished_week_value)
    else:
        finished_week = None

    return PoolMemberSummary(
        user_id=user_id,
        display_name=display_name,
        email=email,
        role=membership.get("role", "member"),
        status=membership.get("status", "active"),
        joined_at=_coerce_datetime(membership.get("joinedAt")),
        invited_at=_coerce_datetime(membership.get("invitedAt")),
        elimination_reason=membership.get("elimination_reason"),
        eliminated_week=membership.get("eliminated_week"),
        eliminated_date=_coerce_datetime(membership.get("eliminated_date")),
        final_rank=final_rank,
        finished_week=finished_week,
        finished_date=_coerce_datetime(membership.get("finished_date")),
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

    pool_status = pool.get("status", POOL_STATUS_OPEN)
    completed_week_raw = pool.get("completed_week")
    if isinstance(completed_week_raw, int):
        pool_completed_week = completed_week_raw
    elif isinstance(completed_week_raw, float):
        pool_completed_week = int(completed_week_raw)
    else:
        pool_completed_week = None

    pool_completed_at = _coerce_datetime(pool.get("completed_at"))

    winner_ids: list[ObjectId] = [
        candidate
        for candidate in pool.get("winners", []) or []
        if isinstance(candidate, ObjectId)
    ]
    winner_summaries = _load_winner_summaries(winner_ids) if winner_ids else []
    did_tie = len(winner_summaries) > 1

    current_week = pool.get("current_week", 1)

    membership = pool_memberships_collection.find_one(
        {"poolId": pool_oid, "userId": user_oid}
    )
    if not membership:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User is not a member of this pool",
        )

    cache = membership.get("available_contestants")
    score_value = membership.get("score")
    if not (
        isinstance(cache, list)
        and isinstance(score_value, int)
        and score_value == len(cache)
    ):
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Available contestant cache invalid",
        )

    membership_status = membership.get("status")
    if membership_status == "eliminated":
        return AvailableContestantsResponse(
            pool_id=str(pool_oid),
            user_id=str(user_oid),
            current_week=current_week,
            contestants=[],
            score=score_value,
            current_pick=None,
            is_eliminated=True,
            elimination_reason=membership.get("elimination_reason"),
            eliminated_week=membership.get("eliminated_week"),
            is_winner=False,
            pool_status=pool_status,
            pool_completed_week=pool_completed_week,
            pool_completed_at=pool_completed_at,
            winners=winner_summaries,
            did_tie=did_tie,
        )

    if membership_status == MEMBERSHIP_STATUS_WINNER:
        return AvailableContestantsResponse(
            pool_id=str(pool_oid),
            user_id=str(user_oid),
            current_week=current_week,
            contestants=[],
            score=score_value,
            current_pick=None,
            is_eliminated=False,
            elimination_reason=None,
            eliminated_week=None,
            is_winner=True,
            pool_status=pool_status,
            pool_completed_week=pool_completed_week,
            pool_completed_at=pool_completed_at,
            winners=winner_summaries,
            did_tie=did_tie,
        )

    if membership_status != "active":
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
        {"contestants": 1, "tribe_timeline": 1},
    )
    if not season:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Season not found",
        )

    contestant_catalog: dict[str, dict[str, Any]] = {
        contestant.get("id"): contestant
        for contestant in season.get("contestants", [])
        if isinstance(contestant.get("id"), str)
    }

    contestants: list[AvailableContestantResponse] = []
    for contestant_id in cache:
        if not isinstance(contestant_id, str):
            continue
        contestant = contestant_catalog.get(contestant_id, {})
        tribe_name, tribe_color = _resolve_contestant_tribe(
            season, contestant_id, current_week
        )
        contestants.append(
            AvailableContestantResponse(
                id=contestant_id,
                name=contestant.get("name") or contestant_id,
                subtitle=None,
                tribe_name=tribe_name,
                tribe_color=tribe_color,
            )
        )

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
        score=score_value,
        current_pick=current_pick_summary,
        is_eliminated=False,
        elimination_reason=None,
        eliminated_week=None,
        is_winner=False,
        pool_status=pool_status,
        pool_completed_week=pool_completed_week,
        pool_completed_at=pool_completed_at,
        winners=winner_summaries,
        did_tie=did_tie,
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
        {"contestants": 1, "eliminations": 1, "tribe_timeline": 1},
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

    tribe_name, tribe_color = _resolve_contestant_tribe(
        season, contestant_id, current_week
    )

    detail = ContestantDetail(
        id=contestant_id,
        name=target_contestant.get("name") or contestant_id,
        age=target_contestant.get("age"),
        occupation=target_contestant.get("occupation"),
        hometown=target_contestant.get("hometown"),
        tribe_name=tribe_name,
        tribe_color=tribe_color,
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
    if pool.get("status") == POOL_STATUS_COMPLETED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Pool already completed",
        )
    current_week = pool["current_week"]
    status_payload, _ = _compute_pool_advance_status(pool_oid, current_week)
    return status_payload


def advance_pool_week(pool_id: str, payload: PoolAdvanceRequest) -> PoolAdvanceResponse:
    pool, pool_oid, _ = _require_pool_owner(pool_id, payload.user_id)

    if pool.get("status") == POOL_STATUS_COMPLETED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Pool already completed",
        )

    current_week = pool["current_week"]
    elimination_reasons: dict[ObjectId, str] = {}
    pool_completed = False
    winner_ids: list[ObjectId] = []

    season_id = pool.get("seasonId")
    if not isinstance(season_id, ObjectId):
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
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Season not found for pool",
        )

    now = datetime.now()

    _, missing_ids = _compute_pool_advance_status(pool_oid, current_week)

    missing_set = {
        member_id for member_id in missing_ids if isinstance(member_id, ObjectId)
    }
    if missing_set:
        pool_memberships_collection.update_many(
            {
                "poolId": pool_oid,
                "userId": {"$in": list(missing_set)},
                "status": "active",
            },
            {
                "$set": {
                    "status": "eliminated",
                    "elimination_reason": ELIMINATION_REASON_MISSED_PICK,
                    "eliminated_week": current_week,
                    "eliminated_date": now,
                    "score": 0,
                    "available_contestants": [],
                }
            },
        )
        for member_id in missing_set:
            elimination_reasons[member_id] = ELIMINATION_REASON_MISSED_PICK

    eliminated_contestants = [
        elimination.get("eliminated_contestant_id")
        for elimination in season.get("eliminations", [])
        if elimination.get("week") == current_week
        and elimination.get("eliminated_contestant_id")
    ]

    if eliminated_contestants:
        losing_cursor = picks_collection.find(
            {
                "poolId": pool_oid,
                "week": current_week,
                "contestant_id": {"$in": eliminated_contestants},
            },
            {"userId": 1},
        )
        losing_ids: set[ObjectId] = set()
        for pick in losing_cursor:
            user_id = pick.get("userId")
            if isinstance(user_id, ObjectId) and user_id not in elimination_reasons:
                losing_ids.add(user_id)

        if losing_ids:
            pool_memberships_collection.update_many(
                {
                    "poolId": pool_oid,
                    "userId": {"$in": list(losing_ids)},
                    "status": "active",
                },
                {
                    "$set": {
                        "status": "eliminated",
                        "elimination_reason": ELIMINATION_REASON_CONTESTANT,
                        "eliminated_week": current_week,
                        "eliminated_date": now,
                        "score": 0,
                        "available_contestants": [],
                    }
                },
            )
        for member_id in losing_ids:
            elimination_reasons[member_id] = ELIMINATION_REASON_CONTESTANT

    next_week = current_week + 1

    eligible_contestants: set[str] = set()
    eliminated_before_next = {
        elimination.get("eliminated_contestant_id")
        for elimination in season.get("eliminations", [])
        if elimination.get("eliminated_contestant_id")
        and elimination.get("week", 0) < next_week
    }
    for contestant in season.get("contestants", []):
        contestant_id = contestant.get("id")
        if (
            isinstance(contestant_id, str)
            and contestant_id not in eliminated_before_next
        ):
            eligible_contestants.add(contestant_id)

    picks_cursor = picks_collection.find(
        {
            "poolId": pool_oid,
            "week": {"$lte": current_week},
        },
        {"userId": 1, "contestant_id": 1},
    )
    used_contestants: dict[ObjectId, set[str]] = {}
    for pick in picks_cursor:
        pick_user = pick.get("userId")
        pick_contestant = pick.get("contestant_id")
        if isinstance(pick_user, ObjectId) and isinstance(pick_contestant, str):
            used_contestants.setdefault(pick_user, set()).add(pick_contestant)

    no_option_ids: set[ObjectId] = set()
    active_cursor = pool_memberships_collection.find(
        {"poolId": pool_oid, "status": "active"},
        {"userId": 1},
    )
    for membership in active_cursor:
        member_user = membership.get("userId")
        if not isinstance(member_user, ObjectId):
            continue
        if member_user in elimination_reasons:
            continue
        remaining_options = eligible_contestants - used_contestants.get(
            member_user, set()
        )
        if not remaining_options:
            no_option_ids.add(member_user)

    if no_option_ids:
        pool_memberships_collection.update_many(
            {
                "poolId": pool_oid,
                "userId": {"$in": list(no_option_ids)},
                "status": "active",
            },
            {
                "$set": {
                    "status": "eliminated",
                    "elimination_reason": ELIMINATION_REASON_NO_OPTIONS,
                    "eliminated_week": current_week,
                    "eliminated_date": now,
                    "score": 0,
                    "available_contestants": [],
                }
            },
        )
        for member_id in no_option_ids:
            elimination_reasons[member_id] = ELIMINATION_REASON_NO_OPTIONS

    if pool.get("is_competitive"):
        active_after_cursor = pool_memberships_collection.find(
            {"poolId": pool_oid, "status": "active"},
            {"userId": 1},
        )
        remaining_active: list[ObjectId] = []
        for membership in active_after_cursor:
            member_user = membership.get("userId")
            if isinstance(member_user, ObjectId):
                remaining_active.append(member_user)

        if len(remaining_active) == 1:
            pool_completed = True
            winner_ids = remaining_active
        elif len(remaining_active) == 0 and elimination_reasons:
            tie_ids = [
                member_id
                for member_id in elimination_reasons
                if isinstance(member_id, ObjectId)
            ]
            if tie_ids:
                pool_completed = True
                winner_ids = tie_ids

    update_filter: dict[str, Any] = {
        "_id": pool_oid,
        "current_week": current_week,
    }

    seen_winners: set[ObjectId] = set()
    winner_list: list[ObjectId] = []
    if pool_completed and winner_ids:
        for candidate in winner_ids:
            if candidate not in seen_winners:
                seen_winners.add(candidate)
                winner_list.append(candidate)

    if pool_completed and not winner_list:
        pool_completed = False

    if pool_completed and winner_ids:
        _mark_members_as_winners(pool_oid, winner_list, current_week, now)

        pools_collection.update_one(
            {"_id": pool_oid},
            {
                "$set": {
                    "status": POOL_STATUS_COMPLETED,
                    "completed_week": current_week,
                    "completed_at": now,
                    "winners": winner_list,
                }
            },
        )

        updated_pool = pools_collection.find_one({"_id": pool_oid})
        new_week = updated_pool.get("current_week", current_week)
        _recalculate_pool_scores(pool_oid, season, current_week)
    else:
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
        _recalculate_pool_scores(pool_oid, season, new_week)

    if pool_completed and winner_list:
        for member_id in list(elimination_reasons.keys()):
            if member_id in seen_winners:
                elimination_reasons.pop(member_id, None)

    winner_summaries = _load_winner_summaries(winner_list)

    eliminated_members: list[PoolEliminatedMember] = []
    if elimination_reasons:
        eliminated_ids = list(elimination_reasons.keys())
        users_cursor = users_collection.find(
            {"_id": {"$in": eliminated_ids}},
            {"display_name": 1, "email": 1},
        )
        names_by_id: dict[ObjectId, str] = {}
        for user in users_cursor:
            label = user.get("display_name") or user.get("email") or ""
            names_by_id[user["_id"]] = label

        for member_id in eliminated_ids:
            if member_id in seen_winners:
                continue
            display_name = names_by_id.get(member_id, str(member_id))
            eliminated_members.append(
                PoolEliminatedMember(
                    user_id=str(member_id),
                    display_name=display_name,
                    reason=elimination_reasons[member_id],
                )
            )

        eliminated_members.sort(key=lambda member: member.display_name.lower())

    return PoolAdvanceResponse(
        new_current_week=new_week,
        eliminations=eliminated_members,
        pool_completed=pool_completed,
        winners=winner_summaries,
    )


def get_pool_leaderboard(pool_id: str, user_id: str) -> PoolLeaderboardResponse:
    pool_oid = parse_object_id(pool_id, "pool_id")
    user_oid = parse_object_id(user_id, "user_id")

    pool = pools_collection.find_one({"_id": pool_oid})
    if not pool:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pool not found",
        )

    viewer_membership = pool_memberships_collection.find_one(
        {"poolId": pool_oid, "userId": user_oid}
    )
    if not viewer_membership:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User is not a member of this pool",
        )

    viewer_status = viewer_membership.get("status") or ""
    allowed_statuses = {"active", "eliminated", MEMBERSHIP_STATUS_WINNER}
    if viewer_status not in allowed_statuses:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Leaderboard only available to pool members",
        )

    membership_docs = list(pool_memberships_collection.find({"poolId": pool_oid}))

    user_ids: list[ObjectId] = []
    for membership in membership_docs:
        member_id = membership.get("userId")
        if isinstance(member_id, ObjectId):
            user_ids.append(member_id)

    users_by_id: dict[ObjectId, dict[str, Any]] = {}
    if user_ids:
        users_cursor = users_collection.find(
            {"_id": {"$in": user_ids}},
            {"display_name": 1, "email": 1},
        )
        users_by_id = {user["_id"]: user for user in users_cursor}

    winner_ids: list[ObjectId] = [
        candidate
        for candidate in pool.get("winners", []) or []
        if isinstance(candidate, ObjectId)
    ]
    winner_summaries = _load_winner_summaries(winner_ids) if winner_ids else []
    did_tie = len(winner_summaries) > 1

    entry_payloads: list[dict[str, Any]] = []
    for membership in membership_docs:
        member_id = membership.get("userId")
        if not isinstance(member_id, ObjectId):
            continue
        status_value = membership.get("status") or "active"
        if status_value not in allowed_statuses:
            continue
        user_doc = users_by_id.get(member_id, {})
        display_name = (
            user_doc.get("display_name") or user_doc.get("email") or str(member_id)
        )
        score_value = _coerce_int(membership.get("score")) or 0
        raw_reason = membership.get("elimination_reason")
        elimination_reason = (
            raw_reason if isinstance(raw_reason, str) and raw_reason else None
        )
        entry_payloads.append(
            {
                "user_id": str(member_id),
                "display_name": display_name,
                "score": score_value,
                "status": status_value,
                "is_winner": status_value == MEMBERSHIP_STATUS_WINNER,
                "elimination_reason": elimination_reason,
                "eliminated_week": _coerce_int(membership.get("eliminated_week")),
                "final_rank": _coerce_int(membership.get("final_rank")),
                "finished_week": _coerce_int(membership.get("finished_week")),
                "finished_date": _coerce_datetime(membership.get("finished_date")),
            }
        )

    entry_payloads.sort(
        key=lambda entry: (
            -entry["score"],
            entry["display_name"].lower(),
        )
    )

    last_score: int | None = None
    current_rank = 0
    for index, payload in enumerate(entry_payloads):
        score_value = payload["score"]
        if last_score is None or score_value != last_score:
            current_rank = index + 1
            last_score = score_value
        payload["rank"] = current_rank

    entries = [PoolLeaderboardEntry(**payload) for payload in entry_payloads]

    current_week = _coerce_int(pool.get("current_week")) or 1
    pool_status_value = pool.get("status")
    status_label = (
        pool_status_value
        if isinstance(pool_status_value, str) and pool_status_value
        else POOL_STATUS_OPEN
    )

    return PoolLeaderboardResponse(
        pool_id=str(pool_oid),
        current_week=current_week,
        pool_status=status_label,
        pool_completed_week=_coerce_int(pool.get("completed_week")),
        pool_completed_at=_coerce_datetime(pool.get("completed_at")),
        entries=entries,
        winners=winner_summaries,
        did_tie=did_tie,
    )


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
            0 if member.status in {"active", MEMBERSHIP_STATUS_WINNER} else 1,
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
                "elimination_reason": None,
                "eliminated_week": None,
                "eliminated_date": None,
                "final_rank": None,
                "finished_week": None,
                "finished_date": None,
            },
            "$setOnInsert": {
                "score": 0,
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

    pool = pools_collection.find_one({"_id": pool_oid})
    if not pool:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pool not found",
        )

    season_id = pool.get("seasonId")
    if not isinstance(season_id, ObjectId):
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
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Season not found",
        )

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
                "elimination_reason": None,
                "eliminated_week": None,
                "eliminated_date": None,
                "final_rank": None,
                "finished_week": None,
                "finished_date": None,
            }
        }
    else:
        update_doc = {
            "$set": {
                "status": "declined",
                "joinedAt": None,
                "invitedAt": membership.get("invitedAt") or now,
                "elimination_reason": None,
                "score": 0,
                "available_contestants": [],
                "final_rank": None,
                "finished_week": None,
                "finished_date": None,
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

    if action == "accept":
        current_week = pool.get("current_week", 1)
        if not isinstance(current_week, int):
            current_week = 1
        _recalculate_pool_scores(pool_oid, season, current_week)
        _maybe_mark_pool_competitive(pool_oid, pool)

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
