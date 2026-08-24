import React, { useState } from 'react';
import { 
  Users, 
  ShieldCheck, 
  AlertTriangle, 
  Siren, 
  Plus, 
  Search, 
  PhoneCall, 
  Stethoscope, 
  Edit, 
  Trash2, 
  Sparkles,
  Map,
  LayoutGrid
} from 'lucide-react';
import { api } from '../services/api';
import SOSBanner from '../components/SOSBanner';
import ResidentModal from '../components/ResidentModal';
import RealisticMap from '../components/RealisticMap';
import LoadingScreen from '../components/LoadingScreen';
import { useLanguage } from '../context/LanguageContext';
import { useGeolocation } from '../hooks/useGeolocation';
import { usePolling } from '../hooks/usePolling';
import { indexById, matchesQuery } from '../utils/collections';
import { alertError, logError } from '../utils/errors';
import { resolveCoords, scatterOffset } from '../utils/location';

export default function Dashboard({ user }) {
  const { t } = useLanguage();
  const [residents, setResidents] = useState([]);
  const [alerts, setAlerts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filterStatus, setFilterStatus] = useState('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [viewMode, setViewMode] = useState('grid'); // 'grid' or 'map'
  
  const geo = useGeolocation();

  // Modal states
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedResident, setSelectedResident] = useState(null);
  
  // SOS Trigger Modal
  const [sosResidentId, setSosResidentId] = useState('');
  const [sosReason, setSosReason] = useState('');
  const [isSosModalOpen, setIsSosModalOpen] = useState(false);

  const fetchData = async () => {
    try {
      const [resList, incList] = await Promise.all([
        api.getResidents(),
        api.getIncidents()
      ]);
      setResidents(resList);
      setAlerts(incList);
    } catch (err) {
      logError("Failed to load caregiver dashboard data", err);
    } finally {
      setLoading(false);
    }
  };

  usePolling(fetchData, 3000);

  const residentsMap = indexById(residents);

  const handleResolveAlert = async (alertId) => {
    try {
      await api.updateIncidentStatus(alertId, "Resolved");
      await fetchData();
    } catch (err) {
      alertError("Failed to resolve alert", err);
    }
  };

  const handleSaveResident = async (formData) => {
    try {
      if (selectedResident) {
        await api.updateResident(selectedResident.id, formData);
      } else {
        await api.createResident(formData);
      }
      setIsModalOpen(false);
      setSelectedResident(null);
      await fetchData();
    } catch (err) {
      alertError("Error saving resident", err);
    }
  };

  const handleDeleteResident = async (id, name) => {
    if (window.confirm(`Are you sure you want to remove ${name} from the roster?`)) {
      try {
        await api.deleteResident(id);
        await fetchData();
      } catch (err) {
        alertError("Failed to delete resident", err);
      }
    }
  };

  const handleTriggerSOS = async (e) => {
    e.preventDefault();
    if (!sosResidentId) return;
    try {
      await api.triggerIncident({
        resident_id: parseInt(sosResidentId),
        emergency_type: "Medical Emergency",
        priority: "High",
        description: sosReason || "Manual SOS triggered by caregiver.",
        location: residentsMap[sosResidentId]?.address || `Room ${residentsMap[sosResidentId]?.room_number}`
      });
      setIsSosModalOpen(false);
      setSosReason('');
      setSosResidentId('');
      await fetchData();
    } catch (err) {
      alertError("Failed to trigger SOS", err);
    }
  };

  // Filtered residents
  const filteredResidents = residents.filter(r => {
    const matchesStatus = filterStatus === 'all' || r.status === filterStatus;
    const matchesSearch = matchesQuery(searchQuery, r.full_name, r.room_number, r.medical_notes);
    return matchesStatus && matchesSearch;
  });

  const safeCount = residents.filter(r => r.status === 'safe').length;
  const alertCount = residents.filter(r => r.status === 'alert').length;
  const emergencyCount = residents.filter(r => r.status === 'emergency').length;

  const { lat: baseLat, lng: baseLng } = resolveCoords(geo);

  // Build pins for all residents
  const residentMapMarkers = filteredResidents.map((res, idx) => {
    const offset = scatterOffset(idx, [0.003, -0.004, 0.002], [0.004, -0.003]);

    return {
      id: res.id,
      lat: baseLat + offset.lat,
      lng: baseLng + offset.lng,
      title: `${res.full_name} (Room ${res.room_number})`,
      description: `Age ${res.age} • Contact: ${res.emergency_contact}`,
      status: res.status.toUpperCase(),
      type: res.status === 'emergency' ? 'sos' : res.status === 'alert' ? 'responder' : 'user'
    };
  });

  return (
    <div>
      {/* Live Active SOS Banner */}
      <SOSBanner alerts={alerts} residentsMap={residentsMap} onResolve={handleResolveAlert} />

      <main style={{ maxWidth: '1280px', margin: '0 auto', padding: '32px 24px' }}>
        
        {/* Top Header & Quick Actions */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '28px', flexWrap: 'wrap', gap: '16px' }}>
          <div>
            <h2 style={{ fontSize: '1.8rem', fontWeight: 800, margin: 0, color: '#f8fafc' }}>
              Caregiver Roster & Monitoring Center
            </h2>
            <p style={{ color: '#94a3b8', margin: '4px 0 0 0', fontSize: '0.9rem' }}>
              Real-time resident vitals roster, status indicators & interactive facility map
            </p>
          </div>

          <div style={{ display: 'flex', gap: '12px' }}>
            <button className="btn btn-sos-pulse" onClick={() => setIsSosModalOpen(true)}>
              <Siren size={20} />
              <span>Trigger SOS Emergency</span>
            </button>
            <button className="btn btn-primary" onClick={() => { setSelectedResident(null); setIsModalOpen(true); }}>
              <Plus size={20} />
              <span>Add Resident</span>
            </button>
          </div>
        </div>

        {/* Stats Grid */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '20px', marginBottom: '32px' }}>
          <div className="glass-card" style={{ padding: '20px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ color: '#94a3b8', fontSize: '0.85rem', fontWeight: 600 }}>TOTAL RESIDENTS</span>
              <Users size={22} color="#3b82f6" />
            </div>
            <div style={{ fontSize: '2rem', fontWeight: 800, color: '#f8fafc', marginTop: '8px' }}>
              {residents.length}
            </div>
          </div>

          <div className="glass-card" style={{ padding: '20px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ color: '#94a3b8', fontSize: '0.85rem', fontWeight: 600 }}>STABLE & SAFE</span>
              <ShieldCheck size={22} color="#10b981" />
            </div>
            <div style={{ fontSize: '2rem', fontWeight: 800, color: '#10b981', marginTop: '8px' }}>
              {safeCount}
            </div>
          </div>

          <div className="glass-card" style={{ padding: '20px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ color: '#94a3b8', fontSize: '0.85rem', fontWeight: 600 }}>ATTENTION REQUIRED</span>
              <AlertTriangle size={22} color="#f59e0b" />
            </div>
            <div style={{ fontSize: '2rem', fontWeight: 800, color: '#f59e0b', marginTop: '8px' }}>
              {alertCount}
            </div>
          </div>

          <div className="glass-card" style={{ padding: '20px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ color: '#94a3b8', fontSize: '0.85rem', fontWeight: 600 }}>ACTIVE EMERGENCIES</span>
              <Siren size={22} color="#ef4444" />
            </div>
            <div style={{ fontSize: '2rem', fontWeight: 800, color: '#ef4444', marginTop: '8px' }}>
              {emergencyCount}
            </div>
          </div>
        </div>

        {/* View Mode & Filter Controls */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px', flexWrap: 'wrap', gap: '16px' }}>
          <div style={{ display: 'flex', gap: '8px' }}>
            {['all', 'safe', 'alert', 'emergency'].map(st => (
              <button
                key={st}
                onClick={() => setFilterStatus(st)}
                style={{
                  background: filterStatus === st ? '#14b8a6' : 'rgba(30, 41, 59, 0.6)',
                  color: filterStatus === st ? '#ffffff' : '#94a3b8',
                  border: '1px solid rgba(255, 255, 255, 0.1)',
                  padding: '8px 16px',
                  borderRadius: '9999px',
                  fontSize: '0.85rem',
                  fontWeight: 600,
                  textTransform: 'capitalize',
                  cursor: 'pointer',
                  transition: 'all 0.2s'
                }}
              >
                {st} ({st === 'all' ? residents.length : residents.filter(r => r.status === st).length})
              </button>
            ))}
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            {/* View Mode Switcher: Grid vs Map */}
            <div style={{ background: 'rgba(30, 41, 59, 0.8)', padding: '4px', borderRadius: '9999px', border: '1px solid rgba(255,255,255,0.1)', display: 'flex', gap: '4px' }}>
              <button
                onClick={() => setViewMode('grid')}
                style={{
                  background: viewMode === 'grid' ? '#14b8a6' : 'transparent',
                  color: viewMode === 'grid' ? '#fff' : '#94a3b8',
                  border: 'none',
                  padding: '6px 14px',
                  borderRadius: '9999px',
                  fontSize: '0.8rem',
                  fontWeight: 700,
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px'
                }}
              >
                <LayoutGrid size={14} /> Cards
              </button>
              <button
                onClick={() => setViewMode('map')}
                style={{
                  background: viewMode === 'map' ? '#14b8a6' : 'transparent',
                  color: viewMode === 'map' ? '#fff' : '#94a3b8',
                  border: 'none',
                  padding: '6px 14px',
                  borderRadius: '9999px',
                  fontSize: '0.8rem',
                  fontWeight: 700,
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px'
                }}
              >
                <Map size={14} /> Realistic Map
              </button>
            </div>

            <div style={{ position: 'relative', width: '240px' }}>
              <Search size={18} color="#64748b" style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)' }} />
              <input
                type="text"
                className="form-input"
                placeholder="Search name, room..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                style={{ paddingLeft: '38px', borderRadius: '9999px' }}
              />
            </div>
          </div>
        </div>

        {/* MAP VIEW OR CARDS GRID VIEW */}
        {viewMode === 'map' ? (
          <div className="glass-card" style={{ padding: '24px', marginBottom: '32px' }}>
            <h3 style={{ fontSize: '1.25rem', fontWeight: 800, margin: '0 0 16px 0', color: '#f8fafc', display: 'flex', alignItems: 'center', gap: '8px' }}>
              <Map size={22} color="#3b82f6" /> Facility Resident Pins & Live Location Map
            </h3>
            <RealisticMap
              origin={{
                lat: baseLat,
                lng: baseLng,
                title: 'Care Facility Headquarters',
                address: geo.address || 'Facility Main Entrance'
              }}
              markers={residentMapMarkers}
              height="320px"
              isExpandable={true}
            />
          </div>
        ) : (
          /* Resident Roster Cards Grid */
          loading ? (
            <LoadingScreen message="Loading resident roster..." />
          ) : filteredResidents.length === 0 ? (
            <div className="glass-card" style={{ textAlign: 'center', padding: '60px' }}>
              <p style={{ color: '#94a3b8', margin: 0 }}>No residents found matching criteria.</p>
            </div>
          ) : (
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(340px, 1fr))', gap: '24px' }}>
              {filteredResidents.map(res => (
                <div key={res.id} className="glass-card" style={{ padding: '24px', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
                  <div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '14px' }}>
                      <div>
                        <h3 style={{ fontSize: '1.25rem', fontWeight: 800, margin: 0, color: '#f8fafc' }}>
                          {res.full_name}
                        </h3>
                        <span style={{ fontSize: '0.85rem', color: '#94a3b8' }}>
                          Age {res.age} • Room <strong>{res.room_number}</strong>
                        </span>
                      </div>
                      <span className={`badge badge-${res.status}`}>
                        {res.status}
                      </span>
                    </div>

                    <div style={{
                      background: 'rgba(15, 23, 42, 0.5)',
                      borderRadius: '10px',
                      padding: '12px',
                      marginBottom: '16px',
                      border: '1px solid rgba(255, 255, 255, 0.05)'
                    }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: '#94a3b8', fontSize: '0.78rem', marginBottom: '4px', textTransform: 'uppercase', fontWeight: 700 }}>
                        <Stethoscope size={14} color="#14b8a6" /> Medical & Daily Notes
                      </div>
                      <p style={{ color: '#cbd5e1', fontSize: '0.85rem', margin: 0, lineHeight: 1.4 }}>
                        {res.medical_notes || 'No medical notes recorded.'}
                      </p>
                    </div>

                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#94a3b8', fontSize: '0.82rem', marginBottom: '20px' }}>
                      <PhoneCall size={14} color="#3b82f6" />
                      <span>Emergency Contact: <strong style={{ color: '#e2e8f0' }}>{res.emergency_contact}</strong></span>
                    </div>
                  </div>

                  {/* Card Actions */}
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingTop: '16px', borderTop: '1px solid rgba(255, 255, 255, 0.08)' }}>
                    <div style={{ display: 'flex', gap: '8px' }}>
                      <button
                        className="btn btn-secondary"
                        style={{ padding: '6px 12px', fontSize: '0.8rem' }}
                        onClick={() => { setSelectedResident(res); setIsModalOpen(true); }}
                      >
                        <Edit size={14} />
                        <span>Edit</span>
                      </button>
                      <button
                        className="btn btn-secondary"
                        style={{ padding: '6px 12px', fontSize: '0.8rem', color: '#f87171' }}
                        onClick={() => handleDeleteResident(res.id, res.full_name)}
                      >
                        <Trash2 size={14} />
                      </button>
                    </div>

                    <button
                      className="btn btn-danger"
                      style={{ padding: '6px 14px', fontSize: '0.8rem' }}
                      onClick={() => {
                        setSosResidentId(res.id);
                        setSosReason(`Manual emergency trigger for ${res.full_name} in Room ${res.room_number}`);
                        setIsSosModalOpen(true);
                      }}
                    >
                      <Siren size={14} />
                      <span>SOS Panic</span>
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )
        )}
      </main>

      {/* Add / Edit Resident Modal */}
      <ResidentModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onSave={handleSaveResident}
        resident={selectedResident}
      />

      {/* Trigger SOS Modal */}
      {isSosModalOpen && (
        <div className="modal-overlay">
          <div className="modal-container">
            <h2 style={{ color: '#ef4444', display: 'flex', alignItems: 'center', gap: '10px', marginTop: 0 }}>
              <Siren size={24} /> Trigger Emergency SOS Alert
            </h2>
            <form onSubmit={handleTriggerSOS}>
              <div className="form-group">
                <label>Select Resident *</label>
                <select
                  className="form-input"
                  value={sosResidentId}
                  onChange={(e) => setSosResidentId(e.target.value)}
                  required
                >
                  <option value="">-- Choose Resident --</option>
                  {residents.map(r => (
                    <option key={r.id} value={r.id}>
                      {r.full_name} (Room {r.room_number})
                    </option>
                  ))}
                </select>
              </div>

              <div className="form-group">
                <label>Emergency Reason / Details</label>
                <textarea
                  className="form-input"
                  rows={3}
                  placeholder="Describe emergency reason (e.g. Unscheduled fall, chest pain...)"
                  value={sosReason}
                  onChange={(e) => setSosReason(e.target.value)}
                />
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '20px' }}>
                <button type="button" className="btn btn-secondary" onClick={() => setIsSosModalOpen(false)}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-danger">
                  <Siren size={18} />
                  <span>Dispatch SOS Alert</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
