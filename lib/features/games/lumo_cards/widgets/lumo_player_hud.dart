// ════════════════════════════════════════════════════════════════════════
// LUMO PLAYER HUD — Spieler-Anzeige (1:1 nach Mockup Bild 3)
// ════════════════════════════════════════════════════════════════════════
// Eine kompakte Spieler-Karte wie in den LUMO-CARDS-Mockups:
//  • Runder Avatar mit farbigem Ring (Fuchs-Emoji als Platzhalter)
//  • Aktiver Spieler: pulsierender Glow-Ring (gold)
//  • Name darunter
//  • Karten-Anzahl als kleine Badge (Karten-Icon + Zahl)
//  • Stern-Score (✦ + Zahl) wenn vorhanden
//
// Rein praesentativ - keine Spiel-Logik. Funktioniert fuer eigenen
// Spieler wie fuer Gegner (compact-Flag macht es kleiner).
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

class LumoPlayerHud extends StatefulWidget {
  const LumoPlayerHud({
    super.key,
    required this.name,
    required this.cardCount,
    this.stars = 0,
    this.isActive = false,
    this.compact = false,
    this.avatarEmoji = '🦊',
    this.ringColor = const Color(0xFFFF7A2F),
  });

  /// Name des Spielers (z.B. 'Du', 'Lumo', 'Zoey').
  final String name;

  /// Anzahl Karten auf der Hand.
  final int cardCount;

  /// Stern-Punkte (optional, 0 = ausgeblendet).
  final int stars;

  /// Aktiver Spieler? -> pulsierender Glow-Ring.
  final bool isActive;

  /// Kompakt fuer Gegner-Plaetze (kleinere Groessen).
  final bool compact;

  /// Avatar-Emoji (Default Fuchs).
  final String avatarEmoji;

  /// Farbe des Avatar-Rings.
  final Color ringColor;

  @override
  State<LumoPlayerHud> createState() => _LumoPlayerHudState();
}

class _LumoPlayerHudState extends State<LumoPlayerHud>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatarSize = widget.compact ? 42.0 : 54.0;
    final ringWidth = widget.compact ? 2.5 : 3.2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Avatar mit Ring (+ pulsierendem Aktiv-Glow) ──
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, child) {
            final t = _pulse.value;
            return Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.95),
                    const Color(0xFFFFF1E6),
                  ],
                ),
                border: Border.all(
                  color: widget.isActive
                      ? const Color(0xFFFCD34D)
                      : widget.ringColor,
                  width: ringWidth,
                ),
                boxShadow: [
                  // Basis-Schatten
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                  // Aktiver Glow (pulsierend gold)
                  if (widget.isActive)
                    BoxShadow(
                      color: const Color(0xFFFCD34D)
                          .withOpacity(0.40 + t * 0.35),
                      blurRadius: 14 + t * 10,
                      spreadRadius: 1 + t * 2,
                    ),
                ],
              ),
              child: child,
            );
          },
          child: Center(
            child: Text(
              widget.avatarEmoji,
              style: TextStyle(fontSize: widget.compact ? 22 : 28),
            ),
          ),
        ),
        const SizedBox(height: 5),

        // ── Name ──
        Text(
          widget.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: widget.compact ? 12 : 14,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.0,
            shadows: const [
              Shadow(
                color: Color(0x88000000),
                offset: Offset(0, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // ── Badges: Karten-Anzahl + optional Sterne ──
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _badge(
              icon: Icons.style_rounded,
              label: '${widget.cardCount}',
              bg: Colors.black.withOpacity(0.32),
              fg: Colors.white,
            ),
            if (widget.stars > 0) ...[
              const SizedBox(width: 5),
              _badge(
                icon: null,
                glyph: '✦',
                label: '${widget.stars}',
                bg: const Color(0xFFFCD34D),
                fg: const Color(0xFF1F1713),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _badge({
    IconData? icon,
    String? glyph,
    required String label,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 12, color: fg)
          else if (glyph != null)
            Text(glyph,
                style: TextStyle(fontSize: 11, color: fg, height: 1.0)),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: fg,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
