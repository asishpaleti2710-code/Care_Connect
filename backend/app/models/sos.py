from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from app.database import Base

class SOSAlert(Base):
    __tablename__ = "sos_alerts"

    id = Column(Integer, primary_key=True, index=True)
    resident_id = Column(Integer, ForeignKey("residents.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    alert_type = Column(String, default="Medical Emergency")
    category = Column(String, default="Medical Emergency")
    message = Column(String, nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    maps_url = Column(String, nullable=True)
    priority = Column(String, default="CRITICAL")  # CRITICAL, HIGH, MODERATE, LOW
    status = Column(String, default="ACTIVE")  # ACTIVE, ACKNOWLEDGED, RESPONDING, RESOLVED, CANCELLED
    created_at = Column(DateTime, default=datetime.utcnow)
    activated_at = Column(DateTime, default=datetime.utcnow)
    acknowledged_at = Column(DateTime, nullable=True)
    responding_at = Column(DateTime, nullable=True)
    resolved_at = Column(DateTime, nullable=True)
    cancelled_at = Column(DateTime, nullable=True)
    
    responder_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    responder_name = Column(String, nullable=True)
    responder_role = Column(String, nullable=True)
    response_notes = Column(String, nullable=True)

    resident = relationship("Resident", backref="sos_alerts", foreign_keys=[resident_id])
    user = relationship("User", foreign_keys=[user_id])
    responder = relationship("User", foreign_keys=[responder_id])
    audit_logs = relationship("SOSAuditLog", backref="sos_alert", cascade="all, delete-orphan", order_by="SOSAuditLog.created_at.desc()")


class SOSAuditLog(Base):
    __tablename__ = "sos_audit_logs"

    id = Column(Integer, primary_key=True, index=True)
    sos_id = Column(Integer, ForeignKey("sos_alerts.id"), nullable=False)
    previous_status = Column(String, nullable=True)
    new_status = Column(String, nullable=False)
    action_by_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    action_by_name = Column(String, nullable=True)
    action_by_role = Column(String, nullable=True)
    notes = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    action_user = relationship("User", foreign_keys=[action_by_id])
