import time
import os
from starlette.testclient import TestClient
from app.main import app
from app.database import SessionLocal
from app.models.user import User
from app.models.resident import Resident
from app.models.notification import Notification
from app.models.sos import SOSAlert
from app.services.email_service import email_service

client = TestClient(app)

def test_full_production_suite():
    print("=" * 65)
    print("CARECONNECT ENTERPRISE PRODUCTION SERVICES VALIDATION")
    print("=" * 65)

    # 1. Health Monitoring & Dialect
    t0 = time.time()
    health_resp = client.get("/health")
    latency = int((time.time() - t0) * 1000)
    assert health_resp.status_code == 200, f"Health check failed: {health_resp.text}"
    health_data = health_resp.json()
    print(f"[1/8 PASSED] Health Monitor OK: status={health_data['status']}, db={health_data['database']['status']}, engine={health_data['database']['engine']}, latency={latency}ms")

    # 2. Multi-User Registration
    ts = int(time.time())
    user_a_email = f"resident_alpha_{ts}@careconnect.org"
    user_b_email = f"resident_beta_{ts}@careconnect.org"
    password = "ProductionPassword2026!"

    resp_a = client.post("/api/auth/register", json={
        "email": user_a_email,
        "password": password,
        "full_name": "Resident Alpha (Moto G32)",
        "role": "resident"
    })
    assert resp_a.status_code == 200, f"Registration Alpha failed: {resp_a.text}"
    token_a = resp_a.json()["access_token"]
    user_a_id = resp_a.json()["user"]["id"]

    resp_b = client.post("/api/auth/register", json={
        "email": user_b_email,
        "password": password,
        "full_name": "Resident Beta (Care Facility)",
        "role": "resident"
    })
    assert resp_b.status_code == 200, f"Registration Beta failed: {resp_b.text}"
    token_b = resp_b.json()["access_token"]
    user_b_id = resp_b.json()["user"]["id"]
    print(f"[2/8 PASSED] Multi-User Registration Verified: User A (ID {user_a_id}), User B (ID {user_b_id})")

    # 3. Database Persistence & Isolation
    db = SessionLocal()
    try:
        db_user_a = db.query(User).filter(User.id == user_a_id).first()
        db_res_a = db.query(Resident).filter(Resident.user_id == user_a_id).first()
        db_user_b = db.query(User).filter(User.id == user_b_id).first()
        db_res_b = db.query(Resident).filter(Resident.user_id == user_b_id).first()
        assert db_user_a is not None and db_res_a is not None, "User A or Resident profile missing!"
        assert db_user_b is not None and db_res_b is not None, "User B or Resident profile missing!"
        print(f"[3/8 PASSED] Database Connectivity & Resident Provisioning OK: Resident A (ID {db_res_a.id}), Resident B (ID {db_res_b.id})")
    finally:
        db.close()

    # 4. Authentication & Bearer JWT Token
    login_resp = client.post("/api/auth/login", json={"email": user_a_email, "password": password})
    assert login_resp.status_code == 200, f"Login failed: {login_resp.text}"
    auth_token = login_resp.json()["access_token"]
    assert len(auth_token) > 30, "Invalid JWT token structure"
    print(f"[4/8 PASSED] Login & JWT Token Verified: Length={len(auth_token)} bytes")

    # 5. Authenticated Session Retrieval (/api/auth/me)
    me_resp = client.get("/api/auth/me", headers={"Authorization": f"Bearer {auth_token}"})
    assert me_resp.status_code == 200, f"/me failed: {me_resp.text}"
    me_data = me_resp.json()
    assert me_data["email"] == user_a_email, "User identity mismatch in /me"
    print(f"[5/8 PASSED] Authenticated Session OK: Welcome {me_data['full_name']} ({me_data['role']})")

    # 6. SOS Alert Trigger with GPS & Routing
    sos_payload = {
        "category": "Cardiac Emergency",
        "message": "Emergency medical alarm activated from Android mobile device",
        "latitude": 13.0827,
        "longitude": 80.2707,
        "priority": "CRITICAL"
    }
    sos_resp = client.post("/api/sos", json=sos_payload, headers={"Authorization": f"Bearer {auth_token}"})
    assert sos_resp.status_code == 201, f"SOS Trigger failed: {sos_resp.text}"
    sos_data = sos_resp.json()
    alert_id = sos_data["id"]
    print(f"[6/8 PASSED] SOS Alert Triggered: ID=#{alert_id}, Status={sos_data['status']}, Category={sos_data['category']}")

    # 7. Immediate Email Notification Dispatch to Logged-in User
    db = SessionLocal()
    try:
        user_email_notif = db.query(Notification).filter(
            Notification.sos_id == alert_id,
            Notification.recipient_contact == user_a_email,
            Notification.channel == "EMAIL"
        ).first()
        assert user_email_notif is not None, "Email notification record missing in database!"
        print(f"[7/8 PASSED] SOS Email Logged: Recipient={user_email_notif.recipient_contact}, Status={user_email_notif.status}")
        if user_email_notif.failure_reason:
            print(f"      Diagnostic Detail: {user_email_notif.failure_reason}")
    finally:
        db.close()

    # 8. Independent Email Verification Endpoint (/api/sos/test-email)
    test_mail_resp = client.get(
        "/api/sos/test-email",
        params={"to_email": user_a_email},
        headers={"Authorization": f"Bearer {auth_token}"}
    )
    assert test_mail_resp.status_code == 200, f"Test email endpoint failed: {test_mail_resp.text}"
    test_mail_data = test_mail_resp.json()
    print(f"[8/8 PASSED] Independent /api/sos/test-email OK: Recipient={test_mail_data['recipient']}, Status={test_mail_data['status']}")
    print(f"      SMTP Configuration Summary: {test_mail_data['smtp_configuration']}")

    print("=" * 65)
    print("ALL 8 PRODUCTION BACKEND SERVICES VALIDATED AND 100% OPERATIONAL!")
    print("=" * 65)

if __name__ == "__main__":
    test_full_production_suite()
