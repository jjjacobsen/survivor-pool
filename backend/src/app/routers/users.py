from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from fastapi.responses import HTMLResponse

from ..core.auth import get_current_active_user
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
CurrentUser = Depends(get_current_active_user)
SearchQuery = Query("")
PoolIdQuery = Query(None)
LimitQuery = Query(10, ge=1, le=25)


@router.post("/users", response_model=UserResponse)
def create_user(user_data: UserCreateRequest, request: Request):
    return users_service.create_user(user_data, request)


@router.post("/users/login", response_model=UserResponse)
def login_user(user_data: UserLoginRequest):
    return users_service.login_user(user_data)


@router.patch("/users/{user_id}/default_pool", response_model=UserResponse)
def update_default_pool(
    user_id,
    payload: UserDefaultPoolUpdate,
    current_user=CurrentUser,
):
    _ensure_same_user(user_id, current_user)
    return users_service.update_default_pool(user_id, payload)


@router.get("/users/{user_id}/pools", response_model=list[PoolResponse])
def list_user_pools(
    user_id,
    current_user=CurrentUser,
):
    _ensure_same_user(user_id, current_user)
    return users_service.list_user_pools(user_id)


@router.get("/users/search", response_model=list[UserSearchResult])
def search_users(
    current_user=CurrentUser,
    q: str = SearchQuery,
    pool_id: str | None = PoolIdQuery,
    limit: int = LimitQuery,
):
    return users_service.search_active_users(q, pool_id, limit)


@router.get(
    "/users/{user_id}/invites",
    response_model=PendingInvitesResponse,
)
def list_user_invites(
    user_id,
    current_user=CurrentUser,
):
    _ensure_same_user(user_id, current_user)
    return pools_service.get_pending_invites_for_user(user_id)


@router.delete("/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user(
    user_id,
    current_user=CurrentUser,
):
    _ensure_same_user(user_id, current_user)
    users_service.delete_user(user_id)


@router.get("/users/me", response_model=UserResponse)
def get_current_user_profile(
    current_user=CurrentUser,
):
    return users_service.get_user_profile(current_user.id)


@router.get(
    "/users/verify/{token}",
    response_class=HTMLResponse,
    include_in_schema=False,
    name="verify_user_email",
)
def verify_user_email(token: str):
    users_service.verify_user_email(token)
    return "<p>Email verified. You can close this window.</p>"


def _ensure_same_user(user_id, current_user):
    if user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot act on another user",
        )
