from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    superset_url: str = "http://superset:8088"
    superset_external_url: str = ""
    log_level: str = "INFO"
    root_path: str = ""

    jwt_secret: str = ""
    jwt_algorithm: str = "HS256"

    postgrest_url: str = "http://postgrest:3000"

    postgrest_external_url: str = "http://localhost:3000"

    api_docs_external_url: str = "http://localhost:3001"

    backend_url: str = "http://backend:8000"

    password_min_length: int = 12

    model_config = SettingsConfigDict(env_file=".env")


settings = Settings()
