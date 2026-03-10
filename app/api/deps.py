from fastapi import Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.repositories.geo_repository import GeoRepository
from app.services.geo_service import GeoService


def get_geo_service(db: Session = Depends(get_db)) -> GeoService:
    return GeoService(GeoRepository(db))
