import React, { useState, useEffect } from 'react';
import { 
  HeartHandshake, 
  ShieldAlert, 
  MapPin, 
  CheckCircle2, 
  Clock, 
  Navigation, 
  Compass, 
  Users, 
  PhoneCall,
  Siren,
  Sparkles
} from 'lucide-react';
import { api } from '../services/api';
import { useGeolocation } from '../hooks/useGeolocation';
import RealisticMap from '../components/RealisticMap';
import LoadErrorBanner from '../components/LoadErrorBanner';
import { useLanguage } from '../context/LanguageContext';

export default function NeighborDashboard({ user }) {
  const { t } = useLanguage();
  const [incidents, setIncidents] = useState([]);
  const [residentsMap, setResidentsMap] = useState({});
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState(null);
  const [respondingId, setRespondingId] = useState(null);

  const geo = useGeolocation();

  const loadData = async () => {
    try {
      const [incList, resList] = await Promise.all([
        api.getIncidents(),
        api.getResidents()
      ]);
      setIncidents(incList);
      const rMap = resList.reduce((acc, r) => {
        acc[r.id] = r;
        return acc;
      }, {});
      setResidentsMap(rMap);
      setLoadError(null);
    } catch (err) {
      console.error("Error loading neighbor emergency feed:", err);
      setLoadError(err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
    const timer = setInterval(loadData, 5000);
    return () => clearInterval(timer);
  }, []);

  const handleNeighborRespond = async (incidentId) => {
    setRespondingId(incidentId);
    try {
      await api.updateIncidentStatus(incidentId, 'Accepted', user.full_name, 'Community Neighbor Responder');
      await loadData();
    } catch (err) {
      alert("Error offering neighbor help: " + err.message);
    } finally {
      setRespondingId(null);
    }
  };

  const activeNeighborhoodAlerts = incidents.filter(i => i.status !== 'Resolved');
  const neighborOrigin = {
    lat: geo.lat || 28.6139,
    lng: geo.lng || 77.2090,
    title: `${user.full_name} (Neighbor #304)`,
    address: geo.address || 'Neighbor Local Apartment #304'
  };

  const mapMarkers = activeNeighborhoodAlerts.map(inc => {
    const res = residentsMap[inc.resident_id];
    return {
      lat: (geo.lat || 28.6139) + (Math.random() * 0.003 - 0.0015),
      lng: (geo.lng || 77.2090) + (Math.random() * 0.003 - 0.0015),
      title: res ? `SOS: ${res.full_name}` : inc.incident_code,
      description: `Emergency: ${inc.description}`,
      type: 'sos',
      status: inc.status
    };
  });

  if (loading) return <div style={{ textAlign: 'center', padding: '60px', color: '#94a3b8' }}>Loading Neighbor Emergency Network...</div>;

  return (
    <main style={{ maxWidth: '1280px', margin: '0 auto', padding: '28px 24px' }}>

      <LoadErrorBanner message={loadError} onRetry={loadData} />
      
      {/* Header Motto Banner */}
      <div className="glass-card" style={{
        padding: '24px 28px',
        marginBottom: '28px',
        background: 'linear-gradient(135deg, rgba(20, 184, 166, 0.2) 0%, rgba(15, 23, 42, 0.9) 100%)',
        border: '1px solid rgba(20, 184, 166, 0.4)',
        display: 'flex',
        justify: 'space-between',
        alignItems: 'center',
        flexWrap: 'wrap',
        gap: '16px'
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div style={{
            width: '52px',
            height: '52px',
            borderRadius: '16px',
            background: 'linear-gradient(135deg, #14b8a6 0%, #0d9488 100%)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            boxShadow: '0 0 20px rgba(20, 184, 166, 0.4)'
          }}>
            <HeartHandshake size={30} color="#ffffff" />
          </div>
          <div>
            <h2 style={{ fontSize: '1.6rem', fontWeight: 800, margin: 0, color: '#f8fafc' }}>
              Neighborhood First Responder Network
            </h2>
            <p style={{ color: '#14b8a6', margin: '4px 0 0 0', fontSize: '0.92rem', fontWeight: 700 }}>
              "Every Second Matters. Every Neighbor Can Help."
            </p>
          </div>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <span style={{ background: 'rgba(239, 68, 68, 0.2)', color: '#f87171', border: '1px solid rgba(239, 68, 68, 0.4)', padding: '6px 14px', borderRadius: '9999px', fontSize: '0.85rem', fontWeight: 800 }}>
            🚨 {activeNeighborhoodAlerts.length} Active Local Emergencies
          </span>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 340px', gap: '28px' }}>
        
        {/* LEFT COLUMN: ACTIVE NEIGHBORHOOD SOS ALERTS */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          <h3 style={{ fontSize: '1.2rem', fontWeight: 800, color: '#f8fafc', margin: 0, display: 'flex', alignItems: 'center', gap: '8px' }}>
            <Siren size={20} color="#ef4444" /> Nearby Resident Emergency Broadcasts
          </h3>

          {activeNeighborhoodAlerts.length === 0 ? (
            <div className="glass-card" style={{ padding: '48px', textAlign: 'center', color: '#94a3b8' }}>
              🎉 No active emergency calls in your immediate neighborhood. All residents are safe!
            </div>
          ) : (
            activeNeighborhoodAlerts.map(inc => {
              const res = residentsMap[inc.resident_id];
              const isIResponding = inc.responder_name === user.full_name;

              return (
                <div key={inc.id} className="glass-card" style={{
                  padding: '24px',
                  borderLeft: `6px solid ${inc.priority === 'Critical' ? '#ef4444' : '#f59e0b'}`,
                  background: 'rgba(15, 23, 42, 0.88)'
                }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '12px', flexWrap: 'wrap', gap: '12px' }}>
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '6px' }}>
                        <span style={{ fontSize: '1.15rem', fontWeight: 800, color: '#f8fafc' }}>{inc.incident_code}</span>
                        <span className={`badge badge-${inc.status === 'Resolved' ? 'safe' : inc.status === 'Pending' ? 'emergency' : 'alert'}`}>
                          {inc.status}
                        </span>
                        <span style={{ fontSize: '0.78rem', color: '#14b8a6', background: 'rgba(20, 184, 166, 0.15)', padding: '2px 8px', borderRadius: '4px', fontWeight: 700 }}>
                          📍 ~45m Away • Same Building
                        </span>
                      </div>

                      <h4 style={{ fontSize: '1.25rem', fontWeight: 800, margin: '0 0 4px 0', color: '#14b8a6' }}>
                        Resident: {res ? res.full_name : `Resident #${inc.resident_id}`} (Age {res?.age || 'N/A'})
                      </h4>
                      <p style={{ color: '#cbd5e1', fontSize: '0.9rem', margin: '4px 0 8px 0' }}>
                        Location: <strong>{inc.location || res?.address}</strong>
                      </p>
                    </div>

                    {/* Neighbor Action Button */}
                    <div>
                      {isIResponding ? (
                        <div style={{ background: 'rgba(16, 185, 129, 0.2)', border: '1px solid #10b981', color: '#10b981', padding: '10px 16px', borderRadius: '12px', fontWeight: 800, fontSize: '0.9rem', display: 'flex', alignItems: 'center', gap: '8px' }}>
                          <CheckCircle2 size={18} /> You are on your way!
                        </div>
                      ) : (
                        <button
                          onClick={() => handleNeighborRespond(inc.id)}
                          disabled={respondingId === inc.id}
                          className="btn btn-primary"
                          style={{
                            background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
                            padding: '12px 20px',
                            fontSize: '0.95rem',
                            fontWeight: 800,
                            boxShadow: '0 4px 16px rgba(16, 185, 129, 0.4)'
                          }}
                        >
                          <HeartHandshake size={20} />
                          <span>🤝 {respondingId === inc.id ? 'Accepting...' : 'I Can Help! (On My Way)'}</span>
                        </button>
                      )}
                    </div>
                  </div>

                  <div style={{ background: 'rgba(15, 23, 42, 0.6)', padding: '12px 14px', borderRadius: '10px', border: '1px solid rgba(255,255,255,0.08)', color: '#e2e8f0', fontSize: '0.88rem', marginBottom: '12px' }}>
                    🚨 <strong>Emergency Details:</strong> "{inc.description}"
                  </div>

                  {inc.responder_name && (
                    <div style={{ fontSize: '0.82rem', color: '#10b981', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '6px' }}>
                      ✓ Active Responder: {inc.responder_name} ({inc.responder_role})
                    </div>
                  )}
                </div>
              );
            })
          )}
        </div>

        {/* RIGHT COLUMN: NEIGHBORHOOD MAP WIDGET */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          <div className="glass-card" style={{ padding: '16px' }}>
            <h4 style={{ fontSize: '1rem', fontWeight: 800, color: '#f8fafc', marginBottom: '12px', display: 'flex', alignItems: 'center', gap: '8px' }}>
              <Navigation size={18} color="#3b82f6" /> Neighborhood Radar Map
            </h4>

            <RealisticMap
              origin={neighborOrigin}
              markers={mapMarkers}
              height="360px"
              isExpandable={true}
            />
          </div>

          <div className="glass-card" style={{ padding: '20px', fontSize: '0.85rem', color: '#cbd5e1' }}>
            <h4 style={{ fontSize: '0.95rem', fontWeight: 800, color: '#14b8a6', marginBottom: '8px' }}>
              💡 Neighbor Response Guidelines
            </h4>
            <ol style={{ paddingLeft: '18px', margin: 0, display: 'flex', flexDirection: 'column', gap: '6px' }}>
              <li>Check your immediate physical safety before rushing.</li>
              <li>Knock or gain entry to provide first aid or comfort.</li>
              <li>Confirm if Security or Ambulances have been dispatched.</li>
              <li>Keep linked family guardians updated on resident status.</li>
            </ol>
          </div>
        </div>

      </div>
    </main>
  );
}
