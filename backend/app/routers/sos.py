from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime
from app.database import get_db
from app.models.sos import SOSAlert
from app.models.resident import Resident
from app.models.user import User
from app.schemas.sos import SOSCreate, SOSResponse
from app.services.auth import get_current_user

router = APIRouter(prefix="/api/sos", tags=["SOS Alerts"])

@router.post("/trigger", response_model=SOSResponse, status_code=status.HTTP_201_CREATED)
def trigger_sos(
    sos_in: SOSCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    resident = db.query(Resident).filter(Resident.id == sos_in.resident_id).first()
    if not resident:
        raise HTTPException(status_code=404, detail="Resident not found")

    # Update resident status to emergency
    resident.status = "emergency"

    new_alert = SOSAlert(
        resident_id=sos_in.resident_id,
        alert_type=sos_in.alert_type or "Medical Emergency",
        message=sos_in.message or f"SOS Alert triggered for {resident.full_name} in Room {resident.room_number}"
    )
    db.add(new_alert)
    db.commit()
    db.refresh(new_alert)
    return new_alert

@router.get("/alerts", response_model=List[SOSResponse])
def get_sos_alerts(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return db.query(SOSAlert).order_by(SOSAlert.created_at.desc()).all()

@router.put("/resolve/{alert_id}", response_model=SOSResponse)
def resolve_sos_alert(
    alert_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    alert = db.query(SOSAlert).filter(SOSAlert.id == alert_id).first()
    if not alert:
        raise HTTPException(status_code=404, detail="SOS alert not found")

    alert.status = "resolved"
    alert.resolved_at = datetime.utcnow()

    # Reset resident status if no active alerts remain
    active_alerts = db.query(SOSAlert).filter(
        SOSAlert.resident_id == alert.resident_id,
        SOSAlert.status == "active",
        SOSAlert.id != alert_id
    ).count()

    if active_alerts == 0:
        resident = db.query(Resident).filter(Resident.id == alert.resident_id).first()
        if resident:
            resident.status = "safe"

    db.commit()
    db.refresh(alert)
    return alert
