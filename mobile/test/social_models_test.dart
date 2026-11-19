// Parses payloads captured from the real backend (GET /chats, /likes/*,
// /subscriptions/*, /chats/:id/messages and the `like` / `message` socket
// events) to keep the app models in sync with the API.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jdate/data/models/match_thread.dart';
import 'package:jdate/data/models/social_models.dart';

void main() {
  final fixtures = jsonDecode(
    File('test/fixtures/api_payloads.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  Map<String, dynamic> m(String key) => fixtures[key] as Map<String, dynamic>;
  List<Map<String, dynamic>> list(Map<String, dynamic> json, String key) =>
      (json[key] as List).cast<Map<String, dynamic>>();

  test('GET /chats -> conversations and new matches', () {
    final chats = m('chats');
    final conversations =
        list(chats, 'conversations').map((c) => MatchThread.fromJson(c, const {}));
    final newMatches =
        list(chats, 'newMatches').map((c) => MatchThread.fromJson(c, const {}));

    final thread = conversations.first;
    expect(thread.id, isNotEmpty);
    expect(thread.partner.name, 'Anjali');
    expect(thread.lastMessage, isNotNull);
    expect(thread.lastMessage!.createdAt, isNotNull);
    expect(newMatches.any((t) => t.isSuperMatch), isTrue);
    expect(newMatches.every((t) => t.lastMessage == null), isTrue);
    expect(chats['canMessage'], isTrue);
  });

  test('GET /chats/:id/messages -> history with note and read state', () {
    final messages = list(m('messages'), 'messages').map(ChatMessage.fromJson).toList();
    expect(messages.first.isNote, isTrue);
    expect(messages.any((x) => x.isFromViewer), isTrue);
    expect(messages.any((x) => x.readAt != null), isTrue);
    // Oldest first.
    for (var i = 1; i < messages.length; i++) {
      expect(!messages[i].createdAt!.isBefore(messages[i - 1].createdAt!), isTrue);
    }
  });

  test('socket `message` event -> ChatMessage for the recipient', () {
    final event = m('messageEvent');
    final message = ChatMessage.fromJson(event['message'] as Map<String, dynamic>);
    expect(message.conversationId, event['conversationId']);
    expect(message.text, 'Free Sunday?');
    expect(message.isFromViewer, isFalse);
    expect((event['sender'] as Map)['name'], 'Anjali');
  });

  test('socket `like` event and GET /likes/received -> LikeItem', () {
    final like = LikeItem.fromJson(m('likeEvent'), const {});
    expect(like.isPremium, isTrue);
    expect(like.note, 'Your playlist is 🔥');
    expect(like.profile.name, 'Lakshmi');
    expect(like.profile.isSuperLiked, isTrue);
    expect(like.profile.neighborhood, endsWith('km away'));
    expect(like.profile.age, greaterThan(18));

    final received =
        list(m('likesReceived'), 'likes').map((l) => LikeItem.fromJson(l, const {}));
    expect(received.map((l) => l.userId), contains(like.userId));
  });

  test('GET /likes/sent -> pending likes', () {
    final sent = list(m('likesSent'), 'likes').map((l) => LikeItem.fromJson(l, const {}));
    expect(sent, isNotEmpty);
    expect(sent.every((l) => l.profile.id.isNotEmpty), isTrue);
  });

  test('GET /subscriptions/me and /plans', () {
    final status = SubscriptionStatus.fromJson(m('subscription'));
    expect(status.planId, 'premium');
    expect(status.canMessage, isTrue);
    expect(status.freeAccess, isFalse);
    expect(status.notes.limit, 1);
    expect(status.likes.limit, isNull);

    final plans = list(m('plans'), 'plans').map(SubscriptionPlan.fromJson).toList();
    expect(plans.map((p) => p.id), ['premium', 'premium_plus', 'ultra']);
    expect(plans.every((p) => p.features.length == 3), isTrue);
  });

  test('relativeLabel', () {
    final now = DateTime(2026, 11, 19, 15);
    expect(relativeLabel(DateTime(2026, 11, 19, 9, 5), now), '9:05 AM');
    expect(relativeLabel(DateTime(2026, 11, 18, 22), now), 'Yesterday');
    expect(relativeLabel(DateTime(2026, 11, 16, 10), now), 'Mon');
    expect(relativeLabel(DateTime(2026, 10, 2), now), '2 Oct');
  });
}
