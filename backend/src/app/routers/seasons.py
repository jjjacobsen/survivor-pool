from fastapi import APIRouter

from ..schemas.seasons import SeasonResponse
from ..services import seasons as seasons_service

router = APIRouter(tags=["seasons"])


@router.get("/seasons", response_model=list[SeasonResponse])
def list_seasons() -> list[SeasonResponse]:
    return seasons_service.list_seasons()
