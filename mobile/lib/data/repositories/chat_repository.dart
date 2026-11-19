// FILE: lib/data/repositories/chat_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/authed_api.dart';
import '../models/match_thread.dart';
import '../models/social_models.dart';

/// Wraps `/chats/*`. Sending normally goes over the socket
/// (see RealtimeService); [send] is the REST fallback.
class ChatRepository {
  ChatRepository(this._api);

  final AuthedApi _api;

  Future<ChatInbox> inbox(Map<String, String> labels) async {
    final json = asJsonMap(await _api.get('/chats'));
    return ChatInbox(
      newMatches: [
        for (final c in asJsonList(json['newMatches'])) MatchThread.fromJson(c, labels),
      ],
      conversations: [
        for (final c in asJsonList(json['conversations'])) MatchThread.fromJson(c, labels),
      ],
      canMessage: json['canMessage'] == true,
    );
  }

  Future<MatchThread> conversation(String id, Map<String, String> labels) async {
    final json = asJsonMap(await _api.get('/chats/$id'));
    return MatchThread.fromJson(asJsonMap(json['conversation']), labels);
  }

  /// Newest page first; pass [cursor] (from the previous page) to go older.
  Future<MessagesPage> messages(String id, {String? cursor, int limit = 30}) async {
    final query = Uri(queryParameters: {
      'limit': '$limit',
      if (cursor != null) 'cursor': cursor,
    }).query;
    final json = asJsonMap(await _api.get('/chats/$id/messages?$query'));
    return MessagesPage(
      messages: [for (final m in asJsonList(json['messages'])) ChatMessage.fromJson(m)],
      nextCursor: json['nextCursor'] as String?,
      hasMore: json['hasMore'] == true,
    );
  }

  Future<ChatMessage> send(String id, String text, {String? clientId}) async {
    final json = asJsonMap(await _api.post('/chats/$id/messages', {
      'text': text,
      if (clientId != null) 'clientId': clientId,
    }));
    return ChatMessage.fromJson(asJsonMap(json['message']), clientId: clientId);
  }

  Future<void> markRead(String id) => _api.post('/chats/$id/read');
}

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.watch(authedApiProvider)),
);
