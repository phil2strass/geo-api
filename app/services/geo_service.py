from app.models.geo import Geo
from app.repositories.geo_repository import GeoRepository


class GeoService:
    def __init__(self, repository: GeoRepository) -> None:
        self.repository = repository

    def list_geo(self, country_code: str | None = None, limit: int = 100) -> list[Geo]:
        return self.repository.list_geo(country_code=country_code, limit=limit)
