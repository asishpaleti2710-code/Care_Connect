import React from 'react';
import { AlertTriangle, CheckCircle, BellRing } from 'lucide-react';

export default function SOSBanner({ alerts, residentsMap, onResolve }) {
  const activeAlerts = alerts.filter(a => a.status === 'active');

  if (activeAlerts.length === 0) return null;

  return (
    <div style={{
      background: 'linear-gradient(90deg, rgba(239, 68, 68, 0.95) 0%, rgba(185, 28, 28, 0.95) 100%)',
      color: '#ffffff',
      padding: '14px 24px',
      borderBottom: '2px solid rgba(255, 255, 255, 0.2)',
      boxShadow: '0 4px 20px rgba(239, 68, 68, 0.5)',
      display: 'flex',
      flexDirection: 'column',
      gap: '10px'
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
        <BellRing size={24} style={{ animation: 'bounce 1s infinite' }} />
        <h3 style={{ margin: 0, fontSize: '1.1rem', fontWeight: 800 }}>
          CRITICAL EMERGENCY ALERT ({activeAlerts.length} ACTIVE)
        </h3>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
        {activeAlerts.map(alert => {
          const resident = residentsMap[alert.resident_id];
          return (
            <div key={alert.id} style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              background: 'rgba(0, 0, 0, 0.25)',
              padding: '10px 16px',
              borderRadius: '8px',
              border: '1px solid rgba(255, 255, 255, 0.2)'
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                <AlertTriangle size={20} color="#fbbf24" />
                <div>
                  <strong>{resident ? resident.full_name : `Resident #${alert.resident_id}`}</strong> (Room {resident ? resident.room_number : 'N/A'})
                  <span style={{ margin: '0 8px', opacity: 0.8 }}>—</span>
                  <span>{alert.message}</span>
                </div>
              </div>

              <button
                className="btn btn-secondary"
                onClick={() => onResolve(alert.id)}
                style={{
                  background: '#ffffff',
                  color: '#dc2626',
                  fontWeight: 700,
                  fontSize: '0.85rem',
                  padding: '6px 14px'
                }}
              >
                <CheckCircle size={16} />
                <span>Resolve Alert</span>
              </button>
            </div>
          );
        })}
      </div>
    </div>
  );
}
