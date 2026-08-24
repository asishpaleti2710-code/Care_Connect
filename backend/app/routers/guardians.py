from fastapi import APIRouter, status
from typing import List
from app.dependencies import CurrentUser, DbSession
from app.models.guardian import Guardian
from app.schemas.guardian import GuardianCreate, GuardianResponse
from app.services.crud import get_or_404, save

router = APIRouter(prefix="/api/guardians", tags=["Guardians"])

@router.get("/resident/{resident_id}", response_model=List[GuardianResponse])
def get_resident_guardians(resident_id: int, db: DbSession, current_user: CurrentUser):
    return db.query(Guardian).filter(Guardian.resident_id == resident_id).all()

@router.post("", response_model=GuardianResponse, status_code=status.HTTP_201_CREATED)
def add_guardian(guardian_in: GuardianCreate, db: DbSession, current_user: CurrentUser):
    new_guardian = Guardian(
        resident_id=guardian_in.resident_id,
        name=guardian_in.name,
        relationship=guardian_in.relationship,
        phone=guardian_in.phone,
        email=guardian_in.email
    )
    return save(db, new_guardian)

@router.delete("/{guardian_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_guardian(guardian_id: int, db: DbSession, current_user: CurrentUser):
    guardian = get_or_404(db, Guardian, guardian_id, "Guardian")
    db.delete(guardian)
    db.commit()
    return None
