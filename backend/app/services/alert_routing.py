from typing import List, Optional
from sqlalchemy.orm import Session
from datetime import datetime

from app.models.sos import SOSAlert
from app.models.resident import Resident
from app.models.guardian import Guardian
from app.models.security import SecurityPerson
from app.models.volunteer import Volunteer
from app.models.user import User, UserRole
from app.models.notification import Notification
from app.services.notification_engine import notification_engine

def route_sos_alert(db: Session, sos: SOSAlert) -> List[Notification]:
    """
    Tiered, authorization-aware emergency notification router.
    Dispatches role-filtered alerts across Primary Guardians, Security Personnel,
    Certified Volunteers, and Community Responders.
    """
    dispatched_records = []
    resident = db.query(Resident).filter(Resident.id == sos.resident_id).first()
    resident_name = resident.full_name if resident else "Resident"
    room_number = resident.room_number if resident else "Unknown Room"
    address = resident.address if resident and resident.address else f"Room {room_number}"
    medical_notes = resident.medical_notes if resident and resident.medical_notes else "None listed"
    blood_group = resident.blood_group if resident and resident.blood_group else "N/A"
    maps_url = sos.maps_url or (
        f"https://www.google.com/maps?q={sos.latitude},{sos.longitude}"
        if sos.latitude and sos.longitude
        else "Location coordinates unavailable"
    )

    category = sos.category or sos.alert_type or "Medical Emergency"
    user_msg = sos.message or "SOS Emergency Dispatch Triggered"

    # =========================================================================
    # 1. PRIMARY GUARDIANS (Full emergency context + medical ID + GPS)
    # =========================================================================
    guardians = db.query(Guardian).filter(Guardian.resident_id == sos.resident_id).all()
    for guardian in guardians:
        # Find matching User record if registered
        guardian_user = db.query(User).filter(
            (User.email == guardian.email) | (User.role == UserRole.GUARDIAN.value)
        ).first()

        guardian_title = f"🚨 URGENT: SOS Alert for {resident_name}"
        guardian_msg = (
            f"EMERGENCY ALERT: {resident_name} triggered an SOS for '{category}'.\n"
            f"Details: {user_msg}\n"
            f"Location: {address} (Room {room_number})\n"
            f"Vitals/Medical Notes: Blood {blood_group} | Notes: {medical_notes}\n"
            f"Live GPS Maps: {maps_url}"
        )

        # A. In-App Notification
        dispatched_records.append(
            notification_engine.dispatch(
                db=db,
                sos_id=sos.id,
                user_id=guardian_user.id if guardian_user else None,
                recipient_role="guardian",
                recipient_name=guardian.name,
                recipient_contact=guardian.phone or guardian.email or "Guardian Contact",
                channel="IN_APP",
                title=guardian_title,
                message=guardian_msg
            )
        )

        # B. Push Notification
        dispatched_records.append(
            notification_engine.dispatch(
                db=db,
                sos_id=sos.id,
                user_id=guardian_user.id if guardian_user else None,
                recipient_role="guardian",
                recipient_name=guardian.name,
                recipient_contact=guardian.phone or guardian.email or "Guardian Device",
                channel="PUSH",
                title=guardian_title,
                message=f"SOS Alert: {resident_name} requires assistance at {address}."
            )
        )

        # C. SMS Notification
        if guardian.phone:
            dispatched_records.append(
                notification_engine.dispatch(
                    db=db,
                    sos_id=sos.id,
                    user_id=guardian_user.id if guardian_user else None,
                    recipient_role="guardian",
                    recipient_name=guardian.name,
                    recipient_contact=guardian.phone,
                    channel="SMS",
                    title="SOS Alert",
                    message=f"URGENT CareConnect SOS: {resident_name} reported '{category}' in {room_number}. Location: {maps_url}"
                )
            )

        # D. Email Notification
        if guardian.email:
            dispatched_records.append(
                notification_engine.dispatch(
                    db=db,
                    sos_id=sos.id,
                    user_id=guardian_user.id if guardian_user else None,
                    recipient_role="guardian",
                    recipient_name=guardian.name,
                    recipient_contact=guardian.email,
                    channel="EMAIL",
                    title=guardian_title,
                    message=guardian_msg
                )
            )

    # =========================================================================
    # 2. SECURITY PERSONNEL (Category + Room/Location + Time + Maps link)
    # =========================================================================
    security_users = db.query(User).filter(User.role == UserRole.SECURITY.value).all()
    for sec_user in security_users:
        sec_title = f"🛡️ SECURITY DISPATCH: SOS Alert #{sos.id}"
        sec_msg = (
            f"Security Dispatch: {category} reported at {address} (Room {room_number}).\n"
            f"Resident: {resident_name}\n"
            f"Message: {user_msg}\n"
            f"GPS Link: {maps_url}"
        )

        # A. In-App Notification
        dispatched_records.append(
            notification_engine.dispatch(
                db=db,
                sos_id=sos.id,
                user_id=sec_user.id,
                recipient_role="security",
                recipient_name=sec_user.full_name,
                recipient_contact=sec_user.email,
                channel="IN_APP",
                title=sec_title,
                message=sec_msg
            )
        )

        # B. Push Notification
        dispatched_records.append(
            notification_engine.dispatch(
                db=db,
                sos_id=sos.id,
                user_id=sec_user.id,
                recipient_role="security",
                recipient_name=sec_user.full_name,
                recipient_contact=sec_user.email,
                channel="PUSH",
                title=sec_title,
                message=f"Dispatch to Room {room_number} for {category}."
            )
        )

    # =========================================================================
    # 3. VOLUNTEERS (Minimum necessary response info + First aid guidance)
    # =========================================================================
    volunteers = db.query(User).filter(User.role == UserRole.VOLUNTEER.value).all()
    for vol_user in volunteers:
        vol_title = f"🤝 VOLUNTEER ASSISTANCE NEEDED: {category}"
        vol_msg = (
            f"Emergency Response Request: Resident in Room {room_number} needs assistance.\n"
            f"Category: {category}\n"
            f"Location: {address}\n"
            f"Please proceed if available and equipped for first response."
        )

        dispatched_records.append(
            notification_engine.dispatch(
                db=db,
                sos_id=sos.id,
                user_id=vol_user.id,
                recipient_role="volunteer",
                recipient_name=vol_user.full_name,
                recipient_contact=vol_user.email,
                channel="IN_APP",
                title=vol_title,
                message=vol_msg
            )
        )

    # =========================================================================
    # 4. COMMUNITY / NEIGHBORS (Non-sensitive building-wide broadcast)
    # =========================================================================
    community_users = db.query(User).filter(
        User.role.in_([UserRole.NEIGHBOUR.value, UserRole.ADMIN.value])
    ).all()
    for comm_user in community_users:
        comm_title = f"📢 Community Safety Notice: {category}"
        comm_msg = (
            f"Safety notice: An emergency incident ({category}) has been reported "
            f"in {address}. Responders are attending."
        )

        dispatched_records.append(
            notification_engine.dispatch(
                db=db,
                sos_id=sos.id,
                user_id=comm_user.id,
                recipient_role=comm_user.role,
                recipient_name=comm_user.full_name,
                recipient_contact=comm_user.email,
                channel="IN_APP",
                title=comm_title,
                message=comm_msg
            )
        )

    db.commit()
    return dispatched_records
