// FILE: lib/data/models/match_thread.dart
import 'package:flutter/foundation.dart';
import 'candidate_profile.dart';
import 'social_models.dart';

/// Delivery state of a message the viewer sent.
enum MessageSendStatus { sending, sent, failed }

/// Represents an individual chat message inside a mutual match thread.
@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAtLabel,
    this.isFromViewer = false,
    this.conversationId = '',
    this.isNote = false,
    this.createdAt,
    this.readAt,
    this.clientId,
    this.status = MessageSendStatus.sent,
  });

  /// Parses a `MessageView` from the API or the `message` socket event.
  factory ChatMessage.fromJson(Map<String, dynamic> json, {String? clientId}) {
    final createdAt = parseApiDate(json['createdAt']) ?? DateTime.now();
    return ChatMessage(
      id: json['id'] as String? ?? '',
      conversationId: json['conversationId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      text: json['text'] as String? ?? '',
      isNote: json['isNote'] == true,
      isFromViewer: json['isMine'] == true,
      createdAt: createdAt,
      readAt: parseApiDate(json['readAt']),
      sentAtLabel: clockLabel(createdAt),
      clientId: clientId,
    );
  }

  final String id;
  final String senderId;
  final String text;
  final String sentAtLabel;
  final bool isFromViewer;
  final String conversationId;

  /// The note that was sent with a like before matching.
  final bool isNote;
  final DateTime? createdAt;
  final DateTime? readAt;

  /// Local id of an optimistic message, echoed back by the server.
  final String? clientId;
  final MessageSendStatus status;

  ChatMessage copyWith({
    String? id,
    DateTime? readAt,
    MessageSendStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId,
      text: text,
      sentAtLabel: sentAtLabel,
      isFromViewer: isFromViewer,
      conversationId: conversationId,
      isNote: isNote,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
      clientId: clientId,
      status: status ?? this.status,
    );
  }
}

/// Represents a mutual match and its conversation history.
@immutable
class MatchThread {
  const MatchThread({
    required this.id,
    required this.partner,
    required this.matchedAtLabel,
    required this.messages,
    this.isSuperMatch = false,
    this.unreadCount = 0,
    this.matchedAt,
  });

  /// Parses a `ConversationView` from the API or the `match` socket event.
  /// [messages] holds only the last message; the chat screen loads history.
  factory MatchThread.fromJson(
    Map<String, dynamic> json,
    Map<String, String> interestLabels,
  ) {
    final matchedAt = parseApiDate(json['matchedAt']) ?? DateTime.now();
    final last = json['lastMessage'];
    return MatchThread(
      id: json['id'] as String? ?? '',
      partner: candidateFromPublicProfile(
        json['partner'] is Map<String, dynamic>
            ? json['partner'] as Map<String, dynamic>
            : const {},
        interestLabels,
      ),
      matchedAt: matchedAt,
      matchedAtLabel: relativeLabel(matchedAt),
      messages: [
        if (last is Map<String, dynamic>) ChatMessage.fromJson(last),
      ],
      isSuperMatch: json['isSuperMatch'] == true,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final CandidateProfile partner;
  final String matchedAtLabel;
  final List<ChatMessage> messages;
  final bool isSuperMatch;
  final int unreadCount;
  final DateTime? matchedAt;

  ChatMessage? get lastMessage => messages.isEmpty ? null : messages.last;

  /// Time of the latest activity, for sorting the chat list.
  DateTime get activityAt =>
      lastMessage?.createdAt ?? matchedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  MatchThread copyWith({
    String? id,
    CandidateProfile? partner,
    String? matchedAtLabel,
    List<ChatMessage>? messages,
    bool? isSuperMatch,
    int? unreadCount,
  }) {
    return MatchThread(
      id: id ?? this.id,
      partner: partner ?? this.partner,
      matchedAtLabel: matchedAtLabel ?? this.matchedAtLabel,
      messages: messages ?? this.messages,
      isSuperMatch: isSuperMatch ?? this.isSuperMatch,
      unreadCount: unreadCount ?? this.unreadCount,
      matchedAt: matchedAt,
    );
  }
}
