// FILE: lib/features/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/network/api_client.dart';
import '../../core/network/mapbox_geocoding_service.dart';
import '../../core/router/app_router.dart';
import '../../core/storage/auth_storage.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/onboarding_models.dart';
import '../../data/repositories/onboarding_repository.dart';
import 'city_search_sheet.dart';
import 'selfie_capture_screen.dart';

const Object _unset = Object();

/// UI label ↔ API enum mappings.
abstract final class OnboardingOptions {
  static const Map<String, String> genders = {
    'Woman': 'FEMALE',
    'Man': 'MALE',
    'Non-binary': 'OTHER',
  };

  static const Map<String, String> relationshipGoals = {
    'Open-minded relationship': 'OPEN_MINDED',
    'Serious relationship': 'SERIOUS_RELATIONSHIP',
    'Casual': 'CASUAL',
  };

  static const List<CityOption> cities = [
    CityOption('Kochi, Kerala', 9.9312, 76.2673),
    CityOption('Trivandrum, Kerala', 8.5241, 76.9366),
    CityOption('Kozhikode, Kerala', 11.2588, 75.7804),
    CityOption('Kottayam, Kerala', 9.5916, 76.5222),
    CityOption('Thrissur, Kerala', 10.5276, 76.2144),
    CityOption('Bengaluru, Karnataka', 12.9716, 77.5946),
    CityOption('Chennai, Tamil Nadu', 13.0827, 80.2707),
    CityOption('Mumbai, Maharashtra', 19.0760, 72.8777),
  ];

  static String? labelFor(Map<String, String> map, String? apiValue) {
    for (final entry in map.entries) {
      if (entry.value == apiValue) return entry.key;
    }
    return null;
  }
}

/// State for the Naam Welcome + 8-Step Onboarding Wizard.
@immutable
class OnboardingFlowState {
  const OnboardingFlowState({
    this.step = 0,
    this.isSubmitting = false,
    this.isUploadingPhotos = false,
    this.isLocating = false,
    this.errorMessage,
    this.countryCode = '+91',
    this.phoneNumber = '',
    this.otp = '',
    this.sessionId,
    this.firstName = '',
    this.dateOfBirth,
    this.gender,
    this.genderDetail = '',
    this.showGenderOnProfile = true,
    this.lookingFor,
    this.photos = const [],
    this.city,
    this.latitude,
    this.longitude,
    this.distanceKm = 25,
    this.selfieConsent = false,
  });

  static const int maxPhotos = 6;

  /// `0` = Welcome screen, `1..8` = Steps `01/08` to `08/08`.
  final int step;
  final bool isSubmitting;
  final bool isUploadingPhotos;
  final bool isLocating;
  final String? errorMessage;
  final String countryCode;
  final String phoneNumber;
  final String otp;
  final String? sessionId;
  final String firstName;
  final DateTime? dateOfBirth;

  /// UI label: `Woman` | `Man` | `Non-binary`.
  final String? gender;
  final String genderDetail;
  final bool showGenderOnProfile;

  /// UI label from [OnboardingOptions.relationshipGoals].
  final String? lookingFor;

  /// Uploaded gallery URLs.
  final List<String> photos;
  final String? city;
  final double? latitude;
  final double? longitude;
  final int distanceKm;
  final bool selfieConsent;

  bool get isBusy => isSubmitting || isUploadingPhotos || isLocating;

  String get phoneDigits => phoneNumber.replaceAll(RegExp(r'\D'), '');

  int? get age {
    final dob = dateOfBirth;
    if (dob == null) return null;
    final now = DateTime.now();
    var years = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      years--;
    }
    return years;
  }

  String get maskedPhone {
    final digits = phoneDigits;
    final lastFour =
        digits.length >= 4 ? digits.substring(digits.length - 4) : digits;
    return '$countryCode ••••• •$lastFour';
  }

  OnboardingFlowState copyWith({
    int? step,
    bool? isSubmitting,
    bool? isUploadingPhotos,
    bool? isLocating,
    String? errorMessage,
    bool clearError = false,
    String? countryCode,
    String? phoneNumber,
    String? otp,
    Object? sessionId = _unset,
    String? firstName,
    Object? dateOfBirth = _unset,
    Object? gender = _unset,
    String? genderDetail,
    bool? showGenderOnProfile,
    Object? lookingFor = _unset,
    List<String>? photos,
    Object? city = _unset,
    Object? latitude = _unset,
    Object? longitude = _unset,
    int? distanceKm,
    bool? selfieConsent,
  }) {
    return OnboardingFlowState(
      step: step ?? this.step,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isUploadingPhotos: isUploadingPhotos ?? this.isUploadingPhotos,
      isLocating: isLocating ?? this.isLocating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      countryCode: countryCode ?? this.countryCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      otp: otp ?? this.otp,
      sessionId:
          identical(sessionId, _unset) ? this.sessionId : sessionId as String?,
      firstName: firstName ?? this.firstName,
      dateOfBirth: identical(dateOfBirth, _unset)
          ? this.dateOfBirth
          : dateOfBirth as DateTime?,
      gender: identical(gender, _unset) ? this.gender : gender as String?,
      genderDetail: genderDetail ?? this.genderDetail,
      showGenderOnProfile: showGenderOnProfile ?? this.showGenderOnProfile,
      lookingFor: identical(lookingFor, _unset)
          ? this.lookingFor
          : lookingFor as String?,
      photos: photos ?? this.photos,
      city: identical(city, _unset) ? this.city : city as String?,
      latitude:
          identical(latitude, _unset) ? this.latitude : latitude as double?,
      longitude:
          identical(longitude, _unset) ? this.longitude : longitude as double?,
      distanceKm: distanceKm ?? this.distanceKm,
      selfieConsent: selfieConsent ?? this.selfieConsent,
    );
  }
}

class OnboardingFlowNotifier extends AutoDisposeNotifier<OnboardingFlowState> {
  final ImagePicker _imagePicker = ImagePicker();

  OnboardingRepository get _repo => ref.read(onboardingRepositoryProvider);

  @override
  OnboardingFlowState build() {
    return const OnboardingFlowState();
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  void goToStep(int targetStep) {
    state = state.copyWith(step: targetStep.clamp(0, 8), clearError: true);
  }

  void previousStep() {
    if (state.isBusy) return;
    switch (state.step) {
      case 0:
        return;
      case 3:
        // Basic info is the first post-OTP page; going back means re-login.
        goToStep(1);
      default:
        goToStep(state.step - 1);
    }
  }

  /// Maps the server's `nextStep` to the UI step index.
  static int _uiStepFor(OnboardingApiStep? step) {
    switch (step) {
      case OnboardingApiStep.basicInfo:
      case null:
        return 3;
      case OnboardingApiStep.relationshipGoal:
        return 5;
      case OnboardingApiStep.photos:
        return 6;
      case OnboardingApiStep.location:
        return 7;
      case OnboardingApiStep.verification:
        return 8;
    }
  }

  // ---------------------------------------------------------------------------
  // Field updates
  // ---------------------------------------------------------------------------

  void updatePhone(String value) {
    state = state.copyWith(phoneNumber: value, clearError: true);
  }

  void cycleCountryCode() {
    const codes = ['+91', '+971', '+44', '+1'];
    final idx = codes.indexOf(state.countryCode);
    final next = codes[(idx + 1) % codes.length];
    state = state.copyWith(countryCode: next);
  }

  void updateOtp(String value) {
    state = state.copyWith(otp: value, clearError: true);
  }

  void updateFirstName(String value) {
    state = state.copyWith(firstName: value, clearError: true);
  }

  void updateDob(DateTime date) {
    state = state.copyWith(dateOfBirth: date, clearError: true);
  }

  void selectGender(String gender) {
    state = state.copyWith(gender: gender, genderDetail: '', clearError: true);
  }

  void setGenderDetail(String detail) {
    state = state.copyWith(genderDetail: detail);
  }

  void toggleShowGender(bool value) {
    state = state.copyWith(showGenderOnProfile: value);
  }

  void selectLookingFor(String option) {
    state = state.copyWith(lookingFor: option, clearError: true);
  }

  void selectCity(CityOption city) {
    state = state.copyWith(
      city: city.label,
      latitude: city.latitude,
      longitude: city.longitude,
      clearError: true,
    );
  }

  void updateDistance(int km) {
    state = state.copyWith(distanceKm: km.clamp(5, 100));
  }

  void toggleSelfieConsent() {
    state = state.copyWith(selfieConsent: !state.selfieConsent);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // ---------------------------------------------------------------------------
  // Photos
  // ---------------------------------------------------------------------------

  Future<void> pickAndUploadPhotos() async {
    final sessionId = state.sessionId;
    final remaining = OnboardingFlowState.maxPhotos - state.photos.length;
    if (sessionId == null || remaining <= 0 || state.isBusy) return;

    List<XFile> picked;
    try {
      if (remaining == 1) {
        final single = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1600,
          imageQuality: 85,
        );
        picked = single == null ? const [] : [single];
      } else {
        picked = await _imagePicker.pickMultiImage(
          maxWidth: 1600,
          imageQuality: 85,
          limit: remaining,
        );
      }
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Could not open your photos. Check gallery permissions.',
      );
      return;
    }
    if (picked.isEmpty) return;
    if (picked.length > remaining) picked = picked.sublist(0, remaining);

    state = state.copyWith(isUploadingPhotos: true, clearError: true);
    try {
      final urls = await _repo.uploadImages(
        sessionId: sessionId,
        type: UploadImageType.gallery,
        files: [
          for (final file in picked)
            UploadFile(path: file.path, mimeType: _mimeTypeFor(file)),
        ],
      );
      state = state.copyWith(
        isUploadingPhotos: false,
        photos: [...state.photos, ...urls].take(OnboardingFlowState.maxPhotos)
            .toList(),
      );
    } on ApiException catch (e) {
      state = state.copyWith(isUploadingPhotos: false, errorMessage: e.message);
    }
  }

  void removePhoto(int index) {
    final updated = List<String>.from(state.photos)..removeAt(index);
    state = state.copyWith(photos: updated, clearError: true);
  }

  void makeMainPhoto(int index) {
    final updated = List<String>.from(state.photos);
    final photo = updated.removeAt(index);
    updated.insert(0, photo);
    state = state.copyWith(photos: updated);
  }

  static String _mimeTypeFor(XFile file) {
    final fromPicker = file.mimeType;
    if (fromPicker != null && fromPicker.startsWith('image/')) {
      return fromPicker;
    }
    final lower = file.path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heic';
    return 'image/jpeg';
  }

  // ---------------------------------------------------------------------------
  // Location
  // ---------------------------------------------------------------------------

  Future<void> useCurrentLocation() async {
    if (state.isBusy) return;
    state = state.copyWith(isLocating: true, clearError: true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const ApiException(
          'Location services are off. Turn them on or choose your city.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const ApiException(
          'Location permission was denied. Choose your city instead.',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 15),
        ),
      );
      String? placeName;
      try {
        placeName = await ref
            .read(mapboxGeocodingProvider)
            .reverse(position.latitude, position.longitude);
      } on ApiException {
        // Name lookup is best-effort; the coordinates are what matter.
      }
      state = state.copyWith(
        isLocating: false,
        city: placeName ?? 'Current location',
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLocating: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLocating: false,
        errorMessage: 'Could not get your location. Choose your city instead.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // API-backed submission
  // ---------------------------------------------------------------------------

  /// Submits the current step. Returns `true` when onboarding is finished and
  /// the user is signed in (caller should navigate into the app).
  ///
  /// Step 8 (selfie) is handled by [submitVerification].
  Future<bool> submitCurrentStep() async {
    if (state.isBusy) return false;
    switch (state.step) {
      case 0:
        goToStep(1);
        return false;
      case 1:
        return _run(_sendOtp);
      case 2:
        return _run(_verifyOtp);
      case 3:
        _validateAboutYou();
        return false;
      case 4:
        return _run(_saveBasicInfo);
      case 5:
        return _run(_saveRelationshipGoal);
      case 6:
        return _run(_savePhotos);
      case 7:
        return _run(_saveLocation);
      default:
        return false;
    }
  }

  /// Re-sends the OTP. Returns `true` on success.
  Future<bool> resendOtp() async {
    if (state.isBusy) return false;
    state = state.copyWith(isSubmitting: true, clearError: true, otp: '');
    try {
      await _repo.sendOtp(
        countryCode: state.countryCode,
        phoneNumber: state.phoneDigits,
      );
      state = state.copyWith(isSubmitting: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.message);
      return false;
    }
  }

  /// Uploads the auto-captured selfie, saves VERIFICATION and completes
  /// onboarding. Returns `true` when the user is signed in.
  Future<bool> submitVerification(String imagePath) {
    return _run(() async {
      final sessionId = _requireSession();
      final urls = await _repo.uploadImages(
        sessionId: sessionId,
        type: UploadImageType.verification,
        files: [UploadFile(path: imagePath)],
      );
      if (urls.isEmpty) {
        throw const ApiException('Selfie upload failed. Please try again.');
      }
      await _repo.saveStep(
        sessionId: sessionId,
        step: OnboardingApiStep.verification,
        fields: {'verificationImages': urls},
      );
      return _complete(sessionId);
    });
  }

  /// Wraps an API action with loading + error state.
  Future<bool> _run(Future<bool> Function() action) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final finished = await action();
      state = state.copyWith(isSubmitting: false);
      return finished;
    } on ApiException catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.message);
      return false;
    }
  }

  String _requireSession() {
    final sessionId = state.sessionId;
    if (sessionId == null) {
      throw const ApiException(
        'Your session has expired. Please verify your number again.',
      );
    }
    return sessionId;
  }

  Future<bool> _sendOtp() async {
    final digits = state.phoneDigits;
    if (digits.length < 7 || digits.length > 15) {
      throw const ApiException('Enter a valid mobile number.');
    }
    await _repo.sendOtp(countryCode: state.countryCode, phoneNumber: digits);
    state = state.copyWith(step: 2, otp: '');
    return false;
  }

  Future<bool> _verifyOtp() async {
    if (state.otp.length != 6) {
      throw const ApiException('Enter the 6-digit code.');
    }
    final VerifyOtpResult result;
    try {
      result = await _repo.verifyOtp(
        phoneNumber: state.phoneDigits,
        otp: state.otp,
      );
    } on ApiException {
      // Clear the boxes so the user can retype straight away.
      state = state.copyWith(otp: '');
      rethrow;
    }

    // Existing user with a completed profile → signed in.
    final token = result.accessToken;
    if (!result.isNewUser && token != null) {
      await ref
          .read(authStorageProvider)
          .saveSession(accessToken: token, user: result.user);
      return true;
    }

    final onboarding = result.onboarding;
    final sessionId = result.sessionId ?? onboarding?.sessionId;
    if (sessionId == null) {
      throw const ApiException('Could not start onboarding. Please try again.');
    }
    state = state.copyWith(sessionId: sessionId);

    if (onboarding != null) {
      _prefill(onboarding.data);
      if (onboarding.nextStep == null && onboarding.canComplete) {
        return _complete(sessionId);
      }
    }
    state = state.copyWith(step: _uiStepFor(onboarding?.nextStep));
    return false;
  }

  /// Restores anything the user already submitted in a previous session.
  void _prefill(OnboardingData data) {
    final matchedCity = OnboardingOptions.cities.where(
      (c) => c.latitude == data.latitude && c.longitude == data.longitude,
    );
    final hasLocation = data.latitude != null && data.longitude != null;

    state = state.copyWith(
      firstName: data.name ?? state.firstName,
      dateOfBirth: data.dateOfBirth ?? state.dateOfBirth,
      gender: OnboardingOptions.labelFor(OnboardingOptions.genders, data.gender) ??
          state.gender,
      showGenderOnProfile: data.showGenderOnProfile ?? state.showGenderOnProfile,
      lookingFor: OnboardingOptions.labelFor(
            OnboardingOptions.relationshipGoals,
            data.relationshipGoal,
          ) ??
          state.lookingFor,
      photos: data.photos.isNotEmpty ? data.photos : state.photos,
      city: hasLocation
          ? (matchedCity.isNotEmpty
              ? matchedCity.first.label
              : 'Saved location')
          : state.city,
      latitude: data.latitude ?? state.latitude,
      longitude: data.longitude ?? state.longitude,
      distanceKm: data.preferredDistanceKm?.clamp(5, 100) ?? state.distanceKm,
    );
  }

  bool _validateAboutYou() {
    String? error;
    final age = state.age;
    if (state.firstName.trim().isEmpty) {
      error = 'Please enter your first name.';
    } else if (age == null) {
      error = 'Please add your date of birth.';
    } else if (age < 18) {
      error = 'You must be 18 or older to use naam.';
    }
    if (error != null) {
      state = state.copyWith(errorMessage: error);
      return false;
    }
    goToStep(4);
    return true;
  }

  Future<bool> _saveBasicInfo() async {
    final sessionId = _requireSession();
    final dob = state.dateOfBirth;
    final gender = OnboardingOptions.genders[state.gender];
    if (state.firstName.trim().isEmpty || dob == null) {
      state = state.copyWith(step: 3);
      throw const ApiException('Please complete your name and birthday.');
    }
    if (gender == null) {
      throw const ApiException('Please choose your gender.');
    }
    await _repo.saveStep(
      sessionId: sessionId,
      step: OnboardingApiStep.basicInfo,
      fields: {
        'name': state.firstName.trim(),
        'dateOfBirth': _isoDate(dob),
        'gender': gender,
        'showGenderOnProfile': state.showGenderOnProfile,
      },
    );
    state = state.copyWith(step: 5);
    return false;
  }

  Future<bool> _saveRelationshipGoal() async {
    final sessionId = _requireSession();
    final goal = OnboardingOptions.relationshipGoals[state.lookingFor];
    if (goal == null) {
      throw const ApiException('Please choose what you\'re looking for.');
    }
    await _repo.saveStep(
      sessionId: sessionId,
      step: OnboardingApiStep.relationshipGoal,
      fields: {'relationshipGoal': goal},
    );
    state = state.copyWith(step: 6);
    return false;
  }

  Future<bool> _savePhotos() async {
    final sessionId = _requireSession();
    await _repo.saveStep(
      sessionId: sessionId,
      step: OnboardingApiStep.photos,
      fields: {'photos': state.photos},
    );
    state = state.copyWith(step: 7);
    return false;
  }

  Future<bool> _saveLocation() async {
    final sessionId = _requireSession();
    final lat = state.latitude;
    final lng = state.longitude;
    if (lat == null || lng == null) {
      throw const ApiException(
        'Use your current location or choose a city to continue.',
      );
    }
    await _repo.saveStep(
      sessionId: sessionId,
      step: OnboardingApiStep.location,
      fields: {
        'latitude': lat,
        'longitude': lng,
        'preferredDistanceKm': state.distanceKm,
      },
    );
    state = state.copyWith(step: 8);
    return false;
  }

  Future<bool> _complete(String sessionId) async {
    final result = await _repo.complete(sessionId: sessionId);
    await ref
        .read(authStorageProvider)
        .saveSession(accessToken: result.accessToken, user: result.user);
    return true;
  }

  static String _isoDate(DateTime date) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-${two(date.month)}-${two(date.day)}';
  }
}

final onboardingFlowProvider =
    NotifierProvider.autoDispose<OnboardingFlowNotifier, OnboardingFlowState>(
  OnboardingFlowNotifier.new,
);

/// Complete Welcome + 8-Step Onboarding Screen (`01/08` through `08/08`).
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(onboardingFlowProvider.notifier);
    final state = ref.read(onboardingFlowProvider);
    if (state.isBusy) return;

    final bool finished;
    if (state.step == 8) {
      final imagePath = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const SelfieCaptureScreen(),
        ),
      );
      if (imagePath == null) return;
      finished = await notifier.submitVerification(imagePath);
    } else {
      finished = await notifier.submitCurrentStep();
    }

    if (finished && context.mounted) {
      context.go(AppRoutes.discover);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingFlowProvider);
    final notifier = ref.read(onboardingFlowProvider.notifier);

    if (state.step == 0) {
      return _WelcomeStepView(
        onStart: () => notifier.goToStep(1),
        onLogin: () => notifier.goToStep(1),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) notifier.previousStep();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _OnboardingTopHeader(
                  step: state.step,
                  onBack: notifier.previousStep,
                ),
                const SizedBox(height: 14),
                _OnboardingProgressSegments(currentStep: state.step),
                const SizedBox(height: 24),
                Expanded(
                  child: _OnboardingStepBodySwitcher(
                    state: state,
                    onSubmit: () => _submit(context, ref),
                  ),
                ),
                _OnboardingStepBottomFooter(
                  state: state,
                  onContinue: () => _submit(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeStepView extends StatelessWidget {
  const _WelcomeStepView({
    required this.onStart,
    required this.onLogin,
  });

  final VoidCallback onStart;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 62,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: const Color(0xFF0A66C2),
                ),
                Positioned(
                  top: 56,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Image.asset(
                      "assets/images/naam_logo.png",
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 38,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text(
                        'Someone new.\nSomething familiar.',
                        textAlign: TextAlign.center,
                        style: textTheme.displayMedium?.copyWith(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1C1C1E),
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Meet Malayali singles who get you.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 15.5,
                          color: const Color(0xFF6E6E73),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: JDateTokens.brandRose,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            elevation: 0,
                          ),
                          onPressed: onStart,
                          child: const Text(
                            "Let's begin",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already here? ',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF6E6E73),
                            ),
                          ),
                          GestureDetector(
                            onTap: onLogin,
                            child: const Text(
                              'Log in',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: JDateTokens.brandRose,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Text(
                    'For adults 18+ · By continuing, you agree to our Terms and Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF8E8E93),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingTopHeader extends StatelessWidget {
  const _OnboardingTopHeader({
    required this.step,
    required this.onBack,
  });

  final int step;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF2C2C2E),
            size: 22,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        Image.asset(
          "assets/images/naam_logo.png",
          height: 22,
          fit: BoxFit.contain,
        ),
        SizedBox(
          width: 52,
          child: Text(
            '0$step / 08',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6E6E73),
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingProgressSegments extends StatelessWidget {
  const _OnboardingProgressSegments({
    required this.currentStep,
  });

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(8, (index) {
        final seg = index + 1;
        final Color color;
        if (seg < currentStep) {
          color = const Color(0xFF6E6E73);
        } else if (seg == currentStep) {
          color = JDateTokens.brandRose;
        } else {
          color = const Color(0xFFE5E5EA);
        }

        return Expanded(
          child: Container(
            height: 3.5,
            margin: EdgeInsets.only(right: index < 7 ? 6 : 0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}

class _OnboardingStepBodySwitcher extends ConsumerWidget {
  const _OnboardingStepBodySwitcher({
    required this.state,
    required this.onSubmit,
  });

  final OnboardingFlowState state;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (state.step) {
      case 1:
        return _StepOnePhoneView(state: state);
      case 2:
        return _StepTwoOtpView(state: state, onCompleted: onSubmit);
      case 3:
        return _StepThreeAboutYouView(state: state);
      case 4:
        return _StepFourGenderView(state: state);
      case 5:
        return _StepFiveLookingForView(state: state);
      case 6:
        return _StepSixPhotosView(state: state);
      case 7:
        return _StepSevenLocationView(state: state);
      case 8:
      default:
        return _StepEightSelfieVerifyView(state: state);
    }
  }
}

class _StepOnePhoneView extends ConsumerStatefulWidget {
  const _StepOnePhoneView({required this.state});

  final OnboardingFlowState state;

  @override
  ConsumerState<_StepOnePhoneView> createState() => _StepOnePhoneViewState();
}

class _StepOnePhoneViewState extends ConsumerState<_StepOnePhoneView> {
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.state.phoneNumber);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(onboardingFlowProvider.notifier);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your number?',
            style: TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1C1C1E),
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "We'll send a one-time code to this number.",
            style: TextStyle(
              fontSize: 15.5,
              color: Color(0xFF6E6E73),
            ),
          ),
          const SizedBox(height: 26),
          const Text(
            'Mobile number',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE4E4E7)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: notifier.cycleCountryCode,
                  child: Row(
                    children: [
                      Text(
                        widget.state.countryCode,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: JDateTokens.brandRose,
                        size: 18,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1.5,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: JDateTokens.brandRose,
                ),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumberNational],
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(15),
                    ],
                    onChanged: notifier.updatePhone,
                    decoration: const InputDecoration(
                      hintText: '98765 43210',
                      hintStyle: TextStyle(color: Color(0xFFB0B0B5)),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      isCollapsed: true,
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: Color(0xFF8E8E93),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Your number stays private. It's only for sign-in and verification.",
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF6E6E73),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepTwoOtpView extends ConsumerStatefulWidget {
  const _StepTwoOtpView({required this.state, required this.onCompleted});

  final OnboardingFlowState state;

  /// Called once all 6 digits are entered.
  final VoidCallback onCompleted;

  @override
  ConsumerState<_StepTwoOtpView> createState() => _StepTwoOtpViewState();
}

class _StepTwoOtpViewState extends ConsumerState<_StepTwoOtpView> {
  late final TextEditingController _otpController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController(text: widget.state.otp);
  }

  @override
  void didUpdateWidget(covariant _StepTwoOtpView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the field in sync when the notifier clears the code (e.g. resend).
    if (widget.state.otp != _otpController.text) {
      _otpController.text = widget.state.otp;
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    ref.read(onboardingFlowProvider.notifier).updateOtp(value);
    if (value.length == 6) {
      _focusNode.unfocus();
      widget.onCompleted();
    }
  }

  Future<void> _resend() async {
    final sent = await ref.read(onboardingFlowProvider.notifier).resendOtp();
    if (!mounted || !sent) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('A new code is on its way.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final notifier = ref.read(onboardingFlowProvider.notifier);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter your code',
            style: TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1C1C1E),
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We sent a 6-digit code on WhatsApp.',
            style: TextStyle(
              fontSize: 15.5,
              color: Color(0xFF6E6E73),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                state.maskedPhone,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              GestureDetector(
                onTap: state.isBusy ? null : () => notifier.goToStep(1),
                child: const Text(
                  'Change number',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: JDateTokens.brandRose,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Verification code',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 60,
            child: Stack(
              children: [
                Row(
                  children: List.generate(6, (index) {
                    final otp = state.otp;
                    final digit = index < otp.length ? otp[index] : '';
                    final isCursor = index == otp.length;
                    return Expanded(
                      child: Container(
                        height: 60,
                        margin: EdgeInsets.only(right: index < 5 ? 8 : 0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCursor
                                ? JDateTokens.brandRose
                                : const Color(0xFFE4E4E7),
                            width: isCursor ? 1.5 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          digit.isEmpty ? (isCursor ? '|' : '–') : digit,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: digit.isEmpty
                                ? JDateTokens.brandRose
                                : const Color(0xFF1C1C1E),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                // Invisible input on top of the boxes: captures taps, typing,
                // paste and SMS/WhatsApp one-time-code autofill.
                Positioned.fill(
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: _otpController,
                      focusNode: _focusNode,
                      autofocus: true,
                      enabled: !state.isSubmitting,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      showCursor: false,
                      enableInteractiveSelection: false,
                      onChanged: _onChanged,
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Text(
                "Didn't get the code? ",
                style: TextStyle(
                  fontSize: 14.5,
                  color: Color(0xFF6E6E73),
                ),
              ),
              GestureDetector(
                onTap: state.isBusy ? null : _resend,
                child: const Text(
                  'Resend code',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: JDateTokens.brandRose,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepThreeAboutYouView extends ConsumerStatefulWidget {
  const _StepThreeAboutYouView({required this.state});

  final OnboardingFlowState state;

  @override
  ConsumerState<_StepThreeAboutYouView> createState() =>
      _StepThreeAboutYouViewState();
}

class _StepThreeAboutYouViewState
    extends ConsumerState<_StepThreeAboutYouView> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.state.firstName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final latestAllowed = DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.state.dateOfBirth ??
          DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: latestAllowed,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Your date of birth',
    );
    if (picked != null) {
      ref.read(onboardingFlowProvider.notifier).updateDob(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(onboardingFlowProvider.notifier);
    final dob = widget.state.dateOfBirth;
    final age = widget.state.age;
    String two(int v) => v.toString().padLeft(2, '0');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'A little about you',
            style: TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1C1C1E),
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Let's start with your name and birthday.",
            style: TextStyle(
              fontSize: 15.5,
              color: Color(0xFF6E6E73),
            ),
          ),
          const SizedBox(height: 26),
          const Text(
            'First name',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE4E4E7)),
            ),
            alignment: Alignment.centerLeft,
            child: TextField(
              controller: _nameController,
              onChanged: notifier.updateFirstName,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.givenName],
              decoration: const InputDecoration(
                hintText: 'Your first name',
                hintStyle: TextStyle(color: Color(0xFFB0B0B5)),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isCollapsed: true,
              ),
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF1C1C1E),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Date of birth',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _pickDob,
            child: Row(
              children: [
                Expanded(
                  child: _DobFieldCard(
                    label: 'Day',
                    value: dob == null ? 'DD' : two(dob.day),
                    isPlaceholder: dob == null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DobFieldCard(
                    label: 'Month',
                    value: dob == null ? 'MM' : two(dob.month),
                    isPlaceholder: dob == null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DobFieldCard(
                    label: 'Year',
                    value: dob == null ? 'YYYY' : '${dob.year}',
                    isPlaceholder: dob == null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F5),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              age == null ? 'Tap above to add your birthday' : "You're $age years old",
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1C1E),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: JDateTokens.brandRose,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Only your age appears on your profile—not your birthday.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF6E6E73),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DobFieldCard extends StatelessWidget {
  const _DobFieldCard({
    required this.label,
    required this.value,
    this.isPlaceholder = false,
  });

  final String label;
  final String value;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6E6E73),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isPlaceholder
                  ? const Color(0xFFB0B0B5)
                  : const Color(0xFF1C1C1E),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepFourGenderView extends ConsumerWidget {
  const _StepFourGenderView({required this.state});

  final OnboardingFlowState state;

  static const Map<String, List<String>> _details = {
    'Woman': ['Cis woman', 'Trans woman'],
    'Man': ['Cis man', 'Trans man'],
    'Non-binary': ['Agender', 'Genderfluid', 'Genderqueer'],
  };

  Future<void> _pickDetail(
    BuildContext context,
    OnboardingFlowNotifier notifier,
    String gender,
  ) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add more detail',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            for (final detail in _details[gender] ?? const <String>[])
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(detail),
                trailing: state.genderDetail == detail
                    ? const Icon(Icons.check_rounded,
                        color: JDateTokens.brandRose)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(detail),
              ),
            if (state.genderDetail.isNotEmpty)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: const Text('Remove detail'),
                onTap: () => Navigator.of(sheetContext).pop(''),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice != null) notifier.setGenderDetail(choice);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onboardingFlowProvider.notifier);
    const options = ['Woman', 'Man', 'Non-binary'];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your gender',
            style: TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1C1C1E),
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose what feels right for you.',
            style: TextStyle(
              fontSize: 15.5,
              color: Color(0xFF6E6E73),
            ),
          ),
          const SizedBox(height: 24),
          ...options.map((option) {
            final isSelected = state.gender == option;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => notifier.selectGender(option),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? JDateTokens.brandRose
                          : const Color(0xFFE4E4E7),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            option,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1C1C1E),
                            ),
                          ),
                          _RadioCircleIndicator(isSelected: isSelected),
                        ],
                      ),
                      if (isSelected) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: Color(0xFFF1F1F4)),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _pickDetail(context, notifier, option),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: SizedBox(
                              width: double.infinity,
                              child: Text(
                                state.genderDetail.isEmpty
                                    ? '+  Add more detail'
                                    : '+  Detail: ${state.genderDetail}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: JDateTokens.brandRose,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Show gender on my profile',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              Switch(
                value: state.showGenderOnProfile,
                activeThumbColor: Colors.white,
                activeTrackColor: JDateTokens.brandRose,
                onChanged: notifier.toggleShowGender,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepFiveLookingForView extends ConsumerWidget {
  const _StepFiveLookingForView({required this.state});

  final OnboardingFlowState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onboardingFlowProvider.notifier);
    const options = [
      'Open-minded relationship',
      'Serious relationship',
      'Casual',
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Looking for...',
            style: TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1C1C1E),
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose the connection you want.',
            style: TextStyle(
              fontSize: 15.5,
              color: Color(0xFF6E6E73),
            ),
          ),
          const SizedBox(height: 24),
          ...options.map((option) {
            final isSelected = state.lookingFor == option;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => notifier.selectLookingFor(option),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? JDateTokens.brandRose
                          : const Color(0xFFE4E4E7),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        option,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                      _RadioCircleIndicator(isSelected: isSelected),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StepSixPhotosView extends ConsumerWidget {
  const _StepSixPhotosView({required this.state});

  final OnboardingFlowState state;

  Future<void> _showPhotoActions(
    BuildContext context,
    OnboardingFlowNotifier notifier,
    int index,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (index != 0)
                ListTile(
                  leading: const Icon(Icons.star_outline_rounded),
                  title: const Text('Make main photo'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    notifier.makeMainPhoto(index);
                  },
                ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFD70015),
                ),
                title: const Text(
                  'Remove photo',
                  style: TextStyle(color: Color(0xFFD70015)),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  notifier.removePhoto(index);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onboardingFlowProvider.notifier);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add your photos',
            style: TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1C1C1E),
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap a photo to remove it or make it your main photo.',
            style: TextStyle(
              fontSize: 15.5,
              color: Color(0xFF6E6E73),
            ),
          ),
          const SizedBox(height: 22),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: OnboardingFlowState.maxPhotos,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.74,
            ),
            itemBuilder: (context, index) {
              final hasPhoto = index < state.photos.length;
              if (hasPhoto) {
                return GestureDetector(
                  onTap: state.isBusy
                      ? null
                      : () => _showPhotoActions(context, notifier, index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          state.photos[index],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) =>
                              progress == null
                                  ? child
                                  : const ColoredBox(
                                      color: Color(0xFFF4F4F5),
                                      child: Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: JDateTokens.brandRose,
                                          ),
                                        ),
                                      ),
                                    ),
                          errorBuilder: (context, error, stackTrace) =>
                              const ColoredBox(
                            color: Color(0xFFF4F4F5),
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              size: 15,
                              color: Color(0xFF1C1C1E),
                            ),
                          ),
                        ),
                        if (index == 0)
                          Positioned(
                            left: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Main photo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }

              final isUploadSlot =
                  state.isUploadingPhotos && index == state.photos.length;
              return GestureDetector(
                onTap: state.isBusy ? null : notifier.pickAndUploadPhotos,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF7F8),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF0D6DF)),
                  ),
                  child: isUploadSlot
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: JDateTokens.brandRose,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Uploading…',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6E6E73),
                              ),
                            ),
                          ],
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              color: JDateTokens.brandRose,
                              size: 22,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Add photo',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6E6E73),
                              ),
                            ),
                          ],
                        ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 18,
                color: JDateTokens.brandRose,
              ),
              const SizedBox(width: 8),
              Text(
                '${state.photos.length} of ${OnboardingFlowState.maxPhotos} added',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF3A3A3C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 18,
                color: JDateTokens.brandRose,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Add 2–6 recent photos. A clear face photo first.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF6E6E73),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepSevenLocationView extends ConsumerWidget {
  const _StepSevenLocationView({required this.state});

  final OnboardingFlowState state;

  Future<void> _pickCity(
    BuildContext context,
    OnboardingFlowNotifier notifier,
  ) async {
    final picked = await showModalBottomSheet<CityOption>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          const CitySearchSheet(suggestions: OnboardingOptions.cities),
    );
    if (picked != null) notifier.selectCity(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onboardingFlowProvider.notifier);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find people nearby',
            style: TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1C1C1E),
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose your city and distance.',
            style: TextStyle(
              fontSize: 15.5,
              color: Color(0xFF6E6E73),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: state.isBusy ? null : notifier.useCurrentLocation,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFF7BFD4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (state.isLocating)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: JDateTokens.brandRose,
                      ),
                    )
                  else
                    const Icon(
                      Icons.my_location_rounded,
                      size: 18,
                      color: JDateTokens.brandRose,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    state.isLocating
                        ? 'Finding your location…'
                        : 'Use my current city',
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: JDateTokens.brandRose,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Or choose your city',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6E6E73),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: state.isBusy ? null : () => _pickCity(context, notifier),
            child: Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE4E4E7)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 19,
                        color: Color(0xFF8E8E93),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        state.city ?? 'Select your city',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w500,
                          color: state.city == null
                              ? const Color(0xFFB0B0B5)
                              : const Color(0xFF1C1C1E),
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF8E8E93),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Preferred distance',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    Text(
                      '${state.distanceKm} km',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: state.distanceKm.toDouble(),
                  min: 5,
                  max: 100,
                  activeColor: JDateTokens.brandRose,
                  onChanged: (v) => notifier.updateDistance(v.round()),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '5 km',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF8E8E93)),
                    ),
                    Text(
                      '100 km',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF8E8E93)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: Color(0xFF8E8E93),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Only your approximate city is shown. Your distance preference stays private.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF6E6E73),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepEightSelfieVerifyView extends ConsumerWidget {
  const _StepEightSelfieVerifyView({required this.state});

  final OnboardingFlowState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onboardingFlowProvider.notifier);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Let's verify it's you",
            style: TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1C1C1E),
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'A quick selfie helps confirm your identity.',
            style: TextStyle(
              fontSize: 15.5,
              color: Color(0xFF6E6E73),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F5),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.face_retouching_natural_rounded,
                  size: 46,
                  color: Color(0xFF71717A),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Just you, clearly.',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Centre your whole face inside the guide.',
                        style: TextStyle(
                          fontSize: 14.5,
                          color: Color(0xFF6E6E73),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _SelfieChecklistRow(
            icon: Icons.wb_sunny_outlined,
            text: 'Good light. Face clear and in focus.',
          ),
          const SizedBox(height: 16),
          const _SelfieChecklistRow(
            icon: Icons.person_outline_rounded,
            text: 'No sunglasses, masks, filters or other people.',
          ),
          const SizedBox(height: 16),
          const _SelfieChecklistRow(
            icon: Icons.lock_outline_rounded,
            text:
                "We compare your selfie with your photos. It won't appear on your profile.",
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, color: Color(0xFFEFEFF4)),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: notifier.toggleSelfieConsent,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: state.selfieConsent
                        ? JDateTokens.brandRose
                        : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: state.selfieConsent
                          ? JDateTokens.brandRose
                          : const Color(0xFFD4D4D8),
                    ),
                  ),
                  child: state.selfieConsent
                      ? const Icon(Icons.check, size: 15, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'I agree to naam using my selfie and profile photos for this identity check, as described in the Privacy Policy.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF3A3A3C),
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Read the Privacy Policy',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: JDateTokens.brandRose,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelfieChecklistRow extends StatelessWidget {
  const _SelfieChecklistRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF8E8E93)),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14.5,
              color: Color(0xFF1C1C1E),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _RadioCircleIndicator extends StatelessWidget {
  const _RadioCircleIndicator({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? JDateTokens.brandRose : Colors.white,
        border: Border.all(
          color: isSelected ? JDateTokens.brandRose : const Color(0xFFE4E4E7),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: isSelected
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            )
          : null,
    );
  }
}

class _OnboardingStepBottomFooter extends StatelessWidget {
  const _OnboardingStepBottomFooter({
    required this.state,
    required this.onContinue,
  });

  final OnboardingFlowState state;
  final VoidCallback onContinue;

  String? get _footerNote {
    switch (state.step) {
      case 3:
        return 'naam is for adults aged 18 and over.';
      case 4:
      case 5:
        return 'You can change this anytime in your profile.';
      case 8:
        return 'Your phone will ask for camera access next.';
      default:
        return null;
    }
  }

  String get _buttonLabel {
    if (state.isSubmitting) {
      switch (state.step) {
        case 1:
          return 'Sending code…';
        case 2:
          return 'Verifying…';
        case 8:
          return 'Verifying your selfie…';
        default:
          return 'Saving…';
      }
    }
    switch (state.step) {
      case 1:
        return 'Send code';
      case 2:
        return 'Verify & continue';
      case 6:
        if (state.photos.isEmpty) return 'Skip for now';
        return state.photos.length == 1
            ? 'Continue with 1 photo'
            : 'Continue with ${state.photos.length} photos';
      case 8:
        return 'Capture selfie';
      default:
        return 'Continue';
    }
  }

  @override
  Widget build(BuildContext context) {
    final note = _footerNote;
    final error = state.errorMessage;
    final isDisabled =
        state.isBusy || (state.step == 8 && !state.selfieConsent);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (error != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 18,
                  color: Color(0xFFD70015),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFFD70015),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ] else if (note != null) ...[
          Text(
            note,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF6E6E73),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: JDateTokens.brandRose,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  JDateTokens.brandRose.withValues(alpha: 0.45),
              disabledForegroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 26),
              elevation: 0,
            ),
            onPressed: isDisabled ? null : onContinue,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _buttonLabel,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (state.isSubmitting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                else
                  const Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
