import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/lumo_voice.dart';
import '../../../theme/lumo_visual_tokens.dart';
import '../lumo_character.dart';
import 'lumo_actor_library.dart';
import 'lumo_stage_layout.dart';
import 'lumo_stage_targets.dart';

export 'lumo_actor_library.dart';
export 'lumo_stage_targets.dart';

/// Was Lumo auf der Bühne gerade tut.
enum LumoStagePhase { home, toTarget, atTarget, toHome }

/// Ein Auftrag an Lumo: hinlaufen, zeigen, sprechen – oder heimgehen.
@immutable
class LumoStageRequest {
  const LumoStageRequest._(this.serial, this.targetId, this.text, this.delay);
  final int serial;

  /// Null bedeutet: zurück auf den Standardplatz.
  final String? targetId;
  final String? text;
  final Duration delay;
}

/// Steuert Lumo auf der Lernbühne. Die Aufgabe ruft nur [helpAt] und
/// [goHome]; Reaktionen kommen über den vorhandenen [LumoCharacterController].
class LumoStageController extends ChangeNotifier {
  final LumoStageTargets targets = LumoStageTargets();
  LumoStageRequest? _request;
  int _serial = 0;

  LumoStageRequest? get request => _request;

  /// Lumo läuft zu [targetId], zeigt darauf und sagt [text] in seiner Blase.
  void helpAt(String targetId, String text, {Duration delay = Duration.zero}) {
    _request = LumoStageRequest._(++_serial, targetId, text, delay);
    notifyListeners();
  }

  /// Freundlich abbrechen: zurück auf den Standardplatz.
  void goHome() {
    if (_request?.targetId == null && _request != null) return;
    _request = LumoStageRequest._(++_serial, null, null, Duration.zero);
    notifyListeners();
  }

  @override
  void dispose() {
    targets.dispose();
    super.dispose();
  }
}

/// Lumo als ganze Figur über dem Aufgabenbildschirm.
///
/// Er steht auf seinem Standardplatz unten in einer Ecke, läuft bei Bedarf zu
/// dem Aufgabenteil, um den es geht, zeigt darauf, spricht mit Blase und läuft
/// zurück. Er verdeckt nie Aufgabe oder Antworten; Tipps auf Antworten gehen
/// immer durch. Mit „Animationen reduzieren“ blendet er am Ziel ein.
class LumoActorStage extends StatefulWidget {
  const LumoActorStage({
    super.key,
    required this.controller,
    required this.library,
    this.character,
    this.voice,
    this.reduceMotion = false,
    this.offerHelp = false,
    this.onTapLumo,
    this.onAcceptOffer,
    this.greet = true,
  });

  final LumoStageController controller;
  final LumoActorLibrary library;
  final LumoCharacterController? character;
  final LumoVoice? voice;
  final bool reduceMotion;

  /// Das Kind zögert lange: Lumo denkt nach und bietet Hilfe nur an.
  final bool offerHelp;
  final VoidCallback? onTapLumo;
  final VoidCallback? onAcceptOffer;
  final bool greet;

  static const String offerText = 'Brauchst du Hilfe? Tipp mich an!';

  @override
  State<LumoActorStage> createState() => LumoActorStageState();
}

@visibleForTesting
class LumoActorStageState extends State<LumoActorStage>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _repaint = ValueNotifier<int>(0);
  Duration _now = Duration.zero;
  Duration _last = Duration.zero;

  LumoStagePhase _phase = LumoStagePhase.home;
  Offset? _foot;
  Offset? _destination;
  bool _facingRight = false;
  bool _ducked = false;
  bool _walking = false;
  double _runDistance = 0;
  double _talkClock = 0;
  double _opacity = 1;
  Duration? _fadeInFrom;

  LumoActorMotion? _reaction;
  Duration _reactionStart = Duration.zero;
  Duration _reactionEnd = Duration.zero;
  Duration _pointStart = Duration.zero;

  LumoStageRequest? _active;
  Duration? _startAt;
  String? _targetId;
  String? _bubbleText;
  Rect? _bubbleRect;
  Rect? _lastTargetRect;
  Duration _lastPlacement = Duration.zero;
  Duration _arrivedAt = Duration.zero;
  bool _spoke = false;
  Duration? _speechEndedAt;
  int _answerTouches = 0;
  bool _greeted = false;

  LumoStagePhase get phase => _phase;
  Offset? get foot => _foot;
  bool get ducked => _ducked;
  bool get facingRight => _facingRight;
  String? get bubbleText => _bubbleRect == null ? null : _shownText;
  Rect? get bubbleRect => _bubbleRect;
  LumoActorMotion get motion => _currentMotion();

  /// Grundfläche der Figur in Bühnen-Koordinaten (für Prüfungen).
  Rect? get actorRect => _foot == null ? null : _layout?.actorRect(_foot!);

  LumoStageLayout? _layout;
  bool get _still => widget.reduceMotion;

  double get _figureHeight {
    final width = _layout?.stage.width ?? MediaQuery.sizeOf(context).width;
    return width < 600 ? 104 : 120;
  }

  /// Darstellungsmaßstab: Feld-Pixel → dp (Figur ≈ 78 % der Feldhöhe).
  double get _fieldScale => _figureHeight / (widget.library.field.height * .78);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    widget.controller.addListener(_requestChanged);
    widget.controller.targets.addListener(_targetsChanged);
    widget.character?.addListener(_characterChanged);
    widget.voice?.status.addListener(_wake);
    _answerTouches = widget.controller.targets.answerTouches;
    if (widget.controller.request?.targetId != null) _requestChanged();
  }

  @override
  void didUpdateWidget(covariant LumoActorStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.removeListener(_requestChanged);
      oldWidget.controller.targets.removeListener(_targetsChanged);
      widget.controller.addListener(_requestChanged);
      widget.controller.targets.addListener(_targetsChanged);
    }
    if (!identical(oldWidget.character, widget.character)) {
      oldWidget.character?.removeListener(_characterChanged);
      widget.character?.addListener(_characterChanged);
    }
    if (!identical(oldWidget.voice, widget.voice)) {
      oldWidget.voice?.status.removeListener(_wake);
      widget.voice?.status.addListener(_wake);
    }
    _wake();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_requestChanged);
    widget.controller.targets.removeListener(_targetsChanged);
    widget.character?.removeListener(_characterChanged);
    widget.voice?.status.removeListener(_wake);
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  void _wake() {
    if (mounted && !_ticker.isActive) _ticker.start();
  }

  void _requestChanged() {
    final request = widget.controller.request;
    if (request == null || identical(request, _active)) return;
    _active = request;
    if (request.targetId == null) {
      _leave();
    } else {
      _reaction = null;
      _startAt = _now + request.delay;
      _targetId = request.targetId;
      _bubbleText = request.text;
      _bubbleRect = null;
      _lastTargetRect = null;
      _spoke = false;
      _speechEndedAt = null;
      _revealTarget(request.targetId!);
    }
    _wake();
  }

  void _revealTarget(String id) {
    final targetContext = widget.controller.targets.contextOf(id) ??
        widget.controller.targets.contextOf('learning-task');
    if (targetContext == null) return;
    // Ziel mittig zeigen, damit oben und unten Platz für Lumo bleibt.
    Scrollable.ensureVisible(targetContext,
        alignment: .4,
        duration: _still ? Duration.zero : const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic);
  }

  void _targetsChanged() {
    final touches = widget.controller.targets.answerTouches;
    if (touches == _answerTouches) return;
    _answerTouches = touches;
    // Das Kind antwortet: Lumo bricht freundlich ab und geht heim.
    if (_phase == LumoStagePhase.toTarget ||
        _phase == LumoStagePhase.atTarget ||
        _startAt != null) {
      _leave();
    }
  }

  void _leave() {
    _startAt = null;
    _targetId = null;
    _bubbleRect = null;
    _bubbleText = null;
    if (_phase != LumoStagePhase.home) {
      _setPhase(LumoStagePhase.toHome);
    }
    _wake();
  }

  void _characterChanged() {
    final action = widget.character?.pending;
    final motion = switch (action) {
      LumoCharacterAction.cheer ||
      LumoCharacterAction.wiggle =>
        LumoActorMotion.cheer,
      LumoCharacterAction.comfort => LumoActorMotion.comfort,
      LumoCharacterAction.think => LumoActorMotion.think,
      LumoCharacterAction.hello ||
      LumoCharacterAction.wave =>
        LumoActorMotion.wave,
      LumoCharacterAction.talk => LumoActorMotion.talk,
      null => null,
    };
    if (motion == null) return;
    // Reaktionen spielt Lumo an seinem Platz; während einer Hilfe zählt sie.
    if (_phase != LumoStagePhase.home && motion != LumoActorMotion.comfort) {
      return;
    }
    _react(motion);
  }

  void _react(LumoActorMotion motion) {
    final clip = widget.library.clipFor(motion);
    _reaction = motion;
    _reactionStart = _now;
    _reactionEnd = _now +
        (clip.loop || clip.frames < 2
            ? const Duration(milliseconds: 2400)
            : clip.duration + const Duration(milliseconds: 250));
    _wake();
  }

  void _setPhase(LumoStagePhase next) {
    if (_phase == next) return;
    setState(() => _phase = next);
  }

  // ── Takt ─────────────────────────────────────────────────────────────

  void _tick(Duration elapsed) {
    final dt =
        ((elapsed - _last).inMicroseconds / 1000000).clamp(0.0, .1).toDouble();
    _last = elapsed;
    _now = elapsed;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || box.size.isEmpty) return;
    final layout = LumoStageLayout(
        stage: box.size, figureHeight: box.size.width < 600 ? 104 : 120);
    _layout = layout;
    final protectedRects = widget.controller.targets.protectedRects(box);
    final home = layout.freeHome(protectedRects);
    final homeFoot = home ?? layout.homeCandidates().first;
    _foot ??= homeFoot;

    if (!_greeted) {
      _greeted = true;
      if (widget.greet) _react(LumoActorMotion.wave);
    }
    if (_reaction != null && _now >= _reactionEnd) _reaction = null;

    final startAt = _startAt;
    if (startAt != null && _now >= startAt) {
      _startAt = null;
      _setPhase(LumoStagePhase.toTarget);
      _lastPlacement = Duration.zero;
    }

    switch (_phase) {
      case LumoStagePhase.home:
        _setDucked(home == null);
        _moveTowards(homeFoot, dt);
      case LumoStagePhase.toTarget:
      case LumoStagePhase.atTarget:
        _followTarget(layout, box, protectedRects, homeFoot, dt);
      case LumoStagePhase.toHome:
        _setDucked(false);
        if (_moveTowards(homeFoot, dt)) _setPhase(LumoStagePhase.home);
    }

    _updateBubble(layout, protectedRects);
    _repaint.value++;

    final idleStill = _still &&
        _phase == LumoStagePhase.home &&
        _reaction == null &&
        _fadeInFrom == null &&
        _startAt == null &&
        !(widget.voice?.status.value == VoiceStatus.speaking);
    if (idleStill) _ticker.stop();
  }

  void _setDucked(bool value) {
    if (_ducked != value) setState(() => _ducked = value);
  }

  void _followTarget(LumoStageLayout layout, RenderBox box,
      List<Rect> protectedRects, Offset homeFoot, double dt) {
    final id = _targetId ?? 'learning-task';
    final targets = widget.controller.targets;
    final targetRect =
        targets.rectOf(id, box) ?? targets.rectOf('learning-task', box);
    if (targetRect == null) {
      _leave();
      return;
    }
    final moved = _lastTargetRect == null ||
        (targetRect.topLeft - _lastTargetRect!.topLeft).distance > 3 ||
        targetRect.size != _lastTargetRect!.size;
    if (moved || _now - _lastPlacement > const Duration(milliseconds: 400)) {
      _lastTargetRect = targetRect;
      _lastPlacement = _now;
      final others = [
        for (final r in protectedRects)
          if (r != targetRect) r
      ];
      final placement = layout.placeNear(targetRect, others, from: _foot);
      // Kein freier Platz: Lumo hilft von seinem Standardplatz aus.
      _destination = placement?.foot ?? homeFoot;
      if (_phase == LumoStagePhase.atTarget || placement == null) {
        _facingRight = targetRect.center.dx >= _destination!.dx;
      }
    }
    final arrived = _moveTowards(_destination!, dt);
    if (arrived && _phase == LumoStagePhase.toTarget) {
      _facingRight = targetRect.center.dx >= _foot!.dx;
      _arrivedAt = _now;
      _pointStart = _now;
      _setPhase(LumoStagePhase.atTarget);
    }
    if (_phase == LumoStagePhase.atTarget) _considerLeaving();
  }

  void _considerLeaving() {
    final speaking = widget.voice?.status.value == VoiceStatus.speaking;
    if (speaking) {
      _spoke = true;
      _speechEndedAt = null;
      return;
    }
    if (_spoke) {
      _speechEndedAt ??= _now;
      if (_now - _speechEndedAt! > const Duration(milliseconds: 700)) _leave();
      return;
    }
    final words = (_bubbleText ?? '').split(RegExp(r'\s+')).length;
    final reading =
        Duration(milliseconds: (words * 380).clamp(3500, 10000).toInt());
    if (_now - _arrivedAt > reading) _leave();
  }

  /// Bewegt den Fußpunkt; true, wenn Lumo angekommen ist.
  bool _moveTowards(Offset destination, double dt) {
    final foot = _foot!;
    final delta = destination - foot;
    final distance = delta.distance;
    if (distance < .5) {
      _walking = false;
      _foot = destination;
      _finishFade();
      return true;
    }
    if (_still) {
      // Kein Rennen: Lumo blendet am Ziel ein.
      _foot = destination;
      _walking = false;
      _fadeInFrom = _now;
      _opacity = 0;
      return true;
    }
    if (delta.dx.abs() > 1) _facingRight = delta.dx > 0;
    final run = widget.library.clipFor(LumoActorMotion.run);
    final stride = (run.stridePx ?? 120) * _fieldScale;
    final loopSeconds = run.duration.inMicroseconds / 1000000;
    // Schneller laufen heißt schneller treten: die Füße rutschen nie.
    final base = stride / loopSeconds;
    final boost = (distance / (base * 1.4)).clamp(1.0, 2.4);
    final step = math.min(distance, base * boost * dt);
    _foot = foot + delta / distance * step;
    _runDistance += step;
    if (!_walking) setState(() => _walking = true);
    return false;
  }

  void _finishFade() {
    final from = _fadeInFrom;
    if (from == null) {
      _opacity = 1;
      return;
    }
    _opacity = ((_now - from).inMilliseconds / 250).clamp(0.0, 1.0);
    if (_opacity >= 1) _fadeInFrom = null;
  }

  void _updateBubble(LumoStageLayout layout, List<Rect> protectedRects) {
    String? text;
    Rect? target;
    if (_phase == LumoStagePhase.atTarget) {
      text = _bubbleText;
      target = _lastTargetRect;
    } else if (_phase == LumoStagePhase.home &&
        widget.offerHelp &&
        !_ducked &&
        _startAt == null) {
      text = LumoActorStage.offerText;
    }
    Rect? rect;
    if (text != null && text.isNotEmpty && _foot != null) {
      final size = _bubbleSize(text, layout.stage);
      rect = layout.placeBubble(size, _foot!, protectedRects, target: target);
    }
    if (rect == null) text = null;
    if (text != _shownText || rect != _bubbleRect) {
      setState(() {
        _bubbleRect = rect;
        _shownText = text;
      });
    }
  }

  String? _shownText;

  static const _bubbleStyle = TextStyle(
      fontFamily: 'Nunito',
      fontSize: 15,
      height: 1.3,
      fontWeight: FontWeight.w800,
      color: Color(0xFF0B2347));
  static const _bubblePadding = EdgeInsets.fromLTRB(14, 10, 14, 11);
  static const _bubbleMaxLines = 6;

  Size _bubbleSize(String text, Size stage) {
    final maxWidth =
        math.min(280.0, stage.width - 32) - _bubblePadding.horizontal;
    final painter = TextPainter(
      text: TextSpan(text: text, style: _bubbleStyle),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: _bubbleMaxLines,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    final size = Size(painter.width + _bubblePadding.horizontal + 1,
        painter.height + _bubblePadding.vertical + 1);
    painter.dispose();
    return size;
  }

  // ── Bewegung wählen ──────────────────────────────────────────────────

  LumoActorMotion _currentMotion() {
    if (_walking) return LumoActorMotion.run;
    switch (_phase) {
      case LumoStagePhase.toTarget:
      case LumoStagePhase.toHome:
        return LumoActorMotion.idle;
      case LumoStagePhase.atTarget:
        final point = widget.library.clipFor(LumoActorMotion.point);
        final speaking = widget.voice?.status.value == VoiceStatus.speaking;
        if (speaking && _now - _pointStart > point.duration) {
          return LumoActorMotion.talk;
        }
        return LumoActorMotion.point;
      case LumoStagePhase.home:
        final reaction = _reaction;
        if (reaction != null) return reaction;
        if (widget.voice?.status.value == VoiceStatus.speaking) {
          return LumoActorMotion.talk;
        }
        if (widget.offerHelp) return LumoActorMotion.think;
        return LumoActorMotion.idle;
    }
  }

  ({LumoActorClip clip, int frame}) _frame() {
    final motion = _currentMotion();
    final clip = widget.library.clipFor(motion);
    if (_still) {
      final frame = clip.loop ? 0 : clip.frames - 1;
      return (clip: clip, frame: frame);
    }
    switch (motion) {
      case LumoActorMotion.run:
        final stride = (clip.stridePx ?? 120) * _fieldScale;
        final cycle = (_runDistance / stride) % 1.0;
        return (clip: clip, frame: (cycle * clip.frames).floor());
      case LumoActorMotion.talk:
        // Der Mund läuft nur, solange echter Ton zu hören ist.
        final mouth = widget.voice?.clipMouth.value;
        if (mouth == null || mouth > .06) _talkClock += 1 / 60;
        return (
          clip: clip,
          frame:
              clip.frameAt(Duration(microseconds: (_talkClock * 1e6).round()))
        );
      case LumoActorMotion.point:
        return (clip: clip, frame: clip.frameAt(_now - _pointStart));
      default:
        final start = _reaction == motion ? _reactionStart : Duration.zero;
        return (clip: clip, frame: clip.frameAt(_now - start));
    }
  }

  // ── Darstellung ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final layout = _layout;
    final foot = _foot;
    final actor =
        layout != null && foot != null ? layout.actorRect(foot) : null;
    final bubble = _bubbleRect;
    final tappable =
        actor != null && _phase == LumoStagePhase.home && !_ducked && !_walking;
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                key: const ValueKey('lumo-actor-stage-paint'),
                painter: _ActorPainter(this, repaint: _repaint),
              ),
            ),
          ),
        ),
        if (bubble != null && _shownText != null)
          Positioned.fromRect(
            rect: bubble,
            child: IgnorePointer(
              child: _SpeechBubble(
                key: const ValueKey('lumo-stage-bubble'),
                text: _shownText!,
                style: _bubbleStyle,
                padding: _bubblePadding,
                maxLines: _bubbleMaxLines,
                tailRight: foot != null && foot.dx > bubble.center.dx,
              ),
            ),
          ),
        if (tappable)
          Positioned.fromRect(
            rect: actor,
            child: Semantics(
              button: true,
              label: widget.offerHelp
                  ? 'Lumo, dein Lernfuchs. Hilfe annehmen'
                  : 'Lumo, dein Lernfuchs. Hilfe und Ideen öffnen',
              child: GestureDetector(
                key: const ValueKey('lumo-stage-actor'),
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (widget.offerHelp && widget.onAcceptOffer != null) {
                    widget.onAcceptOffer!();
                  } else {
                    widget.onTapLumo?.call();
                  }
                },
              ),
            ),
          ),
      ],
    );
  }

  void _paint(Canvas canvas, Size size) {
    final foot = _foot;
    if (foot == null) return;
    final library = widget.library;
    final scale = _fieldScale;
    var drawFoot = foot;
    var opacity = _opacity;
    if (_ducked && _phase == LumoStagePhase.home) {
      // Beide Ecken belegt: Lumo duckt sich unter den Rand und schaut nur hervor.
      drawFoot = foot + Offset(0, _figureHeight * .62);
      opacity *= .8;
    }
    if (opacity <= 0) return;
    final (:clip, :frame) = _frame();
    final fieldSize = library.field;
    final dest = Rect.fromLTWH(
        drawFoot.dx - library.anchor.dx * scale,
        drawFoot.dy - library.anchor.dy * scale,
        fieldSize.width * scale,
        fieldSize.height * scale);
    final paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..color = Color.fromRGBO(255, 255, 255, opacity);
    final shadow = library.shadow;
    if (shadow != null) {
      canvas.drawImageRect(
          shadow,
          Offset.zero & Size(shadow.width.toDouble(), shadow.height.toDouble()),
          dest,
          paint);
    }
    canvas.save();
    if (!_facingRight) {
      canvas.translate(drawFoot.dx, 0);
      canvas.scale(-1, 1);
      canvas.translate(-drawFoot.dx, 0);
    }
    canvas.drawImageRect(
        clip.image, clip.sourceRect(frame, fieldSize), dest, paint);
    canvas.restore();
  }
}

class _ActorPainter extends CustomPainter {
  _ActorPainter(this.state, {required Listenable repaint})
      : super(repaint: repaint);
  final LumoActorStageState state;

  @override
  void paint(Canvas canvas, Size size) => state._paint(canvas, size);

  @override
  bool shouldRepaint(covariant _ActorPainter oldDelegate) =>
      !identical(oldDelegate.state, state);
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({
    super.key,
    required this.text,
    required this.style,
    required this.padding,
    required this.maxLines,
    required this.tailRight,
  });

  final String text;
  final TextStyle style;
  final EdgeInsets padding;
  final int maxLines;
  final bool tailRight;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF4FBFF),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(tailRight ? 18 : 5),
            bottomRight: Radius.circular(tailRight ? 5 : 18),
          ),
          border: Border.all(color: LumoVisualTokens.cyanBright, width: 2),
          boxShadow: const [
            BoxShadow(
                color: Color(0x6637D2FD), blurRadius: 14, spreadRadius: 1),
          ],
        ),
        child: Padding(
          padding: padding,
          child: Text(text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: style),
        ),
      );
}
