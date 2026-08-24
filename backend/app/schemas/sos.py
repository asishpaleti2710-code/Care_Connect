from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class SOSCreate(BaseModel):
    resident_id: int = Field(gt=0)
    alert_type: Optional[str] = Field(default="Medical Emergency", max_length=80)
    message: Optional[str] = Field(default=None, max_length=2000)

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
