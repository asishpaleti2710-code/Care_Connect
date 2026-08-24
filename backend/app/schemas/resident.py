from pydantic import BaseModel, Field
from typing import Literal, Optional
from datetime import datetime

class ResidentBase(BaseModel):
    full_name: str = Field(min_length=1, max_length=120)
    age: int = Field(ge=0, le=130)
    room_number: str = Field(min_length=1, max_length=30)
    medical_notes: Optional[str] = Field(default=None, max_length=5000)
    emergency_contact: str = Field(min_length=1, max_length=40)

class ResidentCreate(ResidentBase):
    pass

class ResidentUpdate(BaseModel):
    full_name: Optional[str] = Field(default=None, min_length=1, max_length=120)
    age: Optional[int] = Field(default=None, ge=0, le=130)
    room_number: Optional[str] = Field(default=None, min_length=1, max_length=30)
    medical_notes: Optional[str] = Field(default=None, max_length=5000)
    emergency_contact: Optional[str] = Field(default=None, min_length=1, max_length=40)
    status: Optional[Literal["safe", "alert", "emergency"]] = None

class ResidentResponse(ResidentBase):
    id: int
    status: str
    created_at: datetime

    class Config:
        from_attributes = True
