import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'lumo_holo_effects.dart';

/// Gemeinsames Bewegungssystem der Lern-App.
///
/// Kurze Reaktionen 100–250 ms, größere Übergänge 250–500 ms. Jede Bewegung
/// entfällt, wenn das System „Animationen entfernen“ meldet. Eingaben werden
/// nie verzögert: Animationen laufen nur neben der Aktion her.
abstract final class LumoMotion {
  static const Duration press = Duration(milliseconds: 110);
  static const Duration release = Duration(milliseconds: 240);
  static const Duration value = Duration(milliseconds: 650);
  static const Duration page = Duration(milliseconds: 320);
  static const Duration entrance = Duration(milliseconds: 360);
  static const Duration stagger = Duration(milliseconds: 45);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve spring = Curves.easeOutBack;

  /// App-Einstellung „Animationen reduzieren“ bzw. Ruhemodus; AppShell
  /// hält den Wert aktuell.
  static bool appReduced = false;

  static bool reduced(BuildContext context) =>
      appReduced || (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
}

/// Federnde Druckreaktion mit Lichtimpuls, leichtem 3D-Kippen zum Finger hin
/// und gelegentlichem holografischem Schimmer für jede tippbare Fläche.
///
/// Der Tap selbst bleibt beim Kind-Widget (InkWell, Button …); diese Hülle
/// beobachtet nur die Zeiger und verändert nichts an der Gestenerkennung.
/// Bei reduzierter Bewegung entfallen Skalierung, Kippen und Schimmer.
class LumoPressable extends StatefulWidget {
  const LumoPressable({
    super.key,
    required this.child,
    this.enabled = true,
    this.glowColor = const Color(0xFF52E5FF),
    this.radius = 22,
    this.pressedScale = .955,
    this.maxTilt = .07,
    this.shimmer = true,
  });

  final Widget child;
  final bool enabled;
  final Color glowColor;
  final double radius;
  final double pressedScale;

  /// Größter Kippwinkel in Radiant beim Drücken (0 schaltet das Kippen ab).
  final double maxTilt;

  /// Holografischer Lichtschimmer in zufälligen Abständen.
  final bool shimmer;

  @override
  State<LumoPressable> createState() => _LumoPressableState();
}

class _LumoPressableState extends State<LumoPressable>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  Offset _tilt = Offset.zero;
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: LumoMotion.press,
    reverseDuration: LumoMotion.release,
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _down(PointerDownEvent event) {
    if (!widget.enabled || LumoMotion.reduced(context)) return;
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize && !box.size.isEmpty) {
      final local = box.globalToLocal(event.position);
      // -1 … 1 relativ zur Mitte: die gedrückte Seite sinkt leicht ein.
      _tilt = Offset(
        ((local.dx / box.size.width) * 2 - 1).clamp(-1.0, 1.0),
        ((local.dy / box.size.height) * 2 - 1).clamp(-1.0, 1.0),
      );
    } else {
      _tilt = Offset.zero;
    }
    _press.forward();
    unawaited(HapticFeedback.selectionClick().catchError((_) {}));
  }

  void _up([PointerEvent? _]) {
    if (_press.isDismissed) return;
    _press.reverse();
  }

  @override
  void didUpdateWidget(covariant LumoPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) {
      _hovered = false;
      _press.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (widget.enabled) setState(() => _hovered = true);
      },
      onExit: (_) => setState(() => _hovered = false),
      child: Listener(
        onPointerDown: _down,
        onPointerUp: _up,
        onPointerCancel: _up,
        behavior: HitTestBehavior.translucent,
        child: AnimatedBuilder(
          animation: _press,
          child: LumoHoloShimmer(
            enabled: widget.shimmer && widget.enabled,
            radius: widget.radius,
            child: widget.child,
          ),
          builder: (context, child) {
            final reduced = LumoMotion.reduced(context);
            final t = reduced
                ? 0.0
                : _press.isAnimating && _press.status == AnimationStatus.reverse
                    ? LumoMotion.spring.transform(_press.value)
                    : Curves.easeOut.transform(_press.value);
            final glow = t > 0
                ? t
                : _hovered
                    ? .45
                    : 0.0;
            final scale = 1 - (1 - widget.pressedScale) * t;
            final tilt = widget.maxTilt * t;
            final transform = t == 0
                ? Matrix4.identity()
                : (Matrix4.identity()
                  ..setEntry(3, 2, .0014)
                  ..rotateX(_tilt.dy * tilt)
                  ..rotateY(-_tilt.dx * tilt)
                  ..scaleByDouble(scale, scale, 1, 1));
            // Gleiche Baumstruktur in Ruhe und beim Drücken: sonst würde das
            // Kind neu aufgebaut und der laufende Tap ginge verloren.
            return Transform(
              alignment: Alignment.center,
              transform: transform,
              // Glow liegt hinter der Fläche (kein Schleier über dem Text),
              // die leuchtende Kante darüber.
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.radius),
                  boxShadow: [
                    BoxShadow(
                      color: widget.glowColor.withValues(alpha: .5 * glow),
                      blurRadius: 24,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.radius),
                    border: Border.all(
                        color: widget.glowColor.withValues(alpha: .85 * glow),
                        width: 1.8),
                  ),
                  child: child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Karten erscheinen geordnet: leicht von unten, nacheinander nach [index].
class LumoEntrance extends StatefulWidget {
  const LumoEntrance({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  State<LumoEntrance> createState() => _LumoEntranceState();
}

class _LumoEntranceState extends State<LumoEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: LumoMotion.entrance);
  Timer? _delay;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (LumoMotion.reduced(context)) {
      _c.value = 1;
      return;
    }
    final wait = LumoMotion.stagger * widget.index.clamp(0, 8);
    if (wait == Duration.zero) {
      _c.forward();
    } else {
      _delay = Timer(wait, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _c, curve: LumoMotion.enter);
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, .06), end: Offset.zero)
            .animate(curve),
        child: widget.child,
      ),
    );
  }
}

/// Bewegt einen Wert (0–1 Fortschritt, Sterne, XP) vom alten zum neuen
/// tatsächlichen Wert. Beim ersten Aufbau steht er sofort am echten Wert.
class LumoAnimatedValue extends StatelessWidget {
  const LumoAnimatedValue({
    super.key,
    required this.value,
    required this.builder,
  });

  final double value;
  final Widget Function(BuildContext context, double value) builder;

  @override
  Widget build(BuildContext context) {
    if (LumoMotion.reduced(context)) return builder(context, value);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value),
      duration: LumoMotion.value,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => builder(context, v),
    );
  }
}

/// Weicher, zügiger Seitenwechsel: einblenden und leicht nachrücken.
class LumoPageTransitionsBuilder extends PageTransitionsBuilder {
  const LumoPageTransitionsBuilder();

  @override
  Duration get transitionDuration => LumoMotion.page;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (LumoMotion.reduced(context)) return child;
    final enter = CurvedAnimation(
        parent: animation,
        curve: LumoMotion.enter,
        reverseCurve: Curves.easeInCubic);
    final leave =
        CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOut);
    return FadeTransition(
      opacity: enter,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(.04, 0), end: Offset.zero)
            .animate(enter),
        child: FadeTransition(
          opacity: Tween<double>(begin: 1, end: .82).animate(leave),
          child: child,
        ),
      ),
    );
  }
}
