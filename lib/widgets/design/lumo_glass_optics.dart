import 'package:flutter/material.dart';

/// Thin bevel and reflected skylight, painted once rather than a screen blur.
/// The transparent middle keeps text readable and never intercepts input.
class LumoGlassOptics extends CustomPainter {
  const LumoGlassOptics(
      {this.radius = 24, this.accent = const Color(0xFF53DDFD)});
  final double radius;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final edge =
        RRect.fromRectAndRadius(rect.deflate(.8), Radius.circular(radius));
    canvas.save();
    canvas.clipRRect(edge);
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width * .72, 0)
        ..lineTo(size.width * .18, size.height * .35)
        ..lineTo(0, size.height * .22)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: .07),
            Colors.white.withValues(alpha: 0)
          ],
        ).createShader(rect),
    );
    canvas.drawRRect(
        edge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0, .2, .48, .75, 1],
            colors: [
              Colors.white.withValues(alpha: .8),
              accent.withValues(alpha: .65),
              accent.withValues(alpha: .08),
              accent.withValues(alpha: .12),
              accent.withValues(alpha: .6)
            ],
          ).createShader(rect));
    canvas.restore();
  }

  @override
  bool shouldRepaint(LumoGlassOptics oldDelegate) =>
      radius != oldDelegate.radius || accent != oldDelegate.accent;
}

/// Spatial light plinth for the original fox artwork; no replacement character.
class LumoLightPlinth extends StatelessWidget {
  const LumoLightPlinth({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        Positioned(
            left: 0,
            right: 0,
            top: 12,
            bottom: 12,
            child: DecoratedBox(
                decoration: BoxDecoration(
                    gradient: RadialGradient(
              colors: [
                const Color(0xFF37D2FD).withValues(alpha: .24),
                Colors.transparent
              ],
            )))),
        Positioned(
            left: 14,
            right: 14,
            bottom: 5,
            height: 28,
            child: DecoratedBox(
                decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.elliptical(100, 22)),
              gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x8853DDFD), Color(0xE908214D)]),
              border: Border.all(color: const Color(0xAA8CEAFF)),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x5537D2FD), blurRadius: 24, spreadRadius: 2)
              ],
            ))),
        child,
      ]);
}
