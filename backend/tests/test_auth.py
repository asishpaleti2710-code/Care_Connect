from app.models.user import User
from app.services.auth import hash_password


def test_authentication_account_lifecycle(client, db):
    registration = client.post(
        "/api/auth/register",
        json={
            "email": "new.user@careconnect.org",
            "password": "initial-password",
            "full_name": "New User",
            "role": "caregiver",
        },
    )

    assert registration.status_code == 200
    token = registration.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    duplicate = client.post(
        "/api/auth/register",
        json={
            "email": "new.user@careconnect.org",
            "password": "initial-password",
            "full_name": "Duplicate User",
        },
    )
    assert duplicate.status_code == 400
    assert duplicate.json()["detail"] == "Email already registered"

    invalid_login = client.post(
        "/api/auth/login",
        json={
            "email": "new.user@careconnect.org",
            "password": "wrong-password",
        },
    )
    assert invalid_login.status_code == 401

    profile = client.put(
        "/api/auth/profile",
        headers=headers,
        json={"full_name": "Updated User", "bio": "Community caregiver"},
    )
    assert profile.status_code == 200
    assert profile.json()["full_name"] == "Updated User"
    assert profile.json()["bio"] == "Community caregiver"

    wrong_password = client.put(
        "/api/auth/change-password",
        headers=headers,
        json={
            "current_password": "wrong-password",
            "new_password": "updated-password",
        },
    )
    assert wrong_password.status_code == 400
    assert wrong_password.json()["detail"] == "Incorrect current password"

    password_update = client.put(
        "/api/auth/change-password",
        headers=headers,
        json={
            "current_password": "initial-password",
            "new_password": "updated-password",
        },
    )
    assert password_update.status_code == 200

    login = client.post(
        "/api/auth/login",
        json={
            "email": "new.user@careconnect.org",
            "password": "updated-password",
        },
    )
    assert login.status_code == 200

    activities = client.get("/api/auth/activities", headers=headers)
    assert activities.status_code == 200
    assert len(activities.json()) == 3

    deletion = client.delete("/api/auth/account", headers=headers)
    assert deletion.status_code == 200
    assert db.query(User).filter(User.email == "new.user@careconnect.org").first() is None


def test_current_user_rejects_invalid_tokens_and_unknown_users(client, db):
    malformed = client.get(
        "/api/auth/me",
        headers={"Authorization": "Bearer not-a-token"},
    )
    assert malformed.status_code == 401

    user = User(
        email="removed.user@careconnect.org",
        hashed_password=hash_password("password"),
        full_name="Removed User",
        role="caregiver",
    )
    db.add(user)
    db.commit()

    login = client.post(
        "/api/auth/login",
        json={"email": user.email, "password": "password"},
    )
    token = login.json()["access_token"]
    db.delete(user)
    db.commit()

    missing_user = client.get(
        "/api/auth/me",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert missing_user.status_code == 401
