from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.models.guardian import Guardian
from app.models.user import User
from app.schemas.guardian import GuardianCreate, GuardianResponse
from app.services.auth import get_current_user

router = APIRouter(prefix="/api/guardians", tags=["Guardians"])

@router.get("/resident/{resident_id}", response_model=List[GuardianResponse])
def get_resident_guardians(
    resident_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return db.query(Guardian).filter(Guardian.resident_id == resident_id).all()

@router.post("", response_model=GuardianResponse, status_code=status.HTTP_201_CREATED)
def add_guardian(
    guardian_in: GuardianCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    new_guardian = Guardian(
        resident_id=guardian_in.resident_id,
        name=guardian_in.name,
        relationship=guardian_in.relationship,
        phone=guardian_in.phone,
        email=guardian_in.email
    )
    db.add(new_guardian)
    db.commit()
    db.refresh(new_guardian)
    return new_guardian

@router.delete("/{guardian_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_guardian(
    guardian_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    g = db.query(Guardian).filter(Guardian.id == guardian_id).first()
    if not g:
        raise HTTPException(status_code=404, detail="Guardian not found")
    db.delete(g)
    db.commit()
    return None
