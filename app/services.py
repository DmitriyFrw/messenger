from datetime import datetime, timezone

from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.models import Conversation, Message, MessageStatus, User, utcnow
from app.schemas import MessageOut


def normalize_pair(user_id: int, peer_id: int) -> tuple[int, int]:
    return (user_id, peer_id) if user_id < peer_id else (peer_id, user_id)


def get_or_create_conversation(db: Session, user_id: int, peer_id: int) -> Conversation:
    a_id, b_id = normalize_pair(user_id, peer_id)
    conv = (
        db.query(Conversation)
        .filter(Conversation.user_a_id == a_id, Conversation.user_b_id == b_id)
        .first()
    )
    if conv:
        return conv
    conv = Conversation(user_a_id=a_id, user_b_id=b_id)
    db.add(conv)
    db.flush()
    return conv


def conversation_participant_ids(conv: Conversation) -> tuple[int, int]:
    return conv.user_a_id, conv.user_b_id


def user_in_conversation(conv: Conversation, user_id: int) -> bool:
    return user_id in conversation_participant_ids(conv)


def message_to_out(db: Session, msg: Message) -> MessageOut:
    sender = db.get(User, msg.sender_id)
    return MessageOut(
        id=msg.id,
        conversation_id=msg.conversation_id,
        sender_id=msg.sender_id,
        sender_display_name=sender.display_name if sender else "",
        text=msg.text,
        status=msg.status,
        sent_at=msg.sent_at,
        status_updated_at=msg.status_updated_at,
    )


def mark_delivered_for_recipient(db: Session, message: Message, recipient_id: int) -> Message | None:
    if message.sender_id == recipient_id:
        return None
    if message.status == MessageStatus.READ:
        return None
    if message.status == MessageStatus.DELIVERED:
        return None
    message.status = MessageStatus.DELIVERED
    message.status_updated_at = utcnow()
    db.commit()
    db.refresh(message)
    return message


def mark_read_in_conversation(db: Session, conversation_id: int, reader_id: int) -> list[Message]:
    updated: list[Message] = []
    messages = (
        db.query(Message)
        .filter(
            Message.conversation_id == conversation_id,
            Message.sender_id != reader_id,
            Message.status != MessageStatus.READ,
        )
        .all()
    )
    now = utcnow()
    for msg in messages:
        msg.status = MessageStatus.READ
        msg.status_updated_at = now
        updated.append(msg)
    if updated:
        db.commit()
        for msg in updated:
            db.refresh(msg)
    return updated


def sync_messages_for_user(db: Session, user_id: int, since: datetime | None) -> list[Message]:
    q = (
        db.query(Message)
        .join(Conversation)
        .filter(or_(Conversation.user_a_id == user_id, Conversation.user_b_id == user_id))
        .order_by(Message.sent_at.asc())
    )
    if since is not None:
        if since.tzinfo is None:
            since = since.replace(tzinfo=timezone.utc)
        q = q.filter(Message.status_updated_at > since)
    return q.all()
