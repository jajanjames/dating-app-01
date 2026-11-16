// FILE: lib/data/models/discover_models.dart
import 'package:flutter/foundation.dart';

import 'candidate_profile.dart';

/// Swipe actions accepted by `POST /discover/swipe`.
enum SwipeAction {
  dislike('DISLIKE'),
  like('LIKE'),
  premiumLike('PREMIUM_LIKE');

  const SwipeAction(this.value);

  final String value;
}

/// A profile card from `GET /discover`. Never contains phone or coordinates.
@immutable
class DiscoverProfile {
  const DiscoverProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.relationshipGoal,
    required this.photos,
    required this.distanceKm,
    required this.sharedInterestsCount,
    required this.interestsStepOne,
    required this.interestsStepTwo,
  });

  factory DiscoverProfile.fromJson(Map<String, dynamic> json) {
    List<String> strings(dynamic v) =>
        v is List ? v.whereType<String>().toList() : const [];
    return DiscoverProfile(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      gender: json['gender'] as String?,
      relationshipGoal: json['relationshipGoal'] as String?,
      photos: strings(json['photos']),
      distanceKm: (json['distanceKm'] as num?)?.round() ?? 0,
      sharedInterestsCount: (json['sharedInterestsCount'] as num?)?.toInt() ?? 0,
      interestsStepOne: strings(json['interestsStepOne']),
      interestsStepTwo: strings(json['interestsStepTwo']),
    );
  }

  final String id;
  final String name;
  final int age;

  /// `MALE` | `FEMALE` | `OTHER`, or `null` when the user hides it.
  final String? gender;

  /// `OPEN_MINDED` | `SERIOUS_RELATIONSHIP` | `CASUAL`.
  final String? relationshipGoal;
  final List<String> photos;
  final int distanceKm;
  final int sharedInterestsCount;
  final List<String> interestsStepOne;
  final List<String> interestsStepTwo;

  static const Map<String, String> _genderLabels = {
    'MALE': 'Men',
    'FEMALE': 'Women',
    'OTHER': 'Non-binary',
  };

  static const Map<String, String> _goalLabels = {
    'OPEN_MINDED': 'Open-minded relationship',
    'SERIOUS_RELATIONSHIP': 'Serious relationship',
    'CASUAL': 'Casual',
  };

  /// Adapts the API card to the UI model. [interestLabels] maps interest enum
  /// values to display labels (from `GET /interests`).
  CandidateProfile toCandidate(Map<String, String> interestLabels) {
    String label(String v) => interestLabels[v] ?? _humanize(v);
    final goal = relationshipGoal == null
        ? ''
        : (_goalLabels[relationshipGoal] ?? _humanize(relationshipGoal!));
    return CandidateProfile(
      id: id,
      name: name,
      age: age,
      gender: _genderLabels[gender] ?? '',
      occupation: goal,
      education: '',
      heightLabel: '',
      zodiac: '',
      lifestyle: '',
      neighborhood: '$distanceKm km away',
      distanceKm: distanceKm,
      bio: sharedInterestsCount > 0
          ? '$sharedInterestsCount shared interest'
              '${sharedInterestsCount == 1 ? '' : 's'}'
          : '',
      imageUrls: photos,
      prompt: const ProfilePrompt(question: '', answer: ''),
      interests: [
        ...interestsStepOne.map(label),
        ...interestsStepTwo.map(label),
      ],
      intention: goal,
      likesViewer: false,
    );
  }

  static String _humanize(String v) {
    final words = v.toLowerCase().split('_').where((w) => w.isNotEmpty);
    final text = words.join(' ');
    return text.isEmpty ? v : text[0].toUpperCase() + text.substring(1);
  }
}

/// Response of `GET /discover` (at most 2 profiles).
@immutable
class DiscoverPage {
  const DiscoverPage({
    required this.profiles,
    required this.nextCursor,
    required this.hasMore,
  });

  factory DiscoverPage.fromJson(Map<String, dynamic> json) {
    final raw = json['profiles'];
    return DiscoverPage(
      profiles: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(DiscoverProfile.fromJson)
              .toList()
          : const [],
      nextCursor: json['nextCursor'] as String?,
      hasMore: json['hasMore'] == true,
    );
  }

  final List<DiscoverProfile> profiles;

  /// Opaque; pass back unchanged. `null` when [hasMore] is `false`.
  final String? nextCursor;
  final bool hasMore;
}

/// Response of `POST /discover/swipe`.
@immutable
class SwipeResult {
  const SwipeResult({
    required this.swipeId,
    required this.action,
    required this.messageSent,
    required this.isMatch,
  });

  factory SwipeResult.fromJson(Map<String, dynamic> json) => SwipeResult(
        swipeId: json['swipeId'] as String? ?? '',
        action: json['action'] as String? ?? '',
        messageSent: json['messageSent'] == true,
        isMatch: json['isMatch'] == true,
      );

  final String swipeId;
  final String action;
  final bool messageSent;
  final bool isMatch;
}
