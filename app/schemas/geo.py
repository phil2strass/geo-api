from decimal import Decimal

from pydantic import BaseModel, ConfigDict


class GeoRead(BaseModel):
    id: int
    country_code: str
    postal_code: str
    city: str
    latitude: Decimal
    longitude: Decimal

    model_config = ConfigDict(from_attributes=True)
