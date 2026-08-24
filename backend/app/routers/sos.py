from fastapi import APIRouter, status
from typing import List
from datetime import datetime
from app.dependencies import CurrentUser, DbSession
from app.models.sos import SOSAlert
from app.models.resident import Resident
from app.schemas.sos import SOSCreate, SOSResponse
from app.services.crud import get_or_404, save
from app.services.residents import clear_resident_emergency

router = APIRouter(prefix="/api/sos", tags=["SOS Alerts"])

@router.post("/trigger", response_model=SOSResponse, status_code=status.HTTP_201_CREATED)
def trigger_sos(sos_in: SOSCreate, db: DbSession, current_user: CurrentUser):
    resident = get_or_404(db, Resident, sos_in.resident_id, "Resident")

    # Update resident status to emergency
    resident.status = "emergency"

    new_alert = SOSAlert(
        resident_id=sos_in.resident_id,
        alert_type=sos_in.alert_type or "Medical Emergency",
        message=sos_in.message or f"SOS Alert triggered for {resident.full_name} in Room {resident.room_number}"
    )
    return save(db, new_alert)

@router.get("/alerts", response_model=List[SOSResponse])
def get_sos_alerts(db: DbSession, current_user: CurrentUser):
    return db.query(SOSAlert).order_by(SOSAlert.created_at.desc()).all()

@router.put("/resolve/{alert_id}", response_model=SOSResponse)
def resolve_sos_alert(alert_id: int, db: DbSession, current_user: CurrentUser):
    alert = get_or_404(db, SOSAlert, alert_id, "SOS alert")

    alert.status = "resolved"
    alert.resolved_at = datetime.utcnow()

    clear_resident_emergency(db, alert.resident_id, SOSAlert, ["active"], alert_id)

    return save(db, alert)
