// FILE: lib/features/matches/likes_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/candidate_profile.dart';
import '../../data/repositories/dating_repository.dart';
import '../discovery/widgets/discovery_card.dart';
import 'chat_screen.dart';

/// Async provider supplying the Likes tab data (`Liked You`, `Your Likes`, and `profileNotes`) with 4-state coverage.
final likesFeedProvider = FutureProvider.autoDispose<
    ({
      List<CandidateProfile> admirers,
      List<CandidateProfile> yourLikes,
      Map<String, String> profileNotes,
    })>(
  (ref) async {
    ref.watch(datingActivityRevisionProvider);
    final repo = ref.watch(datingRepositoryProvider);
    return (
      admirers: repo.getAdmirers(),
      yourLikes: repo.getLikedProfiles(),
      profileNotes: repo.getProfileNotes(),
    );
  },
);

/// Naam Likes Tab Screen:
/// - No inline "Type a message... [Send]" box on cards and no top showcase strip.
/// - Tapping any profile card opens the Direct Message composer modal immediately.
/// - When an incoming Note or Star (Super Like) is present on a card, displays "Accept" and "Decline" action buttons.
/// - Full 4-state UI coverage (`loading`, `error`, `empty`, `data`).
class LikesScreen extends ConsumerStatefulWidget {
  const LikesScreen({super.key});

  @override
  ConsumerState<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends ConsumerState<LikesScreen> {
  int _selectedSegment = 0; // 0 = Liked You, 1 = Your Likes
  final Set<String> _declinedCandidateIds = <String>{};

  void _handleAcceptIncoming(CandidateProfile candidate) {
    final repo = ref.read(datingRepositoryProvider);
    final thread = repo.registerMutualMatch(candidate);
    ref.read(datingActivityRevisionProvider.notifier).state++;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Accepted ${candidate.firstName} — chat opened!'),
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

  void _handleDeclineIncoming(CandidateProfile candidate) {
    setState(() {
      _declinedCandidateIds.add(candidate.id);
    });
    ref.read(datingRepositoryProvider).removeLikedProfile(candidate.id);
    ref.read(datingActivityRevisionProvider.notifier).state++;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Declined ${candidate.firstName}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleSendDirectMessage(CandidateProfile candidate, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final repo = ref.read(datingRepositoryProvider);
    final thread = repo.sendDirectMessage(candidate: candidate, text: trimmed);
    ref.read(datingActivityRevisionProvider.notifier).state++;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Direct message sent to ${candidate.firstName}!'),
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

  void _openDirectMessageSheet(CandidateProfile candidate) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _DirectMessageComposerSheet(
        candidate: candidate,
        onSend: (messageText) {
          Navigator.of(sheetContext).pop();
          _handleSendDirectMessage(candidate, messageText);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncLikes = ref.watch(likesFeedProvider);
    final repo = ref.watch(datingRepositoryProvider);

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
                'Tap any profile to send a direct message, or Accept / Decline incoming notes and Super Likes.',
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
                    onAction: () => ref.invalidate(likesFeedProvider),
                  ),
                  data: (feed) {
                    final rawList = _selectedSegment == 0
                        ? feed.admirers
                        : feed.yourLikes;
                    final activeList = rawList
                        .where((c) => !_declinedCandidateIds.contains(c.id))
                        .toList(growable: false);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LikesSegmentedBar(
                          selectedIndex: _selectedSegment,
                          admirerCount: feed.admirers
                              .where(
                                  (c) => !_declinedCandidateIds.contains(c.id))
                              .length,
                          yourLikesCount: feed.yourLikes
                              .where(
                                  (c) => !_declinedCandidateIds.contains(c.id))
                              .length,
                          onSelect: (index) {
                            setState(() => _selectedSegment = index);
                          },
                        ),
                        const SizedBox(height: 14),
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
                                    childAspectRatio: 0.66,
                                  ),
                                  itemBuilder: (context, index) {
                                    final person = activeList[index];
                                    final isSuperLiked =
                                        person.isSuperLiked ||
                                            repo.isStarred(person.id);
                                    final incomingNote =
                                        feed.profileNotes[person.id] ??
                                            person.paidIntroMessage;

                                    return _LikeProfileGridCard(
                                      candidate: person,
                                      isSuperLiked: isSuperLiked,
                                      incomingNote: incomingNote,
                                      onTapCard: () =>
                                          _openDirectMessageSheet(person),
                                      onAccept: () =>
                                          _handleAcceptIncoming(person),
                                      onDecline: () =>
                                          _handleDeclineIncoming(person),
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
    required this.isSuperLiked,
    required this.incomingNote,
    required this.onTapCard,
    required this.onAccept,
    required this.onDecline,
  });

  final CandidateProfile candidate;
  final bool isSuperLiked;
  final String? incomingNote;
  final VoidCallback onTapCard;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final hasIncomingNoteOrStar =
        isSuperLiked || (incomingNote != null && incomingNote!.isNotEmpty);

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
                    if (hasIncomingNoteOrStar)
                      _IncomingNoteOrStarBox(
                        isSuperLiked: isSuperLiked,
                        incomingNote: incomingNote,
                        onAccept: onAccept,
                        onDecline: onDecline,
                      )
                    else
                      const _DirectMessageHintPill(),
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
    required this.onAccept,
    required this.onDecline,
  });

  final bool isSuperLiked;
  final String? incomingNote;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
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
                isSuperLiked ? Icons.star_rounded : Icons.chat_bubble_rounded,
                size: 12,
                color: JDateTokens.brandRose,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  isSuperLiked ? 'Sent you a Super Like' : 'Sent you a note',
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
          if (incomingNote != null && incomingNote!.isNotEmpty) ...[
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
                  onTap: onAccept,
                  child: Container(
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: JDateTokens.brandRose,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Accept',
                      style: TextStyle(
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
                  onTap: onDecline,
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

class _DirectMessageHintPill extends StatelessWidget {
  const _DirectMessageHintPill();

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
            Icons.chat_bubble_outline_rounded,
            size: 11,
            color: Colors.white,
          ),
          SizedBox(width: 5),
          Flexible(
            child: Text(
              'Tap to send direct message',
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

class _DirectMessageComposerSheet extends StatefulWidget {
  const _DirectMessageComposerSheet({
    required this.candidate,
    required this.onSend,
  });

  final CandidateProfile candidate;
  final ValueChanged<String> onSend;

  @override
  State<_DirectMessageComposerSheet> createState() =>
      _DirectMessageComposerSheetState();
}

class _DirectMessageComposerSheetState
    extends State<_DirectMessageComposerSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 14, 14, bottomInset + 16),
      child: LiquidGlassSurface(
        borderRadius: 24,
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Direct Message ${widget.candidate.firstName}',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Send a direct message to start chatting immediately with ${widget.candidate.firstName}.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'Write a direct message to ${widget.candidate.firstName}...',
                filled: true,
                fillColor: const Color(0xFFF8F8FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => widget.onSend(_controller.text),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Send Direct Message'),
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
