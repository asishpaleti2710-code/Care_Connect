import os
import sys
import time
from sqlalchemy import text

# Ensure backend directory is present in sys.path for absolute imports
backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

from fastapi import FastAPI, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from app.config import settings
from app.database import engine, Base, get_db

# Import all models to ensure database tables are registered
import app.models  # noqa

# Import routers
from app.routers import auth, residents, sos, guardians, incidents, ai
from app.seed import seed_database

# Initialize DB tables
try:
    Base.metadata.create_all(bind=engine)
except Exception as e:
    print(f"[Database Warning] Table creation encountered: {e}")

# Ensure database has seed data initialized
try:
    seed_database(force=False)
except Exception as e:
    print(f"[Seed Warning] Database seeding skipped: {e}")

app = FastAPI(
    title=settings.PROJECT_NAME,
    description="CareConnect Cloud API - Community Safety, SOS Emergency Dispatch & AI Triage",
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Start time tracking for uptime
SERVER_START_TIME = time.time()

@app.on_event("startup")
def startup_event():
    print("=" * 60)
    print(f"🚀 CareConnect API Server Initialized")
    print(f"🌍 Environment : {settings.ENVIRONMENT.upper()}")
    print(f"🛢️ Database Dialect : {engine.dialect.name.upper()}")
    print(f"🛡️ CORS Allowed Origins : {settings.cors_origins}")
    print("=" * 60)

# Configure Production CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(auth.router)
app.include_router(residents.router)
app.include_router(sos.router)
app.include_router(guardians.router)
app.include_router(incidents.router)
app.include_router(ai.router)

@app.get("/")
def home():
    return {
        "service": settings.PROJECT_NAME,
        "status": "online",
        "environment": settings.ENVIRONMENT,
        "version": "2.0.0",
        "docs": "/docs",
        "health": "/health"
    }

@app.get("/health")
@app.get("/api/health")
def health_check(db: Session = Depends(get_db)):
    db_status = "healthy"
    try:
        db.execute(text("SELECT 1"))
    except Exception as e:
        db_status = f"unhealthy: {str(e)}"

    uptime_seconds = int(time.time() - SERVER_START_TIME)

    return {
        "status": "healthy" if db_status == "healthy" else "degraded",
        "database": {
            "status": db_status,
            "engine": engine.dialect.name
        },
        "uptime_seconds": uptime_seconds,
        "environment": settings.ENVIRONMENT,
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host=settings.HOST, port=settings.PORT, reload=(settings.ENVIRONMENT == "development"))
