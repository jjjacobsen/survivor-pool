from fastapi import APIRouter

from ..db.mongo import ping_database

router = APIRouter(tags=["system"])


@router.get("/")
def read_root():
    return {"message": "Hello, FastAPI + uv + MongoDB!"}


@router.get("/health")
def health_check():
    try:
        ping_database()
        return {"status": "healthy", "database": "connected"}
    except Exception as exc:
        return {
            "status": "unhealthy",
            "database": "disconnected",
            "error": str(exc),
        }
