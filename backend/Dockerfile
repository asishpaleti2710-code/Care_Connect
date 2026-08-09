# Multi-stage lightweight production Dockerfile for CareConnect Backend
FROM python:3.11-slim as builder

WORKDIR /app

# Install build dependencies for compiling binary packages if needed
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    default-libmysqlclient-dev \
    pkg-config \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Final minimal runtime image
FROM python:3.11-slim as runner

WORKDIR /app

# Install runtime database client libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
    libmariadb3 \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy installed Python packages from builder stage
COPY --from=builder /root/.local /root/.local
ENV PATH=/root/.local/bin:$PATH

# Set environment defaults
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=8000 \
    ENVIRONMENT=production

# Copy application source code
COPY . .

# Expose container port
EXPOSE 8000

# Healthcheck definition
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:${PORT}/health || exit 1

# Start FastAPI application using Gunicorn with Uvicorn worker class for production scale
CMD ["sh", "-c", "gunicorn app.main:app -w 2 -k uvicorn.workers.UvicornWorker -b 0.0.0.0:${PORT} --timeout 120 --access-logfile - --error-logfile -"]
