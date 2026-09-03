import os
import smtplib
import logging
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime
from typing import Optional, Dict, Any, List
import httpx

logger = logging.getLogger("careconnect.email")

class EmailService:
    """
    CareConnect Enterprise Email Notification Service.
    Supports SMTP, SendGrid, and Resend with branded responsive HTML emergency templates.
    """

    def __init__(self):
        self._reload_config()

    def _reload_config(self):
        self.smtp_host = os.getenv("SMTP_HOST")
        self.smtp_port = int(os.getenv("SMTP_PORT", "587"))
        self.smtp_user = os.getenv("SMTP_USERNAME") or os.getenv("SMTP_USER")
        self.smtp_password = os.getenv("SMTP_PASSWORD") or os.getenv("SMTP_PASS")
        self.smtp_from_email = (
            os.getenv("SENDER_EMAIL")
            or os.getenv("SMTP_FROM_EMAIL")
            or "emergency-alerts@careconnect.org"
        )
        self.smtp_from_name = os.getenv("SMTP_FROM_NAME", "CareConnect Emergency Network")
        self.sendgrid_api_key = os.getenv("SENDGRID_API_KEY")
        self.resend_api_key = os.getenv("RESEND_API_KEY")

    @property
    def is_configured(self) -> bool:
        self._reload_config()
        return bool(
            self.sendgrid_api_key
            or self.resend_api_key
            or (self.smtp_host and self.smtp_user and self.smtp_password)
        )

    def get_config_summary(self) -> Dict[str, Any]:
        self._reload_config()
        return {
            "smtp_host": self.smtp_host,
            "smtp_port": self.smtp_port,
            "smtp_user": f"{self.smtp_user[:3]}***" if self.smtp_user else None,
            "has_password": bool(self.smtp_password),
            "from_email": self.smtp_from_email,
            "has_sendgrid": bool(self.sendgrid_api_key),
            "has_resend": bool(self.resend_api_key),
            "is_configured": self.is_configured
        }

    def _generate_sos_user_html(
        self,
        user_name: str,
        user_email: str,
        emergency_message: str,
        location: Optional[str] = None,
        maps_url: Optional[str] = None,
        timestamp_str: Optional[str] = None,
        category: str = "Medical Emergency"
    ) -> str:
        time_display = timestamp_str or datetime.utcnow().strftime("%B %d, %Y - %I:%M:%S %p UTC")
        location_display = location or "GPS Location Broadcasted"
        maps_button = (
            f"""<div style="text-align: center; margin-top: 24px;">
                  <a href="{maps_url}" style="display: inline-block; background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%); color: #ffffff; text-decoration: none; padding: 12px 24px; border-radius: 8px; font-weight: 700; font-size: 14px;" target="_blank">
                    📍 Open Live Emergency GPS Tracking
                  </a>
                </div>"""
            if maps_url and maps_url != "#"
            else ""
        )

        return f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SOS Alert Triggered</title>
<style>
  body {{ margin: 0; padding: 0; background-color: #0f172a; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; color: #f8fafc; }}
  .container {{ max-width: 600px; margin: 20px auto; background-color: #1e293b; border-radius: 14px; overflow: hidden; border: 1px solid rgba(255,255,255,0.1); box-shadow: 0 10px 30px rgba(0,0,0,0.5); }}
  .header {{ background: linear-gradient(135deg, #7f1d1d 0%, #991b1b 100%); padding: 24px; text-align: center; border-bottom: 1px solid rgba(255,255,255,0.1); }}
  .brand {{ font-size: 22px; font-weight: 800; color: #ffffff; letter-spacing: -0.5px; text-transform: uppercase; }}
  .content {{ padding: 28px; }}
  .badge {{ display: inline-block; background-color: #ef4444; color: #ffffff; padding: 6px 14px; border-radius: 20px; font-size: 12px; font-weight: 700; letter-spacing: 0.5px; margin-bottom: 18px; }}
  .title {{ font-size: 22px; font-weight: 800; margin-bottom: 12px; color: #ffffff; }}
  .info-box {{ background-color: rgba(15, 23, 42, 0.7); border-radius: 8px; border-left: 4px solid #ef4444; padding: 18px; margin: 18px 0; }}
  .info-row {{ display: flex; margin-bottom: 10px; font-size: 14px; line-height: 1.4; }}
  .info-label {{ font-weight: 600; color: #94a3b8; width: 140px; flex-shrink: 0; }}
  .info-value {{ color: #f8fafc; word-break: break-word; }}
  .footer {{ background-color: #0f172a; padding: 16px; text-align: center; font-size: 12px; color: #64748b; border-top: 1px solid rgba(255,255,255,0.05); }}
</style>
</head>
<body>
<div class="container">
  <div class="header">
    <div class="brand">🚨 CareConnect Emergency Alert</div>
  </div>
  <div class="content">
    <span class="badge">SOS DISPATCH ACTIVATED</span>
    <h1 class="title">SOS Alert Triggered</h1>
    <p style="color: #cbd5e1; font-size: 15px; line-height: 1.5;">
      An emergency SOS alert was triggered from your CareConnect account. Responders and community guardians have been alerted.
    </p>
    
    <div class="info-box">
      <div class="info-row"><span class="info-label">User Name:</span><span class="info-value"><strong>{user_name}</strong></span></div>
      <div class="info-row"><span class="info-label">User Email:</span><span class="info-value">{user_email}</span></div>
      <div class="info-row"><span class="info-label">Time & Date:</span><span class="info-value">{time_display}</span></div>
      <div class="info-row"><span class="info-label">Emergency Category:</span><span class="info-value">{category}</span></div>
      <div class="info-row"><span class="info-label">Emergency Message:</span><span class="info-value"><strong>{emergency_message}</strong></span></div>
      <div class="info-row"><span class="info-label">Location:</span><span class="info-value">{location_display}</span></div>
    </div>

    {maps_button}

    <p style="font-size: 13px; color: #94a3b8; margin-top: 24px; text-align: center;">
      If this was triggered accidentally, open the CareConnect app and tap <strong>Cancel SOS</strong>.
    </p>
  </div>
  <div class="footer">
    CareConnect Safety & Emergency Response Network &bull; Automated System Dispatch
  </div>
</div>
</body>
</html>"""

    def send_sos_email_to_user(
        self,
        user_name: str,
        user_email: str,
        emergency_message: str,
        location: Optional[str] = None,
        maps_url: Optional[str] = None,
        timestamp_str: Optional[str] = None,
        category: str = "Medical Emergency"
    ) -> Dict[str, Any]:
        """
        Sends an immediate SOS notification email directly to the logged-in user.
        Subject: 'SOS Alert Triggered'
        """
        self._reload_config()
        subject = "SOS Alert Triggered"
        html_content = self._generate_sos_user_html(
            user_name=user_name,
            user_email=user_email,
            emergency_message=emergency_message,
            location=location,
            maps_url=maps_url,
            timestamp_str=timestamp_str,
            category=category
        )

        plain_text = (
            f"SOS Alert Triggered\n\n"
            f"User Name: {user_name}\n"
            f"User Email: {user_email}\n"
            f"Time & Date: {timestamp_str or datetime.utcnow().strftime('%B %d, %Y - %I:%M:%S %p UTC')}\n"
            f"Emergency Category: {category}\n"
            f"Emergency Message: {emergency_message}\n"
            f"Location: {location or 'Not provided'}\n"
            f"Maps Link: {maps_url or 'N/A'}\n"
        )

        logger.info(f"[EMAIL SOS TRIGGER] Dispatching '{subject}' to logged-in user: {user_email}")
        return self._dispatch_mail(
            recipient_email=user_email,
            recipient_name=user_name,
            subject=subject,
            plain_text=plain_text,
            html_content=html_content
        )

    def send_email(
        self,
        recipient_email: str,
        recipient_name: str,
        subject: str,
        event_type: str,
        message: str,
        metadata: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """General multi-tier notification email dispatch."""
        self._reload_config()
        meta = metadata or {}
        location = meta.get("location", "Care Facility")
        maps_url = meta.get("maps_url", "#")
        category = meta.get("category", "Emergency")

        html_content = self._generate_sos_user_html(
            user_name=recipient_name,
            user_email=recipient_email,
            emergency_message=message,
            location=location,
            maps_url=maps_url,
            category=category
        )

        return self._dispatch_mail(
            recipient_email=recipient_email,
            recipient_name=recipient_name,
            subject=subject,
            plain_text=message,
            html_content=html_content
        )

    def _dispatch_mail(
        self,
        recipient_email: str,
        recipient_name: str,
        subject: str,
        plain_text: str,
        html_content: str
    ) -> Dict[str, Any]:
        now = datetime.utcnow()

        # 1. Resend API
        if self.resend_api_key:
            try:
                logger.info(f"[EMAIL PROVIDER: RESEND] Sending to {recipient_email}...")
                resp = httpx.post(
                    "https://api.resend.com/emails",
                    headers={"Authorization": f"Bearer {self.resend_api_key}", "Content-Type": "application/json"},
                    json={
                        "from": f"{self.smtp_from_name} <{self.smtp_from_email}>",
                        "to": [recipient_email],
                        "subject": subject,
                        "html": html_content
                    },
                    timeout=10.0
                )
                if resp.status_code in [200, 201]:
                    logger.info(f"[EMAIL SUCCESS: RESEND] Delivered to {recipient_email}")
                    return {"success": True, "status": "DELIVERED", "provider": "resend", "delivered_at": now, "error": None}
                else:
                    logger.error(f"[EMAIL ERROR: RESEND] Status {resp.status_code}: {resp.text}")
            except Exception as e:
                logger.error(f"[EMAIL EXCEPTION: RESEND] {str(e)}")

        # 2. SendGrid API
        if self.sendgrid_api_key:
            try:
                logger.info(f"[EMAIL PROVIDER: SENDGRID] Sending to {recipient_email}...")
                resp = httpx.post(
                    "https://api.sendgrid.com/v3/mail/send",
                    headers={"Authorization": f"Bearer {self.sendgrid_api_key}", "Content-Type": "application/json"},
                    json={
                        "personalizations": [{"to": [{"email": recipient_email, "name": recipient_name}]}],
                        "from": {"email": self.smtp_from_email, "name": self.smtp_from_name},
                        "subject": subject,
                        "content": [{"type": "text/html", "value": html_content}]
                    },
                    timeout=10.0
                )
                if resp.status_code in [200, 201, 202]:
                    logger.info(f"[EMAIL SUCCESS: SENDGRID] Delivered to {recipient_email}")
                    return {"success": True, "status": "DELIVERED", "provider": "sendgrid", "delivered_at": now, "error": None}
                else:
                    logger.error(f"[EMAIL ERROR: SENDGRID] Status {resp.status_code}: {resp.text}")
            except Exception as e:
                logger.error(f"[EMAIL EXCEPTION: SENDGRID] {str(e)}")

        # 3. SMTP Server
        if self.smtp_host and self.smtp_user and self.smtp_password:
            try:
                logger.info(f"[EMAIL PROVIDER: SMTP] Connecting to {self.smtp_host}:{self.smtp_port} as '{self.smtp_user}'...")
                msg = MIMEMultipart("alternative")
                msg["Subject"] = subject
                msg["From"] = f"{self.smtp_from_name} <{self.smtp_from_email}>"
                msg["To"] = recipient_email
                msg.attach(MIMEText(plain_text, "plain"))
                msg.attach(MIMEText(html_content, "html"))

                # Support SSL (465) or STARTTLS (587/25)
                if self.smtp_port == 465:
                    with smtplib.SMTP_SSL(self.smtp_host, self.smtp_port, timeout=12) as server:
                        server.login(self.smtp_user, self.smtp_password)
                        server.send_message(msg)
                else:
                    with smtplib.SMTP(self.smtp_host, self.smtp_port, timeout=12) as server:
                        server.starttls()
                        server.login(self.smtp_user, self.smtp_password)
                        server.send_message(msg)

                logger.info(f"[EMAIL SUCCESS: SMTP] Successfully delivered '{subject}' to {recipient_email}")
                return {"success": True, "status": "DELIVERED", "provider": "smtp", "delivered_at": now, "error": None}
            except Exception as e:
                error_msg = f"SMTP Error ({self.smtp_host}:{self.smtp_port}): {type(e).__name__}: {str(e)}"
                logger.error(f"[EMAIL FAILED: SMTP] {error_msg}")
                return {
                    "success": False,
                    "status": "FAILED",
                    "error": error_msg,
                    "failure_reason": error_msg,
                    "provider": "smtp",
                    "timestamp": now
                }

        # 4. Fallback if not configured
        missing = []
        if not self.smtp_host: missing.append("SMTP_HOST")
        if not self.smtp_user: missing.append("SMTP_USERNAME")
        if not self.smtp_password: missing.append("SMTP_PASSWORD")
        warning_msg = f"Email delivery failed: Missing required SMTP credentials ({', '.join(missing)})."
        logger.warning(f"[EMAIL UNCONFIGURED] {warning_msg}")
        return {
            "success": False,
            "status": "NOT_CONFIGURED",
            "error": warning_msg,
            "failure_reason": warning_msg,
            "provider": "none",
            "timestamp": now
        }

email_service = EmailService()
