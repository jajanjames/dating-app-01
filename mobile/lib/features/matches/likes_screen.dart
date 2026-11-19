// FILE: lib/features/matches/likes_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/candidate_profile.dart';
import '../../data/models/social_models.dart';
import '../discovery/widgets/discovery_card.dart';
import 'chat_screen.dart';
import 'likes_controller.dart';

/// Naam Likes Tab Screen:
/// - `Liked You`: every incoming like, Super Like (star) and note, each with "Accept" and "Decline".
///   Accept likes them back and opens the chat; Decline passes (the other person is not told).
/// - `Your Likes`: likes you sent from Discover that are waiting for an answer.
/// - Likes are only sent from Discover; there is no messaging before a match.
/// - Live updates from the `like` / `match` socket events; full 4-state UI coverage.
class LikesScreen extends ConsumerStatefulWidget {
  const LikesScreen({super.key});

  @override
  ConsumerState<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends ConsumerState<LikesScreen> {
  int _selectedSegment = 0; // 0 = Liked You, 1 = Your Likes
  final Set<String> _busyUserIds = <String>{};

  Future<void> _handleAcceptIncoming(LikeItem like) async {
    if (!_busyUserIds.add(like.userId)) return;
    setState(() {});
    try {
      final thread =
          await ref.read(likesControllerProvider.notifier).accept(like);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("It's a match with ${like.profile.firstName}!"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => ChatScreen(initialThread: thread),
        ),
      );
    } on ApiException catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busyUserIds.remove(like.userId));
    }
  }

  Future<void> _handleDeclineIncoming(LikeItem like) async {
    if (!_busyUserIds.add(like.userId)) return;
    setState(() {});
    try {
      await ref.read(likesControllerProvider.notifier).reject(like);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Declined ${like.profile.firstName}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ApiException catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busyUserIds.remove(like.userId));
    }
  }

  void _showError(ApiException e) {
    if (!mounted) return;
    // 404 / 409: the like is no longer pending; resync the list.
    if (e.statusCode == 404 || e.statusCode == 409) {
      ref.read(likesControllerProvider.notifier).refresh();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
    );
  }

  void _showPendingHint(LikeItem like) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "You'll be notified when ${like.profile.firstName} likes you back.",
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncLikes = ref.watch(likesControllerProvider);

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
                'Accept a like, Super Like or note to start chatting, or Decline it. Likes are sent from Discover.',
                style: TextStyle(
                  color: Color(0xFF71717A),
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: asyncLikes.when(
                  loading: () => const _LikesStateView(
                    icon: Icons.favorite_outline_rounded,
                    title: 'Loading Likes',
                    subtitle:
                        'Checking your latest admirers, Super Likes, and incoming notes...',
                  ),
                  error: (err, _) => _LikesStateView(
                    icon: Icons.error_outline_rounded,
                    title: 'Unable to Load Likes',
                    subtitle: err.toString(),
                    actionLabel: 'Retry',
                    onAction: () => ref.invalidate(likesControllerProvider),
                  ),
                  data: (feed) {
                    final isReceived = _selectedSegment == 0;
                    final activeList = isReceived ? feed.received : feed.sent;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LikesSegmentedBar(
                          selectedIndex: _selectedSegment,
                          admirerCount: feed.received.length,
                          yourLikesCount: feed.sent.length,
                          onSelect: (index) {
                            setState(() => _selectedSegment = index);
                          },
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: RefreshIndicator(
                            color: JDateTokens.brandRose,
                            onRefresh: () => ref
                                .read(likesControllerProvider.notifier)
                                .refresh(),
                            child: activeList.isEmpty
                                ? ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      const SizedBox(height: 60),
                                      _LikesStateView(
                                        icon: Icons.favorite_border_rounded,
                                        title: isReceived
                                            ? 'No New Admirers Yet'
                                            : 'No Pending Likes',
                                        subtitle: isReceived
                                            ? 'Keep exploring on Discover to appear in more local decks.'
                                            : 'Tap the Heart or Star button on Discover to like profiles. Matches move to Chats.',
                                      ),
                                    ],
                                  )
                                : GridView.builder(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    itemCount: activeList.length,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 14,
                                      crossAxisSpacing: 14,
                                      childAspectRatio: 0.66,
                                    ),
                                    itemBuilder: (context, index) {
                                      final like = activeList[index];
                                      return _LikeProfileGridCard(
                                        candidate: like.profile,
                                        isSuperLiked: like.isPremium,
                                        incomingNote: like.note,
                                        isIncoming: isReceived,
                                        isBusy:
                                            _busyUserIds.contains(like.userId),
                                        onTapCard: isReceived
                                            ? null
                                            : () => _showPendingHint(like),
                                        onAccept: () =>
                                            _handleAcceptIncoming(like),
                                        onDecline: () =>
                                            _handleDeclineIncoming(like),
                                      );
                                    },
                                  ),
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
    required this.isSuperLiked,
    required this.incomingNote,
    required this.isIncoming,
    required this.isBusy,
    required this.onTapCard,
    required this.onAccept,
    required this.onDecline,
  });

  final CandidateProfile candidate;
  final bool isSuperLiked;
  final String? incomingNote;

  /// `Liked You` card (Accept / Decline) vs `Your Likes` card (pending).
  final bool isIncoming;
  final bool isBusy;
  final VoidCallback? onTapCard;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapCard,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: isSuperLiked
              ? Border.all(color: JDateTokens.solarYellow, width: 2.5)
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isSuperLiked ? 19.5 : 22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              NaamProfileImage(
                imageUrl: candidate.primaryImageUrl,
                fit: BoxFit.cover,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x2809090B),
                      Color(0x0009090B),
                      Color(0x5509090B),
                      Color(0xEB09090B),
                    ],
                    stops: [0.0, 0.30, 0.62, 1.0],
                  ),
                ),
              ),
              // Top Row: Liquid Glass Online Badge + Yellow Super Like Circle
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSuperLiked) ...[
                          const _YellowSuperLikeCircleBadge(),
                          const SizedBox(width: 4),
                        ],
                        if (candidate.isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.90),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Icon(
                              Icons.verified_rounded,
                              size: 12,
                              color: JDateTokens.brandRose,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
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
                        fontSize: 16,
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
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isIncoming)
                      _IncomingNoteOrStarBox(
                        isSuperLiked: isSuperLiked,
                        incomingNote: incomingNote,
                        isBusy: isBusy,
                        onAccept: onAccept,
                        onDecline: onDecline,
                      )
                    else
                      const _PendingLikeHintPill(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncomingNoteOrStarBox extends StatelessWidget {
  const _IncomingNoteOrStarBox({
    required this.isSuperLiked,
    required this.incomingNote,
    required this.isBusy,
    required this.onAccept,
    required this.onDecline,
  });

  final bool isSuperLiked;
  final String? incomingNote;
  final bool isBusy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  bool get _hasNote => incomingNote != null && incomingNote!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final headline = isSuperLiked
        ? 'Sent you a Super Like'
        : (_hasNote ? 'Sent you a note' : 'Likes you');
    final icon = isSuperLiked
        ? Icons.star_rounded
        : (_hasNote ? Icons.chat_bubble_rounded : Icons.favorite_rounded);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 12,
                color: JDateTokens.brandRose,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  headline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: JDateTokens.brandRose,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (_hasNote) ...[
            const SizedBox(height: 3),
            Text(
              '“$incomingNote”',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: JDateTokens.pitchBlack,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ],
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: isBusy ? null : onAccept,
                  child: Container(
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: JDateTokens.brandRose,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isBusy ? '...' : 'Accept',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: GestureDetector(
                  onTap: isBusy ? null : onDecline,
                  child: Container(
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F5),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFE4E4E7)),
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                        color: Color(0xFF3F3F46),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

class _PendingLikeHintPill extends StatelessWidget {
  const _PendingLikeHintPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.hourglass_top_rounded,
            size: 11,
            color: Colors.white,
          ),
          SizedBox(width: 5),
          Flexible(
            child: Text(
              'Waiting for a like back',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _YellowSuperLikeCircleBadge extends StatelessWidget {
  const _YellowSuperLikeCircleBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: JDateTokens.solarYellow,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66FACC15),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        Icons.star_rounded,
        size: 15,
        color: JDateTokens.pitchBlack,
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
