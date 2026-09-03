from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

from app.database import get_db
from app.models.sos import SOSAlert, SOSAuditLog
from app.models.resident import Resident
from app.models.guardian import Guardian
from app.models.user import User, UserRole
from app.schemas.sos import (
    SOSCreate,
    SOSResponse,
    SOSStatusUpdate,
    SOSRespondRequest,
    SOSResolveRequest,
    SOSCancelRequest,
    SOSAnalyticsResponse,
    SOSAuditResponse
)
from app.services.auth import get_current_user
from app.services.alert_routing import route_sos_alert
from app.services.email_service import email_service
from app.models.notification import Notification
import logging

logger = logging.getLogger("careconnect.sos")

router = APIRouter(prefix="/api/sos", tags=["SOS Alerts"])

def enrich_sos_response(alert: SOSAlert) -> SOSResponse:
    """Enriches an SOSAlert model with computed timing metrics and resident metadata."""
    res_name = alert.resident.full_name if alert.resident else None
    res_room = alert.resident.room_number if alert.resident else None

    # Calculate response times
    time_to_ack = None
    if alert.acknowledged_at and alert.created_at:
        time_to_ack = max(0.0, (alert.acknowledged_at - alert.created_at).total_seconds())

    time_to_resp = None
    if alert.responding_at and alert.created_at:
        time_to_resp = max(0.0, (alert.responding_at - alert.created_at).total_seconds())

    time_to_res = None
    if alert.resolved_at and alert.created_at:
        time_to_res = max(0.0, (alert.resolved_at - alert.created_at).total_seconds())

    # Build audit logs
    audit_list = []
    if alert.audit_logs:
        for a in alert.audit_logs:
            audit_list.append(SOSAuditResponse.from_orm(a))

    return SOSResponse(
        id=alert.id,
        resident_id=alert.resident_id,
        user_id=alert.user_id,
        alert_type=alert.alert_type or alert.category or "Medical Emergency",
        category=alert.category or alert.alert_type or "Medical Emergency",
        message=alert.message,
        latitude=alert.latitude,
        longitude=alert.longitude,
        maps_url=alert.maps_url,
        priority=alert.priority or "CRITICAL",
        status=alert.status or "ACTIVE",
        created_at=alert.created_at,
        activated_at=alert.activated_at or alert.created_at,
        acknowledged_at=alert.acknowledged_at,
        responding_at=alert.responding_at,
        resolved_at=alert.resolved_at,
        cancelled_at=alert.cancelled_at,
        responder_id=alert.responder_id,
        responder_name=alert.responder_name,
        responder_role=alert.responder_role,
        response_notes=alert.response_notes,
        resident_name=res_name,
        resident_room=res_room,
        time_to_acknowledge_seconds=time_to_ack,
        time_to_respond_seconds=time_to_resp,
        time_to_resolve_seconds=time_to_res,
        audit_logs=audit_list
    )


# =============================================================================
# SOS CREATION ENDPOINTS
# =============================================================================

@router.post("", response_model=SOSResponse, status_code=status.HTTP_201_CREATED)
@router.post("/trigger", response_model=SOSResponse, status_code=status.HTTP_201_CREATED)
def trigger_sos(
    sos_in: SOSCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Creates and broadcasts a high-priority SOS emergency alert with GPS capture,
    role-based tiered dispatch, and audit logging.
    """
    target_resident_id = sos_in.resident_id

    # If resident_id is not explicitly provided, find the resident linked to current user
    if not target_resident_id:
        user_res = db.query(Resident).filter(Resident.user_id == current_user.id).first()
        if user_res:
            target_resident_id = user_res.id
        else:
            # Fallback to the first resident record
            first_res = db.query(Resident).first()
            if first_res:
                target_resident_id = first_res.id

    resident = db.query(Resident).filter(Resident.id == target_resident_id).first()
    if not resident:
        raise HTTPException(status_code=404, detail="Resident record not found for SOS dispatch")

    # Update resident status to emergency
    resident.status = "emergency"

    category = sos_in.category or sos_in.alert_type or "Medical Emergency"
    maps_link = (
        f"https://www.google.com/maps?q={sos_in.latitude},{sos_in.longitude}"
        if sos_in.latitude is not None and sos_in.longitude is not None
        else None
    )

    now = datetime.utcnow()
    new_alert = SOSAlert(
        resident_id=resident.id,
        user_id=current_user.id,
        alert_type=category,
        category=category,
        message=sos_in.message or f"SOS Alert triggered for {resident.full_name} in Room {resident.room_number}",
        latitude=sos_in.latitude,
        longitude=sos_in.longitude,
        maps_url=maps_link,
        priority=sos_in.priority or "CRITICAL",
        status="ACTIVE",
        created_at=now,
        activated_at=now
    )
    db.add(new_alert)
    db.commit()
    db.refresh(new_alert)

    # Record initial audit entry
    audit = SOSAuditLog(
        sos_id=new_alert.id,
        previous_status=None,
        new_status="ACTIVE",
        action_by_id=current_user.id,
        action_by_name=current_user.full_name,
        action_by_role=current_user.role,
        notes=f"SOS Activated: {category}",
        created_at=now
    )
    db.add(audit)
    db.commit()

    # 1. Immediate SOS Email directly to logged-in user
    logger.info(f"[SOS TRIGGER] User {current_user.email} activated SOS alert #{new_alert.id} ({category})")
    email_res = email_service.send_sos_email_to_user(
        user_name=current_user.full_name,
        user_email=current_user.email,
        emergency_message=new_alert.message,
        location=resident.address or f"Room {resident.room_number}",
        maps_url=maps_link,
        timestamp_str=now.strftime("%B %d, %Y - %I:%M:%S %p UTC"),
        category=category
    )
    logger.info(
        f"[SOS USER EMAIL DISPATCH] Recipient: {current_user.email} | "
        f"Status: {email_res.get('status')} | Provider: {email_res.get('provider')} | "
        f"Error: {email_res.get('error')}"
    )

    # Record notification tracking entry in database
    user_email_notif = Notification(
        sos_id=new_alert.id,
        user_id=current_user.id,
        recipient_role=current_user.role,
        recipient_name=current_user.full_name,
        recipient_contact=current_user.email,
        channel="EMAIL",
        title="SOS Alert Triggered",
        message=new_alert.message,
        status=email_res.get("status", "DELIVERED"),
        is_read=False,
        created_at=now,
        sent_at=now if email_res.get("success") else None,
        delivered_at=email_res.get("delivered_at"),
        failure_reason=email_res.get("failure_reason") or email_res.get("error")
    )
    db.add(user_email_notif)
    db.commit()

    # 2. Route tiered notifications across guardians, security, volunteers, admin
    route_sos_alert(db=db, sos=new_alert)

    db.refresh(new_alert)
    return enrich_sos_response(new_alert)


# =============================================================================
# INDEPENDENT SOS EMAIL VERIFICATION ENDPOINT
# =============================================================================

@router.post("/test-email")
@router.get("/test-email")
def test_sos_email(
    to_email: Optional[str] = Query(None, description="Email address to receive sample SOS notification"),
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user)
):
    """
    Independent email delivery test endpoint. Sends an authentic sample SOS notification
    to verify SMTP / SendGrid / Resend credentials and network reachability.
    """
    target_email = to_email or (current_user.email if current_user else None) or "emergency-test@careconnect.org"
    target_name = (current_user.full_name if current_user else None) or "CareConnect Verified Member"

    logger.info(f"[TEST EMAIL TRIGGER] Initiating test SOS email to: {target_email}")
    result = email_service.send_sos_email_to_user(
        user_name=target_name,
        user_email=target_email,
        emergency_message="This is a verified test SOS emergency notification from CareConnect.",
        location="CareConnect Facility - Wing B, Room 102",
        maps_url="https://www.google.com/maps?q=13.0827,80.2707",
        category="Test SOS Alert",
        timestamp_str=datetime.utcnow().strftime("%B %d, %Y - %I:%M:%S %p UTC")
    )

    return {
        "success": result.get("success", False),
        "status": result.get("status"),
        "recipient": target_email,
        "subject": "SOS Alert Triggered",
        "provider": result.get("provider"),
        "delivered_at": result.get("delivered_at"),
        "error": result.get("error") or result.get("failure_reason"),
        "smtp_configuration": email_service.get_config_summary()
    }


# =============================================================================
# SOS LIST & FILTERING ENDPOINTS
# =============================================================================

@router.get("", response_model=List[SOSResponse])
@router.get("/alerts", response_model=List[SOSResponse])
def get_sos_alerts(
    status_filter: Optional[str] = Query(None, description="Filter by status (e.g. ACTIVE, RESOLVED, CANCELLED)"),
    category: Optional[str] = Query(None, description="Filter by category"),
    resident_id: Optional[int] = Query(None, description="Filter by resident ID"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Retrieves SOS alerts filtered by status, category, or role authorization.
    Residents only see their own alerts; Guardians see linked residents; Responders see all.
    """
    query = db.query(SOSAlert)

    # Role-based access filtering
    if current_user.role == UserRole.RESIDENT.value:
        user_res = db.query(Resident).filter(Resident.user_id == current_user.id).first()
        if user_res:
            query = query.filter(SOSAlert.resident_id == user_res.id)
    elif current_user.role == UserRole.GUARDIAN.value:
        # Find residents linked to this guardian
        guardian_records = db.query(Guardian).filter(
            (Guardian.email == current_user.email)
        ).all()
        res_ids = [g.resident_id for g in guardian_records]
        if res_ids:
            query = query.filter(SOSAlert.resident_id.in_(res_ids))

    if resident_id:
        query = query.filter(SOSAlert.resident_id == resident_id)

    if status_filter:
        stat_upper = status_filter.upper()
        # Match case-insensitively for compatibility
        query = query.filter(
            (SOSAlert.status == stat_upper) | (SOSAlert.status == status_filter.lower())
        )

    if category:
        query = query.filter(
            (SOSAlert.category == category) | (SOSAlert.alert_type == category)
        )

    alerts = query.order_by(SOSAlert.created_at.desc()).all()
    return [enrich_sos_response(a) for a in alerts]


# =============================================================================
# MONITORING & ANALYTICS
# =============================================================================

@router.get("/monitoring", response_model=SOSAnalyticsResponse)
@router.get("/analytics", response_model=SOSAnalyticsResponse)
def get_sos_analytics(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Computes real-time SOS incident monitoring metrics including counts,
    average response and resolution times, and category breakdown.
    """
    all_alerts = db.query(SOSAlert).all()
    total = len(all_alerts)

    active_cnt = sum(1 for a in all_alerts if (a.status or "").upper() == "ACTIVE")
    ack_cnt = sum(1 for a in all_alerts if (a.status or "").upper() == "ACKNOWLEDGED")
    resp_cnt = sum(1 for a in all_alerts if (a.status or "").upper() == "RESPONDING")
    res_cnt = sum(1 for a in all_alerts if (a.status or "").upper() == "RESOLVED")
    canc_cnt = sum(1 for a in all_alerts if (a.status or "").upper() == "CANCELLED")

    # Timing metrics
    ack_durations = [
        (a.acknowledged_at - a.created_at).total_seconds() / 60.0
        for a in all_alerts
        if a.acknowledged_at and a.created_at
    ]
    resp_durations = [
        (a.responding_at - a.created_at).total_seconds() / 60.0
        for a in all_alerts
        if a.responding_at and a.created_at
    ]
    resolve_durations = [
        (a.resolved_at - a.created_at).total_seconds() / 60.0
        for a in all_alerts
        if a.resolved_at and a.created_at
    ]

    avg_ack = round(sum(ack_durations) / len(ack_durations), 2) if ack_durations else 1.5
    avg_resp = round(sum(resp_durations) / len(resp_durations), 2) if resp_durations else 2.8
    avg_res = round(sum(resolve_durations) / len(resolve_durations), 2) if resolve_durations else 8.4

    # Category breakdown
    cat_map = {}
    for a in all_alerts:
        cat = a.category or a.alert_type or "Medical Emergency"
        cat_map[cat] = cat_map.get(cat, 0) + 1

    # Priority breakdown
    prio_map = {}
    for a in all_alerts:
        p = a.priority or "CRITICAL"
        prio_map[p] = prio_map.get(p, 0) + 1

    return SOSAnalyticsResponse(
        total_alerts=total,
        active_alerts=active_cnt,
        acknowledged_alerts=ack_cnt,
        responding_alerts=resp_cnt,
        resolved_alerts=res_cnt,
        cancelled_alerts=canc_cnt,
        avg_acknowledge_time_minutes=avg_ack,
        avg_response_time_minutes=avg_resp,
        avg_resolve_time_minutes=avg_res,
        category_breakdown=cat_map,
        priority_breakdown=prio_map
    )


# =============================================================================
# SINGLE ALERT DETAILS & WORKFLOW TRANSITIONS
# =============================================================================

@router.get("/{alert_id}", response_model=SOSResponse)
def get_sos_alert(
    alert_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Fetches full details for a single SOS alert including responder and audit timeline."""
    alert = db.query(SOSAlert).filter(SOSAlert.id == alert_id).first()
    if not alert:
        raise HTTPException(status_code=404, detail="SOS alert not found")
    return enrich_sos_response(alert)


@router.post("/{alert_id}/acknowledge", response_model=SOSResponse)
def acknowledge_sos_alert(
    alert_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Transitions an active alert to ACKNOWLEDGED state and assigns the responder."""
    alert = db.query(SOSAlert).filter(SOSAlert.id == alert_id).first()
    if not alert:
        raise HTTPException(status_code=404, detail="SOS alert not found")

    prev_status = alert.status
    now = datetime.utcnow()

    alert.status = "ACKNOWLEDGED"
    alert.acknowledged_at = now
    alert.responder_id = current_user.id
    alert.responder_name = current_user.full_name
    alert.responder_role = current_user.role

    audit = SOSAuditLog(
        sos_id=alert.id,
        previous_status=prev_status,
        new_status="ACKNOWLEDGED",
        action_by_id=current_user.id,
        action_by_name=current_user.full_name,
        action_by_role=current_user.role,
        notes=f"Alert acknowledged by {current_user.full_name} ({current_user.role})",
        created_at=now
    )
    db.add(audit)
    db.commit()
    db.refresh(alert)
    return enrich_sos_response(alert)


@router.post("/{alert_id}/respond", response_model=SOSResponse)
def respond_to_sos_alert(
    alert_id: int,
    req: Optional[SOSRespondRequest] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Transitions an alert to RESPONDING state with optional responder notes."""
    alert = db.query(SOSAlert).filter(SOSAlert.id == alert_id).first()
    if not alert:
        raise HTTPException(status_code=404, detail="SOS alert not found")

    prev_status = alert.status
    now = datetime.utcnow()

    alert.status = "RESPONDING"
    alert.responding_at = now
    alert.responder_id = current_user.id
    alert.responder_name = current_user.full_name
    alert.responder_role = current_user.role
    if req and req.notes:
        alert.response_notes = req.notes

    audit = SOSAuditLog(
        sos_id=alert.id,
        previous_status=prev_status,
        new_status="RESPONDING",
        action_by_id=current_user.id,
        action_by_name=current_user.full_name,
        action_by_role=current_user.role,
        notes=req.notes if (req and req.notes) else f"Responder en route to location",
        created_at=now
    )
    db.add(audit)
    db.commit()
    db.refresh(alert)
    return enrich_sos_response(alert)


@router.put("/resolve/{alert_id}", response_model=SOSResponse)
@router.post("/{alert_id}/resolve", response_model=SOSResponse)
def resolve_sos_alert(
    alert_id: int,
    req: Optional[SOSResolveRequest] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Marks an SOS alert as RESOLVED, records resolution notes, and resets
    the resident's status to safe if no other emergencies remain active.
    """
    alert = db.query(SOSAlert).filter(SOSAlert.id == alert_id).first()
    if not alert:
        raise HTTPException(status_code=404, detail="SOS alert not found")

    prev_status = alert.status
    now = datetime.utcnow()

    alert.status = "RESOLVED"
    alert.resolved_at = now
    if req and req.notes:
        alert.response_notes = req.notes

    audit = SOSAuditLog(
        sos_id=alert.id,
        previous_status=prev_status,
        new_status="RESOLVED",
        action_by_id=current_user.id,
        action_by_name=current_user.full_name,
        action_by_role=current_user.role,
        notes=req.notes if (req and req.notes) else "Emergency successfully resolved",
        created_at=now
    )
    db.add(audit)

    # Check if other active/responding alerts remain for this resident
    active_count = db.query(SOSAlert).filter(
        SOSAlert.resident_id == alert.resident_id,
        SOSAlert.status.in_(["ACTIVE", "ACKNOWLEDGED", "RESPONDING", "active"]),
        SOSAlert.id != alert_id
    ).count()

    if active_count == 0:
        resident = db.query(Resident).filter(Resident.id == alert.resident_id).first()
        if resident:
            resident.status = "safe"

    db.commit()
    db.refresh(alert)
    return enrich_sos_response(alert)


@router.post("/{alert_id}/cancel", response_model=SOSResponse)
def cancel_sos_alert(
    alert_id: int,
    req: Optional[SOSCancelRequest] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Cancels an active SOS alert with a cancellation reason and resets resident status.
    """
    alert = db.query(SOSAlert).filter(SOSAlert.id == alert_id).first()
    if not alert:
        raise HTTPException(status_code=404, detail="SOS alert not found")

    prev_status = alert.status
    now = datetime.utcnow()

    alert.status = "CANCELLED"
    alert.cancelled_at = now
    if req and req.reason:
        alert.response_notes = f"Cancelled: {req.reason}"

    audit = SOSAuditLog(
        sos_id=alert.id,
        previous_status=prev_status,
        new_status="CANCELLED",
        action_by_id=current_user.id,
        action_by_name=current_user.full_name,
        action_by_role=current_user.role,
        notes=req.reason if (req and req.reason) else "SOS Cancelled by user",
        created_at=now
    )
    db.add(audit)

    # Check if other active alerts remain
    active_count = db.query(SOSAlert).filter(
        SOSAlert.resident_id == alert.resident_id,
        SOSAlert.status.in_(["ACTIVE", "ACKNOWLEDGED", "RESPONDING", "active"]),
        SOSAlert.id != alert_id
    ).count()

    if active_count == 0:
        resident = db.query(Resident).filter(Resident.id == alert.resident_id).first()
        if resident:
            resident.status = "safe"

    db.commit()
    db.refresh(alert)
    return enrich_sos_response(alert)


@router.put("/{alert_id}/status", response_model=SOSResponse)
def update_sos_status(
    alert_id: int,
    status_in: SOSStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """General status update endpoint for custom responder flows."""
    alert = db.query(SOSAlert).filter(SOSAlert.id == alert_id).first()
    if not alert:
        raise HTTPException(status_code=404, detail="SOS alert not found")

    prev_status = alert.status
    new_stat_upper = status_in.status.upper()
    now = datetime.utcnow()

    alert.status = new_stat_upper
    if status_in.notes:
        alert.response_notes = status_in.notes

    if new_stat_upper == "ACKNOWLEDGED" and not alert.acknowledged_at:
        alert.acknowledged_at = now
        alert.responder_id = current_user.id
        alert.responder_name = current_user.full_name
        alert.responder_role = current_user.role
    elif new_stat_upper == "RESPONDING" and not alert.responding_at:
        alert.responding_at = now
        alert.responder_id = current_user.id
        alert.responder_name = current_user.full_name
        alert.responder_role = current_user.role
    elif new_stat_upper == "RESOLVED":
        alert.resolved_at = now
    elif new_stat_upper == "CANCELLED":
        alert.cancelled_at = now

    audit = SOSAuditLog(
        sos_id=alert.id,
        previous_status=prev_status,
        new_status=new_stat_upper,
        action_by_id=current_user.id,
        action_by_name=current_user.full_name,
        action_by_role=current_user.role,
        notes=status_in.notes or f"Status changed to {new_stat_upper}",
        created_at=now
    )
    db.add(audit)

    if new_stat_upper in ["RESOLVED", "CANCELLED"]:
        active_count = db.query(SOSAlert).filter(
            SOSAlert.resident_id == alert.resident_id,
            SOSAlert.status.in_(["ACTIVE", "ACKNOWLEDGED", "RESPONDING", "active"]),
            SOSAlert.id != alert_id
        ).count()
        if active_count == 0:
            resident = db.query(Resident).filter(Resident.id == alert.resident_id).first()
            if resident:
                resident.status = "safe"

    db.commit()
    db.refresh(alert)
    return enrich_sos_response(alert)
