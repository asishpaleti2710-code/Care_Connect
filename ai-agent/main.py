import logging

from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, Dict, Any
from agent_service import ai_service

logger = logging.getLogger(__name__)

app = FastAPI(title="CareConnect AI Agent Service", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class EmergencyClassifyRequest(BaseModel):
    description: str

class RiskAnalysisRequest(BaseModel):
    full_name: str
    age: int
    medical_notes: str

class ChatQueryRequest(BaseModel):
    query: str
    context: Optional[Dict[str, Any]] = None

@app.get("/")
def root():
    return {
        "service": "CareConnect AI Agent Emergency Classifier",
        "status": "online",
        "version": "2.0.0"
    }

@app.post("/api/ai/classify-emergency")
def classify_emergency(req: EmergencyClassifyRequest):
    try:
        return ai_service.classify_emergency(req.description)
    except Exception:
        logger.exception("Emergency classification failed")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Emergency classification failed")

@app.post("/api/ai/analyze-notes")
def analyze_resident_notes(req: RiskAnalysisRequest):
    try:
        return ai_service.analyze_medical_notes(req.full_name, req.age, req.medical_notes)
    except Exception:
        logger.exception("Medical notes analysis failed")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Medical notes analysis failed")

@app.post("/api/ai/chat")
def chat_with_agent(req: ChatQueryRequest):
    try:
        return {"query": req.query, "reply": ai_service.answer_caregiver_query(req.query, req.context)}
    except Exception:
        logger.exception("AI chat query failed")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="AI chat query failed")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
