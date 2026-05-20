// ════════════════════════════════════════════════════════════════════════
// LUMO REWARD BURST — Sterne fliegen, Belohnung wird sichtbar
// ════════════════════════════════════════════════════════════════════════
// Verwendung als overlay nach Erfolg:
//   showLumoRewardBurst(context, stars: 3, xp: 25);
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/lumo_design_tokens.dart';

/// Zeigt eine Sterne-Burst-Animation als Overlay.
/// Auto-dismisses nach 1.5 Sekunden.
Future<void> showLumoRewardBurst(
  BuildContext context, {
  int stars = 1,
  int? xp,
  String? message,
}) {
  final completer = Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: false,
      pageBuilder: (_, __, ___) => _RewardBurstOverlay(
        stars: stars,
        xp: xp,
        message: message,
      ),
      transitionDuration: const Duration(milliseconds: 250),
    ),
  );
  Future.delayed(const Duration(milliseconds: 1800), () {
    if (Navigator.canPop(context)) Navigator.of(context).pop();
  });
  return completer;
}

class _RewardBurstOverlay extends StatefulWidget {
  const _RewardBurstOverlay({
    required this.stars,
    this.xp,
    this.message,
  });
  final int stars;
  final int? xp;
  final String? message;

  @override
  State<_RewardBurstOverlay> createState() => _RewardBurstOverlayState();
}

class _RewardBurstOverlayState extends State<_RewardBurstOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _mainCtrl;
  late final AnimationController _burstCtrl;
  final _rng = math.Random();
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _burstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _particles = List.generate(
      18,
      (_) => _Particle(
        angle: _rng.nextDouble() * math.pi * 2,
        speed: 80 + _rng.nextDouble() * 200,
        size: 6 + _rng.nextDouble() * 14,
      ),
    );
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _burstCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Particle burst
              AnimatedBuilder(
                animation: _burstCtrl,
                builder: (_, __) => CustomPaint(
                  size: const Size(280, 280),
                  painter: _BurstPainter(
                    particles: _particles,
                    progress: _burstCtrl.value,
                  ),
                ),
              ),
              // Central card with stars
              AnimatedBuilder(
                animation: _mainCtrl,
                builder: (_, child) {
                  final t = Curves.easeOutBack.transform(
                      math.min(1.0, _mainCtrl.value * 1.5));
                  return Transform.scale(scale: t, child: child);
                },
                child: Container(
                  padding: const EdgeInsets.all(LumoTokens.space24),
                  decoration: BoxDecoration(
                    color: LumoTokens.colors.surface,
                    borderRadius: LumoTokens.brXLarge,
                    boxShadow: LumoTokens.shadows.hero,
                    border: Border.all(
                        color: LumoTokens.colors.gold, width: 3),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.stars.clamp(1, 5),
                          (i) => Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 2),
                            child: Icon(
                              Icons.star_rounded,
                              size: 56,
                              color: LumoTokens.colors.gold,
                            ),
                          ),
                        ),
                      ),
                      if (widget.xp != null) ...[
                        const SizedBox(height: LumoTokens.space12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: LumoTokens.space16,
                              vertical: LumoTokens.space8),
                          decoration: BoxDecoration(
                            gradient: LumoTokens.colors.heroLila,
                            borderRadius: LumoTokens.brPill,
                          ),
                          child: Text(
                            '+${widget.xp} XP',
                            style: LumoTokens.typo.labelLarge.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                      if (widget.message != null) ...[
                        const SizedBox(height: LumoTokens.space12),
                        Text(
                          widget.message!,
                          style: LumoTokens.typo.titleMedium.copyWith(
                            color: LumoTokens.colors.textDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Particle {
  _Particle(
      {required this.angle, required this.speed, required this.size});
  final double angle;
  final double speed;
  final double size;
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.particles, required this.progress});
  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final t = Curves.easeOut.transform(progress);
    for (final p in particles) {
      final dx = math.cos(p.angle) * p.speed * t;
      final dy = math.sin(p.angle) * p.speed * t;
      final pos = center + Offset(dx, dy);
      final opacity = (1.0 - t).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = (p.size > 12
                ? LumoTokens.colors.gold
                : LumoTokens.colors.lumoOrange)
            .withOpacity(opacity);
      _drawSparkle(canvas, pos, p.size * (1 - t * 0.3), paint);
    }
  }

  void _drawSparkle(Canvas canvas, Offset c, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final r = (i % 2 == 0) ? size : size * 0.4;
      final x = c.dx + r * math.cos(angle);
      final y = c.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.progress != progress;
}
