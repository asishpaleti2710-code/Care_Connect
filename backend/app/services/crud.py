from typing import Any, Type, TypeVar

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.database import Base

ModelT = TypeVar("ModelT", bound=Base)


def get_or_404(db: Session, model: Type[ModelT], record_id: int, label: str) -> ModelT:
    """Fetch a record by primary key or raise a 404 with a ``<label> not found`` detail."""
    record = db.query(model).filter(model.id == record_id).first()
    if not record:
        raise HTTPException(status_code=404, detail=f"{label} not found")
    return record


def save(db: Session, record: ModelT) -> ModelT:
    """Persist a new or modified record and return it refreshed from the database."""
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


def apply_updates(record: ModelT, updates: dict[str, Any], skip_none: bool = False) -> ModelT:
    """Assign ``updates`` onto ``record``, optionally ignoring ``None`` values."""
    for field, value in updates.items():
        if skip_none and value is None:
            continue
        setattr(record, field, value)
    return record
