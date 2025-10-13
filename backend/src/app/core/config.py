from os import environ
from pathlib import Path

from dotenv import dotenv_values

_BACKEND_DIR = Path(__file__).resolve().parents[3]
_ENV_DIR = _BACKEND_DIR / "env"
_APP_ENV = environ.get("APP_ENV", "dev")
_ENV_FILE = _ENV_DIR / (".env.prod" if _APP_ENV == "prod" else ".env.dev")
_VALUES_FROM_FILE = dotenv_values(_ENV_FILE) if _ENV_FILE.exists() else {}
_ENV = {**_VALUES_FROM_FILE, **environ}


def _require(name: str) -> str:
    value = _ENV.get(name)
    if value is None:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


CORS_ALLOW_ORIGIN_REGEX = _require("CORS_ALLOW_ORIGIN_REGEX")
CORS_ALLOW_CREDENTIALS = True
CORS_ALLOW_METHODS = ["*"]
CORS_ALLOW_HEADERS = ["*"]

MONGO_URL = _require("MONGO_URL")
DATABASE_NAME = _require("DATABASE_NAME")
