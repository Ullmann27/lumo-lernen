// ════════════════════════════════════════════════════════════════════════
// LUMO COSMOS VIEW — Anzeige der wachsenden Lern-Welt
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/lumo_cosmos.dart';
import '../../theme/lumo_design_tokens.dart';
import '../../widgets/premium/lumo_premium_card.dart';

class LumoCosmosScreen extends StatefulWidget {
  const LumoCosmosScreen({super.key});

  @override
  State<LumoCosmosScreen> createState() => _LumoCosmosScreenState();
}

class _LumoCosmosScreenState extends State<LumoCosmosScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 10))
      ..repeat();
    _load();
  }

  Future<void> _load() async {
    await CosmosWorld.instance.load();
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final world = CosmosWorld.instance;
    final period = currentDayPeriod();
    final season = currentSeason();
    final skyColors = _skyForPeriod(period);
    final grassColor = _grassForSeason(season);
    return Scaffold(
      backgroundColor: skyColors.first,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(world, period, season),
            Expanded(
              child: Stack(
                children: [
                  // Sky-Gradient passt zur Tageszeit
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            skyColors[0],
                            skyColors[1],
                            grassColor,
                          ],
                          stops: const [0, 0.5, 0.55],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  // Sonne oder Mond
                  if (period == LumoDayPeriod.night)
                    Positioned(
                      top: 30, right: 30,
                      child: _MoonIcon(),
                    )
                  else if (period == LumoDayPeriod.morning ||
                      period == LumoDayPeriod.noon)
                    Positioned(
                      top: 30, right: 30,
                      child: _SunIcon(
                        color: period == LumoDayPeriod.morning
                            ? const Color(0xFFFFB347)
                            : const Color(0xFFFCD34D),
                      ),
                    ),
                  // Sterne bei Nacht
                  if (period == LumoDayPeriod.night)
                    Positioned.fill(child: _StarsLayer()),
                  // Animated items
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _animCtrl,
                      builder: (_, __) {
                        return CustomPaint(
                          painter: _CosmosPainter(
                            items: world.items,
                            progress: _animCtrl.value,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            _buildStats(world),
          ],
        ),
      ),
    );
  }

  List<Color> _skyForPeriod(LumoDayPeriod p) {
    switch (p) {
      case LumoDayPeriod.morning:
        return [const Color(0xFFFFD194), const Color(0xFFFFB5A7)];
      case LumoDayPeriod.noon:
        return [const Color(0xFF87CEEB), const Color(0xFFB5E2FA)];
      case LumoDayPeriod.evening:
        return [const Color(0xFFFF7E5F), const Color(0xFFFEB47B)];
      case LumoDayPeriod.night:
        return [const Color(0xFF1E3A8A), const Color(0xFF4338CA)];
    }
  }

  Color _grassForSeason(Season s) {
    switch (s) {
      case Season.spring: return const Color(0xFF90EE90);
      case Season.summer: return const Color(0xFF52C41A);
      case Season.autumn: return const Color(0xFFFFB347);
      case Season.winter: return const Color(0xFFE6E6FA);
    }
  }

  Widget _buildTopBar(CosmosWorld world, LumoDayPeriod period, Season season) {
    String periodName = 'Tag';
    switch (period) {
      case LumoDayPeriod.morning: periodName = 'Morgen'; break;
      case LumoDayPeriod.noon: periodName = 'Mittag'; break;
      case LumoDayPeriod.evening: periodName = 'Abend'; break;
      case LumoDayPeriod.night: periodName = 'Nacht'; break;
    }
    String seasonName = 'Sommer';
    switch (season) {
      case Season.spring: seasonName = 'Fruehling'; break;
      case Season.summer: seasonName = 'Sommer'; break;
      case Season.autumn: seasonName = 'Herbst'; break;
      case Season.winter: seasonName = 'Winter'; break;
    }
    return Padding(
      padding: const EdgeInsets.all(LumoTokens.space12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Meine Welt',
                    style: LumoTokens.typo.headlineMedium),
                Text('$periodName · $seasonName · ${world.worldStage}',
                    style: LumoTokens.typo.bodyMedium.copyWith(
                        color: LumoTokens.colors.textMuted)),
              ],
            ),
          ),
          // Stats Pill
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: LumoTokens.brPill,
              boxShadow: LumoTokens.shadows.subtle,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.eco_rounded, color: Color(0xFF10B981)),
                const SizedBox(width: 4),
                Text('${world.totalItems}',
                    style: LumoTokens.typo.titleMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(CosmosWorld world) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(LumoTokens.space16),
      child: Row(
        children: [
          Expanded(
            child: _statTile(
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF10B981),
              label: 'Richtig',
              value: '${world.totalCorrect}',
            ),
          ),
          Expanded(
            child: _statTile(
              icon: Icons.local_fire_department_rounded,
              color: const Color(0xFFF97316),
              label: 'Tage Streak',
              value: '${world.streakDays}',
            ),
          ),
          Expanded(
            child: _statTile(
              icon: Icons.auto_awesome_rounded,
              color: const Color(0xFFFCD34D),
              label: 'Items',
              value: '${world.totalItems}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(value, style: LumoTokens.typo.titleLarge),
        Text(label, style: LumoTokens.typo.bodySmall.copyWith(
            color: LumoTokens.colors.textMuted)),
      ],
    );
  }
}

class _CosmosPainter extends CustomPainter {
  _CosmosPainter({required this.items, required this.progress});
  final List<CosmosItem> items;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // Sortiere Items nach Y (hinten zuerst) fuer Tiefen-Effekt
    final sorted = List<CosmosItem>.from(items)
      ..sort((a, b) => a.y.compareTo(b.y));

    for (final item in sorted) {
      final x = item.x * size.width;
      final y = item.y * size.height;
      _drawItem(canvas, item, Offset(x, y));
    }
  }

  void _drawItem(Canvas canvas, CosmosItem item, Offset pos) {
    // Wiggle fuer animierte Items
    Offset offset = pos;
    if (item.type == CosmosItemType.butterfly ||
        item.type == CosmosItemType.bird) {
      final t = progress * 2 * math.pi + item.x * 10;
      offset = pos + Offset(
        math.sin(t) * 15,
        math.cos(t * 1.3) * 8,
      );
    } else if (item.type == CosmosItemType.cloud) {
      offset = pos + Offset(
        math.sin(progress * 2 * math.pi + item.x * 5) * 20,
        0,
      );
    }

    final emoji = item.type.emoji;
    final fontSize = 32.0 * item.scale;
    final tp = TextPainter(
      text: TextSpan(text: emoji, style: TextStyle(fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    if (item.rotation != 0) canvas.rotate(item.rotation);
    canvas.translate(-tp.width / 2, -tp.height / 2);
    tp.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CosmosPainter old) =>
      old.items.length != items.length || old.progress != progress;
}

class _SunIcon extends StatelessWidget {
  const _SunIcon({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0.0)],
          stops: const [0.5, 1.0],
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _MoonIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCE8),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFEFCE8).withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Text('🌙', style: TextStyle(fontSize: 28)),
    );
  }
}

class _StarsLayer extends StatefulWidget {
  @override
  State<_StarsLayer> createState() => _StarsLayerState();
}

class _StarsLayerState extends State<_StarsLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _twinkle;
  late final List<Offset> _stars;
  @override
  void initState() {
    super.initState();
    _twinkle = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    final r = math.Random(13);
    _stars = List.generate(40,
        (_) => Offset(r.nextDouble(), r.nextDouble() * 0.45));
  }
  @override
  void dispose() {
    _twinkle.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _twinkle,
      builder: (_, __) {
        return IgnorePointer(
          child: CustomPaint(
            painter: _StarsPainter(
                stars: _stars, opacity: 0.5 + _twinkle.value * 0.5),
          ),
        );
      },
    );
  }
}

class _StarsPainter extends CustomPainter {
  _StarsPainter({required this.stars, required this.opacity});
  final List<Offset> stars;
  final double opacity;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(opacity);
    for (final s in stars) {
      canvas.drawCircle(
          Offset(s.dx * size.width, s.dy * size.height), 1.5, paint);
    }
  }
  @override
  bool shouldRepaint(_StarsPainter old) => old.opacity != opacity;
}
