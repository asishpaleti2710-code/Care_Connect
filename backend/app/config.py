import os
from typing import List
from dotenv import load_dotenv

load_dotenv()

class Settings:
    PROJECT_NAME: str = os.getenv("PROJECT_NAME", "CareConnect API")
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development").lower()
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./careconnect.db")
    SECRET_KEY: str = os.getenv("SECRET_KEY", "careconnect_secret_key_production_secure_32bytes_minimum")
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", "8000"))

    @property
    def cors_origins(self) -> List[str]:
        raw_origins = os.getenv("CORS_ORIGINS", "*")
        if raw_origins.strip() == "*":
            return ["*"]
        return [origin.strip() for origin in raw_origins.split(",") if origin.strip()]

settings = Settings()
