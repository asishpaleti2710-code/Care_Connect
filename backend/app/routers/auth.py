import logging
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.user import User
from app.models.resident import Resident
from app.schemas.user import UserCreate, UserLogin, UserResponse, Token, UserProfileUpdate, ChangePasswordRequest
from app.services.auth import hash_password, verify_password, create_access_token, get_current_user

logger = logging.getLogger("careconnect.auth")

router = APIRouter(prefix="/api/auth", tags=["Authentication"])

@router.post("/register", response_model=Token)
def register(user_data: UserCreate, db: Session = Depends(get_db)):
    logger.info(f"[REGISTER REQUEST] Email: {user_data.email}, Role: {user_data.role}, Name: {user_data.full_name}")
    db_user = db.query(User).filter(User.email == user_data.email).first()
    if db_user:
        logger.warning(f"[REGISTER FAILED] Email already registered: {user_data.email}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered. Please sign in."
        )
    
    new_user = User(
        email=user_data.email,
        hashed_password=hash_password(user_data.password),
        full_name=user_data.full_name,
        role=user_data.role or "resident"
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    # Automatically provision a Resident record for resident registrations
    if new_user.role == "resident":
        existing_res = db.query(Resident).filter(Resident.user_id == new_user.id).first()
        if not existing_res:
            res_record = Resident(
                user_id=new_user.id,
                full_name=new_user.full_name,
                age=25,
                blood_group="O+",
                room_number=f"Suite {100 + new_user.id}",
                address="Main Care Campus, Wing A",
                emergency_contact="+1-555-CARE-911",
                medical_notes="Standard monitoring profile created on registration.",
                status="safe"
            )
            db.add(res_record)
            db.commit()

    logger.info(f"[REGISTER SUCCESS] User ID {new_user.id} registered: {new_user.email} (Role: {new_user.role})")
    access_token = create_access_token(data={"sub": new_user.email})
    return Token(access_token=access_token, token_type="bearer", user=new_user)

@router.post("/login", response_model=Token)
def login(login_data: UserLogin, db: Session = Depends(get_db)):
    logger.info(f"[LOGIN REQUEST] Attempting login for email: {login_data.email}")
    user = db.query(User).filter(User.email == login_data.email).first()
    if not user:
        logger.warning(f"[LOGIN FAILED] User not found: {login_data.email}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )
    if not verify_password(login_data.password, user.hashed_password):
        logger.warning(f"[LOGIN FAILED] Incorrect password for email: {login_data.email}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )
    
    logger.info(f"[LOGIN SUCCESS] User {user.email} authenticated successfully (Role: {user.role})")
    access_token = create_access_token(data={"sub": user.email})
    return Token(access_token=access_token, token_type="bearer", user=user)

@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    return current_user

@router.put("/profile", response_model=UserResponse)
def update_profile(
    profile_data: UserProfileUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    for field, value in profile_data.dict(exclude_unset=True).items():
        if value is not None:
            setattr(current_user, field, value)
    db.commit()
    db.refresh(current_user)
    return current_user

@router.put("/change-password")
def change_password(
    password_data: ChangePasswordRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if not verify_password(password_data.current_password, current_user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Incorrect current password"
        )
    current_user.hashed_password = hash_password(password_data.new_password)
    db.commit()
    return {"message": "Password updated successfully"}

@router.delete("/account")
def delete_account(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    db.delete(current_user)
    db.commit()
    return {"message": "Account deleted successfully"}

@router.get("/activities")
def get_activities(
    current_user: User = Depends(get_current_user)
):
    return [
        {"id": 1, "action": "Profile Updated", "timestamp": "2026-08-01 16:50:00", "details": "Updated height, location and bio"},
        {"id": 2, "action": "Portal Login", "timestamp": "2026-08-01 16:15:00", "details": "Authenticated via CareConnect Portal"},
        {"id": 3, "action": "Security Preferences", "timestamp": "2026-07-30 14:00:00", "details": "Enabled SOS Emergency SMS Broadcasts"}
    ]
