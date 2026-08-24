from fastapi import APIRouter, HTTPException, status
from app.dependencies import CurrentUser, DbSession
from app.models.user import User
from app.schemas.user import UserCreate, UserLogin, UserResponse, Token, UserProfileUpdate, ChangePasswordRequest
from app.services.auth import hash_password, verify_password, create_access_token
from app.services.crud import apply_updates, save

router = APIRouter(prefix="/api/auth", tags=["Authentication"])

@router.post("/register", response_model=Token)
def register(user_data: UserCreate, db: DbSession):
    db_user = db.query(User).filter(User.email == user_data.email).first()
    if db_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )

    new_user = save(db, User(
        email=user_data.email,
        hashed_password=hash_password(user_data.password),
        full_name=user_data.full_name,
        role=user_data.role or "caregiver"
    ))

    access_token = create_access_token(data={"sub": new_user.email})
    return Token(access_token=access_token, token_type="bearer", user=new_user)

@router.post("/login", response_model=Token)
def login(login_data: UserLogin, db: DbSession):
    user = db.query(User).filter(User.email == login_data.email).first()
    if not user or not verify_password(login_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )
    
    access_token = create_access_token(data={"sub": user.email})
    return Token(access_token=access_token, token_type="bearer", user=user)

@router.get("/me", response_model=UserResponse)
def get_me(current_user: CurrentUser):
    return current_user

@router.put("/profile", response_model=UserResponse)
def update_profile(
    profile_data: UserProfileUpdate,
    db: DbSession,
    current_user: CurrentUser
):
    apply_updates(current_user, profile_data.dict(exclude_unset=True), skip_none=True)
    return save(db, current_user)

@router.put("/change-password")
def change_password(
    password_data: ChangePasswordRequest,
    db: DbSession,
    current_user: CurrentUser
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
def delete_account(db: DbSession, current_user: CurrentUser):
    db.delete(current_user)
    db.commit()
    return {"message": "Account deleted successfully"}

@router.get("/activities")
def get_activities(current_user: CurrentUser):
    return [
        {"id": 1, "action": "Profile Updated", "timestamp": "2026-08-01 16:50:00", "details": "Updated height, location and bio"},
        {"id": 2, "action": "Portal Login", "timestamp": "2026-08-01 16:15:00", "details": "Authenticated via CareConnect Portal"},
        {"id": 3, "action": "Security Preferences", "timestamp": "2026-07-30 14:00:00", "details": "Enabled SOS Emergency SMS Broadcasts"}
    ]
