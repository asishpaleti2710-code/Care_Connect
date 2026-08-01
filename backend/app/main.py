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

app = FastAPI(title=settings.PROJECT_NAME)

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
