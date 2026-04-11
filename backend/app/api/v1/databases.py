from fastapi import APIRouter, Depends
from pydantic import BaseModel

from app.auth.dependencies import get_current_user
from app.auth.models import UserInfo


router = APIRouter(tags=["databases"])


class DatabaseInfo(BaseModel):
    name: str
    is_default: bool


@router.get("/databases", response_model=list[DatabaseInfo])
async def list_databases(
    current_user: UserInfo = Depends(get_current_user),
) -> list[DatabaseInfo]:
    databases = current_user.databases
    return [
        DatabaseInfo(name=db, is_default=(i == 0))
        for i, db in enumerate(databases)
    ]
