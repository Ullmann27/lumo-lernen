// ════════════════════════════════════════════════════════════════════════
// LUMO CONFETTI — bunte Partikel die nach unten regnen (Sieg-Animation)
// ════════════════════════════════════════════════════════════════════════
// Heinz Mockup-Sheet 2026-05-22: 'Confetti pieces' als Sieg-Effekt.
// Einmal-Animation: bei Game-Over erscheint dieses Widget kurz UEBER
// dem Result-Dialog, ~2.5 Sekunden lang.
//
// Stabil: ein einziger AnimationController, der bei dispose sauber
// abgeraeumt wird. Pures CustomPainter, kein Image-Decode, kein
// Inherited-Widget-Subscribe.
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';

class LumoConfetti extends StatefulWidget {
  const LumoConfetti({
    super.key,
    this.duration = const Duration(milliseconds: 2400),
    this.pieceCount = 70,
  });

  final Duration duration;
  final int pieceCount;

  @override
  State<LumoConfetti> createState() => _LumoConfettiState();
}

class _LumoConfettiState extends State<LumoConfetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Piece> _pieces;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    final rng = math.Random();
    _pieces = List.generate(widget.pieceCount, (_) => _Piece.random(rng));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tier 1 Foundation 2026-05-23: RepaintBoundary isoliert die 60-fps-
    // Confetti-Painter-Updates vom Result-Dialog drunter. Dialog wird so
    // nicht 60-mal pro Sekunde mit neu komponiert.
    return RepaintBoundary(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            return CustomPaint(
              painter: _ConfettiPainter(_ctrl.value, _pieces),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class _Piece {
  _Piece({
    required this.startX,
    required this.endX,
    required this.startY,
    required this.endY,
    required this.color,
    required this.size,
    required this.spinSpeed,
    required this.shape,
    required this.delay,
  });

  factory _Piece.random(math.Random rng) {
    const palette = [
      Color(0xFFFF4D4F), // Rot
      Color(0xFFFFC83D), // Gelb
      Color(0xFF2D7BFF), // Blau
      Color(0xFF35C759), // Gruen
      Color(0xFFFF7A2F), // Orange
      Color(0xFF7C3AED), // Lila
      Color(0xFFFFFFFF), // Weiss
    ];
    final dxStart = -0.05 + rng.nextDouble() * 1.10;
    return _Piece(
      startX: dxStart,
      endX: dxStart + (rng.nextDouble() * 0.32 - 0.16),
      startY: -0.10 - rng.nextDouble() * 0.20,
      endY: 1.15,
      color: palette[rng.nextInt(palette.length)],
      size: 6.0 + rng.nextDouble() * 10.0,
      spinSpeed: (rng.nextDouble() * 6 - 3),
      shape: rng.nextInt(3), // 0=rect, 1=circle, 2=diamond
      delay: rng.nextDouble() * 0.3,
    );
  }

  final double startX; // 0..1 (normalisiert)
  final double endX;
  final double startY;
  final double endY;
  final Color color;
  final double size;
  final double spinSpeed;
  final int shape;
  final double delay;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t, this.pieces);

  final double t; // 0..1 globaler Fortschritt
  final List<_Piece> pieces;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in pieces) {
      final localT = ((t - p.delay) / (1.0 - p.delay)).clamp(0.0, 1.0);
      if (localT <= 0) continue;
      final x = (p.startX + (p.endX - p.startX) * localT) * size.width;
      final y = (p.startY + (p.endY - p.startY) * localT) * size.height;
      final fadeOut = localT > 0.85 ? (1 - (localT - 0.85) / 0.15) : 1.0;
      paint.color = p.color.withOpacity(fadeOut.clamp(0.0, 1.0));

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(localT * p.spinSpeed);
      switch (p.shape) {
        case 0:
          final r = Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.55);
          canvas.drawRect(r, paint);
          break;
        case 1:
          canvas.drawCircle(Offset.zero, p.size * 0.4, paint);
          break;
        case 2:
          final s = p.size * 0.5;
          final path = Path()
            ..moveTo(0, -s)
            ..lineTo(s, 0)
            ..lineTo(0, s)
            ..lineTo(-s, 0)
            ..close();
          canvas.drawPath(path, paint);
          break;
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
