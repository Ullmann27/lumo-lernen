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
    return Scaffold(
      backgroundColor: const Color(0xFFB5E2FA), // Himmelblau
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(world),
            Expanded(
              child: Stack(
                children: [
                  // Sky-Gradient
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFB5E2FA), // Himmel
                            const Color(0xFFFFE4B5), // Horizon
                            const Color(0xFF90EE90), // Gras
                          ],
                          stops: const [0, 0.5, 0.55],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
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

  Widget _buildTopBar(CosmosWorld world) {
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
                Text(world.worldStage,
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
