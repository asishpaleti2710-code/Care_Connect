from pydantic import BaseModel
from typing import Optional, Dict
from datetime import datetime

class NotificationResponse(BaseModel):
    id: int
    user_id: Optional[int] = None
    sos_id: Optional[int] = None
    recipient_role: Optional[str] = None
    recipient_name: Optional[str] = None
    recipient_contact: Optional[str] = None
    channel: str = "IN_APP"
    title: str
    message: str
    status: str = "DELIVERED"
    is_read: bool = False
    created_at: datetime
    sent_at: Optional[datetime] = None
    delivered_at: Optional[datetime] = None
    read_at: Optional[datetime] = None
    failure_reason: Optional[str] = None

    class Config:
        from_attributes = True

class NotificationStatsResponse(BaseModel):
    total: int
    unread: int
    channels: Dict[str, int]
    statuses: Dict[str, int]
