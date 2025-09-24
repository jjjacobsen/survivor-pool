from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel


class PickRequest(BaseModel):
    user_id: str
    contestant_id: str


class PickResponse(BaseModel):
    pick_id: str
    pool_id: str
    user_id: str
    contestant_id: str
    week: int
    locked_at: datetime
