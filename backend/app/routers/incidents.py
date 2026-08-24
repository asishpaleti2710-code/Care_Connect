from fastapi import APIRouter, status
from typing import List, Optional
from datetime import datetime
import random
from app.dependencies import CurrentUser, DbSession
from app.models.incident import Incident
from app.models.resident import Resident
from app.schemas.incident import IncidentCreate, IncidentStatusUpdate, IncidentResponse
from app.services.crud import get_or_404, save
from app.services.residents import clear_resident_emergency

router = APIRouter(prefix="/api/incidents", tags=["Incidents"])

ACTIVE_STATUSES = ["Pending", "Accepted", "In Progress"]

@router.post("/trigger", response_model=IncidentResponse, status_code=status.HTTP_201_CREATED)
def trigger_incident(inc_in: IncidentCreate, db: DbSession, current_user: CurrentUser):
    resident = get_or_404(db, Resident, inc_in.resident_id, "Resident")

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

    return save(db, new_incident)

@router.get("", response_model=List[IncidentResponse])
def get_incidents(
    db: DbSession,
    current_user: CurrentUser,
    status_filter: Optional[str] = None
):
    query = db.query(Incident)
    if status_filter:
        query = query.filter(Incident.status == status_filter)
    return query.order_by(Incident.created_at.desc()).all()

@router.put("/{incident_id}/accept", response_model=IncidentResponse)
def accept_incident(incident_id: int, db: DbSession, current_user: CurrentUser):
    inc = get_or_404(db, Incident, incident_id, "Incident")

    inc.status = "Accepted"
    inc.responder_id = current_user.id
    inc.responder_name = current_user.full_name
    inc.responder_role = current_user.role
    inc.accepted_at = datetime.utcnow()

    return save(db, inc)

@router.put("/{incident_id}/status", response_model=IncidentResponse)
def update_incident_status(
    incident_id: int,
    status_in: IncidentStatusUpdate,
    db: DbSession,
    current_user: CurrentUser
):
    inc = get_or_404(db, Incident, incident_id, "Incident")

    inc.status = status_in.status

    if status_in.status == "Resolved":
        inc.resolved_at = datetime.utcnow()
        clear_resident_emergency(db, inc.resident_id, Incident, ACTIVE_STATUSES, incident_id)

    return save(db, inc)

@router.get("/analytics")
def get_incident_analytics(db: DbSession, current_user: CurrentUser):
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
