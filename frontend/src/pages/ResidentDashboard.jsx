import React, { useState, useEffect } from 'react';
import {
  Siren,
  Heart,
  User,
  ShieldAlert,
  Plus,
  Trash2,
  Phone,
  MapPin,
  Sparkles,
  CheckCircle2,
  Clock,
  Navigation,
  Compass,
  Map,
  Maximize2
} from 'lucide-react';
import { api } from '../services/api';
import { useGeolocation } from '../hooks/useGeolocation';
import RealisticMap from '../components/RealisticMap';
import { useLanguage } from '../context/LanguageContext';
import SensorTelemetryWidget from '../components/SensorTelemetryWidget';

export default function ResidentDashboard({ user }) {
  const { t } = useLanguage();
  const [resident, setResident] = useState(null);
  const [guardians, setGuardians] = useState([]);
  const [incidents, setIncidents] = useState([]);
  const [loading, setLoading] = useState(true);

  // Geolocation hook
  const geo = useGeolocation();

  // Custom location overrides
  const [selectedLocation, setSelectedLocation] = useState(null);

  // SOS Trigger Form
  const [emergencyText, setEmergencyText] = useState('');
  const [aiClassification, setAiClassification] = useState(null);
  const [isTriggering, setIsTriggering] = useState(false);
  const [sosSuccessMsg, setSosSuccessMsg] = useState('');

  // Add Guardian Form
  const [isGuardianModalOpen, setIsGuardianModalOpen] = useState(false);
  const [newGuardian, setNewGuardian] = useState({ name: '', relationship: 'Father', phone: '', email: '' });

  const loadData = async () => {
    try {
      const residents = await api.getResidents();
      let res = residents.find(r => r.user_id === user.id || r.full_name === user.full_name);
      if (!res && residents.length > 0) res = residents[0];

      setResident(res);

      if (res) {
        const [gList, incList] = await Promise.all([
          api.getGuardians(res.id),
          api.getIncidents()
        ]);
        setGuardians(gList);
        setIncidents(incList.filter(i => i.resident_id === res.id));
      }
    } catch (err) {
      console.error("Error loading resident data:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
    const timer = setInterval(loadData, 5000);
    return () => clearInterval(timer);
  }, [user]);

  const handleAIClassify = async () => {
    if (!emergencyText.trim()) return;
    try {
      const classified = await api.classifyEmergency(emergencyText);
      setAiClassification(classified);
    } catch (err) {
      console.error("AI classification error:", err);
    }
  };

  const handlePressSOS = async () => {
    if (!resident) return;
    setIsTriggering(true);
    try {
      const cat = aiClassification ? aiClassification.category : "Medical Emergency";
      const prio = aiClassification ? aiClassification.priority : "High";

      // Formulate precise location payload using live browser GPS or selected map pin
      let finalLocation = selectedLocation?.address || geo.address;
      if (!finalLocation && geo.lat) {
        finalLocation = `GPS (${geo.lat.toFixed(5)}, ${geo.lng.toFixed(5)})`;
      }
      if (!finalLocation) {
        finalLocation = resident.address || `Room ${resident.room_number}`;
      }

      await api.triggerIncident({
        resident_id: resident.id,
        emergency_type: cat,
        priority: prio,
        description: emergencyText || `SOS Panic triggered by ${resident.full_name}`,
        location: finalLocation
      });

      setEmergencyText('');
      setAiClassification(null);
      setSosSuccessMsg('🚨 SOS Emergency Signal Dispatched Successfully!');
      setTimeout(() => setSosSuccessMsg(''), 6000);
      await loadData();
    } catch (err) {
      alert("Error triggering SOS: " + err.message);
    } finally {
      setIsTriggering(false);
    }
  };

  const handleAddGuardian = async (e) => {
    e.preventDefault();
    if (!resident || !newGuardian.name || !newGuardian.phone) return;
    try {
      await api.addGuardian({
        resident_id: resident.id,
        ...newGuardian
      });
      setNewGuardian({ name: '', relationship: 'Father', phone: '', email: '' });
      setIsGuardianModalOpen(false);
      await loadData();
    } catch (err) {
      alert("Error adding guardian: " + err.message);
    }
  };

  const handleDeleteGuardian = async (id) => {
    try {
      await api.deleteGuardian(id);
      await loadData();
    } catch (err) {
      alert("Error removing guardian: " + err.message);
    }
  };

  const currentLat = selectedLocation?.lat || geo.lat || 28.6139;
  const currentLng = selectedLocation?.lng || geo.lng || 77.2090;

  if (loading) return <div style={{ textAlign: 'center', padding: '60px', color: '#94a3b8' }}>Loading Resident Portal...</div>;

  return (
    <main style={{ maxWidth: '1280px', margin: '0 auto', padding: '28px 24px' }}>

      {/* Welcome Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <h2 style={{ fontSize: '1.8rem', fontWeight: 800, margin: 0, color: '#f8fafc' }}>
            {t('welcome')}, {user.full_name}
          </h2>
          <p style={{ color: '#94a3b8', margin: '4px 0 0 0', fontSize: '0.9rem' }}>
            Resident Emergency Portal • Status: <strong style={{ color: resident?.status === 'emergency' ? '#ef4444' : '#10b981', textTransform: 'uppercase' }}>{resident?.status || 'Safe'}</strong>
          </p>
        </div>

        {/* Location Quick Button */}
        <div style={{ display: 'flex', gap: '8px' }}>
          <button
            className="btn btn-secondary"
            onClick={() => {
              setSelectedLocation(null);
              geo.requestLocation();
            }}
            style={{ background: 'rgba(20, 184, 166, 0.15)', borderColor: 'rgba(20, 184, 166, 0.3)', color: '#14b8a6' }}
          >
            <Compass size={18} className={geo.loading ? 'spin' : ''} />
            <span>{geo.address ? `📍 ${geo.address}` : 'Enable Live GPS Location'}</span>
          </button>
          {selectedLocation && (
            <button
              className="btn btn-secondary"
              onClick={() => setSelectedLocation(null)}
              style={{ background: 'rgba(239, 68, 68, 0.15)', borderColor: 'rgba(239, 68, 68, 0.3)', color: '#f87171' }}
              title="Clear custom selected map location and return to live GPS"
            >
              Clear Custom Pin
            </button>
          )}
        </div>
      </div>

      {/* IoT SMART SENSOR TELEMETRY WIDGET */}
      <SensorTelemetryWidget
        onSimulateEmergency={async (payload) => {
          if (!resident) return;
          let finalLocation = selectedLocation?.address || geo.address || resident.address || `Room ${resident.room_number}`;
          await api.triggerIncident({
            resident_id: resident.id,
            emergency_type: payload.type,
            priority: payload.priority,
            description: payload.description,
            location: finalLocation
          });
          await loadData();
        }}
      />

      {/* TOP SECTION: TOP-LEFT COMPACT MAP WIDGET + SOS PANIC PANEL + MEDICAL PROFILE */}
      <div style={{ display: 'grid', gridTemplateColumns: '320px 1fr 1fr', gap: '20px', marginBottom: '28px' }}>

        {/* TOP LEFT: COMPACT MAP WIDGET WITH EXPAND SYMBOL */}
        <div className="glass-card" style={{ padding: '16px', display: 'flex', flexDirection: 'column', background: 'rgba(15, 23, 42, 0.88)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '10px' }}>
            <span style={{ fontSize: '0.85rem', fontWeight: 800, color: '#f8fafc', display: 'flex', alignItems: 'center', gap: '6px' }}>
              <Map size={16} color="#14b8a6" /> {t('mapTitle')}
            </span>
            <span style={{ fontSize: '0.72rem', color: '#14b8a6', background: 'rgba(20, 184, 166, 0.15)', padding: '2px 8px', borderRadius: '9999px', fontWeight: 700 }}>
              Top-Left Widget
            </span>
          </div>

          <RealisticMap
            origin={{
              lat: currentLat,
              lng: currentLng,
              title: resident?.full_name || 'My Location',
              address: selectedLocation?.address || geo.address || resident?.address
            }}
            markers={[
              {
                lat: currentLat,
                lng: currentLng,
                title: resident?.full_name || 'Resident',
                description: `Status: ${resident?.status || 'Safe'}`,
                type: resident?.status === 'emergency' ? 'sos' : 'user'
              }
            ]}
            selectable={true}
            onLocationSelect={(loc) => setSelectedLocation(loc)}
            height="210px"
            isExpandable={true}
          />
        </div>

        {/* SOS Emergency Panic Panel */}
        <div className="glass-card" style={{ padding: '20px', textAlign: 'center', background: 'linear-gradient(135deg, rgba(239, 68, 68, 0.15) 0%, var(--bg-secondary) 100%)', border: '1px solid rgba(239, 68, 68, 0.3)' }}>
          <h3 style={{ fontSize: '1.1rem', fontWeight: 800, color: '#ef4444', marginBottom: '10px' }}>
            {t('triggerSOS')} EMERGENCY PANIC
          </h3>

          {sosSuccessMsg && (
            <div style={{
              background: 'rgba(16, 185, 129, 0.15)',
              border: '1px solid #10b981',
              color: '#10b981',
              padding: '10px',
              borderRadius: '8px',
              fontSize: '0.82rem',
              fontWeight: 700,
              marginBottom: '14px',
              animation: 'pulse-emergency 1.5s infinite'
            }}>
              {sosSuccessMsg}
            </div>
          )}

          <button
            className="btn btn-sos-pulse"
            onClick={handlePressSOS}
            disabled={isTriggering}
            style={{
              width: '130px',
              height: '130px',
              borderRadius: '50%',
              fontSize: '1.6rem',
              fontWeight: 900,
              margin: '4px auto 12px auto',
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '4px'
            }}
          >
            <Siren size={36} />
            <span>{t('triggerSOS')}</span>
          </button>

          <div style={{ fontSize: '0.78rem', color: '#cbd5e1', marginBottom: '10px', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '4px' }}>
            <MapPin size={12} color="#ef4444" />
            <span style={{ maxWidth: '280px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
              {t('emergencyLocation')}: <strong>{selectedLocation?.address || geo.address || resident?.address || `Room ${resident?.room_number}`}</strong>
            </span>
          </div>

          {/* Optional Emergency Description */}
          <div style={{ textAlign: 'left' }}>
            <div style={{ display: 'flex', gap: '6px', marginBottom: '6px' }}>
              <input
                type="text"
                className="form-input"
                placeholder={t('describeEmergencyPlaceholder')}
                value={emergencyText}
                onChange={(e) => setEmergencyText(e.target.value)}
                style={{ fontSize: '0.8rem', padding: '6px 10px' }}
              />
              <button className="btn btn-secondary" onClick={handleAIClassify} style={{ padding: '6px 10px', fontSize: '0.75rem', whiteSpace: 'nowrap' }}>
                <Sparkles size={13} color="#c084fc" /> {t('aiClassify')}
              </button>
            </div>

            {aiClassification && (
              <div style={{ background: 'rgba(139, 92, 246, 0.15)', border: '1px solid rgba(139, 92, 246, 0.3)', borderRadius: '8px', padding: '8px', fontSize: '0.78rem' }}>
                <div style={{ color: '#c084fc', fontWeight: 700, marginBottom: '2px' }}>
                  AI: {aiClassification.category} ({aiClassification.priority})
                </div>
                <div style={{ color: '#e2e8f0' }}>💡 {aiClassification.immediate_advice}</div>
              </div>
            )}
          </div>
        </div>

        {/* Resident Profile & Medical Card */}
        <div className="glass-card" style={{ padding: '20px' }}>
          <h3 style={{ fontSize: '1.05rem', fontWeight: 800, color: '#f8fafc', marginBottom: '14px', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <User size={18} color="#14b8a6" /> {t('personalProfile')}
          </h3>

          {resident ? (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', fontSize: '0.84rem' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', paddingBottom: '6px', borderBottom: '1px solid rgba(255, 255, 255, 0.08)' }}>
                <span style={{ color: '#94a3b8' }}>{t('fullName')}:</span>
                <strong style={{ color: '#f8fafc' }}>{resident.full_name}</strong>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', paddingBottom: '6px', borderBottom: '1px solid rgba(255, 255, 255, 0.08)' }}>
                <span style={{ color: '#94a3b8' }}>{t('ageBloodGroup')}:</span>
                <strong style={{ color: '#14b8a6' }}>{resident.age} yrs • Blood {resident.blood_group}</strong>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', paddingBottom: '6px', borderBottom: '1px solid rgba(255, 255, 255, 0.08)' }}>
                <span style={{ color: '#94a3b8' }}>{t('roomNumber')}:</span>
                <strong style={{ color: '#f8fafc' }}>{resident.address || `Room ${resident.room_number}`}</strong>
              </div>
              <div>
                <span style={{ color: '#94a3b8', display: 'block', marginBottom: '4px' }}>{t('medicalNotes')}:</span>
                <div style={{ background: 'rgba(15, 23, 42, 0.6)', padding: '8px', borderRadius: '6px', color: '#cbd5e1', fontSize: '0.8rem' }}>
                  {resident.medical_notes || 'None recorded'}
                </div>
              </div>
            </div>
          ) : (
            <p style={{ color: '#94a3b8' }}>No resident profile linked.</p>
          )}
        </div>

      </div>

      {/* Guardian Management Roster */}
      <div className="glass-card" style={{ padding: '24px', marginBottom: '28px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
          <h3 style={{ fontSize: '1.15rem', fontWeight: 800, color: '#f8fafc', margin: 0, display: 'flex', alignItems: 'center', gap: '8px' }}>
            <Phone size={18} color="#3b82f6" /> {t('linkedGuardians')} ({guardians.length})
          </h3>
          <button className="btn btn-secondary" style={{ padding: '6px 12px', fontSize: '0.82rem' }} onClick={() => setIsGuardianModalOpen(true)}>
            <Plus size={15} /> {t('addGuardian')}
          </button>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: '16px' }}>
          {guardians.map(g => (
            <div key={g.id} style={{ background: 'rgba(15, 23, 42, 0.6)', border: '1px solid rgba(255, 255, 255, 0.08)', borderRadius: '12px', padding: '14px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <strong style={{ color: '#f8fafc', fontSize: '0.95rem', display: 'block' }}>{g.name}</strong>
                <span style={{ fontSize: '0.78rem', color: '#14b8a6', textTransform: 'uppercase', fontWeight: 700 }}>{g.relationship}</span>
                <div style={{ color: '#94a3b8', fontSize: '0.82rem', marginTop: '4px' }}>📞 {g.phone}</div>
              </div>
              <button onClick={() => handleDeleteGuardian(g.id)} style={{ background: 'none', border: 'none', color: '#f87171', cursor: 'pointer' }}>
                <Trash2 size={16} />
              </button>
            </div>
          ))}
        </div>
      </div>

      {/* Active Incident History */}
      <div className="glass-card" style={{ padding: '28px' }}>
        <h3 style={{ fontSize: '1.2rem', fontWeight: 800, color: '#f8fafc', marginBottom: '18px', display: 'flex', alignItems: 'center', gap: '8px' }}>
          <Clock size={20} color="#f59e0b" /> {t('emergencyHistory')}
        </h3>

        {incidents.length === 0 ? (
          <p style={{ color: '#94a3b8', margin: 0 }}>No emergency incidents recorded.</p>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
            {incidents.map(inc => (
              <div key={inc.id} style={{ background: 'rgba(15, 23, 42, 0.6)', border: '1px solid rgba(255, 255, 255, 0.08)', borderRadius: '12px', padding: '16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <strong style={{ color: '#f8fafc' }}>{inc.incident_code}</strong>
                    <span className={`badge badge-${inc.status === 'Resolved' ? 'safe' : inc.status === 'Pending' ? 'emergency' : 'alert'}`}>
                      {inc.status}
                    </span>
                    <span style={{ fontSize: '0.8rem', color: '#94a3b8' }}>• {inc.emergency_type}</span>
                  </div>
                  <p style={{ color: '#cbd5e1', fontSize: '0.85rem', margin: '6px 0 0 0' }}>{inc.description}</p>
                  <span style={{ fontSize: '0.78rem', color: '#3b82f6', display: 'block', marginTop: '4px' }}>
                    📍 Location: {inc.location}
                  </span>
                  {inc.responder_name && (
                    <span style={{ fontSize: '0.78rem', color: '#10b981', display: 'block', marginTop: '2px' }}>
                      ✓ Assigned Responder: {inc.responder_name} ({inc.responder_role})
                    </span>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Add Guardian Modal */}
      {isGuardianModalOpen && (
        <div className="modal-overlay">
          <div className="modal-container">
            <h3 style={{ margin: '0 0 18px 0', color: '#f8fafc' }}>Add Emergency Guardian</h3>
            <form onSubmit={handleAddGuardian}>
              <div className="form-group">
                <label>Guardian Name *</label>
                <input
                  type="text"
                  className="form-input"
                  placeholder="e.g. Ramesh"
                  value={newGuardian.name}
                  onChange={(e) => setNewGuardian({ ...newGuardian, name: e.target.value })}
                  required
                />
              </div>
              <div className="form-group">
                <label>Relationship *</label>
                <select
                  className="form-input"
                  value={newGuardian.relationship}
                  onChange={(e) => setNewGuardian({ ...newGuardian, relationship: e.target.value })}
                >
                  <option value="Father">Father</option>
                  <option value="Mother">Mother</option>
                  <option value="Brother">Brother</option>
                  <option value="Sister">Sister</option>
                  <option value="Friend">Friend</option>
                  <option value="Spouse">Spouse</option>
                </select>
              </div>
              <div className="form-group">
                <label>Phone Number *</label>
                <input
                  type="text"
                  className="form-input"
                  placeholder="+1-555-0199"
                  value={newGuardian.phone}
                  onChange={(e) => setNewGuardian({ ...newGuardian, phone: e.target.value })}
                  required
                />
              </div>
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '20px' }}>
                <button type="button" className="btn btn-secondary" onClick={() => setIsGuardianModalOpen(false)}>Cancel</button>
                <button type="submit" className="btn btn-primary">Save Guardian</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </main>
  );
}
