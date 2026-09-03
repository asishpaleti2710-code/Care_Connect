from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from app.database import Base

class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    sos_id = Column(Integer, ForeignKey("sos_alerts.id"), nullable=True)
    recipient_role = Column(String, nullable=True)  # guardian, security, volunteer, community, admin, resident
    recipient_name = Column(String, nullable=True)
    recipient_contact = Column(String, nullable=True)  # phone number or email address
    channel = Column(String, default="IN_APP")  # IN_APP, PUSH, SMS, EMAIL
    title = Column(String, nullable=False)
    message = Column(String, nullable=False)
    status = Column(String, default="DELIVERED")  # PENDING, SENT, DELIVERED, FAILED, READ, CONFIGURATION_REQUIRED
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    sent_at = Column(DateTime, nullable=True)
    delivered_at = Column(DateTime, nullable=True)
    read_at = Column(DateTime, nullable=True)
    failure_reason = Column(String, nullable=True)

    user = relationship("User", backref="notifications", foreign_keys=[user_id])
    sos = relationship("SOSAlert", backref="notifications", foreign_keys=[sos_id])
