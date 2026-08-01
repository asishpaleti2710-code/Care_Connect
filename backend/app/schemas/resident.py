from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class ResidentBase(BaseModel):
    full_name: str
    age: int
    room_number: str
    medical_notes: Optional[str] = None
    emergency_contact: str

class ResidentCreate(ResidentBase):
    pass

class ResidentUpdate(BaseModel):
    full_name: Optional[str] = None
    age: Optional[int] = None
    room_number: Optional[str] = None
    medical_notes: Optional[str] = None
    emergency_contact: Optional[str] = None
    status: Optional[str] = None

class ResidentResponse(ResidentBase):
    id: int
    status: str
    created_at: datetime

    class Config:
        from_attributes = True
