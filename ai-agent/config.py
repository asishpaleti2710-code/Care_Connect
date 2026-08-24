import os
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
    def __init__(self) -> None:
        self.ENVIRONMENT = os.getenv("ENVIRONMENT", "development").lower()
        self.SECRET_KEY = os.getenv("SECRET_KEY")
        self.REQUIRE_AUTH = _parse_bool(os.getenv("AI_AGENT_REQUIRE_AUTH"), default=True)
        self.CORS_ORIGINS = _parse_list(
            os.getenv("CORS_ORIGINS"),
            ["http://localhost:5173", "http://127.0.0.1:5173"],
        )

        if self.REQUIRE_AUTH and not self.SECRET_KEY:
            raise RuntimeError(
                "SECRET_KEY must be set (same value as the backend API) so the AI agent "
                "can validate access tokens. Set AI_AGENT_REQUIRE_AUTH=false only for "
                "local experiments."
            )
        if not self.REQUIRE_AUTH:
            warnings.warn(
                "AI agent authentication is disabled; endpoints are publicly callable.",
                stacklevel=2,
            )


settings = Settings()
