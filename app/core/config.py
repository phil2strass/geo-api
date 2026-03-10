from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "geo-api"
    app_env: str = "dev"
    database_url: str = "postgresql+psycopg://geo_user:geo_pass@localhost:5432/geo"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


settings = Settings()
