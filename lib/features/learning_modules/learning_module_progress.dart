import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/discovery_progress.dart';
import '../../core/learning_journey.dart';

/// Durable answer/reward boundary shared by the direct Akademie modules.
/// A failed write keeps the accepted answer locked until Retry flushes it.
class LearningModuleProgress extends ChangeNotifier
    with WidgetsBindingObserver {
  LearningModuleProgress({
    required this.appState,
    required this.subject,
    required this.unit,
    this.discoveryTarget,
  }) {
    WidgetsBinding.instance.addObserver(this);
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  final LumoAppState appState;
  final String subject;
  final String unit;
  final DiscoveryLearningTarget? discoveryTarget;
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
  String get savingText => _pending?.discoveryPermission != null
      ? 'Die Entdeckungsfreigabe wird gespeichert…'
      : discoveryTarget != null
          ? 'Dein Entdeckungsweg wird gespeichert…'
          : _pending?.learningEvidence != null && _pending?.correct == null
              ? 'Wir speichern deinen Lernschritt…'
              : _pending?.correct == null
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
    DiscoveryStepKind discoveryStep = DiscoveryStepKind.independent,
    LearningEvidence? learningEvidence,
  }) {
    learningEvidence?.validate();
    if (learningEvidence != null && discoveryTarget != null) {
      throw StateError('Discovery uses its own existing observation model');
    }
    if (learningEvidence != null && learningEvidence.correct != correct) {
      throw ArgumentError('Answer and learning evidence must agree');
    }
    if (learningEvidence != null &&
        hintUsed &&
        learningEvidence.helpLevel == 0) {
      throw ArgumentError('Assisted answers require assisted evidence');
    }
    hintUsed = hintUsed || (learningEvidence?.helpLevel ?? 0) > 0;
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
      discoveryStep: discoveryStep,
      learningEvidence: learningEvidence,
    ));
  }

  /// Accompanied construction is an observation, never a school answer,
  /// Daily increment or reward. It uses the same captured owner and retry.
  Future<bool> saveObservation(LearningEvidence evidence) {
    evidence.validate();
    if (evidence.helpLevel == 0) {
      throw ArgumentError('Accompanied observations require support metadata');
    }
    if (discoveryTarget != null) {
      throw StateError('Discovery uses its own existing observation model');
    }
    if (_disposed || appState.resetting) return Future<bool>.value(false);
    if (_pending != null) return _pending!.completion.future;
    return _enqueue(_PendingModuleSave(
      stars: 0,
      xp: 0,
      owner: appState.beginLearningAction(),
      learningEvidence: evidence,
    ));
  }

  Future<bool> saveDiscoveryIntroduction() {
    if (discoveryTarget == null) {
      throw StateError('This is a regular learning module');
    }
    if (_disposed || appState.resetting) return Future<bool>.value(false);
    if (_pending != null) return _pending!.completion.future;
    return _enqueue(_PendingModuleSave(
      stars: 0,
      xp: 0,
      owner: appState.beginLearningAction(),
      discoveryIntroduction: true,
    ));
  }

  /// Explicit local parent choice through the same captured owner and retry
  /// boundary. This never grants cloud, microphone, camera or premium access.
  Future<bool> saveDiscoveryPermission(
      {required bool enabled, required int maxGrade}) {
    if (maxGrade < 1 || maxGrade > 4) {
      throw ArgumentError('Invalid discovery limit');
    }
    if (_disposed || appState.resetting) return Future<bool>.value(false);
    if (_pending != null) return _pending!.completion.future;
    return _enqueue(_PendingModuleSave(
      stars: 0,
      xp: 0,
      owner: appState.beginLearningAction(),
      discoveryPermission: (enabled: enabled, maxGrade: maxGrade),
    ));
  }

  /// Session bonuses affect only the wallet, never Daily or skill answers.
  Future<bool> saveBonus({required int stars, required int xp}) {
    if (discoveryTarget != null) {
      throw StateError('Discovery does not award school or wallet bonuses');
    }
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
    if (discoveryTarget != null) {
      throw StateError('Discovery does not award school or wallet rewards');
    }
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
      if (discoveryTarget != null || pending.discoveryPermission != null) {
        await appState.prepareLearningLease(owner);
        await owner.profile.loadDiscovery();
        if (!appState.canUseLearningLease(owner)) {
          _complete(pending, false);
          return;
        }
        if (!pending.profileRecorded) {
          if (pending.discoveryPermission == null) {
            owner.profile.requireDiscoveryAllowed(discoveryTarget!);
          }
          pending.profileRecorded = true;
          final permission = pending.discoveryPermission;
          if (permission != null) {
            await owner.profile.setDiscoveryPermission(
                enabled: permission.enabled, maxGrade: permission.maxGrade);
          } else if (pending.discoveryIntroduction) {
            await owner.profile.introduceDiscovery(discoveryTarget!);
          } else if (pending.correct != null) {
            await owner.profile.recordDiscoveryAnswer(
              target: discoveryTarget!,
              step: pending.discoveryStep,
              correct: pending.correct!,
              hintUsed: pending.hintUsed,
            );
          } else {
            throw StateError('Discovery has no wallet-only reward action');
          }
        } else {
          await owner.profile.flushDiscovery();
        }
        // Voluntary learning never calls regular rewards, Daily, attempts,
        // Cosmos or recordLearningAnswer. Reuse the existing owner/retry guard.
        _complete(
            pending,
            appState.isCurrentLearningLease(owner) &&
                (pending.discoveryPermission != null ||
                    owner.profile.canDiscover(discoveryTarget!.grade)));
        return;
      }
      // Flags precede writes: both services mutate before persistence and a
      // failure must retry the same queued state instead of awarding/counting.
      if (pending.learningEvidence != null) {
        // Loading is fallible before any mutation. Do not mark an observation
        // recorded until its original owner's bytes are safely available.
        await owner.profile.loadJourney();
        if (!appState.canUseLearningLease(owner)) {
          _complete(pending, false);
          return;
        }
      }
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
            taskId: pending.learningEvidence?.taskId,
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
      final evidence = pending.learningEvidence;
      if (evidence != null) {
        if (!appState.canUseLearningLease(owner)) {
          _complete(pending, false);
          return;
        }
        // Re-submit the identical accepted identity: the journal deduplicates
        // it after mutation, and retries validation/load failures before it.
        await owner.profile.recordJourneyEvidence(
            subject: subject, unit: unit, evidence: evidence);
      }
      // Unmount cancels UI continuations, not the accepted storage operation.
      _complete(
          pending,
          pending.correct == null
              ? owner.generation == appState.profileGeneration &&
                  appState.canUseLearningLease(owner)
              : appState.isCurrentLearningLease(owner));
    } on DiscoveryNotAllowed {
      _complete(pending, false);
    } catch (_) {
      if (pending.owner.invalidated) {
        _complete(pending, false);
        return;
      }
      _saving = false;
      _error = pending.discoveryPermission != null
          ? 'Die Entdeckungsfreigabe wartet noch aufs Speichern.'
          : discoveryTarget != null
              ? 'Dein Entdeckungsweg wartet noch aufs Speichern.'
              : pending.correct == null
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
    this.discoveryIntroduction = false,
    this.discoveryStep = DiscoveryStepKind.independent,
    this.discoveryPermission,
    this.learningEvidence,
  });

  final String prompt;
  final String given;
  final String expected;
  final int? durationMs;
  final bool discoveryIntroduction;
  final DiscoveryStepKind discoveryStep;
  final ({bool enabled, int maxGrade})? discoveryPermission;
  final LearningEvidence? learningEvidence;

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
