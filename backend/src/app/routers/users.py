from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status

from ..core.auth import AuthenticatedUser, get_current_active_user
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

CurrentUser = Annotated[AuthenticatedUser, Depends(get_current_active_user)]


@router.post("/users", response_model=UserResponse)
def create_user(user_data: UserCreateRequest) -> UserResponse:
    return users_service.create_user(user_data)


@router.post("/users/login", response_model=UserResponse)
def login_user(user_data: UserLoginRequest) -> UserResponse:
    return users_service.login_user(user_data)


@router.patch("/users/{user_id}/default_pool", response_model=UserResponse)
def update_default_pool(
    user_id: str,
    payload: UserDefaultPoolUpdate,
    current_user: CurrentUser,
) -> UserResponse:
    _ensure_same_user(user_id, current_user)
    return users_service.update_default_pool(user_id, payload)


@router.get("/users/{user_id}/pools", response_model=list[PoolResponse])
def list_user_pools(
    user_id: str,
    current_user: CurrentUser,
) -> list[PoolResponse]:
    _ensure_same_user(user_id, current_user)
    return users_service.list_user_pools(user_id)


@router.get("/users/search", response_model=list[UserSearchResult])
def search_users(
    current_user: CurrentUser,
    q: str = Query(""),
    pool_id: str | None = None,
    limit: int = Query(10, ge=1, le=25),
) -> list[UserSearchResult]:
    return users_service.search_active_users(q, pool_id, limit)


@router.get(
    "/users/{user_id}/invites",
    response_model=PendingInvitesResponse,
)
def list_user_invites(
    user_id: str,
    current_user: CurrentUser,
) -> PendingInvitesResponse:
    _ensure_same_user(user_id, current_user)
    return pools_service.get_pending_invites_for_user(user_id)


@router.delete("/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user(
    user_id: str,
    current_user: CurrentUser,
) -> None:
    _ensure_same_user(user_id, current_user)
    users_service.delete_user(user_id)


@router.get("/users/me", response_model=UserResponse)
def get_current_user_profile(
    current_user: CurrentUser,
) -> UserResponse:
    return users_service.get_user_profile(current_user.id)


def _ensure_same_user(user_id: str, current_user: AuthenticatedUser) -> None:
    if user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot act on another user",
        )
