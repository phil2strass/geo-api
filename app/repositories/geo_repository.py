from sqlalchemy import Select, select
from sqlalchemy.orm import Session

from app.models.geo import Geo


class GeoRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def list_geo(self, country_code: str | None = None, limit: int = 100) -> list[Geo]:
        query: Select[tuple[Geo]] = select(Geo).order_by(Geo.id).limit(limit)
        if country_code:
            query = query.where(Geo.country_code == country_code.upper())
        return list(self.db.scalars(query).all())
