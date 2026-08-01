from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from datetime import datetime
from app.database import Base

class SecurityPerson(Base):
    __tablename__ = "security_personnel"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    badge_number = Column(String, nullable=False)
    assigned_zone = Column(String, default="Main Complex / Block A")
    phone = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
