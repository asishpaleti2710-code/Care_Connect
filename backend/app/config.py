import os
import secrets
import warnings

from dotenv import load_dotenv

load_dotenv()


def _parse_bool(value: str | None, default: bool = False) -> bool:
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


def _parse_list(value: str | None, default: list[str]) -> list[str]:
    if not value:
        return default
    return [item.strip() for item in value.split(",") if item.strip()]


class Settings:
    PROJECT_NAME: str = os.getenv("PROJECT_NAME", "CareConnect API")
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./careconnect.db")
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development").lower()

    def __init__(self) -> None:
        self.SECRET_KEY = self._resolve_secret_key()
        self.CORS_ORIGINS = _parse_list(
            os.getenv("CORS_ORIGINS"),
            ["http://localhost:5173", "http://127.0.0.1:5173"],
        )
        self.ENABLE_DOCS = _parse_bool(
            os.getenv("ENABLE_DOCS"), default=not self.is_production
        )

    @property
    def is_production(self) -> bool:
        return self.ENVIRONMENT in {"production", "prod"}

    MIN_SECRET_KEY_LENGTH = 32

    def _resolve_secret_key(self) -> str:
        key = os.getenv("SECRET_KEY")
        if key:
            if len(key) < self.MIN_SECRET_KEY_LENGTH:
                raise RuntimeError(
                    "SECRET_KEY must be at least "
                    f"{self.MIN_SECRET_KEY_LENGTH} characters long"
                )
            return key
        if self.is_production:
            raise RuntimeError(
                "SECRET_KEY environment variable must be set when ENVIRONMENT=production"
            )
        warnings.warn(
            "SECRET_KEY is not set; generating an ephemeral development key. "
            "Issued tokens will be invalidated on restart.",
            stacklevel=2,
        )
        return secrets.token_urlsafe(48)


settings = Settings()
