import os
import shutil
import tempfile
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from app.config import settings

def get_database_url():
    db_url = settings.DATABASE_URL
    # Check if running in Vercel or read-only serverless environment
    if "VERCEL" in os.environ or os.getenv("SERVERLESS") or os.access(".", os.W_OK) is False:
        tmp_dir = "/tmp" if os.path.exists("/tmp") else tempfile.gettempdir()
        try:
            os.makedirs(tmp_dir, exist_ok=True)
        except Exception:
            pass
        tmp_db = os.path.join(tmp_dir, "careconnect.db")
        if not os.path.exists(tmp_db):
            # Look for existing pre-populated db to copy to /tmp
            possible_sources = [
                os.path.join(os.path.dirname(__file__), "..", "careconnect.db"),
                os.path.join(os.path.dirname(__file__), "..", "..", "careconnect.db"),
                "careconnect.db"
            ]
            for src in possible_sources:
                if os.path.exists(src):
                    try:
                        shutil.copyfile(src, tmp_db)
                        break
                    except Exception:
                        pass
        # SQLite connection URL requires forward slashes
        normalized_tmp_db = tmp_db.replace("\\", "/")
        return f"sqlite:///{normalized_tmp_db}"
    return db_url

db_url = get_database_url()
connect_args = {"check_same_thread": False} if db_url.startswith("sqlite") else {}

engine = create_engine(
    db_url,
    connect_args=connect_args
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
