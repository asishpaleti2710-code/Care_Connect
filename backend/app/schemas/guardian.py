from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime

class GuardianCreate(BaseModel):
    resident_id: int
    name: str
    relationship: str
    phone: str
    email: Optional[str] = None

class GuardianResponse(BaseModel):
    id: int
    resident_id: int
    name: str
    relationship: str
    phone: str
    email: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True
