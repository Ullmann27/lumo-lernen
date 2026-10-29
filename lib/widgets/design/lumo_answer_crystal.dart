import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/lumo_visual_tokens.dart';
import 'lumo_motion.dart';

/// Presentation state supplied AFTER the owning lesson evaluates an answer.
/// This component deliberately never receives the correct solution.
enum LumoCrystalState { neutral, correct, retry }

class LumoCrystalAnswerGrid extends StatelessWidget {
  const LumoCrystalAnswerGrid({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        return GridView.count(
          crossAxisCount: scale > 1.6 ? 1 : 2,
          mainAxisExtent: 108 * scale.clamp(1.0, 1.6),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: children,
        );
      });
}

class LumoAnswerCrystal extends StatelessWidget {
  const LumoAnswerCrystal({
    super.key,
    required this.label,
    required this.onPressed,
    this.state = LumoCrystalState.neutral,
    this.buttonKey,
    this.fontSize = 32,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final LumoCrystalState state;
  final Key? buttonKey;
  final double fontSize;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final accent = switch (state) {
      LumoCrystalState.correct => LumoVisualTokens.gold,
      LumoCrystalState.retry => const Color(0xFFFFB977),
      LumoCrystalState.neutral => LumoVisualTokens.cyan,
    };
    return Semantics(
      label: semanticLabel,
      button: semanticLabel == null ? null : true,
      enabled: semanticLabel == null ? null : onPressed != null,
      excludeSemantics: semanticLabel != null,
      onTap: semanticLabel == null ? null : onPressed,
      value: switch (state) {
        LumoCrystalState.correct => 'Richtig',
        LumoCrystalState.retry => 'Noch nicht richtig',
        LumoCrystalState.neutral => null,
      },
      child: LumoPressable(
        enabled: onPressed != null,
        glowColor: accent,
        pressedScale: .97,
        child: LayoutBuilder(builder: (context, bounds) {
          final height = bounds.hasBoundedHeight
              ? bounds.maxHeight
              : 112.0 *
                  MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
          return SizedBox(
            height: height,
            child: TweenAnimationBuilder<double>(
              tween: Tween(
                  begin: 0, end: state == LumoCrystalState.correct ? 1 : 0),
              duration: LumoMotion.reduced(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 700),
              builder: (context, progress, child) => CustomPaint(
                painter: LumoCrystalPainter(
                    accent: accent, pedestal: true, celebration: progress),
                child: child,
              ),
              child: Stack(fit: StackFit.expand, children: [
                OutlinedButton(
                  key: buttonKey,
                  onPressed: onPressed,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: LumoVisualTokens.white,
                    disabledForegroundColor: LumoVisualTokens.white,
                    side: BorderSide.none,
                    minimumSize: const Size(48, 48),
                    padding: EdgeInsets.fromLTRB(bounds.maxWidth < 96 ? 5 : 14,
                        4, bounds.maxWidth < 96 ? 5 : 14, height * .22),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    textStyle: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: fontSize,
                        fontWeight: FontWeight.w900,
                        height: 1.1),
                  ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.focused)
                              ? accent.withValues(alpha: .28)
                              : states.contains(WidgetState.hovered)
                                  ? accent.withValues(alpha: .12)
                                  : null)),
                  child: Text(label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(shadows: [
                        Shadow(
                            color: Color(0xFF041D55),
                            blurRadius: 4,
                            offset: Offset(0, 2)),
                        Shadow(color: Color(0x9953DDFD), blurRadius: 9),
                      ])),
                ),
                if (state != LumoCrystalState.neutral)
                  Positioned(
                      right: 12,
                      top: 9,
                      child: IgnorePointer(
                          child: Icon(
                              state == LumoCrystalState.correct
                                  ? Icons.check_circle_rounded
                                  : Icons.refresh_rounded,
                              size: 18,
                              color: accent))),
              ]),
            ),
          );
        }),
      ),
    );
  }
}

/// Noninteractive sibling for the task itself. All text stays in Flutter.
class LumoCrystalPanel extends StatelessWidget {
  const LumoCrystalPanel({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: const LumoCrystalPainter(),
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: child),
      );
}

/// A faceted glass body, beveled rim and stone pedestal, painted once until
/// feedback changes. No shaders, texture duplication or ambient animation.
class LumoCrystalPainter extends CustomPainter {
  const LumoCrystalPainter({
    this.accent = LumoVisualTokens.cyan,
    this.pedestal = false,
    this.celebration = 0,
  });
  final Color accent;
  final bool pedestal;
  final double celebration;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height * (pedestal ? .79 : 1);
    Path polygon(List<Offset> points) => Path()..addPolygon(points, true);
    Offset p(double x, double y) => Offset(5 + x * (w - 10), 4 + y * (h - 10));
    final points = [
      p(.12, .05),
      p(.76, 0),
      p(.94, .16),
      p(1, .64),
      p(.86, .90),
      p(.18, 1),
      p(0, .74),
      p(.025, .26)
    ];
    final body = polygon(points);

    if (pedestal) {
      final base =
          Rect.fromLTRB(w * .06, size.height * .72, w * .94, size.height * .98);
      canvas.drawOval(base.shift(const Offset(0, 2)),
          Paint()..color = const Color(0x8800081C));
      canvas.drawRRect(
          RRect.fromRectAndRadius(base, const Radius.circular(10)),
          Paint()
            ..shader = const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF53758C), Color(0xFF162640)])
                .createShader(base));
      final seam = Paint()
        ..color = const Color(0xFF0C1C31)
        ..strokeWidth = 1.2;
      for (var i = 1; i <= 5; i++) {
        final x = base.left + base.width * i / 6;
        canvas.drawLine(Offset(x, base.top + 6),
            Offset(x + (i.isEven ? 3 : -3), base.bottom), seam);
      }
      final cap = Rect.fromCenter(
          center: Offset(w / 2, base.top + 4), width: base.width, height: 14);
      canvas.drawOval(cap, Paint()..color = const Color(0xFF355F7B));
      canvas.drawOval(
          cap.deflate(3),
          Paint()
            ..color = accent.withValues(alpha: .85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2);
    }

    canvas.drawShadow(body, const Color(0xCC000A25), 4, false);
    // A visible lower side gives the crystal thickness even without motion.
    canvas.drawPath(body.shift(const Offset(0, 6)),
        Paint()..color = const Color(0xFF041B4F));
    canvas.drawPath(
        body,
        Paint()
          ..color = accent.withValues(alpha: .48)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawPath(
        body,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(const Color(0xFF225EC4), accent, .45)!,
              const Color(0xFF163D9A),
              const Color(0xFF071D5B),
              Color.lerp(const Color(0xFF2363B8), accent, .44)!
            ],
            stops: const [0, .35, .72, 1],
          ).createShader(Rect.fromLTWH(0, 0, w, h)));

    // Edge facets surround a calm central reading surface.
    final inner = [
      p(.19, .20),
      p(.71, .15),
      p(.82, .29),
      p(.87, .62),
      p(.77, .76),
      p(.23, .84),
      p(.13, .65),
      p(.15, .32)
    ];
    for (var i = 0; i < points.length; i++) {
      final next = (i + 1) % points.length;
      final facet = polygon([points[i], points[next], inner[next], inner[i]]);
      const facetLight = [.52, .68, .40, .14, .32, .24, .52, .62];
      canvas.drawPath(
          facet,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(accent, Colors.white, .55)!
                    .withValues(alpha: facetLight[i]),
                accent.withValues(alpha: facetLight[i] * .30),
              ],
            ).createShader(Rect.fromLTWH(0, 0, w, h)));
      // Split the broad bevels into irregular refracting planes. Their bright
      // and dark triangles remain outside the central number's reading area.
      final ridge = Offset.lerp(points[i], inner[next], .52)!;
      canvas.drawPath(
          polygon([points[i], ridge, inner[i]]),
          Paint()
            ..color = (i.isEven ? Colors.white : const Color(0xFF020F3B))
                .withValues(alpha: i.isEven ? .18 : .34));
      canvas.drawLine(
          points[i],
          inner[i],
          Paint()
            ..color = const Color(0xB9C8F7FF)
            ..strokeWidth = .9);
    }
    canvas.drawPath(
        polygon(inner),
        Paint()
          ..color = accent.withValues(alpha: .48)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1);
    // Fine refracted crystal veins add visual depth to the real interactive
    // answer controls. Only decorative edges are painted: the central digit
    // stays unobstructed and the correct choice is never revealed beforehand.
    final fracture = Paint()
      ..color = Colors.white.withValues(alpha: .24)
      ..strokeWidth = .8
      ..style = PaintingStyle.stroke;
    final rainbow = Paint()
      ..color = accent.withValues(alpha: .4)
      ..strokeWidth = 1.05
      ..style = PaintingStyle.stroke;
    final leftVein = Path()
      ..moveTo(p(.05, .48).dx, p(.05, .48).dy)
      ..lineTo(p(.18, .33).dx, p(.18, .33).dy)
      ..lineTo(p(.13, .19).dx, p(.13, .19).dy)
      ..moveTo(p(.16, .73).dx, p(.16, .73).dy)
      ..lineTo(p(.24, .84).dx, p(.24, .84).dy);
    final topVein = Path()
      ..moveTo(p(.44, .05).dx, p(.44, .05).dy)
      ..lineTo(p(.54, .13).dx, p(.54, .13).dy)
      ..lineTo(p(.73, .12).dx, p(.73, .12).dy);
    final rightVein = Path()
      ..moveTo(p(.96, .49).dx, p(.96, .49).dy)
      ..lineTo(p(.83, .62).dx, p(.83, .62).dy)
      ..lineTo(p(.89, .78).dx, p(.89, .78).dy);
    canvas.drawPath(leftVein, fracture);
    canvas.drawPath(topVein, fracture);
    canvas.drawPath(rightVein, rainbow);
    canvas.drawCircle(
        p(.2, .14), 1.8, Paint()..color = Colors.white.withValues(alpha: .76));
    canvas.drawCircle(
        p(.79, .79), 1.5, Paint()..color = accent.withValues(alpha: .85));

    canvas.drawPath(
        body,
        Paint()
          ..color = Color.lerp(accent, Colors.white, .30)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8);
    canvas.drawLine(
        points[0],
        points[1],
        Paint()
          ..color = const Color(0xD7F7FBFF)
          ..strokeWidth = 1.4);

    for (final spot in [p(.12, .26), p(.84, .20), p(.84, .78)]) {
      final glint = Paint()
        ..color = accent.withValues(alpha: .85)
        ..strokeWidth = .9;
      canvas.drawLine(
          spot - const Offset(3, 0), spot + const Offset(3, 0), glint);
      canvas.drawLine(
          spot - const Offset(0, 3), spot + const Offset(0, 3), glint);
    }
    if (celebration > 0 && celebration < 1) {
      for (var i = 0; i < 6; i++) {
        final a = i * math.pi / 3;
        final center = Offset(w / 2 + math.cos(a) * w * .43 * celebration,
            h / 2 + math.sin(a) * h * .4 * celebration);
        canvas.drawCircle(
            center,
            2.5 * (1 - celebration),
            Paint()
              ..color = LumoVisualTokens.goldLight
                  .withValues(alpha: 1 - celebration));
      }
    }
  }

  @override
  bool shouldRepaint(LumoCrystalPainter oldDelegate) =>
      accent != oldDelegate.accent ||
      pedestal != oldDelegate.pedestal ||
      celebration != oldDelegate.celebration;
}
