from __future__ import annotations

from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from typing import Any

import bcrypt
import jwt
from fastapi import HTTPException, status

from .config import (
    JWT_ALGORITHM,
    JWT_SECRET_KEY,
    TOKEN_REFRESH_INTERVAL_DAYS,
    TOKEN_TTL_DAYS,
)

DUMMY_PASSWORD_HASH = bcrypt.hashpw(b"placeholder-secret", bcrypt.gensalt()).decode(
    "utf-8"
)


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(password.encode("utf-8"), hashed_password.encode("utf-8"))


@dataclass
class TokenData:
    user_id: str
    issued_at: datetime
    expires_at: datetime

    def should_refresh(self, *, now: datetime | None = None) -> bool:
        moment = now or datetime.now(UTC)
        refresh_delta = timedelta(days=TOKEN_REFRESH_INTERVAL_DAYS)
        return (moment - self.issued_at) >= refresh_delta


_TOKEN_LIFETIME = timedelta(days=TOKEN_TTL_DAYS)


def create_access_token(user_id: str, *, issued_at: datetime | None = None) -> str:
    now = issued_at or datetime.now(UTC)
    payload = {
        "sub": user_id,
        "iat": int(now.timestamp()),
        "exp": int((now + _TOKEN_LIFETIME).timestamp()),
    }
    return jwt.encode(payload, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)


def decode_access_token(token: str) -> TokenData:
    try:
        payload = jwt.decode(
            token,
            JWT_SECRET_KEY,
            algorithms=[JWT_ALGORITHM],
            options={"require": ["sub", "iat", "exp"]},
        )
    except jwt.ExpiredSignatureError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Token expired"
        ) from exc
    except jwt.InvalidTokenError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token"
        ) from exc

    user_id = payload.get("sub")
    issued_at_value = payload.get("iat")
    expires_at_value = payload.get("exp")

    if not isinstance(user_id, str) or not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token subject"
        )

    issued_at = _coerce_epoch(issued_at_value, "iat")
    expires_at = _coerce_epoch(expires_at_value, "exp")

    return TokenData(user_id=user_id, issued_at=issued_at, expires_at=expires_at)


def _coerce_epoch(value: Any, claim: str) -> datetime:
    if isinstance(value, (int, float)):  # noqa: UP038
        return datetime.fromtimestamp(int(value), tz=UTC)
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail=f"Invalid token claim: {claim}",
    )
