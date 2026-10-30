// FILE: lib/features/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/candidate_profile.dart';
import '../../data/repositories/dating_repository.dart';

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
  );
});

final activeSubscriptionPlanProvider = StateProvider<String?>((ref) => null);

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
    tagline: 'Everything you need for effortless daily discovery.',
    icon: Icons.favorite_rounded,
    features: [
      'Unlimited daily Likes & Rewinds',
      'Full Community, Faith & City filters',
      'Ad-free discovery experience',
    ],
  ),
  SubscriptionTierInfo(
    id: 'premium_plus',
    title: 'Premium+',
    badgeLabel: 'Most Popular',
    priceLabel: '₹899/mo',
    tagline: 'Unlock everyone who liked you + 3x profile boost.',
    icon: Icons.auto_awesome_rounded,
    features: [
      'See everyone who already Liked you',
      '5 free Direct Comments every week',
      '3× Profile Boost in your city weekly',
    ],
  ),
  SubscriptionTierInfo(
    id: 'ultra',
    title: 'Ultra',
    badgeLabel: 'VIP Access',
    priceLabel: '₹1,499/mo',
    tagline: 'Priority placement and curated weekly introductions.',
    icon: Icons.workspace_premium_rounded,
    features: [
      'Priority #1 placement in Discover & Likes',
      'Unlimited Direct Comments & Super-Stars',
      'Curated weekly VIP introductions',
    ],
  ),
];

/// Naam `You` Tab Screen:
/// 1. Minimal User Profile Identity Card (single Edit button next to name/bio, no photo icon overlay, no 29% completion strip)
/// 2. Clean White Card with Rose Accent, 3 Short Perks, and Upgrade CTA
/// 3. 4 Essential Rows (Your Likes, Recent Passes, Safety Tips, Help Center)
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

  void _openUpgradeSheet(BuildContext context, SubscriptionTierInfo tier) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _SubscriptionUpgradeSheet(
        tier: tier,
        onConfirmUpgrade: () {
          ref.read(activeSubscriptionPlanProvider.notifier).state = tier.id;
          Navigator.of(sheetContext).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Naam ${tier.title} activated!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
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
    final selectedTier = _kSubscriptionTiers[_selectedTierIndex];

    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            // 1. Minimal User Profile Header Card (Single Edit button only)
            _EditorialProfileIdentityCard(
              profile: profile,
              onEditTap: () => _openPhotoAndInfoEditor(context),
            ),
            const SizedBox(height: 18),

            // 2. Clean White Card with Rose Accent, 3 Short Perks & Upgrade CTA
            _MediumSubscriptionShowcaseCard(
              tiers: _kSubscriptionTiers,
              selectedIndex: _selectedTierIndex,
              activePlanId: activePlanId,
              onSelectTab: (index) {
                setState(() => _selectedTierIndex = index);
              },
              onTapUpgrade: () => _openUpgradeSheet(context, selectedTier),
            ),
            const SizedBox(height: 18),

            // 3. Clean Minimal Rows (Your Likes, Recent Passes, Safety Tips, Help Center)
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
                        'How to update your profile photos and verify your selfie.',
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

class _EditorialProfileIdentityCard extends StatelessWidget {
  const _EditorialProfileIdentityCard({
    required this.profile,
    required this.onEditTap,
  });

  final UserProfileData profile;
  final VoidCallback onEditTap;

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
      child: Row(
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
          // 1. Segmented Tier Selector Tabs
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

          // 2. Selected Tier Header + Price
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

          // 3. 3 Short Perks
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

          // 4. Single Upgrade CTA Button
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
    final List<CandidateProfile> list =
        isPassesMode ? repo.getPassedProfiles() : repo.getLikedProfiles();
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
                              child: Image.network(
                                person.primaryImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const ColoredBox(color: Color(0xFFE4E4E7)),
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

/// Full-Screen Photo Grid & Personal Information Editor
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

  void _saveChanges() {
    final current = ref.read(userProfileProvider);
    ref.read(userProfileProvider.notifier).state = current.copyWith(
      displayName: _nameController.text.trim(),
      occupation: _occupationController.text.trim(),
      education: _educationController.text.trim(),
      neighborhood: _neighborhoodController.text.trim(),
      bio: _bioController.text.trim(),
      promptAnswer: _promptAnswerController.text.trim(),
    );
    Navigator.of(context).pop();
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Profile',
                    style: textTheme.headlineMedium,
                  ),
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  LiquidGlassSurface(
                    borderRadius: 24,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Profile Photos', style: textTheme.titleMedium),
                            Text(
                              '${profile.photoUrls.length} of 6 slots',
                              style: textTheme.bodySmall,
                            ),
                          ],
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
                            childAspectRatio: 0.76,
                          ),
                          itemBuilder: (context, index) {
                            final hasPhoto = index < profile.photoUrls.length;
                            return _ProfilePhotoTile(
                              photoUrl:
                                  hasPhoto ? profile.photoUrls[index] : null,
                              onTap: () => _handleSwapOrAddPhoto(index),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  LiquidGlassSurface(
                    borderRadius: 24,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProfileTextField(
                          label: 'Display Name',
                          controller: _nameController,
                        ),
                        const SizedBox(height: 14),
                        _ProfileTextField(
                          label: 'Occupation & Role',
                          controller: _occupationController,
                        ),
                        const SizedBox(height: 14),
                        _ProfileTextField(
                          label: 'Education',
                          controller: _educationController,
                        ),
                        const SizedBox(height: 14),
                        _ProfileTextField(
                          label: 'City',
                          controller: _neighborhoodController,
                        ),
                        const SizedBox(height: 14),
                        _ProfileTextField(
                          label: 'About / Bio',
                          controller: _bioController,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 14),
                        _ProfileTextField(
                          label: 'Profile Prompt',
                          controller: _promptAnswerController,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _saveChanges,
                            child: const Text('Save Changes'),
                          ),
                        ),
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

class _ProfilePhotoTile extends StatelessWidget {
  const _ProfilePhotoTile({
    required this.photoUrl,
    required this.onTap,
  });

  final String? photoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: JDateTokens.pearlGlassBorder),
          ),
          child: photoUrl != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const ColoredBox(color: Color(0xFFE4E4E7)),
                    ),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: JDateTokens.brandRose,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Edit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: Icon(
                    Icons.add_rounded,
                    color: JDateTokens.brandRose,
                    size: 28,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
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
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: JDateTokens.pearlGlassBorder),
            ),
          ),
        ),
      ],
    );
  }
}
