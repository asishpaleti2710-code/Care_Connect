from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.models.resident import Resident
from app.models.user import User, UserRole
from app.schemas.resident import ResidentCreate, ResidentUpdate, ResidentResponse
from app.services.auth import get_current_user, require_roles

require_staff = require_roles(UserRole.ADMIN.value, UserRole.CAREGIVER.value)

router = APIRouter(prefix="/api/residents", tags=["Residents"])

@router.get("", response_model=List[ResidentResponse])
def get_residents(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return db.query(Resident).all()

@router.post("", response_model=ResidentResponse, status_code=status.HTTP_201_CREATED)
def create_resident(
    resident_in: ResidentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_staff)
):
    new_resident = Resident(
        full_name=resident_in.full_name,
        age=resident_in.age,
        room_number=resident_in.room_number,
        medical_notes=resident_in.medical_notes,
        emergency_contact=resident_in.emergency_contact
    )
    db.add(new_resident)
    db.commit()
    db.refresh(new_resident)
    return new_resident

@router.get("/{resident_id}", response_model=ResidentResponse)
def get_resident(
    resident_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    resident = db.query(Resident).filter(Resident.id == resident_id).first()
    if not resident:
        raise HTTPException(status_code=404, detail="Resident not found")
    return resident

@router.put("/{resident_id}", response_model=ResidentResponse)
def update_resident(
    resident_id: int,
    resident_in: ResidentUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_staff)
):
    resident = db.query(Resident).filter(Resident.id == resident_id).first()
    if not resident:
        raise HTTPException(status_code=404, detail="Resident not found")

    update_data = resident_in.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(resident, field, value)

    db.commit()
    db.refresh(resident)
    return resident

@router.delete("/{resident_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_resident(
    resident_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_staff)
):
    resident = db.query(Resident).filter(Resident.id == resident_id).first()
    if not resident:
        raise HTTPException(status_code=404, detail="Resident not found")
    
    db.delete(resident)
    db.commit()
    return None
