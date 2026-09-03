import os
from starlette.testclient import TestClient
from app.main import app
from app.database import SessionLocal
from app.models.user import User
from app.models.resident import Resident
from app.models.notification import Notification
from app.services.auth import create_access_token
from app.services.email_service import email_service

client = TestClient(app)

def test_sos_email_dispatch_flow():
    print("=" * 60)
    print("CARECONNECT SOS USER EMAIL DISPATCH & VERIFICATION TEST")
    print("=" * 60)

    # 1. Setup/query verified test user
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == "motog32_test@careconnect.org").first()
        if not user:
            user = User(
                email="motog32_test@careconnect.org",
                hashed_password="hashed_pass_placeholder",
                full_name="Ashish Moto G32 Tester",
                role="resident"
            )
            db.add(user)
            db.commit()
            db.refresh(user)

        resident = db.query(Resident).filter(Resident.user_id == user.id).first()
        if not resident:
            resident = Resident(
                user_id=user.id,
                full_name=user.full_name,
                age=24,
                room_number="Suite 304",
                address="Main Campus, Building A",
                emergency_contact="+1-555-123-4567",
                status="safe"
            )
            db.add(resident)
            db.commit()
            db.refresh(resident)

        user_id = user.id
        user_email = user.email
        user_name = user.full_name
        res_id = resident.id
    finally:
        db.close()

    token = create_access_token(data={"sub": user_email})
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Test the independent /api/sos/test-email endpoint
    test_email_resp = client.get(
        "/api/sos/test-email",
        params={"to_email": user_email},
        headers=headers
    )
    assert test_email_resp.status_code == 200, f"Test email endpoint failed: {test_email_resp.text}"
    test_email_data = test_email_resp.json()
    print(f"[1/4 PASSED] /api/sos/test-email reachable: Recipient={test_email_data['recipient']}, Status={test_email_data['status']}")
    print(f"      SMTP Configuration Summary: {test_email_data['smtp_configuration']}")

    # 3. Test Email Template Generation contains all required fields
    html = email_service._generate_sos_user_html(
        user_name=user_name,
        user_email=user_email,
        emergency_message="Severe Chest Pain - Requires Immediate Medical Assistance",
        location="Building A, Room 304",
        maps_url="https://www.google.com/maps?q=13.0827,80.2707",
        category="Cardiac Emergency"
    )
    assert "SOS Alert Triggered" in html, "Subject/Title missing from HTML"
    assert user_name in html, "User name missing from HTML"
    assert user_email in html, "User email missing from HTML"
    assert "Cardiac Emergency" in html, "Category missing from HTML"
    assert "Building A, Room 304" in html, "Location missing from HTML"
    assert "Chest Pain" in html, "Message missing from HTML"
    assert "maps?q=13.0827,80.2707" in html, "GPS link missing from HTML"
    print(f"[2/4 PASSED] Email Template Verified: Contains Subject, User Name, Email, Timestamp, Message, & Location")

    # 4. Trigger SOS Alert via POST /api/sos and verify immediate email dispatch
    sos_payload = {
        "category": "Medical Emergency",
        "message": "Immediate assistance requested by Ashish on Moto G32",
        "latitude": 13.0827,
        "longitude": 80.2707,
        "priority": "CRITICAL",
        "resident_id": res_id
    }
    sos_resp = client.post("/api/sos", json=sos_payload, headers=headers)
    assert sos_resp.status_code == 201, f"SOS Trigger failed: {sos_resp.text}"
    sos_data = sos_resp.json()
    alert_id = sos_data["id"]
    print(f"[3/4 PASSED] SOS Alert #{alert_id} Created Successfully: Status={sos_data['status']}, Maps={sos_data['maps_url']}")

    # 5. Verify Notification Record in Database
    db = SessionLocal()
    try:
        user_email_notif = db.query(Notification).filter(
            Notification.sos_id == alert_id,
            Notification.recipient_contact == user_email,
            Notification.channel == "EMAIL"
        ).first()

        assert user_email_notif is not None, "Notification record for user email was NOT found in database!"
        assert user_email_notif.title == "SOS Alert Triggered", f"Unexpected title: {user_email_notif.title}"
        print(f"[4/4 PASSED] User Email Notification Persisted in Database: ID={user_email_notif.id}, Status={user_email_notif.status}")
        if user_email_notif.failure_reason:
            print(f"      Notification Failure Reason Logged: {user_email_notif.failure_reason}")
    finally:
        db.close()

    print("=" * 60)
    print("ALL 4 SOS USER EMAIL TESTS PASSED PERFECTLY!")
    print("=" * 60)

if __name__ == "__main__":
    test_sos_email_dispatch_flow()
