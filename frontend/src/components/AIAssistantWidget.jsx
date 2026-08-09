import React, { useState } from 'react';
import { Sparkles, Send, X, Bot, User, Stethoscope } from 'lucide-react';
import { api } from '../services/api';

export default function AIAssistantWidget({ isOpen, onClose }) {
  const [messages, setMessages] = useState([
    {
      sender: 'bot',
      text: 'Hello! I am CarePulse AI, your intelligent medical care assistant. Ask me about resident emergency protocols, blood pressure guidelines, dementia care routines, or medication notes.'
    }
  ]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);

  if (!isOpen) return null;

  const getLocalFallbackReply = (query) => {
    const q = query ? query.toLowerCase() : "";

    // Medicines DB
    if (q.includes("paracetamol") || q.includes("acetaminophen")) {
      return "💊 **Paracetamol / Acetaminophen (Pain & Fever)**:\n• Dosage: 500mg-1000mg q4-6h (Max 4g/day).\n• Warning: Watch daily limit to protect liver. Avoid alcohol.";
    } else if (q.includes("ibuprofen") || q.includes("advil")) {
      return "💊 **Ibuprofen (NSAID)**:\n• Dosage: 200mg-400mg q6-8h with food.\n• Warning: Take with food to protect stomach. Caution in seniors with hypertension or kidney conditions.";
    } else if (q.includes("aspirin")) {
      return "💊 **Aspirin (Antiplatelet / Cardioprotective)**:\n• Dosage: 81mg daily for heart protection, or 325mg chewed immediately for acute chest pain emergency.";
    } else if (q.includes("amlodipine") || q.includes("norvasc")) {
      return "💊 **Amlodipine (Blood Pressure)**:\n• Dosage: 5mg-10mg daily.\n• Indications: Hypertension & Angina. Monitor for ankle swelling or dizziness.";
    } else if (q.includes("lisinopril") || q.includes("metoprolol")) {
      return "💊 **Lisinopril / Metoprolol (Blood Pressure & Cardiac)**:\n• Indications: Hypertension, Angina, Heart failure.\n• Warning: Monitor blood pressure & pulse before administering.";
    } else if (q.includes("metformin") || q.includes("insulin")) {
      return "💊 **Metformin / Insulin (Diabetes Control)**:\n• Metformin: 500mg-1000mg with meals.\n• Insulin: Per sliding scale. Always keep 15g fast-acting sugar nearby for hypoglycemia risk.";
    } else if (q.includes("nitroglycerin")) {
      return "💊 **Nitroglycerin (Acute Chest Pain / Angina)**:\n• Dosage: 1 sublingual dose under tongue every 5 mins up to 3 doses. Press SOS immediately if pain persists after 1st dose.";
    } else if (q.includes("medication") || q.includes("medicine") || q.includes("pill") || q.includes("drug")) {
      return "💊 **5 Rights of Medication Safety**:\n1) Right Patient 2) Right Drug 3) Right Dose 4) Right Route 5) Right Time. Store drugs in a cool dry place and log all doses.";
    }

    // Medical Vitals & Emergencies
    else if (q.includes("bp") || q.includes("blood pressure") || q.includes("vitals")) {
      return "🩺 **Senior Vitals Reference Ranges**:\n• BP: Target <120/80 mmHg. (>180/120 is Hypertensive Crisis ➔ Press SOS).\n• Pulse: 60-100 bpm at rest.\n• SpO2: 95%-100% on room air.\n• Temp: 97.8°F-99.1°F.";
    } else if (q.includes("stroke") || q.includes("fast")) {
      return "🧠 **Stroke F.A.S.T. Warning**:\n• **F**ace drooping • **A**rm weakness • **S**peech difficulty • **T**ime to press SOS immediately!";
    } else if (q.includes("heart attack") || q.includes("chest pain")) {
      return "🚨 **Cardiac Emergency**: Sit upright, loosen tight clothes, give 325mg Aspirin to chew if not allergic, and press red CareConnect SOS button immediately!";
    } else if (q.includes("fall")) {
      return "🚨 **Fall Emergency Protocol**: Do NOT force resident to stand up if head or spinal injury is suspected. Keep resident warm & press red SOS button for responder dispatch.";
    } else if (q.includes("seizure")) {
      return "⚡ **Seizure Protocol**: Turn resident onto side (recovery position). Do NOT place objects in mouth. Clear sharp hazards. Time seizure duration.";
    } else if (q.includes("dementia") || q.includes("memory")) {
      return "🧠 **Dementia Care Guidance**: Maintain daily routine, use simple reassuring sentences, visual clocks/photos, and gently redirect agitation without arguing.";
    }

    // CareConnect App
    else if (q.includes("app") || q.includes("careconnect") || q.includes("portal") || q.includes("role")) {
      return "📱 **CareConnect Platform**: Features 6 role portals — Resident SOS, Security Responders, Volunteer Network, Family Guardians, Caregiver Roster, and Admin Command Center.";
    } else if (q.includes("sos") || q.includes("emergency") || q.includes("panic")) {
      return "⚡ **CareConnect SOS System**: Pressing the red SOS button broadcasts live location coordinates & medical profile to Security, Volunteers, and notifies Guardians.";
    } else {
      return `🤖 **CarePulse AI**: Query "${query}" recorded. Ask me about any medicine (Paracetamol, Ibuprofen, Amlodipine, Insulin), medical vitals, stroke/cardiac protocols, or CareConnect app features!`;
    }
  };

  const handleSend = async (e) => {
    e.preventDefault();
    if (!input.trim() || loading) return;

    const userMsg = input.trim();
    setInput('');
    setMessages(prev => [...prev, { sender: 'user', text: userMsg }]);
    setLoading(true);

    try {
      const res = await api.chatAI(userMsg);
      setMessages(prev => [...prev, { sender: 'bot', text: res.reply }]);
    } catch (err) {
      console.warn("AI Agent remote service unreachable, using local medical intelligence fallback:", err);
      const fallbackReply = getLocalFallbackReply(userMsg);
      setMessages(prev => [...prev, { sender: 'bot', text: fallbackReply }]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{
      position: 'fixed',
      bottom: '24px',
      right: '24px',
      width: '420px',
      height: '560px',
      background: 'rgba(30, 41, 59, 0.95)',
      backdropFilter: 'blur(20px)',
      border: '1px solid rgba(139, 92, 246, 0.4)',
      borderRadius: '20px',
      boxShadow: '0 12px 40px rgba(0, 0, 0, 0.6)',
      display: 'flex',
      flexDirection: 'column',
      zIndex: 90,
      overflow: 'hidden'
    }}>
      {/* Header */}
      <div style={{
        padding: '16px 20px',
        background: 'linear-gradient(135deg, rgba(139, 92, 246, 0.3) 0%, rgba(20, 184, 166, 0.2) 100%)',
        borderBottom: '1px solid rgba(255, 255, 255, 0.1)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between'
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <div style={{
            width: '34px',
            height: '34px',
            borderRadius: '10px',
            background: 'linear-gradient(135deg, #8b5cf6 0%, #6d28d9 100%)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center'
          }}>
            <Sparkles size={18} color="#ffffff" />
          </div>
          <div>
            <h3 style={{ margin: 0, fontSize: '1rem', fontWeight: 700, color: '#f8fafc' }}>CarePulse AI</h3>
            <span style={{ fontSize: '0.72rem', color: '#10b981', display: 'flex', alignItems: 'center', gap: '4px' }}>
              <span style={{ width: '6px', height: '6px', borderRadius: '50%', background: '#10b981' }} />
              Active Medical Intelligence
            </span>
          </div>
        </div>
        <button onClick={onClose} style={{ background: 'none', border: 'none', color: '#94a3b8', cursor: 'pointer' }}>
          <X size={20} />
        </button>
      </div>

      {/* Quick Prompt Pills */}
      <div style={{
        display: 'flex',
        gap: '6px',
        padding: '8px 12px',
        background: 'rgba(15, 23, 42, 0.4)',
        overflowX: 'auto',
        borderBottom: '1px solid rgba(255, 255, 255, 0.05)'
      }}>
        {['Fall Protocol', 'Blood Pressure', 'Dementia Care'].map((tag, idx) => (
          <button
            key={idx}
            onClick={() => setInput(tag)}
            style={{
              background: 'rgba(255, 255, 255, 0.08)',
              border: '1px solid rgba(255, 255, 255, 0.1)',
              color: '#cbd5e1',
              borderRadius: '9999px',
              padding: '3px 10px',
              fontSize: '0.72rem',
              whiteSpace: 'nowrap',
              cursor: 'pointer'
            }}
          >
            {tag}
          </button>
        ))}
      </div>

      {/* Messages Feed */}
      <div style={{
        flex: 1,
        padding: '16px',
        overflowY: 'auto',
        display: 'flex',
        flexDirection: 'column',
        gap: '12px'
      }}>
        {messages.map((msg, index) => (
          <div
            key={index}
            style={{
              alignSelf: msg.sender === 'user' ? 'flex-end' : 'flex-start',
              maxWidth: '85%',
              display: 'flex',
              gap: '8px',
              flexDirection: msg.sender === 'user' ? 'row-reverse' : 'row'
            }}
          >
            <div style={{
              width: '28px',
              height: '28px',
              borderRadius: '50%',
              background: msg.sender === 'user' ? '#14b8a6' : '#8b5cf6',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              flexShrink: 0
            }}>
              {msg.sender === 'user' ? <User size={14} color="#fff" /> : <Bot size={14} color="#fff" />}
            </div>

            <div style={{
              background: msg.sender === 'user'
                ? 'linear-gradient(135deg, #14b8a6 0%, #0d9488 100%)'
                : 'rgba(15, 23, 42, 0.7)',
              border: msg.sender === 'bot' ? '1px solid rgba(255, 255, 255, 0.1)' : 'none',
              padding: '10px 14px',
              borderRadius: '14px',
              color: '#f8fafc',
              fontSize: '0.85rem',
              lineHeight: 1.45
            }}>
              {msg.text}
            </div>
          </div>
        ))}
        {loading && (
          <div style={{ alignSelf: 'flex-start', color: '#94a3b8', fontSize: '0.8rem', fontStyle: 'italic' }}>
            Thinking...
          </div>
        )}
      </div>

      {/* Input Form */}
      <form onSubmit={handleSend} style={{
        padding: '12px',
        background: 'rgba(15, 23, 42, 0.8)',
        borderTop: '1px solid rgba(255, 255, 255, 0.1)',
        display: 'flex',
        gap: '8px'
      }}>
        <input
          type="text"
          className="form-input"
          placeholder="Ask caregiver advice..."
          value={input}
          onChange={(e) => setInput(e.target.value)}
          style={{ flex: 1, padding: '10px 14px', fontSize: '0.85rem' }}
        />
        <button type="submit" className="btn btn-primary" style={{ padding: '10px 16px' }} disabled={loading}>
          <Send size={16} />
        </button>
      </form>
    </div>
  );
}
