import sys
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health():
    resp = client.get("/health")
    assert resp.status_code == 200
    print("[OK] Health Check Passed")

def test_roles_and_auth():
    roles = [
        ("ashish@careconnect.org", "resident123", "resident"),
        ("guardian@careconnect.org", "guard123", "guardian"),
        ("volunteer@careconnect.org", "vol123", "volunteer"),
        ("security@careconnect.org", "sec123", "security"),
        ("admin@careconnect.org", "admin123", "admin")
    ]
    tokens = {}
    for email, pwd, role in roles:
        res = client.post("/api/auth/login", json={"email": email, "password": pwd})
        assert res.status_code == 200
        data = res.json()
        assert data["user"]["role"] == role
        tokens[role] = data["access_token"]
        print(f"[OK] Auth Login Passed for Role: {role.upper()}")
    return tokens

def test_guardians_api(tokens):
    headers = {"Authorization": f"Bearer {tokens['resident']}"}
    res_list = client.get("/api/residents", headers=headers).json()
    ashish_res = [r for r in res_list if r["full_name"] == "Ashish"][0]
    
    # Get guardians
    guardians_resp = client.get(f"/api/guardians/resident/{ashish_res['id']}", headers=headers)
    assert guardians_resp.status_code == 200
    guardians = guardians_resp.json()
    assert len(guardians) >= 2
    print(f"[OK] Guardians Endpoint Passed (Found {len(guardians)} guardians for Ashish)")

def test_incident_workflow(tokens):
    headers_res = {"Authorization": f"Bearer {tokens['resident']}"}
    headers_sec = {"Authorization": f"Bearer {tokens['security']}"}
    
    # Get Ashish resident ID
    residents = client.get("/api/residents", headers=headers_res).json()
    ashish = [r for r in residents if r["full_name"] == "Ashish"][0]

    # 1. Trigger Incident
    inc_payload = {
        "resident_id": ashish["id"],
        "emergency_type": "Medical Emergency",
        "priority": "Critical",
        "description": "Heart rate spike detected near bedside.",
        "location": "Flat A-302"
    }
    trigger_resp = client.post("/api/incidents/trigger", json=inc_payload, headers=headers_res)
    assert trigger_resp.status_code == 201
    inc = trigger_resp.json()
    assert inc["status"] == "Pending"
    inc_id = inc["id"]
    print(f"[OK] Trigger Incident Passed (Code: {inc['incident_code']}, Status: {inc['status']})")

    # 2. Security Accepts Incident
    accept_resp = client.put(f"/api/incidents/{inc_id}/accept", headers=headers_sec)
    assert accept_resp.status_code == 200
    inc_accepted = accept_resp.json()
    assert inc_accepted["status"] == "Accepted"
    assert inc_accepted["responder_role"] == "security"
    print(f"[OK] Responder Acceptance Passed (Responder: {inc_accepted['responder_name']})")

    # 3. Status Progress to Resolved
    resolve_resp = client.put(f"/api/incidents/{inc_id}/status", json={"status": "Resolved"}, headers=headers_sec)
    assert resolve_resp.status_code == 200
    inc_resolved = resolve_resp.json()
    assert inc_resolved["status"] == "Resolved"
    print("[OK] Incident Resolution Workflow Passed")

def test_analytics(tokens):
    headers = {"Authorization": f"Bearer {tokens['admin']}"}
    resp = client.get("/api/incidents/analytics", headers=headers)
    assert resp.status_code == 200
    data = resp.json()
    assert "total_incidents" in data
    print(f"[OK] Incident Analytics Passed (Total Incidents: {data['total_incidents']})")

if __name__ == "__main__":
    print("--- RUNNING CARECONNECT PORTFOLIO SUITE ---")
    test_health()
    tokens = test_roles_and_auth()
    test_guardians_api(tokens)
    test_incident_workflow(tokens)
    test_analytics(tokens)
    print("--- ALL BACKEND PORTFOLIO TESTS PASSED ---")
