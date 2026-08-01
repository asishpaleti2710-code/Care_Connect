import React, { useState } from 'react';
import { Sparkles, Send, X, Bot, User, Stethoscope } from 'lucide-react';
import { api } from '../services/api';

export default function AIAssistantWidget({ isOpen, onClose }) {
  const [messages, setMessages] = useState([
    {
      sender: 'bot',
      text: 'Hello! I am your CareConnect AI Assistant. Ask me about resident emergency protocols, blood pressure guidelines, dementia care routines, or medication notes.'
    }
  ]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);

  if (!isOpen) return null;

  const getLocalFallbackReply = (query) => {
    const q = query.lower ? query.lower() : query.toLowerCase();
    if (q.includes("fall")) {
      return "🚨 **Fall Emergency Protocol**: 1) Do NOT move resident if head/spinal injury is suspected. 2) Check breathing & consciousness. 3) Keep resident warm with a blanket. 4) Trigger SOS panic alert to dispatch Security & Medical Volunteers.";
    } else if (q.includes("bp") || q.includes("blood pressure")) {
      return "🩺 **Blood Pressure Standards**: Normal senior target is <130/80 mmHg. If reading exceeds 160/100, re-measure in 15 mins. If accompanied by chest pain or dizziness, press SOS panic button immediately.";
    } else if (q.includes("dementia") || q.includes("memory")) {
      return "🧠 **Dementia Care Guidance**: Maintain a structured daily routine, speak in calm simple sentences, use visual orientation cues (clocks/calendars), and gently redirect agitation without arguing.";
    } else if (q.includes("sos") || q.includes("emergency") || q.includes("panic")) {
      return "⚡ **CareConnect SOS System**: Press the red SOS button on your Resident or Navbar portal. It broadcasts immediate location coordinates to on-duty Security and sends SMS alerts to linked Guardians.";
    } else if (q.includes("medication") || q.includes("pill") || q.includes("dose")) {
      return "💊 **Medication Safety**: Verify 5 Rights: Right Patient, Right Drug, Right Dose, Right Route, and Right Time. Log all doses in the Resident Medical Record.";
    } else {
      return `🤖 **CareConnect Medical Assistant**: Query "${query}" recorded. Always verify urgent medical symptoms with on-duty clinical staff or trigger the SOS Emergency Alert.`;
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
            <h3 style={{ margin: 0, fontSize: '1rem', fontWeight: 700, color: '#f8fafc' }}>AI Care Assistant</h3>
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
