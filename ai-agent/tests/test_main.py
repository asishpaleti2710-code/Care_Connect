from fastapi.testclient import TestClient

import main


client = TestClient(main.app)


def test_ai_agent_endpoints():
    root = client.get("/")
    assert root.status_code == 200
    assert root.json()["status"] == "online"

    classification = client.post(
        "/api/ai/classify-emergency",
        json={"description": "Resident is having trouble breathing"},
    )
    assert classification.status_code == 200
    assert classification.json()["category"] == "Medical Emergency"

    analysis = client.post(
        "/api/ai/analyze-notes",
        json={
            "full_name": "Eleanor",
            "age": 78,
            "medical_notes": "Hypertension",
        },
    )
    assert analysis.status_code == 200
    assert analysis.json()["risk_level"] == "Moderate"

    chat = client.post(
        "/api/ai/chat",
        json={"query": "What is the SOS protocol?", "context": {"room": "101-A"}},
    )
    assert chat.status_code == 200
    assert chat.json()["query"] == "What is the SOS protocol?"
    assert "Emergency Protocol" in chat.json()["reply"]


def test_ai_agent_endpoints_translate_service_errors(monkeypatch):
    def fail(*args, **kwargs):
        raise RuntimeError("service unavailable")

    monkeypatch.setattr(main.ai_service, "classify_emergency", fail)
    monkeypatch.setattr(main.ai_service, "analyze_medical_notes", fail)
    monkeypatch.setattr(main.ai_service, "answer_caregiver_query", fail)

    responses = [
        client.post(
            "/api/ai/classify-emergency",
            json={"description": "Help"},
        ),
        client.post(
            "/api/ai/analyze-notes",
            json={
                "full_name": "Eleanor",
                "age": 78,
                "medical_notes": "Hypertension",
            },
        ),
        client.post(
            "/api/ai/chat",
            json={"query": "Help"},
        ),
    ]

    for response in responses:
        assert response.status_code == 500
        assert response.json()["detail"] == "service unavailable"
