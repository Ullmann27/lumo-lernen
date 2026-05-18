import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animations-Zustand des Lumo-Fuchses.
/// Wird aus dem Spieler-State abgeleitet und steuert die Darstellung.
enum FoxAnimationState {
  /// Steht still – sanfter Atemrhythmus, Augenblinzeln, Schwanzwedeln.
  idle,

  /// Läuft nach links/rechts – alternierende Beinbewegung, Körperneigung.
  run,

  /// Springt nach oben (vy < 0) – Beine angezogen, Ohren zurück.
  jump,

  /// Fällt nach unten (vy > 0) – Augen groß, Ohren flach, Beine gestreckt.
  fall,

  /// Duckt sich – gestauchter Körper, Ohren flach.
  duck,

  /// Rollt/Dash – lila Kugel mit rotierenden Goldpunkten.
  roll,
}

/// Zeichnet den animierten Lumo-Fuchs prozedural auf einen Canvas.
///
/// Keine externen Assets nötig – vollständig vektorbasiert.
/// Wird vom [_LumoJumpPainter] aufgerufen.
class FoxSprite {
  const FoxSprite._();

  // ── Farb-Palette ───────────────────────────────────────────────
  static const Color _orange     = Color(0xFFF97316);
  static const Color _orangeDark = Color(0xFFC2410C);
  static const Color _cream      = Color(0xFFFEDBA4);
  static const Color _brown      = Color(0xFF422006);
  static const Color _dark       = Color(0xFF1F2937);
  static const Color _ink        = Color(0xFF0F172A);
  static const Color _cheek      = Color(0xFFFB7185);
  static const Color _rollPurple = Color(0xFF7C3AED);
  static const Color _gold       = Color(0xFFFCD34D);

  // ── Augenblinzeln-Timing ──────────────────────────────────────
  /// Abstand zwischen zwei Blinzel-Aktionen in Sekunden.
  static const double _blinkInterval = 3.5;
  /// Dauer des Augenschlusses in Sekunden.
  static const double _blinkDuration = 0.12;

  /// Malt den Fuchs auf [canvas] innerhalb von [rect].
  ///
  /// [state]        – aktueller Animations-Zustand (aus `_PlayerState`)
  /// [facingRight]  – true = Blickrichtung rechts
  /// [animTime]     – monoton wachsende Ticker-Zeit in Sekunden
  static void paint(
    Canvas canvas, {
    required Rect rect,
    required FoxAnimationState state,
    required bool facingRight,
    required double animTime,
  }) {
    switch (state) {
      case FoxAnimationState.roll:
        _paintRoll(canvas, rect: rect, animTime: animTime);
      case FoxAnimationState.duck:
        _paintDuck(canvas, rect: rect, facingRight: facingRight, animTime: animTime);
      default:
        _paintFull(canvas, rect: rect, state: state, facingRight: facingRight, animTime: animTime);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Roll – lila Dash-Kugel
  // ─────────────────────────────────────────────────────────────
  static void _paintRoll(Canvas canvas, {required Rect rect, required double animTime}) {
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final r  = math.min(rect.width, rect.height) * 0.48;

    // Schatten
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, rect.bottom + 4), width: r * 1.5, height: 5),
      Paint()..color = Colors.black.withOpacity(0.18),
    );
    // Äußerer Glow
    canvas.drawCircle(Offset(cx, cy), r + 3,
        Paint()..color = _rollPurple.withOpacity(0.28));
    // Körper
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = _rollPurple);
    // Rotierende Goldpunkte (Bewegungsindikator)
    final t = animTime * 14.0;
    for (var i = 0; i < 3; i++) {
      final a = t + i * (math.pi * 2 / 3);
      canvas.drawCircle(
        Offset(cx + math.cos(a) * r * 0.55, cy + math.sin(a) * r * 0.55),
        r * 0.18,
        Paint()..color = _gold,
      );
    }
    // Highlight
    canvas.drawCircle(Offset(cx - r * 0.35, cy - r * 0.3), r * 0.22,
        Paint()..color = Colors.white.withOpacity(0.55));
  }

  // ─────────────────────────────────────────────────────────────
  // Duck – gestauchter Fuchs
  // ─────────────────────────────────────────────────────────────
  static void _paintDuck(Canvas canvas, {
    required Rect rect,
    required bool facingRight,
    required double animTime,
  }) {
    final dir = facingRight ? 1.0 : -1.0;
    final cx  = rect.center.dx;
    final cy  = rect.bottom - rect.height * 0.4;
    final w   = rect.width;
    final h   = rect.height;

    // Schatten
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, rect.bottom + 3), width: w * 0.75, height: 5),
      Paint()..color = Colors.black.withOpacity(0.18),
    );
    // Schwanz (flach)
    _paintTail(canvas, cx: cx, cy: cy + h * 0.1, dir: dir, scale: 0.75,
        animTime: animTime, bodyColor: _orange, streamBack: false);
    // Gestauchter Körper
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + h * 0.15), width: w * 0.85, height: h * 0.44),
      Paint()..color = _orange,
    );
    // Bauch
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 3 * dir, cy + h * 0.2), width: w * 0.5, height: h * 0.27),
      Paint()..color = _cream,
    );
    // Kopf (niedriger, leicht nach vorne geneigt)
    final headCx = cx + 8 * dir;
    final headCy = cy - h * 0.02;
    final headR  = w * 0.36;
    _paintHead(canvas,
        cx: headCx, cy: headCy, headR: headR, dir: dir,
        state: FoxAnimationState.duck, animTime: animTime);
    // Kurze Beine
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx - 7, rect.bottom - 5), width: 10, height: 8),
          const Radius.circular(3)),
      Paint()..color = _orangeDark,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx + 7, rect.bottom - 5), width: 10, height: 8),
          const Radius.circular(3)),
      Paint()..color = _orangeDark,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Voller Fuchs – idle / run / jump / fall
  // ─────────────────────────────────────────────────────────────
  static void _paintFull(Canvas canvas, {
    required Rect rect,
    required FoxAnimationState state,
    required bool facingRight,
    required double animTime,
  }) {
    final dir = facingRight ? 1.0 : -1.0;
    final cx  = rect.center.dx;
    final cy  = rect.center.dy;
    final w   = rect.width;
    final h   = rect.height;

    // Idle-Bob: sanftes Auf/Ab
    final bob = (state == FoxAnimationState.idle)
        ? math.sin(animTime * 2.2) * 2.0
        : 0.0;

    // Schatten (kleiner wenn in der Luft)
    final shadowAlpha = (state == FoxAnimationState.jump || state == FoxAnimationState.fall)
        ? 0.08 : 0.20;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, rect.bottom + 4 + bob), width: w * 0.7, height: 5),
      Paint()..color = Colors.black.withOpacity(shadowAlpha),
    );

    final bodyCy = cy + h * 0.12 + bob;

    // Schwanz (hinter dem Körper)
    _paintTail(canvas,
        cx: cx, cy: bodyCy + h * 0.05, dir: dir, scale: 1.0,
        animTime: animTime, bodyColor: _orange,
        streamBack: state == FoxAnimationState.run || state == FoxAnimationState.jump);

    // Körper-Oval
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, bodyCy), width: w * 0.70, height: h * 0.57),
      Paint()..color = _orange,
    );
    // Bauchpartie
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 4 * dir, bodyCy + h * 0.10), width: w * 0.42, height: h * 0.35),
      Paint()..color = _cream,
    );

    // Kopf-Y variiert je Zustand
    final headOffsetY = switch (state) {
      FoxAnimationState.jump => -4.0,
      FoxAnimationState.fall => 3.0,
      _                      => 0.0,
    };
    final headCx = cx + 6 * dir;
    final headCy = cy - h * 0.22 + bob + headOffsetY;
    final headR  = w * 0.42;

    _paintHead(canvas,
        cx: headCx, cy: headCy, headR: headR, dir: dir,
        state: state, animTime: animTime);

    _paintLegs(canvas, rect: rect, cx: cx, state: state, animTime: animTime);
  }

  // ─────────────────────────────────────────────────────────────
  // Schwanz
  // ─────────────────────────────────────────────────────────────
  static void _paintTail(Canvas canvas, {
    required double cx, required double cy,
    required double dir, required double scale,
    required double animTime, required Color bodyColor,
    bool streamBack = false,
  }) {
    final wagSpeed = streamBack ? 6.0 : 8.0;
    final wagAmp   = streamBack ? 0.06 : 0.18;
    final wag      = math.sin(animTime * wagSpeed) * wagAmp * dir;
    final stretch  = streamBack ? 1.30 : 1.0;

    canvas.save();
    canvas.translate(cx - 16 * dir * scale, cy);
    canvas.rotate(wag);

    final tailPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-14 * dir * scale * stretch, -10 * scale,
                          -26 * dir * scale * stretch, -6 * scale)
      ..quadraticBezierTo(-32 * dir * scale * stretch, 4 * scale,
                          -28 * dir * scale * stretch, 12 * scale)
      ..quadraticBezierTo(-22 * dir * scale * stretch, 18 * scale,
                          -12 * dir * scale, 16 * scale)
      ..quadraticBezierTo(-4 * dir * scale, 12 * scale, 0, 6 * scale)
      ..close();
    canvas.drawPath(tailPath, Paint()..color = bodyColor);

    // Dunkles Innen
    final inner = Path()
      ..moveTo(-4 * dir * scale, 2 * scale)
      ..quadraticBezierTo(-12 * dir * scale * stretch, -4 * scale,
                          -18 * dir * scale * stretch, 0)
      ..quadraticBezierTo(-22 * dir * scale * stretch, 8 * scale,
                          -18 * dir * scale * stretch, 12 * scale)
      ..quadraticBezierTo(-10 * dir * scale, 12 * scale, -4 * dir * scale, 8 * scale)
      ..close();
    canvas.drawPath(inner, Paint()..color = _orangeDark.withOpacity(0.4));

    // Weiße Schwanzspitze
    canvas.drawCircle(Offset(-26 * dir * scale * stretch, 4 * scale), 8 * scale,
        Paint()..color = Colors.white);
    canvas.drawCircle(Offset(-28 * dir * scale * stretch, 2 * scale), 5 * scale,
        Paint()..color = _cream);

    canvas.restore();
  }

  // ─────────────────────────────────────────────────────────────
  // Kopf (inkl. Ohren, Augen, Nase, Mund)
  // ─────────────────────────────────────────────────────────────
  static void _paintHead(Canvas canvas, {
    required double cx, required double cy,
    required double headR, required double dir,
    required FoxAnimationState state, required double animTime,
  }) {
    // Kopf-Kreis
    canvas.drawCircle(Offset(cx, cy), headR, Paint()..color = _orange);

    // Schnauze
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 6 * dir, cy + 8),
          width: headR * 1.05, height: headR * 0.80),
      Paint()..color = _cream,
    );

    // Wangen-Rouge (Pausbacken)
    final cheekPaint = Paint()..color = _cheek.withOpacity(0.5);
    canvas.drawCircle(Offset(cx - 8 * dir, cy + 6), 4, cheekPaint);
    canvas.drawCircle(Offset(cx + 14 * dir, cy + 6), 4, cheekPaint);

    _paintEars(canvas, cx: cx, cy: cy, headR: headR, dir: dir, state: state);
    _paintEyes(canvas, cx: cx, cy: cy, headR: headR, dir: dir, state: state, animTime: animTime);
    _paintNoseMouth(canvas, cx: cx, cy: cy, dir: dir, state: state);
  }

  // ─────────────────────────────────────────────────────────────
  // Ohren
  // ─────────────────────────────────────────────────────────────
  static void _paintEars(Canvas canvas, {
    required double cx, required double cy,
    required double headR, required double dir,
    required FoxAnimationState state,
  }) {
    final flatEars = state == FoxAnimationState.duck || state == FoxAnimationState.fall;

    // Vorderes Ohr
    canvas.save();
    canvas.translate(cx, cy);
    if (flatEars) canvas.rotate(-0.28 * dir);
    final earFront = Path()
      ..moveTo(-16 * dir, -headR * 0.55)
      ..quadraticBezierTo(-6 * dir, -headR * (flatEars ? 0.95 : 1.15),
                          4 * dir, -headR * 0.45)
      ..close();
    canvas.drawPath(earFront, Paint()..color = _orange);
    // Innen-Ohr (Pink)
    final earFrontInner = Path()
      ..moveTo(-10 * dir, -headR * 0.55)
      ..quadraticBezierTo(-4 * dir, -headR * (flatEars ? 0.82 : 0.95),
                          2 * dir, -headR * 0.50)
      ..close();
    canvas.drawPath(earFrontInner, Paint()..color = _cheek);
    canvas.restore();

    // Hinteres Ohr
    canvas.save();
    canvas.translate(cx, cy);
    if (flatEars) canvas.rotate(0.20 * dir);
    final earBack = Path()
      ..moveTo(10 * dir, -headR * 0.45)
      ..quadraticBezierTo(20 * dir, -headR * (flatEars ? 0.85 : 1.0),
                          26 * dir, -headR * 0.25)
      ..close();
    canvas.drawPath(earBack, Paint()..color = _orange);
    canvas.restore();
  }

  // ─────────────────────────────────────────────────────────────
  // Augen
  // ─────────────────────────────────────────────────────────────
  static void _paintEyes(Canvas canvas, {
    required double cx, required double cy,
    required double headR, required double dir,
    required FoxAnimationState state, required double animTime,
  }) {
    final eyeY  = cy + 2;
    final eyeLx = cx - 7 * dir;
    final eyeRx = cx + 8 * dir;
    // Fallen → überraschte große Augen
    final es = 7.5 * (state == FoxAnimationState.fall ? 1.25 : 1.0);

    // Augenweiß
    canvas.drawCircle(Offset(eyeLx, eyeY), es, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(eyeRx, eyeY), es, Paint()..color = Colors.white);
    // Iris
    canvas.drawCircle(Offset(eyeLx + 1.5 * dir, eyeY + 0.5), es * 0.70, Paint()..color = _brown);
    canvas.drawCircle(Offset(eyeRx + 1.5 * dir, eyeY + 0.5), es * 0.70, Paint()..color = _brown);
    // Pupille
    canvas.drawCircle(Offset(eyeLx + 2 * dir, eyeY + 1), es * 0.45, Paint()..color = _ink);
    canvas.drawCircle(Offset(eyeRx + 2 * dir, eyeY + 1), es * 0.45, Paint()..color = _ink);
    // Haupthighlight
    canvas.drawCircle(Offset(eyeLx + 1 * dir, eyeY - 2), 2.4, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(eyeRx + 1 * dir, eyeY - 2), 2.4, Paint()..color = Colors.white);
    // Kleiner zweiter Highlight
    canvas.drawCircle(Offset(eyeLx + 3 * dir, eyeY + 2), 1.0,
        Paint()..color = Colors.white.withOpacity(0.8));
    canvas.drawCircle(Offset(eyeRx + 3 * dir, eyeY + 2), 1.0,
        Paint()..color = Colors.white.withOpacity(0.8));

    // Blinzeln – alle ~3,5 s kurz im Idle-Zustand
    if (state == FoxAnimationState.idle && animTime % _blinkInterval < _blinkDuration) {
      final blinkPaint = Paint()..color = _orange;
      canvas.drawOval(
          Rect.fromCenter(center: Offset(eyeLx, eyeY), width: es * 2.1, height: es * 0.38),
          blinkPaint);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(eyeRx, eyeY), width: es * 2.1, height: es * 0.38),
          blinkPaint);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Nase + Mund
  // ─────────────────────────────────────────────────────────────
  static void _paintNoseMouth(Canvas canvas, {
    required double cx, required double cy,
    required double dir,
    required FoxAnimationState state,
  }) {
    final noseX = cx + 10 * dir;
    final noseY = cy + 10;

    // Nase
    canvas.drawCircle(Offset(noseX, noseY + 0.5), 3,
        Paint()..color = Colors.black.withOpacity(0.15));
    canvas.drawCircle(Offset(noseX, noseY), 3, Paint()..color = _dark);
    canvas.drawCircle(Offset(noseX - 1, noseY - 1), 0.9, Paint()..color = Colors.white);

    // Mund: lächelnd bei idle/run/jump, neutral/überrascht bei fall/duck
    final happy = state == FoxAnimationState.idle ||
        state == FoxAnimationState.run ||
        state == FoxAnimationState.jump;
    final mouthPath = Path()
      ..moveTo(noseX - 4, noseY + 3);
    if (happy) {
      mouthPath.quadraticBezierTo(noseX, noseY + 7, noseX + 4, noseY + 3);
    } else {
      mouthPath.quadraticBezierTo(noseX, noseY + 4, noseX + 4, noseY + 3);
    }
    canvas.drawPath(
      mouthPath,
      Paint()
        ..color = _dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Beine / Pfoten
  // ─────────────────────────────────────────────────────────────
  static void _paintLegs(Canvas canvas, {
    required Rect rect,
    required double cx,
    required FoxAnimationState state,
    required double animTime,
  }) {
    final legY    = rect.bottom - 6;
    final legSwing = math.sin(animTime * 14.0) * 5.0;
    final idleBob  = math.sin(animTime * 2.2) * 1.0;

    switch (state) {
      case FoxAnimationState.run:
        // Alternierende Beine
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx - 8, legY + legSwing), width: 10, height: 14),
              const Radius.circular(4)),
          Paint()..color = _orangeDark,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx + 8, legY - legSwing), width: 10, height: 14),
              const Radius.circular(4)),
          Paint()..color = _orangeDark,
        );

      case FoxAnimationState.jump:
        // Beine angezogen
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx - 9, legY - 6), width: 10, height: 10),
              const Radius.circular(4)),
          Paint()..color = _orangeDark,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx + 9, legY - 6), width: 10, height: 10),
              const Radius.circular(4)),
          Paint()..color = _orangeDark,
        );

      case FoxAnimationState.fall:
        // Beine ausgestreckt (Fallhaltung)
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx - 10, legY + 4), width: 10, height: 16),
              const Radius.circular(4)),
          Paint()..color = _orangeDark,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx + 10, legY + 4), width: 10, height: 16),
              const Radius.circular(4)),
          Paint()..color = _orangeDark,
        );

      default:
        // Idle – sanfter Bob
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx - 8, legY + idleBob), width: 10, height: 12),
              const Radius.circular(4)),
          Paint()..color = _orangeDark,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx + 8, legY + idleBob), width: 10, height: 12),
              const Radius.circular(4)),
          Paint()..color = _orangeDark,
        );
    }
  }
}
