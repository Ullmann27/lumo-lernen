import 'package:flutter/material.dart';

/// Short celebratory hop shown when a Lumo-Sprung card is played.
class LumoJumpCelebration extends StatefulWidget {
  const LumoJumpCelebration({super.key, this.onDone});

  final VoidCallback? onDone;

  @override
  State<LumoJumpCelebration> createState() => _LumoJumpCelebrationState();
}

class _LumoJumpCelebrationState extends State<LumoJumpCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward().whenComplete(() {
        if (mounted) widget.onDone?.call();
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final t = _ctrl.value;
          final hop = (t < 0.45)
              ? Curves.easeOut.transform(t / 0.45) * -42
              : Curves.bounceOut.transform((t - 0.45) / 0.55) * -42 * (1 - t);
          return Opacity(
            opacity: t < 0.85 ? 1 : (1 - t) / 0.15,
            child: Transform.translate(
              offset: Offset(0, hop),
              child: child,
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/lumo_design/fox/fox_spielwelt_jump.png',
              height: 110,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 6),
            const DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xE8FFF3C4),
                borderRadius: BorderRadius.all(Radius.circular(18)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Text(
                  'Lumo-Sprung!',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF7A3A10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
