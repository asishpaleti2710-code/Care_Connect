from app.database import SessionLocal, engine, Base
from app.models.user import User, UserRole
from app.models.resident import Resident
from app.models.guardian import Guardian
from app.models.volunteer import Volunteer
from app.models.security import SecurityPerson
from app.models.incident import Incident
from app.models.sos import SOSAlert
from app.services.auth import hash_password
from datetime import datetime, timedelta

def seed_database(force: bool = False):
    db_check = SessionLocal()
    try:
        if not force and db_check.query(User).first() is not None:
            print("Database already contains data. Skipping seed.")
            return
    except Exception:
        pass
    finally:
        db_check.close()

    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    try:
        print("Seeding Portfolio CareConnect Database...")

        # 1. Create Users for all 5 Roles
        users = [
            User(
                email="admin@careconnect.org",
                hashed_password=hash_password("admin123"),
                full_name="Dr. Sarah Jenkins",
                role=UserRole.ADMIN.value
            ),
            User(
                email="ashish@careconnect.org",
                hashed_password=hash_password("resident123"),
                full_name="Ashish",
                role=UserRole.RESIDENT.value
            ),
            User(
                email="eleanor@careconnect.org",
                hashed_password=hash_password("resident123"),
                full_name="Eleanor Vance",
                role=UserRole.RESIDENT.value
            ),
            User(
                email="guardian@careconnect.org",
                hashed_password=hash_password("guard123"),
                full_name="Elena Rostova",
                role=UserRole.GUARDIAN.value
            ),
            User(
                email="volunteer@careconnect.org",
                hashed_password=hash_password("vol123"),
                full_name="Alex Rivera",
                role=UserRole.VOLUNTEER.value
            ),
            User(
                email="security@careconnect.org",
                hashed_password=hash_password("sec123"),
                full_name="Officer Marcus Vance",
                role=UserRole.SECURITY.value
            ),
            User(
                email="caregiver@careconnect.org",
                hashed_password=hash_password("care123"),
                full_name="Nurse David Miller",
                role=UserRole.CAREGIVER.value
            ),
            User(
                email="neighbor@careconnect.org",
                hashed_password=hash_password("neighbor123"),
                full_name="Priya Sharma (Neighbor #304)",
                role=UserRole.NEIGHBOUR.value
            )
        ]
        db.add_all(users)
        db.commit()

        # Refresh users map by email
        user_map = {u.email: u.id for u in db.query(User).all()}

        # 2. Create Volunteers & Security profiles
        vol = Volunteer(
            user_id=user_map["volunteer@careconnect.org"],
            phone="+1-555-0191",
            availability_status="available",
            skills="First Aid Certified, Basic Life Support"
        )
        sec = SecurityPerson(
            user_id=user_map["security@careconnect.org"],
            badge_number="SEC-9042",
            assigned_zone="Block A & Central Courtyard",
            phone="+1-555-0199"
        )
        db.add(vol)
        db.add(sec)
        db.commit()

        # 3. Create Residents
        residents = [
            Resident(
                user_id=user_map["ashish@careconnect.org"],
                full_name="Ashish",
                age=22,
                blood_group="O+",
                room_number="302-A",
                address="Flat A-302, Senior Living Tower",
                medical_notes="Allergic to penicillin. Requires periodic asthma check.",
                emergency_contact="+1-555-0101",
                status="emergency"
            ),
            Resident(
                user_id=user_map["eleanor@careconnect.org"],
                full_name="Eleanor Vance",
                age=78,
                blood_group="A+",
                room_number="102-A",
                address="Building B, Room 102-A",
                medical_notes="Hypertension, daily blood pressure check required.",
                emergency_contact="+1-555-0192",
                status="safe"
            ),
            Resident(
                full_name="Arthur Pendelton",
                age=84,
                blood_group="B-",
                room_number="105-B",
                address="Building B, Room 105-B",
                medical_notes="Type 2 Diabetes, pacemaker. High fall risk.",
                emergency_contact="+1-555-0144",
                status="alert"
            ),
            Resident(
                full_name="Clara Oswald",
                age=79,
                blood_group="O-",
                room_number="204-C",
                address="Building C, Room 204-C",
                medical_notes="Mild cognitive impairment. Requires mobility assistance.",
                emergency_contact="+1-555-0155",
                status="safe"
            )
        ]
        db.add_all(residents)
        db.commit()

        for r in residents:
            db.refresh(r)
        res_map = {r.full_name: r.id for r in residents}

        # 4. Create Guardians
        guardians = [
            Guardian(
                resident_id=res_map["Ashish"],
                name="Father (Robert)",
                relationship="Father",
                phone="+1-555-0988",
                email="robert@gmail.com"
            ),
            Guardian(
                resident_id=res_map["Ashish"],
                name="Brother (Richard)",
                relationship="Brother",
                phone="+1-555-0989",
                email="richard@gmail.com"
            ),
            Guardian(
                resident_id=res_map["Eleanor Vance"],
                name="Elena Rostova",
                relationship="Daughter",
                phone="+1-555-0194",
                email="guardian@careconnect.org"
            )
        ]
        db.add_all(guardians)
        db.commit()

        # 5. Create Incidents
        incidents = [
            Incident(
                incident_code="INC-8091",
                resident_id=res_map["Ashish"],
                emergency_type="Medical Emergency",
                priority="Critical",
                description="Ashish pressed SOS panic button from Flat A-302. High heart rate reported.",
                location="Flat A-302, Senior Living Tower",
                status="Pending",
                created_at=datetime.utcnow() - timedelta(minutes=5)
            ),
            Incident(
                incident_code="INC-7042",
                resident_id=res_map["Arthur Pendelton"],
                emergency_type="Fall Incident",
                priority="High",
                description="Unscheduled fall detected near bedside.",
                location="Building B, Room 105-B",
                status="Accepted",
                responder_id=user_map["security@careconnect.org"],
                responder_name="Officer Marcus Vance",
                responder_role="security",
                created_at=datetime.utcnow() - timedelta(minutes=25),
                accepted_at=datetime.utcnow() - timedelta(minutes=20)
            ),
            Incident(
                incident_code="INC-6011",
                resident_id=res_map["Eleanor Vance"],
                emergency_type="Security Threat",
                priority="Moderate",
                description="Door sensor alert after visiting hours.",
                location="Building B, Room 102-A",
                status="Resolved",
                responder_id=user_map["volunteer@careconnect.org"],
                responder_name="Alex Rivera",
                responder_role="volunteer",
                created_at=datetime.utcnow() - timedelta(hours=3),
                accepted_at=datetime.utcnow() - timedelta(hours=2, minutes=50),
                resolved_at=datetime.utcnow() - timedelta(hours=2, minutes=30)
            )
        ]
        db.add_all(incidents)
        db.commit()

        # 6. Create SOS Alerts
        sos_alerts = [
            SOSAlert(
                resident_id=res_map["Ashish"],
                alert_type="Medical Emergency",
                message="SOS Panic button triggered in Flat A-302",
                status="active"
            )
        ]
        db.add_all(sos_alerts)
        db.commit()

        print("Database seeded with portfolio entities successfully!")

    except Exception as e:
        db.rollback()
        print(f"Error seeding portfolio database: {e}")
        raise e
    finally:
        db.close()

if __name__ == "__main__":
    seed_database()
