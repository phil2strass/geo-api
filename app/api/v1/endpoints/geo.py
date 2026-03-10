from typing import Annotated

from fastapi import APIRouter, Depends, Query

from app.api.deps import get_geo_service
from app.schemas.geo import GeoRead
from app.services.geo_service import GeoService

router = APIRouter()


@router.get("", response_model=list[GeoRead])
def list_geos(
    service: Annotated[GeoService, Depends(get_geo_service)],
    country_code: Annotated[str | None, Query(min_length=2, max_length=2)] = None,
    limit: Annotated[int, Query(ge=1, le=1000)] = 100,
) -> list[GeoRead]:
    return [GeoRead.model_validate(item) for item in service.list_geo(country_code=country_code, limit=limit)]
