import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

/// Sprint 5 - Premium-Mathe-Visuals fuer Lumo Lernen.
/// Vier eigenstaendige Widgets, alle ohne neue Dependency.
///
/// Verwendung:
///   QuantityPictureCard(count: 7)
///   NumberLineVisual(highlight: 8, max: 20)
///   MathHouseVisual(roof: 10, leftRoom: 4)
///   PlaceValueVisual(tens: 3, ones: 7)

// ════════════════════════════════════════════════════════
// 1) MENGENBILDER - grosse runde Punkte, max 20
// ════════════════════════════════════════════════════════

class QuantityPictureCard extends StatelessWidget {
  const QuantityPictureCard({
    super.key,
    required this.count,
    this.dotColor = LumoColors.orange,
    this.label,
    this.background = LumoColors.orangeSurface,
  });

  final int count;
  final Color dotColor;
  final Color background;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final n = count.clamp(0, 20);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: dotColor.withOpacity(0.25), width: 1.6),
      ),
      child: Column(
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: LumoColors.ink900,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List<Widget>.generate(n, (i) {
              return _Dot(color: dotColor, size: 28);
            }),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: <Color>[
            Color.lerp(color, Colors.white, 0.45)!,
            color,
          ],
          stops: const <double>[0.0, 1.0],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
// 2) ZAHLENSTRAHL - mit Hopper-Lumo an Position
// ════════════════════════════════════════════════════════

class NumberLineVisual extends StatelessWidget {
  const NumberLineVisual({
    super.key,
    required this.max,
    this.highlight,
    this.from,
    this.to,
    this.height = 88,
  });

  final int max;
  /// Markierte Hauptposition (Lumo sitzt drauf).
  final int? highlight;
  /// Optionaler Sprung-Anfang (gruener Marker).
  final int? from;
  /// Optionaler Sprung-Ziel (oranger Marker).
  final int? to;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: LumoColors.blueSurface,
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: LumoColors.blue.withOpacity(0.25), width: 1.4),
      ),
      child: CustomPaint(
        painter: _NumberLinePainter(
          max: max,
          highlight: highlight,
          from: from,
          to: to,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _NumberLinePainter extends CustomPainter {
  _NumberLinePainter({required this.max, this.highlight, this.from, this.to});
  final int max;
  final int? highlight;
  final int? from;
  final int? to;

  @override
  void paint(Canvas canvas, Size size) {
    final padL = 8.0;
    final padR = 8.0;
    final lineY = size.height * 0.65;
    final usable = size.width - padL - padR;
    final step = max == 0 ? usable : usable / max;

    // Linie
    final linePaint = Paint()
      ..color = LumoColors.blue
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(padL, lineY), Offset(size.width - padR, lineY), linePaint);

    // Ticks + Zahlen
    final tickPaint = Paint()..color = LumoColors.blue..strokeWidth = 3..strokeCap = StrokeCap.round;
    for (var i = 0; i <= max; i++) {
      final x = padL + step * i;
      canvas.drawLine(Offset(x, lineY - 6), Offset(x, lineY + 6), tickPaint);
      final tp = TextPainter(
        text: TextSpan(
          text: '$i',
          style: TextStyle(
            color: LumoColors.ink900,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: max > 12 ? 10 : 12,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, lineY + 10));
    }

    // Sprung-Bogen (optional)
    if (from != null && to != null) {
      final fromX = padL + step * from!.clamp(0, max);
      final toX = padL + step * to!.clamp(0, max);
      final arcPaint = Paint()
        ..color = LumoColors.orange.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      final path = Path()
        ..moveTo(fromX, lineY)
        ..quadraticBezierTo((fromX + toX) / 2, lineY - 30, toX, lineY);
      canvas.drawPath(path, arcPaint);
      // Pfeil-Spitze
      final dir = toX > fromX ? 1 : -1;
      final tipPaint = Paint()..color = LumoColors.orange;
      final tip = Path()
        ..moveTo(toX, lineY)
        ..lineTo(toX - 6 * dir, lineY - 5)
        ..lineTo(toX - 6 * dir, lineY + 5)
        ..close();
      canvas.drawPath(tip, tipPaint);
    }

    // Highlight - Lumo-Position
    if (highlight != null) {
      final hx = padL + step * highlight!.clamp(0, max);
      final glowPaint = Paint()
        ..color = LumoColors.orange.withOpacity(0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(hx, lineY - 14), 14, glowPaint);
      final dotPaint = Paint()..color = LumoColors.orange;
      canvas.drawCircle(Offset(hx, lineY - 14), 12, dotPaint);
      final bordPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(Offset(hx, lineY - 14), 12, bordPaint);
      // Fox-Emoji im Kreis als Marker
      final tp = TextPainter(
        text: const TextSpan(text: '🦊', style: TextStyle(fontSize: 16)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(hx - tp.width / 2, lineY - 14 - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _NumberLinePainter old) =>
      old.max != max || old.highlight != highlight || old.from != from || old.to != to;
}

// ════════════════════════════════════════════════════════
// 3) RECHENHAUS - Dach + 2 Zimmer (Zahlzerlegung)
// ════════════════════════════════════════════════════════

class MathHouseVisual extends StatelessWidget {
  const MathHouseVisual({
    super.key,
    required this.roof,
    this.leftRoom,
    this.rightRoom,
    this.size = 180,
  });

  /// Zahl im Dach (Summe).
  final int roof;
  /// Linke Kammer (null = ? Platzhalter).
  final int? leftRoom;
  /// Rechte Kammer.
  final int? rightRoom;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MathHousePainter(roof: roof, left: leftRoom, right: rightRoom),
      ),
    );
  }
}

class _MathHousePainter extends CustomPainter {
  _MathHousePainter({required this.roof, this.left, this.right});
  final int roof;
  final int? left;
  final int? right;

  @override
  void paint(Canvas canvas, Size size) {
    // Dach (Dreieck)
    final roofPaint = Paint()..color = LumoColors.orange;
    final roofPath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.04)
      ..lineTo(size.width * 0.04, size.height * 0.40)
      ..lineTo(size.width * 0.96, size.height * 0.40)
      ..close();
    canvas.drawPath(roofPath, roofPaint);

    // Dach-Border
    final borderPaint = Paint()
      ..color = const Color(0xFFC2410C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(roofPath, borderPaint);

    // Zahl im Dach
    _drawNumber(canvas, '$roof', Offset(size.width * 0.5, size.height * 0.27), 28, Colors.white);

    // Haus-Korpus (Rechteck)
    final bodyRect = Rect.fromLTWH(
      size.width * 0.10,
      size.height * 0.40,
      size.width * 0.80,
      size.height * 0.55,
    );
    final bodyPaint = Paint()..color = LumoColors.orangeSurface;
    canvas.drawRect(bodyRect, bodyPaint);
    canvas.drawRect(bodyRect, borderPaint);

    // Trennlinie zwischen Zimmern
    final midX = size.width * 0.5;
    final midPaint = Paint()
      ..color = const Color(0xFFC2410C)
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(midX, size.height * 0.42),
      Offset(midX, size.height * 0.93),
      midPaint,
    );

    // Linke Kammer
    final leftLabel = left == null ? '?' : '$left';
    final leftColor = left == null ? LumoColors.ink400 : LumoColors.ink900;
    _drawNumber(canvas, leftLabel, Offset(size.width * 0.30, size.height * 0.68), 36, leftColor);

    // Rechte Kammer
    final rightLabel = right == null ? '?' : '$right';
    final rightColor = right == null ? LumoColors.ink400 : LumoColors.ink900;
    _drawNumber(canvas, rightLabel, Offset(size.width * 0.70, size.height * 0.68), 36, rightColor);
  }

  void _drawNumber(Canvas canvas, String text, Offset center, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w900,
          fontSize: size,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _MathHousePainter old) =>
      old.roof != roof || old.left != left || old.right != right;
}

// ════════════════════════════════════════════════════════
// 4) ZEHNER/EINER-TABELLE
// ════════════════════════════════════════════════════════

class PlaceValueVisual extends StatelessWidget {
  const PlaceValueVisual({
    super.key,
    required this.tens,
    required this.ones,
  });

  final int tens;
  final int ones;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LumoColors.tealSurface,
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: LumoColors.teal.withOpacity(0.3), width: 1.4),
      ),
      child: Row(
        children: [
          Expanded(child: _Column(label: 'Z', count: tens, color: LumoColors.teal, isTens: true)),
          const SizedBox(width: 12),
          Expanded(child: _Column(label: 'E', count: ones, color: LumoColors.orange, isTens: false)),
        ],
      ),
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({required this.label, required this.count, required this.color, required this.isTens});
  final String label;
  final int count;
  final Color color;
  final bool isTens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(LumoRadius.pill),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$count',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            fontSize: 32,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: isTens
              ? List<Widget>.generate(math.min(count, 9), (_) => _TensBar(color: color))
              : List<Widget>.generate(math.min(count, 9), (_) => _Dot(color: color, size: 14)),
        ),
      ],
    );
  }
}

class _TensBar extends StatelessWidget {
  const _TensBar({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}
