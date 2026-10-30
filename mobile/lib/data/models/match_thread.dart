// FILE: lib/data/models/match_thread.dart
import 'package:flutter/foundation.dart';
import 'candidate_profile.dart';

/// Represents an individual chat message inside a mutual match thread.
@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAtLabel,
    this.isFromViewer = false,
  });

  final String id;
  final String senderId;
  final String text;
  final String sentAtLabel;
  final bool isFromViewer;
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
  });

  final String id;
  final CandidateProfile partner;
  final String matchedAtLabel;
  final List<ChatMessage> messages;
  final bool isSuperMatch;
  final int unreadCount;

  ChatMessage? get lastMessage => messages.isEmpty ? null : messages.last;

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
    );
  }
}
