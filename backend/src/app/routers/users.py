from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from fastapi.responses import HTMLResponse

from ..core.auth import get_current_active_user
from ..schemas.pools import PendingInvitesResponse, PoolResponse
from ..schemas.users import (
    PasswordResetConfirm,
    PasswordResetRequest,
    PasswordUpdateRequest,
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


@router.post("/users/forgot_password", status_code=status.HTTP_204_NO_CONTENT)
def forgot_password(payload: PasswordResetRequest):
    users_service.request_password_reset(payload)


@router.post("/users/reset_password", status_code=status.HTTP_204_NO_CONTENT)
def reset_password(payload: PasswordResetConfirm):
    users_service.complete_password_reset(payload)


@router.patch("/users/{user_id}/password", status_code=status.HTTP_204_NO_CONTENT)
def update_password(
    user_id,
    payload: PasswordUpdateRequest,
    current_user=CurrentUser,
):
    _ensure_same_user(user_id, current_user)
    users_service.update_password(user_id, payload)


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
    return """
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <title>Survivor Pool</title>
      </head>
      <body style="margin:0;background:#0f172a;font-family:Arial,sans-serif;">
        <div
          style="
            min-height:100vh;
            display:flex;
            align-items:center;
            justify-content:center;
            padding:32px;
          "
        >
          <div
            style="
              background:#ffffff;
              border-radius:16px;
              padding:32px;
              max-width:420px;
              width:100%;
              box-shadow:0 12px 30px rgba(15,23,42,0.2);
              color:#0f172a;
            "
          >
            <div
              style="
                display:flex;
                align-items:center;
                gap:12px;
                margin-bottom:12px;
              "
            >
              <div
                style="
                  height:36px;
                  width:36px;
                  border-radius:12px;
                  background:#0ea5e9;
                  display:flex;
                  align-items:center;
                  justify-content:center;
                  color:#ffffff;
                  font-weight:700;
                "
              >
                ✓
              </div>
              <div style="font-size:22px;font-weight:700;">Email verified</div>
            </div>
            <p style="margin:0 0 12px 0;line-height:1.6;color:#334155;">
              Your email is confirmed. You can return to Survivor Pool and sign in.
            </p>
            <p style="margin:0;line-height:1.5;color:#64748b;">
              You can close this window.
            </p>
          </div>
        </div>
      </body>
    </html>
    """


def _ensure_same_user(user_id, current_user):
    if user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot act on another user",
        )
