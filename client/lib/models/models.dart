enum MessageStatus { notDelivered, delivered, read }

MessageStatus messageStatusFromString(String value) {
  switch (value) {
    case 'delivered':
      return MessageStatus.delivered;
    case 'read':
      return MessageStatus.read;
    default:
      return MessageStatus.notDelivered;
  }
}

String messageStatusToString(MessageStatus status) {
  switch (status) {
    case MessageStatus.delivered:
      return 'delivered';
    case MessageStatus.read:
      return 'read';
    case MessageStatus.notDelivered:
      return 'not_delivered';
  }
}

class UserPublic {
  const UserPublic({
    required this.id,
    required this.username,
    required this.displayName,
  });

  final int id;
  final String username;
  final String displayName;

  factory UserPublic.fromJson(Map<String, dynamic> json) => UserPublic(
        id: json['id'] as int,
        username: json['username'] as String,
        displayName: json['display_name'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'display_name': displayName,
      };
}

class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderDisplayName,
    required this.text,
    required this.status,
    required this.sentAt,
    required this.statusUpdatedAt,
  });

  final int id;
  final int conversationId;
  final int senderId;
  final String senderDisplayName;
  final String text;
  final MessageStatus status;
  final DateTime sentAt;
  final DateTime statusUpdatedAt;

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as int,
        conversationId: json['conversation_id'] as int,
        senderId: json['sender_id'] as int,
        senderDisplayName: json['sender_display_name'] as String? ?? '',
        text: json['text'] as String,
        status: messageStatusFromString(json['status'] as String),
        sentAt: DateTime.parse(json['sent_at'] as String).toUtc(),
        statusUpdatedAt:
            DateTime.parse(json['status_updated_at'] as String).toUtc(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'sender_id': senderId,
        'sender_display_name': senderDisplayName,
        'text': text,
        'status': messageStatusToString(status),
        'sent_at': sentAt.toIso8601String(),
        'status_updated_at': statusUpdatedAt.toIso8601String(),
      };

  Message copyWith({
    MessageStatus? status,
    DateTime? statusUpdatedAt,
    int? id,
  }) =>
      Message(
        id: id ?? this.id,
        conversationId: conversationId,
        senderId: senderId,
        senderDisplayName: senderDisplayName,
        text: text,
        status: status ?? this.status,
        sentAt: sentAt,
        statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
      );
}

class Conversation {
  const Conversation({
    required this.id,
    required this.peer,
    this.lastMessage,
  });

  final int id;
  final UserPublic peer;
  final Message? lastMessage;

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'] as int,
        peer: UserPublic.fromJson(json['peer'] as Map<String, dynamic>),
        lastMessage: json['last_message'] != null
            ? Message.fromJson(json['last_message'] as Map<String, dynamic>)
            : null,
      );
}

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final UserPublic user;
}
