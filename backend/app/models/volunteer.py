from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from datetime import datetime
from app.database import Base

class Volunteer(Base):
    __tablename__ = "volunteers"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    phone = Column(String, nullable=False)
    availability_status = Column(String, default="available")  # available, busy, offline
    skills = Column(String, default="First Aid Certified, CPR Trained")
    created_at = Column(DateTime, default=datetime.utcnow)
