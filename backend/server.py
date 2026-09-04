import os
import sys

# Ensure current backend directory is in python path
backend_dir = os.path.dirname(os.path.abspath(__file__))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

print(f"[CareConnect] Backend server.py starting...", flush=True)
print(f"[CareConnect] Working dir = {os.getcwd()}", flush=True)
print(f"[CareConnect] sys.path[0] = {sys.path[0]}", flush=True)

import uvicorn

port = int(os.getenv("PORT", "8000"))
host = os.getenv("HOST", "0.0.0.0")

print(f"[CareConnect] Starting Cloud API on {host}:{port}", flush=True)

uvicorn.run("app.main:app", host=host, port=port, log_level="info")
