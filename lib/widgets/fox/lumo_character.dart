import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/lumo_visual_tokens.dart';
import '../design/lumo_design_system.dart';

/// Einmalige Bewegungen, die Lumo auf Zuruf spielt.
enum LumoCharacterAction {
  /// Großer Freudensprung mit Strecken, Drehung und Sternen (richtig!).
  cheer,

  /// Tröstend: zur Seite neigen, kurz einsinken, sanft den Kopf schütteln.
  comfort,

  /// Antippen: kitzlig wackeln und zusammenstauchen.
  wiggle,

  /// Kleiner Hüpfer mit Schwung, zum Begrüßen.
  hello,

  /// Erklärbewegung während Lumo eine Aufgabe oder Hilfe vorliest.
  talk,

  /// Nachdenkliche Reaktion, z. B. vor einem Tipp.
  think,

  /// Deutliches Winken bei Begrüßung/Navigation.
  wave,
}

/// Steuert eine [LumoCharacter]-Figur von außen, z. B. aus einer Aufgabe.
class LumoCharacterController extends ChangeNotifier {
  LumoCharacterAction? _pending;
  int _serial = 0;

  LumoCharacterAction? get pending => _pending;
  int get serial => _serial;

  void play(LumoCharacterAction action) {
    _pending = action;
    _serial++;
    notifyListeners();
  }

  void cheer() => play(LumoCharacterAction.cheer);
  void comfort() => play(LumoCharacterAction.comfort);
  void wiggle() => play(LumoCharacterAction.wiggle);
  void hello() => play(LumoCharacterAction.hello);
  void talk() => play(LumoCharacterAction.talk);
  void think() => play(LumoCharacterAction.think);
  void wave() => play(LumoCharacterAction.wave);
}

/// Lumo als lebendige Zeichentrickfigur.
///
/// Die Posen sind fertige Einzelbilder (keine Gelenke), darum bewegt sich
/// Lumo wie eine Puppe nach klassischen Trickfilm-Regeln: Atmen mit Stauchen
/// und Strecken, leichtes Schwanken, ab und zu ein kleiner Hüpfer,
/// Ausholen vor jedem Sprung, Nachschwingen beim Landen und ein Schatten,
/// der mit der Sprunghöhe kleiner wird. Bei Freude wechselt er kurz in die
/// Jubel-Pose. Alles läuft über Transformationen in einem RepaintBoundary;
/// mit „Animationen reduzieren“ steht Lumo still.
class LumoCharacter extends StatefulWidget {
  const LumoCharacter({
    super.key,
    required this.pose,
    this.size = 160,
    this.reduceMotion = false,
    this.controller,
    this.onTap,
    this.celebratePose = LumoDesignFoxPose.cheer,
    this.shadow = true,
    this.idleHops = true,
    this.intro = true,
    this.ambientPoses = const <LumoDesignFoxPose>[],
    this.child,
  });

  final LumoDesignFoxPose pose;
  final double size;
  final bool reduceMotion;
  final LumoCharacterController? controller;
  final VoidCallback? onTap;

  /// Pose während des Jubelsprungs; null behält die normale Pose.
  final LumoDesignFoxPose? celebratePose;
  final bool shadow;
  final bool idleHops;

  /// Beim Erscheinen mit Schwung hereinploppen.
  final bool intro;

  /// Zusätzliche Posen für den Leerlauf. Damit ist Lumo nicht nur ein
  /// transformiertes Standbild: er wechselt weich zwischen echten,
  /// konsistenten Lumo-Posen (z. B. Lehrer -> Zeigen -> Zwinkern).
  final List<LumoDesignFoxPose> ambientPoses;

  /// Statt der Pose ein eigenes Bild bewegen (z. B. das runde Avatar-Bild).
  final Widget? child;

  @override
  State<LumoCharacter> createState() => _LumoCharacterState();
}

class _LumoCharacterState extends State<LumoCharacter>
    with TickerProviderStateMixin {
  // Atmen: 2,6 s hin und her.
  late final AnimationController _breath = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2600));
  // Langer Leerlauf-Zyklus: Schwanken und ein Hüpfer gegen Ende.
  late final AnimationController _cycle = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 7400));
  late final AnimationController _action = AnimationController(vsync: this);
  late final AnimationController _intro = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 650));

  LumoCharacterAction? _current;
  int _seenSerial = 0;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onControllerAction);
    _seenSerial = widget.controller?.serial ?? 0;
    _action.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _current = null);
      }
    });
    _startLoops();
  }

  void _startLoops() {
    if (widget.reduceMotion) {
      _breath.value = 0;
      _cycle.value = 0;
      _intro.value = 1;
      return;
    }
    _breath.repeat();
    _cycle.repeat();
    if (widget.intro) {
      _intro.forward(from: 0);
    } else {
      _intro.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant LumoCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerAction);
      widget.controller?.addListener(_onControllerAction);
      _seenSerial = widget.controller?.serial ?? 0;
    }
    if (oldWidget.reduceMotion != widget.reduceMotion) {
      _breath.stop();
      _cycle.stop();
      _startLoops();
    }
  }

  void _onControllerAction() {
    final controller = widget.controller;
    if (controller == null || controller.serial == _seenSerial) return;
    _seenSerial = controller.serial;
    final action = controller.pending;
    if (action != null) _play(action);
  }

  void _play(LumoCharacterAction action) {
    if (!mounted) return;
    if (widget.reduceMotion) {
      // Ohne Bewegung zeigt Lumo die Freude kurz über die Jubel-Pose.
      if (action == LumoCharacterAction.cheer) {
        setState(() => _current = action);
        _action.duration = const Duration(milliseconds: 900);
        _action.forward(from: 0);
      }
      return;
    }
    setState(() => _current = action);
    _action.duration = switch (action) {
      LumoCharacterAction.cheer => const Duration(milliseconds: 1100),
      LumoCharacterAction.comfort => const Duration(milliseconds: 1300),
      LumoCharacterAction.wiggle => const Duration(milliseconds: 650),
      LumoCharacterAction.hello => const Duration(milliseconds: 800),
      LumoCharacterAction.talk => const Duration(milliseconds: 1450),
      LumoCharacterAction.think => const Duration(milliseconds: 1250),
      LumoCharacterAction.wave => const Duration(milliseconds: 1050),
    };
    _action.forward(from: 0);
  }

  void _handleTap() {
    widget.onTap?.call();
    _play(LumoCharacterAction.wiggle);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerAction);
    _breath.dispose();
    _cycle.dispose();
    _action.dispose();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return Semantics(
      image: widget.child == null,
      label: widget.pose.semanticLabel,
      button: widget.onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap == null ? null : _handleTap,
        child: RepaintBoundary(
          child: SizedBox(
            width: size,
            height: size,
            child: AnimatedBuilder(
              animation: Listenable.merge([_breath, _cycle, _action, _intro]),
              builder: (context, _) => _frame(size),
            ),
          ),
        ),
      ),
    );
  }

  Widget _frame(double size) {
    final m = _motion(size);
    final displayPose = _displayPose();
    final figure = widget.child ??
        AnimatedSwitcher(
          duration: widget.reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          // Keep pose transitions transform-free. The outer character Transform is the
          // single source of movement/rotation, which keeps hit testing and animation
          // regression measurements stable while poses cross-fade.
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: LumoFoxPose(
            key: ValueKey(displayPose.assetName),
            pose: displayPose,
            size: size,
          ),
        );
    return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          if (widget.shadow)
            Positioned(
              bottom: size * .02,
              child: Opacity(
                opacity: (.32 * m.shadow).clamp(0, 1).toDouble(),
                child: Container(
                  width: size * .5 * m.shadow,
                  height: size * .07 * m.shadow,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(size),
                    gradient: const RadialGradient(colors: [
                      Color(0xFF000814),
                      Color(0x00000814),
                    ]),
                  ),
                ),
              ),
            ),
          if (_current == LumoCharacterAction.cheer)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _StarBurstPainter(progress: _action.value),
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(m.dx, m.dy),
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()
                ..rotateZ(m.rotation)
                ..scale(m.scaleX, m.scaleY),
              child: figure,
            ),
          ),
        ]);
  }

  LumoDesignFoxPose _displayPose() {
    if (_current == LumoCharacterAction.cheer &&
        widget.celebratePose != null &&
        _action.value < .92) {
      return widget.celebratePose!;
    }
    switch (_current) {
      case LumoCharacterAction.talk:
        return LumoDesignFoxPose.teacherStick;
      case LumoCharacterAction.think:
        return LumoDesignFoxPose.bookPoint;
      case LumoCharacterAction.wave:
      case LumoCharacterAction.hello:
        return LumoDesignFoxPose.armsOpen;
      case LumoCharacterAction.wiggle:
        return LumoDesignFoxPose.thumbWink;
      case LumoCharacterAction.cheer:
      case LumoCharacterAction.comfort:
      case null:
        break;
    }
    if (widget.reduceMotion || widget.ambientPoses.isEmpty) {
      return widget.pose;
    }
    final cycle = _cycle.value;
    if (cycle >= .50 && cycle < .62) {
      return widget.ambientPoses.first;
    }
    if (widget.ambientPoses.length > 1 && cycle >= .76 && cycle < .89) {
      return widget.ambientPoses[1];
    }
    if (widget.ambientPoses.length > 2 && cycle >= .92) {
      return widget.ambientPoses[2];
    }
    return widget.pose;
  }

  /// Rechnet die momentane Haltung aus allen Bewegungsschichten zusammen.
  _Motion _motion(double size) {
    var dx = 0.0, dy = 0.0, rotation = 0.0, scaleX = 1.0, scaleY = 1.0;
    var lift = 0.0; // Höhe über dem Boden für den Schatten (0..1).

    // Hereinploppen: von klein mit Überschwingen auf normal.
    final intro = _intro.value;
    if (intro < 1) {
      final pop = Curves.elasticOut.transform(intro);
      scaleX *= .55 + .45 * pop;
      scaleY *= .55 + .45 * pop;
    }

    if (!widget.reduceMotion) {
      // Atmen: Strecken nach oben, dabei etwas schmaler (Volumen bleibt).
      final b = math.sin(_breath.value * 2 * math.pi);
      scaleY *= 1 + .018 * b;
      scaleX *= 1 - .009 * b;
      dy += -2.5 * (b + 1) / 2;
      // Schwanken und Gewicht verlagern.
      final c = _cycle.value;
      rotation += .014 * math.sin(c * 4 * math.pi);
      dx += 1.6 * math.sin(c * 2 * math.pi);
      // Leerlauf-Hüpfer kurz vor Ende des Zyklus.
      if (widget.idleHops && _current == null && c > .80 && c < .95) {
        final hop = _jump((c - .80) / .15, height: size * .06);
        dy += hop.dy;
        scaleX *= hop.sx;
        scaleY *= hop.sy;
        lift = math.max(lift, hop.lift);
      }
    }

    final t = _action.value;
    switch (_current) {
      case LumoCharacterAction.cheer:
        if (widget.reduceMotion) break;
        final jump = _jump(t, height: size * .2);
        dy += jump.dy;
        scaleX *= jump.sx;
        scaleY *= jump.sy;
        lift = math.max(lift, jump.lift);
        // Halbe Drehung in der Luft hin und zurück.
        rotation += .12 * math.sin(t * 2 * math.pi) * (1 - t);
      case LumoCharacterAction.comfort:
        // Zur Seite neigen, einsinken, dann sanft „macht nichts“ schütteln.
        final lean = math.sin(math.min(t / .3, 1) * math.pi / 2) *
            (t < .7 ? 1 : 1 - (t - .7) / .3);
        rotation += -.09 * lean;
        dy += 5 * lean;
        scaleY *= 1 - .04 * lean;
        scaleX *= 1 + .02 * lean;
        if (t > .3 && t < .85) {
          final shake = (t - .3) / .55;
          rotation += .045 * math.sin(shake * 6 * math.pi) * (1 - shake);
        }
      case LumoCharacterAction.wiggle:
        final decay = 1 - t;
        rotation += .14 * math.sin(t * 7 * math.pi) * decay;
        final squash = math.sin(math.min(t / .25, 1) * math.pi);
        scaleY *= 1 - .08 * squash;
        scaleX *= 1 + .06 * squash;
      case LumoCharacterAction.hello:
        final hop = _jump(t, height: size * .09);
        dy += hop.dy;
        scaleX *= hop.sx;
        scaleY *= hop.sy;
        lift = math.max(lift, hop.lift);
        rotation += .07 * math.sin(t * 4 * math.pi) * (1 - t);
      case LumoCharacterAction.talk:
        // Sprech-Rhythmus: kleine Betonungen statt hektischem Wackeln.
        final syllable = math.sin(t * 10 * math.pi) * (1 - .35 * t);
        dy += -1.8 * math.max(0, syllable);
        scaleY *= 1 + .018 * syllable;
        scaleX *= 1 - .009 * syllable;
        rotation += .018 * math.sin(t * 5 * math.pi) * (1 - t);
      case LumoCharacterAction.think:
        final ease = math.sin(t * math.pi);
        rotation += -.055 * ease;
        dx += -2.0 * ease;
        dy += 1.2 * ease;
      case LumoCharacterAction.wave:
        final wave = math.sin(t * 7 * math.pi) * (1 - t);
        rotation += .05 * wave;
        final hop = _jump(t, height: size * .045);
        dy += hop.dy;
        lift = math.max(lift, hop.lift);
      case null:
        break;
    }
    return _Motion(dx, dy, rotation, scaleX, scaleY, 1 - .55 * lift);
  }

  /// Sprung mit Ausholen (stauchen), Flug (strecken) und Landung
  /// (stauchen, nachfedern). [u] läuft von 0 bis 1.
  _Jump _jump(double u, {required double height}) {
    if (u <= 0 || u >= 1) return const _Jump(0, 1, 1, 0);
    if (u < .2) {
      final s = math.sin(u / .2 * math.pi / 2);
      return _Jump(2 * s, 1 + .07 * s, 1 - .1 * s, 0);
    }
    if (u < .72) {
      final v = (u - .2) / .52;
      final arc = math.sin(v * math.pi);
      final stretch = 1 - (2 * v - 1).abs();
      return _Jump(-height * arc, 1 - .05 * stretch, 1 + .08 * stretch, arc);
    }
    final w = (u - .72) / .28;
    final squash = math.sin(w * math.pi) * (1 - w * .6);
    return _Jump(1.5 * squash, 1 + .08 * squash, 1 - .1 * squash, 0);
  }
}

class _Motion {
  const _Motion(
      this.dx, this.dy, this.rotation, this.scaleX, this.scaleY, this.shadow);
  final double dx, dy, rotation, scaleX, scaleY, shadow;
}

class _Jump {
  const _Jump(this.dy, this.sx, this.sy, this.lift);
  final double dy, sx, sy, lift;
}

/// Kleine Sterne, die beim Jubeln aus Lumo herausspringen und verblassen.
class _StarBurstPainter extends CustomPainter {
  const _StarBurstPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final center = Offset(size.width / 2, size.height * .45);
    final ease = Curves.easeOutCubic.transform(progress);
    final fade = (1 - progress).clamp(0.0, 1.0);
    for (var i = 0; i < 9; i++) {
      final angle = -math.pi / 2 + (i - 4) * .32;
      final distance = size.width * (.25 + .38 * ease) * (i.isEven ? 1 : .8);
      final p = center + Offset(math.cos(angle), math.sin(angle)) * distance;
      final r = size.width * (.035 + .015 * (i % 3)) * (1 - .4 * progress);
      final color =
          (i % 3 == 0 ? LumoVisualTokens.cyanBright : LumoVisualTokens.gold)
              .withValues(alpha: fade);
      canvas.drawPath(_star(p, r), Paint()..color = color);
    }
  }

  Path _star(Offset c, double r) {
    final path = Path();
    for (var k = 0; k < 10; k++) {
      final radius = k.isEven ? r : r * .45;
      final a = -math.pi / 2 + k * math.pi / 5;
      final point = c + Offset(math.cos(a), math.sin(a)) * radius;
      k == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant _StarBurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
