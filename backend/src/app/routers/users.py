from fastapi import APIRouter, Query

from ..schemas.pools import PendingInvitesResponse, PoolResponse
from ..schemas.users import (
    UserCreateRequest,
    UserDefaultPoolUpdate,
    UserLoginRequest,
    UserResponse,
    UserSearchResult,
)
from ..services import pools as pools_service
from ..services import users as users_service

router = APIRouter(tags=["users"])


@router.post("/users", response_model=UserResponse)
def create_user(user_data: UserCreateRequest) -> UserResponse:
    return users_service.create_user(user_data)


@router.post("/users/login", response_model=UserResponse)
def login_user(user_data: UserLoginRequest) -> UserResponse:
    return users_service.login_user(user_data)


@router.patch("/users/{user_id}/default_pool", response_model=UserResponse)
def update_default_pool(user_id: str, payload: UserDefaultPoolUpdate) -> UserResponse:
    return users_service.update_default_pool(user_id, payload)


@router.get("/users/{user_id}/pools", response_model=list[PoolResponse])
def list_user_pools(user_id: str) -> list[PoolResponse]:
    return users_service.list_user_pools(user_id)


@router.get("/users/search", response_model=list[UserSearchResult])
def search_users(
    q: str = Query(""), pool_id: str | None = None
) -> list[UserSearchResult]:
    return users_service.search_active_users(q, pool_id)


@router.get(
    "/users/{user_id}/invites",
    response_model=PendingInvitesResponse,
)
def list_user_invites(user_id: str) -> PendingInvitesResponse:
    return pools_service.get_pending_invites_for_user(user_id)
