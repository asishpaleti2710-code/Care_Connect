import pytest

from agent_service import AIAgentService


@pytest.fixture
def service():
    return AIAgentService()


@pytest.mark.parametrize(
    ("description", "category", "priority"),
    [
        ("There is an intruder with a knife", "Security Threat", "Critical"),
        ("Resident slipped and fell", "Fall Incident", "High"),
        ("Resident reports chest pain", "Medical Emergency", "Critical"),
        ("Smoke is coming from a gas leak", "Fire & Safety", "Critical"),
        ("Resident needs immediate assistance", "General Emergency", "High"),
    ],
)
def test_classify_emergency_categories(service, description, category, priority):
    result = service.classify_emergency(description)

    assert result["description"] == description
    assert result["category"] == category
    assert result["priority"] == priority
    assert result["suggested_responders"]
    assert result["immediate_advice"]


@pytest.mark.parametrize(
    ("name", "age", "notes", "risk_level", "risk_score", "summary_fragment"),
    [
        ("Arthur", 70, "History of cardiac issues", "High", 85, "cardiac"),
        ("Eleanor", 86, "", "High", 85, "Advanced age"),
        ("Clara", 70, "Managed diabetes", "Moderate", 55, "diabetes"),
        ("Sam", 75, "", "Moderate", 55, "Routine age care"),
        ("Alex", 60, "No known conditions", "Low", 20, "routine care"),
    ],
)
def test_analyze_medical_notes_risk_levels(
    service,
    name,
    age,
    notes,
    risk_level,
    risk_score,
    summary_fragment,
):
    result = service.analyze_medical_notes(name, age, notes)

    assert result["resident_name"] == name
    assert result["risk_level"] == risk_level
    assert result["risk_score"] == risk_score
    assert summary_fragment in result["summary"]
    assert result["recommendations"]


@pytest.mark.parametrize(
    ("query", "response_fragment"),
    [
        ("What is the fall emergency protocol?", "Emergency Protocol"),
        ("What should I do about high BP?", "Blood Pressure Guidance"),
        ("How can I support memory loss?", "Cognitive Care"),
        ("Where is the resident profile?", "CareConnect AI Assistant"),
    ],
)
def test_answer_caregiver_query_routes_guidance(service, query, response_fragment):
    assert response_fragment in service.answer_caregiver_query(query)
