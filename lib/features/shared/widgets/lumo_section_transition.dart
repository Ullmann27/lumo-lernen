import 'package:flutter/material.dart';

/// Sanfter Uebergang zwischen Sections: Slide-up + Scale 0.98 -> 1.0 + Fade.
/// Dauer 220ms, Curve easeOutCubic - ruhig und hochwertig, nicht hektisch.
///
/// Verwendung als Wrapper um den Section-Content. Bei jedem Section-Wechsel
/// triggert AnimatedSwitcher den neuen Uebergang.
class LumoSectionTransition extends StatelessWidget {
  const LumoSectionTransition({
    super.key,
    required this.sectionKey,
    required this.child,
    this.duration = const Duration(milliseconds: 220),
  });

  /// Eindeutiger Key der Section (z.B. der LumoSection-Name) damit
  /// AnimatedSwitcher den Wechsel erkennt.
  final String sectionKey;
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(animation);
        final scale = Tween<double>(begin: 0.985, end: 1.0).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: slide,
            child: ScaleTransition(scale: scale, child: child),
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey<String>(sectionKey), child: child),
    );
  }
}

/// Tap-Reaktion fuer Menue-Items: kurz auf 0.96 skalieren beim Druecken.
/// Wird ueber `Listener` statt GestureDetector implementiert damit es
/// mit bestehenden onTap-Callbacks zusammenarbeitet.
class LumoTapBounce extends StatefulWidget {
  const LumoTapBounce({
    super.key,
    required this.child,
    this.scale = 0.96,
    this.duration = const Duration(milliseconds: 90),
  });
  final Widget child;
  final double scale;
  final Duration duration;

  @override
  State<LumoTapBounce> createState() => _LumoTapBounceState();
}

class _LumoTapBounceState extends State<LumoTapBounce> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
