from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, EmailStr


class UserCreateRequest(BaseModel):
    username: str
    email: EmailStr
    password: str
    display_name: str


class UserResponse(BaseModel):
    id: str
    username: str
    email: str
    display_name: str
    account_status: str
    created_at: datetime
    default_pool: str | None = None
    token: str | None = None


class UserLoginRequest(BaseModel):
    identifier: str
    password: str


class UserDefaultPoolUpdate(BaseModel):
    default_pool: str | None = None


class UserSearchResult(BaseModel):
    id: str
    display_name: str
    email: str
    username: str
    membership_status: str | None = None
