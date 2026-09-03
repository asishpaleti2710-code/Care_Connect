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
from app.routers import auth, residents, sos, guardians, incidents, ai, notifications
from app.seed import seed_database
from app.database_migrations import run_safe_schema_migrations

# Initialize DB tables & run non-destructive migrations
try:
    Base.metadata.create_all(bind=engine)
    run_safe_schema_migrations()
except Exception as e:
    print(f"[Database Warning] Table creation or migration encountered: {e}")

# Ensure database has seed data initialized
try:
    seed_database(force=False)
except Exception as e:
    print(f"[Seed Warning] Database seeding skipped: {e}")

app = FastAPI(
    title=settings.PROJECT_NAME,
    description="CareConnect Cloud API - Community Safety, SOS Emergency Dispatch, Notifications & AI Triage",
    version="2.1.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Start time tracking for uptime
SERVER_START_TIME = time.time()

@app.on_event("startup")
def startup_event():
    print("=" * 60)
    print(f"[STARTUP] CareConnect API Server Initialized")
    print(f"[STARTUP] Environment : {settings.ENVIRONMENT.upper()}")
    print(f"[STARTUP] Database Dialect : {engine.dialect.name.upper()}")
    print(f"[STARTUP] CORS Allowed Origins : {settings.cors_origins}")
    print("=" * 60)

# Configure Production CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Production Rate Limiting and Security Headers Middleware
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse
from fastapi import Request
import collections

RATE_LIMIT_WINDOW = 60  # seconds
MAX_REQUESTS_PER_WINDOW = 200  # general requests
MAX_SENSITIVE_REQUESTS = 50   # auth / sos endpoints
_ip_request_history = collections.defaultdict(list)

class RateLimitingAndSecurityMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        client_ip = request.client.host if request.client else "unknown"
        now = time.time()

        # Check rate limits on non-health and non-websocket routes
        if not request.url.path.startswith("/ws/") and request.url.path not in ["/health", "/api/health", "/docs", "/openapi.json"]:
            cutoff = now - RATE_LIMIT_WINDOW
            timestamps = [t for t in _ip_request_history[client_ip] if t > cutoff]
            _ip_request_history[client_ip] = timestamps

            limit = MAX_SENSITIVE_REQUESTS if ("/auth/" in request.url.path or "/sos" in request.url.path) else MAX_REQUESTS_PER_WINDOW
            if len(timestamps) >= limit:
                return JSONResponse(
                    status_code=429,
                    content={"detail": "Too many requests. Emergency rate limit throttled. Please retry shortly."},
                    headers={"Retry-After": "30"}
                )
            _ip_request_history[client_ip].append(now)

        response = await call_next(request)
        # Enforce Production HTTP Security Headers
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
        return response

app.add_middleware(RateLimitingAndSecurityMiddleware)

# Include Routers
app.include_router(auth.router)
app.include_router(residents.router)
app.include_router(sos.router)
app.include_router(notifications.router)
app.include_router(guardians.router)
app.include_router(incidents.router)
app.include_router(ai.router)

@app.get("/")
def home():
    return {
        "service": settings.PROJECT_NAME,
        "status": "online",
        "environment": settings.ENVIRONMENT,
        "version": "2.1.0",
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

# =============================================================================
# REAL-TIME WEBSOCKET ENDPOINTS
# =============================================================================
from fastapi import WebSocket, WebSocketDisconnect
from app.services.realtime import realtime_hub

@app.websocket("/ws/sos")
async def websocket_sos_endpoint(websocket: WebSocket):
    await realtime_hub.connect_sos(websocket)
    try:
        while True:
            data = await websocket.receive_text()
            await websocket.send_json({"type": "PONG", "status": "CONNECTED"})
    except WebSocketDisconnect:
        realtime_hub.disconnect_sos(websocket)

@app.websocket("/ws/tracking")
async def websocket_tracking_endpoint(websocket: WebSocket):
    await realtime_hub.connect_tracking(websocket)
    try:
        while True:
            data = await websocket.receive_json()
            await realtime_hub.broadcast_tracking(data)
    except WebSocketDisconnect:
        realtime_hub.disconnect_tracking(websocket)

@app.websocket("/ws/notifications")
async def websocket_notifications_endpoint(websocket: WebSocket, user_id: int = None):
    await realtime_hub.connect_notifications(websocket, user_id)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        realtime_hub.disconnect_notifications(websocket, user_id)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host=settings.HOST, port=settings.PORT, reload=(settings.ENVIRONMENT == "development"))
