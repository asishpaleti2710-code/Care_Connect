from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def get_tokens():
    roles = {
        "resident": ("ashish@careconnect.org", "resident123"),
        "guardian": ("guardian@careconnect.org", "guard123"),
        "security": ("security@careconnect.org", "sec123"),
        "volunteer": ("volunteer@careconnect.org", "vol123"),
        "admin": ("admin@careconnect.org", "admin123"),
    }
    tokens = {}
    for role, (email, pwd) in roles.items():
        res = client.post("/api/auth/login", json={"email": email, "password": pwd})
        assert res.status_code == 200, f"Login failed for {email}"
        tokens[role] = res.json()["access_token"]
    return tokens

def test_sos_full_lifecycle():
    tokens = get_tokens()
    headers_res = {"Authorization": f"Bearer {tokens['resident']}"}
    headers_sec = {"Authorization": f"Bearer {tokens['security']}"}
    headers_guard = {"Authorization": f"Bearer {tokens['guardian']}"}
    headers_vol = {"Authorization": f"Bearer {tokens['volunteer']}"}
    headers_admin = {"Authorization": f"Bearer {tokens['admin']}"}

    # 1. Resident triggers SOS with GPS coordinates & message
    sos_payload = {
        "category": "Medical Emergency",
        "message": "I fell near the bed and cannot stand up. Need urgent help!",
        "latitude": 13.0827,
        "longitude": 80.2707,
        "priority": "CRITICAL"
    }

    create_resp = client.post("/api/sos", json=sos_payload, headers=headers_res)
    assert create_resp.status_code == 201, f"Create SOS failed: {create_resp.text}"
    sos_data = create_resp.json()
    alert_id = sos_data["id"]

    assert sos_data["status"] == "ACTIVE"
    assert sos_data["category"] == "Medical Emergency"
    assert sos_data["latitude"] == 13.0827
    assert sos_data["longitude"] == 80.2707
    assert "https://www.google.com/maps?q=13.0827,80.2707" in sos_data["maps_url"]
    assert len(sos_data["audit_logs"]) >= 1
    print(f"[TEST 1 PASSED] SOS Alert Created (ID: {alert_id}, Status: ACTIVE, Maps URL: {sos_data['maps_url']})")

    # 2. Check Tiered Notification Dispatches
    all_notifs_resp = client.get(f"/api/notifications/all?sos_id={alert_id}", headers=headers_admin)
    assert all_notifs_resp.status_code == 200
    dispatched_notifs = all_notifs_resp.json()
    assert len(dispatched_notifs) >= 3, f"Expected notifications for multiple roles, got {len(dispatched_notifs)}"

    roles_notified = {n["recipient_role"] for n in dispatched_notifs if n["recipient_role"]}
    channels_used = {n["channel"] for n in dispatched_notifs}
    statuses = {n["status"] for n in dispatched_notifs}

    assert "guardian" in roles_notified, "Guardian should be notified"
    assert "security" in roles_notified, "Security should be notified"
    assert "IN_APP" in channels_used, "In-App channel should be dispatched"
    assert "DELIVERED" in statuses, "In-app notifications must be marked DELIVERED"
    print(f"[TEST 2 PASSED] Tiered Alert Routing Verified (Roles: {roles_notified}, Channels: {channels_used})")

    # 3. Security Acknowledges the Alert
    ack_resp = client.post(f"/api/sos/{alert_id}/acknowledge", headers=headers_sec)
    assert ack_resp.status_code == 200
    ack_data = ack_resp.json()
    assert ack_data["status"] == "ACKNOWLEDGED"
    assert ack_data["responder_name"] == "Officer Marcus Vance"
    assert ack_data["responder_role"] == "security"
    assert ack_data["time_to_acknowledge_seconds"] is not None
    print(f"[TEST 3 PASSED] Responder Acknowledgment Verified (Responder: {ack_data['responder_name']}, Time: {ack_data['time_to_acknowledge_seconds']}s)")

    # 4. Security Dispatches / Responds with Notes
    resp_resp = client.post(
        f"/api/sos/{alert_id}/respond",
        json={"notes": "Security officer en route with first aid kit."},
        headers=headers_sec
    )
    assert resp_resp.status_code == 200
    responding_data = resp_resp.json()
    assert responding_data["status"] == "RESPONDING"
    assert responding_data["response_notes"] == "Security officer en route with first aid kit."
    print(f"[TEST 4 PASSED] Response Dispatch Verified (Status: RESPONDING)")

    # 5. Resolve the SOS Alert
    res_resp = client.post(
        f"/api/sos/{alert_id}/resolve",
        json={"notes": "Resident attended, vitals stable, family informed."},
        headers=headers_sec
    )
    assert res_resp.status_code == 200
    resolved_data = res_resp.json()
    assert resolved_data["status"] == "RESOLVED"
    assert resolved_data["time_to_resolve_seconds"] is not None
    print(f"[TEST 5 PASSED] Alert Resolution Verified (Status: RESOLVED, Resolve Time: {resolved_data['time_to_resolve_seconds']}s)")

    # 6. Test SOS Cancellation Workflow (Trigger & Cancel)
    sos2_resp = client.post(
        "/api/sos",
        json={"category": "Accident", "message": "Accidental tap test", "priority": "HIGH"},
        headers=headers_res
    )
    assert sos2_resp.status_code == 201
    alert2_id = sos2_resp.json()["id"]

    cancel_resp = client.post(
        f"/api/sos/{alert2_id}/cancel",
        json={"reason": "False alarm, pressed by mistake"},
        headers=headers_res
    )
    assert cancel_resp.status_code == 200
    cancelled_data = cancel_resp.json()
    assert cancelled_data["status"] == "CANCELLED"
    assert "False alarm" in cancelled_data["response_notes"]
    print(f"[TEST 6 PASSED] SOS Cancellation Verified (Status: CANCELLED)")

    # 7. Check SOS Monitoring & Analytics API
    analytics_resp = client.get("/api/sos/monitoring", headers=headers_admin)
    assert analytics_resp.status_code == 200
    analytics = analytics_resp.json()
    assert analytics["total_alerts"] >= 2
    assert "Medical Emergency" in analytics["category_breakdown"]
    assert analytics["resolved_alerts"] >= 1
    assert analytics["cancelled_alerts"] >= 1
    print(f"[TEST 7 PASSED] SOS Monitoring & Analytics API Verified (Total: {analytics['total_alerts']}, Resolved: {analytics['resolved_alerts']})")

    # 8. Test In-App Notification Center Endpoints
    sec_notifs_resp = client.get("/api/notifications", headers=headers_sec)
    assert sec_notifs_resp.status_code == 200
    sec_notifs = sec_notifs_resp.json()
    assert len(sec_notifs) >= 1
    notif_id = sec_notifs[0]["id"]

    # Mark single read
    read_resp = client.put(f"/api/notifications/{notif_id}/read", headers=headers_sec)
    assert read_resp.status_code == 200
    assert read_resp.json()["is_read"] is True

    # Mark all read
    read_all_resp = client.put("/api/notifications/read-all", headers=headers_sec)
    assert read_all_resp.status_code == 200

    # Notification stats
    stats_resp = client.get("/api/notifications/stats", headers=headers_sec)
    assert stats_resp.status_code == 200
    assert "total" in stats_resp.json()
    print(f"[TEST 8 PASSED] Notification Center API Verified (Read tracking and stats functional)")

if __name__ == "__main__":
    print("--- RUNNING SOS ALERT & EMERGENCY NOTIFICATION SYSTEM TESTS ---")
    test_sos_full_lifecycle()
    print("--- ALL SOS ALERT & NOTIFICATION SYSTEM TESTS PASSED SUCCESSFULLY! ---")
