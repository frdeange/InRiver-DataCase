from fastapi import APIRouter, Depends

from app.auth.dependencies import get_current_user
from app.auth.domain_resolver import DomainResolver
from app.auth.models import UserInfo

router = APIRouter(tags=["databases"])
domain_resolver = DomainResolver()


@router.get("/databases")
async def list_databases(
    current_user: UserInfo = Depends(get_current_user),
) -> dict[str, list[str]]:
    databases = domain_resolver.resolve(current_user.domain)
    return {"databases": databases}
