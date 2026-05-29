from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_user
from app.models import Conversation, Message, MessageStatus, User, utcnow
from app.schemas import (
    ConversationOut,
    MessageOut,
    SendMessageRequest,
    StatusUpdateEvent,
    SyncResponse,
    UserPublic,
)
from app.services import (
    conversation_participant_ids,
    get_or_create_conversation,
    mark_delivered_for_recipient,
    mark_read_in_conversation,
    message_to_out,
    sync_messages_for_user,
    user_in_conversation,
)
from app.ws_manager import manager

router = APIRouter(tags=["messages"])


def _peer_for(conv: Conversation, user_id: int, db: Session) -> UserPublic:
    a_id, b_id = conversation_participant_ids(conv)
    peer_id = b_id if user_id == a_id else a_id
    peer = db.get(User, peer_id)
    if not peer:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Peer not found")
    return UserPublic.model_validate(peer)


@router.get("/conversations", response_model=list[ConversationOut])
def list_conversations(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[ConversationOut]:
    convs = (
        db.query(Conversation)
        .filter(
            or_(Conversation.user_a_id == current_user.id, Conversation.user_b_id == current_user.id)
        )
        .all()
    )
    result: list[ConversationOut] = []
    for conv in convs:
        last = (
            db.query(Message)
            .filter(Message.conversation_id == conv.id)
            .order_by(Message.sent_at.desc())
            .first()
        )
        result.append(
            ConversationOut(
                id=conv.id,
                peer=_peer_for(conv, current_user.id, db),
                last_message=message_to_out(db, last) if last else None,
            )
        )
    result.sort(
        key=lambda c: c.last_message.sent_at
        if c.last_message
        else datetime.min.replace(tzinfo=timezone.utc),
        reverse=True,
    )
    return result


@router.get("/conversations/{conversation_id}/messages", response_model=list[MessageOut])
def get_messages(
    conversation_id: int,
    before_id: int | None = None,
    limit: int = Query(default=50, ge=1, le=200),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[MessageOut]:
    conv = db.get(Conversation, conversation_id)
    if not conv or not user_in_conversation(conv, current_user.id):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Conversation not found")
    q = db.query(Message).filter(Message.conversation_id == conversation_id)
    if before_id is not None:
        q = q.filter(Message.id < before_id)
    messages = q.order_by(Message.id.desc()).limit(limit).all()
    messages.reverse()
    return [message_to_out(db, m) for m in messages]


@router.post("/messages", response_model=MessageOut, status_code=status.HTTP_201_CREATED)
async def send_message(
    body: SendMessageRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> MessageOut:
    if body.recipient_id == current_user.id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Cannot message yourself")
    peer = db.get(User, body.recipient_id)
    if not peer:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Recipient not found")

    conv = get_or_create_conversation(db, current_user.id, body.recipient_id)
    initial_status = MessageStatus.DELIVERED if manager.is_online(body.recipient_id) else MessageStatus.NOT_DELIVERED
    msg = Message(
        conversation_id=conv.id,
        sender_id=current_user.id,
        text=body.text,
        status=initial_status,
        sent_at=utcnow(),
        status_updated_at=utcnow(),
    )
    db.add(msg)
    db.commit()
    db.refresh(msg)
    out = message_to_out(db, msg)

    await manager.send_to_user(
        body.recipient_id,
        {"type": "new_message", "message": out.model_dump(mode="json")},
    )
    if initial_status == MessageStatus.DELIVERED:
        await manager.send_to_user(
            current_user.id,
            {
                "type": "message_status",
                "message_id": msg.id,
                "conversation_id": conv.id,
                "status": MessageStatus.DELIVERED.value,
                "status_updated_at": msg.status_updated_at.isoformat(),
            },
        )
    return out


@router.post("/conversations/{conversation_id}/read", response_model=list[MessageOut])
async def mark_conversation_read(
    conversation_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[MessageOut]:
    conv = db.get(Conversation, conversation_id)
    if not conv or not user_in_conversation(conv, current_user.id):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Conversation not found")
    updated = mark_read_in_conversation(db, conversation_id, current_user.id)
    result = [message_to_out(db, m) for m in updated]
    for msg in updated:
        event = StatusUpdateEvent(
            message_id=msg.id,
            conversation_id=conversation_id,
            status=MessageStatus.READ,
            status_updated_at=msg.status_updated_at,
        )
        await manager.send_to_user(msg.sender_id, {**event.model_dump(), "type": "message_status"})
    return result


@router.get("/sync", response_model=SyncResponse)
def sync_history(
    updated_since: datetime | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> SyncResponse:
    """Инкрементальная синхронизация для локального хранилища на устройстве."""
    messages = sync_messages_for_user(db, current_user.id, updated_since)
    return SyncResponse(
        server_time=utcnow(),
        messages=[message_to_out(db, m) for m in messages],
    )
