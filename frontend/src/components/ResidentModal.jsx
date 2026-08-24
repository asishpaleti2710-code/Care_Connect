import React, { useState, useEffect } from 'react';
import { X, Sparkles, UserPlus, Save, AlertCircle, MapPin, Compass } from 'lucide-react';
import { api } from '../services/api';
import { useGeolocation } from '../hooks/useGeolocation';
import { riskBadgeClass } from '../utils/status';

export default function ResidentModal({ isOpen, onClose, onSave, resident = null }) {
  const geo = useGeolocation();

  const [formData, setFormData] = useState({
    full_name: '',
    age: '',
    room_number: '',
    address: '',
    medical_notes: '',
    emergency_contact: '',
    status: 'safe'
  });

  const [aiAnalysis, setAiAnalysis] = useState(null);
  const [analyzing, setAnalyzing] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (resident) {
      setFormData({
        full_name: resident.full_name || '',
        age: resident.age || '',
        room_number: resident.room_number || '',
        address: resident.address || '',
        medical_notes: resident.medical_notes || '',
        emergency_contact: resident.emergency_contact || '',
        status: resident.status || 'safe'
      });
    } else {
      setFormData({
        full_name: '',
        age: '',
        room_number: '',
        address: '',
        medical_notes: '',
        emergency_contact: '',
        status: 'safe'
      });
    }
    setAiAnalysis(null);
    setError('');
  }, [resident, isOpen]);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleDetectLocation = () => {
    geo.requestLocation();
  };

  useEffect(() => {
    if (geo.address && !formData.address) {
      setFormData(prev => ({ ...prev, address: geo.address }));
    }
  }, [geo.address]);

  const handleAnalyzeAI = async () => {
    if (!formData.medical_notes) {
      setError('Please enter medical notes first to perform AI analysis.');
      return;
    }
    setAnalyzing(true);
    setError('');
    try {
      const res = await api.analyzeNotes(
        formData.full_name || 'Resident',
        parseInt(formData.age) || 75,
        formData.medical_notes
      );
      setAiAnalysis(res);
    } catch (err) {
      setError('Could not reach AI analysis service.');
    } finally {
      setAnalyzing(false);
    }
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!formData.full_name || !formData.age || !formData.room_number || !formData.emergency_contact) {
      setError('Please fill in all required fields.');
      return;
    }
    onSave({
      ...formData,
      age: parseInt(formData.age)
    });
  };

  if (!isOpen) return null;

  return (
    <div className="modal-overlay">
      <div className="modal-container">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
          <h2 style={{ fontSize: '1.3rem', fontWeight: 800, margin: 0, display: 'flex', alignItems: 'center', gap: '8px' }}>
            <UserPlus size={22} color="#14b8a6" />
            {resident ? 'Edit Resident Profile' : 'Register New Resident'}
          </h2>
          <button onClick={onClose} style={{ background: 'none', border: 'none', color: '#94a3b8', cursor: 'pointer' }}>
            <X size={22} />
          </button>
        </div>

        {error && (
          <div style={{
            background: 'rgba(239, 68, 68, 0.15)',
            border: '1px solid rgba(239, 68, 68, 0.3)',
            color: '#f87171',
            padding: '10px 14px',
            borderRadius: '8px',
            marginBottom: '16px',
            fontSize: '0.85rem',
            display: 'flex',
            alignItems: 'center',
            gap: '8px'
          }}>
            <AlertCircle size={16} />
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label>Full Name *</label>
            <input
              type="text"
              name="full_name"
              className="form-input"
              placeholder="e.g. Margaret Thatcher"
              value={formData.full_name}
              onChange={handleChange}
              required
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
            <div className="form-group">
              <label>Age *</label>
              <input
                type="number"
                name="age"
                className="form-input"
                placeholder="78"
                value={formData.age}
                onChange={handleChange}
                required
              />
            </div>
            <div className="form-group">
              <label>Room Number *</label>
              <input
                type="text"
                name="room_number"
                className="form-input"
                placeholder="104-A"
                value={formData.room_number}
                onChange={handleChange}
                required
              />
            </div>
          </div>

          <div className="form-group">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
              <label style={{ margin: 0 }}>Physical Address / GPS Location</label>
              <button
                type="button"
                onClick={handleDetectLocation}
                style={{
                  background: 'none',
                  border: 'none',
                  color: '#14b8a6',
                  fontSize: '0.8rem',
                  fontWeight: 600,
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '4px'
                }}
              >
                <Compass size={14} className={geo.loading ? 'spin' : ''} />
                {geo.loading ? 'Detecting...' : 'Auto-Detect GPS'}
              </button>
            </div>
            <input
              type="text"
              name="address"
              className="form-input"
              placeholder="Building A, Sector 4, Room 104"
              value={formData.address}
              onChange={handleChange}
            />
          </div>

          <div className="form-group">
            <label>Emergency Contact *</label>
            <input
              type="text"
              name="emergency_contact"
              className="form-input"
              placeholder="+1-555-0199"
              value={formData.emergency_contact}
              onChange={handleChange}
              required
            />
          </div>

          <div className="form-group">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
              <label style={{ margin: 0 }}>Medical Notes & Care Instructions</label>
              <button
                type="button"
                onClick={handleAnalyzeAI}
                style={{
                  background: 'none',
                  border: 'none',
                  color: '#c084fc',
                  fontSize: '0.8rem',
                  fontWeight: 600,
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '4px'
                }}
              >
                <Sparkles size={14} />
                {analyzing ? 'Analyzing...' : 'AI Risk Check'}
              </button>
            </div>
            <textarea
              name="medical_notes"
              className="form-input"
              rows={3}
              placeholder="Known conditions, daily medication times, allergies..."
              value={formData.medical_notes}
              onChange={handleChange}
            />
          </div>

          {aiAnalysis && (
            <div style={{
              background: 'rgba(139, 92, 246, 0.15)',
              border: '1px solid rgba(139, 92, 246, 0.3)',
              borderRadius: '10px',
              padding: '12px 14px',
              marginBottom: '18px',
              fontSize: '0.85rem'
            }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                <strong style={{ color: '#c084fc', display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <Sparkles size={14} /> AI Health Assessment
                </strong>
                <span className={riskBadgeClass(aiAnalysis.risk_level)}>
                  {aiAnalysis.risk_level} Risk ({aiAnalysis.risk_score}%)
                </span>
              </div>
              <p style={{ color: '#e2e8f0', margin: '4px 0 8px 0' }}>{aiAnalysis.summary}</p>
              {aiAnalysis.recommendations.map((rec, idx) => (
                <div key={idx} style={{ color: '#94a3b8', fontSize: '0.78rem' }}>• {rec}</div>
              ))}
            </div>
          )}

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '24px' }}>
            <button type="button" className="btn btn-secondary" onClick={onClose}>
              Cancel
            </button>
            <button type="submit" className="btn btn-primary">
              <Save size={18} />
              <span>{resident ? 'Update Profile' : 'Save Resident'}</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
