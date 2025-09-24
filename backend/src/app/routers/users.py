from fastapi import APIRouter

from ..schemas.pools import PoolResponse
from ..schemas.users import (
    UserCreateRequest,
    UserDefaultPoolUpdate,
    UserLoginRequest,
    UserResponse,
)
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
