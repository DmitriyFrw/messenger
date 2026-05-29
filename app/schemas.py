from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field

from app.models import MessageStatus


class UserPublic(BaseModel):
    id: int
    username: str
    display_name: str

    model_config = {"from_attributes": True}


class RegisterRequest(BaseModel):
    username: str = Field(min_length=3, max_length=64, pattern=r"^[a-zA-Z0-9_]+$")
    password: str = Field(min_length=6, max_length=128)
    display_name: str = Field(min_length=1, max_length=128)


class LoginRequest(BaseModel):
    username: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: Literal["bearer"] = "bearer"
    user: UserPublic


class UpdateDisplayNameRequest(BaseModel):
    display_name: str = Field(min_length=1, max_length=128)


class MessageOut(BaseModel):
    id: int
    conversation_id: int
    sender_id: int
    sender_display_name: str
    text: str
    status: MessageStatus
    sent_at: datetime
    status_updated_at: datetime

    model_config = {"from_attributes": True}


class SendMessageRequest(BaseModel):
    recipient_id: int
    text: str = Field(min_length=1, max_length=10000)


class ConversationOut(BaseModel):
    id: int
    peer: UserPublic
    last_message: MessageOut | None = None

    model_config = {"from_attributes": True}


class SyncResponse(BaseModel):
    """Ответ для синхронизации локальной истории на устройстве."""

    server_time: datetime
    messages: list[MessageOut]
    deleted_message_ids: list[int] = []


class StatusUpdateEvent(BaseModel):
    type: Literal["message_status"] = "message_status"
    message_id: int
    conversation_id: int
    status: MessageStatus
    status_updated_at: datetime


class NewMessageEvent(BaseModel):
    type: Literal["new_message"] = "new_message"
    message: MessageOut
