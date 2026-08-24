from typing import Sequence, Type

from sqlalchemy.orm import Session

from app.models.resident import Resident


def clear_resident_emergency(
    db: Session,
    resident_id: int,
    model: Type,
    active_statuses: Sequence[str],
    exclude_id: int,
) -> None:
    """Mark a resident safe again once no other active alert/incident references them."""
    remaining = db.query(model).filter(
        model.resident_id == resident_id,
        model.status.in_(active_statuses),
        model.id != exclude_id,
    ).count()

    if remaining:
        return

    resident = db.query(Resident).filter(Resident.id == resident_id).first()
    if resident:
        resident.status = "safe"
