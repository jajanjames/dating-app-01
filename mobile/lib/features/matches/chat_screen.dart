// FILE: lib/features/matches/chat_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/realtime/realtime_service.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/match_thread.dart';
import '../../data/models/social_models.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/interests_repository.dart';
import 'chats_controller.dart';

/// Full-screen dedicated conversation screen for Naam (pushed above bottom navigation bar)
/// with live/last-seen presence indicator, match context banner, icebreaker chips, and message composer.
///
/// Messages are sent over the realtime socket (REST fallback) and arrive on the
/// single `message` socket event. Women can always reply; men need a plan.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    this.initialThread,
    this.conversationId,
  }) : assert(initialThread != null || conversationId != null);

  final MatchThread? initialThread;

  /// Used when opened from a push notification (no thread loaded yet).
  final String? conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  late final StateController<String?> _openConversation;

  MatchThread? _thread;

  /// Oldest first.
  List<ChatMessage> _messages = const [];
  bool _loading = true;
  String? _loadError;
  String? _olderCursor;
  bool _hasOlder = false;
  bool _loadingOlder = false;

  static const List<String> _icebreakers = [
    'Chai or filter coffee this weekend?',
    'What is your favorite quiet spot in the city?',
    'Tell me the story behind your second photo!',
  ];

  String get _conversationId =>
      widget.initialThread?.id ?? widget.conversationId!;

  @override
  void initState() {
    super.initState();
    _thread = widget.initialThread;
    _openConversation = ref.read(openConversationIdProvider.notifier);
    Future.microtask(() => _openConversation.state = _conversationId);

    final realtime = ref.read(realtimeServiceProvider);
    _subscriptions
      ..add(realtime.onMessage.listen(_onSocketMessage))
      ..add(realtime.onRead.listen(_onSocketRead))
      ..add(realtime.onReconnect.listen((_) => _load()));
    _scrollController.addListener(_maybeLoadOlder);
    _load();
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    final openConversation = _openConversation;
    final id = _conversationId;
    Future.microtask(() {
      if (openConversation.state == id) openConversation.state = null;
    });
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = ref.read(chatRepositoryProvider);
    try {
      if (_thread == null) {
        final labels = await ref.read(interestLabelsProvider.future);
        final thread = await repo.conversation(_conversationId, labels);
        if (!mounted) return;
        setState(() => _thread = thread);
      }
      final page = await repo.messages(_conversationId);
      if (!mounted) return;
      setState(() {
        final pending =
            _messages.where((m) => m.status != MessageSendStatus.sent);
        _messages = [...page.messages, ...pending];
        _olderCursor = page.nextCursor;
        _hasOlder = page.hasMore;
        _loading = false;
        _loadError = null;
      });
      _markRead();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.message;
      });
    }
  }

  /// The list is reversed, so "older" is near the max scroll extent.
  Future<void> _maybeLoadOlder() async {
    if (!_hasOlder || _loadingOlder || _olderCursor == null) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 200) return;
    _loadingOlder = true;
    try {
      final page = await ref
          .read(chatRepositoryProvider)
          .messages(_conversationId, cursor: _olderCursor);
      if (!mounted) return;
      setState(() {
        final known = _messages.map((m) => m.id).toSet();
        _messages = [
          ...page.messages.where((m) => !known.contains(m.id)),
          ..._messages,
        ];
        _olderCursor = page.nextCursor;
        _hasOlder = page.hasMore;
      });
    } on ApiException {
      // Try again on the next scroll.
    } finally {
      _loadingOlder = false;
    }
  }

  void _markRead() {
    ref.read(chatInboxProvider.notifier).markRead(_conversationId);
    final hasUnread = _messages.any((m) => !m.isFromViewer && m.readAt == null);
    if (!hasUnread) return;
    final realtime = ref.read(realtimeServiceProvider);
    realtime.markRead(_conversationId).catchError((Object _) async {
      await ref.read(chatRepositoryProvider).markRead(_conversationId);
      return <String, dynamic>{};
    }).ignore();
  }

  void _onSocketMessage(Map<String, dynamic> event) {
    final raw = event['message'];
    if (event['conversationId'] != _conversationId ||
        raw is! Map<String, dynamic>) {
      return;
    }
    final clientId = event['clientId'] as String?;
    final message = ChatMessage.fromJson(raw, clientId: clientId);
    _upsertMessage(message);
    if (!message.isFromViewer) _markRead();
  }

  void _onSocketRead(Map<String, dynamic> event) {
    if (event['conversationId'] != _conversationId) return;
    final readAt = parseApiDate(event['readAt']) ?? DateTime.now();
    setState(() {
      _messages = [
        for (final m in _messages)
          m.isFromViewer &&
                  m.readAt == null &&
                  m.status == MessageSendStatus.sent
              ? m.copyWith(readAt: readAt)
              : m,
      ];
    });
  }

  /// Replaces the optimistic bubble (same clientId) or the same id; else appends.
  void _upsertMessage(ChatMessage message) {
    if (!mounted) return;
    setState(() {
      final index = _messages.indexWhere((m) =>
          m.id == message.id ||
          (message.clientId != null && m.clientId == message.clientId));
      if (index == -1) {
        _messages = [..._messages, message];
      } else {
        _messages = [..._messages]..[index] = message;
      }
    });
  }

  void _removeMessage(String clientId) {
    setState(() {
      _messages = _messages.where((m) => m.clientId != clientId).toList();
    });
  }

  bool get _canMessage =>
      ref.read(chatInboxProvider).valueOrNull?.canMessage ?? true;

  Future<void> _sendText(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty) return;
    if (!_canMessage) {
      _showUpgradePrompt('Get a Naam plan to send messages');
      return;
    }
    _textController.clear();

    final clientId = 'c${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now();
    _upsertMessage(ChatMessage(
      id: clientId,
      clientId: clientId,
      conversationId: _conversationId,
      senderId: '',
      text: text,
      isFromViewer: true,
      createdAt: now,
      sentAtLabel: clockLabel(now),
      status: MessageSendStatus.sending,
    ));

    try {
      final sent = await _deliver(text, clientId);
      _upsertMessage(sent);
      final base = _thread ??
          ref.read(chatInboxProvider).valueOrNull?.find(_conversationId);
      if (base != null) {
        ref
            .read(chatInboxProvider.notifier)
            .upsert(base.copyWith(messages: [sent], unreadCount: 0));
      }
    } on TimeoutException {
      _markFailed(clientId, 'Message not sent. Check your connection.');
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.requiresUpgrade) {
        _removeMessage(clientId);
        _textController.text = text;
        ref.read(chatInboxProvider.notifier).setCanMessage(false);
        _showUpgradePrompt(e.message);
        return;
      }
      _markFailed(clientId, e.message);
    }
  }

  /// Over the socket when connected (REST otherwise). A socket timeout is not
  /// retried over REST, since the server may already have stored the message.
  Future<ChatMessage> _deliver(String text, String clientId) async {
    final Map<String, dynamic> ack;
    try {
      ack = await ref.read(realtimeServiceProvider).sendMessage(
            conversationId: _conversationId,
            text: text,
            clientId: clientId,
          );
    } on RealtimeUnavailable {
      return ref
          .read(chatRepositoryProvider)
          .send(_conversationId, text, clientId: clientId);
    }
    final raw = ack['message'];
    if (ack['ok'] != true || raw is! Map<String, dynamic>) {
      throw ApiException(
        raw is String ? raw : 'Message not sent',
        statusCode: (ack['statusCode'] as num?)?.toInt(),
        code: ack['code'] as String?,
      );
    }
    return ChatMessage.fromJson(raw, clientId: clientId);
  }

  void _markFailed(String clientId, String error) {
    if (!mounted) return;
    final index = _messages.indexWhere((m) => m.clientId == clientId);
    if (index != -1) {
      setState(() {
        _messages = [..._messages]..[index] =
            _messages[index].copyWith(status: MessageSendStatus.failed);
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
    );
  }

  void _retry(ChatMessage message) {
    if (message.clientId != null) _removeMessage(message.clientId!);
    _sendText(message.text);
  }

  void _showUpgradePrompt(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(label: 'Upgrade', onPressed: _goToPlans),
      ),
    );
  }

  void _retryLoad() {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    _load();
  }

  void _goToPlans() {
    if (!mounted) return;
    GoRouter.of(context).go(AppRoutes.profile);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thread = _thread;
    if (thread == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFCFCFD),
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: Center(
          child: _loadError == null
              ? const CircularProgressIndicator(color: JDateTokens.brandRose)
              : _ChatLoadError(message: _loadError!, onRetry: _retryLoad),
        ),
      );
    }
    final partner = thread.partner;
    final canMessage =
        ref.watch(chatInboxProvider).valueOrNull?.canMessage ?? true;

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
                    child: NaamProfileImage(
                      imageUrl: partner.primaryImageUrl,
                      fit: BoxFit.cover,
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
            child: _loading && _messages.isEmpty
                ? const Center(
                    child:
                        CircularProgressIndicator(color: JDateTokens.brandRose),
                  )
                : _loadError != null && _messages.isEmpty
                    ? Center(
                        child: _ChatLoadError(
                          message: _loadError!,
                          onRetry: _retryLoad,
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        // Newest at the bottom; older pages load when scrolling up.
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                        itemCount: _messages.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _messages.length) {
                            if (_hasOlder) {
                              return const Padding(
                                padding: EdgeInsets.only(bottom: 16),
                                child: Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: JDateTokens.brandRose,
                                    ),
                                  ),
                                ),
                              );
                            }
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
                          final message =
                              _messages[_messages.length - 1 - index];
                          return _MessageBubble(
                            message: message,
                            onRetry: message.status == MessageSendStatus.failed
                                ? () => _retry(message)
                                : null,
                          );
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
            child: !canMessage
                ? _UpgradeToReplyNotice(
                    name: partner.firstName,
                    onUpgrade: _goToPlans,
                  )
                : ListView.separated(
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
  const _MessageBubble({required this.message, this.onRetry});

  final ChatMessage message;

  /// Set for a message that failed to send.
  final VoidCallback? onRetry;

  String get _footer {
    final note = message.isNote ? 'Note · ' : '';
    if (!message.isFromViewer) return '$note${message.sentAtLabel}';
    return switch (message.status) {
      MessageSendStatus.sending => 'Sending…',
      MessageSendStatus.failed => 'Not sent · Tap to retry',
      MessageSendStatus.sent =>
        '$note${message.sentAtLabel} · ${message.readAt != null ? 'Read' : 'Delivered'}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMe = message.isFromViewer;

    return GestureDetector(
      onTap: onRetry,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
              constraints: const BoxConstraints(maxWidth: 280),
              decoration: BoxDecoration(
                color: isMe
                    ? JDateTokens.brandRose.withValues(
                        alpha:
                            message.status == MessageSendStatus.sent ? 1 : 0.6,
                      )
                    : const Color(0xFFF1F1F4),
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
                _footer,
                style: TextStyle(
                  color: message.status == MessageSendStatus.failed
                      ? JDateTokens.brandRose
                      : const Color(0xFFA1A1AA),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown instead of the icebreakers when the viewer needs a plan to reply.
class _UpgradeToReplyNotice extends StatelessWidget {
  const _UpgradeToReplyNotice({required this.name, required this.onUpgrade});

  final String name;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.workspace_premium_rounded,
          size: 16,
          color: JDateTokens.brandRose,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Get a Naam plan to reply to $name',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF3F3F46),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: onUpgrade,
          child: const Text(
            'Upgrade',
            style: TextStyle(
              color: JDateTokens.brandRose,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatLoadError extends StatelessWidget {
  const _ChatLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: JDateTokens.brandRose,
          ),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
