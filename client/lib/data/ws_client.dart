import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/api_config.dart';

typedef WsEventHandler = void Function(Map<String, dynamic> event);

class WsClient {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _pingTimer;
  String? _token;
  WsEventHandler? onEvent;
  void Function(bool connected)? onConnectionChanged;

  Future<void> connect(String token) async {
    await disconnect();
    _token = token;
    final baseUrl = await ApiConfig.loadBaseUrl();
    final wsBase = ApiConfig.httpToWs(baseUrl);
    final uri = Uri.parse('$wsBase/ws?token=${Uri.encodeComponent(token)}');
    _channel = WebSocketChannel.connect(uri);
    onConnectionChanged?.call(true);
    _subscription = _channel!.stream.listen(
      (data) {
        try {
          final map = jsonDecode(data as String) as Map<String, dynamic>;
          onEvent?.call(map);
        } catch (_) {}
      },
      onError: (_) => _scheduleReconnect(),
      onDone: () {
        onConnectionChanged?.call(false);
        _scheduleReconnect();
      },
    );
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      send({'action': 'ping'});
    });
  }

  void _scheduleReconnect() {
    final token = _token;
    if (token == null) return;
    Future.delayed(const Duration(seconds: 3), () {
      if (_token == token) {
        connect(token);
      }
    });
  }

  void send(Map<String, dynamic> payload) {
    _channel?.sink.add(jsonEncode(payload));
  }

  void markRead(int conversationId) {
    send({'action': 'read', 'conversation_id': conversationId});
  }

  Future<void> disconnect() async {
    _pingTimer?.cancel();
    _pingTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    onConnectionChanged?.call(false);
  }
}
