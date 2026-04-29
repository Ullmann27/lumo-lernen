import 'package:flutter/material.dart';
import '../../app/app_theme.dart';

/// Schwebender "+XP"-Text der nach oben steigt und ausfadet.
/// Ergibt das klassische Reward-Hit-Gefühl.
///
/// Aufruf:
/// ```
/// XpFloat.show(context, origin: Offset(300, 400), amount: 20);
/// ```
class XpFloat extends StatefulWidget {
  const XpFloat({
    super.key,
    required this.origin,
    required this.amount,
    required this.onDone,
    this.color = LumoColors.gold,
    this.label = 'XP',
  });

  final Offset origin;
  final int amount;
  final VoidCallback onDone;
  final Color color;
  final String label;

  static void show(
    BuildContext context, {
    required Offset origin,
    required int amount,
    Color color = LumoColors.gold,
    String label = 'XP',
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: XpFloat(
          origin: origin,
          amount: amount,
          color: color,
          label: label,
          onDone: () => entry.remove(),
        ),
      ),
    );
    overlay.insert(entry);
  }

  @override
  State<XpFloat> createState() => _XpFloatState();
}

class _XpFloatState extends State<XpFloat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    })
    ..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;

        // Y bewegt sich 90px nach oben mit Bounce-Anfang
        final liftCurve = Curves.easeOutCubic.transform(t);
        final dy = -90 * liftCurve;

        // Skaliert kurz auf 1.15, dann zurück auf 1.0
        final scaleT = (t < 0.2) ? t / 0.2 : 1.0;
        final overshoot = (t < 0.2)
            ? Curves.easeOut.transform(scaleT)
            : 1.0;
        final scale = 0.6 + 0.55 * overshoot - (t > 0.2 ? (t - 0.2) * 0.15 : 0);

        // Fade out in letzter Phase
        final opacity = t < 0.7 ? 1.0 : (1.0 - (t - 0.7) / 0.3);

        return Positioned(
          left: widget.origin.dx - 60,
          top: widget.origin.dy + dy - 24,
          child: Transform.scale(
            scale: scale.clamp(0.0, 1.5),
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.color,
                      Color.lerp(widget.color, Colors.white, .25)!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(LumoRadius.pill),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(.45),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '+${widget.amount}',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Color(0x55000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.label,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: .5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
