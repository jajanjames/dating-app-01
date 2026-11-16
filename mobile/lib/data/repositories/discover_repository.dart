// FILE: lib/data/repositories/discover_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/auth_storage.dart';
import '../models/discover_models.dart';
import 'onboarding_repository.dart';

/// Wraps `GET /discover` and `POST /discover/swipe` (JWT required).
class DiscoverRepository {
  DiscoverRepository(this._api, this._storage);

  final ApiClient _api;
  final AuthStorage _storage;

  /// Fetches the next (up to) 2 profiles. Omit [cursor] for the first page.
  Future<DiscoverPage> fetch({String? cursor, String? gender}) async {
    final query = <String, String>{
      if (cursor != null) 'cursor': cursor,
      if (gender != null) 'gender': gender,
    };
    final path = query.isEmpty
        ? '/discover'
        : '/discover?${Uri(queryParameters: query).query}';
    final json = await _authed((token) => _api.getJson(path, token: token));
    return DiscoverPage.fromJson(_asMap(json));
  }

  /// Swipes once on [targetUserId]. [message] (max 200 chars) is only valid
  /// with [SwipeAction.like] or [SwipeAction.premiumLike].
  Future<SwipeResult> swipe({
    required String targetUserId,
    required SwipeAction action,
    String? message,
  }) async {
    final text = message?.trim();
    final json = await _authed(
      (token) => _api.postJson(
        '/discover/swipe',
        {
          'targetUserId': targetUserId,
          'action': action.value,
          if (action != SwipeAction.dislike && text != null && text.isNotEmpty)
            'message': text.length > 200 ? text.substring(0, 200) : text,
        },
        token: token,
      ),
    );
    return SwipeResult.fromJson(_asMap(json));
  }

  Future<dynamic> _authed(Future<dynamic> Function(String token) call) async {
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Your session has expired. Please sign in again.',
        statusCode: 401,
      );
    }
    try {
      return await call(token);
    } on ApiException catch (e) {
      if (e.statusCode == 401) await _storage.clear();
      rethrow;
    }
  }

  Map<String, dynamic> _asMap(dynamic json) {
    if (json is Map<String, dynamic>) return json;
    throw const ApiException('Unexpected response from the server.');
  }
}

final discoverRepositoryProvider = Provider<DiscoverRepository>(
  (ref) => DiscoverRepository(
    ref.watch(apiClientProvider),
    ref.watch(authStorageProvider),
  ),
);
