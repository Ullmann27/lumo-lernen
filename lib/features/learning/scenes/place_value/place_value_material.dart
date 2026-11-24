import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../theme/lumo_visual_tokens.dart';
import '../learning_scene_motion.dart';

/// Farben eines Stellenwert-Materials: Zehner kühl wie Glas, Einer warm.
class PlaceValueTone {
  static PlaceValueTone lerp(PlaceValueTone a, PlaceValueTone b, double t) =>
      PlaceValueTone(
        frontLight: Color.lerp(a.frontLight, b.frontLight, t)!,
        frontDeep: Color.lerp(a.frontDeep, b.frontDeep, t)!,
        top: Color.lerp(a.top, b.top, t)!,
        side: Color.lerp(a.side, b.side, t)!,
        glow: Color.lerp(a.glow, b.glow, t)!,
      );

  const PlaceValueTone({
    required this.frontLight,
    required this.frontDeep,
    required this.top,
    required this.side,
    required this.glow,
  });

  final Color frontLight;
  final Color frontDeep;
  final Color top;
  final Color side;
  final Color glow;

  static const tens = PlaceValueTone(
    frontLight: Color(0xFF55D3F7),
    frontDeep: Color(0xFF1781BD),
    top: Color(0xFFC4F4FF),
    side: Color(0xFF0E5F92),
    glow: LumoVisualTokens.cyanBright,
  );

  static const ones = PlaceValueTone(
    frontLight: Color(0xFFFFC266),
    frontDeep: Color(0xFFEB841D),
    top: Color(0xFFFFE6B3),
    side: Color(0xFFB85C0E),
    glow: LumoVisualTokens.gold,
  );
}

/// Glänzende Würfel in Kabinettprojektion. Eine Säule aus [count] Würfeln;
/// bei der Zehnerstange bleiben alle zehn Würfel einzeln sichtbar.
class PlaceValueCubePainter extends CustomPainter {
  const PlaceValueCubePainter({
    required this.count,
    required this.tone,
    this.glow = 0,
    this.opacity = 1,
    this.shadow = true,
  });

  final int count;
  final PlaceValueTone tone;

  /// 0..1: Leuchten für gezählt, ausgewählt oder Lumos Fokus.
  final double glow;
  final double opacity;
  final bool shadow;

  static const double depth = .34;

  /// Kantenlänge eines Würfels, damit die Säule in [size] passt.
  static double cubeFor(Size size, int count) =>
      math.min(size.width / (1 + depth), size.height / (count + depth + .12));

  /// Malfläche für einen Einzelwürfel an Platz [index] (0 = oben) einer
  /// Säule aus [count] Würfeln in [size]. Für Verwandlungen auf der Bühne.
  static Rect slot(Size size, int count, int index) {
    final s = cubeFor(size, count);
    final d = s * depth;
    final x = (size.width - (s + d)) / 2;
    final top = size.height - (s * count + d) - s * .1 + d;
    return Rect.fromLTWH(x, top + s * index - d, s + d, s + d + s * .12);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0 || size.isEmpty) return;
    final s = cubeFor(size, count);
    final d = s * depth;
    final width = s + d, height = s * count + d;
    final origin =
        Offset((size.width - width) / 2, size.height - height - s * .1);
    final x = origin.dx, top = origin.dy + d;
    final bottom = top + s * count;
    Color fade(Color c) => c.withValues(alpha: c.a * opacity);

    if (shadow) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x + width * .48, bottom + s * .06),
              width: width * 1.25,
              height: s * .32),
          Paint()
            ..color = fade(const Color(0x7A000A1E))
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * .12));
    }
    if (glow > 0) {
      // Weicher Lichthof plus klare Kante: markiert, ohne zu verschmieren.
      final ring = RRect.fromRectAndRadius(
          Rect.fromLTRB(x - s * .2, origin.dy - s * .2, x + width + s * .2,
              bottom + s * .2),
          Radius.circular(s * .38));
      canvas.drawRRect(
          ring,
          Paint()
            ..color = tone.glow.withValues(alpha: .26 * glow * opacity)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * .55));
      canvas.drawRRect(
          ring,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1.3, s * .09)
            ..color = tone.glow.withValues(alpha: .9 * glow * opacity));
    }
    // Seitenfläche (rechts) über die ganze Säule.
    final sidePath = Path()
      ..moveTo(x + s, top)
      ..lineTo(x + s + d, top - d)
      ..lineTo(x + s + d, bottom - d)
      ..lineTo(x + s, bottom)
      ..close();
    canvas.drawPath(
        sidePath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              fade(tone.side),
              fade(Color.lerp(tone.side, Colors.black, .35)!)
            ],
          ).createShader(Rect.fromLTRB(x + s, top - d, x + s + d, bottom)));
    // Deckfläche.
    final topPath = Path()
      ..moveTo(x, top)
      ..lineTo(x + d, top - d)
      ..lineTo(x + s + d, top - d)
      ..lineTo(x + s, top)
      ..close();
    canvas.drawPath(
        topPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [
              fade(tone.top),
              fade(Color.lerp(tone.top, Colors.white, .5)!)
            ],
          ).createShader(Rect.fromLTRB(x, top - d, x + s + d, top)));
    // Vorderflächen, jede einzeln mit Fuge.
    for (var i = 0; i < count; i++) {
      final rect = Rect.fromLTWH(x, top + s * i, s, s);
      canvas.drawRect(
          rect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [fade(tone.frontLight), fade(tone.frontDeep)],
            ).createShader(rect));
      // Weiche Glanzkante oben links in jedem Würfel.
      canvas.drawPath(
          Path()
            ..moveTo(rect.left + s * .08, rect.bottom - s * .14)
            ..lineTo(rect.left + s * .08, rect.top + s * .08)
            ..lineTo(rect.right - s * .14, rect.top + s * .08),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1, s * .07)
            ..strokeCap = StrokeCap.round
            ..color = Colors.white.withValues(alpha: .42 * opacity));
      if (i > 0) {
        canvas.drawLine(
            Offset(rect.left, rect.top),
            Offset(rect.right, rect.top),
            Paint()
              ..strokeWidth = math.max(1, s * .06)
              ..color = fade(Color.lerp(tone.side, Colors.black, .45)!));
        canvas.drawLine(
            Offset(rect.right, rect.top),
            Offset(rect.right + d, rect.top - d),
            Paint()
              ..strokeWidth = math.max(1, s * .05)
              ..color = fade(Color.lerp(tone.side, Colors.black, .55)!));
      }
    }
    // Feine helle Außenkante wie bei Glas.
    canvas.drawPath(
        Path()
          ..moveTo(x, bottom)
          ..lineTo(x, top)
          ..lineTo(x + d, top - d)
          ..lineTo(x + s + d, top - d)
          ..lineTo(x + s + d, bottom - d)
          ..lineTo(x + s, bottom)
          ..close(),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.8, s * .045)
          ..color = Colors.white.withValues(alpha: .34 * opacity));
  }

  @override
  bool shouldRepaint(covariant PlaceValueCubePainter old) =>
      old.count != count ||
      old.tone != tone ||
      old.glow != glow ||
      old.opacity != opacity ||
      old.shadow != shadow;
}

/// Eine Zehnerstange als eigenes, antippbares Objekt (mindestens 48 dp).
class PlaceValueRod extends StatelessWidget {
  const PlaceValueRod({
    super.key,
    required this.cube,
    required this.label,
    this.buttonKey,
    this.counted = false,
    this.badge,
    this.focus = false,
    this.hidden = false,
    this.tone = PlaceValueTone.tens,
    this.onTap,
  });

  final double cube;
  final String label;
  final Key? buttonKey;
  final bool counted;

  /// Laufende Zehnerzahl über der Stange (10, 20, 30 …).
  final String? badge;
  final bool focus;

  /// Während einer Verwandlung zeichnet die Bühne die Würfel selbst.
  final bool hidden;
  final PlaceValueTone tone;
  final VoidCallback? onTap;

  static Size sizeFor(double cube) => Size(
      math.max(48, cube * (1 + PlaceValueCubePainter.depth) + 12),
      math.max(64, cube * (10 + PlaceValueCubePainter.depth + .12) + 34));

  @override
  Widget build(BuildContext context) {
    final size = sizeFor(cube);
    final calm = LearningSceneMotion.reduced(context);
    final lift = counted ? -cube * .45 : 0.0;
    return Semantics(
      label: label,
      selected: counted,
      button: onTap != null,
      excludeSemantics: true,
      onTap: onTap,
      child: SizedBox.fromSize(
        size: size,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: buttonKey,
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            splashColor: tone.glow.withValues(alpha: .18),
            highlightColor: tone.glow.withValues(alpha: .08),
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(
                top: 22,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: lift),
                  duration:
                      calm ? Duration.zero : LearningSceneMotion.interaction,
                  curve: LearningSceneMotion.pop,
                  builder: (context, dy, child) =>
                      Transform.translate(offset: Offset(0, dy), child: child),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: counted || focus ? 1 : 0),
                    duration:
                        calm ? Duration.zero : LearningSceneMotion.interaction,
                    builder: (context, glow, _) => CustomPaint(
                      painter: PlaceValueCubePainter(
                          count: 10,
                          tone: tone,
                          glow: glow,
                          opacity: hidden ? 0 : 1),
                    ),
                  ),
                ),
              ),
              if (badge != null && !hidden)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(child: PlaceValueBadge(text: badge!)),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Ein Einerwürfel. Antippbar nur, wenn [onTap] gesetzt ist.
class PlaceValueCube extends StatelessWidget {
  const PlaceValueCube({
    super.key,
    required this.cube,
    required this.label,
    this.buttonKey,
    this.selected = false,
    this.badge,
    this.hidden = false,
    this.tone = PlaceValueTone.ones,
    this.onTap,
  });

  final double cube;
  final String label;
  final Key? buttonKey;
  final bool selected;
  final String? badge;
  final bool hidden;
  final PlaceValueTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final calm = LearningSceneMotion.reduced(context);
    final box = math.max(onTap == null ? cube * 1.5 : 48.0, cube * 1.6);
    final painted = TweenAnimationBuilder<double>(
      tween: Tween(end: selected ? 1 : 0),
      duration: calm ? Duration.zero : LearningSceneMotion.interaction,
      builder: (context, glow, _) => CustomPaint(
        painter: PlaceValueCubePainter(
            count: 1, tone: tone, glow: glow, opacity: hidden ? 0 : 1),
      ),
    );
    final body = SizedBox.square(
      dimension: box,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(
            child: Padding(
          padding: EdgeInsets.all((box - cube * 1.45) / 2),
          child: painted,
        )),
        if (badge != null && !hidden)
          Positioned(
              right: -2,
              top: -2,
              child: PlaceValueBadge(text: badge!, small: true)),
      ]),
    );
    if (onTap == null) {
      return Semantics(
          label: label,
          excludeSemantics: true,
          child: KeyedSubtree(key: buttonKey, child: body));
    }
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: buttonKey,
          onTap: onTap,
          customBorder: const CircleBorder(),
          splashColor: tone.glow.withValues(alpha: .2),
          child: body,
        ),
      ),
    );
  }
}

/// Kleines leuchtendes Zahlenschild (Zählhilfe, keine Wertung).
class PlaceValueBadge extends StatelessWidget {
  const PlaceValueBadge({super.key, required this.text, this.small = false});
  final String text;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final calm = LearningSceneMotion.reduced(context);
    return TweenAnimationBuilder<double>(
      key: ValueKey(text),
      tween: Tween(begin: calm ? 1 : .4, end: 1),
      duration: calm ? Duration.zero : LearningSceneMotion.feedback,
      curve: LearningSceneMotion.pop,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: small ? 5 : 7, vertical: small ? 1 : 2),
        decoration: BoxDecoration(
          color: const Color(0xFF0B2E5C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: LumoVisualTokens.cyanBright, width: 1.2),
          boxShadow: const [
            BoxShadow(color: Color(0x6653DDFD), blurRadius: 8),
          ],
        ),
        child: Text(text,
            textScaler: TextScaler.noScaling,
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: small ? 11 : 13,
                fontWeight: FontWeight.w900,
                color: LumoVisualTokens.white)),
      ),
    );
  }
}
