import os
from dotenv import load_dotenv

load_dotenv()

class Settings:
    PROJECT_NAME: str = os.getenv("PROJECT_NAME", "CareConnect API")
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./careconnect.db")
    SECRET_KEY: str = os.getenv("SECRET_KEY", "careconnect_secret")

settings = Settings()
