// FILE: lib/features/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';

/// State for the Naam Welcome + 8-Step Onboarding Wizard.
@immutable
class OnboardingFlowState {
  const OnboardingFlowState({
    this.step = 0,
    this.isLoading = false,
    this.errorMessage,
    this.countryCode = '+91',
    this.phoneNumber = '98765 43210',
    this.otpDigits = const ['', '', '', '', '', ''],
    this.firstName = 'Anjali',
    this.dobDay = '14',
    this.dobMonth = '06',
    this.dobYear = '1998',
    this.gender = 'Woman',
    this.genderDetail = '',
    this.showGenderOnProfile = true,
    this.lookingFor = 'Serious relationship',
    this.photos = const [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=900&q=85',
      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=900&q=85',
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=900&q=85',
    ],
    this.city = 'Kochi, Kerala',
    this.distanceKm = 25,
    this.selfieConsent = true,
  });

  /// `0` = Welcome screen, `1..8` = Steps `01/08` to `08/08`.
  final int step;
  final bool isLoading;
  final String? errorMessage;
  final String countryCode;
  final String phoneNumber;
  final List<String> otpDigits;
  final String firstName;
  final String dobDay;
  final String dobMonth;
  final String dobYear;
  final String gender;
  final String genderDetail;
  final bool showGenderOnProfile;
  final String lookingFor;
  final List<String> photos;
  final String city;
  final int distanceKm;
  final bool selfieConsent;

  int get calculatedAge {
    final parsed = int.tryParse(dobYear);
    if (parsed == null || parsed < 1940 || parsed > 2008) {
      return 28;
    }
    final age = 2026 - parsed;
    return age < 18 ? 18 : age;
  }

  String get maskedPhone {
    final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final lastFour =
        digits.length >= 4 ? digits.substring(digits.length - 4) : '3210';
    return '$countryCode ••••• •$lastFour';
  }

  OnboardingFlowState copyWith({
    int? step,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? countryCode,
    String? phoneNumber,
    List<String>? otpDigits,
    String? firstName,
    String? dobDay,
    String? dobMonth,
    String? dobYear,
    String? gender,
    String? genderDetail,
    bool? showGenderOnProfile,
    String? lookingFor,
    List<String>? photos,
    String? city,
    int? distanceKm,
    bool? selfieConsent,
  }) {
    return OnboardingFlowState(
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      countryCode: countryCode ?? this.countryCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      otpDigits: otpDigits ?? this.otpDigits,
      firstName: firstName ?? this.firstName,
      dobDay: dobDay ?? this.dobDay,
      dobMonth: dobMonth ?? this.dobMonth,
      dobYear: dobYear ?? this.dobYear,
      gender: gender ?? this.gender,
      genderDetail: genderDetail ?? this.genderDetail,
      showGenderOnProfile: showGenderOnProfile ?? this.showGenderOnProfile,
      lookingFor: lookingFor ?? this.lookingFor,
      photos: photos ?? this.photos,
      city: city ?? this.city,
      distanceKm: distanceKm ?? this.distanceKm,
      selfieConsent: selfieConsent ?? this.selfieConsent,
    );
  }
}

class OnboardingFlowNotifier extends Notifier<OnboardingFlowState> {
  static const List<String> _extraPhotos = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=900&q=85',
    'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?auto=format&fit=crop&w=900&q=85',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=900&q=85',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=900&q=85',
  ];

  static const List<String> availableCities = [
    'Kochi, Kerala',
    'Trivandrum, Kerala',
    'Kozhikode, Kerala',
    'Kottayam, Kerala',
    'Thrissur, Kerala',
    'Bengaluru, Karnataka',
    'Chennai, Tamil Nadu',
    'Mumbai, Maharashtra',
  ];

  @override
  OnboardingFlowState build() {
    return const OnboardingFlowState();
  }

  void goToStep(int targetStep) {
    state = state.copyWith(step: targetStep.clamp(0, 8), clearError: true);
  }

  void nextStep() {
    if (state.step < 8) {
      state = state.copyWith(step: state.step + 1, clearError: true);
    }
  }

  void previousStep() {
    if (state.step > 0) {
      state = state.copyWith(step: state.step - 1, clearError: true);
    }
  }

  void updatePhone(String value) {
    state = state.copyWith(phoneNumber: value, clearError: true);
  }

  void cycleCountryCode() {
    const codes = ['+91', '+971', '+44', '+1'];
    final idx = codes.indexOf(state.countryCode);
    final next = codes[(idx + 1) % codes.length];
    state = state.copyWith(countryCode: next);
  }

  void setOtpDigit(int index, String value) {
    final updated = List<String>.from(state.otpDigits);
    if (index >= 0 && index < updated.length) {
      updated[index] = value;
      state = state.copyWith(otpDigits: updated);
    }
  }

  void fillSampleOtp() {
    state = state.copyWith(otpDigits: const ['4', '8', '2', '9', '1', '6']);
  }

  void updateFirstName(String value) {
    state = state.copyWith(firstName: value);
  }

  void updateDob({String? day, String? month, String? year}) {
    state = state.copyWith(
      dobDay: day ?? state.dobDay,
      dobMonth: month ?? state.dobMonth,
      dobYear: year ?? state.dobYear,
    );
  }

  void selectGender(String gender) {
    state = state.copyWith(gender: gender, genderDetail: '');
  }

  void toggleGenderDetail() {
    final defaultDetail = state.gender == 'Woman'
        ? 'Cis woman'
        : state.gender == 'Man'
            ? 'Cis man'
            : 'Agender / Genderfluid';
    state = state.copyWith(
      genderDetail: state.genderDetail.isEmpty ? defaultDetail : '',
    );
  }

  void toggleShowGender(bool value) {
    state = state.copyWith(showGenderOnProfile: value);
  }

  void selectLookingFor(String option) {
    state = state.copyWith(lookingFor: option);
  }

  void tapPhotoSlot(int slotIndex) {
    final current = List<String>.from(state.photos);
    if (slotIndex < current.length) {
      if (current.length > 2) {
        current.removeAt(slotIndex);
      } else {
        current[slotIndex] =
            _extraPhotos[(slotIndex + current.length) % _extraPhotos.length];
      }
    } else if (current.length < 6) {
      current.add(_extraPhotos[current.length % _extraPhotos.length]);
    }
    state = state.copyWith(photos: current);
  }

  void selectCity(String city) {
    state = state.copyWith(city: city);
  }

  void cycleCity() {
    final idx = availableCities.indexOf(state.city);
    final next = availableCities[(idx + 1) % availableCities.length];
    state = state.copyWith(city: next);
  }

  void updateDistance(int km) {
    state = state.copyWith(distanceKm: km.clamp(5, 100));
  }

  void toggleSelfieConsent() {
    state = state.copyWith(selfieConsent: !state.selfieConsent);
  }

  void retry() {
    state = state.copyWith(isLoading: false, clearError: true);
  }
}

final onboardingFlowProvider =
    NotifierProvider<OnboardingFlowNotifier, OnboardingFlowState>(
  OnboardingFlowNotifier.new,
);

/// Complete Welcome + 8-Step Onboarding Screen (`01/08` through `08/08`).
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingFlowProvider);
    final notifier = ref.read(onboardingFlowProvider.notifier);

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: JDateTokens.brandRose),
        ),
      );
    }

    if (state.errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.errorMessage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: notifier.retry,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.step == 0) {
      return _WelcomeStepView(
        onStart: () => notifier.goToStep(1),
        onLogin: () => notifier.goToStep(1),
      );
    }

    return Scaffold(
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
                child: _OnboardingStepBodySwitcher(state: state),
              ),
              _OnboardingStepBottomFooter(
                state: state,
                onContinue: () {
                  if (state.step < 8) {
                    notifier.nextStep();
                  } else {
                    if (!context.mounted) return;
                    context.go(AppRoutes.discover);
                  }
                },
              ),
            ],
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
                      JDateTokens.naamLogoAsset,
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
          JDateTokens.naamLogoAsset,
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
  });

  final OnboardingFlowState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (state.step) {
      case 1:
        return _StepOnePhoneView(state: state);
      case 2:
        return _StepTwoOtpView(state: state);
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
                    onChanged: notifier.updatePhone,
                    decoration: const InputDecoration(
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

class _StepTwoOtpView extends ConsumerWidget {
  const _StepTwoOtpView({required this.state});

  final OnboardingFlowState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            'We sent a 6-digit code by SMS.',
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
                onTap: () => notifier.goToStep(1),
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
            'SMS code',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(6, (index) {
              final digit = state.otpDigits[index];
              return Expanded(
                child: GestureDetector(
                  onTap: notifier.fillSampleOtp,
                  child: Container(
                    height: 60,
                    margin: EdgeInsets.only(right: index < 5 ? 8 : 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE4E4E7)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      digit.isEmpty ? (index == 0 ? '|' : '–') : digit,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: digit.isEmpty
                            ? JDateTokens.brandRose
                            : const Color(0xFF1C1C1E),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Text(
                "Didn't get a text? ",
                style: TextStyle(
                  fontSize: 14.5,
                  color: Color(0xFF6E6E73),
                ),
              ),
              GestureDetector(
                onTap: notifier.fillSampleOtp,
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

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(onboardingFlowProvider.notifier);

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
              decoration: const InputDecoration(
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
          Row(
            children: [
              Expanded(
                child: _DobFieldCard(
                  label: 'Day',
                  value: widget.state.dobDay,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DobFieldCard(
                  label: 'Month',
                  value: widget.state.dobMonth,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DobFieldCard(
                  label: 'Year',
                  value: widget.state.dobYear,
                ),
              ),
            ],
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
              "You're ${widget.state.calculatedAge} years old",
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
  });

  final String label;
  final String value;

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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1C1C1E),
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
                        GestureDetector(
                          onTap: notifier.toggleGenderDetail,
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
            'Tap to edit · Drag to reorder',
            style: TextStyle(
              fontSize: 15.5,
              color: Color(0xFF6E6E73),
            ),
          ),
          const SizedBox(height: 22),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
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
                  onTap: () => notifier.tapPhotoSlot(index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          state.photos[index],
                          fit: BoxFit.cover,
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
              return GestureDetector(
                onTap: () => notifier.tapPhotoSlot(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF7F8),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF0D6DF)),
                  ),
                  child: const Column(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: JDateTokens.brandRose,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${state.photos.length} of 6 added',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF3A3A3C),
                    ),
                  ),
                ],
              ),
              const Text(
                'Photo tips',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: JDateTokens.brandRose,
                  decoration: TextDecoration.underline,
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
            onTap: () => notifier.selectCity('Kochi, Kerala'),
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFF7BFD4)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.my_location_rounded,
                    size: 18,
                    color: JDateTokens.brandRose,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Use my current city',
                    style: TextStyle(
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
            onTap: notifier.cycleCity,
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
                        state.city,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1C1C1E),
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
    switch (state.step) {
      case 1:
        return 'Send SMS code';
      case 2:
        return 'Verify & continue';
      case 6:
        return 'Continue with ${state.photos.length} photos';
      case 8:
        return 'Capture selfie';
      default:
        return 'Continue';
    }
  }

  @override
  Widget build(BuildContext context) {
    final note = _footerNote;
    final isDisabled = state.step == 8 && !state.selfieConsent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (note != null) ...[
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
                const Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
