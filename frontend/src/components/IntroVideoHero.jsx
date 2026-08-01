import React, { useState } from 'react';
import { Play, Volume2, VolumeX, HeartPulse, ShieldAlert, Sparkles, X, ChevronDown } from 'lucide-react';

export default function IntroVideoHero({ onSkip }) {
  const [isMuted, setIsMuted] = useState(true);

  return (
    <div style={{
      position: 'relative',
      width: '100%',
      marginBottom: '28px',
      borderRadius: '24px',
      overflow: 'hidden',
      border: '1px solid rgba(255, 255, 255, 0.15)',
      boxShadow: '0 12px 40px rgba(0, 0, 0, 0.6)',
      background: '#0f172a'
    }}>
      {/* Video Player */}
      <div style={{ position: 'relative', width: '100%', height: '380px', overflow: 'hidden' }}>
        <video
          autoPlay
          loop
          muted={isMuted}
          playsInline
          style={{
            width: '100%',
            height: '100%',
            objectFit: 'cover',
            /* Slight scale & top-left origin to crop out watermark */
            transform: 'scale(1.08)',
            transformOrigin: 'top left',
            filter: 'brightness(0.75) contrast(1.1)'
          }}
        >
          <source src="/intro.mp4" type="video/mp4" />
          Your browser does not support the video tag.
        </video>

        {/* Gradient Overlay for Readable Text */}
        <div style={{
          position: 'absolute',
          inset: 0,
          background: 'linear-gradient(180deg, rgba(15, 23, 42, 0.4) 0%, rgba(15, 23, 42, 0.95) 100%)',
          zIndex: 2
        }} />

        {/* Watermark Cover Badge in Bottom Right Corner */}
        <div style={{
          position: 'absolute',
          bottom: 0,
          right: 0,
          width: '160px',
          height: '60px',
          background: 'rgba(15, 23, 42, 0.98)',
          backdropFilter: 'blur(16px)',
          borderTopLeftRadius: '20px',
          borderLeft: '1px solid rgba(255, 255, 255, 0.1)',
          borderTop: '1px solid rgba(255, 255, 255, 0.1)',
          zIndex: 10,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          gap: '8px'
        }}>
          <HeartPulse size={18} color="#ef4444" />
          <span style={{ fontSize: '0.75rem', fontWeight: 800, color: '#f8fafc', letterSpacing: '0.05em' }}>
            CareConnect
          </span>
        </div>

        {/* Hero Overlay Content */}
        <div style={{
          position: 'absolute',
          inset: 0,
          zIndex: 5,
          padding: '32px 40px',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'space-between'
        }}>
          {/* Top Bar Controls */}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '8px',
              background: 'rgba(239, 68, 68, 0.25)',
              border: '1px solid rgba(239, 68, 68, 0.4)',
              padding: '6px 14px',
              borderRadius: '9999px',
              fontSize: '0.8rem',
              fontWeight: 700,
              color: '#f87171',
              textTransform: 'uppercase',
              letterSpacing: '0.05em'
            }}>
              <ShieldAlert size={14} /> Official Platform Intro
            </div>

            <div style={{ display: 'flex', gap: '10px' }}>
              <button
                onClick={() => setIsMuted(!isMuted)}
                className="btn btn-secondary"
                style={{ background: 'rgba(0, 0, 0, 0.5)', padding: '8px 14px', fontSize: '0.8rem' }}
              >
                {isMuted ? <VolumeX size={16} /> : <Volume2 size={16} />}
                <span>{isMuted ? 'Unmute' : 'Mute'}</span>
              </button>
              {onSkip && (
                <button
                  onClick={onSkip}
                  className="btn btn-secondary"
                  style={{ background: 'rgba(0, 0, 0, 0.5)', padding: '8px 14px', fontSize: '0.8rem' }}
                >
                  <span>Hide Intro</span>
                  <ChevronDown size={16} />
                </button>
              )}
            </div>
          </div>

          {/* Bottom Title & Tagline */}
          <div>
            <h2 style={{
              fontSize: '2.2rem',
              fontWeight: 900,
              color: '#ffffff',
              margin: '0 0 8px 0',
              textShadow: '0 2px 10px rgba(0,0,0,0.8)',
              display: 'flex',
              alignItems: 'center',
              gap: '12px'
            }}>
              CareConnect Emergency System
            </h2>
            <p style={{
              fontSize: '1rem',
              color: '#cbd5e1',
              margin: 0,
              maxWidth: '680px',
              lineHeight: 1.5,
              textShadow: '0 2px 8px rgba(0,0,0,0.8)'
            }}>
              Real-time senior safety tracking, automatic SOS panic dispatch, 5-role responder workflow & AI-powered medical intelligence.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
