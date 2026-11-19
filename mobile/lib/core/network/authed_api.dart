// FILE: lib/core/network/authed_api.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/onboarding_repository.dart';
import '../storage/auth_storage.dart';
import 'api_client.dart';

/// [ApiClient] calls that need the signed-in user's JWT. Clears the session on 401.
class AuthedApi {
  AuthedApi(this._api, this._storage);

  final ApiClient _api;
  final AuthStorage _storage;

  Future<dynamic> get(String path) => _run((t) => _api.getJson(path, token: t));

  Future<dynamic> post(String path, [Map<String, dynamic> body = const {}]) =>
      _run((t) => _api.postJson(path, body, token: t));

  Future<dynamic> put(String path, Map<String, dynamic> body) =>
      _run((t) => _api.putJson(path, body, token: t));

  Future<dynamic> delete(String path) =>
      _run((t) => _api.deleteJson(path, token: t));

  Future<String> requireToken() async {
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Your session has expired. Please sign in again.',
        statusCode: 401,
      );
    }
    return token;
  }

  Future<dynamic> _run(Future<dynamic> Function(String token) call) async {
    final token = await requireToken();
    try {
      return await call(token);
    } on ApiException catch (e) {
      if (e.statusCode == 401) await _storage.clear();
      rethrow;
    }
  }
}

Map<String, dynamic> asJsonMap(dynamic json) {
  if (json is Map<String, dynamic>) return json;
  throw const ApiException('Unexpected response from the server.');
}

List<Map<String, dynamic>> asJsonList(dynamic json) =>
    json is List ? json.whereType<Map<String, dynamic>>().toList() : const [];

final authedApiProvider = Provider<AuthedApi>(
  (ref) =>
      AuthedApi(ref.watch(apiClientProvider), ref.watch(authStorageProvider)),
);
