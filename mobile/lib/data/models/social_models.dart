// FILE: lib/data/models/social_models.dart
import 'package:flutter/foundation.dart';

import 'candidate_profile.dart';
import 'discover_models.dart';
import 'match_thread.dart';

DateTime? parseApiDate(dynamic value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

/// `2:14 PM`
String clockLabel(DateTime t) {
  final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final minute = t.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${t.hour < 12 ? 'AM' : 'PM'}';
}

/// Chat-list style label: `2:14 PM`, `Yesterday`, `Mon`, or `12 Nov`.
String relativeLabel(DateTime t, [DateTime? now]) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(t.year, t.month, t.day);
  final diff = today.difference(day).inDays;
  if (diff <= 0) return clockLabel(t);
  if (diff == 1) return 'Yesterday';
  if (diff < 7) {
    return const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][t.weekday - 1];
  }
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${t.day} ${months[t.month - 1]}';
}

/// Maps the API `PublicProfile` (Likes / Chats) onto the UI's [CandidateProfile].
CandidateProfile candidateFromPublicProfile(
  Map<String, dynamic> json,
  Map<String, String> interestLabels,
) {
  final distance = (json['distanceKm'] as num?)?.round();
  final isOnline = json['isOnline'] == true;
  final base = DiscoverProfile.fromJson({
    'id': json['id'] ?? '',
    ...json,
    'sharedInterestsCount': 0,
  }).toCandidate(interestLabels);
  return base.copyWith(
    neighborhood: distance == null ? 'Nearby' : '$distance km away',
    distanceKm: distance ?? 0,
    bio: '',
    isOnline: isOnline,
    lastSeenLabel: isOnline ? 'Online' : 'Offline',
  );
}

/// A like, star or note from `GET /likes/received`, `GET /likes/sent`
/// or the `like` socket event.
@immutable
class LikeItem {
  const LikeItem({
    required this.id,
    required this.isPremium,
    required this.note,
    required this.createdAt,
    required this.profile,
  });

  factory LikeItem.fromJson(
    Map<String, dynamic> json,
    Map<String, String> interestLabels,
  ) {
    final isPremium = json['action'] == 'PREMIUM_LIKE';
    final note = json['note'] as String?;
    final profile = candidateFromPublicProfile(
      json['profile'] is Map<String, dynamic>
          ? json['profile'] as Map<String, dynamic>
          : const {},
      interestLabels,
    );
    return LikeItem(
      id: json['id'] as String? ?? '',
      isPremium: isPremium,
      note: note == null || note.isEmpty ? null : note,
      createdAt: parseApiDate(json['createdAt']) ?? DateTime.now(),
      profile: profile.copyWith(isSuperLiked: isPremium, paidIntroMessage: note),
    );
  }

  /// Swipe id.
  final String id;

  /// A star (premium like).
  final bool isPremium;

  /// The note sent with the like, if any.
  final String? note;
  final DateTime createdAt;

  /// The other user.
  final CandidateProfile profile;

  String get userId => profile.id;
}

/// Response of `GET /chats`.
@immutable
class ChatInbox {
  const ChatInbox({
    required this.newMatches,
    required this.conversations,
    required this.canMessage,
  });

  /// Matches without any message yet.
  final List<MatchThread> newMatches;

  /// Matches with messages, latest activity first.
  final List<MatchThread> conversations;

  /// Whether the viewer can send messages (women, or an active plan).
  final bool canMessage;

  int get totalUnread =>
      conversations.fold(0, (sum, t) => sum + t.unreadCount);

  MatchThread? find(String conversationId) {
    for (final t in [...conversations, ...newMatches]) {
      if (t.id == conversationId) return t;
    }
    return null;
  }

  ChatInbox copyWith({
    List<MatchThread>? newMatches,
    List<MatchThread>? conversations,
    bool? canMessage,
  }) {
    return ChatInbox(
      newMatches: newMatches ?? this.newMatches,
      conversations: conversations ?? this.conversations,
      canMessage: canMessage ?? this.canMessage,
    );
  }
}

/// A page of `GET /chats/:id/messages` (oldest first).
@immutable
class MessagesPage {
  const MessagesPage({
    required this.messages,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<ChatMessage> messages;
  final String? nextCursor;
  final bool hasMore;
}

@immutable
class QuotaInfo {
  const QuotaInfo({required this.limit, required this.used, required this.remaining});

  factory QuotaInfo.fromJson(dynamic json) {
    final m = json is Map ? json : const {};
    return QuotaInfo(
      limit: (m['limit'] as num?)?.toInt(),
      used: (m['used'] as num?)?.toInt() ?? 0,
      remaining: (m['remaining'] as num?)?.toInt(),
    );
  }

  /// `null` = unlimited.
  final int? limit;
  final int used;

  /// `null` = unlimited.
  final int? remaining;
}

/// A plan from `GET /subscriptions/plans`.
@immutable
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.title,
    required this.badgeLabel,
    required this.priceLabel,
    required this.tagline,
    required this.features,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) =>
      SubscriptionPlan(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        badgeLabel: json['badgeLabel'] as String? ?? '',
        priceLabel: json['priceLabel'] as String? ?? '',
        tagline: json['tagline'] as String? ?? '',
        features: (json['features'] is List)
            ? (json['features'] as List).whereType<String>().toList()
            : const [],
      );

  final String id;
  final String title;
  final String badgeLabel;
  final String priceLabel;
  final String tagline;
  final List<String> features;
}

/// Response of `GET /subscriptions/me`.
@immutable
class SubscriptionStatus {
  const SubscriptionStatus({
    required this.freeAccess,
    required this.planId,
    required this.expiresAt,
    required this.canMessage,
    required this.likes,
    required this.premiumLikes,
    required this.notes,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    final plan = json['plan'];
    final quotas = json['quotas'] is Map ? json['quotas'] as Map : const {};
    return SubscriptionStatus(
      freeAccess: json['freeAccess'] == true,
      planId: plan is Map ? plan['id'] as String? : null,
      expiresAt: parseApiDate(json['expiresAt']),
      canMessage: json['canMessage'] == true,
      likes: QuotaInfo.fromJson(quotas['likes']),
      premiumLikes: QuotaInfo.fromJson(quotas['premiumLikes']),
      notes: QuotaInfo.fromJson(quotas['notes']),
    );
  }

  /// Women: likes, notes and messages are free.
  final bool freeAccess;
  final String? planId;
  final DateTime? expiresAt;
  final bool canMessage;
  final QuotaInfo likes;
  final QuotaInfo premiumLikes;
  final QuotaInfo notes;
}
