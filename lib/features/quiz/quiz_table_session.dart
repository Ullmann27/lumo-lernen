import 'dart:async';
import 'dart:convert';

import '../../domain/quiz/quiz_show.dart';
import '../lumo3d/native_table_transport.dart';
import 'quiz_show_round.dart';

/// Presentation-only native studio. Correct answers are not sent until reveal.
class QuizTableSession {
  QuizTableSession({
    required this.controller,
    required this.transport,
    this.reduceMotion = false,
    String? token,
    DateTime Function()? now,
  }) : token = token ?? QuizRound.newId(),
       _now = now ?? DateTime.now {
    if (!RegExp(r'^[a-f0-9]{32}$').hasMatch(this.token)) {
      throw ArgumentError('Ungültige Spielverbindung');
    }
  }
  final QuizRoundController controller;
  final NativeTableTransport transport;
  final String token;
  final bool reduceMotion;
  final DateTime Function() _now;
  Timer? _timer;
  bool _open = false,
      _busy = false,
      _active = false,
      _paused = false,
      _exit = false;
  int _revision = 1, _ack = 0, _rejected = 0, _pauseEpoch = 0;
  String? _error;
  bool get isOpen => _open;
  bool get paused => !_active || _paused;
  bool get interactive => _open && !paused && !_exit;

  Map<String, Object?> get view {
    final state = controller.state;
    final question = state.currentQuestion;
    return {
      'schema': 1,
      'game': 'quiz',
      'token': token,
      'roundId': controller.round.id,
      'owner': controller.round.owner,
      'revision': _revision,
      'ack': _ack,
      'rejected': _rejected,
      'recordRevision': controller.round.revision,
      'paused': paused,
      'exit': _exit,
      'reduceMotion': reduceMotion,
      'subject': controller.round.subject,
      'grade': controller.round.grade,
      'number': state.displayQuestionNumber,
      'total': state.questions.length,
      'questionSubject': question.subject,
      'prompt': question.prompt,
      'options': question.options,
      'selected': state.selectedOption,
      'revealed': state.revealed,
      'gameOver': state.gameOver,
      'won': state.won,
      'correctIndex': state.revealed ? question.correctIndex : null,
      'explanation': state.revealed ? question.explanation : null,
      'hidden': state.fiftyFiftyHiddenOptions.toList()..sort(),
      'usedJokers': state.usedJokers.map((j) => j.name).toList(),
      'audience': state.audienceVotes,
      'hint': state.lumoHint,
      'securedStars': state.securedStars,
      'awardedStars': state.awardedStars,
      'rewarded': controller.round.rewarded,
      'error': _error,
      'canSelect': interactive && !state.revealed && !state.gameOver,
      'canReveal':
          interactive &&
          !state.revealed &&
          !state.gameOver &&
          state.selectedOption != null,
      'canNext': interactive && state.revealed && !state.gameOver,
    };
  }

  Future<void> open({bool automaticPolling = true}) async {
    if (_open || !controller.canUseProfile())
      throw StateError('Quiz nicht verfügbar');
    await controller.settleReward();
    if (!controller.canUseProfile())
      throw StateError('Kinderprofil hat gewechselt');
    _open = true;
    try {
      await transport.open(token, view);
    } catch (_) {
      _open = false;
      // A host may durably accept Open before its platform reply is lost.
      // Close this exact token even when the local open flag was never set.
      try {
        await transport.close(token);
      } catch (_) {}
      rethrow;
    }
    if (!controller.canUseProfile()) {
      await close();
      throw StateError('Kinderprofil hat gewechselt');
    }
    if (automaticPolling) {
      _timer = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => unawaited(pump()),
      );
    }
  }

  Future<void> pump() async {
    if (!_open || _busy) return;
    _busy = true;
    try {
      if (!controller.canUseProfile()) {
        await close();
        return;
      }
      final before = jsonEncode(view);
      final box = await transport.poll(token);
      if (!_open || !controller.canUseProfile()) {
        await close();
        return;
      }
      final life = box['lifecycle'];
      final stamp = life is Map ? life['stamp'] : null;
      final age = stamp is int ? _now().millisecondsSinceEpoch - stamp : 100000;
      final epoch = life is Map ? life['pauseEpoch'] : null;
      final active =
          life is Map && life['active'] == true && age >= 0 && age < 2500;
      if ((epoch is int && epoch > _pauseEpoch) || (!active && _active))
        _paused = true;
      if (epoch is int && epoch > _pauseEpoch) _pauseEpoch = epoch;
      _active = active;
      final request = box['request'];
      if (request is Map<String, dynamic>) await _consume(request);
      if (!_open || !controller.canUseProfile()) {
        await close();
        return;
      }
      if (jsonEncode(view) != before) {
        _revision++;
        await transport.publish(token, view);
      }
    } catch (_) {
      _paused = true;
      _error = 'Speichern noch nicht bestätigt. Bitte erneut versuchen.';
      if (_open && controller.canUseProfile()) {
        try {
          _revision++;
          await transport.publish(token, view);
        } catch (_) {
          await close();
        }
      } else {
        await close();
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _consume(Map<String, dynamic> request) async {
    final seq = request['sequence'];
    if (request['token'] != token ||
        seq is! int ||
        seq < 1 ||
        seq <= _ack ||
        seq <= _rejected ||
        seq > 1000000000)
      return;
    if (request['roundId'] != controller.round.id ||
        request['revision'] is! int ||
        request['revision'] != _revision ||
        !_active ||
        _exit) {
      _rejected = seq;
      return;
    }
    final action = request['action'];
    final keys = <String>{'token', 'roundId', 'revision', 'sequence', 'action'};
    if (action == 'select') keys.add('option');
    if (action == 'joker') keys.add('joker');
    if (action == 'subject') keys.add('subject');
    if (request.length != keys.length ||
        request.keys.any((k) => !keys.contains(k))) {
      _rejected = seq;
      return;
    }
    try {
      switch (action) {
        case 'select':
          if (!interactive ||
              request['option'] is! int ||
              !await controller.select(request['option'] as int))
            return;
        case 'reveal':
          if (!interactive || !await controller.reveal()) return;
        case 'next':
          if (!interactive || !await controller.next()) return;
        case 'joker':
          if (!interactive ||
              !QuizJoker.values.any((j) => j.name == request['joker']))
            return;
          if (!await controller.joker(
            QuizJoker.values.firstWhere((j) => j.name == request['joker']),
          ))
            return;
        case 'pause':
          _paused = true;
        case 'resume':
          await controller.settleReward();
          _paused = false;
        case 'exit':
          await controller.settleReward();
          _paused = true;
          _exit = true;
        case 'restart':
          if (!paused && !controller.state.gameOver) return;
          await controller.restart();
          _paused = false;
        case 'subject':
          if ((!paused && !controller.state.gameOver) ||
              !QuizRound.subjects.contains(request['subject']))
            return;
          await controller.restart(subject: request['subject'] as String);
          _paused = false;
        default:
          return;
      }
      if (!_open || !controller.canUseProfile()) return;
      _error = null;
      _ack = seq;
    } catch (_) {
      _rejected = seq;
      rethrow;
    } finally {
      if (_ack != seq && _rejected < seq) _rejected = seq;
    }
  }

  Future<void> close() async {
    if (!_open) return;
    _open = false;
    _active = false;
    _paused = true;
    _timer?.cancel();
    _timer = null;
    try {
      await transport.close(token);
    } catch (_) {}
  }
}
