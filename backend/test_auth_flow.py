import time
from starlette.testclient import TestClient
from app.main import app
from app.database import SessionLocal
from app.models.user import User
from app.models.resident import Resident

client = TestClient(app)

def test_full_auth_lifecycle():
    print("=" * 60)
    print("CARECONNECT COMPLETE AUTHENTICATION FLOW VERIFICATION")
    print("=" * 60)

    # 1. Check Server Health
    health_resp = client.get("/health")
    assert health_resp.status_code == 200, f"Health check failed: {health_resp.text}"
    print(f"[1/7 PASSED] Backend Health Check OK: {health_resp.json()}")

    # 2. Register New User
    timestamp = int(time.time())
    test_email = f"motog32_user_{timestamp}@careconnect.org"
    test_password = "SecurePassword123!"
    test_name = "Ashish Moto G32 Tester"

    reg_payload = {
        "email": test_email,
        "password": test_password,
        "full_name": test_name,
        "role": "resident"
    }

    reg_resp = client.post("/api/auth/register", json=reg_payload)
    assert reg_resp.status_code == 200, f"Registration failed: {reg_resp.text}"
    reg_data = reg_resp.json()
    assert "access_token" in reg_data, "access_token missing from register response"
    assert reg_data["user"]["email"] == test_email, "Email mismatch in registration"
    print(f"[2/7 PASSED] Registration Endpoint Reachable: User ID {reg_data['user']['id']} ({test_email})")

    # 3. Verify Database Insertion & Resident Provisioning
    db = SessionLocal()
    try:
        db_user = db.query(User).filter(User.email == test_email).first()
        assert db_user is not None, "User not found in database!"
        assert db_user.full_name == test_name, "Name mismatch in database"
        assert db_user.role == "resident", "Role mismatch in database"

        db_resident = db.query(Resident).filter(Resident.user_id == db_user.id).first()
        assert db_resident is not None, "Resident profile was not automatically provisioned for resident role!"
        print(f"[3/7 PASSED] Database Insertion Verified: User DB ID={db_user.id}, Resident ID={db_resident.id}, Room={db_resident.room_number}")
    finally:
        db.close()

    # 4. Login With Newly Created Account
    login_payload = {
        "email": test_email,
        "password": test_password
    }
    login_resp = client.post("/api/auth/login", json=login_payload)
    assert login_resp.status_code == 200, f"Login failed: {login_resp.text}"
    login_data = login_resp.json()
    token = login_data["access_token"]
    assert token is not None and len(token) > 20, "Invalid JWT access token returned"
    print(f"[4/7 PASSED] Login Endpoint OK: Received JWT Bearer Token (Length: {len(token)})")

    # 5. Verify Authenticated Session with Bearer Token (/api/auth/me)
    headers = {"Authorization": f"Bearer {token}"}
    me_resp = client.get("/api/auth/me", headers=headers)
    assert me_resp.status_code == 200, f"Authenticated /me call failed: {me_resp.text}"
    me_data = me_resp.json()
    assert me_data["email"] == test_email, "/me email mismatch"
    assert me_data["role"] == "resident", "/me role mismatch"
    print(f"[5/7 PASSED] Authenticated Session Verified via /api/auth/me: Welcome, {me_data['full_name']}")

    # 6. Verify Invalid Password Rejection
    bad_login_payload = {
        "email": test_email,
        "password": "WrongPassword999!"
    }
    bad_login_resp = client.post("/api/auth/login", json=bad_login_payload)
    assert bad_login_resp.status_code == 401, f"Expected 401 for bad password, got {bad_login_resp.status_code}"
    print(f"[6/7 PASSED] Password Verification Enforced: Correctly rejected invalid password (401)")

    # 7. Verify Duplicate Registration Prevention
    dup_resp = client.post("/api/auth/register", json=reg_payload)
    assert dup_resp.status_code == 400, f"Expected 400 for duplicate email, got {dup_resp.status_code}"
    print(f"[7/7 PASSED] Unique Constraint Enforced: Duplicate registration rejected (400)")

    print("=" * 60)
    print("ALL 7 AUTHENTICATION LIFECYCLE TESTS PASSED PERFECTLY!")
    print("=" * 60)

if __name__ == "__main__":
    test_full_auth_lifecycle()
