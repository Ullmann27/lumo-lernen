// ════════════════════════════════════════════════════════════════════════
// LUMO CARDS SCORE HEADER — Round/Target Pille oben (nach Heinz' Mockup)
// ════════════════════════════════════════════════════════════════════════
// Zeigt links das Lumo-Cards-Logo als kompakte Pille, in der Mitte zwei
// kleine Stats (ROUND x/y + TARGET-Score), rechts Emoji + Settings.
//
// Generisches Header-Layout, kein Trade-Dress.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

class LumoCardsScoreHeader extends StatelessWidget {
  const LumoCardsScoreHeader({
    super.key,
    required this.round,
    required this.totalRounds,
    required this.targetPoints,
    this.onClose,
    this.onEmoji,
    this.onSettings,
  });

  final int round;
  final int totalRounds;
  final int targetPoints;
  final VoidCallback? onClose;
  final VoidCallback? onEmoji;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Logo-Pille links: 'LUMO CARDS' ──
          _LogoPill(onClose: onClose),
          const SizedBox(width: 8),
          // ── ROUND / TARGET Stats ──
          _StatPill(
            label: 'ROUND',
            value: '$round/$totalRounds',
          ),
          const SizedBox(width: 6),
          _StatPill(
            label: 'TARGET',
            value: '$targetPoints',
          ),
          const Spacer(),
          // ── Emoji + Settings rechts ──
          if (onEmoji != null) ...[
            _RoundIconButton(
              icon: Icons.emoji_emotions_rounded,
              onTap: onEmoji,
              bg: const Color(0xFF7C3AED),
            ),
            const SizedBox(width: 8),
          ],
          if (onSettings != null)
            _RoundIconButton(
              icon: Icons.settings_rounded,
              onTap: onSettings,
              bg: const Color(0xFF374151),
            ),
        ],
      ),
    );
  }
}

class _LogoPill extends StatelessWidget {
  const _LogoPill({this.onClose});
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFB96B), Color(0xFFFF7A2F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Colors.white.withOpacity(0.65), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF7A2F).withOpacity(0.45),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('🦊', style: TextStyle(fontSize: 18)),
            SizedBox(width: 6),
            Text(
              'LUMO',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(width: 4),
            Text(
              'CARDS',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFFEDC9),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.32),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: Colors.white.withOpacity(0.75),
              letterSpacing: 0.8,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.bg,
    this.onTap,
  });
  final IconData icon;
  final Color bg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.30), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.30),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }
}
