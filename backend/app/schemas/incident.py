from pydantic import BaseModel, Field
from typing import Literal, Optional
from datetime import datetime

class IncidentCreate(BaseModel):
    resident_id: int = Field(gt=0)
    emergency_type: Optional[str] = Field(default="Medical Emergency", max_length=80)
    priority: Optional[Literal["Low", "Moderate", "High", "Critical"]] = "High"
    description: Optional[str] = Field(default=None, max_length=2000)
    location: Optional[str] = Field(default=None, max_length=200)

class IncidentStatusUpdate(BaseModel):
    status: Literal["Pending", "Accepted", "In Progress", "Resolved"]

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
