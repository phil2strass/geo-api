from datetime import datetime
from decimal import Decimal

from sqlalchemy import Numeric, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class Geo(Base):
    __tablename__ = "geo"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    country_code: Mapped[str] = mapped_column(String(2), nullable=False, index=True)
    postal_code: Mapped[str] = mapped_column(String(20), nullable=False, index=True)
    city: Mapped[str] = mapped_column(String(120), nullable=False)
    latitude: Mapped[Decimal] = mapped_column(Numeric(9, 6), nullable=False)
    longitude: Mapped[Decimal] = mapped_column(Numeric(9, 6), nullable=False)
    created_at: Mapped[datetime] = mapped_column(server_default=func.now(), nullable=False)
