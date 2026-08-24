# CareConnect 🏥
### Community Emergency Response & Assistance Network

[![React](https://img.shields.io/badge/Frontend-React_19-blue.svg)](https://react.dev/)
[![FastAPI](https://img.shields.io/badge/Backend-FastAPI-009688.svg)](https://fastapi.tiangolo.com/)
[![Vite](https://img.shields.io/badge/Bundler-Vite_6-646CFF.svg)](https://vitejs.dev/)
[![Capacitor](https://img.shields.io/badge/Mobile-Capacitor_8-119EFF.svg)](https://capacitorjs.com/)
[![Python](https://img.shields.io/badge/Python-3.10+-3776AB.svg)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**CareConnect** is a state-of-the-art, cross-platform community emergency response and caregiving network. Designed to seamlessly connect residents, caregivers, family guardians, community volunteers, security responders, and administrative directors, CareConnect delivers real-time emergency dispatches, interactive GPS maps, AI-assisted medical risk analysis, and native mobile builds for Android and iOS.

---

## 🌐 Live & Deployment URLs

- **GitHub Repository**: [https://github.com/asishpaleti2710-code/Care_Connect](https://github.com/asishpaleti2710-code/Care_Connect)
- **Deployed Backend API**: [https://care-connect-qtsk.vercel.app](https://care-connect-qtsk.vercel.app)
- **Local Dev Web App**: `http://localhost:5173`
- **Local Backend API**: `http://localhost:8000` *(API Docs: `http://localhost:8000/docs`)*
- **Local AI Agent Microservice**: `http://localhost:8001`

---

## ✨ Key Features & Multi-Portal Architecture

CareConnect features **6 specialized role-based portals** to serve every user in the emergency response chain:

| Portal | Target Role | Key Capabilities |
| :--- | :--- | :--- |
| 🚨 **Resident SOS** | Senior Residents / Patients | One-tap emergency SOS triggering, real-time dispatch tracking, medical history profile, emergency contact management, and AI risk classifier. |
| 🛡️ **Responders & Security** | Security, Police, EMTs, Volunteers | Real-time emergency incident feed, one-click incident acceptance, turn-by-turn Leaflet/OSRM map navigation, and incident status progression (`Accepted` ➔ `En Route` ➔ `Resolved`). |
| 💓 **Neighbor Network** | Community Neighbors & Volunteers | Community-based emergency alert network enabling nearby neighbors to accept and provide immediate assistance before official emergency services arrive. |
| 📞 **Guardians** | Family Members / Next of Kin | Continuous peace-of-mind monitoring, live emergency alert notifications when a ward triggers an SOS, and direct caregiver contact details. |
| 📋 **Caregiver Roster** | Caregivers / Nurses | Daily resident care roster, vital sensor telemetry monitoring (heart rate, fall detection), medication logs, and AI-assisted medical note analysis. |
| 📊 **Admin Analytics** | System Admins / Directors | Executive command center, system-wide dispatch override, response time analytics, resident/guardian directory management, and full access to **all sub-portals**. |

> **Note on the Volunteer Role**: Volunteers act as dual-capability community responders and have built-in access to both the **Responders & Security** portal (for official emergency dispatches) and the **Neighbor Network** portal (for local community wellness checks).

---

## 🔄 End-to-End System Working Process

```
┌─────────────────┐      ┌───────────────────────────┐      ┌─────────────────────────────┐
│ 1. SOS Trigger  │ ───► │ 2. AI Risk Classification │ ───► │ 3. Real-Time Broadcast      │
│ Resident or     │      │ FastAPI AI Agent assesses │      │ Broadcasts SOS to           │
│ Sensor Anomaly  │      │ emergency urgency level   │      │ Responders, Neighbors &     │
└─────────────────┘      └───────────────────────────┘      │ Guardians                   │
                                                            └──────────────┬──────────────┘
                                                                           │
┌─────────────────┐      ┌───────────────────────────┐                     │
│ 5. Audit & Logs │ ◄─── │ 4. On-Scene & Resolution  │ ◄───────────────────┘
│ Logged in Admin │      │ Responder accepts, follows│
│ Analytics Panel │      │ GPS map & marks Resolved  │
└─────────────────┘      └───────────────────────────┘
```

### Detailed Operational Flow:
1. **Emergency Triggering**: A resident presses the high-contrast SOS button on their mobile or web dashboard.
2. **AI Classification**: The description is processed by the **FastAPI AI Agent** (`ai-agent/main.py`), categorizing risk severity (e.g., *Critical - Cardiac Risk*).
3. **Multi-Channel Dispatch**: The backend broadcasts the alert to active **Security Responders**, **Volunteer Responders**, **Nearby Neighbors**, and the resident's **Family Guardian**.
4. **Responder Acceptance & GPS Guidance**: A responder accepts the incident. The system locks the dispatch, generates turn-by-turn Leaflet/OSRM route navigation, and provides the responder with vital medical summaries.
5. **Resolution & Executive Auditing**: Upon resolving the incident on-scene, status updates to `Resolved`. Detailed response metrics are archived in **Admin Analytics**.

---

## 🏗️ Architecture & Tech Stack

```
CareConnect Platform
 ├── Frontend: React 19 + Vite + Lucide Icons + Leaflet Maps + Capacitor 8
 ├── Backend API: Python FastAPI + SQLite ORM + PyJWT Authentication
 └── AI Microservice: Python FastAPI + Automated Care Decision Engine
```

---

## 🚀 Quick Start Guide (Local Environment)

### Prerequisites
- **Node.js** (v18+ recommended)
- **Python** (v3.10+ recommended)
- **Git**

---

### 1. Start Backend API Server

```bash
cd backend

# Create local secrets file (never committed)
cp .env.example .env
# Generate a SECRET_KEY value for .env:
python -c "import secrets; print(secrets.token_urlsafe(48))"

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# macOS/Linux:
# source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Seed test database (optional)
python app/seed.py

# Run FastAPI backend
uvicorn app.main:app --reload --port 8000
```
> Backend runs at `http://localhost:8000`. Swagger API docs available at `http://localhost:8000/docs`.

---

### 2. Start AI Agent Service

```bash
cd ai-agent

# The AI service validates CareConnect access tokens, so it needs the same SECRET_KEY
cp .env.example .env

# Activate virtual environment & install requirements
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt

# Start AI Agent service
python main.py
```
> AI Agent runs on port `http://localhost:8001`.

---

### 3. Start Frontend App

```bash
cd frontend

# Install npm packages
npm install

# Start Vite development server
npm run dev
```
> Open your browser at `http://localhost:5173`.

---

## 🔑 Demo Account Credentials

| Role | Email | Password |
| :--- | :--- | :--- |
| **Admin / Director** | `admin@careconnect.org` | `admin123` |
| **Resident (Ashish)** | `ashish@careconnect.org` | `resident123` |
| **Resident (Eleanor)** | `eleanor@careconnect.org` | `resident123` |
| **Guardian** | `guardian@careconnect.org` | `guardian123` |
| **Security Responder** | `security@careconnect.org` | `security123` |

---

## 📱 Mobile App Compilation (Capacitor)

CareConnect compiles directly into native Android and iOS apps using Capacitor:

```bash
cd frontend

# Sync web assets to native mobile projects
npm run cap:sync

# Open in Android Studio
npm run cap:open-android

# Open in Xcode (macOS)
npm run cap:open-ios
```

---

## 🧪 Automated Testing

Run end-to-end API test suites:
```bash
cd backend
python test_api.py
```

---

## 🔐 Security Configuration

| Variable | Service | Notes |
| :--- | :--- | :--- |
| `SECRET_KEY` | backend, ai-agent | JWT signing/validation key. Must be identical in both services and is **required** when `ENVIRONMENT=production`. |
| `ENVIRONMENT` | backend, ai-agent | `development` (default) or `production`. |
| `CORS_ORIGINS` | backend, ai-agent | Comma-separated allowlist of browser origins. Wildcards are not used. |
| `ENABLE_DOCS` | backend | Exposes `/docs`, `/redoc`, `/openapi.json`. Defaults to off in production. |
| `AI_AGENT_REQUIRE_AUTH` | ai-agent | Defaults to `true`; AI endpoints require a valid access token. |

Other security behaviour worth knowing:

- Self-service registration can only create `resident`, `guardian` and `neighbour` accounts. Staff and responder roles (`admin`, `caregiver`, `security`, `volunteer`) must be provisioned directly.
- Residents may only raise SOS alerts/incidents for their own linked resident record.
- Resident record writes are limited to `admin`/`caregiver`; incident dispatch actions to responder roles; analytics to `admin`.
- Passwords must be at least 8 characters.

## 📄 License

Distributed under the MIT License. See `LICENSE` for details.
