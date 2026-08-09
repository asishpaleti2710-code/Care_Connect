# CareConnect: Complete Production Cloud Deployment Guide

A step-by-step guide to deploying the **CareConnect Ecosystem** (FastAPI Backend, Cloud-Hosted Database, React Web PWA, and Flutter Mobile Application) to production so it can be accessed globally from any mobile phone or browser over the internet.

---

## 🏗️ 1. Production Architecture Diagram

```mermaid
graph TD
    subgraph Clients["📱 Client Applications (Global Internet)"]
        MobileApp["Flutter Mobile App (Android APK / iOS)<br/><i>Zero-Unlock Lockscreen Emergency Hub</i>"]
        WebApp["React 19 PWA (Vercel / Netlify / Browser)<br/><i>Responsive Dashboard & Live Maps</i>"]
    end

    subgraph CloudNetwork["☁️ Internet & Security Layer"]
        HTTPS["HTTPS / SSL Gateway (Cloudflare / Render DNS)"]
        CORS["CORS & JWT Authentication Guard"]
    end

    subgraph BackendCluster["🚀 Backend Service (Render / Railway / Docker)"]
        FastAPI["CareConnect FastAPI Cloud Engine<br/><i>Gunicorn + Uvicorn Workers</i>"]
        AuthModule["/api/auth (JWT Security)"]
        SosModule["/api/incidents & /api/sos (Emergency Dispatch)"]
        AiModule["/api/ai (Triage, Risk & Notes Classifier)"]
        HealthModule["/health & /api/health (System Diagnostics)"]
    end

    subgraph DatabaseLayer["🛢️ Cloud Database Layer"]
        MySQL["Cloud-Hosted MySQL 8.0 / Managed PostgreSQL<br/><i>(Aiven / Railway / AWS RDS / Supabase)</i>"]
    end

    MobileApp -->|HTTPS / REST API| HTTPS
    WebApp -->|HTTPS / REST API| HTTPS
    HTTPS --> CORS
    CORS --> FastAPI
    FastAPI --> AuthModule
    FastAPI --> SosModule
    FastAPI --> AiModule
    FastAPI --> HealthModule
    FastAPI -->|SQLAlchemy Connection Pool| MySQL
```

---

## 📋 2. Deployment Checklist

- [x] **Backend Configuration**: Dynamic `DATABASE_URL`, `CORS_ORIGINS`, `ENVIRONMENT=production`, and `/health` monitoring.
- [x] **Database Engine**: Dialect auto-normalizer supporting `mysql+pymysql://`, `postgresql+psycopg2://`, and SQLite.
- [x] **Docker Infrastructure**: Multi-stage `Dockerfile`, `.dockerignore`, and `docker-compose.yml` generated.
- [x] **Infrastructure-as-Code**: `render.yaml`, `railway.json`, `Procfile`, `application-prod.yml` ready.
- [x] **Frontend Web Config**: `.env.production` pointing to cloud backend.
- [x] **Flutter Mobile Config**: Dynamic runtime endpoint switcher and production cloud fallback.
- [ ] **Step 1**: Create Cloud Database (MySQL or PostgreSQL).
- [ ] **Step 2**: Deploy Backend Web Service to Render / Railway.
- [ ] **Step 3**: Deploy Web Frontend to Vercel / Netlify.
- [ ] **Step 4**: Build and install Flutter Android APK on mobile devices.

---

## 🔑 3. Required Accounts & Estimated Costs

| Service | Purpose | Recommended Provider | Free Tier Availability | Estimated Cost |
| :--- | :--- | :--- | :--- | :--- |
| **Backend Hosting** | FastAPI Python API Server | [Render](https://render.com) (Preferred) or [Railway](https://railway.app) | **Free** (750 hrs/mo on Render, $5 trial on Railway) | **$0.00 / mo** |
| **Database** | Cloud MySQL / PostgreSQL | [Aiven for MySQL](https://aiven.io) or [Render Postgres](https://render.com) | **Free** (Free tier on Aiven / Render) | **$0.00 / mo** |
| **Web Frontend** | React PWA Static Site | [Vercel](https://vercel.com) or [Netlify](https://netlify.com) | **Free** (100GB bandwidth/mo) | **$0.00 / mo** |
| **Mobile Build** | Android APK Generation | Flutter SDK (Local Build) | **100% Free** | **$0.00** |
| **Total Cost** | | | | **$0.00 / month** |

---

## 🌐 4. Exact URL Replacement Mapping

| Environment | Old Localhost URL | Production Online Cloud URL |
| :--- | :--- | :--- |
| **Backend REST API** | `http://localhost:8000` | `https://careconnect-backend.onrender.com` |
| **Backend Health Check**| `http://localhost:8000/health` | `https://careconnect-backend.onrender.com/health` |
| **Interactive API Docs** | `http://localhost:8000/docs` | `https://careconnect-backend.onrender.com/docs` |
| **Frontend Web App** | `http://localhost:5173` | `https://careconnect-app.vercel.app` (or your chosen domain) |

---

## 🚀 5. Step-by-Step Deployment Instructions

### Step 1: Set Up Cloud MySQL Database (e.g., on Aiven or Railway)

1. **Option A: Aiven for MySQL (Free)**
   - Go to [Aiven Console](https://console.aiven.io) and create a free account.
   - Click **Create Service** > Select **MySQL** > Choose **Free Plan**.
   - Copy the **Service URI** (e.g. `mysql://avnadmin:password123@mysql-careconnect.aivencloud.com:13402/defaultdb?ssl-mode=REQUIRED`).
   - Prefix it with `mysql+pymysql://` (CareConnect handles this automatically if `mysql://` is provided).

2. **Option B: Render Managed PostgreSQL (Free)**
   - On Render Dashboard, click **New** > **PostgreSQL**.
   - Copy the **Internal Database URL** or **External Database URL**.

---

### Step 2: Deploy Backend to Render (Preferred)

1. Push your repository to GitHub / GitLab.
2. Log in to [Render Dashboard](https://dashboard.render.com).
3. Click **New +** > **Web Service** > Connect your GitHub repository.
4. Fill in the following settings:
   - **Name**: `careconnect-backend`
   - **Root Directory**: `CareConnect/backend`
   - **Runtime**: `Python 3`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `gunicorn app.main:app -w 2 -k uvicorn.workers.UvicornWorker -b 0.0.0.0:$PORT --timeout 120`
5. Under **Environment Variables**, add:
   | Key | Value |
   | :--- | :--- |
   | `ENVIRONMENT` | `production` |
   | `PROJECT_NAME` | `CareConnect Cloud API` |
   | `SECRET_KEY` | *(Generate a 32+ character random string)* |
   | `DATABASE_URL` | `your_cloud_database_connection_string` |
   | `CORS_ORIGINS` | `*` |
   | `PYTHON_VERSION` | `3.11.9` |
6. Click **Create Web Service**. Render will build and deploy your API at:
   `https://careconnect-backend.onrender.com`

---

### Step 3: Deploy Web Frontend to Vercel or Netlify

1. Go to [Vercel](https://vercel.com) > **Add New Project** > Import your repository.
2. Set **Root Directory** to `CareConnect/frontend`.
3. Set **Framework Preset** to `Vite`.
4. Under **Environment Variables**, add:
   - `VITE_API_BASE_URL` = `https://careconnect-backend.onrender.com`
   - `VITE_AI_URL` = `https://careconnect-backend.onrender.com`
5. Click **Deploy**. Your web app is live on HTTPS!

---

### Step 4: Build & Distribute Mobile Application (Flutter APK)

To run the app on any real Android phone over cellular/WiFi internet:

1. Open a terminal in `CareConnect-Flutter`.
2. Build release APK:
   ```bash
   flutter build apk --release
   ```
3. The resulting APK will be generated at:
   `build/app/outputs/flutter-apk/app-release.apk`
4. Transfer this APK to any Android phone and install it.
5. In the app's **Settings**, the server will automatically default to `https://careconnect-backend.onrender.com`. You can tap **"Test Ping"** to verify live connection anytime!

---

## 🧪 6. Post-Deployment Verification Guide

Test the following endpoints on your deployed backend:

1. **Health Diagnostic**:
   ```bash
   curl https://careconnect-backend.onrender.com/health
   ```
   *Expected Response:*
   ```json
   {
     "status": "healthy",
     "database": {
       "status": "healthy",
       "engine": "mysql"
     },
     "uptime_seconds": 120,
     "environment": "production"
   }
   ```

2. **User Authentication**:
   ```bash
   curl -X POST https://careconnect-backend.onrender.com/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"resident@careconnect.org","password":"password123"}'
   ```

3. **Emergency SOS Trigger**:
   ```bash
   curl -X POST https://careconnect-backend.onrender.com/api/incidents/trigger \
     -H "Content-Type: application/json" \
     -d '{"incident_type":"Medical Emergency","description":"Test online dispatch","location":"Global GPS"}'
   ```

4. **AI Emergency Classifier**:
   ```bash
   curl -X POST https://careconnect-backend.onrender.com/api/ai/classify-emergency \
     -H "Content-Type: application/json" \
     -d '{"description":"Resident fell down the stairs and cannot stand"}'
   ```
