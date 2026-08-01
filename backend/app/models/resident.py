from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from datetime import datetime
from app.database import Base

class Resident(Base):
    __tablename__ = "residents"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    full_name = Column(String, nullable=False)
    age = Column(Integer, nullable=False)
    blood_group = Column(String, default="O+")
    room_number = Column(String, nullable=False)
    address = Column(String, default="Building A, Room 101")
    medical_notes = Column(String, nullable=True)
    emergency_contact = Column(String, nullable=False)
    status = Column(String, default="safe")  # safe, alert, emergency
    created_at = Column(DateTime, default=datetime.utcnow)
