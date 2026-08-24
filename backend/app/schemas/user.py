from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime

PASSWORD_MIN_LENGTH = 8
PASSWORD_MAX_LENGTH = 128

class UserBase(BaseModel):
    email: EmailStr
    full_name: str = Field(min_length=1, max_length=120)
    role: Optional[str] = "resident"
    username: Optional[str] = Field(default=None, max_length=60)
    height: Optional[str] = "172 cm"
    sex: Optional[str] = "Male"
    date_of_birth: Optional[str] = "Jun 10, 2006"
    location: Optional[str] = "India"
    time_zone: Optional[str] = "Chennai"
    zip_code: Optional[str] = "11111"
    bio: Optional[str] = Field(default=None, max_length=1000)
    avatar_url: Optional[str] = Field(default=None, max_length=500)

class UserCreate(UserBase):
    password: str = Field(min_length=PASSWORD_MIN_LENGTH, max_length=PASSWORD_MAX_LENGTH)

class UserLogin(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=PASSWORD_MAX_LENGTH)

class UserProfileUpdate(BaseModel):
    full_name: Optional[str] = Field(default=None, min_length=1, max_length=120)
    username: Optional[str] = Field(default=None, max_length=60)
    height: Optional[str] = None
    sex: Optional[str] = None
    date_of_birth: Optional[str] = None
    location: Optional[str] = None
    time_zone: Optional[str] = None
    zip_code: Optional[str] = None
    bio: Optional[str] = Field(default=None, max_length=1000)
    avatar_url: Optional[str] = Field(default=None, max_length=500)

class ChangePasswordRequest(BaseModel):
    current_password: str = Field(min_length=1, max_length=PASSWORD_MAX_LENGTH)
    new_password: str = Field(min_length=PASSWORD_MIN_LENGTH, max_length=PASSWORD_MAX_LENGTH)

class UserResponse(UserBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse
