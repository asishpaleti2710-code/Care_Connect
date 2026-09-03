import json
import logging
from typing import Dict, List, Set, Any
from fastapi import WebSocket, WebSocketDisconnect

logger = logging.getLogger("careconnect.realtime")

class RealtimeConnectionManager:
    """
    CareConnect Real-Time WebSocket Hub.
    Manages live WebSocket channels for:
    - SOS alerts and life-cycle updates (/ws/sos)
    - Responder & resident live GPS telemetry (/ws/tracking)
    - Real-time notification updates (/ws/notifications)
    """

    def __init__(self):
        self.active_sos_connections: Set[WebSocket] = set()
        self.active_tracking_connections: Set[WebSocket] = set()
        self.active_notification_connections: Set[WebSocket] = set()
        self.user_connections: Dict[int, Set[WebSocket]] = {}

    async def connect_sos(self, websocket: WebSocket):
        await websocket.accept()
        self.active_sos_connections.add(websocket)
        logger.info(f"SOS WebSocket connected. Total active: {len(self.active_sos_connections)}")

    def disconnect_sos(self, websocket: WebSocket):
        self.active_sos_connections.discard(websocket)
        logger.info(f"SOS WebSocket disconnected. Total active: {len(self.active_sos_connections)}")

    async def broadcast_sos(self, data: Dict[str, Any]):
        message = json.dumps(data)
        stale = set()
        for ws in self.active_sos_connections:
            try:
                await ws.send_text(message)
            except Exception:
                stale.add(ws)
        for ws in stale:
            self.active_sos_connections.discard(ws)

    async def connect_tracking(self, websocket: WebSocket):
        await websocket.accept()
        self.active_tracking_connections.add(websocket)

    def disconnect_tracking(self, websocket: WebSocket):
        self.active_tracking_connections.discard(websocket)

    async def broadcast_tracking(self, data: Dict[str, Any]):
        message = json.dumps(data)
        stale = set()
        for ws in self.active_tracking_connections:
            try:
                await ws.send_text(message)
            except Exception:
                stale.add(ws)
        for ws in stale:
            self.active_tracking_connections.discard(ws)

    async def connect_notifications(self, websocket: WebSocket, user_id: int = None):
        await websocket.accept()
        self.active_notification_connections.add(websocket)
        if user_id:
            if user_id not in self.user_connections:
                self.user_connections[user_id] = set()
            self.user_connections[user_id].add(websocket)

    def disconnect_notifications(self, websocket: WebSocket, user_id: int = None):
        self.active_notification_connections.discard(websocket)
        if user_id and user_id in self.user_connections:
            self.user_connections[user_id].discard(websocket)
            if not self.user_connections[user_id]:
                del self.user_connections[user_id]

    async def broadcast_notification(self, data: Dict[str, Any], user_id: int = None):
        message = json.dumps(data)
        if user_id and user_id in self.user_connections:
            stale = set()
            for ws in self.user_connections[user_id]:
                try:
                    await ws.send_text(message)
                except Exception:
                    stale.add(ws)
            for ws in stale:
                self.user_connections[user_id].discard(ws)
        else:
            stale = set()
            for ws in self.active_notification_connections:
                try:
                    await ws.send_text(message)
                except Exception:
                    stale.add(ws)
            for ws in stale:
                self.active_notification_connections.discard(ws)

realtime_hub = RealtimeConnectionManager()
