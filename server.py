import os
import sys

# Ensure backend directory is in python path
current_dir = os.path.dirname(os.path.abspath(__file__))
backend_dir = os.path.join(current_dir, "backend")
if os.path.isdir(backend_dir):
    sys.path.insert(0, backend_dir)
else:
    sys.path.insert(0, current_dir)

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", "8000"))
    host = os.getenv("HOST", "0.0.0.0")
    print(f"[CareConnect] Starting Cloud API on {host}:{port}")
    uvicorn.run("app.main:app", host=host, port=port)
