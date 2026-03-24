from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    superset_url: str = "http://superset:8088"
    superset_external_url: str = ""
    log_level: str = "INFO"
    root_path: str = ""

    class Config:
        env_file = ".env"


settings = Settings()
