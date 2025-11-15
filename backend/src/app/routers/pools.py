from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status

from ..core.auth import AuthenticatedUser, get_current_active_user
from ..schemas.pools import (
    AvailableContestantsResponse,
    ContestantDetailResponse,
    PoolAdvanceRequest,
    PoolAdvanceResponse,
    PoolAdvanceStatusResponse,
    PoolCreateRequest,
    PoolInviteDecisionRequest,
    PoolInviteDecisionResponse,
    PoolInviteRequest,
    PoolInviteResponse,
    PoolLeaderboardResponse,
    PoolMembershipListResponse,
    PoolResponse,
)
from ..services import pools as pools_service

router = APIRouter(tags=["pools"])
CurrentUser = Annotated[AuthenticatedUser, Depends(get_current_active_user)]


@router.post("/pools", response_model=PoolResponse, status_code=status.HTTP_201_CREATED)
def create_pool(
    pool_data: PoolCreateRequest,
    current_user: CurrentUser,
):
    _ensure_same_user(pool_data.owner_id, current_user)
    return pools_service.create_pool(pool_data)


@router.get(
    "/pools/{pool_id}/available_contestants",
    response_model=AvailableContestantsResponse,
)
def get_available_contestants(
    pool_id,
    user_id,
    current_user: CurrentUser,
):
    _ensure_same_user(user_id, current_user)
    return pools_service.get_available_contestants(pool_id, user_id)


@router.get(
    "/pools/{pool_id}/contestants/{contestant_id}",
    response_model=ContestantDetailResponse,
)
def get_contestant_detail(
    pool_id,
    contestant_id,
    user_id,
    current_user: CurrentUser,
):
    _ensure_same_user(user_id, current_user)
    return pools_service.get_contestant_detail(pool_id, contestant_id, user_id)


@router.get(
    "/pools/{pool_id}/advance-status",
    response_model=PoolAdvanceStatusResponse,
)
def get_pool_advance_status(
    pool_id,
    user_id,
    current_user: CurrentUser,
):
    _ensure_same_user(user_id, current_user)
    return pools_service.get_pool_advance_status(pool_id, user_id)


@router.get(
    "/pools/{pool_id}/leaderboard",
    response_model=PoolLeaderboardResponse,
)
def get_pool_leaderboard(
    pool_id,
    user_id,
    current_user: CurrentUser,
):
    _ensure_same_user(user_id, current_user)
    return pools_service.get_pool_leaderboard(pool_id, user_id)


@router.post(
    "/pools/{pool_id}/advance-week",
    response_model=PoolAdvanceResponse,
)
def advance_pool_week(
    pool_id,
    payload: PoolAdvanceRequest,
    current_user: CurrentUser,
):
    _ensure_same_user(payload.user_id, current_user)
    return pools_service.advance_pool_week(pool_id, payload)


@router.get(
    "/pools/{pool_id}/memberships",
    response_model=PoolMembershipListResponse,
)
def list_pool_memberships(
    pool_id,
    owner_id,
    current_user: CurrentUser,
):
    _ensure_same_user(owner_id, current_user)
    return pools_service.list_pool_memberships(pool_id, owner_id)


@router.post(
    "/pools/{pool_id}/invites",
    response_model=PoolInviteResponse,
)
def invite_user_to_pool(
    pool_id,
    payload: PoolInviteRequest,
    current_user: CurrentUser,
):
    _ensure_same_user(payload.owner_id, current_user)
    return pools_service.invite_user_to_pool(pool_id, payload)


@router.post(
    "/pools/{pool_id}/invites/respond",
    response_model=PoolInviteDecisionResponse,
)
def respond_to_invite(
    pool_id,
    payload: PoolInviteDecisionRequest,
    current_user: CurrentUser,
):
    _ensure_same_user(payload.user_id, current_user)
    return pools_service.respond_to_invite(pool_id, payload)


@router.delete("/pools/{pool_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_pool(
    pool_id,
    owner_id,
    current_user: CurrentUser,
):
    _ensure_same_user(owner_id, current_user)
    pools_service.delete_pool(pool_id, owner_id)


def _ensure_same_user(user_id, current_user):
    if user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot act on another user",
        )
