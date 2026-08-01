from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    email: str
    full_name: str
    role: Optional[str] = "caregiver"
    username: Optional[str] = None
    height: Optional[str] = "172 cm"
    sex: Optional[str] = "Male"
    date_of_birth: Optional[str] = "Jun 10, 2006"
    location: Optional[str] = "India"
    time_zone: Optional[str] = "Chennai"
    zip_code: Optional[str] = "11111"
    bio: Optional[str] = None
    avatar_url: Optional[str] = None

class UserCreate(UserBase):
    password: str

class UserLogin(BaseModel):
    email: str
    password: str

class UserProfileUpdate(BaseModel):
    full_name: Optional[str] = None
    username: Optional[str] = None
    height: Optional[str] = None
    sex: Optional[str] = None
    date_of_birth: Optional[str] = None
    location: Optional[str] = None
    time_zone: Optional[str] = None
    zip_code: Optional[str] = None
    bio: Optional[str] = None
    avatar_url: Optional[str] = None

class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str

class UserResponse(UserBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse
