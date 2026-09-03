from sqlalchemy import inspect, text
from app.database import engine

def run_safe_schema_migrations():
    """
    Safely adds any missing columns to existing SQLite/MySQL/PostgreSQL tables
    without dropping existing data or schemas.
    """
    inspector = inspect(engine)
    existing_tables = inspector.get_table_names()

    # 1. SOS Alerts Table Migrations
    if "sos_alerts" in existing_tables:
        existing_cols = [c["name"] for c in inspector.get_columns("sos_alerts")]
        new_cols = [
            ("user_id", "INTEGER"),
            ("category", "VARCHAR(255)"),
            ("latitude", "FLOAT"),
            ("longitude", "FLOAT"),
            ("maps_url", "VARCHAR(512)"),
            ("priority", "VARCHAR(64)"),
            ("activated_at", "DATETIME"),
            ("acknowledged_at", "DATETIME"),
            ("responding_at", "DATETIME"),
            ("cancelled_at", "DATETIME"),
            ("responder_id", "INTEGER"),
            ("responder_name", "VARCHAR(255)"),
            ("responder_role", "VARCHAR(64)"),
            ("response_notes", "TEXT"),
        ]

        with engine.begin() as conn:
            for col_name, col_type in new_cols:
                if col_name not in existing_cols:
                    try:
                        conn.execute(text(f"ALTER TABLE sos_alerts ADD COLUMN {col_name} {col_type}"))
                    except Exception as e:
                        print(f"[Migration Note] sos_alerts.{col_name}: {e}")

    # 2. Notifications Table Migrations
    if "notifications" in existing_tables:
        existing_cols = [c["name"] for c in inspector.get_columns("notifications")]
        new_cols = [
            ("recipient_role", "VARCHAR(64)"),
            ("recipient_name", "VARCHAR(255)"),
            ("recipient_contact", "VARCHAR(255)"),
            ("channel", "VARCHAR(64)"),
            ("status", "VARCHAR(64)"),
            ("sent_at", "DATETIME"),
            ("delivered_at", "DATETIME"),
            ("read_at", "DATETIME"),
            ("failure_reason", "TEXT"),
        ]

        with engine.begin() as conn:
            for col_name, col_type in new_cols:
                if col_name not in existing_cols:
                    try:
                        conn.execute(text(f"ALTER TABLE notifications ADD COLUMN {col_name} {col_type}"))
                    except Exception as e:
                        print(f"[Migration Note] notifications.{col_name}: {e}")
