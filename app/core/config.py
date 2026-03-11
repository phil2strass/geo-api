from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "geo-api"
    app_env: str = "dev"
    database_url: str = "postgresql+psycopg://geo:geo@localhost:55432/geo2"
    glottolog_database_url: str = "postgresql+psycopg://geo:geo@localhost:55432/glottolog"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


settings = Settings()
