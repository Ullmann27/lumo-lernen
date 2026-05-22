// ════════════════════════════════════════════════════════════════════════
// LUMO PLAYING CARD — LUMO CARDS Design (1:1 nach Heinz' Mockups)
// ════════════════════════════════════════════════════════════════════════
// Umgesetzt nach den offiziellen LUMO-CARDS-Mockups:
//  • Farbpalette: Rot #FF4D4F, Gelb #FFC83D, Gruen #35C759, Blau #2D7BFF
//  • Glossy Karten-Body mit weissem dicken Rahmen + diagonalem Glanz
//  • Grosse WEISSE Zahl mittig (mit Schatten + faintem ovalen Glow)
//  • Eck-Index: kleine weisse Zahl + winziger Stern (oben-links +
//    unten-rechts 180-rotiert)
//  • Spezialkarten farbig mit weissem Icon: Skip = Kreis-Durchstrich,
//    Reverse = zwei Pfeile, Draw Two = +2
//  • Wild-Karten SCHWARZ mit 4-Farben-Diamant: Wild + Wild Draw Four (+4)
//  • Karten-Rueckseite: dunkles Navy mit leuchtendem Stern + Fuchs
//
// Premium-Tech bleibt: 3D-Tilt (Matrix4), Multi-Layer-Schatten,
// Holographic Shimmer, pulsierender Inner-Glow fuer spielbare Karten.
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../lumo_cards_assets.dart';
import '../lumo_cards_models.dart';

// ── LUMO CARDS Farbpalette (aus den Mockups) ──
const _kRed = Color(0xFFFF4D4F);
const _kYellow = Color(0xFFFFC83D);
const _kGreen = Color(0xFF35C759);
const _kBlue = Color(0xFF2D7BFF);
const _kWildBlack = Color(0xFF14161A);

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
    final base = _baseColor(widget.card.color);

    // 3D Tilt bei Press
    final tiltX = _pressed ? -0.08 : 0.0;
    final tiltY = _pressed ? 0.10 : 0.0;
    final scale = _pressed ? 1.06 : 1.0;
    final liftY = _pressed ? -6.0 : 0.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0015)
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
          child: _build(base),
        ),
      ),
    );
  }

  Widget _build(Color base) {
    final dimColor = widget.dimmed ? Colors.black.withOpacity(0.22) : null;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _buildShadows(base),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            widget.faceDown ? _buildBack() : _buildFront(base),

            // ── Holographic Shimmer ──
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
                        Colors.white.withOpacity(0.16),
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Inner Glow fuer playable (pulsierend) ──
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
                          color: const Color(0xFFFFE08A)
                              .withOpacity(0.55 + t * 0.35),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFC83D)
                                .withOpacity(0.30 + t * 0.20),
                            blurRadius: 12 + t * 6,
                            spreadRadius: -3,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            if (dimColor != null)
              IgnorePointer(child: Container(color: dimColor)),
          ],
        ),
      ),
    );
  }

  List<BoxShadow> _buildShadows(Color base) {
    final lift = _pressed ? 1.0 : 0.0;
    return [
      BoxShadow(
        color: base.withOpacity(0.18 + lift * 0.10),
        blurRadius: 28 + lift * 12,
        offset: Offset(0, 12 + lift * 8),
        spreadRadius: -8,
      ),
      BoxShadow(
        color: base.withOpacity(0.28 + lift * 0.15),
        blurRadius: 14 + lift * 6,
        offset: Offset(0, 6 + lift * 4),
        spreadRadius: -2,
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.18),
        blurRadius: 4,
        offset: const Offset(0, 2),
        spreadRadius: -1,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════
  // FRONT
  // ════════════════════════════════════════════════════════
  Widget _buildFront(Color base) {
    // Heinz 2026-05-22: hat sowohl Zahlenkarten als auch Spezialkarten
    // (Skip/Reverse/Draw 2 + Wild/Wild Draw 4) als PNG geliefert. Spezial-
    // karten wurden per Hue-Rotation in alle 4 Farben generiert. Wenn das
    // PNG existiert, rendern wir es; sonst Fallback auf gezeichnete Variante.
    final assetPath = LumoCardsAssets.assetFor(widget.card);
    if (assetPath != null) {
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            widget.card.isWild ? _buildWildFront() : _buildColorFront(base),
      );
    }
    if (widget.card.isWild) return _buildWildFront();
    return _buildColorFront(base);
  }

  /// Farbige Karte (Zahl ODER farbiges Spezial-Icon).
  Widget _buildColorFront(Color base) {
    final isSpec = widget.card.isSpecial;

    return Container(
      decoration: BoxDecoration(
        // Glossy: hell oben -> satt -> leicht dunkel unten
        gradient: LinearGradient(
          colors: [_lighten(base, 0.10), base, _darken(base, 0.07)],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Weisser Rahmen
          Padding(
            padding: const EdgeInsets.all(4),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2.6),
              ),
            ),
          ),
          // Glanz oben (diagonal)
          IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: widget.height * 0.42,
                margin: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(11)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.30),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Fainter ovaler Glow hinter der Zahl
          Center(
            child: Transform.rotate(
              angle: -0.5,
              child: Container(
                width: widget.width * 0.50,
                height: widget.height * 0.72,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(widget.width * 0.30),
                ),
              ),
            ),
          ),
          // Center: Zahl oder Spezial-Icon (weiss)
          Center(
            child: isSpec
                ? _specialIcon(widget.card.type, widget.width * 0.46,
                    Colors.white)
                : _bigNumber('${widget.card.number}'),
          ),
          // Eck-Indizes
          Positioned(
            top: 6,
            left: 7,
            child: _cornerIndex(isSpec),
          ),
          Positioned(
            bottom: 6,
            right: 7,
            child: Transform.rotate(
              angle: math.pi,
              child: _cornerIndex(isSpec),
            ),
          ),
        ],
      ),
    );
  }

  /// Schwarze Wild-Karte mit 4-Farben-Diamant.
  Widget _buildWildFront() {
    final isDrawFour = widget.card.type == LumoCardType.superRain;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _lighten(_kWildBlack, 0.08),
            _kWildBlack,
            Colors.black,
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Weisser Rahmen
          Padding(
            padding: const EdgeInsets.all(4),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white.withOpacity(0.90), width: 2.4),
              ),
            ),
          ),
          // Glanz oben
          IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: widget.height * 0.40,
                margin: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(11)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.12),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 4-Farben-Diamant in der Mitte
          Center(
            child: isDrawFour
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _colorDiamond(widget.width * 0.42),
                      const SizedBox(height: 4),
                      _bigNumber('+4', size: widget.width * 0.40),
                    ],
                  )
                : _colorDiamond(widget.width * 0.56),
          ),
          // Eck-Diamanten (klein)
          Positioned(
            top: 7,
            left: 8,
            child: _colorDiamond(widget.width * 0.18),
          ),
          Positioned(
            bottom: 7,
            right: 8,
            child: _colorDiamond(widget.width * 0.18),
          ),
        ],
      ),
    );
  }

  /// Grosse weisse Zahl mit Schatten (Mockup-Style).
  Widget _bigNumber(String text, {double? size}) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: size ?? 52,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1.0,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.30),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }

  /// Eck-Index: kleine weisse Zahl/Icon + winziger Stern.
  Widget _cornerIndex(bool isSpec) {
    final label = isSpec ? '' : '${widget.card.number}';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isSpec)
          _specialIcon(widget.card.type, 16, Colors.white)
        else
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.0,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.28),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        const Text('✦',
            style: TextStyle(fontSize: 7, color: Colors.white, height: 1.2)),
      ],
    );
  }

  /// Spezial-Icon (weiss): Skip / Reverse / Draw Two / Think.
  Widget _specialIcon(LumoCardType t, double size, Color color) {
    switch (t) {
      case LumoCardType.lumoJump: // Skip
        return Icon(Icons.block_rounded, size: size, color: color);
      case LumoCardType.whirlwind: // Reverse
        return Icon(Icons.sync_rounded, size: size, color: color);
      case LumoCardType.starRain: // Draw Two
        return _bigNumber('+2', size: size);
      case LumoCardType.thinkPause: // Lumo USP - Lernfrage
        return Icon(Icons.help_rounded, size: size, color: color);
      case LumoCardType.colorMagic:
      case LumoCardType.superRain:
      case LumoCardType.number:
        return const SizedBox.shrink();
    }
  }

  /// 4-Farben-Diamant (rot/gelb/gruen/blau, 45-rotiert) fuer Wild.
  Widget _colorDiamond(double size) {
    return Transform.rotate(
      angle: 0.785, // 45 Grad
      child: Container(
        width: size * 0.72,
        height: size * 0.72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withOpacity(0.85), width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Column(
            children: [
              Expanded(
                child: Row(children: [
                  Expanded(child: Container(color: _kRed)),
                  Expanded(child: Container(color: _kYellow)),
                ]),
              ),
              Expanded(
                child: Row(children: [
                  Expanded(child: Container(color: _kBlue)),
                  Expanded(child: Container(color: _kGreen)),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // BACK — dunkles Navy mit leuchtendem Stern + Fuchs (Mockup)
  // ════════════════════════════════════════════════════════
  Widget _buildBack() {
    // Heinz 2026-05-22: Card-Back-PNG aus seinem Sheet liegt unter
    // assets/lumo_cards/cards/back/card_back_default.png. Wenn das
    // Asset vorhanden ist: rendern. Sonst: gezeichneter Fallback unten.
    return Image.asset(
      LumoCardsAssets.cardBack,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildBackFallback(),
    );
  }

  Widget _buildBackFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3B2A6B), Color(0xFF241947), Color(0xFF14102B)],
          stops: [0.0, 0.55, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Sternenstaub-Pattern
          Positioned.fill(
            child: CustomPaint(painter: _StarDustPainter()),
          ),
          // Weisser Rahmen
          Padding(
            padding: const EdgeInsets.all(4),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white.withOpacity(0.30), width: 1.8),
              ),
            ),
          ),
          // Leuchtender Stern (zentral)
          Container(
            width: widget.width * 0.42,
            height: widget.width * 0.42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFFFFE9A8), Color(0x00FFE9A8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD45A).withOpacity(0.6),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text('✦',
                style: TextStyle(
                  fontSize: widget.width * 0.34,
                  color: Colors.white,
                  height: 1.0,
                )),
          ),
          // Kleiner Fuchs unten
          Positioned(
            bottom: 8,
            child: Text('🦊',
                style: TextStyle(fontSize: widget.width * 0.16, height: 1.0)),
          ),
        ],
      ),
    );
  }

  // ── Farb-Mapping: enum -> Mockup-Palette ──
  static Color _baseColor(LumoCardColor c) {
    switch (c) {
      case LumoCardColor.orange:
        return _kRed; // Rot
      case LumoCardColor.purple:
        return _kYellow; // Gelb
      case LumoCardColor.blue:
        return _kBlue; // Blau
      case LumoCardColor.green:
        return _kGreen; // Gruen
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

/// Sternenstaub fuer die Karten-Rueckseite.
class _StarDustPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(7);
    final paint = Paint();
    for (int i = 0; i < 22; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = 0.6 + rng.nextDouble() * 1.2;
      paint.color = Colors.white.withOpacity(0.15 + rng.nextDouble() * 0.35);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_StarDustPainter old) => false;
}
