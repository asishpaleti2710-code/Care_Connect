from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime

class GuardianCreate(BaseModel):
    resident_id: int = Field(gt=0)
    name: str = Field(min_length=1, max_length=120)
    relationship: str = Field(min_length=1, max_length=60)
    phone: str = Field(min_length=1, max_length=40)
    email: Optional[EmailStr] = None

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
