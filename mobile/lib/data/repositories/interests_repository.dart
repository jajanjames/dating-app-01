// FILE: lib/data/repositories/interests_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/auth_storage.dart';
import '../models/interests_models.dart';
import 'onboarding_repository.dart';

/// Wraps `GET /interests` and `PUT /interests` (JWT required).
class InterestsRepository {
  InterestsRepository(this._api, this._storage);

  final ApiClient _api;
  final AuthStorage _storage;

  Future<InterestsResult> fetch() async {
    final token = await _requireToken();
    try {
      final json = await _api.getJson('/interests', token: token);
      return _parse(json);
    } on ApiException catch (e) {
      throw await _handleAuth(e);
    }
  }

  /// Replaces the saved selection for [step]. Always pass the full selection.
  Future<InterestsResult> save(InterestStep step, List<String> values) async {
    final token = await _requireToken();
    try {
      final json = await _api.putJson(
        '/interests',
        {'step': step.value, 'values': values},
        token: token,
      );
      return _parse(json);
    } on ApiException catch (e) {
      throw await _handleAuth(e);
    }
  }

  Future<String> _requireToken() async {
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Your session has expired. Please sign in again.',
        statusCode: 401,
      );
    }
    return token;
  }

  Future<ApiException> _handleAuth(ApiException e) async {
    if (e.statusCode == 401) await _storage.clear();
    return e;
  }

  InterestsResult _parse(dynamic json) {
    if (json is Map<String, dynamic>) return InterestsResult.fromJson(json);
    throw const ApiException('Unexpected response from the server.');
  }
}

final interestsRepositoryProvider = Provider<InterestsRepository>(
  (ref) => InterestsRepository(
    ref.watch(apiClientProvider),
    ref.watch(authStorageProvider),
  ),
);
