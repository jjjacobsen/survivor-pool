from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from ..routers import picks, pools, root, seasons, users
from .config import (
    CORS_ALLOW_CREDENTIALS,
    CORS_ALLOW_HEADERS,
    CORS_ALLOW_METHODS,
    CORS_ALLOW_ORIGIN_REGEX,
)


def create_app() -> FastAPI:
    app = FastAPI()

    app.add_middleware(
        CORSMiddleware,
        allow_origin_regex=CORS_ALLOW_ORIGIN_REGEX,
        allow_credentials=CORS_ALLOW_CREDENTIALS,
        allow_methods=CORS_ALLOW_METHODS,
        allow_headers=CORS_ALLOW_HEADERS,
    )

    app.include_router(root.router)
    app.include_router(users.router)
    app.include_router(seasons.router)
    app.include_router(pools.router)
    app.include_router(picks.router)

    return app
