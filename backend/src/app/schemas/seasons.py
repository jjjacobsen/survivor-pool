from __future__ import annotations

from pydantic import BaseModel


class SeasonResponse(BaseModel):
    id: str
    season_name: str
    season_number: int | None = None
