from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Callable, Optional, Dict, Any, TypeVar
from agent_service import ai_service

T = TypeVar("T")


def run_ai(handler: Callable[..., T], *args) -> T:
    """Invoke an AI service call, surfacing failures as HTTP 500 responses."""
    try:
        return handler(*args)
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

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
    return run_ai(ai_service.classify_emergency, req.description)

@app.post("/api/ai/analyze-notes")
def analyze_resident_notes(req: RiskAnalysisRequest):
    return run_ai(ai_service.analyze_medical_notes, req.full_name, req.age, req.medical_notes)

@app.post("/api/ai/chat")
def chat_with_agent(req: ChatQueryRequest):
    reply = run_ai(ai_service.answer_caregiver_query, req.query, req.context)
    return {"query": req.query, "reply": reply}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
