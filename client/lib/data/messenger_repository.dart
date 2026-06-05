import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'api_client.dart';
import 'local_database.dart';
import 'ws_client.dart';

const _keyToken = 'auth_token';
const _keyUser = 'auth_user';
const _metaLastSync = 'last_sync_at';

class MessengerRepository {
  MessengerRepository._({
    required this.api,
    required this.db,
    required this.ws,
  });

  final ApiClient api;
  final LocalDatabase db;
  final WsClient ws;

  AuthSession? session;
  final List<void Function()> _listeners = [];

  bool get wsConnected => ws.connected;

  void addListener(void Function() listener) => _listeners.add(listener);
  void removeListener(void Function() listener) => _listeners.remove(listener);
  void notify() {
    for (final l in List<void Function()>.from(_listeners)) {
      l();
    }
  }

  static Future<MessengerRepository> create() async {
    final db = await LocalDatabase.open();
    final api = await ApiClient.create();
    final ws = WsClient();
    final repo = MessengerRepository._(api: api, db: db, ws: ws);
    ws.onEvent = repo._handleWsEvent;
    ws.onConnectionChanged = (connected) {
      repo.notify();
    };
    await repo.restoreSession();
    return repo;
  }

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    final userJson = prefs.getString(_keyUser);
    if (token == null || userJson == null) return;
    api.setToken(token);
    session = AuthSession(
      token: token,
      user: UserPublic.fromJson(
        jsonDecode(userJson) as Map<String, dynamic>,
      ),
    );
    await ws.connect(token);
    await refreshAll();
  }

  Future<void> _persistSession(AuthSession auth) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, auth.token);
    await prefs.setString(_keyUser, jsonEncode(auth.user.toJson()));
    session = auth;
    api.setToken(auth.token);
    await ws.connect(auth.token);
  }

  Future<AuthSession> login(String username, String password) async {
    final auth = await api.login(username: username, password: password);
    await _persistSession(auth);
    await refreshAll();
    notify();
    return auth;
  }

  Future<AuthSession> register({
    required String username,
    required String password,
    required String displayName,
  }) async {
    final auth = await api.register(
      username: username,
      password: password,
      displayName: displayName,
    );
    await _persistSession(auth);
    await refreshAll();
    notify();
    return auth;
  }

  Future<void> logout() async {
    await ws.disconnect();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
    session = null;
    api.setToken(null);
    notify();
  }

  Future<void> updateBaseUrl(String url) async {
    api.setBaseUrl(url);
    final token = session?.token;
    if (token != null) {
      await ws.disconnect();
      await ws.connect(token);
    }
    notify();
  }

  Future<UserPublic> updateDisplayName(String name) async {
    final user = await api.updateDisplayName(name);
    if (session != null) {
      session = AuthSession(token: session!.token, user: user);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUser, jsonEncode(user.toJson()));
    }
    notify();
    return user;
  }

  Future<List<Conversation>> getLocalConversations() => db.getConversations();

  Future<List<Message>> getLocalMessages(int conversationId) =>
      db.getMessages(conversationId);

  Future<void> refreshAll() async {
    final convs = await api.fetchConversations();
    for (final c in convs) {
      await db.upsertConversation(c);
      final messages = await api.fetchMessages(c.id);
      for (final m in messages) {
        await db.upsertMessage(m);
      }
    }
    await _runSync();
    notify();
  }

  Future<void> _runSync() async {
    final lastSyncStr = await db.getMeta(_metaLastSync);
    final since =
        lastSyncStr != null ? DateTime.parse(lastSyncStr).toUtc() : null;
    final messages = await api.sync(updatedSince: since);
    for (final m in messages) {
      await db.upsertMessage(m);
    }
    await db.setMeta(_metaLastSync, DateTime.now().toUtc().toIso8601String());
  }

  Future<Message> sendMessage({
    required int recipientId,
    required String text,
  }) async {
    final message = await api.sendMessage(recipientId: recipientId, text: text);
    await db.upsertMessage(message);
    if (session != null) {
      final peer = await _peerForConversation(message.conversationId);
      if (peer != null) {
        await db.upsertConversation(
          Conversation(id: message.conversationId, peer: peer, lastMessage: message),
        );
      }
    }
    notify();
    return message;
  }

  Future<void> markChatRead(int conversationId) async {
    if (conversationId < 0) return;
    await api.markConversationRead(conversationId);
    ws.markRead(conversationId);
    final messages = await db.getMessages(conversationId);
    final now = DateTime.now().toUtc();
    for (final m in messages) {
      if (m.senderId != session?.user.id &&
          m.status != MessageStatus.read) {
        await db.updateMessageStatus(m.id, MessageStatus.read, now);
      }
    }
    notify();
  }

  Future<UserPublic?> _peerForConversation(int conversationId) async {
    final convs = await db.getConversations();
    for (final c in convs) {
      if (c.id == conversationId) return c.peer;
    }
    return null;
  }

  void _handleWsEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;
    if (type == 'new_message') {
      final msg = Message.fromJson(
        event['message'] as Map<String, dynamic>,
      );
      _applyIncomingMessage(msg);
    } else if (type == 'message_status') {
      final messageId = event['message_id'] as int;
      final status = messageStatusFromString(event['status'] as String);
      final updated = DateTime.parse(event['status_updated_at'] as String);
      db.updateMessageStatus(messageId, status, updated);
      notify();
    }
  }

  Future<void> _applyIncomingMessage(Message msg) async {
    await db.upsertMessage(msg);
    if (session != null && msg.senderId != session!.user.id) {
      final peer = UserPublic(
        id: msg.senderId,
        username: '',
        displayName: msg.senderDisplayName,
      );
      await db.ensureConversationFromMessage(msg, peer);
      final convs = await api.fetchConversations();
      for (final c in convs) {
        if (c.id == msg.conversationId) {
          await db.upsertConversation(c);
          break;
        }
      }
    }
    notify();
  }
}
