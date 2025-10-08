import bcrypt

DUMMY_PASSWORD_HASH = bcrypt.hashpw(b"placeholder-secret", bcrypt.gensalt()).decode(
    "utf-8"
)


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(password.encode("utf-8"), hashed_password.encode("utf-8"))
