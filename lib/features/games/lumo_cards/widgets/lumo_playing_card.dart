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

// Original LUMO suits: rose/star, gold/moon, indigo/crystal, teal/leaf.
// Not the flat primary palette of a well-known commercial shedding game.
const _kRose = Color(0xFFD44A6A);
const _kGold = Color(0xFFE0A83A);
const _kIndigo = Color(0xFF4A58E0);
const _kTeal = Color(0xFF1E9A78);
const _kCream = Color(0xFFFFF4D6);

class LumoPlayingCard extends StatefulWidget {
  const LumoPlayingCard({
    super.key,
    required this.card,
    this.width = 96,
    this.height = 140,
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

  /// Describes only the rendered face, never the identity of a covered card.
  String get semanticLabel {
    if (faceDown) return 'Verdeckt';
    final visibleColor = card.isWild ? 'Vier Farben' : card.color.displayName;
    final visibleType = switch (card.type) {
      LumoCardType.number => 'Zahl ${card.number}',
      LumoCardType.lumoJump => 'Lumo-Sprung',
      LumoCardType.starRain => 'Sternenregen, zwei Karten ziehen',
      LumoCardType.colorMagic => 'Farbzauber',
      LumoCardType.superRain => 'Superregen, vier Karten ziehen',
      LumoCardType.whirlwind => 'Wirbelwind',
      LumoCardType.thinkPause => 'Denkpause',
    };
    final action = playable ? ', spielbar' : (dimmed ? ', nicht spielbar' : '');
    return 'Lumo Karte, $visibleColor, $visibleType$action';
  }

  @override
  State<LumoPlayingCard> createState() => _LumoPlayingCardState();
}

class _LumoPlayingCardState extends State<LumoPlayingCard> {
  // Heinz Crash 2026-05-22 Build 182: stabilitaets-Refactor.
  // - kein dauerhafter AnimationController mehr (jeder LumoPlayingCard
  //   hatte einen, 7+ Hand + 7+ Gegner + 1 Discard + 1 Draw = 16+ Tickers
  //   gleichzeitig -> Memory-Pressure + Lifecycle-Risk).
  // - kein Matrix4-Perspective mehr (komplexe Transform-Math + Layout-
  //   Interaktion).
  // - kein Holographic-Shimmer-Stack mehr.
  // - kein AnimatedBuilder mit Pulse mehr.
  // Press-Feedback laeuft jetzt ueber implicit AnimatedScale - ein einziger
  // billiger Widget statt eines vollen AnimationControllers.
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final base = _baseColor(widget.card.color);

    return Semantics(
        container: true,
        label: widget.semanticLabel,
        button: !widget.faceDown && (widget.playable || widget.onTap != null),
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: GestureDetector(
            onTapDown: widget.onTap == null
                ? null
                : (_) => setState(() => _pressed = true),
            onTapUp: widget.onTap == null
                ? null
                : (_) => setState(() => _pressed = false),
            onTapCancel: widget.onTap == null
                ? null
                : () => setState(() => _pressed = false),
            onTap: widget.onTap,
            child: AnimatedScale(
              scale: _pressed ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              // Tier 4 3D-Optik 2026-05-23: STATISCHE Matrix4-Perspektive.
              // Im Gegensatz zu Build 181 (Crash mit AnimatedContainer +
              // Matrix4 + per-card-Controller) ist diese Perspektive
              // statisch - kein AnimationController, kein pro-Frame-Update,
              // keine Lifecycle-Konflikte. Wirkt nur als visuelle Tiefe:
              //  - faceDown-Karten leicht nach rechts geneigt (wie schief
              //    aufeinander gestapelt)
              //  - playable-Karten leicht zum Spieler hin geneigt (heben
              //    sich von dimmed-Karten ab)
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateX(
                      widget.faceDown ? 0 : (widget.playable ? -0.06 : -0.02))
                  ..rotateY(widget.faceDown ? 0.04 : 0),
                alignment: Alignment.center,
                child: ExcludeSemantics(child: _build(base)),
              ),
            ),
          ),
        ));
  }

  Widget _build(Color base) {
    final dimColor = widget.dimmed ? Colors.black.withOpacity(0.22) : null;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        boxShadow: _buildShadows(base),
      ),
      child: ClipPath(
        clipper: const _LumoCrestClipper(),
        child: Stack(
          children: [
            widget.faceDown ? _buildBack() : _buildFront(base),
            if (widget.playable && !widget.faceDown)
              const Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _LumoCrestBorderPainter(
                      color: Color(0xFFFFE08A),
                      stroke: 3,
                    ),
                  ),
                ),
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
        color: base.withOpacity(0.20 + lift * 0.10),
        blurRadius: 16 + lift * 8,
        offset: Offset(0, 6 + lift * 4),
        spreadRadius: -4,
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.20),
        blurRadius: 3,
        offset: const Offset(0, 2),
        spreadRadius: -1,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════
  // FRONT
  // ════════════════════════════════════════════════════════
  Widget _buildFront(Color base) {
    // Painted original LUMO faces only. Historical PNG faces reused a
    // primary-color + number + circle-slash language and are not shown.
    // Asset paths stay available via LumoCardsAssets.assetFor for tests.
    if (widget.card.isWild) return _buildWildFront();
    return _buildColorFront(base);
  }

  /// Night-sky tablet with a colored suit, not a flat primary-color face.
  Widget _buildColorFront(Color base) {
    final isSpec = widget.card.isSpecial;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF241830),
                Color.lerp(const Color(0xFF141028), base, 0.38)!,
                const Color(0xFF0A0818),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            height: widget.height * 0.18,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_lighten(base, 0.16), base, _darken(base, 0.12)],
              ),
            ),
          ),
        ),
        Center(
          child: Opacity(
            opacity: 0.20,
            child: Icon(
              _suitIcon(widget.card.color),
              size: widget.width * 0.82,
              color: base,
            ),
          ),
        ),
        Center(
          child: isSpec
              ? _specialIcon(widget.card.type, widget.width * 0.44, _kCream)
              : _bigNumber('${widget.card.number}'),
        ),
        Positioned(
          top: widget.height * 0.20,
          left: 8,
          child: _cornerIndex(isSpec, base),
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: Transform.rotate(
            angle: math.pi,
            child: _cornerIndex(isSpec, base),
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _LumoCrestBorderPainter(
                color: Color(0xFFE8C45A),
                stroke: 2.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Wild card: four LUMO suits, not a four-color commercial diamond.
  Widget _buildWildFront() {
    final isDrawFour = widget.card.type == LumoCardType.superRain;
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2A2038), Color(0xFF14161A), Color(0xFF07060C)],
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _suitFlower(widget.width * (isDrawFour ? 0.46 : 0.56)),
              if (isDrawFour) ...[
                const SizedBox(height: 4),
                Icon(Icons.auto_awesome_rounded,
                    size: widget.width * 0.22, color: _kCream),
              ],
            ],
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _LumoCrestBorderPainter(
                color: Color(0xFFE8C45A),
                stroke: 2.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

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
          color: _kCream,
          height: 1.0,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.35),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _cornerIndex(bool isSpec, Color base) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isSpec)
          _specialIcon(widget.card.type, 15, _kCream)
        else
          Text(
            '${widget.card.number}',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: _kCream,
              height: 1.0,
            ),
          ),
        Icon(_suitIcon(widget.card.color), size: 11, color: base),
      ],
    );
  }

  Widget _specialIcon(LumoCardType t, double size, Color color) {
    switch (t) {
      case LumoCardType.lumoJump:
        return Icon(Icons.auto_awesome_rounded, size: size, color: color);
      case LumoCardType.whirlwind:
        return Icon(Icons.cyclone_rounded, size: size, color: color);
      case LumoCardType.starRain:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: size * 0.62, color: color),
            Icon(Icons.star_rounded, size: size * 0.62, color: color),
          ],
        );
      case LumoCardType.thinkPause:
        return Icon(Icons.menu_book_rounded, size: size, color: color);
      case LumoCardType.colorMagic:
      case LumoCardType.superRain:
      case LumoCardType.number:
        return const SizedBox.shrink();
    }
  }

  Widget _suitFlower(double size) {
    const suits = <(IconData, Color)>[
      (Icons.star_rounded, _kRose),
      (Icons.nightlight_round, _kGold),
      (Icons.diamond_rounded, _kIndigo),
      (Icons.eco_rounded, _kTeal),
    ];
    return SizedBox(
      width: size,
      height: size,
      child: Column(
        children: [
          Expanded(
            child: Row(children: [
              Expanded(
                  child:
                      Icon(suits[0].$1, color: suits[0].$2, size: size * 0.38)),
              Expanded(
                  child:
                      Icon(suits[1].$1, color: suits[1].$2, size: size * 0.38)),
            ]),
          ),
          Expanded(
            child: Row(children: [
              Expanded(
                  child:
                      Icon(suits[2].$1, color: suits[2].$2, size: size * 0.38)),
              Expanded(
                  child:
                      Icon(suits[3].$1, color: suits[3].$2, size: size * 0.38)),
            ]),
          ),
        ],
      ),
    );
  }

  static IconData _suitIcon(LumoCardColor c) {
    switch (c) {
      case LumoCardColor.orange:
        return Icons.star_rounded;
      case LumoCardColor.purple:
        return Icons.nightlight_round;
      case LumoCardColor.blue:
        return Icons.diamond_rounded;
      case LumoCardColor.green:
        return Icons.eco_rounded;
    }
  }

  // ════════════════════════════════════════════════════════
  // BACK — dunkles Navy mit leuchtendem Stern + Fuchs (Mockup)
  // ════════════════════════════════════════════════════════
  Widget _buildBack() {
    // Selber Anti-Pattern-Fix wie in _buildFront (Heinz Build 181 Crash).
    return Image.asset(
      LumoCardsAssets.cardBack,
      width: widget.width,
      height: widget.height,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      cacheWidth: 264,
      errorBuilder: (_, __, ___) => _buildBackFallback(),
    );
  }

  Widget _buildBackFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1C4BB0), Color(0xFF123A8C), Color(0xFF0B2468)],
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
                    color: const Color(0xFFE8C45A).withOpacity(0.90),
                    width: 2.2),
              ),
            ),
          ),
          Container(
            width: widget.width * 0.48,
            height: widget.width * 0.48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0x66FFE9A8), Color(0x00FFE9A8)],
              ),
            ),
            alignment: Alignment.center,
            child: Text('L',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: widget.width * 0.36,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFFFD24A),
                  height: 1.0,
                  shadows: const [
                    Shadow(color: Color(0xAAFFE08A), blurRadius: 12),
                  ],
                )),
          ),
        ],
      ),
    );
  }

  // ── Farb-Mapping: enum -> Mockup-Palette ──
  static Color _baseColor(LumoCardColor c) {
    switch (c) {
      case LumoCardColor.orange:
        return _kRose;
      case LumoCardColor.purple:
        return _kGold;
      case LumoCardColor.blue:
        return _kIndigo;
      case LumoCardColor.green:
        return _kTeal;
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

Path _lumoCrestPath(Size size) {
  final w = size.width;
  final h = size.height;
  final peak = h * 0.085;
  return Path()
    ..moveTo(w * 0.5, 1)
    ..quadraticBezierTo(w * 0.84, 1, w - 1.6, peak)
    ..lineTo(w - 1.6, h - 16)
    ..quadraticBezierTo(w - 1.6, h - 1.6, w - 16, h - 1.6)
    ..lineTo(16, h - 1.6)
    ..quadraticBezierTo(1.6, h - 1.6, 1.6, h - 16)
    ..lineTo(1.6, peak)
    ..quadraticBezierTo(w * 0.16, 1, w * 0.5, 1)
    ..close();
}

class _LumoCrestClipper extends CustomClipper<Path> {
  const _LumoCrestClipper();

  @override
  Path getClip(Size size) => _lumoCrestPath(size);

  @override
  bool shouldReclip(covariant _LumoCrestClipper oldClipper) => false;
}

class _LumoCrestBorderPainter extends CustomPainter {
  const _LumoCrestBorderPainter({required this.color, required this.stroke});

  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.drawPath(
      _lumoCrestPath(size),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _LumoCrestBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.stroke != stroke;
}
