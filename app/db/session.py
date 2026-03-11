from collections.abc import Generator

from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import settings

engine = create_engine(settings.database_url, pool_pre_ping=True)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)
glottolog_engine = create_engine(settings.glottolog_database_url, pool_pre_ping=True)
GlottologSessionLocal = sessionmaker(bind=glottolog_engine, autoflush=False, autocommit=False)


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_glottolog_db() -> Generator[Session, None, None]:
    db = GlottologSessionLocal()
    try:
        yield db
    finally:
        db.close()
