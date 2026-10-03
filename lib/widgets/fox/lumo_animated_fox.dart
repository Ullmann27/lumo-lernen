import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/lumo_voice.dart';
import '../../core/lumo_asset_diagnostics.dart';

/// The original sheets contain complete foxes. Their cells are NOT equally
/// spaced: the old pre-cut PNGs cut off faces and included neighbouring tails.
/// These bounds follow each visible silhouette, with a shared ground line.
class LumoFoxFrames {
  static const runAsset =
      'assets/lumo_jump/fox/sprite_sheets/fox_run_sheet_transparent.png';
  static const idleAsset =
      'assets/lumo_jump/fox/sprite_sheets/fox_idle_sheet_transparent.png';
  static const run = <Rect>[
    Rect.fromLTRB(13, 276, 193, 491),
    Rect.fromLTRB(206, 280, 380, 488),
    // Original cells 3/4 overlap at their outlines; skip these two cells.
    Rect.fromLTRB(721, 288, 900, 491),
    Rect.fromLTRB(904, 288, 1066, 491),
    Rect.fromLTRB(1076, 281, 1256, 486),
    Rect.fromLTRB(1267, 284, 1439, 490),
    Rect.fromLTRB(1441, 279, 1610, 489),
    Rect.fromLTRB(1616, 284, 1778, 491),
    Rect.fromLTRB(1786, 283, 1957, 482),
    Rect.fromLTRB(1962, 279, 2136, 489),
  ];
  static const idle = <Rect>[
    Rect.fromLTRB(52, 131, 305, 584),
    Rect.fromLTRB(327, 130, 576, 584),
    Rect.fromLTRB(586, 131, 834, 584),
    Rect.fromLTRB(851, 131, 1098, 584),
    Rect.fromLTRB(1111, 131, 1356, 584),
    Rect.fromLTRB(1373, 131, 1618, 584),
    Rect.fromLTRB(1623, 131, 1867, 584),
    Rect.fromLTRB(1884, 131, 2132, 584),
  ];
}

/// Expressions use the same complete fox and anchored, small movements.
/// This is a 2D sprite animation, not a 3D skeleton or phoneme lip-sync.
enum LumoFoxExpression { idle, greet, think, explain, celebrate, comfort }

class LumoAnimatedFox extends StatefulWidget {
  const LumoAnimatedFox({
    super.key,
    required this.moving,
    this.facingRight = true,
    this.reducedMotion = false,
    this.active = true,
    this.voiceEnabled = false,
    this.expression = LumoFoxExpression.idle,
    this.size = 76,
  });

  final bool moving;
  final bool facingRight;
  final bool reducedMotion;
  final bool active;
  final bool voiceEnabled;
  final LumoFoxExpression expression;
  final double size;

  @override
  State<LumoAnimatedFox> createState() => _LumoAnimatedFoxState();
}

class _FoxArt {
  _FoxArt(this.run, this.idle, this.cheer);
  final ui.Image run, idle;
  final List<ui.Image> cheer;

  // One bounded cache for every avatar, instead of decoding the large sheets
  // separately for the floor, answer reactions and writing coach.
  static Future<_FoxArt>? _cache;
  static _FoxArt? _ready;
  static Future<_FoxArt> load() {
    if (_ready != null) return Future.value(_ready);
    return _cache ??= _load().then((art) {
      _ready = art;
      return art;
    });
  }

  static Future<ui.Image> _image(String path) async {
    try {
      final bytes = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List(
        bytes.offsetInBytes,
        bytes.lengthInBytes,
      ));
      try {
        return (await codec.getNextFrame()).image;
      } finally {
        codec.dispose();
      }
    } catch (error) {
      reportLumoAssetError(path, error);
      rethrow;
    }
  }

  static Future<_FoxArt> _load() async {
    final images = await Future.wait([
      _image(LumoFoxFrames.runAsset),
      _image(LumoFoxFrames.idleAsset),
      for (var frame = 1; frame <= 8; frame++)
        _image(
            'assets/lumo_sprite_pack/cheer/cheer_${frame.toString().padLeft(2, '0')}.png'),
    ]);
    return _FoxArt(images[0], images[1], images.sublist(2));
  }
}

class _LumoAnimatedFoxState extends State<LumoAnimatedFox>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  );
  late final AnimationController _transition = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  );
  late final AnimationController _word = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    value: 1,
  );
  _FoxArt? _art;
  bool _foreground = true;
  bool _previousMoving = false;
  bool _nativeWords = false;
  LumoFoxExpression _previousExpression = LumoFoxExpression.idle;
  double _expressionStart = 0;
  double _previousExpressionStart = 0;

  bool get _quiet =>
      widget.reducedMotion ||
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
  bool get _animate =>
      widget.active && _foreground && TickerMode.of(context) && !_quiet;
  bool get _speaking =>
      widget.voiceEnabled &&
      LumoVoice.instance.isEnabled &&
      LumoVoice.instance.status.value == VoiceStatus.speaking;
  double get _elapsed => _clock.value * 60;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    LumoVoice.instance.status.addListener(_voiceChanged);
    LumoVoice.instance.spokenWordRevision.addListener(_wordChanged);
    _previousMoving = widget.moving;
    _previousExpression = widget.expression;
    _load();
  }

  Future<void> _load() async {
    try {
      final art = await _FoxArt.load();
      if (mounted) setState(() => _art = art);
    } catch (_) {
      // The complete original master is still an offline fallback.
    }
  }

  void _voiceChanged() {
    if (!mounted) return;
    _nativeWords = false;
    if (_speaking && _animate) {
      _word.forward(from: 0);
    } else {
      _word.stop();
      _word.value = 1;
    }
    setState(() {});
  }

  void _wordChanged() {
    if (!mounted || !_speaking || !_animate) return;
    _nativeWords = true;
    _word.forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant LumoAnimatedFox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.moving != widget.moving ||
        oldWidget.expression != widget.expression) {
      _previousMoving = oldWidget.moving;
      _previousExpression = oldWidget.expression;
      _previousExpressionStart = _expressionStart;
      _expressionStart = _elapsed;
      if (_animate) {
        _transition.forward(from: 0);
      } else {
        _transition.value = 1;
      }
    }
    _syncMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (mounted) setState(_syncMotion);
  }

  void _syncMotion() {
    if (!_animate) {
      _clock.stop();
      _transition.stop();
      _word.stop();
      if (_quiet) {
        _clock.value = 0;
        _transition.value = 1;
      }
    } else {
      if (!_clock.isAnimating) _clock.repeat();
      if (!_transition.isAnimating && _transition.value < 1) {
        _transition.forward();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LumoVoice.instance.status.removeListener(_voiceChanged);
    LumoVoice.instance.spokenWordRevision.removeListener(_wordChanged);
    _clock.dispose();
    _transition.dispose();
    _word.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_art == null) {
      return Image.asset(
        'assets/lumo_jump/fox/master/lumo_fox_master_512.png',
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
        errorBuilder: (_, error, __) {
          reportLumoAssetError(
              'assets/lumo_jump/fox/master/lumo_fox_master_512.png', error);
          return SizedBox.square(dimension: widget.size);
        },
      );
    }
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_clock, _transition, _word]),
        builder: (context, _) {
          final seconds = (_elapsed - _expressionStart + 60) % 60;
          final mouth = !_animate || !_speaking
              ? 0.0
              : _nativeWords
                  ? math.sin(_word.value * math.pi)
                  :
                  // Some offline TTS engines report start/end but no word events.
                  // Their actual speaking status still gates this approximation.
                  .25 + .65 * math.pow(math.sin(_elapsed * 9), 2);
          final sample = LumoFoxMotionSample(
            elapsed: _quiet ? 0 : _elapsed,
            expressionSeconds: seconds,
            moving: widget.moving && !_quiet,
            expression: widget.expression,
            mouth: mouth.toDouble(),
            reducedMotion: _quiet,
          );
          return CustomPaint(
            key: const ValueKey('lumo-animated-fox-paint'),
            size: Size.square(widget.size),
            painter: LumoFoxPainter._(
              art: _art!,
              sample: sample,
              previousMoving: _previousMoving && !_quiet,
              previousExpression: _previousExpression,
              previousExpressionSeconds:
                  (_elapsed - _previousExpressionStart + 60) % 60,
              blend: Curves.easeInOut.transform(_transition.value),
              facingRight: widget.facingRight,
            ),
          );
        },
      ),
    );
  }
}

@immutable
class LumoFoxMotionSample {
  const LumoFoxMotionSample(
      {required this.elapsed,
      required this.expressionSeconds,
      required this.moving,
      required this.expression,
      required this.mouth,
      required this.reducedMotion});
  final double elapsed, expressionSeconds, mouth;
  final bool moving, reducedMotion;
  final LumoFoxExpression expression;

  bool get celebrating =>
      expression == LumoFoxExpression.celebrate &&
      expressionSeconds < 1.4 &&
      !reducedMotion;
  double get breath =>
      reducedMotion || moving ? 1 : 1 + math.sin(elapsed * 1.9) * .006;
  double get headAngle => reducedMotion
      ? 0
      : expression == LumoFoxExpression.think
          ? -.025 + math.sin(elapsed * 1.7) * .008
          : expression == LumoFoxExpression.comfort
              ? .016
              : math.sin(elapsed * 1.1) * .008;
  double get tailAngle => reducedMotion
      ? 0
      : math.sin(elapsed * 2) *
          (expression == LumoFoxExpression.greet ? .055 : .025);
  double get pawAngle => reducedMotion
      ? 0
      : expression == LumoFoxExpression.greet && expressionSeconds < 2
          ? -.09 * math.sin(expressionSeconds * math.pi * 3)
          : expression == LumoFoxExpression.explain
              ? -.05 * (.5 + .5 * math.sin(elapsed * 2))
              : 0;
}

/// Shared ground line and subtle anchored head/paw/tail motion preserve the
/// complete silhouette. Mode changes blend for 220ms; legs are never rotated
/// separately or scaled into an artificial bend.
class LumoFoxPainter extends CustomPainter {
  const LumoFoxPainter._(
      {required _FoxArt art,
      required this.sample,
      required this.previousMoving,
      required this.previousExpression,
      required this.previousExpressionSeconds,
      required this.blend,
      required this.facingRight})
      : _art = art;
  final _FoxArt _art;
  final LumoFoxMotionSample sample;
  final bool previousMoving, facingRight;
  final LumoFoxExpression previousExpression;
  final double blend;
  final double previousExpressionSeconds;

  static const _cheerBounds = <Rect>[
    Rect.fromLTRB(60, 82, 452, 468),
    Rect.fromLTRB(60, 82, 452, 468),
    Rect.fromLTRB(60, 82, 452, 468),
    Rect.fromLTRB(60, 82, 452, 468),
    Rect.fromLTRB(60, 82, 452, 468),
    Rect.fromLTRB(60, 82, 452, 468),
    Rect.fromLTRB(60, 82, 452, 468),
    Rect.fromLTRB(60, 82, 452, 468),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(size.width / 2, size.height - 3),
          width: size.width * .46,
          height: 4),
      Paint()..color = const Color(0x260F2855),
    );
    canvas.saveLayer(Offset.zero & size, Paint());
    if (blend < 1) {
      _paintMode(canvas, size, previousMoving, previousExpression, 1 - blend,
          expressionSeconds: previousExpressionSeconds);
    }
    _paintMode(canvas, size, sample.moving, sample.expression, blend,
        additive: blend < 1);
    canvas.restore();
  }

  void _paintMode(Canvas canvas, Size size, bool moving,
      LumoFoxExpression expression, double opacity,
      {bool additive = false, double? expressionSeconds}) {
    if (opacity <= 0) return;
    canvas.saveLayer(
        Offset.zero & size,
        Paint()
          ..color = Color.fromRGBO(255, 255, 255, opacity)
          ..blendMode = additive ? BlendMode.plus : BlendMode.srcOver);
    if (moving) {
      final frame = (sample.elapsed * 14).floor() % LumoFoxFrames.run.length;
      final source = LumoFoxFrames.run[frame];
      final scale = size.height * .94 / 225;
      final width = source.width * scale;
      final height = source.height * scale;
      if (!facingRight) {
        canvas.translate(size.width, 0);
        canvas.scale(-1, 1);
      }
      canvas.drawImageRect(
          _art.run,
          source,
          Rect.fromLTWH((size.width - width) / 2, size.height - height - 3,
              width, height),
          Paint()..filterQuality = FilterQuality.medium);
    } else if (expression == LumoFoxExpression.celebrate &&
        (expressionSeconds ?? sample.expressionSeconds) < 1.4 &&
        !sample.reducedMotion) {
      // One short celebration, then return to breathing while the app is still
      // showing its success text. No endlessly jumping success pose.
      final seconds = expressionSeconds ?? sample.expressionSeconds;
      final frame = (seconds * 7).floor().clamp(0, 7);
      final settle = ((seconds - 1.1) / .3).clamp(0.0, 1.0);
      final bounce = math.sin(seconds / 1.4 * math.pi) * size.height * .025;
      final height = size.height * .90;
      canvas.drawImageRect(
          _art.cheer[frame],
          _cheerBounds[frame],
          Rect.fromLTWH((size.width - height) / 2,
              size.height - height - 3 - bounce, height, height),
          Paint()
            ..filterQuality = FilterQuality.medium
            ..color = Colors.white.withOpacity(1 - settle));
      if (settle > 0) {
        _paintIdle(canvas, size, 0, settle,
            additive: true, expression: LumoFoxExpression.idle);
      }
    } else {
      final phase = sample.elapsed % 6;
      var from = 0, to = 0;
      var mix = 0.0;
      if (!sample.reducedMotion) {
        if (phase >= 2.6 && phase < 2.72) {
          to = 2;
          mix = (phase - 2.6) / .12;
        } else if (phase >= 2.72 && phase < 2.84) {
          from = 2;
          mix = (phase - 2.72) / .12;
        } else if (phase >= 4.4 && phase < 4.6) {
          to = expression == LumoFoxExpression.think ? 1 : 7;
          mix = (phase - 4.4) / .2;
        } else if (phase >= 4.6 && phase < 5) {
          from = to = expression == LumoFoxExpression.think ? 1 : 7;
        } else if (phase >= 5 && phase < 5.2) {
          from = expression == LumoFoxExpression.think ? 1 : 7;
          mix = (phase - 5) / .2;
        }
      }
      _paintIdle(canvas, size, from, 1 - mix, expression: expression);
      if (mix > 0) {
        _paintIdle(canvas, size, to, mix,
            additive: true, expression: expression);
      }
    }
    canvas.restore();
  }

  void _paintIdle(Canvas canvas, Size size, int frame, double opacity,
      {bool additive = false, required LumoFoxExpression expression}) {
    if (opacity <= 0) return;
    final source = LumoFoxFrames.idle[frame];
    const body = Rect.fromLTWH(0, 0, 253, 453);
    final pose = LumoFoxMotionSample(
      elapsed: sample.elapsed,
      expressionSeconds: expression == previousExpression && blend < 1
          ? previousExpressionSeconds
          : sample.expressionSeconds,
      moving: false,
      expression: expression,
      mouth: sample.mouth,
      reducedMotion: sample.reducedMotion,
    );
    final scale = size.height * .94 / 470;
    canvas.saveLayer(
        Offset.zero & size,
        Paint()
          ..color = Color.fromRGBO(255, 255, 255, opacity)
          ..blendMode = additive ? BlendMode.plus : BlendMode.srcOver);
    canvas.translate((size.width - body.width * scale) / 2,
        size.height - body.height * scale * sample.breath - 3);
    canvas.scale(scale, scale * sample.breath);
    final head = Path()..addRect(const Rect.fromLTWH(0, 0, 253, 199));
    final tail = Path()
      ..moveTo(160, 292)
      ..lineTo(187, 263)
      ..lineTo(253, 247)
      ..lineTo(253, 404)
      ..lineTo(171, 405)
      ..lineTo(160, 354)
      ..close();
    final paw = Path()..addRect(const Rect.fromLTWH(0, 244, 50, 103));
    var torso = Path()..addRect(body);
    for (final part in [head, tail, paw]) {
      torso = Path.combine(PathOperation.difference, torso, part);
    }
    void image() => canvas.drawImageRect(
        _art.idle, source, body, Paint()..filterQuality = FilterQuality.medium);
    void part(Path mask, Offset pivot, double angle, {bool mouth = false}) {
      canvas.save();
      canvas.translate(pivot.dx, pivot.dy);
      canvas.rotate(angle);
      canvas.translate(-pivot.dx, -pivot.dy);
      canvas.clipPath(mask);
      image();
      if (mouth) {
        // A feathered muzzle patch avoids rectangular texture seams. The
        // mouth follows the character's original angled smile and only opens
        // during actual TTS. Native word boundaries drive its envelope.
        canvas.drawOval(
          const Rect.fromLTWH(52, 152, 57, 29),
          Paint()
            ..shader = ui.Gradient.linear(
                const Offset(0, 152),
                const Offset(0, 181),
                const [Color(0xFFF5DCC3), Color(0xFFEDD0B4)])
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4),
        );
        final smile = Path()
          ..moveTo(59, 160)
          ..quadraticBezierTo(79, 166, 103, 157);
        if (sample.mouth > .04) {
          smile
            ..quadraticBezierTo(
                87, 168 + 13 * sample.mouth, 72, 164 + 13 * sample.mouth)
            ..quadraticBezierTo(61, 167, 59, 160)
            ..close();
          canvas.drawPath(smile, Paint()..color = const Color(0xFF45251E));
          canvas.drawOval(
              Rect.fromLTWH(73, 166 + 7 * sample.mouth, 13 * sample.mouth,
                  4 * sample.mouth),
              Paint()..color = const Color(0xFFD58484));
        } else {
          canvas.drawPath(
              smile,
              Paint()
                ..color = const Color(0xFF6B4633)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.8
                ..strokeCap = StrokeCap.round);
        }
      }
      canvas.restore();
    }

    part(tail, const Offset(162, 327), pose.tailAngle);
    canvas.save();
    canvas.clipPath(torso);
    image();
    canvas.restore();
    part(paw, const Offset(43, 240), pose.pawAngle);
    part(head, const Offset(106, 195), pose.headAngle, mouth: true);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LumoFoxPainter old) =>
      old.sample != sample ||
      old.blend != blend ||
      old.facingRight != facingRight ||
      old.previousMoving != previousMoving ||
      old.previousExpression != previousExpression;
}
