// FILE: lib/data/repositories/likes_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/authed_api.dart';
import '../models/match_thread.dart';
import '../models/social_models.dart';

/// Wraps `/likes/*`. Likes are only *sent* from Discover; here the user
/// answers incoming likes.
class LikesRepository {
  LikesRepository(this._api);

  final AuthedApi _api;

  /// Liked You: pending incoming likes, stars and notes.
  Future<List<LikeItem>> received(Map<String, String> labels) async {
    final json = asJsonMap(await _api.get('/likes/received'));
    return [for (final l in asJsonList(json['likes'])) LikeItem.fromJson(l, labels)];
  }

  /// Your Likes: sent likes that have not matched yet.
  Future<List<LikeItem>> sent(Map<String, String> labels) async {
    final json = asJsonMap(await _api.get('/likes/sent'));
    return [for (final l in asJsonList(json['likes'])) LikeItem.fromJson(l, labels)];
  }

  /// Like back. Returns the new conversation.
  Future<MatchThread> accept(String userId, Map<String, String> labels) async {
    final json = asJsonMap(await _api.post('/likes/$userId/accept'));
    return MatchThread.fromJson(asJsonMap(json['conversation']), labels);
  }

  Future<void> reject(String userId) => _api.post('/likes/$userId/reject');
}

final likesRepositoryProvider = Provider<LikesRepository>(
  (ref) => LikesRepository(ref.watch(authedApiProvider)),
);
