from fastapi import APIRouter, status

from ..schemas.picks import PickRequest, PickResponse
from ..services import picks as picks_service

router = APIRouter(tags=["picks"])


@router.post(
    "/pools/{pool_id}/picks",
    response_model=PickResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_pick(pool_id: str, payload: PickRequest) -> PickResponse:
    return picks_service.create_pick(pool_id, payload)
