import 'dart:convert';

import 'package:survivor_pool/core/models/user.dart';

import 'storage_backend_stub.dart'
    if (dart.library.html) 'storage_backend_web.dart'
    if (dart.library.io) 'storage_backend_native.dart';

class StoredSession {
  final String token;
  final AppUser user;

  const StoredSession({required this.token, required this.user});
}

class AuthStorage {
  AuthStorage._();

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';
  static final AuthStorageBackend _backend = AuthStorageBackend();

  static Future<void> saveSession(String token, AppUser user) async {
    await _backend.write(_tokenKey, token);
    await _backend.write(_userKey, json.encode(user.toJson()));
  }

  static Future<StoredSession?> loadSession() async {
    final token = await _backend.read(_tokenKey);
    final userRaw = await _backend.read(_userKey);
    if (token == null || token.isEmpty || userRaw == null || userRaw.isEmpty) {
      return null;
    }
    try {
      final decoded = json.decode(userRaw);
      if (decoded is Map<String, dynamic>) {
        return StoredSession(token: token, user: AppUser.fromJson(decoded));
      }
    } catch (_) {
      await clearSession();
    }
    return null;
  }

  static Future<void> clearSession() async {
    await _backend.delete(_tokenKey);
    await _backend.delete(_userKey);
  }

  static Future<void> saveToken(String token) {
    return _backend.write(_tokenKey, token);
  }
}
