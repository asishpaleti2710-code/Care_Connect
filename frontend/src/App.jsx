import React, { useState, useEffect } from 'react';
import Navbar from './components/Navbar';
import Dashboard from './pages/Dashboard';
import ResidentDashboard from './pages/ResidentDashboard';
import ResponderDashboard from './pages/ResponderDashboard';
import GuardianDashboard from './pages/GuardianDashboard';
import AdminDashboard from './pages/AdminDashboard';
import NeighborDashboard from './pages/NeighborDashboard';
import Login from './pages/Login';
import AIAssistantWidget from './components/AIAssistantWidget';
import SplashVideoIntro from './components/SplashVideoIntro';
import SettingsModal from './components/SettingsModal';
import { api } from './services/api';

import { LanguageProvider } from './context/LanguageContext';

function AppContent() {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [activeView, setActiveView] = useState('admin');
  const [isAIOpen, setIsAIOpen] = useState(false);
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);
  const [showIntro, setShowIntro] = useState(true);

  const getViewForRole = (role) => {
    const r = role?.toLowerCase();
    if (r === 'resident') return 'resident';
    if (r === 'security' || r === 'volunteer') return 'responder';
    if (r === 'neighbour' || r === 'neighbor') return 'neighbor';
    if (r === 'guardian') return 'guardian';
    if (r === 'caregiver') return 'caregiver';
    if (r === 'admin') return 'admin';
    return 'resident';
  };

  useEffect(() => {
    document.title = "CareConnect — Emergency Response & Resident Safety System";

    const token = localStorage.getItem('careconnect_token');
    if (token) {
      api.getMe()
        .then(u => {
          setUser(u);
          setActiveView(getViewForRole(u.role));
        })
        .catch((err) => {
          console.error("Session restore failed, clearing stored token:", err);
          localStorage.removeItem('careconnect_token');
          setUser(null);
        })
        .finally(() => setLoading(false));
    } else {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (user && user.role !== 'admin') {
      const rolePortalsMap = {
        resident: ['resident'],
        security: ['responder'],
        volunteer: ['responder', 'neighbor'],
        neighbour: ['neighbor'],
        neighbor: ['neighbor'],
        guardian: ['guardian'],
        caregiver: ['caregiver'],
        admin: ['resident', 'responder', 'neighbor', 'guardian', 'caregiver', 'admin']
      };
      const allowedViews = rolePortalsMap[user.role?.toLowerCase()] || [getViewForRole(user.role)];
      if (!allowedViews.includes(activeView)) {
        setActiveView(getViewForRole(user.role));
      }
    }
  }, [user, activeView]);

  const handleLogout = () => {
    localStorage.removeItem('careconnect_token');
    localStorage.clear();
    setUser(null);
    setShowIntro(true);
  };

  const handleLoginSuccess = (u) => {
    setUser(u);
    setShowIntro(false);
    setActiveView(getViewForRole(u.role));
  };

  if (loading) {
    return (
      <div style={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        color: '#14b8a6',
        fontSize: '1.2rem',
        fontWeight: 600,
        background: '#0f172a'
      }}>
        Loading CareConnect Emergency System...
      </div>
    );
  }

  // 1. FULLSCREEN INTRO VIDEO BEFORE WEBSITE OPENS
  if (showIntro) {
    return (
      <SplashVideoIntro
        onComplete={() => setShowIntro(false)}
      />
    );
  }

  // 2. WEBSITE: LOGIN SCREEN (if unauthenticated)
  if (!user) {
    return (
      <Login
        onLoginSuccess={handleLoginSuccess}
        onBackToIntro={() => setShowIntro(true)}
      />
    );
  }

  // 3. WEBSITE: AUTHENTICATED DASHBOARDS
  const renderActiveView = () => {
    switch (activeView) {
      case 'resident':
        return <ResidentDashboard user={user} />;
      case 'responder':
        return <ResponderDashboard user={user} />;
      case 'neighbor':
        return <NeighborDashboard user={user} />;
      case 'guardian':
        return <GuardianDashboard user={user} />;
      case 'admin':
        return <AdminDashboard user={user} />;
      case 'caregiver':
      default:
        return <Dashboard user={user} />;
    }
  };

  return (
    <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column', background: '#0f172a' }}>
      <Navbar
        user={user}
        activeView={activeView}
        onChangeView={(view) => setActiveView(view)}
        onLogout={handleLogout}
        onToggleAI={() => setIsAIOpen(!isAIOpen)}
        onToggleIntro={() => setShowIntro(true)}
        onOpenSettings={() => setIsSettingsOpen(true)}
        showIntro={false}
      />

      {renderActiveView()}

      <AIAssistantWidget
        isOpen={isAIOpen}
        onClose={() => setIsAIOpen(false)}
      />

      <SettingsModal
        isOpen={isSettingsOpen}
        onClose={() => setIsSettingsOpen(false)}
        user={user}
        onUpdateUser={(updatedUser) => setUser(updatedUser)}
        onLogout={handleLogout}
      />
    </div>
  );
}

export default function App() {
  return (
    <LanguageProvider>
      <AppContent />
    </LanguageProvider>
  );
}
