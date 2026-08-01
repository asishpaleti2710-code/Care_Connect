import React, { useState, useEffect } from 'react';
import { ShieldCheck, Siren, PhoneCall, Heart, Clock, MapPin } from 'lucide-react';
import { api } from '../services/api';

export default function GuardianDashboard({ user }) {
  const [resident, setResident] = useState(null);
  const [incidents, setIncidents] = useState([]);
  const [loading, setLoading] = useState(true);

  const loadData = async () => {
    try {
      const resList = await api.getResidents();
      // Find Eleanor Vance or first resident linked to guardian demo
      let res = resList.find(r => r.full_name === "Ashish" || r.full_name === "Eleanor Vance");
      if (!res && resList.length > 0) res = resList[0];

      setResident(res);

      if (res) {
        const incList = await api.getIncidents();
        setIncidents(incList.filter(i => i.resident_id === res.id));
      }
    } catch (err) {
      console.error("Error loading guardian data:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
    const interval = setInterval(loadData, 5000);
    return () => clearInterval(interval);
  }, []);

  if (loading) return <div style={{ textAlign: 'center', padding: '60px', color: '#94a3b8' }}>Loading Guardian Portal...</div>;

  return (
    <main style={{ maxWidth: '1100px', margin: '0 auto', padding: '32px 24px' }}>
      
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '28px' }}>
        <div>
          <h2 style={{ fontSize: '1.8rem', fontWeight: 800, margin: 0, color: '#f8fafc' }}>
            Family & Guardian Portal
          </h2>
          <p style={{ color: '#94a3b8', margin: '4px 0 0 0', fontSize: '0.9rem' }}>
            Monitoring linked family resident • Logged in as: <strong style={{ color: '#14b8a6' }}>{user.full_name}</strong>
          </p>
        </div>
      </div>

      {/* Linked Resident Card */}
      {resident ? (
        <div className="glass-card" style={{ padding: '28px', marginBottom: '32px', borderLeft: `6px solid ${resident.status === 'emergency' ? '#ef4444' : resident.status === 'alert' ? '#f59e0b' : '#10b981'}` }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '16px' }}>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '8px' }}>
                <h3 style={{ fontSize: '1.5rem', fontWeight: 800, margin: 0, color: '#f8fafc' }}>{resident.full_name}</h3>
                <span className={`badge badge-${resident.status}`}>{resident.status}</span>
              </div>
              <p style={{ color: '#94a3b8', margin: 0, fontSize: '0.9rem' }}>
                Age {resident.age} • Blood Group: <strong style={{ color: '#14b8a6' }}>{resident.blood_group}</strong> • Location: <strong>{resident.address || `Room ${resident.room_number}`}</strong>
              </p>
            </div>

            <a href={`tel:${resident.emergency_contact}`} className="btn btn-primary" style={{ textDecoration: 'none' }}>
              <PhoneCall size={18} />
              <span>Call Resident ({resident.emergency_contact})</span>
            </a>
          </div>

          <div style={{ marginTop: '20px', paddingTop: '16px', borderTop: '1px solid rgba(255, 255, 255, 0.08)' }}>
            <span style={{ fontSize: '0.8rem', color: '#94a3b8', textTransform: 'uppercase', fontWeight: 700, display: 'block', marginBottom: '4px' }}>
              Medical Notes & Condition:
            </span>
            <div style={{ background: 'rgba(15, 23, 42, 0.6)', padding: '12px', borderRadius: '8px', color: '#e2e8f0', fontSize: '0.88rem' }}>
              {resident.medical_notes || 'No critical medical conditions recorded.'}
            </div>
          </div>
        </div>
      ) : (
        <div className="glass-card" style={{ padding: '40px', textAlign: 'center', color: '#94a3b8' }}>
          No resident linked to guardian account.
        </div>
      )}

      {/* Incident History & Live Alerts */}
      <div className="glass-card" style={{ padding: '28px' }}>
        <h3 style={{ fontSize: '1.2rem', fontWeight: 800, color: '#f8fafc', marginBottom: '18px', display: 'flex', alignItems: 'center', gap: '8px' }}>
          <Clock size={20} color="#f59e0b" /> Real-time Emergency Incident Notifications
        </h3>

        {incidents.length === 0 ? (
          <p style={{ color: '#94a3b8', margin: 0 }}>No emergency incidents reported for your linked resident.</p>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            {incidents.map(inc => (
              <div key={inc.id} style={{ background: 'rgba(15, 23, 42, 0.6)', border: '1px solid rgba(255, 255, 255, 0.08)', borderRadius: '12px', padding: '16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <strong style={{ color: '#f8fafc' }}>{inc.incident_code}</strong>
                    <span className={`badge badge-${inc.status === 'Resolved' ? 'safe' : inc.status === 'Pending' ? 'emergency' : 'alert'}`}>
                      {inc.status}
                    </span>
                    <span style={{ color: '#94a3b8', fontSize: '0.8rem' }}>• {inc.emergency_type} ({inc.priority} Priority)</span>
                  </div>
                  <p style={{ color: '#cbd5e1', fontSize: '0.88rem', margin: '6px 0 0 0' }}>{inc.description}</p>
                  {inc.responder_name && (
                    <span style={{ fontSize: '0.8rem', color: '#10b981', display: 'block', marginTop: '4px' }}>
                      ✓ Responder Assigned: {inc.responder_name} ({inc.responder_role})
                    </span>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </main>
  );
}
