import os

from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
from agent_service import ai_service
from auth import require_token
from config import settings

app = FastAPI(title="CareConnect AI Agent Service", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)

class EmergencyClassifyRequest(BaseModel):
    description: str = Field(min_length=1, max_length=2000)

class RiskAnalysisRequest(BaseModel):
    full_name: str = Field(min_length=1, max_length=120)
    age: int = Field(ge=0, le=130)
    medical_notes: str = Field(default="", max_length=5000)

class ChatQueryRequest(BaseModel):
    query: str = Field(min_length=1, max_length=2000)
    context: Optional[Dict[str, Any]] = None

@app.get("/")
def root():
    return {
        "service": "CareConnect AI Agent Emergency Classifier",
        "status": "online",
        "version": "2.0.0"
    }

@app.post("/api/ai/classify-emergency")
def classify_emergency(req: EmergencyClassifyRequest, _=Depends(require_token)):
    try:
        return ai_service.classify_emergency(req.description)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Emergency classification failed",
        )

@app.post("/api/ai/analyze-notes")
def analyze_resident_notes(req: RiskAnalysisRequest, _=Depends(require_token)):
    try:
        return ai_service.analyze_medical_notes(req.full_name, req.age, req.medical_notes)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Medical note analysis failed",
        )

@app.post("/api/ai/chat")
def chat_with_agent(req: ChatQueryRequest, _=Depends(require_token)):
    try:
        return {"query": req.query, "reply": ai_service.answer_caregiver_query(req.query, req.context)}
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="AI assistant request failed",
        )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        host=os.getenv("AI_AGENT_HOST", "127.0.0.1"),
        port=int(os.getenv("AI_AGENT_PORT", "8001")),
    )
