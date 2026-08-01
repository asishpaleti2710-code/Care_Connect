from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class SOSCreate(BaseModel):
    resident_id: int
    alert_type: Optional[str] = "Medical Emergency"
    message: Optional[str] = None

class SOSResponse(BaseModel):
    id: int
    resident_id: int
    alert_type: str
    message: Optional[str]
    status: str
    created_at: datetime
    resolved_at: Optional[datetime]

    class Config:
        from_attributes = True
