from __future__ import annotations

from dataclasses import dataclass
from datetime import UTC, datetime

from bson import ObjectId
from bson.errors import InvalidId
from fastapi import Header, HTTPException, Response, status

from ..db.mongo import users_collection
from ..schemas.users import UserResponse
from .security import TokenData, create_access_token, decode_access_token

AUTH_HEADER_PREFIX = "Bearer "
REFRESH_HEADER_NAME = "x-new-token"


@dataclass
class AuthenticatedUser:
    id: str
    token: str
    token_data: TokenData
    document: dict

    @property
    def response(self) -> UserResponse:
        doc = self.document
        default_pool = doc.get("default_pool")
        default_pool_id = str(default_pool) if default_pool else None
        created_at = doc.get("created_at")
        if isinstance(created_at, datetime):
            created_value = created_at
        else:
            created_value = datetime.now()
        return UserResponse(
            id=str(doc["_id"]),
            username=doc.get("username", ""),
            email=doc.get("email", ""),
            display_name=doc.get("display_name", ""),
            account_status=doc.get("account_status", ""),
            created_at=created_value,
            default_pool=default_pool_id,
        )


def get_current_active_user(
    response: Response, authorization: str = Header(default="")
) -> AuthenticatedUser:
    if not authorization or not authorization.startswith(AUTH_HEADER_PREFIX):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing credentials"
        )

    token = authorization[len(AUTH_HEADER_PREFIX) :].strip()
    token_data = decode_access_token(token)

    try:
        user_oid = ObjectId(token_data.user_id)
    except (InvalidId, TypeError) as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials"
        ) from exc

    user_doc = users_collection.find_one({"_id": user_oid})
    if not user_doc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials"
        )

    if user_doc.get("account_status") != "active":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Account inactive"
        )

    invalidated_at = user_doc.get("token_invalidated_at")
    if isinstance(invalidated_at, datetime):
        if invalidated_at.tzinfo is None:
            invalidated_at = invalidated_at.replace(tzinfo=UTC)
        else:
            invalidated_at = invalidated_at.astimezone(UTC)
        if token_data.issued_at <= invalidated_at:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED, detail="Token expired"
            )

    if token_data.should_refresh(now=datetime.now(UTC)):
        token = create_access_token(token_data.user_id)
        response.headers[REFRESH_HEADER_NAME] = token
        token_data = decode_access_token(token)

    return AuthenticatedUser(
        id=token_data.user_id,
        token=token,
        token_data=token_data,
        document=user_doc,
    )
