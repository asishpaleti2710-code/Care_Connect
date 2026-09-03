from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

from app.database import get_db
from app.models.notification import Notification
from app.models.user import User, UserRole
from app.schemas.notification import NotificationResponse, NotificationStatsResponse
from app.services.auth import get_current_user

router = APIRouter(prefix="/api/notifications", tags=["Notifications"])

@router.get("", response_model=List[NotificationResponse])
def get_user_notifications(
    unread_only: bool = Query(False, description="Filter for unread notifications only"),
    channel: Optional[str] = Query(None, description="Filter by channel (IN_APP, PUSH, SMS, EMAIL)"),
    limit: int = Query(50, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Retrieves emergency notifications directed to the current authenticated user.
    """
    query = db.query(Notification).filter(
        (Notification.user_id == current_user.id) |
        (Notification.recipient_role == current_user.role) |
        (Notification.recipient_contact == current_user.email)
    )

    if unread_only:
        query = query.filter(Notification.is_read == False)

    if channel:
        query = query.filter(Notification.channel == channel.upper())

    return query.order_by(Notification.created_at.desc()).limit(limit).all()


@router.get("/all", response_model=List[NotificationResponse])
def get_all_notifications_admin(
    sos_id: Optional[int] = Query(None, description="Filter notifications for a specific SOS alert"),
    limit: int = Query(100, ge=1, le=200),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Administrative monitoring view: returns all dispatched notifications
    across all channels with delivery tracking.
    """
    query = db.query(Notification)
    if sos_id:
        query = query.filter(Notification.sos_id == sos_id)

    return query.order_by(Notification.created_at.desc()).limit(limit).all()


@router.get("/stats", response_model=NotificationStatsResponse)
def get_notification_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Returns notification metrics for the current user including total, unread,
    and channel distribution.
    """
    user_notifs = db.query(Notification).filter(
        (Notification.user_id == current_user.id) |
        (Notification.recipient_role == current_user.role) |
        (Notification.recipient_contact == current_user.email)
    ).all()

    total = len(user_notifs)
    unread = sum(1 for n in user_notifs if not n.is_read)

    channels = {}
    statuses = {}
    for n in user_notifs:
        channels[n.channel] = channels.get(n.channel, 0) + 1
        statuses[n.status] = statuses.get(n.status, 0) + 1

    return NotificationStatsResponse(
        total=total,
        unread=unread,
        channels=channels,
        statuses=statuses
    )


@router.put("/{notification_id}/read", response_model=NotificationResponse)
def mark_notification_read(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Marks a specific notification as read."""
    notif = db.query(Notification).filter(Notification.id == notification_id).first()
    if not notif:
        raise HTTPException(status_code=404, detail="Notification not found")

    notif.is_read = True
    notif.read_at = datetime.utcnow()
    if notif.status == "DELIVERED":
        notif.status = "READ"

    db.commit()
    db.refresh(notif)
    return notif


@router.put("/read-all")
def mark_all_notifications_read(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Marks all notifications for the current user as read."""
    now = datetime.utcnow()
    user_notifs = db.query(Notification).filter(
        (Notification.user_id == current_user.id) |
        (Notification.recipient_role == current_user.role) |
        (Notification.recipient_contact == current_user.email),
        Notification.is_read == False
    ).all()

    for n in user_notifs:
        n.is_read = True
        n.read_at = now
        if n.status == "DELIVERED":
            n.status = "READ"

    db.commit()
    return {"message": f"Marked {len(user_notifs)} notifications as read"}
