// FILE: lib/data/models/onboarding_models.dart

/// Server-side onboarding steps, in the order the backend enforces.
enum OnboardingApiStep {
  basicInfo('BASIC_INFO'),
  relationshipGoal('RELATIONSHIP_GOAL'),
  photos('PHOTOS'),
  location('LOCATION'),
  verification('VERIFICATION');

  const OnboardingApiStep(this.value);

  final String value;

  static OnboardingApiStep? fromValue(Object? raw) {
    for (final step in values) {
      if (step.value == raw) return step;
    }
    return null;
  }
}

/// `type` field of `/onboarding/upload-images`.
enum UploadImageType {
  gallery('GALLERY'),
  verification('VERIFICATION');

  const UploadImageType(this.value);

  final String value;
}

List<String> _stringList(Object? raw) =>
    raw is List ? raw.whereType<String>().toList() : const <String>[];

double? _toDouble(Object? raw) => raw is num ? raw.toDouble() : null;

/// Data already submitted for an onboarding session (all fields nullable).
class OnboardingData {
  const OnboardingData({
    this.name,
    this.dateOfBirth,
    this.gender,
    this.showGenderOnProfile,
    this.relationshipGoal,
    this.photos = const [],
    this.latitude,
    this.longitude,
    this.preferredDistanceKm,
    this.verificationImages = const [],
  });

  factory OnboardingData.fromJson(Map<String, dynamic> json) {
    return OnboardingData(
      name: json['name'] as String?,
      dateOfBirth: json['dateOfBirth'] is String
          ? DateTime.tryParse(json['dateOfBirth'] as String)
          : null,
      gender: json['gender'] as String?,
      showGenderOnProfile: json['showGenderOnProfile'] as bool?,
      relationshipGoal: json['relationshipGoal'] as String?,
      photos: _stringList(json['photos']),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      preferredDistanceKm: _toDouble(json['preferredDistanceKm'])?.round(),
      verificationImages: _stringList(json['verificationImages']),
    );
  }

  final String? name;
  final DateTime? dateOfBirth;

  /// `MALE` | `FEMALE` | `OTHER`
  final String? gender;
  final bool? showGenderOnProfile;

  /// `OPEN_MINDED` | `SERIOUS_RELATIONSHIP` | `CASUAL`
  final String? relationshipGoal;
  final List<String> photos;
  final double? latitude;
  final double? longitude;
  final int? preferredDistanceKm;
  final List<String> verificationImages;
}

/// Onboarding session progress returned by verify-otp.
class OnboardingSession {
  const OnboardingSession({
    required this.sessionId,
    required this.lastCompletedStep,
    required this.nextStep,
    required this.canComplete,
    required this.data,
  });

  factory OnboardingSession.fromJson(Map<String, dynamic> json) {
    return OnboardingSession(
      sessionId: json['sessionId'] as String,
      lastCompletedStep: OnboardingApiStep.fromValue(json['lastCompletedStep']),
      nextStep: OnboardingApiStep.fromValue(json['nextStep']),
      canComplete: json['canComplete'] == true,
      data: json['data'] is Map<String, dynamic>
          ? OnboardingData.fromJson(json['data'] as Map<String, dynamic>)
          : const OnboardingData(),
    );
  }

  final String sessionId;
  final OnboardingApiStep? lastCompletedStep;
  final OnboardingApiStep? nextStep;
  final bool canComplete;
  final OnboardingData data;
}

/// Result of `/onboarding/verify-otp`.
///
/// New users get [sessionId] + [onboarding]; existing users with a completed
/// profile get [accessToken] + [user].
class VerifyOtpResult {
  const VerifyOtpResult({
    required this.isNewUser,
    this.sessionId,
    this.onboarding,
    this.accessToken,
    this.user,
  });

  factory VerifyOtpResult.fromJson(Map<String, dynamic> json) {
    final onboardingJson = json['onboarding'];
    return VerifyOtpResult(
      isNewUser: json['isNewUser'] == true,
      sessionId: json['sessionId'] as String?,
      onboarding: onboardingJson is Map<String, dynamic>
          ? OnboardingSession.fromJson(onboardingJson)
          : null,
      accessToken: json['accessToken'] as String?,
      user: json['user'] as Map<String, dynamic>?,
    );
  }

  final bool isNewUser;
  final String? sessionId;
  final OnboardingSession? onboarding;
  final String? accessToken;
  final Map<String, dynamic>? user;
}

/// Result of `/onboarding/complete`.
class CompleteOnboardingResult {
  const CompleteOnboardingResult({required this.accessToken, this.user});

  factory CompleteOnboardingResult.fromJson(Map<String, dynamic> json) {
    return CompleteOnboardingResult(
      accessToken: json['accessToken'] as String,
      user: json['user'] as Map<String, dynamic>?,
    );
  }

  final String accessToken;
  final Map<String, dynamic>? user;
}
