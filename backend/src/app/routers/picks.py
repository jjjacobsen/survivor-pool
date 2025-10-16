from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status

from ..core.auth import AuthenticatedUser, get_current_active_user
from ..schemas.picks import PickRequest, PickResponse
from ..services import picks as picks_service

router = APIRouter(tags=["picks"])

CurrentUser = Annotated[AuthenticatedUser, Depends(get_current_active_user)]


@router.post(
    "/pools/{pool_id}/picks",
    response_model=PickResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_pick(
    pool_id: str,
    payload: PickRequest,
    current_user: CurrentUser,
) -> PickResponse:
    if payload.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot lock picks for another user",
        )
    return picks_service.create_pick(pool_id, payload)
