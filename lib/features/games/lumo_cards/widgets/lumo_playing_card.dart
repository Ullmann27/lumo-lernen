// ════════════════════════════════════════════════════════════════════════
// LUMO PLAYING CARD — Premium-Edition (hochmodern, 2026)
// ════════════════════════════════════════════════════════════════════════
// Was wurde optimiert:
//  • 3D Perspective Tilt (Matrix4) statt nur Scale - Karte kippt wenn
//    gedrueckt mit echter Tiefenwahrnehmung.
//  • Holographic Shimmer Overlay - subtiler diagonaler Glanz wie auf
//    echten Premium-Sammelkarten.
//  • Inner Glow fuer playable Karten - sanft pulsierend, nicht harsh
//    auessen-gold-rand. Wirkt wie LED-Hintergrundbeleuchtung.
//  • Multi-Layer Schatten - 3 Layer fuer Tiefe (ambient, mid, contact).
//  • Card-Back mit Lumo-Pattern - wiederholendes Fox-Silhouetten-Muster
//    statt einzelnem grossem Emoji.
//  • Premium Edge-Highlight oben - subtiler weisser Glanz an der
//    Oberkante fuer "Glas/Plastik"-Look.
//  • Bouncy Easing fuer Press-Animation - elastische Reaktion.
//  • Center-Bubble mit subtle Gradient statt flat-white.
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

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

class _LumoPlayingCardState extends State<LumoPlayingCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _gradientFor(widget.card.color);

    // 3D Tilt: leichte Y-Rotation + nach-vorne-kippen wenn gedrueckt
    final tiltX = _pressed ? -0.08 : 0.0;
    final tiltY = _pressed ? 0.10 : 0.0;
    final scale = _pressed ? 1.06 : 1.0;
    final liftY = _pressed ? -6.0 : 0.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0015) // perspective
        ..rotateX(tiltX)
        ..rotateY(tiltY)
        ..scale(scale),
      transformAlignment: Alignment.center,
      child: Transform.translate(
        offset: Offset(0, liftY),
        child: GestureDetector(
          onTapDown: widget.onTap == null
              ? null
              : (_) => setState(() => _pressed = true),
          onTapUp: widget.onTap == null
              ? null
              : (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: _build(colors),
        ),
      ),
    );
  }

  Widget _build(List<Color> colors) {
    final dimColor = widget.dimmed ? Colors.black.withOpacity(0.22) : null;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _buildShadows(colors),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            widget.faceDown ? _buildBack() : _buildFront(colors),

            // ── Holographic Shimmer Overlay ──
            // Diagonaler weisser Glanz - simuliert Premium-Karten-Folie.
            if (!widget.faceDown)
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: const Alignment(-1.2, -1),
                      end: const Alignment(1.2, 1),
                      stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.18),
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Premium Edge-Highlight oben ──
            // Subtiler weisser Glanz an der Oberkante (Glas/Plastik-Look).
            IgnorePointer(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.35),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Inner Glow fuer playable Karten (pulsierend) ──
            if (widget.playable && !widget.faceDown)
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) {
                  final t = _pulseCtrl.value;
                  return IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFCD34D)
                              .withOpacity(0.55 + t * 0.35),
                          width: 2.5,
                        ),
                        boxShadow: [
                          // Inner glow (negative spread + inset effect)
                          BoxShadow(
                            color: const Color(0xFFFCD34D)
                                .withOpacity(0.35 + t * 0.20),
                            blurRadius: 12 + t * 6,
                            spreadRadius: -3,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            // ── Dimming-Layer fuer nicht-spielbare Karten ──
            if (dimColor != null)
              IgnorePointer(
                child: Container(color: dimColor),
              ),
          ],
        ),
      ),
    );
  }

  List<BoxShadow> _buildShadows(List<Color> colors) {
    final lift = _pressed ? 1.0 : 0.0;
    return [
      // Layer 1: Ambient (weit + soft, leicht warm)
      BoxShadow(
        color: colors[1].withOpacity(0.18 + lift * 0.10),
        blurRadius: 28 + lift * 12,
        offset: Offset(0, 12 + lift * 8),
        spreadRadius: -8,
      ),
      // Layer 2: Mid (Tiefe)
      BoxShadow(
        color: colors[1].withOpacity(0.30 + lift * 0.15),
        blurRadius: 14 + lift * 6,
        offset: Offset(0, 6 + lift * 4),
        spreadRadius: -2,
      ),
      // Layer 3: Contact (scharf, direkt unter Karte)
      BoxShadow(
        color: Colors.black.withOpacity(0.18),
        blurRadius: 4,
        offset: const Offset(0, 2),
        spreadRadius: -1,
      ),
      // Highlight oben (subtil)
      BoxShadow(
        color: Colors.white.withOpacity(0.4),
        blurRadius: 5,
        offset: const Offset(-1, -2),
        spreadRadius: -3,
      ),
    ];
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
        // Solider, satter Farbkoerper - professioneller Karten-Look.
        // Subtiler Verlauf von hell oben-links zu dunkel unten-rechts.
        gradient: LinearGradient(
          colors: [
            _lighten(colors[1], 0.06),
            colors[1],
            _darken(colors[1], 0.08),
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Weisser Inner-Rahmen (Karten-Kante) ──
          Padding(
            padding: const EdgeInsets.all(4),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.92),
                  width: 2.2,
                ),
              ),
            ),
          ),

          // ── IKONISCHES CENTERPIECE: rotierte weisse Ellipse (Diamant) ──
          // Das ist die Signature-Optik moderner Karten-Spiele: eine
          // schraeg gestellte weisse Kapsel, auf der die Zahl gross prangt.
          Center(
            child: Transform.rotate(
              angle: -0.52, // ~ -30 Grad - schraeg gestellt
              child: Container(
                width: widget.width * 0.52,
                height: widget.height * 0.78,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(widget.width * 0.30),
                  boxShadow: [
                    // Sanfter Schatten unter der Ellipse (Tiefe)
                    BoxShadow(
                      color: _darken(colors[1], 0.15).withOpacity(0.45),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                      spreadRadius: -1,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Grosse Zahl/Glyph - AUFRECHT auf der Ellipse ──
          // Steht gerade (nicht mitrotiert) damit gut lesbar.
          Center(
            child: SizedBox(
              width: widget.width * 0.66,
              height: widget.height * 0.66,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    centerLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: isSpec ? 28 : 50,
                      fontWeight: FontWeight.w900,
                      color: colors[1],
                      height: 1.0,
                      shadows: [
                        // Subtiler Tiefenschatten fuer die Zahl
                        Shadow(
                          color: _darken(colors[1], 0.20).withOpacity(0.30),
                          offset: const Offset(0, 2),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Eck-Indizes: oben-links + unten-rechts (180 rotiert) ──
          // Weiss mit Schatten - der klassische Karten-Index.
          Positioned(
            top: 7,
            left: 9,
            child: _cornerLabel(cornerLabel, colors[1]),
          ),
          Positioned(
            bottom: 7,
            right: 9,
            child: Transform.rotate(
              angle: math.pi,
              child: _cornerLabel(cornerLabel, colors[1]),
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
            color: color.withOpacity(0.55),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
          Shadow(
            color: Colors.black.withOpacity(0.20),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFB266), // lighter top
            Color(0xFFFF7A2F),
            Color(0xFFE85A11), // deeper bottom
          ],
          stops: [0.0, 0.55, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Subtle Lumo-Pattern: wiederholende Fox-Silhouetten ──
          Positioned.fill(
            child: CustomPaint(
              painter: _LumoBackPatternPainter(),
            ),
          ),
          // ── Weisser Inner-Rahmen ──
          Padding(
            padding: const EdgeInsets.all(4),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.85),
                  width: 1.8,
                ),
              ),
            ),
          ),
          // ── Zentraler Fuchs-Medaillon ──
          Container(
            width: widget.width * 0.58,
            height: widget.height * 0.50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.white.withOpacity(0.92)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE85A11).withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                  spreadRadius: -1,
                ),
              ],
            ),
            child: const Text('🦊',
                style: TextStyle(fontSize: 36, height: 1.0)),
          ),
        ],
      ),
    );
  }

  /// Glyph fuer eine Spezialkarte. Eigene Lumo-Symbole.
  static String _specGlyph(LumoCardType t) {
    switch (t) {
      case LumoCardType.lumoJump:
        return '🦊⤴';
      case LumoCardType.starRain:
        return '⭐+2';
      case LumoCardType.colorMagic:
        return '🌈';
      case LumoCardType.superRain:
        return '🌟+4';
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
        return const [Color(0xFFFFC68F), Color(0xFFFF7A2F)];
      case LumoCardColor.purple:
        return const [Color(0xFFCBB7FF), Color(0xFF7C3AED)];
      case LumoCardColor.blue:
        return const [Color(0xFFA5CDFF), Color(0xFF2563EB)];
      case LumoCardColor.green:
        return const [Color(0xFF99F0BD), Color(0xFF059669)];
    }
  }

  static Color _darken(Color c, double amount) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  static Color _lighten(Color c, double amount) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness + amount).clamp(0.0, 1.0)).toColor();
  }
}

/// Subtiles Pattern fuer die Karten-Rueckseite. Wiederholende kleine
/// Punkte/Sterne fuer Premium-Look (statt einer einzelnen Riesen-Emoji).
class _LumoBackPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.12);
    // Diagonales Punkt-Raster.
    const spacing = 14.0;
    for (double y = 4; y < size.height; y += spacing) {
      final offsetX = ((y / spacing).floor() % 2 == 0) ? 0.0 : spacing / 2;
      for (double x = 4 + offsetX; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_LumoBackPatternPainter old) => false;
}
