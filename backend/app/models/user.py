from sqlalchemy import Column, Integer, String, DateTime
from datetime import datetime
import enum
from app.database import Base

class UserRole(str, enum.Enum):
    ADMIN = "admin"
    RESIDENT = "resident"
    GUARDIAN = "guardian"
    VOLUNTEER = "volunteer"
    SECURITY = "security"
    CAREGIVER = "caregiver"
    NEIGHBOUR = "neighbour"

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String, nullable=False)
    role = Column(String, default=UserRole.RESIDENT.value)
    created_at = Column(DateTime, default=datetime.utcnow)
