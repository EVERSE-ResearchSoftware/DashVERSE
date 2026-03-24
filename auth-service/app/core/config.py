from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field


class Settings(BaseSettings):
    """
    Application settings loaded from environment variables.

    Environment variables are injected by Kubernetes from secrets and configmaps.
    See terraform/modules/auth-service/main.tf for the full configuration.
    """

    DATABASE_URL: str = Field(
        description="PostgreSQL database connection URL"
    )

    JWT_SECRET: str = Field(
        description="Secret key for JWT token signing (min 32 bytes)"
    )

    JWT_ALGORITHM: str = Field(
        default="HS256",
        description="Algorithm for JWT token signing"
    )

    JWT_EXPIRATION_DAYS: int = Field(
        default=30,
        description="JWT token expiration time in days"
    )

    PASSWORD_MIN_LENGTH: int = Field(
        default=12,
        description="Minimum password length for user registration"
    )

    MAX_LOGIN_ATTEMPTS: int = Field(
        default=5,
        description="Maximum failed login attempts before account lockout"
    )

    LOCKOUT_DURATION_MINUTES: int = Field(
        default=15,
        description="Account lockout duration in minutes after max failed attempts"
    )

    LOG_LEVEL: str = Field(
        default="INFO",
        description="Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL)"
    )

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore"
    )


settings = Settings()
