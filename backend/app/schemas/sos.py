from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime

class SOSCreate(BaseModel):
    resident_id: Optional[int] = None
    category: Optional[str] = "Medical Emergency"
    alert_type: Optional[str] = None  # Backwards compatibility
    message: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    priority: Optional[str] = "CRITICAL"

class SOSStatusUpdate(BaseModel):
    status: str
    notes: Optional[str] = None

class SOSRespondRequest(BaseModel):
    notes: Optional[str] = None

class SOSResolveRequest(BaseModel):
    notes: Optional[str] = None

class SOSCancelRequest(BaseModel):
    reason: Optional[str] = None

class SOSAuditResponse(BaseModel):
    id: int
    sos_id: int
    previous_status: Optional[str] = None
    new_status: str
    action_by_id: Optional[int] = None
    action_by_name: Optional[str] = None
    action_by_role: Optional[str] = None
    notes: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

class SOSResponse(BaseModel):
    id: int
    resident_id: int
    user_id: Optional[int] = None
    alert_type: str = "Medical Emergency"
    category: str = "Medical Emergency"
    message: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    maps_url: Optional[str] = None
    priority: str = "CRITICAL"
    status: str = "ACTIVE"
    created_at: datetime
    activated_at: Optional[datetime] = None
    acknowledged_at: Optional[datetime] = None
    responding_at: Optional[datetime] = None
    resolved_at: Optional[datetime] = None
    cancelled_at: Optional[datetime] = None
    
    responder_id: Optional[int] = None
    responder_name: Optional[str] = None
    responder_role: Optional[str] = None
    response_notes: Optional[str] = None

    # Auxiliary populated fields
    resident_name: Optional[str] = None
    resident_room: Optional[str] = None
    time_to_acknowledge_seconds: Optional[float] = None
    time_to_respond_seconds: Optional[float] = None
    time_to_resolve_seconds: Optional[float] = None
    audit_logs: Optional[List[SOSAuditResponse]] = []

    class Config:
        from_attributes = True

class SOSAnalyticsResponse(BaseModel):
    total_alerts: int
    active_alerts: int
    acknowledged_alerts: int
    responding_alerts: int
    resolved_alerts: int
    cancelled_alerts: int
    avg_acknowledge_time_minutes: float
    avg_response_time_minutes: float
    avg_resolve_time_minutes: float
    category_breakdown: Dict[str, int]
    priority_breakdown: Dict[str, int]
