from fastapi import APIRouter, status

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
    PoolMembershipListResponse,
    PoolResponse,
)
from ..services import pools as pools_service

router = APIRouter(tags=["pools"])


@router.post("/pools", response_model=PoolResponse, status_code=status.HTTP_201_CREATED)
def create_pool(pool_data: PoolCreateRequest) -> PoolResponse:
    return pools_service.create_pool(pool_data)


@router.get(
    "/pools/{pool_id}/available_contestants",
    response_model=AvailableContestantsResponse,
)
def get_available_contestants(
    pool_id: str, user_id: str
) -> AvailableContestantsResponse:
    return pools_service.get_available_contestants(pool_id, user_id)


@router.get(
    "/pools/{pool_id}/contestants/{contestant_id}",
    response_model=ContestantDetailResponse,
)
def get_contestant_detail(
    pool_id: str, contestant_id: str, user_id: str
) -> ContestantDetailResponse:
    return pools_service.get_contestant_detail(pool_id, contestant_id, user_id)


@router.get(
    "/pools/{pool_id}/advance-status",
    response_model=PoolAdvanceStatusResponse,
)
def get_pool_advance_status(pool_id: str, user_id: str) -> PoolAdvanceStatusResponse:
    return pools_service.get_pool_advance_status(pool_id, user_id)


@router.post(
    "/pools/{pool_id}/advance-week",
    response_model=PoolAdvanceResponse,
)
def advance_pool_week(pool_id: str, payload: PoolAdvanceRequest) -> PoolAdvanceResponse:
    return pools_service.advance_pool_week(pool_id, payload)


@router.get(
    "/pools/{pool_id}/memberships",
    response_model=PoolMembershipListResponse,
)
def list_pool_memberships(pool_id: str, owner_id: str) -> PoolMembershipListResponse:
    return pools_service.list_pool_memberships(pool_id, owner_id)


@router.post(
    "/pools/{pool_id}/invites",
    response_model=PoolInviteResponse,
)
def invite_user_to_pool(pool_id: str, payload: PoolInviteRequest) -> PoolInviteResponse:
    return pools_service.invite_user_to_pool(pool_id, payload)


@router.post(
    "/pools/{pool_id}/invites/respond",
    response_model=PoolInviteDecisionResponse,
)
def respond_to_invite(
    pool_id: str, payload: PoolInviteDecisionRequest
) -> PoolInviteDecisionResponse:
    return pools_service.respond_to_invite(pool_id, payload)


@router.delete("/pools/{pool_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_pool(pool_id: str, owner_id: str) -> None:
    pools_service.delete_pool(pool_id, owner_id)
