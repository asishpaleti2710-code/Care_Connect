import React, { useState } from 'react';
import { Users, Siren, ShieldCheck, PieChart, FileText, CheckCircle2, Clock, Activity, Filter, Search, Check, RefreshCw } from 'lucide-react';
import { api } from '../services/api';
import LoadingScreen from '../components/LoadingScreen';
import { usePolling } from '../hooks/usePolling';
import { matchesQuery } from '../utils/collections';
import { alertError, logError } from '../utils/errors';
import { IN_PROGRESS_INCIDENT_STATUSES, incidentBadgeClass } from '../utils/status';

export default function AdminDashboard({ user }) {
  const [analytics, setAnalytics] = useState(null);
  const [residents, setResidents] = useState([]);
  const [incidents, setIncidents] = useState([]);
  const [loading, setLoading] = useState(true);

  // Interactive Filter States
  const [incidentFilter, setIncidentFilter] = useState('all');
  const [categoryFilter, setCategoryFilter] = useState('all');
  const [userRoleFilter, setUserRoleFilter] = useState('all');
  const [searchQuery, setSearchQuery] = useState('');

  const loadAdminData = async () => {
    try {
      const [anData, resList, incList] = await Promise.all([
        api.getAnalytics(),
        api.getResidents(),
        api.getIncidents()
      ]);
      setAnalytics(anData);
      setResidents(resList);
      setIncidents(incList);
    } catch (err) {
      logError("Error loading admin analytics", err);
    } finally {
      setLoading(false);
    }
  };

  // High-frequency 2-second polling for real-time accuracy
  usePolling(loadAdminData, 2000);

  const handleResolveIncident = async (id) => {
    try {
      await api.updateIncidentStatus(id, "Resolved");
      await loadAdminData();
    } catch (err) {
      alertError("Error resolving incident", err);
    }
  };

  const handleAcceptIncident = async (id) => {
    try {
      await api.acceptIncident(id);
      await loadAdminData();
    } catch (err) {
      alertError("Error accepting incident", err);
    }
  };

  // Filtered Incidents based on selected tabs & search
  const filteredIncidents = incidents.filter(inc => {
    const matchesStatus = 
      incidentFilter === 'all' ? true :
      incidentFilter === 'pending' ? inc.status === 'Pending' :
      incidentFilter === 'active' ? IN_PROGRESS_INCIDENT_STATUSES.includes(inc.status) :
      incidentFilter === 'resolved' ? inc.status === 'Resolved' : true;

    const matchesCategory = 
      categoryFilter === 'all' ? true : inc.emergency_type === categoryFilter;

    const matchesSearch = matchesQuery(searchQuery, inc.incident_code, inc.description, inc.location);

    return matchesStatus && matchesCategory && matchesSearch;
  });

  // Filtered Residents
  const filteredResidents = residents.filter(r => {
    const matchesRole = 
      userRoleFilter === 'all' ? true :
      userRoleFilter === 'safe' ? r.status === 'safe' :
      userRoleFilter === 'emergency' ? r.status === 'emergency' :
      userRoleFilter === 'alert' ? r.status === 'alert' : true;

    const matchesSearch = matchesQuery(searchQuery, r.full_name, r.room_number);

    return matchesRole && matchesSearch;
  });

  if (loading) return <LoadingScreen message="Loading Admin Real-Time Center..." />;

  return (
    <main style={{ maxWidth: '1280px', margin: '0 auto', padding: '32px 24px' }}>
      
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '28px', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <h2 style={{ fontSize: '1.8rem', fontWeight: 800, margin: 0, color: '#f8fafc', display: 'flex', alignItems: 'center', gap: '10px' }}>
            <Activity size={28} color="#8b5cf6" /> Executive Real-Time Control Center
          </h2>
          <p style={{ color: '#94a3b8', margin: '4px 0 0 0', fontSize: '0.9rem' }}>
            Live emergency incident tracking, Category filter tabs & response metrics
          </p>
        </div>

        <button className="btn btn-secondary" onClick={loadAdminData}>
          <RefreshCw size={16} /> Force Sync Real-Time Data
        </button>
      </div>

      {/* Analytics Metric Cards (Live updating) */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '20px', marginBottom: '32px' }}>
        <div className="glass-card" style={{ padding: '22px' }}>
          <div style={{ color: '#94a3b8', fontSize: '0.8rem', fontWeight: 700 }}>TOTAL EMERGENCIES LOGGED</div>
          <div style={{ fontSize: '2.2rem', fontWeight: 800, color: '#f8fafc', marginTop: '6px' }}>{incidents.length}</div>
        </div>

        <div className="glass-card" style={{ padding: '22px' }}>
          <div style={{ color: '#10b981', fontSize: '0.8rem', fontWeight: 700 }}>RESOLVED INCIDENTS</div>
          <div style={{ fontSize: '2.2rem', fontWeight: 800, color: '#10b981', marginTop: '6px' }}>
            {incidents.filter(i => i.status === 'Resolved').length}
          </div>
        </div>

        <div className="glass-card" style={{ padding: '22px' }}>
          <div style={{ color: '#f59e0b', fontSize: '0.8rem', fontWeight: 700 }}>IN PROGRESS / PENDING</div>
          <div style={{ fontSize: '2.2rem', fontWeight: 800, color: '#f59e0b', marginTop: '6px' }}>
            {incidents.filter(i => i.status !== 'Resolved').length}
          </div>
        </div>

        <div className="glass-card" style={{ padding: '22px' }}>
          <div style={{ color: '#c084fc', fontSize: '0.8rem', fontWeight: 700 }}>AVG RESPONSE TIME</div>
          <div style={{ fontSize: '2.2rem', fontWeight: 800, color: '#c084fc', marginTop: '6px' }}>
            {analytics?.avg_response_time_minutes || 2.4} mins
          </div>
        </div>
      </div>

      {/* Main Interactive Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 2fr', gap: '28px', marginBottom: '32px' }}>
        
        {/* Interactive Category Filter Tabs Card */}
        <div className="glass-card" style={{ padding: '24px' }}>
          <h3 style={{ fontSize: '1.1rem', fontWeight: 800, color: '#f8fafc', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <PieChart size={18} color="#14b8a6" /> Category Filter Tabs
          </h3>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
            <button
              onClick={() => setCategoryFilter('all')}
              style={{
                display: 'flex',
                justify: 'space-between',
                padding: '10px 14px',
                borderRadius: '8px',
                border: categoryFilter === 'all' ? '1px solid #14b8a6' : '1px solid rgba(255,255,255,0.08)',
                background: categoryFilter === 'all' ? 'rgba(20, 184, 166, 0.15)' : 'rgba(15, 23, 42, 0.5)',
                color: categoryFilter === 'all' ? '#14b8a6' : '#cbd5e1',
                cursor: 'pointer',
                fontWeight: 600,
                fontSize: '0.88rem'
              }}
            >
              <span>All Emergency Categories</span>
              <span>{incidents.length}</span>
            </button>

            {Object.entries(analytics?.emergency_types || {}).map(([type, count]) => (
              <button
                key={type}
                onClick={() => setCategoryFilter(categoryFilter === type ? 'all' : type)}
                style={{
                  display: 'flex',
                  justify: 'space-between',
                  padding: '10px 14px',
                  borderRadius: '8px',
                  border: categoryFilter === type ? '1px solid #8b5cf6' : '1px solid rgba(255,255,255,0.08)',
                  background: categoryFilter === type ? 'rgba(139, 92, 246, 0.18)' : 'rgba(15, 23, 42, 0.5)',
                  color: categoryFilter === type ? '#c084fc' : '#cbd5e1',
                  cursor: 'pointer',
                  fontWeight: 600,
                  fontSize: '0.88rem',
                  textAlign: 'left'
                }}
              >
                <span>{type}</span>
                <span className="badge badge-safe" style={{ fontSize: '0.75rem' }}>{count} calls</span>
              </button>
            ))}
          </div>
        </div>

        {/* Interactive Incidents Roster & Action Tabs */}
        <div className="glass-card" style={{ padding: '24px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px', flexWrap: 'wrap', gap: '12px' }}>
            <h3 style={{ fontSize: '1.1rem', fontWeight: 800, color: '#f8fafc', margin: 0, display: 'flex', alignItems: 'center', gap: '8px' }}>
              <FileText size={18} color="#3b82f6" /> Executive Incident Audit Roster
            </h3>

            {/* Search Input */}
            <div style={{ position: 'relative', width: '220px' }}>
              <Search size={16} color="#64748b" style={{ position: 'absolute', left: '10px', top: '50%', transform: 'translateY(-50%)' }} />
              <input
                type="text"
                className="form-input"
                placeholder="Filter incidents..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                style={{ paddingLeft: '34px', padding: '6px 12px 6px 34px', fontSize: '0.8rem' }}
              />
            </div>
          </div>

          {/* Incident Status Filter Tabs */}
          <div style={{ display: 'flex', gap: '8px', marginBottom: '16px', overflowX: 'auto' }}>
            {[
              { id: 'all', label: `All (${incidents.length})` },
              { id: 'pending', label: `Pending (${incidents.filter(i => i.status === 'Pending').length})` },
              { id: 'active', label: `Accepted/In Progress (${incidents.filter(i => i.status === 'Accepted' || i.status === 'In Progress').length})` },
              { id: 'resolved', label: `Resolved (${incidents.filter(i => i.status === 'Resolved').length})` },
            ].map(tab => (
              <button
                key={tab.id}
                onClick={() => setIncidentFilter(tab.id)}
                style={{
                  background: incidentFilter === tab.id ? '#3b82f6' : 'rgba(30, 41, 59, 0.6)',
                  color: incidentFilter === tab.id ? '#ffffff' : '#94a3b8',
                  border: '1px solid rgba(255, 255, 255, 0.1)',
                  padding: '6px 14px',
                  borderRadius: '9999px',
                  fontSize: '0.8rem',
                  fontWeight: 600,
                  cursor: 'pointer',
                  whiteSpace: 'nowrap'
                }}
              >
                {tab.label}
              </button>
            ))}
          </div>

          {/* Incidents List */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
            {filteredIncidents.length === 0 ? (
              <div style={{ padding: '30px', textAlign: 'center', color: '#94a3b8', fontSize: '0.88rem' }}>
                No incidents match the selected filter criteria.
              </div>
            ) : (
              filteredIncidents.map(inc => (
                <div key={inc.id} style={{
                  background: 'rgba(15, 23, 42, 0.6)',
                  border: '1px solid rgba(255, 255, 255, 0.08)',
                  borderRadius: '10px',
                  padding: '14px 18px',
                  display: 'flex',
                  justify: 'space-between',
                  alignItems: 'center',
                  flexWrap: 'wrap',
                  gap: '12px'
                }}>
                  <div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <strong style={{ color: '#f8fafc', fontSize: '0.95rem' }}>{inc.incident_code}</strong>
                      <span className={incidentBadgeClass(inc.status)}>
                        {inc.status}
                      </span>
                      <span style={{ fontSize: '0.78rem', color: '#94a3b8' }}>• {inc.emergency_type}</span>
                    </div>

                    <p style={{ color: '#cbd5e1', fontSize: '0.85rem', margin: '4px 0 0 0' }}>{inc.description}</p>
                    
                    {inc.responder_name && (
                      <div style={{ color: '#10b981', fontSize: '0.78rem', marginTop: '4px', fontWeight: 600 }}>
                        Assigned Responder: {inc.responder_name} ({inc.responder_role})
                      </div>
                    )}
                  </div>

                  {/* Quick Admin Actions */}
                  <div style={{ display: 'flex', gap: '8px' }}>
                    {inc.status === 'Pending' && (
                      <button className="btn btn-primary" style={{ padding: '6px 12px', fontSize: '0.78rem' }} onClick={() => handleAcceptIncident(inc.id)}>
                        Accept
                      </button>
                    )}
                    {inc.status !== 'Resolved' && (
                      <button className="btn btn-secondary" style={{ padding: '6px 12px', fontSize: '0.78rem', borderColor: '#10b981', color: '#10b981' }} onClick={() => handleResolveIncident(inc.id)}>
                        <Check size={14} /> Resolve
                      </button>
                    )}
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

      </div>

      {/* Registered Residents & Status Roster */}
      <div className="glass-card" style={{ padding: '24px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px', flexWrap: 'wrap', gap: '12px' }}>
          <h3 style={{ fontSize: '1.1rem', fontWeight: 800, color: '#f8fafc', margin: 0, display: 'flex', alignItems: 'center', gap: '8px' }}>
            <Users size={18} color="#f59e0b" /> Registered Residents Roster ({filteredResidents.length})
          </h3>

          {/* User Status Filter Tabs */}
          <div style={{ display: 'flex', gap: '8px' }}>
            {['all', 'safe', 'alert', 'emergency'].map(st => (
              <button
                key={st}
                onClick={() => setUserRoleFilter(st)}
                style={{
                  background: userRoleFilter === st ? '#14b8a6' : 'rgba(30, 41, 59, 0.6)',
                  color: userRoleFilter === st ? '#ffffff' : '#94a3b8',
                  border: '1px solid rgba(255, 255, 255, 0.1)',
                  padding: '4px 12px',
                  borderRadius: '9999px',
                  fontSize: '0.78rem',
                  fontWeight: 600,
                  textTransform: 'capitalize',
                  cursor: 'pointer'
                }}
              >
                {st}
              </button>
            ))}
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: '16px' }}>
          {filteredResidents.map(r => (
            <div key={r.id} style={{ background: 'rgba(15, 23, 42, 0.6)', padding: '14px', borderRadius: '10px', border: '1px solid rgba(255, 255, 255, 0.08)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <strong style={{ color: '#f8fafc' }}>{r.full_name}</strong>
                <span className={`badge badge-${r.status}`}>{r.status}</span>
              </div>
              <p style={{ color: '#94a3b8', fontSize: '0.8rem', margin: '6px 0 0 0' }}>
                Age {r.age} • Blood {r.blood_group} • Room {r.room_number}
              </p>
              <div style={{ color: '#cbd5e1', fontSize: '0.78rem', marginTop: '4px' }}>
                📍 {r.address || `Building A, Room ${r.room_number}`}
              </div>
            </div>
          ))}
        </div>
      </div>
    </main>
  );
}
