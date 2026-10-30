// FILE: lib/features/discovery/discovery_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/candidate_profile.dart';
import 'discovery_controller.dart';
import 'widgets/discovery_card.dart';
import 'widgets/filter_preferences_sheet.dart';

/// Main Naam Discover tab screen:
/// - Top Header: Compact Naam logo (height: 24) on the left + circular Filter Preferences button on the right
/// - Larger Fixed-Size Portrait Card + 5 Circular Action Buttons with micro-interactions below the card
class DiscoveryScreen extends ConsumerWidget {
  const DiscoveryScreen({super.key});

  void _openFilterSheet(BuildContext context, WidgetRef ref) {
    final currentPrefs =
        ref.read(discoveryControllerProvider).valueOrNull?.preferences ??
            ref.read(filterPreferencesProvider);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => FilterPreferencesSheet(
        initialPreferences: currentPrefs,
        onApply: (updated) {
          ref
              .read(discoveryControllerProvider.notifier)
              .updatePreferences(updated);
        },
      ),
    );
  }

  void _openQuickMessageSheet(
    BuildContext context,
    WidgetRef ref,
    CandidateProfile candidate,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _QuickMessageComposerSheet(
        candidate: candidate,
        onSend: (text) async {
          await ref
              .read(discoveryControllerProvider.notifier)
              .sendIntroMessageFromDiscovery(
                candidate: candidate,
                messageText: text,
              );
          if (!sheetContext.mounted) return;
          Navigator.of(sheetContext).pop();
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Intro sent to ${candidate.firstName}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  void _openFullProfilePage(
    BuildContext context,
    WidgetRef ref,
    CandidateProfile candidate,
    bool canRewind,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (pageContext) => CandidateProfileDetailPage(
          candidate: candidate,
          canRewind: canRewind,
          onRewind: () {
            Navigator.of(pageContext).pop();
            ref.read(discoveryControllerProvider.notifier).rewindLastSwipe();
          },
          onSkip: () {
            Navigator.of(pageContext).pop();
            ref
                .read(discoveryControllerProvider.notifier)
                .swipeCurrent(isLike: false);
          },
          onLike: () {
            Navigator.of(pageContext).pop();
            ref
                .read(discoveryControllerProvider.notifier)
                .swipeCurrent(isLike: true);
          },
          onStar: () {
            Navigator.of(pageContext).pop();
            ref
                .read(discoveryControllerProvider.notifier)
                .swipeCurrent(isLike: true, isSuperLike: true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Star sent to ${candidate.firstName}'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          onSendMessage: () {
            Navigator.of(pageContext).pop();
            _openQuickMessageSheet(context, ref, candidate);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDiscovery = ref.watch(discoveryControllerProvider);

    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Naam Brand Header + Discover-Only Filter Orb
              _NaamTopBar(
                onOpenFilters: () => _openFilterSheet(context, ref),
              ),
              const SizedBox(height: 10),

              // 2. 4-State Discovery Stage (Loading / Error / Empty / Data)
              Expanded(
                child: asyncDiscovery.when(
                  loading: () => const _DiscoveryStateCard(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Finding Connections',
                    subtitle: 'Curating verified profiles nearby...',
                  ),
                  error: (err, _) => _DiscoveryStateCard(
                    icon: Icons.wifi_tethering_error_rounded,
                    title: 'Connection Interrupted',
                    subtitle: err.toString(),
                    actionLabel: 'Retry',
                    onAction: () => ref.invalidate(discoveryControllerProvider),
                  ),
                  data: (state) {
                    final current = state.currentCandidate;
                    if (current == null) {
                      return _DiscoveryStateCard(
                        icon: Icons.favorite_outline_rounded,
                        title: 'You Are All Caught Up',
                        subtitle:
                            'Adjust your filter preferences or reload your Naam discovery deck.',
                        actionLabel: 'Reload Profiles',
                        onAction: () {
                          ref
                              .read(discoveryControllerProvider.notifier)
                              .resetDeck();
                        },
                      );
                    }

                    return DiscoveryCard(
                      candidate: current,
                      canRewind: state.canRewind,
                      onRewind: () => ref
                          .read(discoveryControllerProvider.notifier)
                          .rewindLastSwipe(),
                      onPass: () => ref
                          .read(discoveryControllerProvider.notifier)
                          .swipeCurrent(isLike: false),
                      onLike: () => ref
                          .read(discoveryControllerProvider.notifier)
                          .swipeCurrent(isLike: true),
                      onSuperLike: () {
                        ref
                            .read(discoveryControllerProvider.notifier)
                            .swipeCurrent(isLike: true, isSuperLike: true);
                      },
                      onOpenQuickMessage: () =>
                          _openQuickMessageSheet(context, ref, current),
                      onOpenFullDetails: () => _openFullProfilePage(
                        context,
                        ref,
                        current,
                        state.canRewind,
                      ),
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

class _NaamTopBar extends StatelessWidget {
  const _NaamTopBar({required this.onOpenFilters});

  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const NaamBrandLogo(height: 24),
        GestureDetector(
          onTap: onOpenFilters,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF6F6F9),
              border: Border.all(color: const Color(0xFFEAEAEF)),
            ),
            child: const Center(
              child: Icon(
                Icons.tune_rounded,
                size: 19,
                color: Color(0xFF27272A),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Full-Screen Sequential Profile Story Page:
/// 1. Sequence 1: Photo 1 + Name, Job Role, What They Do, and Location
/// 2. Sequence 2: Photo 2 + Story Description & Prompt
/// 3. Sequence 3: Photo 3 + Lifestyle Description & Unboxed Metadata
class CandidateProfileDetailPage extends StatelessWidget {
  const CandidateProfileDetailPage({
    super.key,
    required this.candidate,
    required this.canRewind,
    required this.onRewind,
    required this.onSkip,
    required this.onLike,
    required this.onStar,
    required this.onSendMessage,
  });

  final CandidateProfile candidate;
  final bool canRewind;
  final VoidCallback onRewind;
  final VoidCallback onSkip;
  final VoidCallback onLike;
  final VoidCallback onStar;
  final VoidCallback onSendMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photo1 =
        candidate.imageUrls.isNotEmpty ? candidate.imageUrls[0] : '';
    final photo2 =
        candidate.imageUrls.length > 1 ? candidate.imageUrls[1] : photo1;
    final photo3 =
        candidate.imageUrls.length > 2 ? candidate.imageUrls[2] : photo1;

    final whatTheyDoText = candidate.whatTheyDo.isNotEmpty
        ? candidate.whatTheyDo
        : '${candidate.occupation} · ${candidate.education}';
    final story2Text = candidate.storyDescription.isNotEmpty
        ? candidate.storyDescription
        : candidate.bio;
    final story3Text = candidate.lifestyleStory.isNotEmpty
        ? candidate.lifestyleStory
        : 'Looking for ${candidate.intention.toLowerCase()} · ${candidate.lifestyle}';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Flexible(
              child: Text(
                '${candidate.firstName}, ${candidate.age}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (candidate.isVerified) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.verified_rounded,
                size: 20,
                color: JDateTokens.brandRose,
              ),
            ],
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: LiquidGlassOrbButton(
              size: 42,
              iconSize: 20,
              icon: Icons.close_rounded,
              tooltip: 'Close Profile',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          // SEQUENCE 1: Photo 1 + Name, Job Role, What They Do, and Location
          _SequencePhotoCard(imageUrl: photo1),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8FA),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFEFEFF4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${candidate.name}, ${candidate.age}',
                        style: theme.textTheme.headlineMedium,
                      ),
                    ),
                    if (candidate.isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified_rounded,
                        size: 20,
                        color: JDateTokens.brandRose,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${candidate.occupation} · ${candidate.neighborhood} · ${candidate.distanceKm} km away',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: JDateTokens.brandRose,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  whatTheyDoText,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  candidate.bio,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // SEQUENCE 2: Photo 2 + Description / Something About Them
          _SequencePhotoCard(imageUrl: photo2),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8FA),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFEFEFF4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About ${candidate.firstName}',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  story2Text,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFE8E8ED)),
                const SizedBox(height: 14),
                Text(
                  candidate.prompt.question,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: JDateTokens.brandRose,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '"${candidate.prompt.answer}"',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // SEQUENCE 3: Photo 3 + More About Them & Unboxed Metadata
          _SequencePhotoCard(imageUrl: photo3),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8FA),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFEFEFF4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Life & Interests',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  story3Text,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  '${candidate.heightLabel} · ${candidate.zodiac} · ${candidate.education}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: JDateTokens.pitchBlack,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  candidate.interests.join(' · '),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEFEFF4))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LiquidGlassOrbButton(
                  size: 46,
                  iconSize: 20,
                  icon: Icons.undo_rounded,
                  tooltip: 'Reverse',
                  onPressed: canRewind ? onRewind : null,
                ),
                const SizedBox(width: 12),
                LiquidGlassOrbButton(
                  size: 54,
                  iconSize: 22,
                  icon: Icons.close_rounded,
                  tooltip: 'Skip',
                  onPressed: onSkip,
                ),
                const SizedBox(width: 12),
                LiquidGlassOrbButton(
                  size: 64,
                  iconSize: 28,
                  icon: Icons.favorite_border_rounded,
                  tooltip: 'Like',
                  isPrimary: true,
                  onPressed: onLike,
                ),
                const SizedBox(width: 12),
                LiquidGlassOrbButton(
                  size: 54,
                  iconSize: 22,
                  icon: Icons.star_border_rounded,
                  tooltip: 'Star',
                  onPressed: onStar,
                ),
                const SizedBox(width: 12),
                LiquidGlassOrbButton(
                  size: 46,
                  iconSize: 20,
                  icon: Icons.chat_bubble_outline_rounded,
                  tooltip: 'Message',
                  onPressed: onSendMessage,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SequencePhotoCard extends StatelessWidget {
  const _SequencePhotoCard({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const ColoredBox(color: Color(0xFFE4E4E7)),
              )
            : const ColoredBox(color: Color(0xFFE4E4E7)),
      ),
    );
  }
}

class _QuickMessageComposerSheet extends StatefulWidget {
  const _QuickMessageComposerSheet({
    required this.candidate,
    required this.onSend,
  });

  final CandidateProfile candidate;
  final ValueChanged<String> onSend;

  @override
  State<_QuickMessageComposerSheet> createState() =>
      _QuickMessageComposerSheetState();
}

class _QuickMessageComposerSheetState
    extends State<_QuickMessageComposerSheet> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
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
              'Message ${widget.candidate.firstName}',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Send a thoughtful note along with your like.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _messageController,
              autofocus: true,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'Ask ${widget.candidate.firstName} about ${widget.candidate.neighborhood}...',
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
              onPressed: () => widget.onSend(_messageController.text),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Send Message'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoveryStateCard extends StatelessWidget {
  const _DiscoveryStateCard({
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
      child: LiquidGlassSurface(
        borderRadius: 24,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: theme.colorScheme.primary),
            const SizedBox(height: 14),
            Text(
              title,
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
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
