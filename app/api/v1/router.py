from fastapi import APIRouter

from app.api.v1.endpoints.geo import router as geo_router

api_v1_router = APIRouter()
api_v1_router.include_router(geo_router, prefix="/geos", tags=["geos"])
