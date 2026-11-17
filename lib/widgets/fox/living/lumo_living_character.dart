import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../../theme/lumo_visual_tokens.dart';
import '../../design/lumo_design_system.dart';
import '../../design/lumo_motion.dart';
import 'lumo_fox_mesh.dart';
import 'lumo_fox_rig.dart';

/// Was Lumo gerade tut. Jeder Zustand hat eine eigene Original-Pose und ein
/// eigenes Verhalten von Kopf, Ohren, Schweif, Blick und Atmung.
enum LumoLivingState {
  greet('Lumo begrüßt dich mit offenen Armen', LumoDesignFoxPose.armsOpen),
  listen('Lumo hört dir aufmerksam zu', LumoDesignFoxPose.bookWelcome),
  think('Lumo denkt nach', LumoDesignFoxPose.bookPoint),
  explain('Lumo erklärt und zeigt mit der Pfote', LumoDesignFoxPose.pointSide),
  demonstrate('Lumo zeigt es dir vor', LumoDesignFoxPose.pointSide),
  encourage('Lumo macht dir Mut', LumoDesignFoxPose.thumbWink),
  approve('Lumo stimmt dir zu', LumoDesignFoxPose.tabletThumb),
  idea('Lumo hat eine neue Idee', LumoDesignFoxPose.teacherStick),
  celebrate('Lumo feiert deinen Lernerfolg', LumoDesignFoxPose.cheer),
  pause('Lumo schlägt eine kleine Pause vor', LumoDesignFoxPose.bookWelcome),
  wait('Lumo wartet ruhig', LumoDesignFoxPose.bookWelcome);

  const LumoLivingState(this.semanticLabel, this.pose);
  final String semanticLabel;
  final LumoDesignFoxPose pose;
}

/// Steuert einen [LumoLivingCharacter] von außen.
class LumoLivingController extends ChangeNotifier {
  LumoLivingController({LumoLivingState state = LumoLivingState.wait})
      : _state = state;

  LumoLivingState _state;
  Offset? _lookAt;
  bool _faceLeft = false;
  int _serial = 0;

  LumoLivingState get state => _state;

  /// Blickziel relativ zur Figur (-1..1 je Achse); null = Zustand bestimmt.
  Offset? get lookAt => _lookAt;

  /// Gespiegelt, wenn Lumo nach links zeigen soll.
  bool get faceLeft => _faceLeft;

  /// Erhöht sich bei jedem Auftritt, auch bei gleichem Zustand.
  int get serial => _serial;

  void perform(LumoLivingState state, {Offset? lookAt, bool? faceLeft}) {
    _state = state;
    _lookAt = lookAt;
    if (faceLeft != null) _faceLeft = faceLeft;
    _serial++;
    notifyListeners();
  }

  void look(Offset? target) {
    if (_lookAt == target) return;
    _lookAt = target;
    notifyListeners();
  }
}

/// Für Tests: die Zielhaltung eines Zustands nach [seconds] Sekunden.
@visibleForTesting
LumoRigFrame lumoLivingFrame(LumoLivingState state, double seconds) =>
    _LumoMotion.target(state, seconds, seconds, null);

/// Der lebendige Original-Lumo.
///
/// Die fertigen Original-Renderings werden über ein Gitter verformt
/// ([LumoFoxMesh]): Ohren zucken und richten sich auf, der Schweif pendelt,
/// der Kopf neigt und nickt, die Pupillen folgen dem Blickziel, die Brust
/// atmet und Lumo blinzelt mit seinen eigenen geschlossenen Augen aus den
/// Zwinker-Posen. Zustandswechsel blenden weich über. Mit „Animationen
/// reduzieren“ zeigt Lumo die passende Pose still, ohne Schleifen.
class LumoLivingCharacter extends StatefulWidget {
  const LumoLivingCharacter({
    super.key,
    required this.controller,
    this.size = 160,
    this.reduceMotion = false,
    this.shadow = true,
    this.onTap,
  });

  final LumoLivingController controller;
  final double size;
  final bool reduceMotion;
  final bool shadow;
  final VoidCallback? onTap;

  /// Ruhelage der zeigenden Hand in einer Figur der Größe [size], zum
  /// Beispiel als Ursprung eines Lichtstrahls in einer Lernszene.
  static Offset handOf(LumoLivingState state, double size,
      {bool faceLeft = false}) {
    final hand = LumoFoxRig.of(state.pose)?.hand ?? const Offset(.8, .4);
    return Offset((faceLeft ? 1 - hand.dx : hand.dx) * size, hand.dy * size);
  }

  @override
  State<LumoLivingCharacter> createState() => _LumoLivingCharacterState();
}

class _LumoLivingCharacterState extends State<LumoLivingCharacter>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  final _clock = _LumoClock();
  final Map<LumoDesignFoxPose, ui.Image> _images = {};
  int _loadedForWidth = 0;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onPerform);
    _clock.start(widget.controller.state, widget.controller.serial);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadImages();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant LumoLivingCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onPerform);
      widget.controller.addListener(_onPerform);
      _onPerform();
    }
    if (oldWidget.size != widget.size) _loadImages();
    _syncTicker();
  }

  bool get _calm => widget.reduceMotion || LumoMotion.reduced(context);

  void _syncTicker() {
    if (_calm) {
      if (_ticker.isActive) _ticker.stop();
      _clock.freeze();
      _clock.notify();
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  void _onPerform() {
    _clock.enter(widget.controller.state, widget.controller.serial,
        instant: _calm);
    if (mounted) setState(() {});
  }

  void _onTick(Duration elapsed) {
    _clock.advance(elapsed, widget.controller);
  }

  void _loadImages() {
    final ratio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2;
    final width = ((widget.size * ratio * 1.15) / 128).ceil() * 128;
    final target = width.clamp(256, 1024);
    if (target == _loadedForWidth) return;
    _loadedForWidth = target;
    final poses = <LumoDesignFoxPose>{
      for (final state in LumoLivingState.values) state.pose,
      LumoLidSource.left.pose,
      LumoLidSource.right.pose,
    };
    for (final pose in poses) {
      final ready = _LumoPoseImages.cached(pose, target);
      if (ready != null) {
        _images[pose] = ready;
        continue;
      }
      _LumoPoseImages.load(pose, target).then((image) {
        if (_disposed || image == null) return;
        setState(() => _images[pose] = image);
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    widget.controller.removeListener(_onPerform);
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state;
    final ready =
        _images.containsKey(state.pose) && LumoFoxRig.supports(state.pose);
    return Semantics(
      image: true,
      label: state.semanticLabel,
      button: widget.onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: RepaintBoundary(
          child: SizedBox.square(
            dimension: widget.size,
            child: ready
                ? CustomPaint(
                    painter: _LumoLivingPainter(
                      clock: _clock,
                      images: _images,
                      version: _images.length,
                      faceLeft: widget.controller.faceLeft,
                      shadow: widget.shadow,
                    ),
                  )
                : Transform.flip(
                    flipX: widget.controller.faceLeft,
                    child: LumoFoxPose(pose: state.pose, size: widget.size),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Lädt die Original-Posen einmal pro Größe und hält sie für alle Lumos.
/// Fertige Bilder werden synchron geliefert; nur laufende Ladevorgänge sind
/// Futures.
class _LumoPoseImages {
  static final Map<(LumoDesignFoxPose, int), ui.Image> _ready = {};
  static final Map<(LumoDesignFoxPose, int), Future<ui.Image?>> _pending = {};

  static ui.Image? cached(LumoDesignFoxPose pose, int width) =>
      _ready[(pose, width)];

  static Future<ui.Image?> load(LumoDesignFoxPose pose, int width) {
    final key = (pose, width);
    return _pending.putIfAbsent(key, () {
      final completer = Completer<ui.Image?>();
      final stream = ResizeImage(AssetImage(pose.assetPath),
              width: width, allowUpscaling: false)
          .resolve(ImageConfiguration.empty);
      late final ImageStreamListener listener;
      listener = ImageStreamListener((info, _) {
        _ready[key] = info.image;
        _pending.remove(key);
        completer.complete(info.image);
        stream.removeListener(listener);
      }, onError: (_, __) {
        _pending.remove(key);
        completer.complete(null);
        stream.removeListener(listener);
      });
      stream.addListener(listener);
      return completer.future;
    });
  }
}

/// Zeit, Zustand und die weich nachgeführte Haltung.
class _LumoClock extends ChangeNotifier {
  LumoLivingState state = LumoLivingState.wait;
  LumoLivingState? previous;
  int _serial = -1;
  double now = 0;
  double enteredAt = 0;
  double fade = 1;
  bool frozen = false;
  LumoRigFrame rig = LumoRigFrame.rest;
  _Body body = const _Body();
  Offset? lookAt;
  Duration _last = Duration.zero;

  double get stateTime => now - enteredAt;

  void start(LumoLivingState first, int serial) {
    state = first;
    _serial = serial;
    previous = null;
    fade = 1;
  }

  void enter(LumoLivingState next, int serial, {bool instant = false}) {
    if (serial == _serial && next == state) return;
    _serial = serial;
    if (next.pose != state.pose && !instant) {
      previous = state;
      fade = 0;
    } else {
      previous = null;
      fade = 1;
    }
    state = next;
    enteredAt = now;
    if (instant) {
      rig = _LumoMotion.target(state, 0, 0, lookAt, calm: true);
      body = const _Body();
    }
    notifyListeners();
  }

  void freeze() {
    frozen = true;
    previous = null;
    fade = 1;
    rig = _LumoMotion.target(state, 0, 0, lookAt, calm: true);
    body = const _Body();
  }

  void notify() => notifyListeners();

  void advance(Duration elapsed, LumoLivingController controller) {
    frozen = false;
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, .05);
    _last = elapsed;
    now += dt;
    lookAt = controller.lookAt;
    if (fade < 1) fade = math.min(1, fade + dt / .2);
    if (fade >= 1) previous = null;
    final goal = _LumoMotion.target(state, now, stateTime, lookAt);
    // Kritisch gedämpftes Nachführen: weiche Übergänge ohne Ruckeln.
    final k = 1 - math.exp(-dt / .09);
    // Lidschlag nicht glätten, er muss schnell sein.
    rig = LumoRigFrame.lerp(rig, goal, k).withBlink(goal.blink);
    body = _LumoMotion.body(state, now, stateTime, fade);
    notifyListeners();
  }
}

/// Ganzkörperbewegung über die Leinwand (Sprung, Neigen, Stauchen).
class _Body {
  const _Body(
      {this.dx = 0,
      this.dy = 0,
      this.rotation = 0,
      this.scaleX = 1,
      this.scaleY = 1,
      this.lift = 0,
      this.effect = 0});
  final double dx, dy, rotation, scaleX, scaleY, lift;

  /// Fortschritt des zustandstypischen Effekts (Sterne, Funke, Atemring).
  final double effect;
}

/// Bewegungsprofile der Zustände. Alle Werte sind bewusst klein.
class _LumoMotion {
  static double _blinkCurve(double t) {
    // 0..1 über 0,16 s: schnell zu, kurz halten, etwas langsamer auf.
    if (t < 0 || t > .16) return 0;
    if (t < .05) return t / .05;
    if (t < .08) return 1;
    return 1 - (t - .08) / .08;
  }

  /// Unregelmäßiges, aber reproduzierbares Blinzeln alle 2,6 bis 5,4 s:
  /// acht feste Abstände, die sich zyklisch wiederholen.
  static const List<double> _blinkGaps = [
    3.1,
    4.6,
    2.7,
    5.2,
    3.8,
    2.9,
    4.9,
    3.4
  ];
  static const double _blinkCycle = 30.6;

  static double _blink(double now) {
    final t = now % _blinkCycle;
    var start = 1.2;
    for (final gap in _blinkGaps) {
      if (t >= start && t <= start + .16) return _blinkCurve(t - start);
      start += gap;
    }
    return 0;
  }

  static double _decay(double s, double rate) => math.exp(-rate * s);
  static double _wave(double g, double hz, [double phase = 0]) =>
      math.sin(2 * math.pi * hz * g + phase);

  static LumoRigFrame target(
      LumoLivingState state, double g, double s, Offset? lookAt,
      {bool calm = false}) {
    final breath = calm ? 0.0 : _wave(g, .32);
    final blink = calm ? 0.0 : _blink(g);
    late LumoRigFrame f;
    switch (state) {
      case LumoLivingState.greet:
        f = LumoRigFrame(
          headTilt: .05 * _wave(g, .6),
          earLeft: -.10 + .12 * _decay(s, 3) * _wave(s, 3.2),
          earRight: -.08 + .10 * _decay(s, 3) * _wave(s, 3.2, 1),
          tail: .22 * _decay(s, .9) * _wave(g, 2.0) + .08 * _wave(g, 1.1),
          gazeY: -.1,
        );
      case LumoLivingState.listen:
        f = LumoRigFrame(
          headTilt: .075 + .015 * _wave(g, .4),
          earLeft: -.12 + .06 * _twitch(g, 3.1),
          earRight: -.10,
          tail: .06 * _wave(g, .45),
          gazeY: -.15,
        );
      case LumoLivingState.think:
        f = LumoRigFrame(
          headTilt: -.07 + .03 * _wave(g, .25),
          headTurn: -.006,
          earLeft: .08,
          earRight: -.05,
          tail: .08 + .10 * _wave(g, .3),
          gazeX: -.65,
          gazeY: -.55,
        );
      case LumoLivingState.explain:
        f = LumoRigFrame(
          headTilt: .03 * _wave(g, .7),
          headNod: .006 * math.max(0, _wave(g, 2.2)),
          earLeft: -.06,
          earRight: -.06 + .05 * _twitch(g, 4.3),
          tail: .10 * _wave(g, .9),
          gazeX: .7,
          gazeY: .05,
        );
      case LumoLivingState.demonstrate:
        f = LumoRigFrame(
          headTilt: .04,
          earLeft: -.10,
          earRight: -.10,
          tail: .12 * _wave(g, 1.2),
          gazeX: .8,
          gazeY: .2,
        );
      case LumoLivingState.encourage:
        f = LumoRigFrame(
          headTilt: .06,
          headNod: .004 * _wave(g, .8),
          earLeft: .05 - .08 * _decay(s, 1.5),
          earRight: .04,
          tail: .08 * _wave(g, .7),
        );
      case LumoLivingState.approve:
        f = LumoRigFrame(
          headNod: s < 1.2 ? .010 * math.max(0, _wave(s, 2.0)) : 0,
          earLeft: -.08,
          earRight: -.08,
          tail: (.08 + .10 * _decay(s, 1.2)) * _wave(g, 1.8),
        );
      case LumoLivingState.idea:
        f = LumoRigFrame(
          headTilt: .05,
          headNod: -.006,
          earLeft: -.14,
          earRight: -.12,
          tail: .20 * _decay(s, 3) * _wave(s, 3) + .06 * _wave(g, .8),
          gazeX: .6,
          gazeY: -.7,
        );
      case LumoLivingState.celebrate:
        f = LumoRigFrame(
          headTilt: .02 * _wave(g, 1.4),
          earLeft: .15 * _decay(s, 1.2) * _wave(s, 3),
          earRight: .15 * _decay(s, 1.2) * _wave(s, 3, 1.4),
          tail: .28 * _wave(g, 2.4),
          blink: s > .25 && s < .75 ? 1 : 0,
        );
      case LumoLivingState.pause:
        final deep = calm ? 0.0 : _wave(g, .18);
        f = LumoRigFrame(
          headTilt: .04 * deep,
          earLeft: .08,
          earRight: .07,
          tail: .04 * _wave(g, .2),
          breath: deep * 1.8,
          // Ruhig die Augen schließen, Lumo atmet mit dem Kind.
          blink: calm ? 0 : (_wave(g, .18) > .55 ? 1 : 0),
        );
      case LumoLivingState.wait:
        final glance = (g % 7.0) > 5.6;
        f = LumoRigFrame(
          headTilt: .02 * _wave(g, .3),
          earLeft: .05 * _twitch(g, 5.2),
          earRight: 0,
          tail: .05 * _wave(g, .35),
          gazeX: glance ? 0 : .35,
          gazeY: glance ? -.1 : .75,
        );
    }
    final look = lookAt;
    return LumoRigFrame(
      headTilt: f.headTilt,
      headNod: f.headNod,
      headTurn: f.headTurn + (look == null ? 0 : look.dx * .008),
      earLeft: f.earLeft,
      earRight: f.earRight,
      tail: calm ? f.tail.clamp(-.04, .04) : f.tail,
      breath: state == LumoLivingState.pause ? f.breath : breath,
      gazeX: look == null ? f.gazeX : look.dx.clamp(-1.0, 1.0),
      gazeY: look == null ? f.gazeY : look.dy.clamp(-1.0, 1.0),
      blink: math.max(f.blink, blink),
    );
  }

  /// Kurzes Ohrzucken alle [period] Sekunden.
  static double _twitch(double g, double period) {
    final t = g % period;
    return t < .18 ? math.sin(t / .18 * math.pi) : 0;
  }

  static _Body body(LumoLivingState state, double g, double s, double fade) {
    var dx = 1.4 * _wave(g, .14), dy = 0.0, rotation = .010 * _wave(g, .12);
    var sx = 1.0, sy = 1.0, lift = 0.0, effect = 0.0;
    // Kleine Vorfreude beim Posenwechsel: kurz stauchen, dann strecken.
    if (fade < 1) {
      final squash = math.sin(fade * math.pi);
      sy *= 1 - .05 * squash;
      sx *= 1 + .03 * squash;
    }
    switch (state) {
      case LumoLivingState.greet:
        final hop = _jump(s / .7);
        dy += hop.$1 * .06;
        sx *= hop.$2;
        sy *= hop.$3;
        lift = hop.$4;
      case LumoLivingState.celebrate:
        final hop = _jump((s % 1.6) / 1.0);
        dy += hop.$1 * .16;
        sx *= hop.$2;
        sy *= hop.$3;
        lift = hop.$4;
        rotation += .08 * math.sin(s * 2 * math.pi) * _decay(s, 1);
        effect = (s % 1.6) / 1.6;
      case LumoLivingState.idea:
        final hop = _jump(s / .55);
        dy += hop.$1 * .035;
        lift = hop.$4;
        effect = (s % 2.4) / 2.4;
      case LumoLivingState.demonstrate:
        rotation += .03;
        effect = (s % 1.8) / 1.8;
      case LumoLivingState.explain:
        effect = (s % 1.4) / 1.4;
      case LumoLivingState.pause:
        final deep = _wave(g, .18);
        sx *= 1 + .012 * deep;
        sy *= 1 + .018 * deep;
        effect = (g * .18) % 1;
      default:
        break;
    }
    return _Body(
        dx: dx,
        dy: dy,
        rotation: rotation,
        scaleX: sx,
        scaleY: sy,
        lift: lift,
        effect: effect);
  }

  /// Sprung mit Ausholen, Flug und Landung: (dy Anteil der Höhe, sx, sy, lift).
  static (double, double, double, double) _jump(double u) {
    if (u <= 0 || u >= 1) return (0, 1, 1, 0);
    if (u < .2) {
      final s = math.sin(u / .2 * math.pi / 2);
      return (.02 * s, 1 + .07 * s, 1 - .1 * s, 0);
    }
    if (u < .72) {
      final v = (u - .2) / .52;
      final arc = math.sin(v * math.pi);
      final stretch = 1 - (2 * v - 1).abs();
      return (-arc, 1 - .05 * stretch, 1 + .08 * stretch, arc);
    }
    final w = (u - .72) / .28;
    final squash = math.sin(w * math.pi) * (1 - w * .6);
    return (.015 * squash, 1 + .08 * squash, 1 - .1 * squash, 0);
  }
}

class _LumoLivingPainter extends CustomPainter {
  _LumoLivingPainter({
    required this.clock,
    required this.images,
    required this.version,
    required this.faceLeft,
    required this.shadow,
  }) : super(repaint: clock);

  final _LumoClock clock;
  final Map<LumoDesignFoxPose, ui.Image> images;
  final int version;
  final bool faceLeft;
  final bool shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final body = clock.body;
    final w = size.width, h = size.height;
    if (shadow) {
      final s = 1 - .55 * body.lift;
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * .5, h * .955),
            width: w * .5 * s,
            height: h * .06 * s),
        Paint()
          ..color = const Color(0xFF000814).withValues(alpha: .30 * s)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
    canvas.save();
    if (faceLeft) {
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
    }
    _paintEffectBehind(canvas, size);
    canvas.translate(w * .5 + body.dx, h * .98 + body.dy * h);
    canvas.rotate(body.rotation);
    canvas.scale(body.scaleX, body.scaleY);
    canvas.translate(-w * .5, -h * .98);
    final previous = clock.previous;
    if (previous != null && clock.fade < 1) {
      _paintPose(canvas, size, previous.pose, 1 - clock.fade);
    }
    _paintPose(
        canvas, size, clock.state.pose, previous != null ? clock.fade : 1);
    _paintEffectFront(canvas, size);
    canvas.restore();
  }

  void _paintPose(
      Canvas canvas, Size size, LumoDesignFoxPose pose, double opacity) {
    final image = images[pose];
    final rig = LumoFoxRig.of(pose);
    if (image == null || rig == null || opacity <= 0) return;
    final frame = clock.rig;
    final pixels = Size(image.width.toDouble(), image.height.toDouble());
    final paint = Paint()
      ..shader = ui.ImageShader(
          image, TileMode.clamp, TileMode.clamp, _identity,
          filterQuality: FilterQuality.medium)
      ..filterQuality = FilterQuality.medium;
    final faded = opacity < 1;
    canvas.drawVertices(
        LumoFoxMesh.grid(
          source: const Rect.fromLTWH(0, 0, 1, 1),
          imagePixels: pixels,
          canvas: size,
          map: (p) => LumoFoxMesh.deform(rig, frame, p),
          opacity: faded ? (_) => opacity : null,
        ),
        faded ? BlendMode.modulate : BlendMode.srcOver,
        paint);
    for (final eye in [rig.leftEye, rig.rightEye]) {
      if (eye == null) continue;
      // Augen-Teilgitter: Pupillen folgen dem Blick, der Lidschlag verengt.
      final region = Rect.fromLTRB(eye.cx - eye.rx * 1.6, eye.cy - eye.ry * 2.7,
          eye.cx + eye.rx * 1.6, eye.cy + eye.ry * 2.5);
      canvas.drawVertices(
          LumoFoxMesh.grid(
            source: region,
            imagePixels: pixels,
            canvas: size,
            columns: 16,
            rows: 22,
            map: (p) => LumoFoxMesh.deformEye(rig, eye, frame, p),
            opacity: faded ? (_) => opacity : null,
          ),
          faded ? BlendMode.modulate : BlendMode.srcOver,
          paint);
    }
    final lid = LumoFoxMesh.lidOpacity(frame.blink) * opacity;
    if (lid > 0) {
      _paintLid(canvas, size, rig, rig.leftEye, LumoLidSource.left,
          rig.leftLidTint, frame, lid);
      _paintLid(canvas, size, rig, rig.rightEye, LumoLidSource.right,
          rig.rightLidTint, frame, lid);
    }
  }

  /// Lumos eigenes geschlossenes Auge aus der Zwinker-Pose, weich eingepasst.
  void _paintLid(
      Canvas canvas,
      Size size,
      LumoFoxRig rig,
      LumoEyeRig? eye,
      LumoLidSource source,
      List<double> tint,
      LumoRigFrame frame,
      double opacity) {
    final image = images[source.pose];
    if (eye == null || image == null) return;
    final from = source.eye;
    final pixels = Size(image.width.toDouble(), image.height.toDouble());
    final paint = Paint()
      ..shader = ui.ImageShader(
          image, TileMode.clamp, TileMode.clamp, _identity,
          filterQuality: FilterQuality.medium)
      ..colorFilter = ColorFilter.matrix(<double>[
        tint[0], 0, 0, 0, 0, //
        0, tint[1], 0, 0, 0, //
        0, 0, tint[2], 0, 0, //
        0, 0, 0, 1, 0,
      ]);
    canvas.drawVertices(
        LumoFoxMesh.grid(
          source: Rect.fromLTRB(
              from.cx - from.rx * 1.6,
              from.cy - from.ry * 1.6,
              from.cx + from.rx * 1.6,
              from.cy + from.ry * 1.6),
          imagePixels: pixels,
          canvas: size,
          columns: 12,
          rows: 12,
          map: (p) => LumoFoxMesh.deform(
              rig,
              frame,
              Offset(eye.cx + (p.dx - from.cx) * eye.rx / from.rx,
                  eye.cy + (p.dy - from.cy) * eye.ry / from.ry)),
          opacity: (p) {
            final u = (p.dx - from.cx) / from.rx,
                v = (p.dy - from.cy) / from.ry;
            final r = math.sqrt(u * u + v * v);
            return opacity * (1 - ((r - 1.0) / .5).clamp(0.0, 1.0));
          },
        ),
        BlendMode.modulate,
        paint);
  }

  Offset _hand(Size size) {
    final rig = LumoFoxRig.of(clock.state.pose);
    return rig == null
        ? Offset(size.width * .8, size.height * .4)
        : Offset(rig.hand.dx * size.width, rig.hand.dy * size.height);
  }

  void _paintEffectBehind(Canvas canvas, Size size) {
    if (clock.state != LumoLivingState.pause || clock.frozen) return;
    // Atemring: wächst beim Einatmen, schrumpft beim Ausatmen.
    final deep = math.sin(2 * math.pi * .18 * clock.now);
    final radius = size.width * (.36 + .06 * deep);
    canvas.drawCircle(
        Offset(size.width * .5, size.height * .5),
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * .018
          ..color =
              LumoVisualTokens.cyanBright.withValues(alpha: .28 + .12 * deep)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
  }

  void _paintEffectFront(Canvas canvas, Size size) {
    if (clock.frozen) return;
    final e = clock.body.effect;
    switch (clock.state) {
      case LumoLivingState.celebrate:
        _stars(canvas, size, e);
      case LumoLivingState.idea:
        _spark(canvas, _hand(size), size.width, e);
      case LumoLivingState.explain:
      case LumoLivingState.demonstrate:
        final glow = .5 + .5 * math.sin(e * 2 * math.pi);
        canvas.drawCircle(
            _hand(size),
            size.width * (.035 + .02 * glow),
            Paint()
              ..color =
                  LumoVisualTokens.cyanBright.withValues(alpha: .35 + .3 * glow)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      default:
        break;
    }
  }

  void _spark(Canvas canvas, Offset at, double scale, double e) {
    final burst = Curves.easeOutCubic.transform((e * 2.4).clamp(0.0, 1.0));
    final fade = 1 - (e * 2.4).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = LumoVisualTokens.gold.withValues(alpha: .9 * fade)
      ..strokeWidth = scale * .012
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(at + dir * scale * .03 * burst,
          at + dir * scale * (.05 + .05 * burst), paint);
    }
    canvas.drawCircle(
        at,
        scale * .03,
        Paint()
          ..color = LumoVisualTokens.gold.withValues(alpha: .55 + .3 * fade)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
  }

  void _stars(Canvas canvas, Size size, double progress) {
    if (progress <= 0 || progress >= 1) return;
    final center = Offset(size.width / 2, size.height * .38);
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
      final path = Path();
      for (var k = 0; k < 10; k++) {
        final radius = k.isEven ? r : r * .45;
        final a = -math.pi / 2 + k * math.pi / 5;
        final point = p + Offset(math.cos(a), math.sin(a)) * radius;
        k == 0
            ? path.moveTo(point.dx, point.dy)
            : path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path..close(), Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _LumoLivingPainter oldDelegate) =>
      oldDelegate.version != version ||
      oldDelegate.faceLeft != faceLeft ||
      oldDelegate.shadow != shadow;
}

/// Einheitsmatrix für Bild-Shader (Texturkoordinaten in Bildpixeln).
final Float64List _identity = Float64List.fromList(
    <double>[1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);
