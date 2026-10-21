import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/lumo_visual_tokens.dart';
import 'lumo_motion.dart';

/// Presentation state supplied AFTER the owning lesson evaluates an answer.
/// This component deliberately never receives the correct solution.
enum LumoCrystalState { neutral, correct, retry }

class LumoAnswerCrystal extends StatelessWidget {
  const LumoAnswerCrystal({
    super.key,
    required this.label,
    required this.onPressed,
    this.state = LumoCrystalState.neutral,
    this.buttonKey,
    this.fontSize = 32,
  });

  final String label;
  final VoidCallback? onPressed;
  final LumoCrystalState state;
  final Key? buttonKey;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final accent = switch (state) {
      LumoCrystalState.correct => LumoVisualTokens.gold,
      LumoCrystalState.retry => const Color(0xFFFFB977),
      LumoCrystalState.neutral => LumoVisualTokens.cyan,
    };
    return Semantics(
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
          final height = bounds.hasBoundedHeight ? bounds.maxHeight : 112.0;
          return SizedBox(
            height: height,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: state == LumoCrystalState.correct ? 1 : 0),
              duration: LumoMotion.reduced(context)
                  ? Duration.zero : const Duration(milliseconds: 700),
              builder: (context, progress, child) => CustomPaint(
                painter: LumoCrystalPainter(accent: accent, pedestal: true,
                    celebration: progress),
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
                    padding: EdgeInsets.fromLTRB(14, 4, 14, height * .22),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    textStyle: TextStyle(fontFamily: 'Nunito', fontSize: fontSize,
                        fontWeight: FontWeight.w900, height: 1.1),
                  ).copyWith(overlayColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.focused)
                      ? accent.withValues(alpha: .28)
                      : states.contains(WidgetState.hovered)
                          ? accent.withValues(alpha: .12) : null)),
                  child: Text(label, textAlign: TextAlign.center),
                ),
                if (state != LumoCrystalState.neutral)
                  Positioned(right: 12, top: 9, child: IgnorePointer(
                    child: Icon(state == LumoCrystalState.correct
                      ? Icons.check_circle_rounded : Icons.refresh_rounded,
                      size: 18, color: accent))),
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
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
    final points = [p(.12, .05), p(.76, 0), p(.94, .16), p(1, .64),
      p(.86, .90), p(.18, 1), p(0, .74), p(.025, .26)];
    final body = polygon(points);

    if (pedestal) {
      final base = Rect.fromLTRB(w * .06, size.height * .72, w * .94, size.height * .98);
      canvas.drawOval(base.shift(const Offset(0, 2)), Paint()..color = const Color(0x8800081C));
      canvas.drawRRect(RRect.fromRectAndRadius(base, const Radius.circular(10)),
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter,
          end: Alignment.bottomCenter, colors: [Color(0xFF53758C), Color(0xFF162640)])
          .createShader(base));
      final seam = Paint()..color = const Color(0xFF0C1C31)..strokeWidth = 1.2;
      for (var i = 1; i <= 5; i++) {
        final x = base.left + base.width * i / 6;
        canvas.drawLine(Offset(x, base.top + 6), Offset(x + (i.isEven ? 3 : -3), base.bottom), seam);
      }
      final cap = Rect.fromCenter(center: Offset(w / 2, base.top + 4), width: base.width, height: 14);
      canvas.drawOval(cap, Paint()..color = const Color(0xFF355F7B));
      canvas.drawOval(cap.deflate(3), Paint()..color = accent.withValues(alpha: .85)
        ..style = PaintingStyle.stroke..strokeWidth = 1.2);
    }

    canvas.drawShadow(body, const Color(0xCC000A25), 4, false);
    canvas.drawPath(body, Paint()..shader = LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color.lerp(const Color(0xFF12527A), accent, .22)!,
        const Color(0xFF112B75), const Color(0xFF092853),
        Color.lerp(const Color(0xFF144E82), accent, .22)!],
      stops: const [0, .35, .72, 1],
    ).createShader(Rect.fromLTWH(0, 0, w, h)));

    // Edge facets surround a calm central reading surface.
    final inner = [p(.19, .20), p(.71, .15), p(.82, .29), p(.87, .62),
      p(.77, .76), p(.23, .84), p(.13, .65), p(.15, .32)];
    for (var i = 0; i < points.length; i++) {
      final next = (i + 1) % points.length;
      final facet = polygon([points[i], points[next], inner[next], inner[i]]);
      canvas.drawPath(facet, Paint()..color = (i < 3 ? Colors.white : accent)
        .withValues(alpha: i.isEven ? .13 : .055));
      canvas.drawLine(points[i], inner[i], Paint()..color = accent.withValues(alpha: .28)..strokeWidth = .7);
    }
    canvas.drawPath(body, Paint()..color = accent.withValues(alpha: .88)
      ..style = PaintingStyle.stroke..strokeWidth = 1.4);
    canvas.drawLine(points[0], points[1], Paint()..color = const Color(0xD7F7FBFF)..strokeWidth = 1.4);

    for (final spot in [p(.12, .26), p(.84, .20), p(.84, .78)]) {
      final glint = Paint()..color = accent.withValues(alpha: .85)..strokeWidth = .9;
      canvas.drawLine(spot - const Offset(3, 0), spot + const Offset(3, 0), glint);
      canvas.drawLine(spot - const Offset(0, 3), spot + const Offset(0, 3), glint);
    }
    if (celebration > 0 && celebration < 1) {
      for (var i = 0; i < 6; i++) {
        final a = i * math.pi / 3;
        final center = Offset(w / 2 + math.cos(a) * w * .43 * celebration,
            h / 2 + math.sin(a) * h * .4 * celebration);
        canvas.drawCircle(center, 2.5 * (1 - celebration),
            Paint()..color = LumoVisualTokens.goldLight.withValues(alpha: 1 - celebration));
      }
    }
  }

  @override
  bool shouldRepaint(LumoCrystalPainter oldDelegate) =>
      accent != oldDelegate.accent || pedestal != oldDelegate.pedestal ||
      celebration != oldDelegate.celebration;
}
