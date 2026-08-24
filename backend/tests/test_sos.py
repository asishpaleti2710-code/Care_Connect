from app.models.resident import Resident
from app.models.sos import SOSAlert
from app.models.user import User
from app.services.auth import create_access_token, hash_password


def create_authenticated_resident(db):
    user = User(
        email="resident@careconnect.org",
        hashed_password=hash_password("password"),
        full_name="Test Resident",
        role="resident",
    )
    db.add(user)
    db.flush()

    resident = Resident(
        user_id=user.id,
        full_name="Test Resident",
        age=79,
        room_number="101-A",
        emergency_contact="+1-555-0100",
        status="safe",
    )
    db.add(resident)
    db.commit()
    db.refresh(resident)

    token = create_access_token({"sub": user.email})
    return resident, {"Authorization": f"Bearer {token}"}


def test_sos_trigger_and_resolve_updates_resident_status(client, db):
    resident, headers = create_authenticated_resident(db)

    trigger = client.post(
        "/api/sos/trigger",
        headers=headers,
        json={"resident_id": resident.id},
    )
    assert trigger.status_code == 201
    alert = trigger.json()
    assert alert["alert_type"] == "Medical Emergency"
    assert alert["message"] == (
        "SOS Alert triggered for Test Resident in Room 101-A"
    )

    db.refresh(resident)
    assert resident.status == "emergency"

    alerts = client.get("/api/sos/alerts", headers=headers)
    assert alerts.status_code == 200
    assert [item["id"] for item in alerts.json()] == [alert["id"]]

    another_alert = SOSAlert(
        resident_id=resident.id,
        alert_type="Fall",
        status="active",
    )
    db.add(another_alert)
    db.commit()

    first_resolution = client.put(
        f"/api/sos/resolve/{alert['id']}",
        headers=headers,
    )
    assert first_resolution.status_code == 200
    db.refresh(resident)
    assert resident.status == "emergency"

    final_resolution = client.put(
        f"/api/sos/resolve/{another_alert.id}",
        headers=headers,
    )
    assert final_resolution.status_code == 200
    assert final_resolution.json()["status"] == "resolved"
    db.refresh(resident)
    assert resident.status == "safe"


def test_sos_endpoints_return_not_found_for_unknown_records(client, db):
    _, headers = create_authenticated_resident(db)

    missing_resident = client.post(
        "/api/sos/trigger",
        headers=headers,
        json={"resident_id": 9999},
    )
    assert missing_resident.status_code == 404
    assert missing_resident.json()["detail"] == "Resident not found"

    missing_alert = client.put(
        "/api/sos/resolve/9999",
        headers=headers,
    )
    assert missing_alert.status_code == 404
    assert missing_alert.json()["detail"] == "SOS alert not found"
