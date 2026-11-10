import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_learning_module_frame.dart';
import '../../widgets/design/lumo_quantity_art.dart';

/// The same objects move from the second group into a real ten-frame.
/// Playback is local, finite and controlled by the child; no video service.
class GuidedTenFrameAnimation extends StatefulWidget {
  const GuidedTenFrameAnimation({
    super.key,
    required this.left,
    required this.right,
    required this.reduceMotion,
  }) : assert(left > 0 && left < 10 && right > 0 && right <= 10 &&
            left + right > 10);

  final int left;
  final int right;
  final bool reduceMotion;

  @override
  State<GuidedTenFrameAnimation> createState() => _GuidedTenFrameAnimationState();
}

class _GuidedTenFrameAnimationState extends State<GuidedTenFrameAnimation>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _duration = Duration(seconds: 8);
  static const _stops = [0.0, .18, .36, .64, .82, 1.0];
  static const _text = TextStyle(
      color: LumoVisualTokens.white,
      fontFamily: 'Nunito',
      fontSize: 16,
      height: 1.35,
      fontWeight: FontWeight.w800);
  late final AnimationController _playback;
  bool _slow = false;

  int get _gap => 10 - widget.left;
  int get _remainder => widget.left + widget.right - 10;
  int get _phase => _stops.lastIndexWhere((stop) => _playback.value >= stop);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _playback = AnimationController(vsync: this, duration: _duration)
      ..addListener(_changed);
    if (widget.reduceMotion) {
      _playback.value = 1;
    } else {
      _playback.forward();
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(GuidedTenFrameAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.left != oldWidget.left || widget.right != oldWidget.right) {
      _playback.stop();
      _playback.value = widget.reduceMotion ? 1 : 0;
      if (!widget.reduceMotion) _playback.forward();
    } else if (widget.reduceMotion && !oldWidget.reduceMotion) {
      _playback.stop();
      _playback.value = 1;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      // Returning never skips the explanation or restarts against the child's
      // choice. The visible play button resumes from this exact position.
      _playback.stop();
      if (mounted) setState(() {});
    }
  }

  void _togglePlayback() {
    if (_playback.isAnimating) {
      _playback.stop();
    } else {
      if (_playback.isCompleted) _playback.value = 0;
      _playback.forward();
    }
    setState(() {});
  }

  void _seek(int direction) {
    _playback.stop();
    final value = _playback.value;
    final next = direction > 0
        ? _stops.firstWhere((stop) => stop > value + .001, orElse: () => 1.0)
        : _stops.lastWhere((stop) => stop < value - .001, orElse: () => 0.0);
    _playback.value = next;
    setState(() {});
  }

  String get _caption => switch (_phase) {
        0 => '${widget.left} Äpfel sind im Zehnerfeld. '
            '${widget.right} kommen dazu.',
        1 => 'Im Zehnerfeld sind noch $_gap Plätze frei.',
        2 => 'Schiebe $_gap von den ${widget.right} Äpfeln in die freien Plätze.',
        3 => 'Der Zehner ist voll: ${widget.left} + $_gap = 10.',
        4 => 'Daneben bleiben $_remainder Äpfel. Keiner geht verloren.',
        _ => '${widget.left} + $_gap + $_remainder = '
            '${widget.left + widget.right}. Ein Zehner und $_remainder Einer.',
      };

  @override
  Widget build(BuildContext context) => LumoLessonSurface(
        padding: const EdgeInsets.all(10),
        child: LayoutBuilder(builder: (context, constraints) {
          final cell = math.min(54.0, (constraints.maxWidth - 20) / 8);
          final sourceX = cell * 5 + 12;
          final height = math.max(cell * 2, (widget.right / 3).ceil() * cell) + 6;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${widget.left} + ${widget.right}',
                  style: _text.copyWith(fontSize: 26), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Semantics(
                label: '${widget.left + widget.right} Äpfel insgesamt. $_caption',
                excludeSemantics: true,
                child: SizedBox(
                  height: height,
                  child: Stack(children: [
                    for (var index = 0; index < 10; index++)
                      Positioned(
                        left: (index % 5) * cell,
                        top: (index ~/ 5) * cell,
                        width: cell - 3,
                        height: cell - 3,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFF103966),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                width: _phase >= 3 ? 2 : 1,
                                color: _phase >= 3
                                    ? LumoVisualTokens.gold
                                    : LumoVisualTokens.cyan.withValues(alpha: .55)),
                          ),
                        ),
                      ),
                    for (var index = 0; index < widget.left + widget.right; index++)
                      _apple(index, cell, sourceX),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              Text(_caption, key: const ValueKey('ten-frame-caption'), style: _text),
              const SizedBox(height: 8),
              Text('Schritt ${_phase + 1} von ${_stops.length}', style: _text),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 8, children: [
                _button('ten-frame-back', 'Zurück', Icons.skip_previous_rounded,
                    _playback.value > 0 ? () => _seek(-1) : null),
                if (!widget.reduceMotion)
                  _button('ten-frame-play',
                      _playback.isAnimating ? 'Pause' : 'Abspielen',
                      _playback.isAnimating ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      _togglePlayback),
                _button('ten-frame-next', 'Ein Schritt', Icons.skip_next_rounded,
                    _playback.value < 1 ? () => _seek(1) : null),
                _button('ten-frame-replay', 'Von vorne', Icons.replay_rounded, () {
                  _playback.stop();
                  _playback.value = 0;
                  setState(() {});
                }),
                if (!widget.reduceMotion)
                  _button('ten-frame-speed', _slow ? 'Tempo: langsam' : 'Tempo: normal',
                      Icons.slow_motion_video_rounded, () {
                    final playing = _playback.isAnimating;
                    _playback.stop();
                    _slow = !_slow;
                    _playback.duration = _slow ? _duration * 2 : _duration;
                    if (playing) _playback.forward();
                    setState(() {});
                  }),
              ]),
            ],
          );
        }),
      );

  Widget _button(String key, String label, IconData icon, VoidCallback? action) =>
      OutlinedButton.icon(
        key: ValueKey(key),
        onPressed: action,
        style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: LumoVisualTokens.white,
            side: const BorderSide(color: LumoVisualTokens.cyan)),
        icon: Icon(icon, size: 20),
        label: Text(label),
      );

  Widget _apple(int index, double cell, double sourceX) {
    final next = index - widget.left;
    final start = index < widget.left
        ? Offset((index % 5) * cell, (index ~/ 5) * cell)
        : Offset(sourceX + (next % 3) * cell, (next ~/ 3) * cell);
    final destination = index < 10
        ? Offset((index % 5) * cell, (index ~/ 5) * cell)
        : Offset(sourceX + ((next - _gap) % 3) * cell,
            ((next - _gap) ~/ 3) * cell);
    // Fill the empty cells one by one. Only then regroup the remaining apples.
    final progress = index < widget.left
        ? 0.0
        : index < 10
            ? ((_playback.value - .36) / .28 * _gap - next).clamp(0.0, 1.0)
            : ((_playback.value - .64) / .18).clamp(0.0, 1.0);
    final position = Offset.lerp(
        start, destination, Curves.easeInOutCubic.transform(progress))!;
    return Positioned(
      key: ValueKey('guided-bridge-apple-$index'),
      left: position.dx,
      top: position.dy,
      width: cell - 3,
      height: cell - 3,
      child: LumoQuantityArt.apple(size: cell - 3),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playback.dispose();
    super.dispose();
  }
}
