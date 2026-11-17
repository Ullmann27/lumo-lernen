import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/lumo_visual_tokens.dart';
import '../design/lumo_glass_optics.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Bausteine des Profils nach Heinz' Zielbild vom 17.11.2026
//  (docs/design_targets/2026-11-17/profil_handy.jpg): Neon-Glas-Karten,
//  plastische Sechseck-Abzeichen, leuchtende XP-Leiste, Sprechblase mit
//  Zipfel und das Regal für eingelöste Belohnungen.
//  Reine Darstellung; alle Werte kommen vom Profil-Bildschirm.
// ═══════════════════════════════════════════════════════════════════════════

/// Farbwelt des Zielbilds: königsblaues Glas mit hellblauer Neonkante.
abstract final class ProfilePalette {
  static const glassTop = Color(0xFF15489C);
  static const glassBottom = Color(0xFF0A2468);
  static const inset = Color(0xFF06194A);
  static const neon = Color(0xFF58C8FF);
  static const flame = Color(0xFFFFA63D);
  static const flameDeep = Color(0xFFFF6B1A);
  static const idle = Color(0xFF8FA3CC);
}

const _font = 'Nunito';

/// Glas-Karte mit weicher Neonkante und Lichtkante oben.
class ProfileGlass extends StatelessWidget {
  const ProfileGlass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.radius = 22,
    this.inset = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Vertiefte Fläche innerhalb einer Karte (Abzeichen-Reihe).
  final bool inset;

  static BoxDecoration decoration({double radius = 22, bool inset = false}) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: inset
              ? [
                  ProfilePalette.inset.withValues(alpha: .62),
                  ProfilePalette.inset.withValues(alpha: .78),
                ]
              : [
                  ProfilePalette.glassTop.withValues(alpha: .88),
                  ProfilePalette.glassBottom.withValues(alpha: .92),
                ],
        ),
        border: Border.all(
          color: ProfilePalette.neon.withValues(alpha: inset ? .30 : .72),
          width: inset ? 1 : 1.3,
        ),
        boxShadow: inset
            ? null
            : [
                BoxShadow(
                  color: ProfilePalette.neon.withValues(alpha: .26),
                  blurRadius: 14,
                  spreadRadius: -2,
                ),
                const BoxShadow(
                  color: Color(0x66000A24),
                  blurRadius: 14,
                  spreadRadius: -6,
                  offset: Offset(0, 8),
                ),
              ],
      );

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: decoration(radius: radius, inset: inset),
        child: CustomPaint(
          foregroundPainter: inset
              ? null
              : LumoGlassOptics(radius: radius, accent: ProfilePalette.neon),
          child: Padding(padding: padding, child: child),
        ),
      );
}

/// Leuchtende XP-Leiste; füllt sich beim Erscheinen, außer bei
/// „Animationen reduzieren“.
class ProfileXpBar extends StatelessWidget {
  const ProfileXpBar({
    super.key,
    required this.value,
    required this.reduceMotion,
    this.height = 12,
  });

  final double value;
  final bool reduceMotion;
  final double height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => SizedBox(
            height: height,
            width: double.infinity,
            child: CustomPaint(painter: _XpBarPainter(v)),
          ),
        ),
      );
}

class _XpBarPainter extends CustomPainter {
  const _XpBarPainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.height / 2);
    final track = RRect.fromRectAndRadius(Offset.zero & size, radius);
    canvas.drawRRect(track, Paint()..color = const Color(0xFF051640));
    canvas.drawRRect(
      track.deflate(.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = ProfilePalette.neon.withValues(alpha: .38),
    );
    if (value <= 0) return;
    // Ein sichtbarer Anfang bleibt rund, auch bei wenigen XP.
    final width = math.max(size.height, size.width * value);
    final fill = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, width, size.height).deflate(1.5), radius);
    canvas.drawRRect(
      fill,
      Paint()
        ..color = LumoVisualTokens.cyan.withValues(alpha: .55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawRRect(
      fill,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF9CF3FF), Color(0xFF45D6FF), Color(0xFF2C9DFF)],
        ).createShader(fill.outerRect),
    );
    final gloss = RRect.fromRectAndRadius(
      Rect.fromLTWH(fill.left + 3, fill.top + 1.5, math.max(0, fill.width - 6),
          fill.height * .32),
      radius,
    );
    canvas.drawRRect(
        gloss, Paint()..color = Colors.white.withValues(alpha: .45));
  }

  @override
  bool shouldRepaint(_XpBarPainter oldDelegate) => oldDelegate.value != value;
}

/// Plastisches Sechseck-Abzeichen: dunkler Rand, helle Fläche, Lichtkante.
class ProfileHexBadge extends StatelessWidget {
  const ProfileHexBadge({
    super.key,
    required this.colors,
    required this.child,
    this.size = 52,
    this.glow = true,
  });

  /// Oben hell, unten dunkel.
  final List<Color> colors;
  final Widget child;
  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        // Regelmäßiges Sechseck mit Spitze oben: Höhe = Breite · 2/√3.
        height: size * 1.1547,
        child: CustomPaint(
          painter: _HexPainter(colors: colors, glow: glow),
          child: Center(child: child),
        ),
      );
}

Path _roundedPolygon(List<Offset> points, double radius) {
  final path = Path();
  for (var i = 0; i < points.length; i++) {
    final current = points[i];
    final previous = points[(i - 1 + points.length) % points.length];
    final next = points[(i + 1) % points.length];
    final toPrevious = previous - current;
    final toNext = next - current;
    final start = current + toPrevious / toPrevious.distance * radius;
    final end = current + toNext / toNext.distance * radius;
    if (i == 0) {
      path.moveTo(start.dx, start.dy);
    } else {
      path.lineTo(start.dx, start.dy);
    }
    path.quadraticBezierTo(current.dx, current.dy, end.dx, end.dy);
  }
  return path..close();
}

Path _hexagon(Rect rect, {double corner = 4}) {
  final center = rect.center;
  final r = rect.height / 2;
  return _roundedPolygon([
    for (var i = 0; i < 6; i++)
      Offset(
        center.dx + r * math.cos(math.pi / 3 * i - math.pi / 2),
        center.dy + r * math.sin(math.pi / 3 * i - math.pi / 2),
      ),
  ], corner);
}

class _HexPainter extends CustomPainter {
  const _HexPainter({required this.colors, required this.glow});

  final List<Color> colors;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final top = colors.first;
    final bottom = colors.last;
    final outer = _hexagon(rect.deflate(1.5), corner: size.width * .1);
    if (glow) {
      canvas.drawPath(
        outer,
        Paint()
          ..color = top.withValues(alpha: .55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
    }
    // Rand: oben vom Licht getroffen, unten im Schatten.
    canvas.drawPath(
      outer,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(top, Colors.white, .55)!,
            Color.lerp(bottom, Colors.black, .18)!,
            Color.lerp(bottom, Colors.black, .5)!,
          ],
        ).createShader(rect),
    );
    final inset = size.width * .085;
    final face = _hexagon(rect.deflate(1.5 + inset), corner: size.width * .08);
    canvas.drawPath(
      face,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(top, Colors.white, .12)!, bottom],
        ).createShader(rect),
    );
    // Spiegelung auf der oberen Hälfte.
    canvas.save();
    canvas.clipPath(face);
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, size.height * .30)
        ..quadraticBezierTo(
            size.width * .5, size.height * .52, 0, size.height * .40)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: .30),
            Colors.white.withValues(alpha: .04),
          ],
        ).createShader(rect),
    );
    canvas.restore();
    canvas.drawPath(
      face,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: .70),
            Colors.white.withValues(alpha: .08),
            Colors.black.withValues(alpha: .28),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_HexPainter oldDelegate) =>
      oldDelegate.glow != glow ||
      oldDelegate.colors.first != colors.first ||
      oldDelegate.colors.last != colors.last;
}

/// Glas-Sprechblase mit Zipfel nach unten links, zu Lumo hin.
class ProfileSpeechBubble extends StatelessWidget {
  const ProfileSpeechBubble({super.key, required this.text});

  final String text;

  static const double _tail = 11;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontFamily: _font,
      color: LumoVisualTokens.white,
      fontSize: 12.5,
      height: 1.18,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w800,
    );
    return CustomPaint(
      painter: const _BubblePainter(tail: _tail),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(11, 8, 9, 9 + _tail),
        child: Text.rich(
          TextSpan(children: [
            TextSpan(text: '$text '),
            const WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(Icons.favorite_border_rounded,
                  size: 15, color: LumoVisualTokens.white),
            ),
          ]),
          style: style,
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter({required this.tail});

  final double tail;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Rect.fromLTWH(1, 1, size.width - 2, size.height - tail - 2);
    final shape = Path.combine(
      PathOperation.union,
      Path()
        ..addRRect(RRect.fromRectAndRadius(body, const Radius.circular(16))),
      Path()
        ..moveTo(body.left + 16, body.bottom - 2)
        ..lineTo(body.left + 6, body.bottom + tail)
        ..lineTo(body.left + 32, body.bottom - 2)
        ..close(),
    );
    canvas.drawPath(
      shape,
      Paint()
        ..color = ProfilePalette.neon.withValues(alpha: .40)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawPath(
      shape,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A56B4).withValues(alpha: .90),
            const Color(0xFF0B2F7C).withValues(alpha: .92),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF8ADFFF).withValues(alpha: .92),
    );
  }

  @override
  bool shouldRepaint(_BubblePainter oldDelegate) => oldDelegate.tail != tail;
}

/// LUMO-Schriftzug mit Stern im O und Leitspruch, wie in der Kopfzeile.
class ProfileWordmark extends StatelessWidget {
  const ProfileWordmark({super.key, this.size = 34});

  final double size;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: _font,
      fontSize: size,
      height: 1.05,
      fontWeight: FontWeight.w900,
      letterSpacing: .6,
      color: LumoVisualTokens.white,
      shadows: const [Shadow(color: LumoVisualTokens.cyan, blurRadius: 14)],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: 'LUMO',
          excludeSemantics: true,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('LUM', style: style),
              Stack(alignment: Alignment.center, children: [
                Text('O', style: style),
                Icon(Icons.star_rounded,
                    size: size * .36, color: LumoVisualTokens.cyan),
              ]),
            ]),
          ),
        ),
        const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Lernen. Spielen. Weiterkommen.',
            maxLines: 1,
            style: TextStyle(
              fontFamily: _font,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: LumoVisualTokens.cyanBright,
            ),
          ),
        ),
      ],
    );
  }
}

/// Schwungstrich unter der Überschrift im Kopf.
class ProfileSwoosh extends CustomPainter {
  const ProfileSwoosh();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * .8)
      ..quadraticBezierTo(
          size.width * .5, -size.height * .4, size.width, size.height * .35);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = LumoVisualTokens.cyan.withValues(alpha: .5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = LumoVisualTokens.cyanBright,
    );
  }

  @override
  bool shouldRepaint(ProfileSwoosh oldDelegate) => false;
}

/// Flamme der Lernserie mit Farbverlauf; grau, solange kein Lerntag zählt.
class ProfileFlame extends StatelessWidget {
  const ProfileFlame({super.key, required this.size, this.lit = true});

  final double size;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(Icons.whatshot_rounded, size: size, color: Colors.white);
    if (!lit) {
      return Icon(Icons.whatshot_rounded,
          size: size, color: ProfilePalette.idle.withValues(alpha: .7));
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: ProfilePalette.flame.withValues(alpha: .45),
            blurRadius: size * .45,
            spreadRadius: -size * .2,
          ),
        ],
      ),
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFE27A),
            ProfilePalette.flame,
            ProfilePalette.flameDeep
          ],
        ).createShader(bounds),
        child: icon,
      ),
    );
  }
}

/// Rundes Symbolfeld mit Leuchten (Zielscheibe, Lernbericht).
class ProfileIconChip extends StatelessWidget {
  const ProfileIconChip({
    super.key,
    required this.icon,
    this.size = 32,
    this.color = LumoVisualTokens.cyanBright,
  });

  final IconData icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-.3, -.4),
            colors: [
              Color.lerp(color, Colors.white, .25)!.withValues(alpha: .55),
              const Color(0xFF1F6BE0).withValues(alpha: .85),
              const Color(0xFF0B2F7C),
            ],
          ),
          border: Border.all(color: color.withValues(alpha: .85), width: 1.2),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: .45), blurRadius: 10),
          ],
        ),
        child: Icon(icon, size: size * .62, color: Colors.white),
      );
}

/// Runder Pfeilknopf am Rand einer antippbaren Karte.
class ProfileChevron extends StatelessWidget {
  const ProfileChevron({super.key, this.size = 26});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: .14),
          border: Border.all(color: Colors.white.withValues(alpha: .65)),
        ),
        child: Icon(Icons.chevron_right_rounded,
            size: size * .8, color: Colors.white),
      );
}

/// Leuchtende Plattform, auf der die eingelösten Belohnungen stehen.
/// [surfaceY] ist die Höhe der Standfläche ab Oberkante.
class ProfileShelfPainter extends CustomPainter {
  const ProfileShelfPainter({required this.surfaceY, required this.slots});

  final double surfaceY;
  final int slots;

  @override
  void paint(Canvas canvas, Size size) {
    const depth = 16.0;
    final back = surfaceY - depth * .55;
    final front = surfaceY + depth * .45;
    // Lichtkegel über jedem Platz.
    final slotWidth = size.width / slots;
    for (var i = 0; i < slots; i++) {
      final cx = slotWidth * (i + .5);
      final beam = Path()
        ..moveTo(cx - slotWidth * .16, 0)
        ..lineTo(cx + slotWidth * .16, 0)
        ..lineTo(cx + slotWidth * .40, surfaceY)
        ..lineTo(cx - slotWidth * .40, surfaceY)
        ..close();
      canvas.drawPath(
        beam,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ProfilePalette.neon.withValues(alpha: 0),
              ProfilePalette.neon.withValues(alpha: .13),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, surfaceY)),
      );
    }
    // Vorderseite der Glasplatte mit den Namen.
    final face = RRect.fromRectAndCorners(
      Rect.fromLTRB(0, front, size.width, size.height),
      bottomLeft: const Radius.circular(16),
      bottomRight: const Radius.circular(16),
      topLeft: const Radius.circular(3),
      topRight: const Radius.circular(3),
    );
    canvas.drawRRect(
      face,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1B58BE).withValues(alpha: .80),
            const Color(0xFF0A2670).withValues(alpha: .86),
          ],
        ).createShader(face.outerRect),
    );
    canvas.drawRRect(
      face.deflate(.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = ProfilePalette.neon.withValues(alpha: .38),
    );
    // Standfläche in Perspektive: hinten schmaler als vorn.
    final top = Path()
      ..moveTo(size.width * .035, back)
      ..lineTo(size.width * .965, back)
      ..lineTo(size.width, front)
      ..lineTo(0, front)
      ..close();
    final topRect = Rect.fromLTRB(0, back, size.width, front);
    canvas.drawPath(
      top,
      Paint()
        ..color = LumoVisualTokens.cyan.withValues(alpha: .55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(
      top,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A7BE6), Color(0xFF7FE6FF)],
        ).createShader(topRect),
    );
    canvas.drawLine(
      Offset(1, front),
      Offset(size.width - 1, front),
      Paint()
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: .92),
    );
  }

  @override
  bool shouldRepaint(ProfileShelfPainter oldDelegate) =>
      oldDelegate.surfaceY != surfaceY || oldDelegate.slots != slots;
}

/// Glänzende Kugel mit dem Symbol einer eingelösten Belohnung.
class ProfileRewardToken extends StatelessWidget {
  const ProfileRewardToken({
    super.key,
    required this.icon,
    required this.color,
    this.size = 46,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-.35, -.45),
                  radius: .95,
                  colors: [
                    Color.lerp(color, Colors.white, .6)!,
                    color,
                    Color.lerp(color, const Color(0xFF061A4A), .62)!,
                  ],
                  stops: const [0, .45, 1],
                ),
                border: Border.all(
                    color: Colors.white.withValues(alpha: .55), width: 1.2),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: .6), blurRadius: 12),
                ],
              ),
              child: Icon(
                icon,
                size: size * .52,
                color: Colors.white,
                shadows: const [
                  Shadow(color: Color(0x88000A24), blurRadius: 4),
                ],
              ),
            ),
          ),
          Positioned(
            left: size * .20,
            top: size * .10,
            child: Transform.rotate(
              angle: -.5,
              child: Container(
                width: size * .34,
                height: size * .15,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .5),
                  borderRadius: BorderRadius.circular(size),
                ),
              ),
            ),
          ),
        ]),
      );
}

/// Zielscheibe mit Pfeil für „Nächstes Ziel“.
class ProfileBullseye extends StatelessWidget {
  const ProfileBullseye({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: const CustomPaint(painter: _BullseyePainter()),
      );
}

class _BullseyePainter extends CustomPainter {
  const _BullseyePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .46, size.height * .54);
    final r = size.width * .44;
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = LumoVisualTokens.cyan.withValues(alpha: .55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    const rings = [
      (1.0, Color(0xFF4FC3FF)),
      (.78, Color(0xFFF2FAFF)),
      (.56, Color(0xFF2D7BEA)),
      (.34, Color(0xFFF2FAFF)),
      (.14, Color(0xFF1B55C8)),
    ];
    for (final (factor, color) in rings) {
      canvas.drawCircle(center, r * factor, Paint()..color = color);
    }
    // Pfeil von rechts oben in die Mitte.
    final tail = Offset(size.width * .96, size.height * .06);
    final shaft = Paint()
      ..strokeWidth = size.width * .075
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF0B2F7C);
    canvas.drawLine(center, tail, shaft);
    final feather = Paint()
      ..strokeWidth = size.width * .065
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFFC94A);
    canvas.drawLine(
        tail, tail + Offset(-size.width * .16, -size.height * .01), feather);
    canvas.drawLine(
        tail, tail + Offset(size.width * .01, size.height * .16), feather);
  }

  @override
  bool shouldRepaint(_BullseyePainter oldDelegate) => false;
}
