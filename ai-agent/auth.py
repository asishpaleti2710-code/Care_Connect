import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from config import settings

ALGORITHM = "HS256"

bearer_scheme = HTTPBearer(auto_error=settings.REQUIRE_AUTH)


def require_token(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> dict | None:
    """Validate the CareConnect access token issued by the backend API."""
    if not settings.REQUIRE_AUTH:
        return None

    unauthorized = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    if credentials is None:
        raise unauthorized
    try:
        return jwt.decode(
            credentials.credentials, settings.SECRET_KEY, algorithms=[ALGORITHM]
        )
    except jwt.PyJWTError:
        raise unauthorized
