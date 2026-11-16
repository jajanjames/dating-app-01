// FILE: lib/data/repositories/onboarding_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../models/onboarding_models.dart';

/// Wraps the `/onboarding/*` endpoints.
class OnboardingRepository {
  OnboardingRepository(this._api);

  final ApiClient _api;

  /// Sends (or re-sends) the OTP.
  Future<void> sendOtp({
    required String countryCode,
    required String phoneNumber,
  }) async {
    await _api.postJson('/onboarding/send-otp', {
      'countryCode': countryCode,
      'phoneNumber': phoneNumber,
    });
  }

  Future<VerifyOtpResult> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    final json = await _api.postJson('/onboarding/verify-otp', {
      'phoneNumber': phoneNumber,
      'otp': otp,
    });
    return VerifyOtpResult.fromJson(_asMap(json));
  }

  /// Saves a single step. [fields] holds only that step's data.
  Future<void> saveStep({
    required String sessionId,
    required OnboardingApiStep step,
    required Map<String, dynamic> fields,
  }) async {
    await _api.postJson('/onboarding/save', {
      'sessionId': sessionId,
      'step': step.value,
      ...fields,
    });
  }

  /// Uploads images and returns their public URLs.
  Future<List<String>> uploadImages({
    required String sessionId,
    required UploadImageType type,
    required List<UploadFile> files,
  }) async {
    final json = await _api.postMultipart(
      '/onboarding/upload-images',
      fields: {'sessionId': sessionId, 'type': type.value},
      fileField: 'files',
      files: files,
    );
    final urls = _asMap(json)['urls'];
    if (urls is! List) {
      throw const ApiException('Upload failed: no image URLs returned.');
    }
    return urls.whereType<String>().toList();
  }

  Future<CompleteOnboardingResult> complete({required String sessionId}) async {
    final json = await _api.postJson('/onboarding/complete', {
      'sessionId': sessionId,
    });
    return CompleteOnboardingResult.fromJson(_asMap(json));
  }

  Map<String, dynamic> _asMap(dynamic json) {
    if (json is Map<String, dynamic>) return json;
    throw const ApiException('Unexpected response from the server.');
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepository(ref.watch(apiClientProvider)),
);
