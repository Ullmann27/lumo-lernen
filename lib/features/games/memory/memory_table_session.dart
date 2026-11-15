import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import '../../lumo3d/native_table_transport.dart';
import 'memory_round.dart';
import 'memory_rules.dart';

/// A bounded transport for the existing Dart round. No hidden deck or
/// opponent memory is published. The renderer can submit intentions only.
class MemoryTableSession {
  MemoryTableSession({
    required this.controller,
    required this.transport,
    this.reduceMotion = false,
    String? token,
    DateTime Function()? now,
    int Function()? monotonicMilliseconds,
  }) : token = token ?? MemoryRound.newId(),
       _now = now ?? DateTime.now {
    if (!RegExp(r'^[a-f0-9]{32}$').hasMatch(this.token)) {
      throw ArgumentError('Ungültige Memory-Verbindung');
    }
    _monotonic = monotonicMilliseconds ?? () => _watch.elapsedMilliseconds;
  }

  final MemoryRoundController controller;
  final NativeTableTransport transport;
  final String token;
  final bool reduceMotion;
  final DateTime Function() _now;
  final Stopwatch _watch = Stopwatch()..start();
  late final int Function() _monotonic;
  Timer? _timer;
  bool _open = false;
  bool _opening = false;
  int _generation = 0;
  bool _busy = false;
  bool _active = false;
  bool _exit = false;
  int _revision = 1;
  int _ack = 0;
  int _rejected = 0;
  int _pauseEpoch = 0;
  int _lastTick = 0;
  int _elapsed = 0;
  String? _error;
  Future<void>? _closing;

  bool get isOpen => _open;
  bool get paused => !_active || controller.round.paused;
  bool get interactive => _open && !paused && !_exit;

  Map<String, Object?> get view => {
    'schema': 1, 'game': 'memory', 'token': token,
    'owner': controller.owner, 'roundId': controller.round.id,
    'revision': _revision, 'recordRevision': controller.round.revision,
    'ack': _ack, 'rejected': _rejected,
    'paused': paused, 'exit': _exit, 'reduceMotion': reduceMotion,
    'rewarded': controller.round.rewarded,
    ...controller.state.publicState,
    'canFlip': interactive && controller.state.canFlip,
    'best': controller.best,
    'error': _error,
  };

  Future<void> open({bool automaticPolling = true}) async {
    if (_open || _opening || _closing != null || !controller.canUseProfile()) {
      throw StateError('Memory-Verbindung nicht verfügbar');
    }
    _opening = true;
    final generation = ++_generation;
    try {
      await controller.settleReward();
      if (generation != _generation || _closing != null || !controller.canUseProfile()) {
        throw StateError('Memory-Verbindungsaufbau wurde beendet');
      }
      _open = true;
      _lastTick = _monotonic();
      try {
        await transport.open(token, view);
      } catch (_) {
        _open = false;
        // A reply may be lost after Open was committed. Clean only our token.
        try { await transport.close(token); } catch (_) {}
        rethrow;
      }
      if (generation != _generation || _closing != null || !_open || !controller.canUseProfile()) {
        // Close may have completed before this delayed native Open arrived.
        // Its exact-token cleanup must run again; never revive its timer.
        _open = false;
        try { await transport.close(token); } catch (_) {}
        throw StateError('Memory-Verbindungsaufbau wurde beendet');
      }
      if (automaticPolling) {
        _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => unawaited(pump()));
      }
    } finally {
      _opening = false;
    }
  }

  Future<void> pump() async {
    if (!_open || _busy) return;
    _busy = true;
    try {
      if (!controller.canUseProfile()) {
        await close(persist: false);
        return;
      }
      final before = jsonEncode(view);
      final box = await transport.poll(token);
      if (!_open || !controller.canUseProfile()) {
        await close(persist: false);
        return;
      }
      final currentTick = _monotonic();
      final delta = math.max(0, currentTick - _lastTick);
      _lastTick = currentTick;
      final life = box['lifecycle'];
      final stamp = life is Map ? life['stamp'] : null;
      final epoch = life is Map ? life['pauseEpoch'] : null;
      final age = stamp is int ? _now().millisecondsSinceEpoch - stamp : -1;
      final active = life is Map && life['active'] == true &&
          epoch is int && epoch >= 0 && epoch <= 1000000000 &&
          age >= 0 && age < 2500;
      final newlyPaused = (epoch is int && epoch > _pauseEpoch) || (_active && !active);
      if (_active && active && !newlyPaused && !controller.round.paused && controller.state.remainingMs > 0) {
        // A delayed host callback may finish one pending action. It cannot
        // retroactively run the opponent's subsequently scheduled actions.
        _elapsed = math.min(controller.state.remainingMs, _elapsed + delta);
      }
      if (epoch is int && epoch > _pauseEpoch) _pauseEpoch = epoch;
      _active = active;
      if (newlyPaused) {
        await controller.setPaused(true, elapsedMs: _elapsed);
        _elapsed = 0;
      }
      final request = box['request'];
      if (request is Map<String, dynamic>) await _consume(request);
      if (!_open || !controller.canUseProfile()) {
        await close(persist: false);
        return;
      }
      if (interactive && controller.state.remainingMs > 0 &&
          _elapsed >= controller.state.remainingMs) {
        final amount = controller.state.remainingMs;
        _elapsed = 0;
        await controller.advance(amount);
      }
      if (jsonEncode(view) != before) await _publish();
    } catch (_) {
      _error = 'Speichern noch nicht bestätigt. Bitte erneut versuchen.';
      _elapsed = 0;
      if (_open && controller.canUseProfile()) {
        try {
          await controller.setPaused(true);
          await _publish();
        } catch (_) {
          await close(persist: false);
        }
      } else {
        await close(persist: false);
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _publish() async {
    if (!_open || !controller.canUseProfile()) return;
    if (_revision >= 999999999) throw StateError('Memory-Verbindungsgrenze erreicht');
    _revision++;
    await transport.publish(token, view);
  }

  Future<void> _consume(Map<String, dynamic> request) async {
    final sequence = request['sequence'];
    if (request['token'] != token || sequence is! int ||
        sequence < 1 || sequence > 1000000000 ||
        sequence <= _ack || sequence <= _rejected) return;
    // Every accepted same-session slot reaches ACK or rejection, including
    // a pause/round/revision change between Kotlin acceptance and Dart poll.
    if (request['roundId'] != controller.round.id ||
        request['revision'] is! int || request['revision'] != _revision ||
        !_active || _exit) {
      _rejected = sequence;
      return;
    }
    final action = request['action'];
    final keys = <String>{'token', 'roundId', 'revision', 'sequence', 'action'};
    if (action == 'flip') keys.add('index');
    if (action == 'difficulty') keys.add('difficulty');
    if (action == 'pack') keys.add('pack');
    if (request.length != keys.length || request.keys.any((key) => !keys.contains(key))) {
      _rejected = sequence;
      return;
    }
    try {
      switch (action) {
        case 'flip':
          if (!interactive || request['index'] is! int ||
              !await controller.flip(request['index'] as int)) return;
          _elapsed = 0;
        case 'pause':
          await controller.setPaused(true, elapsedMs: _elapsed);
          _elapsed = 0;
        case 'resume':
          await controller.settleReward();
          await controller.setPaused(false);
          _elapsed = 0;
        case 'exit':
          await controller.setPaused(true, elapsedMs: _elapsed);
          await controller.flush();
          _elapsed = 0;
          _exit = true;
        case 'restart':
          if (!paused && !controller.state.complete) return;
          await controller.restart();
          _elapsed = 0;
        case 'difficulty':
          if ((!paused && !controller.state.complete) ||
              !memoryDifficulties.contains(request['difficulty'])) return;
          await controller.restart(difficulty: request['difficulty'] as String);
          _elapsed = 0;
        case 'pack':
          if ((!paused && !controller.state.complete) ||
              !memoryPacks.contains(request['pack'])) return;
          await controller.restart(pack: request['pack'] as String);
          _elapsed = 0;
        default:
          return;
      }
      if (!_open || !controller.canUseProfile()) return;
      _ack = sequence;
      _error = null;
    } finally {
      if (_ack != sequence && _rejected < sequence) _rejected = sequence;
    }
  }

  Future<void> close({bool persist = true}) {
    if (_closing != null) return _closing!;
    _generation++;
    final wasOpen = _open;
    _open = false;
    _active = false;
    _timer?.cancel();
    _timer = null;
    final elapsed = _elapsed;
    _elapsed = 0;
    return _closing = () async {
      try {
        if (persist && wasOpen && controller.canUseProfile()) {
          await controller.setPaused(true, elapsedMs: elapsed);
          await controller.flush();
        }
      } finally {
        if (wasOpen) {
          try { await transport.close(token); } catch (_) {}
        }
      }
    }();
  }
}
