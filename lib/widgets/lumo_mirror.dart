// ════════════════════════════════════════════════════════════════════════
// LUMO MIRROR — Lebendiger Avatar mit 8 Moods + Eye-Following + Lip-Sync
// ════════════════════════════════════════════════════════════════════════
// Vorschlag 3 aus Heinz' Auswahl: 'wirklich lebendiger Charakter,
// Augen folgen dem Finger, Lippen bewegen sich beim Sprechen'.
//
// Tech: Custom-Painted Fuchs-Gesicht mit:
//   - 8 Mood-States (idle, happy, think, cheer, sad, curious, proud, sleepy)
//   - Eye-Tracking: Pupillen folgen einem Target-Point
//   - Mouth-Animation bei isSpeaking
//   - Atem-Animation (Scale 0.99-1.01)
//   - Tap-Reaktion (Hop)
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';

enum LumoMirrorMood {
  idle,      // Standard ruhig
  happy,     // Lacht, Augen werden zu Halbmonden
  think,     // Kopf schief, Augen schauen nach oben rechts
  cheer,     // Riesen-Hopser, Sterne um Kopf
  sad,       // Augen nach unten, Traene
  curious,   // Augen gross, Kopf nach vorne
  proud,     // Brust raus, Stern auf Stirn
  sleepy,    // Augen halb zu, Zzz
}

class LumoMirror extends StatefulWidget {
  const LumoMirror({
    super.key,
    this.mood = LumoMirrorMood.idle,
    this.size = 120,
    this.isSpeaking = false,
    this.lookAt,
    this.onTap,
  });

  final LumoMirrorMood mood;
  final double size;
  /// Wenn true: Mund bewegt sich auf/zu (TTS-Sync).
  final bool isSpeaking;
  /// Punkt in Screen-Koordinaten den die Augen anschauen sollen.
  /// null = neutral nach vorne.
  final Offset? lookAt;
  final VoidCallback? onTap;

  @override
  State<LumoMirror> createState() => _LumoMirrorState();
}

class _LumoMirrorState extends State<LumoMirror>
    with TickerProviderStateMixin {
  late final AnimationController _breathCtrl;
  late final AnimationController _moodCtrl;
  late final AnimationController _speakCtrl;
  late final AnimationController _tapCtrl;

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
    _moodCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _speakCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _tapCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    if (widget.isSpeaking) {
      _speakCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(LumoMirror old) {
    super.didUpdateWidget(old);
    if (old.isSpeaking != widget.isSpeaking) {
      if (widget.isSpeaking) {
        _speakCtrl.repeat(reverse: true);
      } else {
        _speakCtrl.stop();
        _speakCtrl.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    _moodCtrl.dispose();
    _speakCtrl.dispose();
    _tapCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _tapCtrl.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _breathCtrl, _moodCtrl, _speakCtrl, _tapCtrl,
        ]),
        builder: (_, __) {
          // Tap-Hop ueber Mood-Hop
          final tapBounce = math.sin(_tapCtrl.value * math.pi) * 8;
          // Mood-Hop
          double moodHop = 0;
          if (widget.mood == LumoMirrorMood.happy) {
            moodHop = math.sin(_moodCtrl.value * math.pi) * 4;
          } else if (widget.mood == LumoMirrorMood.cheer) {
            moodHop = math.sin(_moodCtrl.value * math.pi) * 10;
          }
          // Atem
          final breathScale = 1.0 + (_breathCtrl.value - 0.5) * 0.02;
          // Kopf-Tilt
          double tilt = 0;
          if (widget.mood == LumoMirrorMood.think) {
            tilt = -0.15;
          } else if (widget.mood == LumoMirrorMood.curious) {
            tilt = 0.1;
          }
          return Transform.translate(
            offset: Offset(0, -(moodHop + tapBounce)),
            child: Transform.scale(
              scale: breathScale,
              child: Transform.rotate(
                angle: tilt,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _MirrorPainter(
                    mood: widget.mood,
                    lookAt: widget.lookAt,
                    mouthOpen: widget.isSpeaking ? _speakCtrl.value : 0,
                    moodProgress: _moodCtrl.value,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MirrorPainter extends CustomPainter {
  _MirrorPainter({
    required this.mood,
    required this.lookAt,
    required this.mouthOpen,
    required this.moodProgress,
  });
  final LumoMirrorMood mood;
  final Offset? lookAt;
  final double mouthOpen;
  final double moodProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // Fuchs-Kopf (orange Kreis)
    final headPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFA85C), Color(0xFFEA580C)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(
          center: Offset(cx, cy), radius: w * 0.4));
    canvas.drawCircle(Offset(cx, cy + h * 0.05), w * 0.38, headPaint);

    // Ohren (zwei Dreiecke)
    final earPaint = Paint()..color = const Color(0xFFEA580C);
    _drawEar(canvas, Offset(cx - w * 0.22, cy - h * 0.2),
        w * 0.12, earPaint, false);
    _drawEar(canvas, Offset(cx + w * 0.22, cy - h * 0.2),
        w * 0.12, earPaint, true);

    // Wangen (Bluss)
    final cheekPaint = Paint()
      ..color = const Color(0xFFFFB5B5)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - w * 0.18, cy + h * 0.1),
        w * 0.06, cheekPaint);
    canvas.drawCircle(Offset(cx + w * 0.18, cy + h * 0.1),
        w * 0.06, cheekPaint);

    // Schnauze (weiss)
    final snoutPaint = Paint()..color = Colors.white;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + h * 0.15),
          width: w * 0.32, height: h * 0.22),
      snoutPaint,
    );

    // Augen
    _drawEyes(canvas, w, h, cx, cy);

    // Nase
    final nosePaint = Paint()..color = const Color(0xFF1F2937);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + h * 0.08),
          width: w * 0.07, height: h * 0.05),
      nosePaint,
    );

    // Mund (animiert beim Sprechen)
    _drawMouth(canvas, w, h, cx, cy);

    // Mood-Accessoires
    _drawMoodAccents(canvas, w, h, cx, cy);
  }

  void _drawEar(Canvas canvas, Offset center, double size, Paint paint,
      bool flip) {
    final path = Path();
    final mult = flip ? 1.0 : -1.0;
    path.moveTo(center.dx, center.dy + size);
    path.lineTo(center.dx + mult * size * 0.7, center.dy - size * 0.5);
    path.lineTo(center.dx + mult * size * 1.2, center.dy + size * 0.5);
    path.close();
    canvas.drawPath(path, paint);
    // Inner pink
    final inner = Paint()..color = const Color(0xFFFFD1DC);
    final ip = Path();
    ip.moveTo(center.dx + mult * size * 0.15, center.dy + size * 0.5);
    ip.lineTo(center.dx + mult * size * 0.55, center.dy - size * 0.2);
    ip.lineTo(center.dx + mult * size * 0.85, center.dy + size * 0.35);
    ip.close();
    canvas.drawPath(ip, inner);
  }

  void _drawEyes(Canvas canvas, double w, double h, double cx, double cy) {
    final eyeY = cy - h * 0.08;
    final eyeOffsetX = w * 0.13;
    final eyeRadius = w * 0.07;

    // Eye whites
    final whitePaint = Paint()..color = Colors.white;
    // Sleepy/Sad: nur Halbkreise
    if (mood == LumoMirrorMood.sleepy) {
      _drawClosedEye(canvas, Offset(cx - eyeOffsetX, eyeY), eyeRadius);
      _drawClosedEye(canvas, Offset(cx + eyeOffsetX, eyeY), eyeRadius);
      return;
    }
    if (mood == LumoMirrorMood.happy) {
      _drawSmileyEye(canvas, Offset(cx - eyeOffsetX, eyeY), eyeRadius);
      _drawSmileyEye(canvas, Offset(cx + eyeOffsetX, eyeY), eyeRadius);
      return;
    }

    canvas.drawCircle(Offset(cx - eyeOffsetX, eyeY), eyeRadius, whitePaint);
    canvas.drawCircle(Offset(cx + eyeOffsetX, eyeY), eyeRadius, whitePaint);

    // Pupils - folgen lookAt wenn vorhanden
    Offset pupilOffset = Offset.zero;
    if (lookAt != null) {
      // Begrenzt im Eye-Bereich
      final dx = lookAt!.dx.clamp(-1.0, 1.0) * eyeRadius * 0.4;
      final dy = lookAt!.dy.clamp(-1.0, 1.0) * eyeRadius * 0.4;
      pupilOffset = Offset(dx, dy);
    } else if (mood == LumoMirrorMood.think) {
      pupilOffset = Offset(eyeRadius * 0.3, -eyeRadius * 0.3);
    } else if (mood == LumoMirrorMood.curious) {
      pupilOffset = Offset(0, -eyeRadius * 0.1);
    }

    final pupilPaint = Paint()..color = const Color(0xFF1F2937);
    final pupilSize = mood == LumoMirrorMood.curious
        ? eyeRadius * 0.7
        : eyeRadius * 0.55;
    canvas.drawCircle(
        Offset(cx - eyeOffsetX, eyeY) + pupilOffset,
        pupilSize, pupilPaint);
    canvas.drawCircle(
        Offset(cx + eyeOffsetX, eyeY) + pupilOffset,
        pupilSize, pupilPaint);

    // Eye-Glanz
    final shinePaint = Paint()..color = Colors.white;
    canvas.drawCircle(
        Offset(cx - eyeOffsetX, eyeY) + pupilOffset
            + Offset(-pupilSize * 0.3, -pupilSize * 0.3),
        pupilSize * 0.25, shinePaint);
    canvas.drawCircle(
        Offset(cx + eyeOffsetX, eyeY) + pupilOffset
            + Offset(-pupilSize * 0.3, -pupilSize * 0.3),
        pupilSize * 0.25, shinePaint);

    // Sad-Mood: Tropfen unter dem Auge
    if (mood == LumoMirrorMood.sad) {
      final tearPaint = Paint()..color = const Color(0xFF60A5FA);
      canvas.drawCircle(
          Offset(cx - eyeOffsetX - 2, eyeY + eyeRadius + 6),
          3, tearPaint);
    }
  }

  void _drawSmileyEye(Canvas canvas, Offset center, double r) {
    final paint = Paint()
      ..color = const Color(0xFF1F2937)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final path = Path();
    path.moveTo(center.dx - r, center.dy);
    path.quadraticBezierTo(center.dx, center.dy - r,
        center.dx + r, center.dy);
    canvas.drawPath(path, paint);
  }

  void _drawClosedEye(Canvas canvas, Offset center, double r) {
    final paint = Paint()
      ..color = const Color(0xFF1F2937)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(center.dx - r, center.dy),
        Offset(center.dx + r, center.dy),
        paint);
  }

  void _drawMouth(Canvas canvas, double w, double h, double cx, double cy) {
    final paint = Paint()
      ..color = const Color(0xFF1F2937)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final mouthY = cy + h * 0.18;
    final mouthWidth = w * 0.12;

    if (mouthOpen > 0.1) {
      // Sprechen: offener Mund
      final paint2 = Paint()..color = const Color(0xFF1F2937);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, mouthY),
            width: mouthWidth * 0.6,
            height: 4 + mouthOpen * 10),
        paint2,
      );
    } else if (mood == LumoMirrorMood.sad) {
      // Trauriger Mund (umgekehrtes Lachen)
      final path = Path();
      path.moveTo(cx - mouthWidth, mouthY + 6);
      path.quadraticBezierTo(cx, mouthY - 4,
          cx + mouthWidth, mouthY + 6);
      canvas.drawPath(path, paint);
    } else if (mood == LumoMirrorMood.proud ||
        mood == LumoMirrorMood.cheer ||
        mood == LumoMirrorMood.happy) {
      // Grosses Lachen
      final path = Path();
      path.moveTo(cx - mouthWidth * 1.2, mouthY - 2);
      path.quadraticBezierTo(cx, mouthY + 12,
          cx + mouthWidth * 1.2, mouthY - 2);
      canvas.drawPath(path, paint);
    } else {
      // Neutrales kleines Lachen
      final path = Path();
      path.moveTo(cx - mouthWidth * 0.7, mouthY);
      path.quadraticBezierTo(cx, mouthY + 5,
          cx + mouthWidth * 0.7, mouthY);
      canvas.drawPath(path, paint);
    }
  }

  void _drawMoodAccents(Canvas canvas, double w, double h, double cx, double cy) {
    switch (mood) {
      case LumoMirrorMood.cheer:
        // Sterne um den Kopf
        final pts = [
          Offset(cx - w * 0.4, cy - h * 0.35),
          Offset(cx + w * 0.4, cy - h * 0.35),
          Offset(cx - w * 0.45, cy + h * 0.05),
          Offset(cx + w * 0.45, cy + h * 0.05),
        ];
        for (final p in pts) {
          _drawStar(canvas, p, 8,
              Paint()..color = const Color(0xFFFCD34D));
        }
        break;
      case LumoMirrorMood.think:
        // Fragezeichen oben rechts
        final tp = TextPainter(
          text: TextSpan(text: '?', style: TextStyle(
              fontSize: w * 0.2,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF7C3AED))),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(cx + w * 0.3, cy - h * 0.4));
        break;
      case LumoMirrorMood.proud:
        // Stern auf der Stirn
        _drawStar(canvas, Offset(cx, cy - h * 0.25), 6,
            Paint()..color = const Color(0xFFFCD34D));
        break;
      case LumoMirrorMood.sleepy:
        // Z-Z-Z
        final tp = TextPainter(
          text: TextSpan(text: 'Z', style: TextStyle(
              fontSize: w * 0.1,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF60A5FA))),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(cx + w * 0.35, cy - h * 0.35));
        break;
      default:
        break;
    }
  }

  void _drawStar(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final rr = (i % 2 == 0) ? r : r * 0.4;
      final x = c.dx + rr * math.cos(angle);
      final y = c.dy + rr * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_MirrorPainter old) =>
      old.mood != mood ||
      old.lookAt != lookAt ||
      old.mouthOpen != mouthOpen ||
      old.moodProgress != moodProgress;
}
