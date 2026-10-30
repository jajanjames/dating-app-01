// FILE: lib/features/matches/chats_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/candidate_profile.dart';
import '../../data/models/match_thread.dart';
import '../../data/repositories/dating_repository.dart';
import 'chat_screen.dart';

/// Provider supplying active chat threads and new mutual matches with 4-state coverage.
final chatsInboxProvider = FutureProvider.autoDispose<
    ({List<MatchThread> threads, List<CandidateProfile> priorityIntros})>(
  (ref) async {
    ref.watch(datingActivityRevisionProvider);
    final repo = ref.watch(datingRepositoryProvider);
    return (
      threads: repo.getMatches(),
      priorityIntros: repo.getPriorityIntroProfiles(),
    );
  },
);

/// Provider exposing the total unread chat count for the bottom tab badge.
final unreadChatsCountProvider = Provider<int>((ref) {
  ref.watch(datingActivityRevisionProvider);
  final threads = ref.watch(datingRepositoryProvider).getMatches();
  var count = 0;
  for (final thread in threads) {
    count += thread.unreadCount;
  }
  return count;
});

/// Naam Chats Tab Screen:
/// - Horizontal New Connections & Priority Intros strip
/// - Full conversation list with unread count and instant reply
/// - 4-state UI coverage (`loading`, `error`, `empty`, `data`)
class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  void _openThread(
    BuildContext context,
    WidgetRef ref,
    MatchThread thread,
  ) {
    ref.read(datingRepositoryProvider).markThreadRead(thread.id);
    ref.read(datingActivityRevisionProvider.notifier).state++;

    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ChatScreen(initialThread: thread),
      ),
    );
  }

  void _openIntroCandidate(
    BuildContext context,
    WidgetRef ref,
    CandidateProfile candidate,
  ) {
    final repo = ref.read(datingRepositoryProvider);
    final thread = repo.registerMutualMatch(candidate);
    ref.read(datingActivityRevisionProvider.notifier).state++;
    _openThread(context, ref, thread);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncInbox = ref.watch(chatsInboxProvider);

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
                    onAction: () => ref.invalidate(chatsInboxProvider),
                  ),
                  data: (inbox) {
                    if (inbox.threads.isEmpty && inbox.priorityIntros.isEmpty) {
                      return const _ChatsStateView(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'No Conversations Yet',
                        subtitle:
                            'Like or message someone on Discover to start your first conversation.',
                      );
                    }

                    return ListView(
                      children: [
                        if (inbox.priorityIntros.isNotEmpty) ...[
                          const Text(
                            'New Connections',
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
                              itemCount: inbox.priorityIntros.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 14),
                              itemBuilder: (context, index) {
                                final person = inbox.priorityIntros[index];
                                return _NewConnectionAvatarItem(
                                  candidate: person,
                                  onTap: () =>
                                      _openIntroCandidate(context, ref, person),
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
                        ...inbox.threads.map(
                          (thread) => _ChatThreadListRow(
                            thread: thread,
                            onTap: () => _openThread(context, ref, thread),
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

class _NewConnectionAvatarItem extends StatelessWidget {
  const _NewConnectionAvatarItem({
    required this.candidate,
    required this.onTap,
  });

  final CandidateProfile candidate;
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
            Container(
              width: 66,
              height: 66,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: JDateTokens.brandRose,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.network(
                  candidate.primaryImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const ColoredBox(color: Color(0xFFE4E4E7)),
                ),
              ),
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
                child: Image.network(
                  partner.primaryImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const ColoredBox(color: Color(0xFFE4E4E7)),
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
                    lastMsg?.text ?? 'Say hello to ${partner.firstName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasUnread
                          ? JDateTokens.pitchBlack
                          : const Color(0xFF71717A),
                      fontSize: 14,
                      fontWeight:
                          hasUnread ? FontWeight.w600 : FontWeight.w400,
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
                  lastMsg?.sentAtLabel ?? thread.matchedAtLabel,
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
