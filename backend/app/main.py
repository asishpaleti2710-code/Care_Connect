from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.database import engine, Base

# Import all models to ensure database tables are registered
import app.models  # noqa

# Import routers
from app.routers import auth, residents, sos, guardians, incidents

# Initialize DB tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.PROJECT_NAME,
    docs_url="/docs" if settings.ENABLE_DOCS else None,
    redoc_url="/redoc" if settings.ENABLE_DOCS else None,
    openapi_url="/openapi.json" if settings.ENABLE_DOCS else None,
)

@app.on_event("startup")
def startup_event():
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

# Enable CORS for frontend integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)

# Include Routers
app.include_router(auth.router)
app.include_router(residents.router)
app.include_router(sos.router)
app.include_router(guardians.router)
app.include_router(incidents.router)

@app.get("/")
def home():
    return {
        "message": "CareConnect Portfolio Emergency API is running",
        "version": "2.0.0",
        "docs": "/docs" if settings.ENABLE_DOCS else None
    }

@app.get("/health")
def health_check():
    return {"status": "healthy", "database": "sqlite"}
