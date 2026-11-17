// ════════════════════════════════════════════════════════════════════════
// LUMO DISCARD PILE — Ablagestapel mit aktueller Top-Karte
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../lumo_cards_models.dart';
import 'lumo_playing_card.dart';

class LumoDiscardPile extends StatelessWidget {
  const LumoDiscardPile({
    super.key,
    required this.topCard,
    required this.selectedColor,
  });

  final LumoCard topCard;
  final LumoCardColor selectedColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 96,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Kleiner Stapel-Effekt im Hintergrund.
              Positioned(
                left: -3,
                top: 4,
                child: Container(
                  width: 92,
                  height: 132,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5B07A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              // Lege-Animation: bei jeder neuen Top-Karte (ID-Wechsel)
              // bekommt der TweenAnimationBuilder einen frischen Key und
              // animiert die Karte 0->1 mit Slide-von-oben + Scale +
              // Opacity (easeOutBack). Wirkt wie "Karte schwebt rein und
              // klatscht auf den Tisch".
              // Sicher, kein AnimatedSwitcher (der war frueher die
              // Crash-Quelle).
              TweenAnimationBuilder<double>(
                key: ValueKey('discard-${topCard.id}'),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutBack,
                builder: (_, t, child) {
                  // Slide: faengt 70 px ueber dem Ziel an, kommt runter.
                  final dy = (1 - t) * -70;
                  // Scale 0.6 -> 1.0 mit easeOutBack-Schwung
                  final scale = 0.6 + t * 0.4;
                  // Drehung leicht rotierend reinkommen
                  final rot = (1 - t) * -0.18;
                  return Transform.translate(
                    offset: Offset(0, dy),
                    child: Transform.rotate(
                      angle: rot,
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: t.clamp(0.0, 1.0),
                          child: child,
                        ),
                      ),
                    ),
                  );
                },
                child: LumoPlayingCard(card: topCard),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              size: const Size(16, 16),
              painter: _ActiveColorMarkPainter(selectedColor),
            ),
            const SizedBox(width: 6),
            Text(
              selectedColor.displayName,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFFF3F8FF),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Color _colorOf(LumoCardColor c) {
    switch (c) {
      case LumoCardColor.orange:
        return const Color(0xFFFF4D4F); // Rot
      case LumoCardColor.purple:
        return const Color(0xFFFFC83D); // Gelb
      case LumoCardColor.blue:
        return const Color(0xFF2D7BFF); // Blau
      case LumoCardColor.green:
        return const Color(0xFF35C759); // Gruen
    }
  }
}

class _ActiveColorMarkPainter extends CustomPainter {
  const _ActiveColorMarkPainter(this.color);
  final LumoCardColor color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = switch (color) {
      LumoCardColor.orange => Path()
        ..moveTo(rect.center.dx, rect.top)
        ..lineTo(rect.right, rect.center.dy)
        ..lineTo(rect.center.dx, rect.bottom)
        ..lineTo(rect.left, rect.center.dy)
        ..close(),
      LumoCardColor.purple => Path()
        ..moveTo(rect.center.dx, rect.top)
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(rect.left, rect.bottom)
        ..close(),
      LumoCardColor.blue => Path()..addOval(rect.deflate(1)),
      LumoCardColor.green => Path()
        ..addRRect(RRect.fromRectAndRadius(
            rect.deflate(1.5), const Radius.circular(3))),
    };
    canvas.drawPath(path, Paint()..color = LumoDiscardPile._colorOf(color));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFFE8C45A),
    );
  }

  @override
  bool shouldRepaint(covariant _ActiveColorMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
