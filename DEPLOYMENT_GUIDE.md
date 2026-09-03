# CareConnect: Complete Production Cloud Deployment Guide

A comprehensive, production-grade guide to deploying the **CareConnect Ecosystem** (FastAPI Cloud Backend, Cloud-Hosted PostgreSQL Database, React 19 Web App, Flutter Web App, and Android APK/AAB Mobile Application) so it can be accessed globally from any browser or mobile phone over the internet.

---

## 🏗️ 1. Production Architecture Diagram

```mermaid
graph TD
    subgraph Clients["📱 Client Applications (Global Access)"]
        MobileApp["Flutter Mobile App (Android APK / AAB)<br/><i>Zero-Unlock Lockscreen Emergency Hub</i>"]
        WebDashboard["React 19 Web Dashboard (Vercel / Netlify)<br/><i>Single Source of Truth UI & Portal View</i>"]
        FlutterWebApp["Flutter Web App (Browser Access)<br/><i>Multi-Platform Cross-Compiled Web Client</i>"]
    end

    subgraph CloudEdge["☁️ Cloud Edge & Security"]
        HTTPS["HTTPS / SSL Gateway (Cloudflare / Vercel DNS)"]
        WSS["WSS / Secure WebSocket Proxy"]
        CORS["CORS & JWT Authentication Guard"]
    end

    subgraph BackendCluster["🚀 Backend Service (Railway / Render / Docker)"]
        FastAPI["CareConnect FastAPI Engine<br/><i>Uvicorn / Gunicorn Multi-Worker</i>"]
        AuthModule["/api/auth (JWT Security & RBAC)"]
        SosModule["/api/sos & /api/incidents (Emergency Dispatch)"]
        AlertRouter["Alert Routing Engine (4-Tier Escalation)"]
        AiModule["/api/ai (CarePulse AI Triage & Summarizer)"]
        RealtimeHub["WebSocket Hub (/ws/sos, /ws/tracking, /ws/notifications)"]
    end

    subgraph ExternalGateways["📡 External Communication Gateways"]
        EmailGW["SMTP / SendGrid / Resend (HTML Emergency Emails)"]
        PushGW["Firebase Cloud Messaging (FCM Push Alerts)"]
        SmsGW["Twilio SMS Gateway (Offline SMS Fallback)"]
    end

    subgraph DatabaseLayer["🛢️ Cloud Database Layer"]
        Postgres["Managed PostgreSQL Database<br/><i>(Render / Railway / Supabase / Neon)</i>"]
    end

    MobileApp -->|HTTPS| HTTPS
    WebDashboard -->|HTTPS| HTTPS
    FlutterWebApp -->|HTTPS| HTTPS
    MobileApp -->|WSS| WSS
    WebDashboard -->|WSS| WSS

    HTTPS --> CORS
    WSS --> RealtimeHub
    CORS --> FastAPI

    FastAPI --> AuthModule
    FastAPI --> SosModule
    FastAPI --> AlertRouter
    FastAPI --> AiModule
    FastAPI --> RealtimeHub

    AlertRouter --> EmailGW
    AlertRouter --> PushGW
    AlertRouter --> SmsGW

    FastAPI -->|Connection Pool (psycopg2)| Postgres
```

---

## 🌐 2. Live Cloud URLs & Environment Status

| Service | Environment | Live URL / Status | Verification |
| :--- | :--- | :--- | :--- |
| **Backend REST API** | Production | `https://careconnect-production-bab1.up.railway.app` | `GET /` returns `{"service":"CareConnect API","status":"online"}` |
| **Backend Health Check** | Production | `https://careconnect-production-bab1.up.railway.app/health` | `GET /health` returns `{"status":"healthy"}` |
| **Interactive API Docs** | Production | `https://careconnect-production-bab1.up.railway.app/docs` | Swagger UI with all 30+ endpoints |
| **WebSockets Hub** | Production | `wss://careconnect-production-bab1.up.railway.app/ws/sos` | Live emergency broadcast stream |
| **React Web App** | Production Build | Built in `frontend/dist` (Vercel & Netlify ready) | `npm run build` completed in <1s |
| **Flutter Web App** | Production Build | Built in `mobile/build/web` | `flutter build web` completed |
| **Android Release APK** | Production Build | `mobile/build/app/outputs/flutter-apk/app-release.apk` (54.1 MB) | Signed, tree-shaken, R8 optimized |
| **Android Debug APK** | Development | `mobile/build/app/outputs/flutter-apk/app-debug.apk` (156.9 MB) | Tested & validated |

---

## 🚀 3. Step-by-Step Deployment Instructions

### Step 1: Deploy Web Frontend to Vercel (Recommended)

1. Push your repository to GitHub / GitLab / Bitbucket.
2. Log in to [Vercel](https://vercel.com) and click **Add New Project**.
3. Import the `CareConnect` repository.
4. Set the **Root Directory** to `frontend`.
5. Under **Build & Development Settings**:
   - **Framework Preset**: Vite
   - **Build Command**: `npm run build`
   - **Output Directory**: `dist`
6. Add Environment Variable:
   - `VITE_API_BASE_URL` = `https://careconnect-production-bab1.up.railway.app`
   - `VITE_AI_URL` = `https://careconnect-production-bab1.up.railway.app`
7. Click **Deploy**. Vercel will output a live URL (e.g. `https://careconnect.vercel.app`).

### Step 2: Deploy Web Frontend to Netlify (Alternative)

1. Log in to [Netlify](https://netlify.com) and select **Add new site** > **Import an existing project**.
2. Select your repository.
3. Configuration will be auto-detected via `frontend/netlify.toml`:
   - **Base directory**: `frontend`
   - **Build command**: `npm run build`
   - **Publish directory**: `dist`
4. In **Site Configuration** > **Environment Variables**, set:
   - `VITE_API_BASE_URL` = `https://careconnect-production-bab1.up.railway.app`
5. Click **Deploy Site**.

### Step 3: Deploy Backend to Render (with Managed PostgreSQL)

1. Create a free account at [Render](https://render.com).
2. Click **New** > **Blueprint**.
3. Connect your repository. Render will automatically read `backend/render.yaml`.
4. It will provision:
   - **`careconnect-backend`**: Python web service with multi-worker Gunicorn/Uvicorn.
   - **`careconnect-postgres`**: Free managed PostgreSQL database with auto-wired `DATABASE_URL`.
5. Under Environment Variables in the Render dashboard, optionally configure:
   - `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`, `SMTP_FROM_EMAIL`
   - `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_FROM_NUMBER`
   - `FCM_SERVER_KEY`
6. Click **Apply**. Render will deploy both services in minutes.

### Step 4: Deploy Backend to Railway (Alternative)

1. Log in to [Railway](https://railway.app).
2. Click **New Project** > **Deploy from GitHub Repo**.
3. Add a **PostgreSQL** database service by clicking **New** > **Database** > **PostgreSQL**.
4. In your Backend service settings:
   - Connect the PostgreSQL database (`DATABASE_URL` is automatically linked).
   - Set start command to `cd backend && python -m uvicorn app.main:app --host 0.0.0.0 --port $PORT`.
5. Generate domain in service settings.

---

## 🔑 4. Environment Variables Reference

### Backend (`.env.production`)
```ini
PROJECT_NAME="CareConnect Cloud API"
ENVIRONMENT=production
PORT=8000
HOST=0.0.0.0

# Database
DATABASE_URL=postgresql+psycopg2://careconnect_admin:password@host:5432/careconnect

# Security
SECRET_KEY=careconnect_super_secret_production_key_32chars_min_abcdef123456
ACCESS_TOKEN_EXPIRE_MINUTES=1440
CORS_ORIGINS=*

# Email (SMTP / SendGrid / Resend)
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASSWORD=your_api_key_or_smtp_password
SMTP_FROM_EMAIL=emergency-alerts@careconnect.org
SMTP_FROM_NAME="CareConnect Emergency Response Network"

# SMS Fallback (Twilio)
TWILIO_ACCOUNT_SID=your_twilio_sid
TWILIO_AUTH_TOKEN=your_twilio_auth_token
TWILIO_FROM_NUMBER=+15551234567

# Push Notifications (Firebase Cloud Messaging)
FCM_SERVER_KEY=your_fcm_server_key
FIREBASE_PROJECT_ID=careconnect-emergency
```

### Frontend (`.env.production`)
```ini
VITE_API_BASE_URL=https://careconnect-production-bab1.up.railway.app
VITE_AI_URL=https://careconnect-production-bab1.up.railway.app
```

---

## 📱 5. Android APK & Mobile Installation

### Download Built APKs
- **Release APK**: [app-release.apk](file:///d:/infosys%207.0/CareConnect/mobile/build/app/outputs/flutter-apk/app-release.apk) (54.1 MB)
- **Debug APK**: [app-debug.apk](file:///d:/infosys%207.0/CareConnect/mobile/build/app/outputs/flutter-apk/app-debug.apk) (156.9 MB)

### Installation via ADB
```bash
adb install -r "d:\infosys 7.0\CareConnect\mobile\build\app\outputs\flutter-apk\app-release.apk"
```

### Generating Android App Bundle (AAB) for Google Play
```bash
cd mobile
flutter build appbundle --release
```
*Output*: `mobile/build/app/outputs/bundle/release/app-release.aab`
