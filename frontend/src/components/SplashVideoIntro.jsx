import React, { useRef, useEffect } from 'react';
import { ArrowRight, HeartPulse, SkipForward, Volume2 } from 'lucide-react';

export default function SplashVideoIntro({ onComplete }) {
  const videoRef = useRef(null);

  useEffect(() => {
    const video = videoRef.current;
    if (!video) return;

    // 1. Ensure video autoplays smoothly on load without browser blocking/freezing
    video.muted = true;
    const playPromise = video.play();
    if (playPromise !== undefined) {
      playPromise.catch(err => console.warn("Autoplay start attempt:", err));
    }

    // 2. Unmute audio on user click, touch, or keypress (real user gestures recognized by browser)
    // CRITICAL: mousemove/pointermove are omitted because Chrome force-pauses video if unmuted on mousemove!
    const unlockSound = () => {
      if (videoRef.current) {
        videoRef.current.muted = false;
        videoRef.current.volume = 1.0;
        videoRef.current.play().catch(() => {});
      }
    };

    const gestureEvents = ['click', 'touchstart', 'keydown'];
    gestureEvents.forEach(evt => window.addEventListener(evt, unlockSound, { once: true }));

    // Safety timer: Auto-skip after 35s if video finishes or stalls
    const safetyTimer = setTimeout(() => {
      onComplete();
    }, 35000);

    return () => {
      clearTimeout(safetyTimer);
      gestureEvents.forEach(evt => window.removeEventListener(evt, unlockSound));
    };
  }, [onComplete]);

  const handleContainerClick = () => {
    if (videoRef.current) {
      videoRef.current.muted = false;
      videoRef.current.volume = 1.0;
      videoRef.current.play().catch(() => {});
    }
  };

  return (
    <div
      onClick={handleContainerClick}
      style={{
        position: 'fixed',
        inset: 0,
        width: '100vw',
        height: '100vh',
        zIndex: 999999,
        background: '#020617',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        overflow: 'hidden',
        cursor: 'pointer'
      }}
    >
      {/* Fullscreen Video */}
      <video
        ref={videoRef}
        autoPlay
        muted
        playsInline
        preload="auto"
        onEnded={onComplete}
        onError={() => {
          console.error("Intro video failed to load, skipping intro.");
          onComplete();
        }}
        style={{
          width: '100%',
          height: '100%',
          objectFit: 'cover'
        }}
      >
        <source src="/intro.mp4" type="video/mp4" />
        Your browser does not support HTML5 video.
      </video>

      {/* Top Gradient Overlay */}
      <div style={{
        position: 'absolute',
        top: 0,
        left: 0,
        right: 0,
        height: '140px',
        background: 'linear-gradient(to bottom, rgba(2, 6, 23, 0.85), transparent)',
        pointerEvents: 'none',
        zIndex: 2
      }} />

      {/* Bottom Gradient Overlay */}
      <div style={{
        position: 'absolute',
        bottom: 0,
        left: 0,
        right: 0,
        height: '160px',
        background: 'linear-gradient(to top, rgba(2, 6, 23, 0.95), transparent)',
        pointerEvents: 'none',
        zIndex: 2
      }} />

      {/* Top Left Branding Badge */}
      <div style={{
        position: 'absolute',
        top: '28px',
        left: '32px',
        zIndex: 10,
        display: 'flex',
        alignItems: 'center',
        gap: '12px',
        background: 'rgba(15, 23, 42, 0.85)',
        backdropFilter: 'blur(16px)',
        padding: '10px 22px',
        borderRadius: '9999px',
        border: '1px solid rgba(255, 255, 255, 0.15)',
        boxShadow: '0 8px 32px rgba(0,0,0,0.5)'
      }}>
        <div style={{
          width: '28px',
          height: '28px',
          borderRadius: '8px',
          background: 'linear-gradient(135deg, #ef4444 0%, #14b8a6 100%)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center'
        }}>
          <HeartPulse size={18} color="#ffffff" />
        </div>
        <span style={{ color: '#ffffff', fontWeight: 800, fontSize: '0.95rem', letterSpacing: '0.04em' }}>
          CareConnect Intro
        </span>
      </div>

      {/* Subtle Hint Badge */}
      <div style={{
        position: 'absolute',
        top: '28px',
        right: '32px',
        zIndex: 10,
        display: 'flex',
        alignItems: 'center',
        gap: '8px',
        background: 'rgba(15, 23, 42, 0.75)',
        backdropFilter: 'blur(12px)',
        padding: '8px 18px',
        borderRadius: '9999px',
        border: '1px solid rgba(255, 255, 255, 0.12)',
        color: '#14b8a6',
        fontSize: '0.85rem',
        fontWeight: 600,
        pointerEvents: 'none'
      }}>
        <Volume2 size={16} />
        <span>Click anywhere for sound</span>
      </div>

      {/* Bottom Right Buttons */}
      <div style={{
        position: 'absolute',
        bottom: '36px',
        right: '36px',
        zIndex: 10,
        display: 'flex',
        alignItems: 'center',
        gap: '14px'
      }}>
        {/* Skip Button */}
        <button
          onClick={(e) => {
            e.stopPropagation();
            onComplete();
          }}
          style={{
            background: 'rgba(30, 41, 59, 0.85)',
            backdropFilter: 'blur(12px)',
            color: '#94a3b8',
            border: '1px solid rgba(255, 255, 255, 0.15)',
            padding: '14px 24px',
            borderRadius: '9999px',
            fontSize: '0.95rem',
            fontWeight: 700,
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            transition: 'all 0.2s ease'
          }}
        >
          <SkipForward size={18} />
          <span>Skip Intro</span>
        </button>

        {/* Open Website Button */}
        <button
          onClick={(e) => {
            e.stopPropagation();
            onComplete();
          }}
          style={{
            background: 'linear-gradient(135deg, #ef4444 0%, #dc2626 100%)',
            color: '#ffffff',
            border: 'none',
            padding: '14px 32px',
            borderRadius: '9999px',
            fontSize: '1.05rem',
            fontWeight: 800,
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: '12px',
            boxShadow: '0 8px 32px rgba(239, 68, 68, 0.6)'
          }}
        >
          <span>Open Website</span>
          <ArrowRight size={20} />
        </button>
      </div>
    </div>
  );
}






