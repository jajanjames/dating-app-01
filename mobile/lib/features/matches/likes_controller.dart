// FILE: lib/features/matches/likes_controller.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/realtime/realtime_service.dart';
import '../../data/models/match_thread.dart';
import '../../data/models/social_models.dart';
import '../../data/repositories/interests_repository.dart';
import '../../data/repositories/likes_repository.dart';
import 'chats_controller.dart';

@immutable
class LikesFeed {
  const LikesFeed({required this.received, required this.sent});

  /// Liked You: pending likes, stars and notes.
  final List<LikeItem> received;

  /// Your Likes: sent likes waiting for an answer.
  final List<LikeItem> sent;

  LikesFeed copyWith({List<LikeItem>? received, List<LikeItem>? sent}) =>
      LikesFeed(received: received ?? this.received, sent: sent ?? this.sent);

  LikesFeed without(String userId) => LikesFeed(
        received: received.where((l) => l.userId != userId).toList(),
        sent: sent.where((l) => l.userId != userId).toList(),
      );
}

/// Likes tab state, kept live by the `like` and `match` socket events.
class LikesController extends AsyncNotifier<LikesFeed> {
  @override
  Future<LikesFeed> build() async {
    final realtime = ref.watch(realtimeServiceProvider);
    final subscriptions = <StreamSubscription<dynamic>>[
      realtime.onLike.listen(_onLike),
      realtime.onMatch.listen(_onMatch),
      realtime.onReconnect.listen((_) => refresh()),
    ];
    ref.onDispose(() {
      for (final s in subscriptions) {
        s.cancel();
      }
    });
    return _load();
  }

  Future<LikesFeed> _load() async {
    final labels = await ref.read(interestLabelsProvider.future);
    final repo = ref.read(likesRepositoryProvider);
    final results = await Future.wait([repo.received(labels), repo.sent(labels)]);
    return LikesFeed(received: results[0], sent: results[1]);
  }

  Future<void> refresh() async {
    final next = await AsyncValue.guard(_load);
    if (next.hasValue || !state.hasValue) state = next;
  }

  /// Like back. Returns the new conversation to open.
  Future<MatchThread> accept(LikeItem like) async {
    final labels = ref.read(interestLabelsProvider).valueOrNull ?? const {};
    final thread = await ref.read(likesRepositoryProvider).accept(like.userId, labels);
    _remove(like.userId);
    ref.read(chatInboxProvider.notifier).upsert(thread);
    return thread;
  }

  Future<void> reject(LikeItem like) async {
    await ref.read(likesRepositoryProvider).reject(like.userId);
    _remove(like.userId);
  }

  void _remove(String userId) {
    final feed = state.valueOrNull;
    if (feed != null) state = AsyncData(feed.without(userId));
  }

  void _onLike(Map<String, dynamic> event) {
    final feed = state.valueOrNull;
    if (feed == null) return;
    final labels = ref.read(interestLabelsProvider).valueOrNull ?? const {};
    final like = LikeItem.fromJson(event, labels);
    state = AsyncData(feed.copyWith(received: [
      like,
      ...feed.received.where((l) => l.userId != like.userId),
    ]));
  }

  void _onMatch(Map<String, dynamic> event) {
    final conversation = event['conversation'];
    final partner = conversation is Map ? conversation['partner'] : null;
    final partnerId = partner is Map ? partner['id'] : null;
    if (partnerId is String) _remove(partnerId);
  }
}

final likesControllerProvider = AsyncNotifierProvider<LikesController, LikesFeed>(
  LikesController.new,
);
