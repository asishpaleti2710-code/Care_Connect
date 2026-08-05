# CareConnect 🏥
### Community Emergency Response & Assistance Network

[![React](https://img.shields.io/badge/Frontend-React_19-blue.svg)](https://react.dev/)
[![FastAPI](https://img.shields.io/badge/Backend-FastAPI-009688.svg)](https://fastapi.tiangolo.com/)
[![Vite](https://img.shields.io/badge/Bundler-Vite_6-646CFF.svg)](https://vitejs.dev/)
[![Capacitor](https://img.shields.io/badge/Mobile-Capacitor_8-119EFF.svg)](https://capacitorjs.com/)
[![Python](https://img.shields.io/badge/Python-3.10+-3776AB.svg)](https://www.python.org/)

**CareConnect** is a comprehensive, cross-platform community emergency response and caregiving network. Designed to bridge residents, caregivers, family members, and administrative staff, CareConnect provides real-time emergency dispatch, service tracking, dynamic maps, AI-assisted care recommendations, and mobile readiness for Android and iOS devices.

---

## ✨ Key Features

- **🚨 SOS & Emergency Dispatch**: Instant emergency alert triggering with location details and confirmation workflows for rapid responder dispatch.
- **👥 Multi-Role Dashboard**: Custom tailored interfaces for:
  - **Residents**: Emergency triggering, service requests, medical status, and profile management.
  - **Caregivers**: Task assignments, resident monitoring, emergency alerts, and updates.
  - **Family Members**: Loved one's status tracking, updates, and direct communications.
  - **Admin / Staff**: System management, analytics, user roles, and dispatch overview.
- **🤖 AI Agent Integration**: Intelligent FastAPI-based AI agent to assist caregivers and residents with automated care recommendations and queries.
- **🗺️ Interactive Maps & Location Services**: Integrated Leaflet maps for emergency geolocation tracking and community mapping.
- **📱 Cross-Platform & Mobile Ready**: Built with Capacitor & PWA support to seamlessly compile into native **Android** and **iOS** applications.
- **🌐 Dynamic Multi-Language Support**: Built-in internationalization for dynamic location and interface translations.
- **⚙️ Profile & System Settings**: Avatar uploads, computed age displays, contact details, and configurable app preferences.

---

## 🏗️ Architecture & Tech Stack

### **Frontend**
- **Framework**: React 19 + Vite
- **UI & Icons**: Lucide React Icons, Vanilla CSS Design System
- **Mapping**: Leaflet / React-Leaflet
- **Mobile Integration**: Capacitor 8 (Android & iOS targets), Vite PWA Plugin

### **Backend**
- **Framework**: FastAPI (Python)
- **Database**: SQLite with SQLAlchemy ORM
- **Authentication**: JWT (PyJWT) with Passlib/Bcrypt password hashing
- **Data Validation**: Pydantic v2

### **AI Agent Service**
- **Framework**: FastAPI (Python)
- **Service**: Agent decision processing engine for automated caregiver assistance

---

## 📁 Repository Structure

```
CareConnect/
├── frontend/             # React + Vite web & mobile frontend
│   ├── src/              # Components, Pages, Services, Contexts
│   ├── android/          # Native Android Capacitor Project
│   ├── ios/              # Native iOS Capacitor Project
│   ├── package.json
│   └── vite.config.js
├── backend/              # FastAPI REST backend server
│   ├── app/              # Models, Routers, Schemas, Services
│   ├── requirements.txt
│   └── seed.py           # Database seeder script
├── ai-agent/             # AI Assistant microservice
│   ├── agent_service.py  # Core AI logic
│   ├── main.py           # FastAPI AI server endpoint
│   └── requirements.txt
├── database/             # Database schema & migrations
└── README.md             # Documentation
```

---

## 🚀 Quick Start Guide

### Prerequisites
- **Node.js** (v18+ recommended)
- **Python** (v3.10+ recommended)
- **Git**

---

### 1. Backend Setup

```bash
cd backend

# Create and activate Python virtual environment
python -m venv venv

# Windows:
venv\Scripts\activate
# macOS/Linux:
# source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run the FastAPI backend server
uvicorn app.main:app --reload --port 8000
```
> The API server will start at `http://localhost:8000`. API docs available at `http://localhost:8000/docs`.

---

### 2. AI Agent Service Setup

```bash
cd ai-agent

# Activate virtual environment or create one
python -m venv venv
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Start the AI Agent service
python main.py
```
> The AI Agent service runs on port `8001` (or configured port).

---

### 3. Frontend Setup

```bash
cd frontend

# Install Node dependencies
npm install

# Start Vite development server
npm run dev
```
> Open your browser at `http://localhost:5173`.

---

## 📱 Mobile App (Capacitor)

CareConnect is pre-configured with Capacitor for native mobile app compilation.

### Sync Web Assets to Mobile Projects
```bash
cd frontend
npm run cap:sync
```

### Open in Android Studio
```bash
npm run cap:open-android
```

### Open in Xcode (macOS)
```bash
npm run cap:open-ios
```

---

## 🧪 Testing

### Running Backend API Tests
```bash
cd backend
python test_api.py
```

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.
