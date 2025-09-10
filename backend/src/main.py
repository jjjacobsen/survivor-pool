import os
from datetime import datetime

import bcrypt
from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr
from pymongo import MongoClient

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1):\d+",
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

# MongoDB connection
MONGO_URL = os.getenv("MONGO_URL", "mongodb://localhost:27017")
client = MongoClient(MONGO_URL)
db = client.survivor_pool
users_collection = db.users


class UserCreateRequest(BaseModel):
    username: str
    email: EmailStr
    password: str
    display_name: str


class UserResponse(BaseModel):
    id: str
    username: str
    email: str
    display_name: str
    account_status: str
    created_at: datetime
    default_pool: str | None = None


class UserLoginRequest(BaseModel):
    email: EmailStr
    password: str


@app.get("/")
def read_root():
    return {"message": "Hello, FastAPI + uv + MongoDB!"}


@app.get("/health")
def health_check():
    try:
        # Test database connection
        client.admin.command("ping")
        return {"status": "healthy", "database": "connected"}
    except Exception as e:
        return {"status": "unhealthy", "database": "disconnected", "error": str(e)}


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(password.encode("utf-8"), hashed_password.encode("utf-8"))


@app.post("/users", response_model=UserResponse)
def create_user(user_data: UserCreateRequest):
    # Check if username already exists
    if users_collection.find_one({"username": user_data.username}):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Username already exists"
        )

    # Check if email already exists
    if users_collection.find_one({"email": user_data.email}):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Email already exists"
        )

    # Hash password
    hashed_password = hash_password(user_data.password)

    # Create user document
    user_doc = {
        "username": user_data.username,
        "email": user_data.email,
        "password_hash": hashed_password,
        "display_name": user_data.display_name,
        "account_status": "active",
        "created_at": datetime.now(),
        "default_pool": None,
    }

    # Insert user into database
    result = users_collection.insert_one(user_doc)
    if not result.inserted_id:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create user",
        )

    # Return user response without password
    return UserResponse(
        id=str(result.inserted_id),
        username=user_data.username,
        email=user_data.email,
        display_name=user_data.display_name,
        account_status="active",
        created_at=user_doc["created_at"],
        default_pool=None,
    )


@app.post("/users/login", response_model=UserResponse)
def login_user(user_data: UserLoginRequest):
    user = users_collection.find_one({"email": user_data.email})
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
        )

    if not verify_password(user_data.password, user["password_hash"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
        )

    if user["account_status"] != "active":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is not active",
        )

    return UserResponse(
        id=str(user["_id"]),
        username=user["username"],
        email=user["email"],
        display_name=user["display_name"],
        account_status=user["account_status"],
        created_at=user["created_at"],
        default_pool=(
            str(user.get("default_pool")) if user.get("default_pool") else None
        ),
    )
