from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
import random
from app.database import get_db
from app.models.incident import Incident
from app.models.resident import Resident
from app.models.user import User, UserRole
from app.schemas.incident import IncidentCreate, IncidentStatusUpdate, IncidentResponse
from app.services.auth import RESPONDER_ROLES, get_current_user, require_roles

require_responder = require_roles(*RESPONDER_ROLES)
require_admin = require_roles(UserRole.ADMIN.value)

router = APIRouter(prefix="/api/incidents", tags=["Incidents"])

@router.post("/trigger", response_model=IncidentResponse, status_code=status.HTTP_201_CREATED)
def trigger_incident(
    inc_in: IncidentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    resident = db.query(Resident).filter(Resident.id == inc_in.resident_id).first()
    if not resident:
        raise HTTPException(status_code=404, detail="Resident not found")

    if (
        current_user.role == UserRole.RESIDENT.value
        and resident.user_id != current_user.id
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Residents may only raise emergencies for themselves",
        )

    # Update resident status to emergency
    resident.status = "emergency"

    code = f"INC-{random.randint(1000, 9999)}"
    
    new_incident = Incident(
        incident_code=code,
        resident_id=inc_in.resident_id,
        emergency_type=inc_in.emergency_type or "Medical Emergency",
        priority=inc_in.priority or "High",
        description=inc_in.description or f"SOS Emergency reported for {resident.full_name}",
        location=inc_in.location or resident.address or f"Room {resident.room_number}",
        status="Pending"
    )
    
    db.add(new_incident)
    db.commit()
    db.refresh(new_incident)
    return new_incident

@router.get("", response_model=List[IncidentResponse])
def get_incidents(
    status_filter: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(Incident)
    if status_filter:
        query = query.filter(Incident.status == status_filter)
    return query.order_by(Incident.created_at.desc()).all()

@router.put("/{incident_id}/accept", response_model=IncidentResponse)
def accept_incident(
    incident_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_responder)
):
    inc = db.query(Incident).filter(Incident.id == incident_id).first()
    if not inc:
        raise HTTPException(status_code=404, detail="Incident not found")

    inc.status = "Accepted"
    inc.responder_id = current_user.id
    inc.responder_name = current_user.full_name
    inc.responder_role = current_user.role
    inc.accepted_at = datetime.utcnow()

    db.commit()
    db.refresh(inc)
    return inc

@router.put("/{incident_id}/status", response_model=IncidentResponse)
def update_incident_status(
    incident_id: int,
    status_in: IncidentStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_responder)
):
    inc = db.query(Incident).filter(Incident.id == incident_id).first()
    if not inc:
        raise HTTPException(status_code=404, detail="Incident not found")

    inc.status = status_in.status

    if status_in.status == "Resolved":
        inc.resolved_at = datetime.utcnow()

        # Check if active incidents remain for this resident
        active_cnt = db.query(Incident).filter(
            Incident.resident_id == inc.resident_id,
            Incident.status.in_(["Pending", "Accepted", "In Progress"]),
            Incident.id != incident_id
        ).count()

        if active_cnt == 0:
            res = db.query(Resident).filter(Resident.id == inc.resident_id).first()
            if res:
                res.status = "safe"

    db.commit()
    db.refresh(inc)
    return inc

@router.get("/analytics")
def get_incident_analytics(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    all_incidents = db.query(Incident).all()
    total = len(all_incidents)
    resolved = len([i for i in all_incidents if i.status == "Resolved"])
    pending = len([i for i in all_incidents if i.status == "Pending"])
    in_progress = len([i for i in all_incidents if i.status in ["Accepted", "In Progress"]])

    types_breakdown = {}
    for i in all_incidents:
        types_breakdown[i.emergency_type] = types_breakdown.get(i.emergency_type, 0) + 1

    return {
        "total_incidents": total,
        "resolved_incidents": resolved,
        "pending_incidents": pending,
        "in_progress_incidents": in_progress,
        "emergency_types": types_breakdown,
        "avg_response_time_minutes": 2.4
    }
