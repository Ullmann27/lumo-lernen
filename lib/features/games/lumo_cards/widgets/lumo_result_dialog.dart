// ════════════════════════════════════════════════════════════════════════
// LUMO RESULT DIALOG — Gewinner-Anzeige mit Konfetti
// ════════════════════════════════════════════════════════════════════════
// Wird ueber dem Lumo-Cards Screen eingeblendet wenn ein Spiel endet.
// Zeigt: Sieger, Sternenbonus, Streak-Pille, Nochmal/Zurueck Buttons.
// Hinter dem Dialog: einfache Konfetti-Animation (CustomPaint), kein
// neues Paket noetig.
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';

class LumoResultDialog extends StatefulWidget {
  const LumoResultDialog({
    super.key,
    required this.winnerName,
    required this.kindWon,
    required this.reward,
    required this.streak,
    required this.onRestart,
    required this.onExit,
  });

  final String winnerName;
  final bool kindWon;
  final int reward;
  final int streak;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  @override
  State<LumoResultDialog> createState() => _LumoResultDialogState();
}

class _LumoResultDialogState extends State<LumoResultDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.kindWon) _confettiCtrl.forward();
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: Colors.black.withOpacity(0.65)),
          // Konfetti-Layer hinter dem Dialog (nur bei Sieg).
          if (widget.kindWon)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _confettiCtrl,
                  builder: (_, __) => CustomPaint(
                    painter: _ConfettiPainter(_confettiCtrl.value),
                  ),
                ),
              ),
            ),
          Center(child: _buildCard()),
        ],
      ),
    );
  }

  Widget _buildCard() {
    final colors = widget.kindWon
        ? const [Color(0xFFFFFBEB), Color(0xFFFCD34D)]
        : const [Color(0xFFFEF2F2), Color(0xFFFCA5A5)];
    final accent = widget.kindWon
        ? const Color(0xFFCA8A04)
        : const Color(0xFFB91C1C);
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accent, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.kindWon ? '🏆' : '🦊',
              style: const TextStyle(fontSize: 76)),
          const SizedBox(height: 8),
          Text(
            widget.kindWon
                ? '${widget.winnerName} gewinnt!'
                : 'Lumo gewinnt diesmal!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF7C2D12),
            ),
          ),
          if (widget.kindWon && widget.streak >= 2) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFCD34D).withOpacity(0.55),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: accent, width: 1.6),
              ),
              child: Text(
                'Streak x${widget.streak}! ${'🔥' * widget.streak.clamp(1, 5)}',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF7C2D12),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            widget.kindWon
                ? 'Du bekommst ${widget.reward} Sterne!'
                : 'Du bekommst 1 Trost-Stern. Naechstes Mal du!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF7C2D12).withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: widget.onRestart,
                icon: const Icon(Icons.replay_rounded),
                label: const Text(
                  'Nochmal',
                  style: TextStyle(
                      fontFamily: 'Nunito', fontWeight: FontWeight.w900),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: widget.onExit,
                icon: const Icon(Icons.exit_to_app_rounded),
                label: const Text(
                  'Zurueck',
                  style: TextStyle(
                      fontFamily: 'Nunito', fontWeight: FontWeight.w900),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF7C2D12),
                  side:
                      const BorderSide(color: Color(0xFF7C2D12), width: 1.6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t);
  final double t; // 0..1

  static const _colors = [
    Color(0xFFFF7A2F),
    Color(0xFF7C3AED),
    Color(0xFF2563EB),
    Color(0xFF10B981),
    Color(0xFFFCD34D),
    Color(0xFFEC4899),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(7);
    final paint = Paint();
    for (int i = 0; i < 60; i++) {
      final c = _colors[i % _colors.length];
      // Start oben mit zufaelliger x-Position.
      final startX = rng.nextDouble() * size.width;
      final fallSpeed = 0.6 + rng.nextDouble() * 0.6;
      final swing = math.sin((t + i * 0.05) * math.pi * 4) * 30;
      final y = (t * fallSpeed * size.height * 1.4) - 40;
      if (y < -20 || y > size.height + 20) continue;
      final rotation = (t + i * 0.1) * math.pi * 4;
      final cx = startX + swing;
      paint.color = c.withOpacity(0.85);
      canvas.save();
      canvas.translate(cx, y);
      canvas.rotate(rotation);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 8, height: 12),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
