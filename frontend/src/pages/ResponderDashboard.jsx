import React, { useState } from 'react';
import { 
  Siren, 
  Shield, 
  UserCheck, 
  CheckCircle2, 
  MapPin, 
  AlertTriangle, 
  Clock, 
  RefreshCw, 
  Navigation, 
  Map, 
  X, 
  Compass, 
  Route 
} from 'lucide-react';
import { api } from '../services/api';
import { useGeolocation } from '../hooks/useGeolocation';
import RealisticMap from '../components/RealisticMap';
import LoadingScreen from '../components/LoadingScreen';
import { useLanguage } from '../context/LanguageContext';
import { usePolling } from '../hooks/usePolling';
import { indexById } from '../utils/collections';
import { alertError, logError } from '../utils/errors';
import { resolveCoords, scatterOffset } from '../utils/location';
import { incidentBadgeClass } from '../utils/status';

export default function ResponderDashboard({ user }) {
  const { t } = useLanguage();
  const [incidents, setIncidents] = useState([]);
  const [residentsMap, setResidentsMap] = useState({});
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('pending'); // 'pending', 'assigned', 'all', 'map'
  
  // Navigation Modal state for specific incident
  const [navIncident, setNavIncident] = useState(null);
  const [destinationCoords, setDestinationCoords] = useState(null);

  const geo = useGeolocation();

  // Responder fallback origin if browser location is pending
  const responderOrigin = {
    ...resolveCoords(geo),
    title: `Responder ${user.full_name}`,
    address: geo.address || 'Responder Current GPS Position'
  };

  const loadIncidents = async () => {
    try {
      const [incList, resList] = await Promise.all([
        api.getIncidents(),
        api.getResidents()
      ]);

      setIncidents(incList);
      setResidentsMap(indexById(resList));
    } catch (err) {
      logError("Error loading responder dashboard data", err);
    } finally {
      setLoading(false);
    }
  };

  usePolling(loadIncidents, 4000);

  const handleAcceptIncident = async (id) => {
    try {
      await api.acceptIncident(id);
      await loadIncidents();
    } catch (err) {
      alertError("Failed to accept incident", err);
    }
  };

  const handleUpdateStatus = async (id, status) => {
    try {
      await api.updateIncidentStatus(id, status);
      await loadIncidents();
    } catch (err) {
      alertError("Failed to update status", err);
    }
  };

  // Open Navigation modal for an incident
  const handleOpenNavigation = async (inc) => {
    setNavIncident(inc);
    const resident = residentsMap[inc.resident_id];
    const locStr = inc.location || resident?.address || 'Building A, Ground Floor';

    // Attempt geocoding incident address string to lat/lng
    const result = await geo.geocodeAddress(locStr);
    if (result) {
      setDestinationCoords({
        lat: result.lat,
        lng: result.lng,
        title: `Emergency ${inc.incident_code} - ${resident?.full_name || 'Resident'}`,
        address: locStr
      });
    } else {
      // Default offset fallback location for demonstration
      setDestinationCoords({
        lat: responderOrigin.lat + 0.008,
        lng: responderOrigin.lng + 0.006,
        title: `Emergency ${inc.incident_code} - ${resident?.full_name || 'Resident'}`,
        address: locStr
      });
    }
  };

  const pendingIncidents = incidents.filter(i => i.status === 'Pending');
  const myAssignedIncidents = incidents.filter(i => i.responder_id === user.id && i.status !== 'Resolved');
  const resolvedIncidents = incidents.filter(i => i.status === 'Resolved');

  // Prepare map pins for the all-in-one Dispatch Radar Map
  const mapIncidentMarkers = incidents.map((inc, idx) => {
    const res = residentsMap[inc.resident_id];
    const isPending = inc.status === 'Pending';
    const isMine = inc.responder_id === user.id;

    // Distribute markers slightly if no exact geocode yet
    const offset = scatterOffset(idx, [0.004, -0.005, 0.003], [0.005, -0.004]);

    return {
      id: inc.id,
      lat: responderOrigin.lat + offset.lat,
      lng: responderOrigin.lng + offset.lng,
      title: `${inc.incident_code}: ${res?.full_name || 'Resident'}`,
      description: `[${inc.priority} PRIORITY] ${inc.description || 'Emergency SOS call'}`,
      status: inc.status,
      type: isPending ? 'sos' : isMine ? 'responder' : 'user'
    };
  });

  if (loading) return <LoadingScreen message="Loading Emergency Dispatch Feed..." />;

  return (
    <main style={{ maxWidth: '1280px', margin: '0 auto', padding: '32px 24px' }}>
      
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '28px', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <h2 style={{ fontSize: '1.8rem', fontWeight: 800, margin: 0, color: '#f8fafc', display: 'flex', alignItems: 'center', gap: '10px' }}>
            <Shield size={28} color="#10b981" />
            Responder Portal — {user.full_name}
          </h2>
          <p style={{ color: '#94a3b8', margin: '4px 0 0 0', fontSize: '0.9rem' }}>
            Role: <strong style={{ color: '#10b981', textTransform: 'uppercase' }}>{user.role}</strong> • Real-time GPS Navigation & Emergency Dispatch
          </p>
        </div>

        <div style={{ display: 'flex', gap: '12px' }}>
          <button className="btn btn-secondary" onClick={() => geo.requestLocation()}>
            <Compass size={16} color="#14b8a6" />
            <span>{geo.lat ? 'GPS Location Active' : 'Acquire GPS Position'}</span>
          </button>

          <button className="btn btn-secondary" onClick={loadIncidents}>
            <RefreshCw size={16} /> Refresh Queue
          </button>
        </div>
      </div>

      {/* Counter Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '18px', marginBottom: '28px' }}>
        <div className="glass-card" style={{ padding: '20px' }}>
          <span style={{ color: '#ef4444', fontSize: '0.8rem', fontWeight: 700 }}>UNASSIGNED SOS REQUESTS</span>
          <div style={{ fontSize: '2rem', fontWeight: 800, color: '#ef4444', marginTop: '6px' }}>{pendingIncidents.length}</div>
        </div>
        <div className="glass-card" style={{ padding: '20px' }}>
          <span style={{ color: '#f59e0b', fontSize: '0.8rem', fontWeight: 700 }}>MY ACTIVE INCIDENTS</span>
          <div style={{ fontSize: '2rem', fontWeight: 800, color: '#f59e0b', marginTop: '6px' }}>{myAssignedIncidents.length}</div>
        </div>
        <div className="glass-card" style={{ padding: '20px' }}>
          <span style={{ color: '#10b981', fontSize: '0.8rem', fontWeight: 700 }}>RESOLVED BY TEAM</span>
          <div style={{ fontSize: '2rem', fontWeight: 800, color: '#10b981', marginTop: '6px' }}>{resolvedIncidents.length}</div>
        </div>
      </div>

      {/* View Tabs */}
      <div style={{ display: 'flex', gap: '10px', marginBottom: '24px', flexWrap: 'wrap' }}>
        {[
          { key: 'pending', label: `Pending SOS Queue (${pendingIncidents.length})` },
          { key: 'assigned', label: `My Assigned (${myAssignedIncidents.length})` },
          { key: 'map', label: `🗺️ Live Emergency Dispatch Map` },
          { key: 'all', label: `All Incident History (${incidents.length})` }
        ].map(tab => (
          <button
            key={tab.key}
            onClick={() => setActiveTab(tab.key)}
            style={{
              background: activeTab === tab.key ? '#14b8a6' : 'rgba(30, 41, 59, 0.6)',
              color: activeTab === tab.key ? '#ffffff' : '#94a3b8',
              border: '1px solid rgba(255, 255, 255, 0.1)',
              padding: '10px 20px',
              borderRadius: '9999px',
              fontWeight: 600,
              fontSize: '0.88rem',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '6px'
            }}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* MAP VIEW TAB */}
      {activeTab === 'map' ? (
        <div className="glass-card" style={{ padding: '24px', marginBottom: '32px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
            <div>
              <h3 style={{ fontSize: '1.25rem', fontWeight: 800, margin: 0, color: '#f8fafc', display: 'flex', alignItems: 'center', gap: '8px' }}>
                <Map size={22} color="#14b8a6" /> Live Dispatch Radar & Incident Map
              </h3>
              <p style={{ color: '#94a3b8', margin: '4px 0 0 0', fontSize: '0.85rem' }}>
                Google Maps visual rendering of responder position and active emergency SOS pins.
              </p>
            </div>

            <div style={{ display: 'flex', gap: '8px' }}>
              <span className="badge badge-emergency">🔴 {pendingIncidents.length} Pending SOS</span>
              <span className="badge badge-alert">🟡 {myAssignedIncidents.length} In Progress</span>
            </div>
          </div>

          <RealisticMap
            origin={responderOrigin}
            markers={mapIncidentMarkers}
            height="320px"
            isExpandable={true}
          />
        </div>
      ) : (
        /* INCIDENT LIST ROSTER VIEW */
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          {(activeTab === 'pending' ? pendingIncidents : activeTab === 'assigned' ? myAssignedIncidents : incidents).length === 0 ? (
            <div className="glass-card" style={{ padding: '40px', textAlign: 'center', color: '#94a3b8' }}>
              No emergency incidents found in this view.
            </div>
          ) : (
            (activeTab === 'pending' ? pendingIncidents : activeTab === 'assigned' ? myAssignedIncidents : incidents).map(inc => {
              const resident = residentsMap[inc.resident_id];
              return (
                <div key={inc.id} className="glass-card" style={{
                  padding: '24px',
                  borderLeft: `5px solid ${inc.priority === 'Critical' ? '#ef4444' : inc.priority === 'High' ? '#f59e0b' : '#3b82f6'}`,
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  flexWrap: 'wrap',
                  gap: '16px'
                }}>
                  <div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '8px' }}>
                      <span style={{ fontSize: '1.1rem', fontWeight: 800, color: '#f8fafc' }}>{inc.incident_code}</span>
                      <span className={incidentBadgeClass(inc.status)}>
                        {inc.status}
                      </span>
                      <span style={{ background: 'rgba(239, 68, 68, 0.15)', color: '#f87171', padding: '2px 8px', borderRadius: '4px', fontSize: '0.75rem', fontWeight: 700 }}>
                        {inc.priority} PRIORITY
                      </span>
                    </div>

                    <h3 style={{ fontSize: '1.2rem', fontWeight: 700, margin: '0 0 4px 0', color: '#14b8a6' }}>
                      Resident: {resident ? resident.full_name : `Resident #${inc.resident_id}`} (Age {resident?.age || 'N/A'})
                    </h3>

                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: '#cbd5e1', fontSize: '0.88rem', margin: '4px 0 8px 0' }}>
                      <MapPin size={16} color="#3b82f6" />
                      <span>Location: <strong>{inc.location || resident?.address}</strong></span>
                    </div>

                    <p style={{ color: '#94a3b8', fontSize: '0.85rem', margin: 0 }}>
                      Emergency Details: <em>"{inc.description}"</em>
                    </p>

                    {inc.responder_name && (
                      <div style={{ fontSize: '0.8rem', color: '#10b981', marginTop: '8px', fontWeight: 600 }}>
                        ✓ Assigned Responder: {inc.responder_name} ({inc.responder_role})
                      </div>
                    )}
                  </div>

                  {/* Responder Actions & Navigation */}
                  <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
                    <button 
                      className="btn btn-secondary" 
                      style={{ background: 'rgba(59, 130, 246, 0.15)', color: '#60a5fa', borderColor: 'rgba(59, 130, 246, 0.3)' }}
                      onClick={() => handleOpenNavigation(inc)}
                    >
                      <Navigation size={18} />
                      <span>Get Directions & Map</span>
                    </button>

                    {inc.status === 'Pending' && (
                      <button className="btn btn-primary" onClick={() => handleAcceptIncident(inc.id)}>
                        <UserCheck size={18} />
                        <span>Accept Request</span>
                      </button>
                    )}

                    {inc.status === 'Accepted' && (
                      <button className="btn btn-secondary" style={{ background: '#f59e0b', color: '#0f172a', fontWeight: 700 }} onClick={() => handleUpdateStatus(inc.id, 'In Progress')}>
                        <span>Set In Progress</span>
                      </button>
                    )}

                    {(inc.status === 'Accepted' || inc.status === 'In Progress') && (
                      <button className="btn btn-primary" style={{ background: '#10b981' }} onClick={() => handleUpdateStatus(inc.id, 'Resolved')}>
                        <CheckCircle2 size={18} />
                        <span>Mark Resolved</span>
                      </button>
                    )}
                  </div>
                </div>
              );
            })
          )}
        </div>
      )}

      {/* TURN-BY-TURN NAVIGATION MODAL */}
      {navIncident && (
        <div className="modal-overlay">
          <div className="modal-container" style={{ maxWidth: '900px', width: '95%' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
              <div>
                <h2 style={{ fontSize: '1.4rem', fontWeight: 800, margin: 0, color: '#f8fafc', display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <Navigation size={22} color="#3b82f6" /> Turn-by-Turn Emergency Dispatch Navigation
                </h2>
                <p style={{ color: '#94a3b8', margin: '4px 0 0 0', fontSize: '0.85rem' }}>
                  Incident {navIncident.incident_code} • Victim: <strong>{residentsMap[navIncident.resident_id]?.full_name || 'Resident'}</strong>
                </p>
              </div>
              <button onClick={() => setNavIncident(null)} style={{ background: 'none', border: 'none', color: '#94a3b8', cursor: 'pointer' }}>
                <X size={24} />
              </button>
            </div>

            <div style={{ marginBottom: '16px' }}>
              <RealisticMap
                origin={responderOrigin}
                destination={destinationCoords}
                height="460px"
                showDirectionsPanel={true}
              />
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
              <button className="btn btn-secondary" onClick={() => setNavIncident(null)}>
                Close Map
              </button>
              {navIncident.status === 'Pending' && (
                <button className="btn btn-primary" onClick={() => { handleAcceptIncident(navIncident.id); setNavIncident(null); }}>
                  <UserCheck size={18} /> Accept Emergency Request
                </button>
              )}
            </div>
          </div>
        </div>
      )}
    </main>
  );
}
