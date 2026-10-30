// FILE: lib/features/matches/likes_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/candidate_profile.dart';
import '../../data/repositories/dating_repository.dart';
import '../discovery/discovery_screen.dart';
import '../discovery/widgets/discovery_card.dart';
import 'chat_screen.dart';

/// Async provider supplying the Likes tab data (`Liked You` & `Your Likes`) with 4-state coverage.
final likesFeedProvider = FutureProvider.autoDispose<
    ({List<CandidateProfile> admirers, List<CandidateProfile> yourLikes})>(
  (ref) async {
    ref.watch(datingActivityRevisionProvider);
    final repo = ref.watch(datingRepositoryProvider);
    return (
      admirers: repo.getAdmirers(),
      yourLikes: repo.getLikedProfiles(),
    );
  },
);

/// Naam Likes Tab Screen:
/// - Segmented selector between `Liked You` (incoming admirers) and `Your Likes` (profiles you liked/starred)
/// - Liquid Glass Online / Last-Seen badge with glowing green dot on every card (zero pink Online pills)
/// - Instant Match & Message actions on every card
/// - Full 4-state UI coverage (`loading`, `error`, `empty`, `data`)
class LikesScreen extends ConsumerStatefulWidget {
  const LikesScreen({super.key});

  @override
  ConsumerState<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends ConsumerState<LikesScreen> {
  int _selectedSegment = 0; // 0 = Liked You, 1 = Your Likes

  void _handleInstantMatch(CandidateProfile candidate) {
    final repo = ref.read(datingRepositoryProvider);
    final thread = repo.registerMutualMatch(candidate);
    ref.read(datingActivityRevisionProvider.notifier).state++;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Matched with ${candidate.firstName}!'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ChatScreen(initialThread: thread),
      ),
    );
  }

  void _handleOpenChat(CandidateProfile candidate) {
    final repo = ref.read(datingRepositoryProvider);
    final thread = repo.registerMutualMatch(candidate);
    ref.read(datingActivityRevisionProvider.notifier).state++;

    Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ChatScreen(initialThread: thread),
      ),
    );
  }

  void _handleRemoveLike(CandidateProfile candidate) {
    ref.read(datingRepositoryProvider).removeLikedProfile(candidate.id);
    ref.read(datingActivityRevisionProvider.notifier).state++;
  }

  void _handleOpenProfile(CandidateProfile candidate) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (pageContext) => CandidateProfileDetailPage(
          candidate: candidate,
          canRewind: false,
          onRewind: () {},
          onSkip: () {
            Navigator.of(pageContext).pop();
            _handleRemoveLike(candidate);
          },
          onLike: () {
            Navigator.of(pageContext).pop();
            _handleInstantMatch(candidate);
          },
          onStar: () {
            Navigator.of(pageContext).pop();
            _handleInstantMatch(candidate);
          },
          onSendMessage: () {
            Navigator.of(pageContext).pop();
            _handleOpenChat(candidate);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncLikes = ref.watch(likesFeedProvider);

    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Likes',
                style: TextStyle(
                  color: JDateTokens.pitchBlack,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'People who already like you and profiles you saved.',
                style: TextStyle(
                  color: Color(0xFF71717A),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: asyncLikes.when(
                  loading: () => const _LikesStateView(
                    icon: Icons.favorite_outline_rounded,
                    title: 'Loading Likes',
                    subtitle: 'Checking your latest admirers and saved likes...',
                  ),
                  error: (err, _) => _LikesStateView(
                    icon: Icons.error_outline_rounded,
                    title: 'Unable to Load Likes',
                    subtitle: err.toString(),
                    actionLabel: 'Retry',
                    onAction: () => ref.invalidate(likesFeedProvider),
                  ),
                  data: (feed) {
                    final activeList = _selectedSegment == 0
                        ? feed.admirers
                        : feed.yourLikes;

                    return Column(
                      children: [
                        _LikesSegmentedBar(
                          selectedIndex: _selectedSegment,
                          admirerCount: feed.admirers.length,
                          yourLikesCount: feed.yourLikes.length,
                          onSelect: (index) {
                            setState(() => _selectedSegment = index);
                          },
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: activeList.isEmpty
                              ? _LikesStateView(
                                  icon: Icons.favorite_border_rounded,
                                  title: _selectedSegment == 0
                                      ? 'No New Admirers Yet'
                                      : 'No Saved Likes Yet',
                                  subtitle: _selectedSegment == 0
                                      ? 'Keep exploring on Discover to appear in more local decks.'
                                      : 'Tap the Heart or Star button on Discover to save profiles here.',
                                )
                              : GridView.builder(
                                  itemCount: activeList.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 14,
                                    crossAxisSpacing: 14,
                                    childAspectRatio: 0.72,
                                  ),
                                  itemBuilder: (context, index) {
                                    final person = activeList[index];
                                    return _LikeProfileGridCard(
                                      candidate: person,
                                      isAdmirerMode: _selectedSegment == 0,
                                      onTapCard: () =>
                                          _handleOpenProfile(person),
                                      onPrimaryAction: () =>
                                          _selectedSegment == 0
                                              ? _handleInstantMatch(person)
                                              : _handleOpenChat(person),
                                      onSecondaryAction: () =>
                                          _selectedSegment == 0
                                              ? _handleOpenChat(person)
                                              : _handleRemoveLike(person),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LikesSegmentedBar extends StatelessWidget {
  const _LikesSegmentedBar({
    required this.selectedIndex,
    required this.admirerCount,
    required this.yourLikesCount,
    required this.onSelect,
  });

  final int selectedIndex;
  final int admirerCount;
  final int yourLikesCount;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentTabButton(
              label: 'Liked You ($admirerCount)',
              isSelected: selectedIndex == 0,
              onTap: () => onSelect(0),
            ),
          ),
          Expanded(
            child: _SegmentTabButton(
              label: 'Your Likes ($yourLikesCount)',
              isSelected: selectedIndex == 1,
              onTap: () => onSelect(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentTabButton extends StatelessWidget {
  const _SegmentTabButton({
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
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x1218181B),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color:
                isSelected ? JDateTokens.pitchBlack : const Color(0xFF71717A),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _LikeProfileGridCard extends StatelessWidget {
  const _LikeProfileGridCard({
    required this.candidate,
    required this.isAdmirerMode,
    required this.onTapCard,
    required this.onPrimaryAction,
    required this.onSecondaryAction,
  });

  final CandidateProfile candidate;
  final bool isAdmirerMode;
  final VoidCallback onTapCard;
  final VoidCallback onPrimaryAction;
  final VoidCallback onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapCard,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              candidate.primaryImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const ColoredBox(color: Color(0xFFE4E4E7)),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x2809090B),
                    Color(0x0009090B),
                    Color(0x4509090B),
                    Color(0xE009090B),
                  ],
                  stops: [0.0, 0.35, 0.68, 1.0],
                ),
              ),
            ),
            // Top Row: Liquid Glass Online / Last Seen Badge + Verified Pill
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  LiquidGlassPresenceBadge(
                    isOnline: candidate.isOnline,
                    label: candidate.lastSeenLabel,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (candidate.isVerified) ...[
                          const Icon(
                            Icons.verified_rounded,
                            size: 12,
                            color: JDateTokens.brandRose,
                          ),
                          const SizedBox(width: 3),
                        ],
                        Text(
                          candidate.isVerified ? 'Verified' : 'Unverified',
                          style: const TextStyle(
                            color: JDateTokens.pitchBlack,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${candidate.firstName}, ${candidate.age}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${candidate.occupation} · ${candidate.neighborhood}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: onPrimaryAction,
                          child: Container(
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: JDateTokens.brandRose,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              isAdmirerMode ? 'Match' : 'Chat',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onSecondaryAction,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isAdmirerMode
                                ? Icons.chat_bubble_outline_rounded
                                : Icons.close_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
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

class _LikesStateView extends StatelessWidget {
  const _LikesStateView({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
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
            Icon(icon, size: 42, color: JDateTokens.brandRose),
            const SizedBox(height: 12),
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
              const SizedBox(height: 18),
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
