import React from 'react';
import { AlertTriangle } from 'lucide-react';

export default function LoadErrorBanner({ message, onRetry }) {
  if (!message) return null;
  return (
    <div
      role="alert"
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: '10px',
        background: 'rgba(239, 68, 68, 0.12)',
        border: '1px solid rgba(239, 68, 68, 0.4)',
        color: '#f87171',
        borderRadius: '10px',
        padding: '10px 14px',
        marginBottom: '20px',
        fontSize: '0.85rem',
        fontWeight: 600
      }}
    >
      <AlertTriangle size={16} style={{ flexShrink: 0 }} />
      <span style={{ flex: 1 }}>Failed to load live data: {message}</span>
      {onRetry && (
        <button
          onClick={onRetry}
          className="btn btn-secondary"
          style={{
            padding: '4px 12px',
            fontSize: '0.78rem',
            background: 'rgba(239, 68, 68, 0.15)',
            borderColor: 'rgba(239, 68, 68, 0.4)',
            color: '#f87171'
          }}
        >
          Retry
        </button>
      )}
    </div>
  );
}
