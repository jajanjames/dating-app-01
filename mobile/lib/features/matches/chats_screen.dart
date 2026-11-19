// FILE: lib/features/matches/chats_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/candidate_profile.dart';
import '../../data/models/match_thread.dart';
import '../../data/models/social_models.dart';
import 'chat_screen.dart';
import 'chats_controller.dart';

/// Naam Chats Tab Screen:
/// - Horizontal New Matches strip (matches without messages) with yellow Super Like circle badge and ring
/// - Full conversation list with unread count, kept live by the `message` / `match` socket events
/// - 4-state UI coverage (`loading`, `error`, `empty`, `data`)
class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  void _openThread(
    BuildContext context,
    WidgetRef ref,
    MatchThread thread,
  ) {
    ref.read(chatInboxProvider.notifier).markRead(thread.id);

    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ChatScreen(initialThread: thread),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncInbox = ref.watch(chatInboxProvider);

    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chats',
                style: TextStyle(
                  color: JDateTokens.pitchBlack,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Meaningful conversations with your connections.',
                style: TextStyle(
                  color: Color(0xFF71717A),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: asyncInbox.when(
                  loading: () => const _ChatsStateView(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Loading Conversations',
                    subtitle: 'Syncing your latest messages...',
                  ),
                  error: (err, _) => _ChatsStateView(
                    icon: Icons.error_outline_rounded,
                    title: 'Could Not Load Chats',
                    subtitle: err.toString(),
                    actionLabel: 'Retry',
                    onAction: () => ref.invalidate(chatInboxProvider),
                  ),
                  data: (inbox) {
                    Future<void> onRefresh() =>
                        ref.read(chatInboxProvider.notifier).refresh();

                    if (inbox.conversations.isEmpty &&
                        inbox.newMatches.isEmpty) {
                      return RefreshIndicator(
                        color: JDateTokens.brandRose,
                        onRefresh: onRefresh,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 60),
                            _ChatsStateView(
                              icon: Icons.chat_bubble_outline_rounded,
                              title: 'No Conversations Yet',
                              subtitle:
                                  'Like someone on Discover, or accept a like, to start your first conversation.',
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      color: JDateTokens.brandRose,
                      onRefresh: onRefresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          if (inbox.newMatches.isNotEmpty) ...[
                            const Text(
                              'New Matches',
                              style: TextStyle(
                                color: JDateTokens.pitchBlack,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 98,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: inbox.newMatches.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 14),
                                itemBuilder: (context, index) {
                                  final thread = inbox.newMatches[index];
                                  return _NewConnectionAvatarItem(
                                    candidate: thread.partner,
                                    isSuperLiked: thread.isSuperMatch,
                                    onTap: () =>
                                        _openThread(context, ref, thread),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 18),
                          ],
                          const Text(
                            'Messages',
                            style: TextStyle(
                              color: JDateTokens.pitchBlack,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (inbox.conversations.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'Tap a new match above to say hello.',
                                style: TextStyle(
                                  color: Color(0xFF71717A),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ...inbox.conversations.map(
                            (thread) => _ChatThreadListRow(
                              thread: thread,
                              onTap: () => _openThread(context, ref, thread),
                            ),
                          ),
                        ],
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

class _NewConnectionAvatarItem extends StatelessWidget {
  const _NewConnectionAvatarItem({
    required this.candidate,
    required this.isSuperLiked,
    required this.onTap,
  });

  final CandidateProfile candidate;
  final bool isSuperLiked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 66,
                  height: 66,
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSuperLiked
                          ? JDateTokens.solarYellow
                          : JDateTokens.brandRose,
                      width: 2.5,
                    ),
                  ),
                  child: ClipOval(
                    child: NaamProfileImage(
                      imageUrl: candidate.primaryImageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (isSuperLiked)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: JDateTokens.solarYellow,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x55FACC15),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: JDateTokens.pitchBlack,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              candidate.firstName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: JDateTokens.pitchBlack,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatThreadListRow extends StatelessWidget {
  const _ChatThreadListRow({
    required this.thread,
    required this.onTap,
  });

  final MatchThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final partner = thread.partner;
    final lastMsg = thread.lastMessage;
    final hasUnread = thread.unreadCount > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFF3F3F6), width: 1),
          ),
        ),
        child: Row(
          children: [
            ClipOval(
              child: SizedBox(
                width: 56,
                height: 56,
                child: NaamProfileImage(
                  imageUrl: partner.primaryImageUrl,
                  fit: BoxFit.cover,
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
                          '${partner.firstName}, ${partner.age}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: JDateTokens.pitchBlack,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      if (partner.isVerified) ...[
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: JDateTokens.brandRose,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMsg == null
                        ? 'Say hello to ${partner.firstName}'
                        : '${lastMsg.isFromViewer ? 'You: ' : ''}${lastMsg.text}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasUnread
                          ? JDateTokens.pitchBlack
                          : const Color(0xFF71717A),
                      fontSize: 14,
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  lastMsg?.createdAt != null
                      ? relativeLabel(lastMsg!.createdAt!)
                      : (lastMsg?.sentAtLabel ?? thread.matchedAtLabel),
                  style: TextStyle(
                    color: hasUnread
                        ? JDateTokens.brandRose
                        : const Color(0xFFA1A1AA),
                    fontSize: 12,
                    fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (hasUnread) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: JDateTokens.brandRose,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${thread.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatsStateView extends StatelessWidget {
  const _ChatsStateView({
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
