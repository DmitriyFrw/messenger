import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/models.dart';

class ApiClient {
  ApiClient({required String baseUrl, String? token})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          ),
        );

  final Dio _dio;

  void setToken(String? token) {
    if (token == null) {
      _dio.options.headers.remove('Authorization');
    } else {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  void setBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  Future<AuthSession> register({
    required String username,
    required String password,
    required String displayName,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/register',
      data: {
        'username': username,
        'password': password,
        'display_name': displayName,
      },
    );
    return _sessionFromResponse(response.data!);
  }

  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: {'username': username, 'password': password},
    );
    return _sessionFromResponse(response.data!);
  }

  AuthSession _sessionFromResponse(Map<String, dynamic> data) => AuthSession(
        token: data['access_token'] as String,
        user: UserPublic.fromJson(data['user'] as Map<String, dynamic>),
      );

  Future<UserPublic> getMe() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/users/me');
    return UserPublic.fromJson(response.data!);
  }

  Future<UserPublic> updateDisplayName(String displayName) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/users/me',
      data: {'display_name': displayName},
    );
    return UserPublic.fromJson(response.data!);
  }

  Future<List<UserPublic>> searchUsers(String query) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/users/search',
      queryParameters: {'q': query},
    );
    return response.data!
        .map((e) => UserPublic.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Conversation>> fetchConversations() async {
    final response = await _dio.get<List<dynamic>>('/api/conversations');
    return response.data!
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Message>> fetchMessages(int conversationId) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/conversations/$conversationId/messages',
      queryParameters: {'limit': 200},
    );
    return response.data!
        .map((e) => Message.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Message> sendMessage({
    required int recipientId,
    required String text,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/messages',
      data: {'recipient_id': recipientId, 'text': text},
    );
    return Message.fromJson(response.data!);
  }

  Future<List<Message>> markConversationRead(int conversationId) async {
    final response = await _dio.post<List<dynamic>>(
      '/api/conversations/$conversationId/read',
    );
    return response.data!
        .map((e) => Message.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Message>> sync({DateTime? updatedSince}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/sync',
      queryParameters: updatedSince != null
          ? {'updated_since': updatedSince.toUtc().toIso8601String()}
          : null,
    );
    final data = response.data!;
    final serverTime = DateTime.parse(data['server_time'] as String).toUtc();
    final messages = (data['messages'] as List<dynamic>)
        .map((e) => Message.fromJson(e as Map<String, dynamic>))
        .toList();
    return messages;
  }

  static Future<ApiClient> create({String? token}) async {
    final baseUrl = await ApiConfig.loadBaseUrl();
    return ApiClient(baseUrl: baseUrl, token: token);
  }
}
