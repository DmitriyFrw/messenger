import json

from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from sqlalchemy.orm import Session

from app.auth import decode_user_id
from app.database import SessionLocal
from app.models import Conversation, Message, MessageStatus
from app.services import mark_delivered_for_recipient, mark_read_in_conversation, message_to_out
from app.ws_manager import manager

router = APIRouter()


@router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket) -> None:
    token = websocket.query_params.get("token")
    if not token:
        await websocket.close(code=4401)
        return
    user_id = decode_user_id(token)
    if user_id is None:
        await websocket.close(code=4401)
        return

    await manager.connect(user_id, websocket)
    db: Session = SessionLocal()
    try:
        pending = (
            db.query(Message)
            .join(Conversation)
            .filter(
                Message.sender_id != user_id,
                Message.status == MessageStatus.NOT_DELIVERED,
                (Conversation.user_a_id == user_id) | (Conversation.user_b_id == user_id),
            )
            .all()
        )
        for msg in pending:
            updated = mark_delivered_for_recipient(db, msg, user_id)
            if updated:
                out = message_to_out(db, updated)
                await manager.send_to_user(
                    updated.sender_id,
                    {
                        "type": "message_status",
                        "message_id": updated.id,
                        "conversation_id": updated.conversation_id,
                        "status": MessageStatus.DELIVERED.value,
                        "status_updated_at": updated.status_updated_at.isoformat(),
                    },
                )
                await websocket.send_text(
                    json.dumps(
                        {"type": "new_message", "message": out.model_dump(mode="json")},
                        default=str,
                    )
                )

        while True:
            raw = await websocket.receive_text()
            try:
                data = json.loads(raw)
            except json.JSONDecodeError:
                continue
            action = data.get("action")
            if action == "ping":
                await websocket.send_text(json.dumps({"type": "pong"}))
            elif action == "read" and (conversation_id := data.get("conversation_id")):
                conv = db.get(Conversation, int(conversation_id))
                if conv and user_id in (conv.user_a_id, conv.user_b_id):
                    updated = mark_read_in_conversation(db, conv.id, user_id)
                    for msg in updated:
                        await manager.send_to_user(
                            msg.sender_id,
                            {
                                "type": "message_status",
                                "message_id": msg.id,
                                "conversation_id": conv.id,
                                "status": MessageStatus.READ.value,
                                "status_updated_at": msg.status_updated_at.isoformat(),
                            },
                        )
    except WebSocketDisconnect:
        pass
    finally:
        db.close()
        await manager.disconnect(user_id, websocket)
