// ════════════════════════════════════════════════════════════════════════
// LUMO TURN PILL — "DEIN ZUG" / "GEGNER" Indikator-Pille
// ════════════════════════════════════════════════════════════════════════
// Nach Heinz' HUD-Asset-Sheet (2026-05-22): grosse, gut sichtbare
// Pille die zeigt wer dran ist:
//   • Spieler dran:  cyan-blau-Verlauf "DEIN ZUG" + Pfeil-Icon, pulsierend
//   • Gegner dran:   dunkle Pille "GEGNER ZIEHT" + Sanduhr-Icon
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

class LumoTurnPill extends StatefulWidget {
  const LumoTurnPill({
    super.key,
    required this.isMyTurn,
    this.myLabel = 'DEIN ZUG',
    this.opponentLabel = 'GEGNER',
  });

  final bool isMyTurn;
  final String myLabel;
  final String opponentLabel;

  @override
  State<LumoTurnPill> createState() => _LumoTurnPillState();
}

class _LumoTurnPillState extends State<LumoTurnPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMy = widget.isMyTurn;
    final gradient = isMy
        ? const LinearGradient(
            colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF334155), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
    final borderColor = isMy
        ? const Color(0xFFE0F2FE)
        : const Color(0xFF64748B).withOpacity(0.6);
    final label = isMy ? widget.myLabel : widget.opponentLabel;
    final icon = isMy ? Icons.arrow_forward_rounded : Icons.hourglass_top_rounded;
    final glowColor = isMy ? const Color(0xFF38BDF8) : Colors.black;

    // Tier 1 Foundation 2026-05-23: RepaintBoundary isoliert das
    // permanente Pulsieren vom Turn-Banner drumherum.
    return RepaintBoundary(
      child: AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final t = isMy ? _pulse.value : 0.0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: borderColor, width: 1.6),
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(0.35 + t * 0.30),
                blurRadius: 14 + t * 8,
                spreadRadius: 1 + t * 2,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.3,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 16, color: Colors.white),
            ],
          ),
        );
      },
      ),
    );
  }
}
