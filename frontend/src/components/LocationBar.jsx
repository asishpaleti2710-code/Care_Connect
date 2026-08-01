import React, { useState } from 'react';
import { MapPin, Navigation, RefreshCw, AlertCircle, CheckCircle2, ChevronDown } from 'lucide-react';
import { useGeolocation } from '../hooks/useGeolocation';
import { useLanguage } from '../context/LanguageContext';

export default function LocationBar() {
  const geo = useGeolocation();
  const { t } = useLanguage();
  const [showDetails, setShowDetails] = useState(false);

  const getStatusColor = () => {
    if (geo.loading) return '#f59e0b';
    if (geo.permission === 'granted' && geo.lat) return '#10b981';
    if (geo.permission === 'denied' || geo.error) return '#ef4444';
    return '#3b82f6';
  };

  return (
    <div style={{ position: 'relative', display: 'inline-block' }}>
      <div 
        onClick={() => setShowDetails(!showDetails)}
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: '8px',
          background: 'rgba(15, 23, 42, 0.7)',
          border: `1px solid ${getStatusColor()}50`,
          borderRadius: '9999px',
          padding: '6px 14px',
          fontSize: '0.82rem',
          fontWeight: 600,
          color: '#f8fafc',
          cursor: 'pointer',
          boxShadow: '0 2px 10px rgba(0, 0, 0, 0.2)',
          transition: 'all 0.2s ease'
        }}
      >
        <span style={{
          width: '8px',
          height: '8px',
          borderRadius: '50%',
          background: getStatusColor(),
          boxShadow: `0 0 8px ${getStatusColor()}`
        }} />

        <MapPin size={14} color={getStatusColor()} />

        <span style={{ maxWidth: '180px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
          {geo.loading ? t('locating') : geo.address ? geo.address : geo.lat ? `${geo.lat.toFixed(3)}, ${geo.lng.toFixed(3)}` : t('locationOff')}
        </span>

        {geo.accuracy && (
          <span style={{ fontSize: '0.72rem', color: '#94a3b8', background: 'rgba(255, 255, 255, 0.08)', padding: '1px 6px', borderRadius: '4px' }}>
            ±{geo.accuracy}m
          </span>
        )}

        <ChevronDown size={14} color="#94a3b8" style={{ transform: showDetails ? 'rotate(180deg)' : 'none', transition: 'transform 0.2s' }} />
      </div>

      {/* Popover / Dropdown Details */}
      {showDetails && (
        <div style={{
          position: 'absolute',
          top: 'calc(100% + 8px)',
          right: 0,
          width: '280px',
          background: '#1e293b',
          border: '1px solid rgba(255, 255, 255, 0.15)',
          borderRadius: '12px',
          padding: '16px',
          boxShadow: '0 10px 30px rgba(0,0,0,0.5)',
          zIndex: 1000,
          fontSize: '0.85rem'
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
            <span style={{ fontWeight: 700, color: '#f8fafc', display: 'flex', alignItems: 'center', gap: '6px' }}>
              <Navigation size={16} color="#14b8a6" /> {t('locationStatus')}
            </span>
            <span style={{
              fontSize: '0.75rem',
              fontWeight: 700,
              color: getStatusColor(),
              textTransform: 'uppercase',
              background: `${getStatusColor()}20`,
              padding: '2px 8px',
              borderRadius: '4px'
            }}>
              {geo.permission === 'granted' ? 'Active' : geo.permission}
            </span>
          </div>

          {geo.error && (
            <div style={{ background: 'rgba(239, 68, 68, 0.15)', border: '1px solid rgba(239, 68, 68, 0.3)', color: '#f87171', padding: '8px 10px', borderRadius: '6px', fontSize: '0.78rem', marginBottom: '10px' }}>
              ⚠️ {geo.error}
            </div>
          )}

          <div style={{ display: 'flex', flexDirection: 'column', gap: '6px', color: '#cbd5e1', marginBottom: '14px', fontSize: '0.8rem' }}>
            <div><strong>{t('addressLabel')}</strong> {geo.address || 'Not resolved'}</div>
            {geo.lat && (
              <>
                <div><strong>{t('coordinatesLabel')}</strong> {geo.lat.toFixed(5)}, {geo.lng.toFixed(5)}</div>
                <div><strong>{t('accuracyLabel')}</strong> ±{geo.accuracy}m</div>
              </>
            )}
          </div>

          <button
            onClick={() => { geo.requestLocation(); }}
            disabled={geo.loading}
            className="btn btn-primary"
            style={{ width: '100%', padding: '8px', fontSize: '0.82rem' }}
          >
            <RefreshCw size={14} className={geo.loading ? 'spin' : ''} />
            <span>{geo.lat ? t('refreshLocation') : t('enableLocation')}</span>
          </button>
        </div>
      )}
    </div>
  );
}
