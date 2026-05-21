// ════════════════════════════════════════════════════════════════════════
// LUMO PLAYING CARD — eine Spielkarte
// ════════════════════════════════════════════════════════════════════════
// Eigenes Lumo-Design - kein UNO-Klon.
//
// Visuell:
//  - abgerundete 3D-Karte mit Verlauf in der Farbe
//  - weisser Rand
//  - mehrlagiger Schatten (warm)
//  - Zentrum: grosse Zahl ODER Spezial-Glyph
//  - Ecken: kleine Wiederholung
//  - Bei Tap leichter Tilt-Effekt (per AnimatedScale)
//  - Ist die Karte spielbar? -> goldener Glow
//  - Rueckseite: Lumo-Fuchs-Wappen
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../lumo_cards_models.dart';

class LumoPlayingCard extends StatefulWidget {
  const LumoPlayingCard({
    super.key,
    required this.card,
    this.width = 88,
    this.height = 128,
    this.faceDown = false,
    this.playable = false,
    this.onTap,
    this.dimmed = false,
  });

  final LumoCard card;
  final double width;
  final double height;
  final bool faceDown;
  final bool playable;
  final bool dimmed;
  final VoidCallback? onTap;

  @override
  State<LumoPlayingCard> createState() => _LumoPlayingCardState();
}

class _LumoPlayingCardState extends State<LumoPlayingCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 1.06 : 1.0;
    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTapDown: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = true),
        onTapUp: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: _build(),
      ),
    );
  }

  Widget _build() {
    final colors = _gradientFor(widget.card.color);
    final glow = widget.playable
        ? [
            BoxShadow(
              color: const Color(0xFFFCD34D).withOpacity(0.65),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ]
        : <BoxShadow>[];
    final dimColor = widget.dimmed ? Colors.black.withOpacity(0.18) : null;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          // Tiefer warmer Schatten
          BoxShadow(
            color: colors[1].withOpacity(0.45),
            blurRadius: 14,
            offset: const Offset(0, 7),
            spreadRadius: -2,
          ),
          // Highlight
          BoxShadow(
            color: Colors.white.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(-1, -2),
            spreadRadius: -2,
          ),
          ...glow,
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Karten-Vorder- oder Rueckseite.
            widget.faceDown ? _buildBack() : _buildFront(colors),
            if (dimColor != null)
              Container(
                decoration: BoxDecoration(
                  color: dimColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFront(List<Color> colors) {
    final isSpec = widget.card.isSpecial;
    final centerLabel = isSpec
        ? _specGlyph(widget.card.type)
        : '${widget.card.number}';
    final cornerLabel = isSpec
        ? _specGlyph(widget.card.type)
        : '${widget.card.number}';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Weisser Inner-Rahmen.
          Padding(
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                border:
                    Border.all(color: Colors.white.withOpacity(0.85), width: 2),
              ),
            ),
          ),
          // Mittlere Glyphe.
          Center(
            child: Container(
              width: widget.width * 0.62,
              height: widget.height * 0.55,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: colors[1].withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    centerLabel,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: isSpec ? 30 : 44,
                      fontWeight: FontWeight.w900,
                      color: colors[1],
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Ecken: links oben + rechts unten klein wiederholt.
          Positioned(
            top: 6,
            left: 8,
            child: _cornerLabel(cornerLabel, colors[1]),
          ),
          Positioned(
            bottom: 6,
            right: 8,
            child: Transform.rotate(
              angle: 3.14159,
              child: _cornerLabel(cornerLabel, colors[1]),
            ),
          ),
          // Dekoratives Symbol oben rechts (wenn vorhanden).
          if (widget.card.symbol != null && !isSpec)
            Positioned(
              top: 6,
              right: 8,
              child: Text(
                widget.card.symbol!,
                style: const TextStyle(fontSize: 12, height: 1.0),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cornerLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Nunito',
        fontSize: text.length > 1 ? 11 : 14,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        height: 1.0,
        shadows: [
          Shadow(
            color: color.withOpacity(0.5),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF9F58), Color(0xFFFF7A2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Wiederholtes Lumo-Wappen-Muster.
          Padding(
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                border:
                    Border.all(color: Colors.white.withOpacity(0.85), width: 2),
              ),
            ),
          ),
          // Zentraler Fuchs-Glyph.
          Container(
            width: widget.width * 0.6,
            height: widget.height * 0.55,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('🦊',
                style: TextStyle(fontSize: 36, height: 1.0)),
          ),
        ],
      ),
    );
  }

  /// Glyph fuer eine Spezialkarte. Eigene Symbole, kein UNO-Vokabular.
  static String _specGlyph(LumoCardType t) {
    switch (t) {
      case LumoCardType.lumoJump:
        return '🦊⤴'; // Fuchs springt
      case LumoCardType.starRain:
        return '⭐+2';
      case LumoCardType.colorMagic:
        return '🌈';
      case LumoCardType.whirlwind:
        return '🌀+1';
      case LumoCardType.thinkPause:
        return '❓';
      case LumoCardType.number:
        return '';
    }
  }

  static List<Color> _gradientFor(LumoCardColor c) {
    switch (c) {
      case LumoCardColor.orange:
        return const [Color(0xFFFFB96B), Color(0xFFFF7A2F)];
      case LumoCardColor.purple:
        return const [Color(0xFFC4B5FD), Color(0xFF7C3AED)];
      case LumoCardColor.blue:
        return const [Color(0xFF93C5FD), Color(0xFF2563EB)];
      case LumoCardColor.green:
        return const [Color(0xFF86EFAC), Color(0xFF059669)];
    }
  }
}
