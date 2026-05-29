import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/models.dart';

class LocalDatabase {
  Database? _db;

  static Future<LocalDatabase> open() async {
    final instance = LocalDatabase();
    await instance._init();
    return instance;
  }

  Future<void> _init() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'messenger_local.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE conversations (
            id INTEGER PRIMARY KEY,
            peer_id INTEGER NOT NULL,
            peer_username TEXT NOT NULL,
            peer_display_name TEXT NOT NULL,
            last_preview TEXT,
            last_sent_at TEXT,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE messages (
            id INTEGER PRIMARY KEY,
            conversation_id INTEGER NOT NULL,
            sender_id INTEGER NOT NULL,
            sender_display_name TEXT NOT NULL,
            text TEXT NOT NULL,
            status TEXT NOT NULL,
            sent_at TEXT NOT NULL,
            status_updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE meta (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_messages_conv ON messages(conversation_id, sent_at)',
        );
      },
    );
  }

  Database get db {
    final database = _db;
    if (database == null) throw StateError('Database not initialized');
    return database;
  }

  Future<String?> getMeta(String key) async {
    final rows = await db.query('meta', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setMeta(String key, String value) async {
    await db.insert(
      'meta',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertConversation(Conversation conv) async {
    final last = conv.lastMessage;
    await db.insert(
      'conversations',
      {
        'id': conv.id,
        'peer_id': conv.peer.id,
        'peer_username': conv.peer.username,
        'peer_display_name': conv.peer.displayName,
        'last_preview': last?.text,
        'last_sent_at': last?.sentAt.toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Conversation>> getConversations() async {
    final rows = await db.query(
      'conversations',
      orderBy: 'CASE WHEN last_sent_at IS NULL THEN 1 ELSE 0 END, last_sent_at DESC',
    );
    return rows.map((row) {
      Message? lastMessage;
      if (row['last_preview'] != null && row['last_sent_at'] != null) {
        lastMessage = Message(
          id: 0,
          conversationId: row['id'] as int,
          senderId: 0,
          senderDisplayName: '',
          text: row['last_preview'] as String,
          status: MessageStatus.delivered,
          sentAt: DateTime.parse(row['last_sent_at'] as String),
          statusUpdatedAt: DateTime.parse(row['last_sent_at'] as String),
        );
      }
      return Conversation(
        id: row['id'] as int,
        peer: UserPublic(
          id: row['peer_id'] as int,
          username: row['peer_username'] as String,
          displayName: row['peer_display_name'] as String,
        ),
        lastMessage: lastMessage,
      );
    }).toList();
  }

  Future<void> upsertMessage(Message message) async {
    await db.insert(
      'messages',
      {
        'id': message.id,
        'conversation_id': message.conversationId,
        'sender_id': message.senderId,
        'sender_display_name': message.senderDisplayName,
        'text': message.text,
        'status': messageStatusToString(message.status),
        'sent_at': message.sentAt.toIso8601String(),
        'status_updated_at': message.statusUpdatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _touchConversationPreview(message);
  }

  Future<void> _touchConversationPreview(Message message) async {
    final convRows = await db.query(
      'conversations',
      where: 'id = ?',
      whereArgs: [message.conversationId],
    );
    if (convRows.isEmpty) return;
    await db.update(
      'conversations',
      {
        'last_preview': message.text,
        'last_sent_at': message.sentAt.toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [message.conversationId],
    );
  }

  Future<void> updateMessageStatus(
    int messageId,
    MessageStatus status,
    DateTime statusUpdatedAt,
  ) async {
    await db.update(
      'messages',
      {
        'status': messageStatusToString(status),
        'status_updated_at': statusUpdatedAt.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<List<Message>> getMessages(int conversationId) async {
    final rows = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'sent_at ASC',
    );
    return rows.map(_messageFromRow).toList();
  }

  Message _messageFromRow(Map<String, Object?> row) => Message(
        id: row['id'] as int,
        conversationId: row['conversation_id'] as int,
        senderId: row['sender_id'] as int,
        senderDisplayName: row['sender_display_name'] as String,
        text: row['text'] as String,
        status: messageStatusFromString(row['status'] as String),
        sentAt: DateTime.parse(row['sent_at'] as String),
        statusUpdatedAt: DateTime.parse(row['status_updated_at'] as String),
      );

  Future<void> ensureConversationFromMessage(Message message, UserPublic peer) async {
    final exists = await db.query(
      'conversations',
      where: 'id = ?',
      whereArgs: [message.conversationId],
    );
    if (exists.isNotEmpty) return;
    await upsertConversation(
      Conversation(id: message.conversationId, peer: peer, lastMessage: message),
    );
  }
}
