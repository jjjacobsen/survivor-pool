from os import environ


def _require(name: str) -> str:
    value = environ.get(name)
    if value is None:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


CORS_ALLOW_ORIGIN_REGEX = _require("CORS_ALLOW_ORIGIN_REGEX")
CORS_ALLOW_CREDENTIALS = True
CORS_ALLOW_METHODS = ["*"]
CORS_ALLOW_HEADERS = ["*"]

MONGO_URL = _require("MONGO_URL")
DATABASE_NAME = _require("DATABASE_NAME")

JWT_SECRET_KEY = _require("JWT_SECRET_KEY")
JWT_ALGORITHM = "HS256"


def _int_from_env(name: str, default: int) -> int:
    raw = environ.get(name)
    if raw is None:
        return default
    try:
        return int(raw)
    except ValueError as exc:
        raise RuntimeError(f"Invalid integer value for {name}") from exc


TOKEN_TTL_DAYS = _int_from_env("JWT_TOKEN_TTL_DAYS", 30)
TOKEN_REFRESH_INTERVAL_DAYS = _int_from_env("JWT_REFRESH_INTERVAL_DAYS", 3)
