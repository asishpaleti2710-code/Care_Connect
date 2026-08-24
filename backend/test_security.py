import os
import tempfile

os.environ["SECRET_KEY"] = "test-secret-key-that-is-long-enough-for-hs256"
os.environ["DATABASE_URL"] = "sqlite:///" + os.path.join(tempfile.mkdtemp(), "t.db")

from fastapi.testclient import TestClient

from app.main import app
from app.database import SessionLocal
from app.models.resident import Resident
from app.models.user import User, UserRole
from app.services.auth import hash_password

client = TestClient(app)

db = SessionLocal()
admin = User(email="admin@t.org", hashed_password=hash_password("admin1234"),
             full_name="Admin", role=UserRole.ADMIN.value)
db.add(admin)
db.commit()
db.refresh(admin)
resident_user = User(email="res@t.org", hashed_password=hash_password("resident1234"),
                     full_name="Res", role=UserRole.RESIDENT.value)
other_user = User(email="other@t.org", hashed_password=hash_password("other1234"),
                  full_name="Other", role=UserRole.RESIDENT.value)
db.add_all([resident_user, other_user])
db.commit()
db.refresh(resident_user)
db.refresh(other_user)
r1 = Resident(user_id=resident_user.id, full_name="Res", age=70, room_number="1",
              emergency_contact="1", status="safe")
r2 = Resident(user_id=other_user.id, full_name="Other", age=71, room_number="2",
              emergency_contact="2", status="safe")
db.add_all([r1, r2])
db.commit()
db.refresh(r1)
db.refresh(r2)
db.close()


def token(email, password):
    resp = client.post("/api/auth/login", json={"email": email, "password": password})
    assert resp.status_code == 200, resp.text
    return {"Authorization": f"Bearer {resp.json()['access_token']}"}


admin_h = token("admin@t.org", "admin1234")
res_h = token("res@t.org", "resident1234")

# privilege escalation blocked
resp = client.post("/api/auth/register", json={
    "email": "attacker@t.org", "password": "password123",
    "full_name": "Attacker", "role": "admin"})
assert resp.status_code == 403, resp.text

resp = client.post("/api/auth/register", json={
    "email": "newres@t.org", "password": "password123",
    "full_name": "New", "role": "resident"})
assert resp.status_code == 200, resp.text
assert resp.json()["user"]["role"] == "resident"

# weak password rejected
resp = client.post("/api/auth/register", json={
    "email": "weak@t.org", "password": "123", "full_name": "Weak", "role": "resident"})
assert resp.status_code == 422, resp.text

# resident cannot mutate resident records or read analytics
assert client.delete(f"/api/residents/{r2.id}", headers=res_h).status_code == 403
assert client.put(f"/api/residents/{r2.id}", json={"full_name": "x"},
                  headers=res_h).status_code == 403
assert client.get("/api/incidents/analytics", headers=res_h).status_code == 403
assert client.get("/api/incidents/analytics", headers=admin_h).status_code == 200

# resident cannot trigger for someone else, can for self
assert client.post("/api/sos/trigger", json={"resident_id": r2.id},
                   headers=res_h).status_code == 403
assert client.post("/api/sos/trigger", json={"resident_id": r1.id},
                   headers=res_h).status_code == 201
resp = client.post("/api/incidents/trigger", json={"resident_id": r1.id}, headers=res_h)
assert resp.status_code == 201, resp.text
incident_id = resp.json()["id"]

# resident cannot dispatch, admin can
assert client.put(f"/api/incidents/{incident_id}/accept",
                  headers=res_h).status_code == 403
assert client.put(f"/api/incidents/{incident_id}/accept",
                  headers=admin_h).status_code == 200

# unauthenticated access still rejected
assert client.get("/api/residents").status_code in (401, 403)

# invalid incident status rejected
assert client.put(f"/api/incidents/{incident_id}/status", json={"status": "Hacked"},
                  headers=admin_h).status_code == 422

print("security smoke tests passed")
