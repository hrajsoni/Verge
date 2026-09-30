import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String _defaultBaseUrl = "http://localhost:3000/v1";
  static const String _storageTokenKey = "besnap_jwt_token";

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient({String baseUrl = _defaultBaseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Auth Bearer Token Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: _storageTokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          // Global error handling for 401 Unauthorized / Token Expired
          if (error.response?.statusCode == 401) {
            _storage.delete(key: _storageTokenKey);
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Auth Methods
  Future<void> saveToken(String token) async {
    await _storage.write(key: _storageTokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _storageTokenKey);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _storageTokenKey);
  }

  Future<Response> googleLogin(String idToken) {
    return _dio.post('/auth/google', data: {'idToken': idToken});
  }

  // Discovery / Swiping
  Future<Response> getDiscoveryFeed() {
    return _dio.get('/discovery/feed');
  }

  Future<Response> swipeUser(String targetUserId, String action) {
    return _dio.post('/swipes', data: {
      'targetUserId': targetUserId,
      'action': action, // 'LIKE' or 'PASS'
    });
  }

  // Matches & Conversations
  Future<Response> getMatches() {
    return _dio.get('/matching/matches');
  }

  Future<Response> getConversations() {
    return _dio.get('/chat/conversations');
  }

  Future<Response> getMessages(String conversationId) {
    return _dio.get('/chat/conversations/$conversationId/messages');
  }

  Future<Response> sendMessage({
    required String conversationId,
    String? text,
    String? mediaId,
    int? snapDuration,
    int? snapMaxViews,
  }) {
    return _dio.post(
      '/chat/conversations/$conversationId/messages',
      data: {
        if (text != null) 'text': text,
        if (mediaId != null) 'mediaId': mediaId,
        if (snapDuration != null) 'snapViewDuration': snapDuration,
        if (snapMaxViews != null) 'snapMaxViews': snapMaxViews,
      },
    );
  }

  // Ephemeral Snap Lifecycle
  Future<Response> openSnap(String messageId) {
    return _dio.post('/chat/snaps/$messageId/open');
  }

  Future<Response> markSnapViewed(String messageId) {
    return _dio.post('/chat/snaps/$messageId/viewed');
  }

  // Presigned S3 Upload Flow
  Future<Response> requestUploadUrl({
    required String mimeType,
    required String type, // 'SNAP', 'PROFILE', 'CHAT'
    required int sizeBytes,
  }) {
    return _dio.post(
      '/media/upload-url',
      data: {
        'mimeType': mimeType,
        'type': type,
        'sizeBytes': sizeBytes,
      },
    );
  }

  // Profile
  Future<Response> getMyProfile() {
    return _dio.get('/users/me');
  }

  Future<Response> updateMyProfile(Map<String, dynamic> data) {
    return _dio.patch('/users/me', data: data);
  }
}
