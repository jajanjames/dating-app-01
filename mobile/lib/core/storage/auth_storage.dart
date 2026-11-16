// FILE: lib/core/storage/auth_storage.dart
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the signed-in user's access token and profile snapshot.
class AuthStorage {
  AuthStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'naam.accessToken';
  static const String _userKey = 'naam.user';

  Future<void> saveSession({
    required String accessToken,
    Map<String, dynamic>? user,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    if (user != null) {
      await _storage.write(key: _userKey, value: jsonEncode(user));
    }
  }

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<Map<String, dynamic>?> readUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _userKey);
  }
}

final authStorageProvider = Provider<AuthStorage>((ref) => AuthStorage());
