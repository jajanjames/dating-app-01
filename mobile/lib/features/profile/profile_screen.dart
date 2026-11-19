// FILE: lib/features/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/candidate_profile.dart';
import '../../data/models/social_models.dart';
import '../../data/repositories/dating_repository.dart';
import '../matches/likes_controller.dart';
import '../onboarding/malayali_vibe_onboarding_screen.dart';
import '../subscription/subscription_controller.dart';

class UserProfileData {
  const UserProfileData({
    required this.displayName,
    required this.age,
    required this.occupation,
    required this.education,
    required this.neighborhood,
    required this.bio,
    required this.promptQuestion,
    required this.promptAnswer,
    required this.isVerified,
    required this.photoUrls,
    this.interests = const [
      'Mohanlal fan',
      'Malayalam indie',
      'Coffee & chaya dates',
      'Anime & manga',
      'Chaya',
      'Sadya',
    ],
  });

  final String displayName;
  final int age;
  final String occupation;
  final String education;
  final String neighborhood;
  final String bio;
  final String promptQuestion;
  final String promptAnswer;
  final bool isVerified;
  final List<String> photoUrls;
  final List<String> interests;

  UserProfileData copyWith({
    String? displayName,
    int? age,
    String? occupation,
    String? education,
    String? neighborhood,
    String? bio,
    String? promptQuestion,
    String? promptAnswer,
    bool? isVerified,
    List<String>? photoUrls,
    List<String>? interests,
  }) {
    return UserProfileData(
      displayName: displayName ?? this.displayName,
      age: age ?? this.age,
      occupation: occupation ?? this.occupation,
      education: education ?? this.education,
      neighborhood: neighborhood ?? this.neighborhood,
      bio: bio ?? this.bio,
      promptQuestion: promptQuestion ?? this.promptQuestion,
      promptAnswer: promptAnswer ?? this.promptAnswer,
      isVerified: isVerified ?? this.isVerified,
      photoUrls: photoUrls ?? this.photoUrls,
      interests: interests ?? this.interests,
    );
  }
}

final userProfileProvider = StateProvider<UserProfileData>((ref) {
  return const UserProfileData(
    displayName: 'Aarav',
    age: 28,
    occupation: 'Product Architect',
    education: 'NID Ahmedabad',
    neighborhood: 'Kochi',
    bio: 'Designing warm minimal spaces, collecting indie photobooks, and brewing filter coffee.',
    promptQuestion: 'Ideal Sunday ritual',
    promptAnswer:
        'Morning ferry walk in Fort Kochi, fresh flowers, and cooking coastal curry with vinyl records.',
    isVerified: true,
    photoUrls: [
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=900&q=85',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=900&q=85',
    ],
    interests: [
      'Mohanlal fan',
      'Malayalam indie',
      'Coffee & chaya dates',
      'Anime & manga',
      'Chaya',
      'Sadya',
    ],
  );
});

class SubscriptionTierInfo {
  const SubscriptionTierInfo({
    required this.id,
    required this.title,
    required this.badgeLabel,
    required this.priceLabel,
    required this.tagline,
    required this.features,
    required this.icon,
  });

  final String id;
  final String title;
  final String badgeLabel;
  final String priceLabel;
  final String tagline;
  final List<String> features;
  final IconData icon;
}

const List<SubscriptionTierInfo> _kSubscriptionTiers = [
  SubscriptionTierInfo(
    id: 'premium',
    title: 'Premium',
    badgeLabel: 'Essential',
    priceLabel: '₹499/mo',
    tagline: 'Like and chat with everyone you match.',
    icon: Icons.favorite_rounded,
    features: [
      'Unlimited daily Likes',
      'Chat with all your matches',
      '1 Note and 1 Star every day',
    ],
  ),
  SubscriptionTierInfo(
    id: 'premium_plus',
    title: 'Premium+',
    badgeLabel: 'Most Popular',
    priceLabel: '₹899/mo',
    tagline: 'Stand out with more Stars and Notes.',
    icon: Icons.auto_awesome_rounded,
    features: [
      'Unlimited daily Likes & chats',
      '5 Notes every day',
      '3 Stars every day',
    ],
  ),
  SubscriptionTierInfo(
    id: 'ultra',
    title: 'Ultra',
    badgeLabel: 'VIP Access',
    priceLabel: '₹1,499/mo',
    tagline: 'No limits on anything.',
    icon: Icons.workspace_premium_rounded,
    features: [
      'Unlimited Likes & chats',
      'Unlimited Notes',
      'Unlimited Stars',
    ],
  ),
];

/// Naam `You` Tab Screen:
/// 1. Minimal User Profile Identity Card (with compact clickable Interests section that navigates directly to Malayali Vibe & Interests)
/// 2. Clean White Card with Rose Accent, 3 Short Perks, and Upgrade CTA
/// 3. Settings Rows (Your Likes, Recent Passes, Malayali Vibe & Interests, Safety Tips, Help Center)
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _selectedTierIndex = 1;

  Future<void> _openPhotoAndInfoEditor(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const PersonalInformationPage(),
      ),
    );
  }

  Future<void> _openMalayaliVibeOnboarding(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const MalayaliVibeOnboardingScreen(),
      ),
    );
  }

  void _openUpgradeSheet(BuildContext context, SubscriptionTierInfo tier) {
    final status = ref.read(subscriptionStatusProvider).valueOrNull;
    if (status?.freeAccess == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Likes, notes and chats are already free for you.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _SubscriptionUpgradeSheet(
        tier: tier,
        onConfirmUpgrade: () async {
          Navigator.of(sheetContext).pop();
          final messenger = ScaffoldMessenger.of(context);
          try {
            await ref
                .read(subscriptionStatusProvider.notifier)
                .activate(tier.id);
            messenger.showSnackBar(
              SnackBar(
                content: Text('Naam ${tier.title} activated!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } on ApiException catch (e) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(e.message),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  /// Plan copy from `GET /subscriptions/plans`, falling back to the built-in tiers.
  List<SubscriptionTierInfo> _tiersFrom(List<SubscriptionPlan>? plans) {
    if (plans == null || plans.isEmpty) return _kSubscriptionTiers;
    return [
      for (final tier in _kSubscriptionTiers)
        () {
          final plan = plans.where((p) => p.id == tier.id).firstOrNull;
          if (plan == null) return tier;
          return SubscriptionTierInfo(
            id: tier.id,
            title: plan.title,
            badgeLabel: plan.badgeLabel,
            priceLabel: plan.priceLabel,
            tagline: plan.tagline,
            features: plan.features,
            icon: tier.icon,
          );
        }(),
    ];
  }

  void _openYourLikesSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _SavedProfilesSheet(isPassesMode: false),
    );
  }

  void _openRecentPassesSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _SavedProfilesSheet(isPassesMode: true),
    );
  }

  Future<void> _openInfoSubPage(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<String> highlights,
  }) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _ProfileDetailSubPage(
          title: title,
          subtitle: subtitle,
          highlights: highlights,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final activePlanId = ref.watch(activeSubscriptionPlanProvider);
    final tiers = _tiersFrom(ref.watch(subscriptionPlansProvider).valueOrNull);
    final selectedTier = tiers[_selectedTierIndex];

    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            // 1. Minimal User Profile Header Card + Compact Clickable Interests Section
            _EditorialProfileIdentityCard(
              profile: profile,
              onEditTap: () => _openPhotoAndInfoEditor(context),
              onInterestsTap: () => _openMalayaliVibeOnboarding(context),
            ),
            const SizedBox(height: 16),

            // 2. Clean White Card with Rose Accent, 3 Short Perks & Upgrade CTA
            _MediumSubscriptionShowcaseCard(
              tiers: tiers,
              selectedIndex: _selectedTierIndex,
              activePlanId: activePlanId,
              onSelectTab: (index) {
                setState(() => _selectedTierIndex = index);
              },
              onTapUpgrade: () => _openUpgradeSheet(context, selectedTier),
            ),
            const SizedBox(height: 16),

            // 3. Clean Minimal Rows
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFEFEFF4)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A18181B),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _MinimalSettingRow(
                    icon: Icons.favorite_border_rounded,
                    title: 'Your Likes',
                    showDivider: true,
                    onTap: () => _openYourLikesSheet(context),
                  ),
                  _MinimalSettingRow(
                    icon: Icons.undo_rounded,
                    title: 'Recent Passes',
                    showDivider: true,
                    onTap: () => _openRecentPassesSheet(context),
                  ),
                  _MinimalSettingRow(
                    icon: Icons.local_cafe_outlined,
                    title: 'Malayali Vibe & Interests',
                    showDivider: true,
                    onTap: () => _openMalayaliVibeOnboarding(context),
                  ),
                  _MinimalSettingRow(
                    icon: Icons.verified_user_outlined,
                    title: 'Safety Tips',
                    showDivider: true,
                    onTap: () => _openInfoSubPage(
                      context,
                      title: 'Safety Tips',
                      subtitle:
                          'Guidelines for safe and intentional dating on Naam',
                      highlights: const [
                        '1. Prioritize profiles with the Selfie Verified checkmark.',
                        '2. Keep early conversations inside Naam before sharing personal contact details.',
                        '3. Meet in public cafés and share your date plans with a trusted friend.',
                      ],
                    ),
                  ),
                  _MinimalSettingRow(
                    icon: Icons.help_outline_rounded,
                    title: 'Help Center',
                    showDivider: false,
                    onTap: () => _openInfoSubPage(
                      context,
                      title: 'Help Center',
                      subtitle: '24/7 Member Support & Account Privacy',
                      highlights: const [
                        'How Save Search filters curate your Naam Discovery deck.',
                        'How to update your profile photos, Malayali vibe interests, and verify your selfie.',
                        'Privacy Policy, Data Protection & Account Controls.',
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact clickable Interests card used in both Profile (`You`) and `Edit Profile`.
/// Clicking opens the dedicated Malayali Vibe & Interests screen directly; shows a crisp tick mark (`✓`) only.
class _CompactInterestsSectionCard extends StatelessWidget {
  const _CompactInterestsSectionCard({
    required this.interests,
    required this.onTap,
    this.maxPreviewCount = 6,
  });

  final List<String> interests;
  final VoidCallback onTap;
  final int maxPreviewCount;

  @override
  Widget build(BuildContext context) {
    final visibleTags = interests.take(maxPreviewCount).toList(growable: false);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFECECF2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Interests · ${interests.length}',
                  style: const TextStyle(
                    color: Color(0xFF3A3A3C),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  'Edit vibe →',
                  style: TextStyle(
                    color: Color(0xFFF7196B),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (visibleTags.isEmpty)
              const Text(
                'Tap to choose Malayalam movies, music, anime & dating vibes',
                style: TextStyle(
                  color: Color(0xFF6E6E73),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...visibleTags.map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8FA),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0x59F7196B)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tag,
                            style: const TextStyle(
                              color: Color(0xFF1C1C1E),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Color(0xFFF7196B),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (interests.length > maxPreviewCount)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8FA),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0x59F7196B)),
                      ),
                      child: Text(
                        '+${interests.length - maxPreviewCount} more',
                        style: const TextStyle(
                          color: Color(0xFFF7196B),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _EditorialProfileIdentityCard extends StatelessWidget {
  const _EditorialProfileIdentityCard({
    required this.profile,
    required this.onEditTap,
    required this.onInterestsTap,
  });

  final UserProfileData profile;
  final VoidCallback onEditTap;
  final VoidCallback onInterestsTap;

  @override
  Widget build(BuildContext context) {
    final avatarUrl =
        profile.photoUrls.isNotEmpty ? profile.photoUrls.first : '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEFEFF4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D18181B),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const ColoredBox(
                            color: Color(0xFFE4E4E7),
                            child: Icon(Icons.person_rounded, size: 32),
                          ),
                        )
                      : const ColoredBox(
                          color: Color(0xFFE4E4E7),
                          child: Icon(Icons.person_rounded, size: 32),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${profile.displayName}, ${profile.age}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: JDateTokens.pitchBlack,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        if (profile.isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified_rounded,
                            size: 18,
                            color: JDateTokens.brandRose,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${profile.occupation} · ${profile.neighborhood}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF71717A),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onEditTap,
                style: FilledButton.styleFrom(
                  backgroundColor: JDateTokens.pitchBlack,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Edit',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _CompactInterestsSectionCard(
            interests: profile.interests,
            onTap: onInterestsTap,
            maxPreviewCount: 6,
          ),
        ],
      ),
    );
  }
}

/// Clean White Card with Rose Accent, 3 Short Perks, and Upgrade CTA
class _MediumSubscriptionShowcaseCard extends StatelessWidget {
  const _MediumSubscriptionShowcaseCard({
    required this.tiers,
    required this.selectedIndex,
    required this.activePlanId,
    required this.onSelectTab,
    required this.onTapUpgrade,
  });

  final List<SubscriptionTierInfo> tiers;
  final int selectedIndex;
  final String? activePlanId;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onTapUpgrade;

  @override
  Widget build(BuildContext context) {
    final currentTier = tiers[selectedIndex];
    final isCurrentPlanActive = activePlanId == currentTier.id;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0x2EF01E65),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12F01E65),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: List.generate(tiers.length, (idx) {
                final item = tiers[idx];
                final isSelected = idx == selectedIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onSelectTab(idx),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: isSelected
                            ? const [
                                BoxShadow(
                                  color: Color(0x1018181B),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected
                              ? JDateTokens.brandRose
                              : const Color(0xFF71717A),
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: JDateTokens.brandRose.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  currentTier.icon,
                  color: JDateTokens.brandRose,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentTier.badgeLabel,
                      style: const TextStyle(
                        color: JDateTokens.brandRose,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Naam ${currentTier.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: JDateTokens.pitchBlack,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                currentTier.priceLabel,
                style: const TextStyle(
                  color: JDateTokens.pitchBlack,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x0A09090B)),
            ),
            child: Column(
              children: currentTier.features.map(
                (perk) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: JDateTokens.brandRose,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            perk,
                            style: const TextStyle(
                              color: Color(0xFF27272A),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ).toList(),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: onTapUpgrade,
              style: FilledButton.styleFrom(
                backgroundColor: isCurrentPlanActive
                    ? JDateTokens.pitchBlack
                    : JDateTokens.brandRose,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                isCurrentPlanActive
                    ? 'Active: Naam ${currentTier.title}'
                    : 'Upgrade to ${currentTier.title}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionUpgradeSheet extends StatelessWidget {
  const _SubscriptionUpgradeSheet({
    required this.tier,
    required this.onConfirmUpgrade,
  });

  final SubscriptionTierInfo tier;
  final VoidCallback onConfirmUpgrade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      child: LiquidGlassSurface(
        borderRadius: 26,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Naam ${tier.title}',
                  style: theme.textTheme.headlineMedium,
                ),
                Text(
                  tier.priceLabel,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: JDateTokens.brandRose,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(tier.tagline, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            ...tier.features.map(
              (perk) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: JDateTokens.brandRose,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(perk, style: theme.textTheme.bodyLarge),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onConfirmUpgrade,
              child: Text('Activate ${tier.title} (${tier.priceLabel})'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedProfilesSheet extends ConsumerWidget {
  const _SavedProfilesSheet({required this.isPassesMode});

  final bool isPassesMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(datingActivityRevisionProvider);
    final repo = ref.watch(datingRepositoryProvider);
    final List<CandidateProfile> list = isPassesMode
        ? repo.getPassedProfiles()
        : [
            for (final like
                in ref.watch(likesControllerProvider).valueOrNull?.sent ??
                    const [])
              like.profile,
          ];
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      child: LiquidGlassSurface(
        borderRadius: 26,
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isPassesMode ? 'Recent Passes' : 'Your Likes',
                  style: theme.textTheme.headlineMedium,
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isPassesMode
                  ? 'Give skipped profiles a second chance anytime.'
                  : 'Profiles you liked or starred on Discover.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    isPassesMode
                        ? 'No passed profiles in this session.'
                        : 'No liked profiles yet.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              )
            else
              ...list.take(5).map(
                    (person) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8FA),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          ClipOval(
                            child: SizedBox(
                              width: 46,
                              height: 46,
                              child: NaamProfileImage(
                                imageUrl: person.primaryImageUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${person.firstName}, ${person.age}',
                                  style: theme.textTheme.titleMedium,
                                ),
                                Text(
                                  '${person.occupation} · ${person.neighborhood}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (isPassesMode)
                            TextButton(
                              onPressed: () {
                                repo.restorePassedProfile(person);
                                ref
                                    .read(
                                        datingActivityRevisionProvider.notifier)
                                    .state++;
                              },
                              child: const Text('Restore'),
                            ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _MinimalSettingRow extends StatelessWidget {
  const _MinimalSettingRow({
    required this.icon,
    required this.title,
    required this.showDivider,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(
                  bottom: BorderSide(color: Color(0xFFF4F4F6)),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: JDateTokens.pitchBlack),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: JDateTokens.pitchBlack,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFFA1A1AA),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileDetailSubPage extends StatelessWidget {
  const _ProfileDetailSubPage({
    required this.title,
    required this.subtitle,
    required this.highlights,
  });

  final String title;
  final String subtitle;
  final List<String> highlights;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: textTheme.headlineMedium),
                  LiquidGlassOrbButton(
                    icon: Icons.close_rounded,
                    size: 42,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                children: [
                  Text(subtitle, style: textTheme.bodyMedium),
                  const SizedBox(height: 14),
                  ...highlights.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: LiquidGlassSurface(
                        borderRadius: 20,
                        padding: const EdgeInsets.all(16),
                        child: Text(item, style: textTheme.titleMedium),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-Screen Photo Grid, Compact Clickable Malayali Vibe Interests & Personal Information Editor (`Edit Profile`)
class PersonalInformationPage extends ConsumerStatefulWidget {
  const PersonalInformationPage({super.key});

  @override
  ConsumerState<PersonalInformationPage> createState() =>
      _PersonalInformationPageState();
}

class _PersonalInformationPageState
    extends ConsumerState<PersonalInformationPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _occupationController;
  late final TextEditingController _educationController;
  late final TextEditingController _neighborhoodController;
  late final TextEditingController _bioController;
  late final TextEditingController _promptAnswerController;

  @override
  void initState() {
    super.initState();
    final current = ref.read(userProfileProvider);
    _nameController = TextEditingController(text: current.displayName);
    _occupationController = TextEditingController(text: current.occupation);
    _educationController = TextEditingController(text: current.education);
    _neighborhoodController = TextEditingController(text: current.neighborhood);
    _bioController = TextEditingController(text: current.bio);
    _promptAnswerController = TextEditingController(text: current.promptAnswer);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _occupationController.dispose();
    _educationController.dispose();
    _neighborhoodController.dispose();
    _bioController.dispose();
    _promptAnswerController.dispose();
    super.dispose();
  }

  void _handleSwapOrAddPhoto(int slotIndex) {
    const fallbackPool = [
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=900&q=85',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=900&q=85',
      'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?auto=format&fit=crop&w=900&q=85',
    ];
    final current = ref.read(userProfileProvider);
    final updated = List<String>.from(current.photoUrls);
    final replacement = fallbackPool[slotIndex % fallbackPool.length];
    if (slotIndex < updated.length) {
      updated[slotIndex] = replacement;
    } else {
      updated.add(replacement);
    }
    ref.read(userProfileProvider.notifier).state =
        current.copyWith(photoUrls: updated);
  }

  void _handleRemovePhoto(int slotIndex) {
    final current = ref.read(userProfileProvider);
    if (current.photoUrls.length <= 1) return;
    final updated = List<String>.from(current.photoUrls)..removeAt(slotIndex);
    ref.read(userProfileProvider.notifier).state =
        current.copyWith(photoUrls: updated);
  }

  Future<void> _openFullMalayaliVibePage(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const MalayaliVibeOnboardingScreen(),
      ),
    );
  }

  void _handleSave() {
    final current = ref.read(userProfileProvider);
    ref.read(userProfileProvider.notifier).state = current.copyWith(
      displayName: _nameController.text.trim().isEmpty
          ? current.displayName
          : _nameController.text.trim(),
      occupation: _occupationController.text.trim(),
      education: _educationController.text.trim(),
      neighborhood: _neighborhoodController.text.trim(),
      bio: _bioController.text.trim(),
      promptAnswer: _promptAnswerController.text.trim(),
    );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile & Malayali vibe updated!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Edit Profile', style: textTheme.headlineMedium),
                  LiquidGlassOrbButton(
                    icon: Icons.close_rounded,
                    size: 42,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                children: [
                  Text(
                    'Profile Photos (${profile.photoUrls.length}/6)',
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 6,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.78,
                    ),
                    itemBuilder: (context, index) {
                      final hasPhoto = index < profile.photoUrls.length;
                      final url = hasPhoto ? profile.photoUrls[index] : null;
                      return _EditablePhotoSlotTile(
                        imageUrl: url,
                        canRemove: hasPhoto && profile.photoUrls.length > 1,
                        onTap: () => _handleSwapOrAddPhoto(index),
                        onRemove: () => _handleRemovePhoto(index),
                      );
                    },
                  ),
                  const SizedBox(height: 22),

                  // Compact Clickable Malayali Vibe & Interests Section (no banner image, navigates directly to full Malayali Vibe screen)
                  _CompactInterestsSectionCard(
                    interests: profile.interests,
                    onTap: () => _openFullMalayaliVibePage(context),
                    maxPreviewCount: 8,
                  ),
                  const SizedBox(height: 22),
                  _ProfileInputField(
                    label: 'Display Name',
                    controller: _nameController,
                  ),
                  const SizedBox(height: 12),
                  _ProfileInputField(
                    label: 'Occupation',
                    controller: _occupationController,
                  ),
                  const SizedBox(height: 12),
                  _ProfileInputField(
                    label: 'Education',
                    controller: _educationController,
                  ),
                  const SizedBox(height: 12),
                  _ProfileInputField(
                    label: 'City / Neighborhood',
                    controller: _neighborhoodController,
                  ),
                  const SizedBox(height: 12),
                  _ProfileInputField(
                    label: 'Bio',
                    controller: _bioController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  _ProfileInputField(
                    label: 'Prompt Answer (${profile.promptQuestion})',
                    controller: _promptAnswerController,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: _handleSave,
                    child: const Text('Save Profile Changes'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditablePhotoSlotTile extends StatelessWidget {
  const _EditablePhotoSlotTile({
    required this.imageUrl,
    required this.canRemove,
    required this.onTap,
    required this.onRemove,
  });

  final String? imageUrl;
  final bool canRemove;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const ColoredBox(
                  color: Color(0xFFF4F4F6),
                  child: Icon(Icons.broken_image_outlined),
                ),
              )
            else
              Container(
                color: const Color(0xFFF6F6F8),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.add_a_photo_outlined,
                  color: JDateTokens.brandRose,
                ),
              ),
            if (canRemove)
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Color(0xB309090B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInputField extends StatelessWidget {
  const _ProfileInputField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF71717A),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8F8FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
            ),
          ),
        ),
      ],
    );
  }
}
