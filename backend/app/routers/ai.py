from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from typing import Optional, Dict, Any

router = APIRouter(prefix="/api/ai", tags=["AI Agent"])

class EmergencyClassifyRequest(BaseModel):
    description: str

class RiskAnalysisRequest(BaseModel):
    full_name: str
    age: int
    medical_notes: str

class ChatQueryRequest(BaseModel):
    query: str
    context: Optional[Dict[str, Any]] = None

def classify_emergency_logic(description: str) -> Dict[str, Any]:
    text = description.lower() if description else ""

    if any(kw in text for kw in ["break in", "intruder", "thief", "gun", "knife", "threat", "attack"]):
        category = "Security Threat"
        priority = "Critical"
        suggested_responders = ["Security", "Guardians", "Admin"]
        advice = "Lock all doors, stay hidden, and move away from windows. Security officers have been dispatched to your location."
    elif any(kw in text for kw in ["fell", "fall", "slipped", "trip", "collapsed", "unconscious"]):
        category = "Fall Incident"
        priority = "High"
        suggested_responders = ["Volunteers", "Security", "Guardians"]
        advice = "Do not attempt to stand up quickly if spinal injury is suspected. Keep warm and wait for responder dispatch."
    elif any(kw in text for kw in ["chest pain", "heart", "stroke", "bleeding", "seizure", "breathing", "breath"]):
        category = "Medical Emergency"
        priority = "Critical"
        suggested_responders = ["Medical Volunteers", "Guardians", "Admin"]
        advice = "Sit upright, loosen tight clothing, try to maintain calm breathing. Emergency medical team notified."
    elif any(kw in text for kw in ["fire", "smoke", "gas", "leak"]):
        category = "Fire & Safety"
        priority = "Critical"
        suggested_responders = ["Security", "Building Admin"]
        advice = "Evacuate the area immediately via nearest safety exit. Do NOT use elevators."
    else:
        category = "General Emergency"
        priority = "High"
        suggested_responders = ["Volunteers", "Security", "Guardians"]
        advice = "Your emergency signal has been broadcast. On-duty responders are reviewing your request."

    return {
        "description": description,
        "category": category,
        "priority": priority,
        "suggested_responders": suggested_responders,
        "immediate_advice": advice
    }

def analyze_medical_notes_logic(full_name: str, age: int, medical_notes: str) -> Dict[str, Any]:
    notes_lower = medical_notes.lower() if medical_notes else ""
    matched_high = [kw for kw in ["fall", "pacemaker", "cardiac", "stroke", "seizure"] if kw in notes_lower]
    matched_mod = [kw for kw in ["hypertension", "diabetes", "arthritis", "dementia"] if kw in notes_lower]

    if matched_high or age >= 85:
        risk_level = "High"
        risk_score = 85
        summary = f"High monitoring recommended for {full_name}. Identified risk factors: {', '.join(matched_high) if matched_high else 'Advanced age'}."
        recommendations = [
            "Ensure emergency call button is within arm reach at all times.",
            "Schedule vitals check twice daily.",
            "Flag room for frequent night checks."
        ]
    elif matched_mod or age >= 75:
        risk_level = "Moderate"
        risk_score = 55
        summary = f"Moderate monitoring for {full_name}. Observations: {', '.join(matched_mod) if matched_mod else 'Routine age care'}."
        recommendations = [
            "Daily blood pressure and medication adherence check.",
            "Encourage light mobility exercises."
        ]
    else:
        risk_level = "Low"
        risk_score = 20
        summary = f"Standard routine care for {full_name}."
        recommendations = [
            "Standard weekly wellness check-in."
        ]

    return {
        "resident_name": full_name,
        "risk_level": risk_level,
        "risk_score": risk_score,
        "summary": summary,
        "recommendations": recommendations
    }

def answer_caregiver_query_logic(query: str, context: Dict[str, Any] = None) -> str:
    q_lower = query.lower()
    if "fall" in q_lower or "emergency" in q_lower or "sos" in q_lower:
        return "🚨 **Emergency Protocol**: Immediately dispatch caregiver/volunteer to resident room. Check consciousness & breathing. Do NOT move resident if spinal injury suspected."
    elif "bp" in q_lower or "blood pressure" in q_lower:
        return "🩺 **Blood Pressure Guidance**: Normal senior range is below 130/80. If >160/100, re-test in 15 mins and notify physician."
    elif "dementia" in q_lower or "memory" in q_lower:
        return "🧠 **Cognitive Care**: Speak in calm, short sentences. Use orientation cues (clocks, photos) and gently redirect attention."
    else:
        return f"🤖 **CareConnect AI Assistant**: Query '{query}' recorded. Check resident profile or trigger SOS panic button for urgent distress."

@router.post("/classify-emergency")
def classify_emergency(req: EmergencyClassifyRequest):
    try:
        return classify_emergency_logic(req.description)
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

@router.post("/analyze-notes")
def analyze_resident_notes(req: RiskAnalysisRequest):
    try:
        return analyze_medical_notes_logic(req.full_name, req.age, req.medical_notes)
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

@router.post("/chat")
def chat_with_agent(req: ChatQueryRequest):
    try:
        return {"query": req.query, "reply": answer_caregiver_query_logic(req.query, req.context)}
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))
