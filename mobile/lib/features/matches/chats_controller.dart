// FILE: lib/features/matches/chats_controller.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/realtime/realtime_service.dart';
import '../../data/models/match_thread.dart';
import '../../data/models/social_models.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/interests_repository.dart';

/// Conversation currently open in ChatScreen (its messages are not unread).
final openConversationIdProvider = StateProvider<String?>((ref) => null);

/// Chats tab state from `GET /chats`, kept live by the `message` and `match`
/// socket events.
class ChatInboxController extends AsyncNotifier<ChatInbox> {
  @override
  Future<ChatInbox> build() async {
    final realtime = ref.watch(realtimeServiceProvider);
    final subscriptions = <StreamSubscription<dynamic>>[
      realtime.onMessage.listen(_onMessage),
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

  Future<ChatInbox> _load() async {
    final labels = await ref.read(interestLabelsProvider.future);
    return ref.read(chatRepositoryProvider).inbox(labels);
  }

  /// Reloads, keeping the current data on screen if the reload fails.
  Future<void> refresh() async {
    final next = await AsyncValue.guard(_load);
    if (next.hasValue || !state.hasValue) state = next;
  }

  /// Adds or replaces a conversation (e.g. right after accepting a like).
  void upsert(MatchThread thread) {
    final inbox = state.valueOrNull;
    if (inbox == null) return;
    final newMatches = inbox.newMatches.where((t) => t.id != thread.id).toList();
    final conversations = inbox.conversations.where((t) => t.id != thread.id).toList();
    if (thread.lastMessage == null) {
      newMatches.insert(0, thread);
    } else {
      conversations
        ..add(thread)
        ..sort((a, b) => b.activityAt.compareTo(a.activityAt));
    }
    state = AsyncData(inbox.copyWith(newMatches: newMatches, conversations: conversations));
  }

  void markRead(String conversationId) {
    final thread = state.valueOrNull?.find(conversationId);
    if (thread != null && thread.unreadCount > 0) {
      upsert(thread.copyWith(unreadCount: 0));
    }
  }

  /// Latest plan / gender access, after the subscription changes.
  void setCanMessage(bool canMessage) {
    final inbox = state.valueOrNull;
    if (inbox != null) state = AsyncData(inbox.copyWith(canMessage: canMessage));
  }

  void _onMessage(Map<String, dynamic> event) {
    final conversationId = event['conversationId'];
    final raw = event['message'];
    final thread = conversationId is String ? state.valueOrNull?.find(conversationId) : null;
    if (thread == null || raw is! Map<String, dynamic>) {
      refresh();
      return;
    }
    final message = ChatMessage.fromJson(raw);
    final isOpen = ref.read(openConversationIdProvider) == conversationId;
    upsert(thread.copyWith(
      messages: [message],
      unreadCount: isOpen
          ? 0
          : thread.unreadCount + (message.isFromViewer ? 0 : 1),
    ));
  }

  void _onMatch(Map<String, dynamic> event) {
    final raw = event['conversation'];
    if (raw is! Map<String, dynamic>) return;
    final labels = ref.read(interestLabelsProvider).valueOrNull ?? const {};
    upsert(MatchThread.fromJson(raw, labels));
  }
}

final chatInboxProvider = AsyncNotifierProvider<ChatInboxController, ChatInbox>(
  ChatInboxController.new,
);

/// Total unread messages, for the Chats tab badge.
final unreadChatsCountProvider = Provider<int>(
  (ref) => ref.watch(chatInboxProvider).valueOrNull?.totalUnread ?? 0,
);
