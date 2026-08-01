import React, { useState } from 'react';
import { 
  HeartPulse, 
  ShieldAlert, 
  Volume2, 
  VolumeX, 
  ArrowRight, 
  Sparkles, 
  Siren, 
  Shield, 
  Phone, 
  Activity, 
  Users, 
  Lock,
  ChevronRight
} from 'lucide-react';

export default function IntroLandingPage({ onEnterWebsite, onDemoLogin }) {
  const [isMuted, setIsMuted] = useState(true);

  return (
    <div style={{
      minHeight: '100vh',
      background: 'radial-gradient(ellipse at top, #1e293b 0%, #0f172a 70%, #020617 100%)',
      color: '#f8fafc',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      padding: '40px 24px',
      fontFamily: 'system-ui, -apple-system, sans-serif'
    }}>
      {/* Top Header Branding */}
      <div style={{
        maxWidth: '1200px',
        width: '100%',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: '32px'
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
          <div style={{
            width: '46px',
            height: '46px',
            borderRadius: '14px',
            background: 'linear-gradient(135deg, #ef4444 0%, #14b8a6 100%)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            boxShadow: '0 0 20px rgba(239, 68, 68, 0.4)'
          }}>
            <HeartPulse size={28} color="#ffffff" />
          </div>
          <div>
            <h1 style={{ fontSize: '1.5rem', fontWeight: 900, letterSpacing: '-0.02em', margin: 0 }}>
              CareConnect
            </h1>
            <p style={{ fontSize: '0.78rem', color: '#94a3b8', margin: 0, fontWeight: 500 }}>
              Senior Living Emergency Safety & Responder Ecosystem
            </p>
          </div>
        </div>

        <button
          onClick={onEnterWebsite}
          className="btn btn-primary"
          style={{
            padding: '12px 24px',
            fontSize: '0.92rem',
            fontWeight: 700,
            borderRadius: '9999px',
            boxShadow: '0 4px 20px rgba(239, 68, 68, 0.35)'
          }}
        >
          <span>Enter CareConnect Website</span>
          <ArrowRight size={18} />
        </button>
      </div>

      {/* Main Container */}
      <div style={{ maxWidth: '1200px', width: '100%' }}>
        {/* Intro Video Hero Showcase Card */}
        <div style={{
          position: 'relative',
          width: '100%',
          borderRadius: '28px',
          overflow: 'hidden',
          border: '1px solid rgba(255, 255, 255, 0.15)',
          boxShadow: '0 20px 60px rgba(0, 0, 0, 0.7)',
          background: '#0f172a',
          marginBottom: '40px'
        }}>
          <div style={{ position: 'relative', width: '100%', height: '460px', overflow: 'hidden' }}>
            <video
              autoPlay
              loop
              muted={isMuted}
              playsInline
              style={{
                width: '100%',
                height: '100%',
                objectFit: 'cover',
                transform: 'scale(1.08)',
                transformOrigin: 'top left',
                filter: 'brightness(0.75) contrast(1.1)'
              }}
            >
              <source src="/intro.mp4" type="video/mp4" />
              Your browser does not support the video tag.
            </video>

            {/* Gradient Dark Overlay */}
            <div style={{
              position: 'absolute',
              inset: 0,
              background: 'linear-gradient(180deg, rgba(15, 23, 42, 0.3) 0%, rgba(15, 23, 42, 0.95) 100%)',
              zIndex: 2
            }} />

            {/* Watermark Cover Badge */}
            <div style={{
              position: 'absolute',
              bottom: 0,
              right: 0,
              width: '170px',
              height: '56px',
              background: 'rgba(15, 23, 42, 0.98)',
              backdropFilter: 'blur(16px)',
              borderTopLeftRadius: '20px',
              borderLeft: '1px solid rgba(255, 255, 255, 0.15)',
              borderTop: '1px solid rgba(255, 255, 255, 0.15)',
              zIndex: 10,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '8px'
            }}>
              <HeartPulse size={18} color="#ef4444" />
              <span style={{ fontSize: '0.78rem', fontWeight: 800, color: '#f8fafc', letterSpacing: '0.05em' }}>
                CareConnect
              </span>
            </div>

            {/* Content Overlay */}
            <div style={{
              position: 'absolute',
              inset: 0,
              zIndex: 5,
              padding: '36px 48px',
              display: 'flex',
              flexDirection: 'column',
              justifyContent: 'space-between'
            }}>
              {/* Header Badge & Audio Control */}
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '8px',
                  background: 'rgba(239, 68, 68, 0.25)',
                  border: '1px solid rgba(239, 68, 68, 0.4)',
                  padding: '8px 18px',
                  borderRadius: '9999px',
                  fontSize: '0.82rem',
                  fontWeight: 700,
                  color: '#f87171',
                  textTransform: 'uppercase',
                  letterSpacing: '0.06em',
                  backdropFilter: 'blur(10px)'
                }}>
                  <ShieldAlert size={16} /> Official Platform Introduction
                </div>

                <button
                  onClick={() => setIsMuted(!isMuted)}
                  className="btn btn-secondary"
                  style={{ background: 'rgba(0, 0, 0, 0.6)', padding: '10px 18px', fontSize: '0.85rem' }}
                >
                  {isMuted ? <VolumeX size={18} /> : <Volume2 size={18} />}
                  <span>{isMuted ? 'Unmute Audio' : 'Mute Audio'}</span>
                </button>
              </div>

              {/* Title & Tagline & Enter Button */}
              <div>
                <h2 style={{
                  fontSize: '2.6rem',
                  fontWeight: 900,
                  color: '#ffffff',
                  margin: '0 0 12px 0',
                  textShadow: '0 4px 20px rgba(0,0,0,0.9)',
                  lineHeight: 1.25
                }}>
                  CareConnect Emergency System
                </h2>
                <p style={{
                  fontSize: '1.1rem',
                  color: '#cbd5e1',
                  margin: '0 0 24px 0',
                  maxWidth: '740px',
                  lineHeight: 1.6,
                  textShadow: '0 2px 10px rgba(0,0,0,0.9)'
                }}>
                  Real-time senior safety monitoring, automated panic SOS dispatch, multi-role responder alerts & AI clinical intelligence.
                </p>

                <div style={{ display: 'flex', gap: '16px', flexWrap: 'wrap' }}>
                  <button
                    onClick={onEnterWebsite}
                    className="btn btn-primary"
                    style={{
                      padding: '14px 32px',
                      fontSize: '1.05rem',
                      fontWeight: 800,
                      borderRadius: '14px',
                      boxShadow: '0 6px 24px rgba(239, 68, 68, 0.4)'
                    }}
                  >
                    <span>Enter CareConnect Website</span>
                    <ArrowRight size={20} />
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Feature Cards Grid */}
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))',
          gap: '20px',
          marginBottom: '44px'
        }}>
          <div className="glass-card" style={{ padding: '24px', borderRadius: '20px' }}>
            <div style={{
              width: '44px',
              height: '44px',
              borderRadius: '12px',
              background: 'rgba(239, 68, 68, 0.2)',
              border: '1px solid rgba(239, 68, 68, 0.4)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              marginBottom: '16px'
            }}>
              <Siren size={24} color="#ef4444" />
            </div>
            <h3 style={{ fontSize: '1.15rem', fontWeight: 800, margin: '0 0 8px 0' }}>1-Touch Panic SOS</h3>
            <p style={{ fontSize: '0.88rem', color: '#94a3b8', margin: 0, lineHeight: 1.5 }}>
              Instant emergency triggers for elderly residents with room location broadcasting & sound alarms.
            </p>
          </div>

          <div className="glass-card" style={{ padding: '24px', borderRadius: '20px' }}>
            <div style={{
              width: '44px',
              height: '44px',
              borderRadius: '12px',
              background: 'rgba(20, 184, 166, 0.2)',
              border: '1px solid rgba(20, 184, 166, 0.4)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              marginBottom: '16px'
            }}>
              <Shield size={24} color="#14b8a6" />
            </div>
            <h3 style={{ fontSize: '1.15rem', fontWeight: 800, margin: '0 0 8px 0' }}>Security Dispatch</h3>
            <p style={{ fontSize: '0.88rem', color: '#94a3b8', margin: 0, lineHeight: 1.5 }}>
              Security personnel and volunteers receive immediate incident tickets with one-click acceptance.
            </p>
          </div>

          <div className="glass-card" style={{ padding: '24px', borderRadius: '20px' }}>
            <div style={{
              width: '44px',
              height: '44px',
              borderRadius: '12px',
              background: 'rgba(139, 92, 246, 0.2)',
              border: '1px solid rgba(139, 92, 246, 0.4)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              marginBottom: '16px'
            }}>
              <Sparkles size={24} color="#a855f7" />
            </div>
            <h3 style={{ fontSize: '1.15rem', fontWeight: 800, margin: '0 0 8px 0' }}>AI Health Agent</h3>
            <p style={{ fontSize: '0.88rem', color: '#94a3b8', margin: 0, lineHeight: 1.5 }}>
              Automated medical notes analysis, risk classification & emergency AI assistant assistance.
            </p>
          </div>

          <div className="glass-card" style={{ padding: '24px', borderRadius: '20px' }}>
            <div style={{
              width: '44px',
              height: '44px',
              borderRadius: '12px',
              background: 'rgba(59, 130, 246, 0.2)',
              border: '1px solid rgba(59, 130, 246, 0.4)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              marginBottom: '16px'
            }}>
              <Phone size={24} color="#3b82f6" />
            </div>
            <h3 style={{ fontSize: '1.15rem', fontWeight: 800, margin: '0 0 8px 0' }}>Guardian Telemetry</h3>
            <p style={{ fontSize: '0.88rem', color: '#94a3b8', margin: 0, lineHeight: 1.5 }}>
              Family members receive real-time status updates on emergency dispatch and caregiver reports.
            </p>
          </div>
        </div>

        {/* Quick Access / Portal Demo Shortcuts */}
        <div className="glass-card" style={{
          padding: '32px',
          borderRadius: '24px',
          border: '1px solid rgba(255, 255, 255, 0.15)',
          marginBottom: '40px'
        }}>
          <div style={{ textAlign: 'center', marginBottom: '24px' }}>
            <h3 style={{ fontSize: '1.35rem', fontWeight: 800, margin: '0 0 6px 0' }}>
              Direct Portal Quick Access
            </h3>
            <p style={{ fontSize: '0.88rem', color: '#94a3b8', margin: 0 }}>
              Select a portal role to jump directly into the CareConnect Website
            </p>
          </div>

          <div style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(170px, 1fr))',
            gap: '14px'
          }}>
            <button
              onClick={() => onDemoLogin('ashish@careconnect.org', 'resident123')}
              className="btn btn-secondary"
              style={{
                padding: '14px 16px',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                gap: '8px',
                borderColor: '#ef4444',
                background: 'rgba(239, 68, 68, 0.08)'
              }}
            >
              <Siren size={22} color="#ef4444" />
              <span style={{ fontSize: '0.9rem', fontWeight: 700, color: '#f8fafc' }}>Resident Portal</span>
              <span style={{ fontSize: '0.72rem', color: '#f87171' }}>Ashish (Flat 302-A)</span>
            </button>

            <button
              onClick={() => onDemoLogin('security@careconnect.org', 'sec123')}
              className="btn btn-secondary"
              style={{
                padding: '14px 16px',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                gap: '8px',
                borderColor: '#10b981',
                background: 'rgba(16, 185, 129, 0.08)'
              }}
            >
              <Shield size={22} color="#10b981" />
              <span style={{ fontSize: '0.9rem', fontWeight: 700, color: '#f8fafc' }}>Security Responder</span>
              <span style={{ fontSize: '0.72rem', color: '#34d399' }}>Officer Marcus</span>
            </button>

            <button
              onClick={() => onDemoLogin('guardian@careconnect.org', 'guard123')}
              className="btn btn-secondary"
              style={{
                padding: '14px 16px',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                gap: '8px',
                borderColor: '#3b82f6',
                background: 'rgba(59, 130, 246, 0.08)'
              }}
            >
              <Phone size={22} color="#3b82f6" />
              <span style={{ fontSize: '0.9rem', fontWeight: 700, color: '#f8fafc' }}>Guardian Portal</span>
              <span style={{ fontSize: '0.72rem', color: '#60a5fa' }}>Elena Rostova</span>
            </button>

            <button
              onClick={() => onDemoLogin('volunteer@careconnect.org', 'vol123')}
              className="btn btn-secondary"
              style={{
                padding: '14px 16px',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                gap: '8px',
                borderColor: '#f59e0b',
                background: 'rgba(245, 158, 11, 0.08)'
              }}
            >
              <Users size={22} color="#f59e0b" />
              <span style={{ fontSize: '0.9rem', fontWeight: 700, color: '#f8fafc' }}>Volunteer Portal</span>
              <span style={{ fontSize: '0.72rem', color: '#fbbf24' }}>Alex Rivera</span>
            </button>

            <button
              onClick={() => onDemoLogin('admin@careconnect.org', 'admin123')}
              className="btn btn-secondary"
              style={{
                padding: '14px 16px',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                gap: '8px',
                borderColor: '#8b5cf6',
                background: 'rgba(139, 92, 246, 0.08)'
              }}
            >
              <Activity size={22} color="#8b5cf6" />
              <span style={{ fontSize: '0.9rem', fontWeight: 700, color: '#f8fafc' }}>Admin Analytics</span>
              <span style={{ fontSize: '0.72rem', color: '#c084fc' }}>Dr. Sarah Jenkins</span>
            </button>
          </div>
        </div>

        {/* Footer */}
        <div style={{ textAlign: 'center', color: '#64748b', fontSize: '0.82rem' }}>
          CareConnect Portfolio Emergency Response System • Infosys Spring 7.0
        </div>
      </div>
    </div>
  );
}
