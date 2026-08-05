import React, { useState } from 'react';
import { HeartPulse, User, LogOut, Sparkles, Shield, Siren, Activity, Users, Phone, Film, Globe, ChevronDown, Settings } from 'lucide-react';
import LocationBar from './LocationBar';
import { useLanguage, TRANSLATIONS } from '../context/LanguageContext';

export default function Navbar({ user, activeView, onChangeView, onLogout, onToggleAI, onToggleIntro, onOpenSettings, showIntro }) {
  const { lang, setLang, t } = useLanguage();
  const [showLangMenu, setShowLangMenu] = useState(false);

  const navTabs = [
    { id: 'resident', labelKey: 'residentSOS', icon: Siren, role: 'resident' },
    { id: 'responder', labelKey: 'respondersSecurity', icon: Shield, role: 'security' },
    { id: 'neighbor', labelKey: 'neighborPortal', icon: HeartPulse, role: 'neighbour' },
    { id: 'guardian', labelKey: 'guardians', icon: Phone, role: 'guardian' },
    { id: 'caregiver', labelKey: 'caregiverRoster', icon: Users, role: 'caregiver' },
    { id: 'admin', labelKey: 'adminAnalytics', icon: Activity, role: 'admin' },
  ];

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

  const userRole = user?.role?.toLowerCase() || 'resident';
  const allowedPortalIds = rolePortalsMap[userRole] || [userRole];
  const visibleNavTabs = navTabs.filter(tab => allowedPortalIds.includes(tab.id));

  const currentLangObj = TRANSLATIONS[lang] || TRANSLATIONS.en;

  return (
    <header className="navbar-header" style={{
      display: 'flex',
      flexDirection: 'column',
      background: 'var(--bg-navbar, rgba(15, 23, 42, 0.95))',
      backdropFilter: 'blur(16px)',
      borderBottom: '1px solid var(--border-color)',
      position: 'sticky',
      top: 0,
      zIndex: 50
    }}>
      {/* Main Bar */}
      <div style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: '14px 28px',
        borderBottom: '1px solid var(--border-color)'
      }}>
        {/* Brand */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <div style={{
            width: '40px',
            height: '40px',
            borderRadius: '12px',
            background: 'linear-gradient(135deg, #ef4444 0%, #14b8a6 100%)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            boxShadow: '0 0 16px rgba(239, 68, 68, 0.4)'
          }}>
            <HeartPulse size={24} color="#ffffff" />
          </div>
          <div>
            <h1 style={{ fontSize: '1.35rem', fontWeight: 800, color: '#f8fafc', margin: 0 }}>CareConnect</h1>
            <p style={{ fontSize: '0.72rem', color: '#94a3b8', margin: 0 }}>{t('brandSubtitle')}</p>
          </div>
        </div>

        {/* Right User Controls */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          {/* Multi-Language Selector Dropdown */}
          <div style={{ position: 'relative' }}>
            <button
              onClick={() => setShowLangMenu(!showLangMenu)}
              className="btn btn-secondary"
              style={{
                background: 'var(--bg-card)',
                borderColor: 'var(--border-color)',
                color: 'var(--text-primary)',
                fontSize: '0.82rem',
                padding: '6px 12px',
                display: 'flex',
                alignItems: 'center',
                gap: '8px'
              }}
              title="Select Language"
            >
              <Globe size={15} color="#14b8a6" />
              <span>{currentLangObj.flag} <span className="nav-btn-text">{currentLangObj.name}</span></span>
              <ChevronDown size={14} style={{ transform: showLangMenu ? 'rotate(180deg)' : 'none', transition: 'transform 0.2s' }} />
            </button>

            {showLangMenu && (
              <div style={{
                position: 'absolute',
                top: 'calc(100% + 8px)',
                right: 0,
                width: '320px',
                maxHeight: '400px',
                overflowY: 'auto',
                background: '#1e293b',
                border: '1px solid rgba(20, 184, 166, 0.3)',
                borderRadius: '16px',
                padding: '10px',
                boxShadow: '0 15px 40px rgba(0,0,0,0.7)',
                zIndex: 1000,
                display: 'grid',
                gridTemplateColumns: '1fr 1fr',
                gap: '6px'
              }}>
                {Object.values(TRANSLATIONS).map(item => (
                  <button
                    key={item.code}
                    onClick={() => {
                      setLang(item.code);
                      setShowLangMenu(false);
                    }}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '8px',
                      padding: '8px 10px',
                      borderRadius: '8px',
                      border: lang === item.code ? '1px solid rgba(20, 184, 166, 0.5)' : '1px solid transparent',
                      background: lang === item.code ? 'rgba(20, 184, 166, 0.2)' : 'rgba(255, 255, 255, 0.03)',
                      color: lang === item.code ? '#14b8a6' : '#cbd5e1',
                      fontWeight: lang === item.code ? 700 : 500,
                      fontSize: '0.8rem',
                      cursor: 'pointer',
                      textAlign: 'left',
                      width: '100%',
                      transition: 'all 0.15s ease'
                    }}
                  >
                    <span style={{ fontSize: '1.2rem' }}>{item.flag}</span>
                    <div style={{ display: 'flex', flexDirection: 'column', lineHeight: 1.1 }}>
                      <span style={{ fontWeight: 700, color: '#f8fafc' }}>{item.nativeName || item.name}</span>
                      <span style={{ fontSize: '0.68rem', color: '#94a3b8' }}>{item.name}</span>
                    </div>
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* Live Location Access Badge */}
          <LocationBar />

          <button 
            className="btn btn-secondary" 
            onClick={onToggleIntro}
            style={{
              background: 'rgba(255, 255, 255, 0.08)',
              borderColor: 'rgba(255, 255, 255, 0.15)',
              color: '#f8fafc',
              fontSize: '0.82rem'
            }}
            title="Return to Intro Landing Screen"
          >
            <Film size={16} />
            <span className="nav-btn-text">{t('introPage')}</span>
          </button>

          <button 
            className="btn btn-secondary" 
            onClick={onToggleAI}
            style={{ background: 'rgba(139, 92, 246, 0.18)', borderColor: 'rgba(139, 92, 246, 0.4)', color: '#c084fc', fontSize: '0.82rem' }}
          >
            <Sparkles size={16} />
            <span className="nav-btn-text">{t('aiAssistant')}</span>
          </button>

          {user && (
            <div style={{
              display: 'flex',
              alignItems: 'center',
              gap: '10px',
              background: 'var(--bg-card)',
              padding: '6px 14px',
              borderRadius: '9999px',
              border: '1px solid var(--border-color)'
            }}>
              <User size={16} color="#14b8a6" />
              <div className="nav-profile-details" style={{ textAlign: 'left' }}>
                <div style={{ fontSize: '0.82rem', fontWeight: 700, color: '#f8fafc' }}>{user.full_name}</div>
                <div style={{ fontSize: '0.68rem', color: '#10b981', textTransform: 'uppercase', fontWeight: 700 }}>{user.role}</div>
              </div>
            </div>
          )}

          <button 
            className="btn btn-secondary" 
            onClick={onOpenSettings} 
            title="Settings & Profile" 
            style={{ background: 'rgba(20, 184, 166, 0.15)', borderColor: 'rgba(20, 184, 166, 0.3)', color: '#14b8a6', padding: '8px 14px' }}
          >
            <Settings size={16} />
            <span className="nav-btn-text">Settings</span>
          </button>

          <button className="btn btn-secondary" onClick={onLogout} title="Log Out" style={{ padding: '8px 14px' }}>
            <LogOut size={16} />
            <span className="nav-btn-text">{t('logout')}</span>
          </button>
        </div>
      </div>

      {/* Interactive Quick View Tab Navigator */}
      <div style={{
        display: 'flex',
        alignItems: 'center',
        gap: '6px',
        padding: '6px 28px',
        background: 'var(--bg-navbar, rgba(15, 23, 42, 0.6))',
        borderBottom: '1px solid var(--border-color)',
        overflowX: 'auto'
      }}>
        <span style={{ fontSize: '0.72rem', color: '#64748b', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.05em', marginRight: '8px' }}>
          View Portals:
        </span>
        {visibleNavTabs.map(tab => {
          const Icon = tab.icon;
          const isActive = activeView === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => onChangeView(tab.id)}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '6px',
                padding: '6px 14px',
                borderRadius: '8px',
                border: isActive ? '1px solid #14b8a6' : '1px solid transparent',
                background: isActive ? 'rgba(20, 184, 166, 0.18)' : 'transparent',
                color: isActive ? '#14b8a6' : '#94a3b8',
                fontWeight: isActive ? 700 : 500,
                fontSize: '0.82rem',
                cursor: 'pointer',
                transition: 'all 0.2s ease',
                whiteSpace: 'nowrap'
              }}
            >
              <Icon size={14} />
              <span>{t(tab.labelKey)}</span>
            </button>
          );
        })}
      </div>
    </header>
  );
}
