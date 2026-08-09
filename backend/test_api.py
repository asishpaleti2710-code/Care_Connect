import sys
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    print("HEALTH CHECK OK")

def test_auth_login():
    # Login with seeded caregiver
    response = client.post(
        "/api/auth/login",
        json={"email": "caregiver@careconnect.org", "password": "care123"}
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    token = data["access_token"]
    print(f"AUTH LOGIN OK (Token length: {len(token)})")
    return token

def test_residents(token):
    headers = {"Authorization": f"Bearer {token}"}
    
    # Get residents list
    response = client.get("/api/residents", headers=headers)
    assert response.status_code == 200
    residents = response.json()
    assert len(residents) >= 4
    print(f"GET RESIDENTS OK (Count: {len(residents)})")

    # Add a new resident
    new_res_payload = {
        "full_name": "Test Resident",
        "age": 75,
        "room_number": "301-A",
        "medical_notes": "Allergic to penicillin.",
        "emergency_contact": "+1-555-0999"
    }
    response = client.post("/api/residents", json=new_res_payload, headers=headers)
    assert response.status_code == 201
    created_res = response.json()
    assert created_res["full_name"] == "Test Resident"
    res_id = created_res["id"]
    print(f"CREATE RESIDENT OK (ID: {res_id})")

    # Delete test resident
    del_resp = client.delete(f"/api/residents/{res_id}", headers=headers)
    assert del_resp.status_code == 204
    print("DELETE RESIDENT OK")

def test_sos_alerts(token):
    headers = {"Authorization": f"Bearer {token}"}
    
    # Get alerts
    response = client.get("/api/sos/alerts", headers=headers)
    assert response.status_code == 200
    alerts = response.json()
    assert len(alerts) >= 1
    print(f"GET SOS ALERTS OK (Count: {len(alerts)})")

if __name__ == "__main__":
    print("--- Running Backend API Tests ---")
    test_health_check()
    token = test_auth_login()
    test_residents(token)
    test_sos_alerts(token)
    print("--- ALL BACKEND TESTS PASSED SUCCESSFULLY ---")
