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
