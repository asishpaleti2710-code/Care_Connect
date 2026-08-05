import os
import sys

# Ensure backend directory is present in sys.path for absolute imports on Vercel/serverless
backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.database import engine, Base, SessionLocal

# Import all models to ensure database tables are registered
import app.models  # noqa

# Import routers
from app.routers import auth, residents, sos, guardians, incidents, ai
from app.seed import seed_database

# Initialize DB tables
Base.metadata.create_all(bind=engine)

# Ensure database has seed data initialized
try:
    seed_database(force=False)
except Exception as e:
    print(f"Error checking/seeding database: {e}")

app = FastAPI(title=settings.PROJECT_NAME)

@app.on_event("startup")
def startup_event():
    # Skip network socket lookup when running on Vercel or serverless environments
    if "VERCEL" in os.environ or os.getenv("SERVERLESS"):
        return

    try:
        import socket
        def get_local_ip():
            try:
                s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                s.connect(("8.8.8.8", 80))
                ip = s.getsockname()[0]
                s.close()
                return ip
            except Exception:
                return "127.0.0.1"
        local_ip = get_local_ip()
        print("\n" + "=" * 70)
        print(" CareConnect Backend Service Active on Local Network")
        print(f" Host Local IP Address: {local_ip}")
        print(f" Configure Mobile Frontend API to: http://{local_ip}:8000")
        print("=" * 70 + "\n")
    except Exception:
        pass

# Enable CORS for frontend integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
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
        "message": "CareConnect Portfolio Emergency API is running",
        "version": "2.0.0",
        "docs": "/docs"
    }

@app.get("/health")
def health_check():
    return {"status": "healthy", "database": "sqlite"}
