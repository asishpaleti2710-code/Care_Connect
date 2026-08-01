from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from datetime import datetime
from app.database import Base

class Incident(Base):
    __tablename__ = "incidents"

    id = Column(Integer, primary_key=True, index=True)
    incident_code = Column(String, unique=True, index=True, nullable=False)
    resident_id = Column(Integer, ForeignKey("residents.id"), nullable=False)
    emergency_type = Column(String, default="Medical Emergency")
    priority = Column(String, default="High")  # Critical, High, Moderate, Low
    description = Column(String, nullable=True)
    location = Column(String, default="Room 101")
    status = Column(String, default="Pending")  # Pending, Accepted, In Progress, Resolved
    
    responder_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    responder_name = Column(String, nullable=True)
    responder_role = Column(String, nullable=True)

    created_at = Column(DateTime, default=datetime.utcnow)
    accepted_at = Column(DateTime, nullable=True)
    resolved_at = Column(DateTime, nullable=True)
