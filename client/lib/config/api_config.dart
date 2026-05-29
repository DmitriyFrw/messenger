import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const _keyBaseUrl = 'api_base_url';

  /// URL по умолчанию для эмулятора/симулятора и десктопа.
  static String defaultBaseUrl() {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  static String httpToWs(String baseUrl) {
    final uri = Uri.parse(baseUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return uri.replace(scheme: scheme).toString();
  }

  static Future<String> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBaseUrl) ?? defaultBaseUrl();
  }

  static Future<void> saveBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, url.trim().replaceAll(RegExp(r'/+$'), ''));
  }
}
