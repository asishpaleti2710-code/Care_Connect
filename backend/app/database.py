import re
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from app.config import settings

def normalize_database_url(url: str) -> str:
    """
    Normalizes cloud-provided database URLs to include the appropriate SQLAlchemy driver.
    """
    if not url:
        return "sqlite:///./careconnect.db"
    
    # Normalize MySQL URL
    if url.startswith("mysql://"):
        return url.replace("mysql://", "mysql+pymysql://", 1)
    
    # Normalize PostgreSQL URL (Render / Heroku / Supabase style)
    if url.startswith("postgres://"):
        return url.replace("postgres://", "postgresql+psycopg2://", 1)
    elif url.startswith("postgresql://") and not url.startswith("postgresql+"):
        return url.replace("postgresql://", "postgresql+psycopg2://", 1)
        
    return url

raw_db_url = settings.DATABASE_URL
db_url = normalize_database_url(raw_db_url)

def create_resilient_engine(url: str):
    if url.startswith("sqlite"):
        return create_engine(
            url,
            connect_args={"check_same_thread": False}
        )
    
    # Configure cloud MySQL / PostgreSQL with fast connection timeout
    connect_args = {"connect_timeout": 5}
    try:
        cloud_engine = create_engine(
            url,
            pool_size=10,
            max_overflow=20,
            pool_pre_ping=True,
            pool_recycle=3600,
            pool_timeout=10,
            connect_args=connect_args
        )
        from sqlalchemy import text
        with cloud_engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        safe_info = url.split("@")[-1] if "@" in url else "cloud database"
        print(f"[Database] Successfully connected to cloud database: {safe_info}")
        return cloud_engine
    except Exception as err:
        print(f"[Database Resilience] Could not reach cloud database ({err}). Falling back to local SQLite.")
        return create_engine(
            "sqlite:///./careconnect.db",
            connect_args={"check_same_thread": False}
        )

engine = create_resilient_engine(db_url)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
