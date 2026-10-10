import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_state.dart';

/// Durable answer/reward boundary shared by the direct Akademie modules.
/// A failed write keeps the accepted answer locked until Retry flushes it.
class LearningModuleProgress extends ChangeNotifier
    with WidgetsBindingObserver {
  LearningModuleProgress({
    required this.appState,
    required this.subject,
    required this.unit,
  }) {
    WidgetsBinding.instance.addObserver(this);
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  final LumoAppState appState;
  final String subject;
  final String unit;
  _PendingModuleSave? _pending;
  bool _saving = false;
  bool _disposed = false;
  bool _bonusSaved = false;
  String? _error;
  bool _foreground = true;
  Timer? _feedbackTimer;
  Completer<bool>? _feedback;
  Duration _feedbackRemaining = Duration.zero;
  final Stopwatch _feedbackClock = Stopwatch();

  bool get hasPending => !_disposed && _pending != null;
  bool get saving => _saving;
  String? get error => _error;
  String get savingText => _pending?.correct == null
      ? 'Wir speichern deine Belohnung…'
      : 'Wir speichern deine Antwort…';

  /// Zeitpunkt der letzten Antwort (oder des Starts); daraus ergibt sich die
  /// Bearbeitungszeit der nächsten Aufgabe fürs Aufgabenprotokoll.
  DateTime _lastAnswerAt = DateTime.now();

  Future<bool> saveAnswer({
    required bool correct,
    bool hintUsed = false,
    int stars = 0,
    int xp = 0,
    String prompt = '',
    String given = '',
    String expected = '',
    String? cosmosSubjectId,
    bool cosmosIsMath = false,
    bool cosmosIsPerfect = false,
  }) {
    if (_disposed || appState.resetting) return Future<bool>.value(false);
    if (_pending != null) return _pending!.completion.future;
    final owner = appState.beginLearningAction();
    final now = DateTime.now();
    final ms = now.difference(_lastAnswerAt).inMilliseconds.clamp(0, 60000);
    if (_pending == null) _lastAnswerAt = now;
    return _enqueue(_PendingModuleSave(
      correct: correct,
      hintUsed: hintUsed,
      stars: stars,
      xp: xp,
      owner: owner,
      cosmosSubjectId: cosmosSubjectId,
      cosmosIsMath: cosmosIsMath,
      cosmosIsPerfect: cosmosIsPerfect,
      prompt: prompt,
      given: given,
      expected: expected,
      durationMs: ms,
    ));
  }

  /// Session bonuses affect only the wallet, never Daily or skill answers.
  Future<bool> saveBonus({required int stars, required int xp}) {
    if (_disposed || appState.resetting) return Future<bool>.value(false);
    if (_pending != null) return _pending!.completion.future;
    if (_bonusSaved) return Future<bool>.value(true);
    return _enqueue(_PendingModuleSave(
      stars: stars,
      xp: xp,
      owner: appState.beginLearningAction(),
      sessionBonus: true,
    ));
  }

  /// Intermediate rewards (for example a letter) do not count as answers.
  Future<bool> saveReward({required int stars, required int xp}) {
    if (_disposed || appState.resetting) return Future<bool>.value(false);
    if (_pending != null) return _pending!.completion.future;
    return _enqueue(_PendingModuleSave(
      stars: stars,
      xp: xp,
      owner: appState.beginLearningAction(),
    ));
  }

  /// Call from a real Nochmal action before beginning a new session.
  bool resetSession() {
    if (_disposed || hasPending) return false;
    _bonusSaved = false;
    _cancelFeedback();
    return true;
  }

  Future<bool> _enqueue(_PendingModuleSave pending) {
    if (_disposed || appState.resetting) return Future<bool>.value(false);
    if (_pending != null) return _pending!.completion.future;
    _pending = pending;
    _saving = true;
    _error = null;
    notifyListeners();
    unawaited(_attempt(pending));
    return pending.completion.future;
  }

  void retry() {
    final pending = _pending;
    if (_disposed || _saving || pending == null) return;
    _saving = true;
    _error = null;
    notifyListeners();
    unawaited(_attempt(pending));
  }

  Future<void> _attempt(_PendingModuleSave pending) async {
    try {
      final owner = await pending.owner.resolve();
      if (!appState.canUseLearningLease(owner)) {
        _complete(pending, false);
        return;
      }
      // Flags precede writes: both services mutate before persistence and a
      // failure must retry the same queued state instead of awarding/counting.
      if (!pending.rewardBooked) {
        pending.rewardBooked = true;
        appState.addRewards(stars: pending.stars, xp: pending.xp);
      }
      await appState.flushRewards();
      if (!appState.canUseLearningLease(owner)) {
        _complete(pending, false);
        return;
      }
      if (pending.correct != null) {
        await appState.prepareLearningLease(owner);
        if (!appState.canUseLearningLease(owner)) {
          _complete(pending, false);
          return;
        }
        if (!pending.profileRecorded) {
          pending.profileRecorded = true;
          await appState.recordLearningAnswer(
            subject: subject,
            unit: unit,
            correct: pending.correct!,
            hintUsed: pending.hintUsed,
            requireSaved: true,
            lease: owner,
            prompt: pending.prompt,
            given: pending.given,
            expected: pending.expected,
            durationMs: pending.durationMs,
          );
        } else {
          await appState.flushLearningProgress(lease: owner);
        }
        if (pending.correct! && pending.cosmosSubjectId != null) {
          // Load can fail before a reward is booked. Only mark a reward once
          // its world is available; retries then flush that same snapshot.
          await owner.cosmos.load();
          if (!appState.canUseLearningLease(owner)) {
            _complete(pending, false);
            return;
          }
          if (!pending.cosmosRecorded) {
            pending.cosmosRecorded = true;
            await appState.grantCosmosReward(
              subjectId: pending.cosmosSubjectId!,
              isMath: pending.cosmosIsMath,
              isPerfect: pending.cosmosIsPerfect,
              lease: owner,
              requireSaved: true,
            );
          } else {
            await appState.flushCosmos(lease: owner);
          }
        }
      } else if (pending.sessionBonus) {
        _bonusSaved = true;
      }
      // Unmount cancels UI continuations, not the accepted storage operation.
      _complete(
          pending,
          pending.correct == null
              ? owner.generation == appState.profileGeneration &&
                  appState.canUseLearningLease(owner)
              : appState.isCurrentLearningLease(owner));
    } catch (_) {
      if (pending.owner.invalidated) {
        _complete(pending, false);
        return;
      }
      _saving = false;
      _error = pending.correct == null
          ? 'Deine Belohnung wartet noch aufs Speichern.'
          : 'Deine Antwort wartet noch aufs Speichern.';
      if (!_disposed) notifyListeners();
      if (_disposed) pending.owner.close();
    }
  }

  void _complete(_PendingModuleSave pending, bool saved) {
    pending.owner.close();
    if (identical(_pending, pending)) _pending = null;
    _saving = false;
    _error = null;
    if (!_disposed) notifyListeners();
    if (!pending.completion.isCompleted) {
      pending.completion.complete(saved && !_disposed);
    }
  }

  /// Preserve feedback time across background/resume; never advance offscreen.
  Future<bool> feedbackDelay(Duration duration) {
    if (_disposed) return Future<bool>.value(false);
    _cancelFeedback();
    final completion = Completer<bool>();
    _feedback = completion;
    _feedbackRemaining = duration;
    _resumeFeedback();
    return completion.future;
  }

  void _resumeFeedback() {
    if (!_foreground || _disposed || _feedback == null) return;
    _feedbackClock.reset();
    _feedbackClock.start();
    _feedbackTimer = Timer(_feedbackRemaining, () {
      _feedbackTimer = null;
      _feedbackClock.stop();
      final completion = _feedback;
      _feedback = null;
      completion?.complete(!_disposed && _foreground);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (foreground == _foreground) return;
    _foreground = foreground;
    if (foreground) {
      _resumeFeedback();
    } else if (_feedbackTimer != null) {
      _feedbackTimer!.cancel();
      _feedbackTimer = null;
      _feedbackClock.stop();
      _feedbackRemaining -= _feedbackClock.elapsed;
      if (_feedbackRemaining.isNegative) _feedbackRemaining = Duration.zero;
    }
  }

  void _cancelFeedback() {
    _feedbackTimer?.cancel();
    _feedbackTimer = null;
    _feedbackClock.stop();
    final completion = _feedback;
    _feedback = null;
    if (completion != null && !completion.isCompleted) {
      completion.complete(false);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _cancelFeedback();
    final pending = _pending;
    if (pending != null && !_saving) pending.owner.close();
    if (pending != null && !pending.completion.isCompleted) {
      pending.completion.complete(false);
    }
    super.dispose();
  }
}

class _PendingModuleSave {
  _PendingModuleSave({
    this.correct,
    this.hintUsed = false,
    required this.stars,
    required this.xp,
    required this.owner,
    this.cosmosSubjectId,
    this.cosmosIsMath = false,
    this.cosmosIsPerfect = false,
    this.sessionBonus = false,
    this.prompt = '',
    this.given = '',
    this.expected = '',
    this.durationMs,
  });

  final String prompt;
  final String given;
  final String expected;
  final int? durationMs;

  final bool? correct;
  final bool hintUsed;
  final int stars;
  final int xp;
  final LearningProfileAction owner;
  final String? cosmosSubjectId;
  final bool cosmosIsMath;
  final bool cosmosIsPerfect;
  final bool sessionBonus;
  final Completer<bool> completion = Completer<bool>();
  bool rewardBooked = false;
  bool profileRecorded = false;
  bool cosmosRecorded = false;
}

/// A compact reserved status row: it reflows content rather than covering it.
class LearningModuleProgressScope extends StatelessWidget {
  const LearningModuleProgressScope({
    super.key,
    required this.progress,
    required this.child,
  });

  final LearningModuleProgress progress;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: progress,
        child: child,
        builder: (context, child) => PopScope<void>(
          canPop: !progress.hasPending,
          child: Column(children: [
            if (progress.hasPending)
              Material(
                color: const Color(0xFFFFF5D9),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Semantics(
                        liveRegion: true,
                        child: Text(progress.error ?? progress.savingText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Color(0xFF332B20), fontSize: 16)),
                      ),
                      if (progress.error != null)
                        FilledButton(
                          onPressed: progress.saving ? null : progress.retry,
                          child: const Text('Erneut versuchen'),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: LinearProgressIndicator(),
                        ),
                    ]),
                  ),
                ),
              ),
            Expanded(
              child: AbsorbPointer(
                absorbing: progress.hasPending,
                child: child!,
              ),
            ),
          ]),
        ),
      );
}
