import os
import sys

# Ensure backend directory is in python path
current_dir = os.path.dirname(os.path.abspath(__file__))
backend_dir = os.path.join(current_dir, "backend")

if os.path.isdir(backend_dir):
    sys.path.insert(0, backend_dir)
    print(f"[CareConnect] Running from root, backend at: {backend_dir}", flush=True)
else:
    # Already inside the backend directory (Railway may deploy only the backend dir)
    sys.path.insert(0, current_dir)
    print(f"[CareConnect] Running from backend dir: {current_dir}", flush=True)

import uvicorn

port = int(os.getenv("PORT", "8000"))
host = os.getenv("HOST", "0.0.0.0")

print(f"[CareConnect] Starting Cloud API on {host}:{port}", flush=True)
print(f"[CareConnect] sys.path = {sys.path[:3]}", flush=True)
print(f"[CareConnect] Working dir = {os.getcwd()}", flush=True)

uvicorn.run("app.main:app", host=host, port=port, log_level="info")
