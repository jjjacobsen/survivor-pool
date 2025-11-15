from bson import ObjectId
from fastapi import HTTPException, status


def parse_object_id(value, field_name):
    if not ObjectId.is_valid(value):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid {field_name}",
        )
    return ObjectId(value)
