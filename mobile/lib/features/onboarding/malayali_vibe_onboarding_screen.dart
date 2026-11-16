// FILE: lib/features/onboarding/malayali_vibe_onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../profile/profile_screen.dart';

/// Model representing a Malayali cultural & dating interest category (Millennial + Gen Z).
class MalayaliVibeCategory {
  const MalayaliVibeCategory({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;
}

/// Step 01 / 02 Malayali Vibe categories (Malayalam cinema, On repeat, Dating & connection, Gen Z, anime & pop culture).
const List<MalayaliVibeCategory> kMalayaliVibeStep1Categories = [
  MalayaliVibeCategory(
    title: 'Malayalam cinema',
    items: [
      'Mohanlal fan',
      'Mammootty fan',
      'Fahadh Faasil',
      'Kumbalangi Nights',
      'Premalu & Aavesham',
      'Manjummel Boys',
      'Bangalore Days',
      '90s Priyadarshan',
      'Lijo Jose Pellissery',
      'IFFK Trivandrum',
    ],
  ),
  MalayaliVibeCategory(
    title: 'On repeat',
    items: [
      'Malayalam indie',
      'Evergreen hits',
      'Sushin Shyam',
      'Rex Vijayan & Avial',
      'Job Kurian',
      'Thaikkudam Bridge',
      'KJ Yesudas & Chithra',
      'Vidyasagar classics',
      'Fejo & Mallu Rap',
      'Govind Vasantha',
    ],
  ),
  MalayaliVibeCategory(
    title: 'Dating & connection',
    items: [
      'Coffee & chaya dates',
      'Deep 2 AM talks',
      'Slow-burn romance',
      'Long drives & playlists',
      'Cooking together',
      'Beach sunset walks',
      'Bookstore & café hopping',
      'Spontaneous roadtrips',
      'Humor & banter',
      'Intentional dating',
    ],
  ),
  MalayaliVibeCategory(
    title: 'Gen Z, anime & pop culture',
    items: [
      'Anime & manga',
      'One Piece & JJK',
      'Studio Ghibli',
      'Attack on Titan',
      'K-Dramas & ramen',
      'Gaming & PS5 nights',
      'Thrifting & streetwear',
      '35mm film photography',
      'Matcha & iced latte',
      'Memes & reels',
      'Indie gigs',
    ],
  ),
];

/// Step 02 / 02 Malayali Vibe categories (Comfort food, Hangouts & Kerala spots, Roots & celebrations, Millennial & Malayali life).
const List<MalayaliVibeCategory> kMalayaliVibeStep2Categories = [
  MalayaliVibeCategory(
    title: 'Comfort food',
    items: [
      'Chaya',
      'Puttu & kadala',
      'Sadya',
      'Porotta & beef roast',
      'Thalassery biriyani',
      'Pazham pori & beef',
      'Karimeen pollichathu',
      'Kallummakaya',
      'Kappa & meen curry',
      'Sulaimani & kattan chaya',
    ],
  ),
  MalayaliVibeCategory(
    title: 'Hangouts & Kerala spots',
    items: [
      'Fort Kochi cafés',
      'Varkala cliff sunsets',
      'Munnar mist drives',
      'Kozhikode beach',
      'Marine Drive walks',
      'Alleppey backwaters',
      'Wayanad trails',
      'Kochi-Muziris Biennale',
      'Chayakkada talks',
    ],
  ),
  MalayaliVibeCategory(
    title: 'Roots & celebrations',
    items: [
      'Onam sadya & pookkalam',
      'Thrissur Pooram',
      'Vishu kani',
      'Vallamkali boat race',
      'Theyyam nights',
      'Christmas plum cake',
      'Monsoon & parippu vada',
    ],
  ),
  MalayaliVibeCategory(
    title: 'Millennial & Malayali life',
    items: [
      'NRI Malayali',
      'Bangalore / Kochi tech',
      'Late-night thattukada',
      'Fluent in Manglish',
      '90s Doordarshan nostalgia',
      'Weekend home to Kerala',
      'Filter kaapi & books',
      'Roadtrips to hills',
    ],
  ),
];

/// Provider supplying the 2-step Malayali Vibe catalog with 4-state UI coverage.
final malayaliVibeCatalogProvider = FutureProvider.autoDispose<
    ({
      List<MalayaliVibeCategory> step1,
      List<MalayaliVibeCategory> step2,
    })>(
  (ref) async {
    return (
      step1: kMalayaliVibeStep1Categories,
      step2: kMalayaliVibeStep2Categories,
    );
  },
);

/// 2-Step "What's your Malayali vibe?" Onboarding & Profile Interest Selector (`01 / 02` and `02 / 02`).
/// Clean, properly aligned layout with no banner image clutter and a set tick mark (`✓`) only on selected items.
class MalayaliVibeOnboardingScreen extends ConsumerStatefulWidget {
  const MalayaliVibeOnboardingScreen({
    super.key,
    this.initialStep = 1,
    this.onCompleted,
  });

  final int initialStep;
  final VoidCallback? onCompleted;

  @override
  ConsumerState<MalayaliVibeOnboardingScreen> createState() =>
      _MalayaliVibeOnboardingScreenState();
}

class _MalayaliVibeOnboardingScreenState
    extends ConsumerState<MalayaliVibeOnboardingScreen> {
  late int _currentStep;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep.clamp(1, 2);
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    final currentProfile = ref.read(userProfileProvider);
    final currentInterests = List<String>.from(currentProfile.interests);
    if (currentInterests.contains(tag)) {
      currentInterests.remove(tag);
    } else {
      currentInterests.add(tag);
    }
    ref.read(userProfileProvider.notifier).state = currentProfile.copyWith(
      interests: currentInterests,
    );
  }

  void _handleBack() {
    if (_currentStep == 2) {
      setState(() => _currentStep = 1);
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      return;
    }
    Navigator.of(context).maybePop();
  }

  void _handleContinue() {
    if (_currentStep == 1) {
      setState(() => _currentStep = 2);
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      return;
    }
    if (widget.onCompleted != null) {
      widget.onCompleted!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncCatalog = ref.watch(malayaliVibeCatalogProvider);
    final profile = ref.watch(userProfileProvider);
    final selectedTags = profile.interests;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: asyncCatalog.when(
          loading: () => const _MalayaliVibeStateView(
            icon: Icons.local_cafe_outlined,
            title: 'Brewing Your Malayali Vibe',
            subtitle: 'Loading Malayalam cinema, dating, and Gen Z vibes...',
            isLoading: true,
          ),
          error: (err, _) => _MalayaliVibeStateView(
            icon: Icons.error_outline_rounded,
            title: 'Could Not Load Malayali Vibes',
            subtitle: err.toString(),
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(malayaliVibeCatalogProvider),
          ),
          data: (catalog) {
            final activeCategories =
                _currentStep == 1 ? catalog.step1 : catalog.step2;
            if (activeCategories.isEmpty) {
              return const _MalayaliVibeStateView(
                icon: Icons.sentiment_neutral_rounded,
                title: 'No Categories Available',
                subtitle: 'Check back soon for more Malayali vibe tags.',
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MalayaliVibeTopHeader(
                  currentStep: _currentStep,
                  onBack: _handleBack,
                ),
                _MalayaliVibeTwoStepProgressBar(currentStep: _currentStep),
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                    children: [
                      const Text(
                        'What’s your\nMalayali vibe?',
                        style: TextStyle(
                          color: Color(0xFF1C1C1E),
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          height: 1.08,
                          letterSpacing: -0.9,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'For Malayalis, wherever you call home.',
                        style: TextStyle(
                          color: Color(0xFF6E6E73),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _MalayaliVibeSelectionCounterRow(
                        selectedCount: selectedTags.length,
                      ),
                      const SizedBox(height: 18),
                      ...activeCategories.map(
                        (category) => Padding(
                          padding: const EdgeInsets.only(bottom: 22),
                          child: _MalayaliVibeCategorySection(
                            category: category,
                            selectedTags: selectedTags,
                            onToggleTag: _toggleTag,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _MalayaliVibeBottomFooter(
                  currentStep: _currentStep,
                  canContinue: selectedTags.length >= 3,
                  onContinue: _handleContinue,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MalayaliVibeTopHeader extends StatelessWidget {
  const _MalayaliVibeTopHeader({
    required this.currentStep,
    required this.onBack,
  });

  final int currentStep;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 22, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF2C2C2E),
              size: 22,
            ),
            tooltip: 'Back',
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'naam',
                style: TextStyle(
                  color: Color(0xFF2C2C2E),
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              SizedBox(width: 2),
              Icon(
                Icons.favorite_border_rounded,
                color: Color(0xFFF7196B),
                size: 22,
              ),
            ],
          ),
          Text(
            '0$currentStep / 02',
            style: const TextStyle(
              color: Color(0xFF6E6E73),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MalayaliVibeTwoStepProgressBar extends StatelessWidget {
  const _MalayaliVibeTwoStepProgressBar({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFF7196B),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: currentStep >= 2
                    ? const Color(0xFFF7196B)
                    : const Color(0xFFEBEBF0),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MalayaliVibeSelectionCounterRow extends StatelessWidget {
  const _MalayaliVibeSelectionCounterRow({required this.selectedCount});

  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF2F2F7)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Choose at least 3 that feel like you',
            style: TextStyle(
              color: Color(0xFF6E6E73),
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '$selectedCount selected',
            style: const TextStyle(
              color: Color(0xFFF7196B),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MalayaliVibeCategorySection extends StatelessWidget {
  const _MalayaliVibeCategorySection({
    required this.category,
    required this.selectedTags,
    required this.onToggleTag,
  });

  final MalayaliVibeCategory category;
  final List<String> selectedTags;
  final ValueChanged<String> onToggleTag;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category.title,
          style: const TextStyle(
            color: Color(0xFF3A3A3C),
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: category.items.map((tag) {
            final isSelected = selectedTags.contains(tag);
            return _MalayaliVibeSelectablePill(
              label: tag,
              isSelected: isSelected,
              onTap: () => onToggleTag(tag),
            );
          }).toList(growable: false),
        ),
      ],
    );
  }
}

/// Selectable Malayali Vibe pill with a set tick mark (`✓`) only when selected (no faded `+` toggle).
class _MalayaliVibeSelectablePill extends StatelessWidget {
  const _MalayaliVibeSelectablePill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 42),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF5F8) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF7196B)
                : const Color(0xFFE5E5EA),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1C1C1E),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.check_rounded,
                size: 16,
                color: Color(0xFFF7196B),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MalayaliVibeBottomFooter extends StatelessWidget {
  const _MalayaliVibeBottomFooter({
    required this.currentStep,
    required this.canContinue,
    required this.onContinue,
  });

  final int currentStep;
  final bool canContinue;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'A familiar taste is a lovely place to start.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6E6E73),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: canContinue ? onContinue : null,
            child: Opacity(
              opacity: canContinue ? 1.0 : 0.45,
              child: Container(
                height: 58,
                padding: const EdgeInsets.symmetric(horizontal: 26),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF7196B),
                      Color(0xFFE0115F),
                    ],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x47F7196B),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currentStep == 1 ? 'Continue' : 'Save Malayali Vibe',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MalayaliVibeStateView extends StatelessWidget {
  const _MalayaliVibeStateView({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isLoading = false,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLoading;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const CircularProgressIndicator(color: JDateTokens.brandRose)
            else
              Icon(icon, size: 42, color: JDateTokens.brandRose),
            const SizedBox(height: 14),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
