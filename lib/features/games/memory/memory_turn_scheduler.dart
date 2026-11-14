import 'dart:async';
import 'dart:math' as math;

/// One bounded turn callback. A cancelled generation can never finish a new
/// board; partial elapsed time is returned for the authoritative pause save.
class MemoryTurnScheduler {
  MemoryTurnScheduler({
    int Function()? milliseconds,
    Timer Function(Duration, void Function())? createTimer,
  }) : _milliseconds = milliseconds ?? _monotonicClock(),
       _createTimer = createTimer ?? ((delay, action) => Timer(delay, action));

  static int Function() _monotonicClock() {
    final clock = Stopwatch()..start();
    return () => clock.elapsedMilliseconds;
  }
  final int Function() _milliseconds;
  final Timer Function(Duration, void Function()) _createTimer;
  Timer? _timer;
  int _generation = 0;
  int _started = 0;
  int _duration = 0;
  bool _disposed = false;

  void schedule(int duration, void Function(int elapsed) complete) {
    cancelElapsed();
    if (_disposed || duration <= 0 || duration > 900) {
      if (_disposed) return;
      throw ArgumentError.value(duration, 'duration');
    }
    final generation = ++_generation;
    _duration = duration;
    _started = _milliseconds();
    _timer = _createTimer(Duration(milliseconds: duration), () {
      if (_disposed || generation != _generation) return;
      _timer = null;
      _duration = 0;
      complete(duration);
    });
  }

  int cancelElapsed() {
    _generation++;
    _timer?.cancel();
    _timer = null;
    final elapsed = _duration == 0 ? 0 :
        math.max(0, math.min(_duration, _milliseconds() - _started));
    _duration = 0;
    return elapsed;
  }

  void dispose() {
    cancelElapsed();
    _disposed = true;
  }
}
