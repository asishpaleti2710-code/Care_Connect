from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class IncidentCreate(BaseModel):
    resident_id: int
    emergency_type: Optional[str] = "Medical Emergency"
    priority: Optional[str] = "High"
    description: Optional[str] = None
    location: Optional[str] = None

class IncidentStatusUpdate(BaseModel):
    status: str  # Pending, Accepted, In Progress, Resolved

class IncidentResponse(BaseModel):
    id: int
    incident_code: str
    resident_id: int
    emergency_type: str
    priority: str
    description: Optional[str] = None
    location: Optional[str] = None
    status: str
    responder_id: Optional[int] = None
    responder_name: Optional[str] = None
    responder_role: Optional[str] = None
    created_at: datetime
    accepted_at: Optional[datetime] = None
    resolved_at: Optional[datetime] = None

    class Config:
        from_attributes = True
