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
    username = Column(String, nullable=True)
    role = Column(String, default=UserRole.RESIDENT.value)
    height = Column(String, default="172 cm")
    sex = Column(String, default="Male")
    date_of_birth = Column(String, default="Jun 10, 2006")
    location = Column(String, default="India")
    time_zone = Column(String, default="Chennai")
    zip_code = Column(String, default="11111")
    bio = Column(String, nullable=True)
    avatar_url = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
