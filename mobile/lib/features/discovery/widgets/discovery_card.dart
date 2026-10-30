// FILE: lib/features/discovery/widgets/discovery_card.dart
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/candidate_profile.dart';

/// Fixed-dimension Portrait Card + 5 Circular Action Buttons with Twitter/X-style micro-interactions
/// and Liquid Glass online/last-seen status pill.
class DiscoveryCard extends StatefulWidget {
  const DiscoveryCard({
    super.key,
    required this.candidate,
    required this.canRewind,
    required this.onRewind,
    required this.onPass,
    required this.onLike,
    required this.onSuperLike,
    required this.onOpenQuickMessage,
    required this.onOpenFullDetails,
  });

  final CandidateProfile candidate;
  final bool canRewind;
  final VoidCallback onRewind;
  final VoidCallback onPass;
  final VoidCallback onLike;
  final VoidCallback onSuperLike;
  final VoidCallback onOpenQuickMessage;
  final VoidCallback onOpenFullDetails;

  @override
  State<DiscoveryCard> createState() => _DiscoveryCardState();
}

class _DiscoveryCardState extends State<DiscoveryCard>
    with SingleTickerProviderStateMixin {
  Offset _dragOffset = Offset.zero;
  int _photoIndex = 0;
  String? _microAction; // 'like' | 'pass' | 'super' | 'rewind'
  Timer? _actionTimer;
  late final AnimationController _burstController;

  @override
  void initState() {
    super.initState();
    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
  }

  @override
  void didUpdateWidget(covariant DiscoveryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.candidate.id != widget.candidate.id) {
      _photoIndex = 0;
      _dragOffset = Offset.zero;
      _microAction = null;
      _burstController.reset();
    }
  }

  @override
  void dispose() {
    _actionTimer?.cancel();
    _burstController.dispose();
    super.dispose();
  }

  void _triggerMicroAction(String action, VoidCallback callback) {
    if (_microAction != null) return;
    setState(() {
      _microAction = action;
    });
    _burstController.forward(from: 0);
    _actionTimer?.cancel();
    _actionTimer = Timer(const Duration(milliseconds: 340), () {
      if (!mounted) return;
      setState(() {
        _microAction = null;
      });
      callback();
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_microAction != null) return;
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_microAction != null) return;
    if (_dragOffset.dx > 105) {
      setState(() => _dragOffset = Offset.zero);
      _triggerMicroAction('like', widget.onLike);
      return;
    } else if (_dragOffset.dx < -105) {
      setState(() => _dragOffset = Offset.zero);
      _triggerMicroAction('pass', widget.onPass);
      return;
    }
    setState(() {
      _dragOffset = Offset.zero;
    });
  }

  void _cyclePhoto(int delta) {
    final total = widget.candidate.imageUrls.length;
    if (total <= 1) return;
    setState(() {
      _photoIndex = (_photoIndex + delta).clamp(0, total - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.candidate.imageUrls;
    final currentPhoto = photos.isNotEmpty
        ? photos[_photoIndex.clamp(0, photos.length - 1)]
        : '';

    final animOffset = switch (_microAction) {
      'like' => const Offset(38, -10),
      'pass' => const Offset(-38, 4),
      'super' => const Offset(0, -26),
      'rewind' => const Offset(-14, -6),
      _ => _dragOffset,
    };

    final rotationAngle = switch (_microAction) {
      'like' => 0.055,
      'pass' => -0.055,
      _ => (_dragOffset.dx / 340) * (math.pi / 20),
    };

    final cardOpacity = _microAction != null ? 0.35 : 1.0;

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            onTapUp: (details) {
              final width = MediaQuery.sizeOf(context).width;
              if (details.localPosition.dx < width * 0.30) {
                _cyclePhoto(-1);
              } else if (details.localPosition.dx > width * 0.70) {
                _cyclePhoto(1);
              } else {
                widget.onOpenFullDetails();
              }
            },
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              opacity: cardOpacity,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                transform: Matrix4.identity()
                  ..translate(animOffset.dx, animOffset.dy)
                  ..rotateZ(rotationAngle),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F18181B),
                      blurRadius: 28,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: currentPhoto.isNotEmpty
                            ? Image.network(
                                currentPhoto,
                                key: ValueKey<String>(
                                  '${widget.candidate.id}_$_photoIndex',
                                ),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) =>
                                    const _PhotoFallback(),
                              )
                            : const _PhotoFallback(),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x2809090B),
                              Color(0x0009090B),
                              Color(0x5909090B),
                              Color(0xD909090B),
                            ],
                            stops: [0.0, 0.42, 0.70, 1.0],
                          ),
                        ),
                      ),
                      if (_microAction != null)
                        Center(
                          child: _MicroActionPulseBadge(action: _microAction!),
                        ),
                      Positioned(
                        top: 14,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StoryPhotoIndicators(
                              count: photos.length,
                              activeIndex: _photoIndex,
                            ),
                            const SizedBox(height: 10),
                            LiquidGlassPresenceBadge(
                              isOnline: widget.candidate.isOnline,
                              label: widget.candidate.lastSeenLabel,
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 18,
                        child: _PortraitCardIdentityOverlay(
                          candidate: widget.candidate,
                          onTapDetails: widget.onOpenFullDetails,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _FigmaFiveCircleActionRow(
          canRewind: widget.canRewind,
          activeAction: _microAction,
          burstProgress: _burstController,
          onRewind: () => _triggerMicroAction('rewind', widget.onRewind),
          onSkip: () => _triggerMicroAction('pass', widget.onPass),
          onHeart: () => _triggerMicroAction('like', widget.onLike),
          onStar: () => _triggerMicroAction('super', widget.onSuperLike),
          onMessage: widget.onOpenQuickMessage,
        ),
      ],
    );
  }
}

/// Reusable Liquid Glass Presence Pill with glowing emerald green dot when online
/// or frosted dot + 'Seen 1h ago' / 'Seen 1d ago' / 'Seen 2d ago' when offline.
class LiquidGlassPresenceBadge extends StatelessWidget {
  const LiquidGlassPresenceBadge({
    super.key,
    required this.isOnline,
    required this.label,
  });

  final bool isOnline;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0x8518181D),
                Color(0x5718181D),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline
                      ? const Color(0xFF22C55E)
                      : Colors.white.withValues(alpha: 0.65),
                  boxShadow: isOnline
                      ? const [
                          BoxShadow(
                            color: Color(0xCC22C55E),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MicroActionPulseBadge extends StatelessWidget {
  const _MicroActionPulseBadge({required this.action});

  final String action;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color bg) = switch (action) {
      'like' => (Icons.favorite_rounded, JDateTokens.brandRose),
      'super' => (Icons.star_rounded, const Color(0xFFF59E0B)),
      'rewind' => (Icons.undo_rounded, const Color(0xFF18181B)),
      _ => (Icons.close_rounded, const Color(0xFF18181B)),
    };

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 30),
    );
  }
}

class _StoryPhotoIndicators extends StatelessWidget {
  const _StoryPhotoIndicators({
    required this.count,
    required this.activeIndex,
  });

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();
    return Row(
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3.5,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.36),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        );
      }),
    );
  }
}

class _PortraitCardIdentityOverlay extends StatelessWidget {
  const _PortraitCardIdentityOverlay({
    required this.candidate,
    required this.onTapDetails,
  });

  final CandidateProfile candidate;
  final VoidCallback onTapDetails;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapDetails,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 90,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    '${candidate.firstName}, ${candidate.age}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
                      height: 1.15,
                    ),
                  ),
                ),
                if (candidate.isVerified) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.verified_rounded,
                    size: 19,
                    color: Colors.white,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 3),
            Text(
              '${candidate.occupation} · ${candidate.neighborhood}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.94),
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              candidate.bio,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.32,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FigmaFiveCircleActionRow extends StatelessWidget {
  const _FigmaFiveCircleActionRow({
    required this.canRewind,
    required this.activeAction,
    required this.burstProgress,
    required this.onRewind,
    required this.onSkip,
    required this.onHeart,
    required this.onStar,
    required this.onMessage,
  });

  final bool canRewind;
  final String? activeAction;
  final Animation<double> burstProgress;
  final VoidCallback onRewind;
  final VoidCallback onSkip;
  final VoidCallback onHeart;
  final VoidCallback onStar;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionCircleButton(
          size: 44,
          iconSize: 19,
          icon: Icons.undo_rounded,
          tooltip: 'Reverse',
          isPressed: activeAction == 'rewind',
          burstProgress: burstProgress,
          onTap: canRewind ? onRewind : null,
        ),
        const SizedBox(width: 12),
        _ActionCircleButton(
          size: 52,
          iconSize: 22,
          icon: Icons.close_rounded,
          tooltip: 'Skip',
          isPressed: activeAction == 'pass',
          burstProgress: burstProgress,
          onTap: onSkip,
        ),
        const SizedBox(width: 12),
        _ActionCircleButton(
          size: 62,
          iconSize: 28,
          icon: activeAction == 'like'
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          tooltip: 'Like',
          isPrimaryHeart: true,
          isPressed: activeAction == 'like',
          burstProgress: burstProgress,
          onTap: onHeart,
        ),
        const SizedBox(width: 12),
        _ActionCircleButton(
          size: 52,
          iconSize: 22,
          icon: activeAction == 'super'
              ? Icons.star_rounded
              : Icons.star_border_rounded,
          tooltip: 'Star',
          isPressed: activeAction == 'super',
          burstProgress: burstProgress,
          onTap: onStar,
        ),
        const SizedBox(width: 12),
        _ActionCircleButton(
          size: 44,
          iconSize: 19,
          icon: Icons.chat_bubble_outline_rounded,
          tooltip: 'Message',
          burstProgress: burstProgress,
          onTap: onMessage,
        ),
      ],
    );
  }
}

class _ActionCircleButton extends StatelessWidget {
  const _ActionCircleButton({
    required this.size,
    required this.iconSize,
    required this.icon,
    required this.tooltip,
    required this.burstProgress,
    this.isPrimaryHeart = false,
    this.isPressed = false,
    this.onTap,
  });

  final double size;
  final double iconSize;
  final IconData icon;
  final String tooltip;
  final Animation<double> burstProgress;
  final bool isPrimaryHeart;
  final bool isPressed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (isPressed && isPrimaryHeart)
              AnimatedBuilder(
                animation: burstProgress,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size(size * 2.1, size * 2.1),
                    painter: _TwitterHeartBurstPainter(
                      progress: burstProgress.value,
                    ),
                  );
                },
              ),
            AnimatedScale(
              scale: isPressed ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 160),
              curve: Curves.elasticOut,
              child: Opacity(
                opacity: onTap == null ? 0.36 : 1.0,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPrimaryHeart ? JDateTokens.brandRose : Colors.white,
                    border: isPrimaryHeart
                        ? null
                        : Border.all(color: const Color(0xFFE8E8ED), width: 1.2),
                    boxShadow: [
                      if (isPrimaryHeart)
                        const BoxShadow(
                          color: Color(0x47F01E65),
                          blurRadius: 22,
                          offset: Offset(0, 8),
                        )
                      else
                        const BoxShadow(
                          color: Color(0x0F18181B),
                          blurRadius: 14,
                          offset: Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: iconSize,
                      color: isPrimaryHeart
                          ? Colors.white
                          : const Color(0xFF27272A),
                    ),
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

class _TwitterHeartBurstPainter extends CustomPainter {
  const _TwitterHeartBurstPainter({required this.progress});

  final double progress;

  static const List<Color> _particleColors = [
    Color(0xFFFF1F6D),
    Color(0xFFFB7185),
    Color(0xFFF43F5E),
    Color(0xFFF59E0B),
    Color(0xFFFF1F6D),
    Color(0xFFEC4899),
    Color(0xFFF43F5E),
    Color(0xFFFBBF24),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final center = Offset(size.width / 2, size.height / 2);

    // Expanding shockwave ring
    final ringPaint = Paint()
      ..color = const Color(0xFFFF1F6D).withValues(alpha: (1.0 - progress) * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (1.0 - progress) * 3.5;
    canvas.drawCircle(center, 24 + (progress * 26), ringPaint);

    // 8 Radial burst particles
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi) / 4;
      final distance = 22 + (progress * 28);
      final offset = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );
      final radius = (1.0 - progress) * 3.8;
      final dotPaint = Paint()
        ..color = _particleColors[i].withValues(alpha: 1.0 - progress)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(offset, radius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TwitterHeartBurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF27272A),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: 64,
          color: Colors.white38,
        ),
      ),
    );
  }
}
