import React, { useState, useEffect } from 'react';
import { Activity, Heart, ShieldAlert, Zap, Radio, BatteryCharging } from 'lucide-react';
import { useLanguage } from '../context/LanguageContext';

export default function SensorTelemetryWidget({ onSimulateEmergency }) {
  const { t } = useLanguage();
  const [bpm, setBpm] = useState(74);
  const [motionStatus, setMotionStatus] = useState('Active / Stable');
  const [isSimulating, setIsSimulating] = useState(false);

  // Live BPM pulse simulation
  useEffect(() => {
    const interval = setInterval(() => {
      setBpm(prev => {
        const delta = Math.floor(Math.random() * 5) - 2;
        const newBpm = prev + delta;
        return newBpm < 68 ? 70 : newBpm > 85 ? 78 : newBpm;
      });
    }, 2500);
    return () => clearInterval(interval);
  }, []);

  const triggerFallSimulation = async () => {
    setIsSimulating(true);
    setMotionStatus('🚨 SUDDEN IMPACT / FALL DETECTED');
    setBpm(132);

    if (onSimulateEmergency) {
      await onSimulateEmergency({
        type: 'Fall Incident',
        priority: 'High',
        description: 'AUTOMATED IOT SENSOR ALERT: Sudden acceleration drop detected by CareConnect Smart Wristband #772. Resident may be unresponsive.'
      });
    }

    setTimeout(() => {
      setMotionStatus('Active / Stable');
      setBpm(74);
      setIsSimulating(false);
    }, 6000);
  };

  const triggerPulseSimulation = async () => {
    setIsSimulating(true);
    setBpm(168);
    setMotionStatus('⚠️ Cardiac Anomaly / High Heart Rate');

    if (onSimulateEmergency) {
      await onSimulateEmergency({
        type: 'Cardiac Anomaly',
        priority: 'Critical',
        description: 'AUTOMATED IOT SENSOR ALERT: Sustained pulse rate spike (168 BPM) detected by CareConnect Smart Wristband #772.'
      });
    }

    setTimeout(() => {
      setMotionStatus('Active / Stable');
      setBpm(74);
      setIsSimulating(false);
    }, 6000);
  };

  return (
    <div className="glass-card" style={{
      padding: '20px',
      background: 'linear-gradient(135deg, rgba(15, 23, 42, 0.95) 0%, rgba(30, 41, 59, 0.9) 100%)',
      border: '1px solid rgba(20, 184, 166, 0.3)',
      boxShadow: '0 8px 24px rgba(0,0,0,0.4)',
      marginBottom: '28px'
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px', flexWrap: 'wrap', gap: '10px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <div style={{
            width: '36px',
            height: '36px',
            borderRadius: '10px',
            background: 'rgba(20, 184, 166, 0.2)',
            border: '1px solid #14b8a6',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center'
          }}>
            <Activity size={20} color="#14b8a6" />
          </div>
          <div>
            <h4 style={{ fontSize: '1rem', fontWeight: 800, margin: 0, color: '#f8fafc' }}>
              {t('sensorTelemetry')}
            </h4>
            <span style={{ fontSize: '0.72rem', color: '#94a3b8' }}>
              IoT Band #772 • Bluetooth LE Active
            </span>
          </div>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <span style={{ fontSize: '0.75rem', color: '#10b981', background: 'rgba(16, 185, 129, 0.15)', padding: '3px 10px', borderRadius: '9999px', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '4px' }}>
            <Radio size={12} className="spin" /> Live Telemetry
          </span>
          <span style={{ fontSize: '0.75rem', color: '#cbd5e1', display: 'flex', alignItems: 'center', gap: '4px' }}>
            <BatteryCharging size={14} color="#10b981" /> 94%
          </span>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1.2fr', gap: '14px', alignItems: 'center' }}>
        {/* Heart Rate Block */}
        <div style={{
          background: 'rgba(15, 23, 42, 0.6)',
          padding: '12px 16px',
          borderRadius: '12px',
          border: '1px solid rgba(255, 255, 255, 0.08)',
          display: 'flex',
          alignItems: 'center',
          gap: '12px'
        }}>
          <Heart size={28} color="#ef4444" style={{ animation: 'pulse-sos 1s infinite' }} />
          <div>
            <div style={{ fontSize: '1.4rem', fontWeight: 900, color: bpm > 140 ? '#ef4444' : '#f8fafc' }}>
              {bpm} <span style={{ fontSize: '0.8rem', fontWeight: 600, color: '#94a3b8' }}>BPM</span>
            </div>
            <div style={{ fontSize: '0.72rem', color: bpm > 140 ? '#ef4444' : '#10b981', fontWeight: 700 }}>
              {bpm > 140 ? 'CRITICAL SPIKE' : 'Normal Resting Rate'}
            </div>
          </div>
        </div>

        {/* Fall Detection Block */}
        <div style={{
          background: 'rgba(15, 23, 42, 0.6)',
          padding: '12px 16px',
          borderRadius: '12px',
          border: '1px solid rgba(255, 255, 255, 0.08)'
        }}>
          <div style={{ fontSize: '0.75rem', color: '#94a3b8', fontWeight: 700, textTransform: 'uppercase', marginBottom: '4px' }}>
            Accelerometer / Gyro
          </div>
          <div style={{ fontSize: '0.88rem', fontWeight: 800, color: motionStatus.includes('SUDDEN') ? '#ef4444' : '#14b8a6' }}>
            {motionStatus}
          </div>
        </div>

        {/* Simulator Controls */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
          <button
            onClick={triggerFallSimulation}
            disabled={isSimulating}
            className="btn btn-secondary"
            style={{
              background: 'rgba(239, 68, 68, 0.18)',
              borderColor: 'rgba(239, 68, 68, 0.4)',
              color: '#f87171',
              fontSize: '0.78rem',
              padding: '6px 12px',
              fontWeight: 700,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '6px'
            }}
          >
            <ShieldAlert size={14} />
            <span>{t('simulateFall')}</span>
          </button>

          <button
            onClick={triggerPulseSimulation}
            disabled={isSimulating}
            className="btn btn-secondary"
            style={{
              background: 'rgba(245, 158, 11, 0.18)',
              borderColor: 'rgba(245, 158, 11, 0.4)',
              color: '#fbbf24',
              fontSize: '0.78rem',
              padding: '6px 12px',
              fontWeight: 700,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '6px'
            }}
          >
            <Zap size={14} />
            <span>{t('simulatePulseSpike')}</span>
          </button>
        </div>
      </div>
    </div>
  );
}
