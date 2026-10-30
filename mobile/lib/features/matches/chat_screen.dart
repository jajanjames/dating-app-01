// FILE: lib/features/matches/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/match_thread.dart';
import '../../data/repositories/dating_repository.dart';

/// Full-screen dedicated conversation screen for Naam (pushed above bottom navigation bar)
/// with live/last-seen presence indicator, match context banner, icebreaker chips, and message composer.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.initialThread,
  });

  final MatchThread initialThread;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late MatchThread _thread;

  static const List<String> _icebreakers = [
    'Chai or filter coffee this weekend?',
    'What is your favorite quiet spot in the city?',
    'Tell me the story behind your second photo!',
  ];

  @override
  void initState() {
    super.initState();
    _thread = widget.initialThread;
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendText(String rawText) {
    final text = rawText.trim();
    if (text.isEmpty) return;
    _textController.clear();

    final updated = ref.read(datingRepositoryProvider).appendViewerMessage(
          threadId: _thread.id,
          text: text,
        );
    ref.read(datingActivityRevisionProvider.notifier).state++;
    if (updated != null) {
      setState(() => _thread = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final partner = _thread.partner;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: Image.network(
                      partner.primaryImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const ColoredBox(color: Color(0xFFE4E4E7)),
                    ),
                  ),
                ),
                if (partner.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${partner.firstName}, ${partner.age}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (partner.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: JDateTokens.brandRose,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: partner.isOnline
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFA1A1AA),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          '${partner.lastSeenLabel} · ${partner.neighborhood}',
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
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
      body: Column(
        children: [
          const Divider(height: 1, color: Color(0xFFEFEFF4)),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              itemCount: _thread.messages.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Matched with ${partner.firstName} · ${partner.occupation} in ${partner.neighborhood}',
                        style: const TextStyle(
                          color: Color(0xFF71717A),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }
                final message = _thread.messages[index - 1];
                return _MessageBubble(message: message);
              },
            ),
          ),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFFCFCFD),
              border: Border(
                top: BorderSide(color: Color(0xFFF4F4F6)),
              ),
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _icebreakers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = _icebreakers[index];
                return Center(
                  child: _IcebreakerChip(
                    label: prompt,
                    onTap: () => _sendText(prompt),
                  ),
                );
              },
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEFEFF4))),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F7),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFEAEAEF)),
                        ),
                        child: TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                            hintText: 'Message ${partner.firstName}...',
                            border: InputBorder.none,
                          ),
                          onSubmitted: _sendText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    LiquidGlassOrbButton(
                      size: 44,
                      iconSize: 19,
                      icon: Icons.send_rounded,
                      tooltip: 'Send Message',
                      isPrimary: true,
                      onPressed: () => _sendText(_textController.text),
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

class _IcebreakerChip extends StatelessWidget {
  const _IcebreakerChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE4E4E7)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF3F3F46),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMe = message.isFromViewer;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
            constraints: const BoxConstraints(maxWidth: 280),
            decoration: BoxDecoration(
              color: isMe ? JDateTokens.brandRose : const Color(0xFFF1F1F4),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 6),
                bottomRight: Radius.circular(isMe ? 6 : 20),
              ),
            ),
            child: Text(
              message.text,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isMe ? Colors.white : JDateTokens.pitchBlack,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              isMe ? '${message.sentAtLabel} · Delivered' : message.sentAtLabel,
              style: const TextStyle(
                color: Color(0xFFA1A1AA),
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
