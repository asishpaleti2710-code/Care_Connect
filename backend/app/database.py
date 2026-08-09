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

# Engine configuration based on database dialect
if db_url.startswith("sqlite"):
    engine = create_engine(
        db_url,
        connect_args={"check_same_thread": False}
    )
else:
    # Cloud MySQL / PostgreSQL connection pooling
    engine = create_engine(
        db_url,
        pool_size=10,
        max_overflow=20,
        pool_pre_ping=True,
        pool_recycle=3600,
        pool_timeout=30
    )

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
