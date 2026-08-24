from fastapi import APIRouter, status
from typing import List
from app.dependencies import CurrentUser, DbSession
from app.models.resident import Resident
from app.schemas.resident import ResidentCreate, ResidentUpdate, ResidentResponse
from app.services.crud import apply_updates, get_or_404, save

router = APIRouter(prefix="/api/residents", tags=["Residents"])

@router.get("", response_model=List[ResidentResponse])
def get_residents(db: DbSession, current_user: CurrentUser):
    return db.query(Resident).all()

@router.post("", response_model=ResidentResponse, status_code=status.HTTP_201_CREATED)
def create_resident(resident_in: ResidentCreate, db: DbSession, current_user: CurrentUser):
    new_resident = Resident(
        full_name=resident_in.full_name,
        age=resident_in.age,
        room_number=resident_in.room_number,
        medical_notes=resident_in.medical_notes,
        emergency_contact=resident_in.emergency_contact
    )
    return save(db, new_resident)

@router.get("/{resident_id}", response_model=ResidentResponse)
def get_resident(resident_id: int, db: DbSession, current_user: CurrentUser):
    return get_or_404(db, Resident, resident_id, "Resident")

@router.put("/{resident_id}", response_model=ResidentResponse)
def update_resident(
    resident_id: int,
    resident_in: ResidentUpdate,
    db: DbSession,
    current_user: CurrentUser
):
    resident = get_or_404(db, Resident, resident_id, "Resident")
    apply_updates(resident, resident_in.dict(exclude_unset=True))
    return save(db, resident)

@router.delete("/{resident_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_resident(resident_id: int, db: DbSession, current_user: CurrentUser):
    resident = get_or_404(db, Resident, resident_id, "Resident")
    db.delete(resident)
    db.commit()
    return None
