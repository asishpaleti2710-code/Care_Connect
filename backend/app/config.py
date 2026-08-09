import os
from typing import List
from dotenv import load_dotenv

load_dotenv()

def resolve_database_url() -> str:
    """
    Automatically resolves the database URL from Railway MySQL environment variables,
    standard DATABASE_URL, or falls back to local SQLite.
    """
    # 1. Railway single-string URL formats
    url = os.getenv("MYSQL_URL") or os.getenv("MYSQL_PUBLIC_URL") or os.getenv("DATABASE_URL")
    if url and url.strip():
        return url.strip()

    # 2. Railway individual MySQL connection variables
    host = os.getenv("MYSQLHOST") or os.getenv("RAILWAY_TCP_PROXY_DOMAIN")
    port = os.getenv("MYSQLPORT") or os.getenv("RAILWAY_TCP_PROXY_PORT") or "3306"
    user = os.getenv("MYSQLUSER")
    password = os.getenv("MYSQLPASSWORD")
    database = os.getenv("MYSQLDATABASE") or "railway"

    if host and user and password:
        return f"mysql+pymysql://{user}:{password}@{host}:{port}/{database}"

    # 3. Default fallback
    return "sqlite:///./careconnect.db"

class Settings:
    PROJECT_NAME: str = os.getenv("PROJECT_NAME", "CareConnect API")
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development").lower()
    DATABASE_URL: str = resolve_database_url()
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
