import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/iq/iq_test_repository.dart';
import '../../core/iq/iq_test_session.dart';
import '../../core/iq/exam_session_owner.dart';
import '../../core/learning_attempt_id.dart';
import '../../domain/iq/iq_puzzle.dart';
import '../../domain/school/attempt.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../../widgets/design/lumo_motion.dart';
import 'iq/iq_result_view.dart';
import 'iq/iq_review_view.dart';
import 'iq/iq_reward.dart';
import 'iq/iq_puzzle_view.dart';
import 'iq/iq_start_view.dart';
import 'iq/iq_style.dart';
import 'iq/iq_widgets.dart';
import 'iq/exam_companion_scope.dart';

enum _Phase { start, areaIntro, puzzle, saving, saveError, result, review }

/// Lumo Knobel-Test: spielerisches Denk-Abenteuer ohne normierten IQ-Wert.
///
/// 24 Rätsel in sechs Bereichen, ohne Zeitdruck und ohne „richtig/falsch“
/// zwischendurch. Am Ende gibt es ein Denk-Profil, aber bewusst keine
/// erfundene IQ-Zahl.
class IqTestScreen extends StatefulWidget {
  const IqTestScreen({
    super.key,
    required this.appState,
    this.repository = const IqTestRepository(),
    this.session,
    this.now = DateTime.now,
    this.rewards = const IqRewardPolicy(),
  });

  final LumoAppState appState;
  final IqTestRepository repository;

  /// Ein fertig vorbereiteter Ablauf (Standard: neuer Ablauf für die Klasse
  /// des Kindes mit zufälligen Rätseln).
  final IqTestSession? session;

  /// Uhr – nur für Tests austauschbar.
  final DateTime Function() now;
  final IqRewardPolicy rewards;

  /// Kennung des Kindes für Ergebnisse und Protokoll: das zugeordnete
  /// Schulkind, sonst eine Ersatzkennung aus Name und Klasse (wie beim
  /// Denkprofil).
  static Future<String> studentIdFor(LumoAppState appState) async {
    final state = appState.state;
    try {
      final id = await appState.school.activeStudentId();
      if (id != null) return id;
    } catch (_) {
      // Ohne lesbare Zuordnung gilt die Ersatzkennung.
    }
    final safeName = state.childName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9äöüß]+'), '_');
    return 'local_${safeName.isEmpty ? 'kind' : safeName}_${state.grade}';
  }

  @override
  State<IqTestScreen> createState() => _IqTestScreenState();
}

class _IqTestScreenState extends State<IqTestScreen> {
  late final ExamSessionOwner _owner;
  final String _sessionId = newLearningAttemptId();
  late IqTestSession _session =
      widget.session ?? IqTestSession(grade: widget.appState.state.grade);
  _Phase _phase = _Phase.start;
  IqTestResult? _previous;
  IqTestResult? _result;
  IqReward _reward = IqReward.none;
  bool _alreadyRewarded = false;
  bool _saveFailed = false;
  DateTime? _startedAt;
  IqTestResult? _pendingResult;
  List<IqTestResult>? _earlier;
  bool _savingInFlight = false, _resultSaved = false, _attemptsSaved = false;
  bool _rewardEvaluated = false, _rewardQueued = false;

  @override
  void initState() {
    super.initState();
    _owner = ExamSessionOwner(widget.appState)..addListener(_profileChanged);
    _loadPrevious();
  }

  void _profileChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _owner.removeListener(_profileChanged);
    _owner.dispose();
    super.dispose();
  }

  Future<void> _loadPrevious() async {
    try {
      final id = await _owner.studentId();
      final latest = await widget.repository.latest(id);
      if (mounted && !_owner.retired && _result == null) {
        setState(() => _previous = latest);
      }
    } catch (_) {
      // Ohne frühere Ergebnisse startet die Seite eben ohne „Letztes Mal“.
    }
  }

  // ------------------------------------------------------------- Ablauf

  void _start() {
    if (_owner.retired || _phase != _Phase.start) return;
    _startedAt = widget.now();
    setState(
        () => _phase = _session.atAreaStart ? _Phase.areaIntro : _Phase.puzzle);
  }

  void _startExtended() {
    if (_owner.retired || _phase != _Phase.start) return;
    // Keep injected test/recovery sessions unchanged. For the regular user,
    // build a separate, longer adaptive challenge with six puzzles per area.
    if (widget.session == null) {
      _session = IqTestSession(
        grade: widget.appState.state.grade,
        itemsPerArea: 6,
      );
    }
    _start();
  }

  void _onSubmit(
      String puzzleId, int index, List<int> response, int durationMs) {
    if (_owner.retired ||
        _phase != _Phase.puzzle ||
        _session.finished ||
        _session.index != index ||
        _session.current.id != puzzleId) {
      return;
    }
    try {
      _session.answer(response,
          durationMs: durationMs,
          expectedPuzzleId: puzzleId,
          expectedIndex: index);
    } on ArgumentError {
      return; // Incomplete recognition/input is not a scored wrong answer.
    }
    if (_session.finished) {
      _finish();
      return;
    }
    setState(
        () => _phase = _session.atAreaStart ? _Phase.areaIntro : _Phase.puzzle);
  }

  Future<void> _finish() async {
    if (_savingInFlight || _owner.retired || !_session.finished) return;
    _savingInFlight = true;
    setState(() => _phase = _Phase.saving);
    try {
      final studentId = _pendingResult?.studentId ?? await _owner.studentId();
      if (!mounted || _owner.retired) return;
      final finishedAt = _pendingResult?.finishedAt ?? widget.now();
      final result = _pendingResult ??= _session.result(
        id: 'iq-${finishedAt.microsecondsSinceEpoch}',
        studentId: studentId,
        finishedAt: finishedAt,
        durationMs:
            finishedAt.difference(_startedAt ?? finishedAt).inMilliseconds,
      );
      _earlier ??= await widget.repository.loadAll(studentId);
      if (_owner.retired) return;
      if (!_resultSaved) {
        await widget.repository.save(result);
        _resultSaved = true;
      }
      if (!_attemptsSaved) {
        await widget.appState.attemptLog.appendAll(_attempts(result));
        _attemptsSaved = true;
      }
      // Accepted history keeps its original child; a changed profile must
      // never receive this session's reward or see the previous child's data.
      if (_owner.retired) return;
      if (!_rewardEvaluated) {
        _alreadyRewarded = widget.rewards.alreadyDoneOn(_earlier!, finishedAt);
        _reward =
            _alreadyRewarded ? IqReward.none : widget.rewards.forResult(result);
        _rewardEvaluated = true;
      }
      if (!_reward.isEmpty && !_rewardQueued) {
        widget.appState.addRewards(stars: _reward.stars, xp: _reward.xp);
        _rewardQueued = true;
      }
      if (_rewardQueued) await widget.appState.flushRewards();
      _saveFailed = false;
    } catch (_) {
      _saveFailed = true;
    } finally {
      _savingInFlight = false;
      if (mounted && !_owner.retired) {
        final result = _pendingResult;
        IqTestResult? previous;
        if (result != null) {
          for (final item in _earlier ?? const <IqTestResult>[]) {
            if (item.version != result.version ||
                item.items.length != result.items.length ||
                item.id == result.id) {
              continue;
            }
            if (previous == null ||
                item.finishedAt.isAfter(previous.finishedAt)) {
              previous = item;
            }
          }
        }
        setState(() {
          _result = result;
          _previous = previous;
          _phase = result == null ? _Phase.saveError : _Phase.result;
        });
      }
    }
  }

  /// Ein Protokolleintrag je Rätsel, damit Lernbericht und Lehrerbereich den
  /// Test sehen.
  List<Attempt> _attempts(IqTestResult result) {
    final answered = _session.answered;
    var after = result.items.fold<int>(0, (sum, item) => sum + item.durationMs);
    return [
      for (var i = 0; i < result.items.length; i++)
        () {
          final item = result.items[i];
          after -= item.durationMs;
          return Attempt(
            id: '${result.id}-${item.puzzleId}',
            studentId: result.studentId,
            subject: 'IQ-Rätsel',
            unit: item.area.title,
            competency: item.area.skill,
            correct: item.correct,
            at: result.finishedAt.subtract(Duration(milliseconds: after)),
            prompt: i < answered.length ? answered[i].$1.question : '',
            given: item.given,
            expected: item.expected,
            durationMs: item.durationMs,
            score: item.correct ? 1 : 0,
          );
        }(),
    ];
  }

  // ----------------------------------------------------------- Zurück

  bool get _canPopDirectly =>
      _owner.retired ||
      _phase == _Phase.start ||
      _phase == _Phase.result ||
      _phase == _Phase.saveError;

  Future<void> _handleBack() async {
    switch (_phase) {
      case _Phase.start:
      case _Phase.result:
      case _Phase.saveError:
        Navigator.of(context).pop();
      case _Phase.review:
        setState(() => _phase = _Phase.result);
      case _Phase.saving:
        break;
      case _Phase.areaIntro:
      case _Phase.puzzle:
        final leave = await showDialog<bool>(
          context: context,
          builder: (context) => const _ExitDialog(),
        );
        if (leave == true && mounted) Navigator.of(context).pop();
    }
  }

  // ------------------------------------------------------------ Seiten

  Widget _page() {
    switch (_phase) {
      case _Phase.start:
        return IqStartView(
          key: const ValueKey('iq-page-start'),
          lastPoints: _previous?.thinkingPoints,
          onStart: _start,
          onStartExtended: widget.session == null ? _startExtended : null,
          onBack: _handleBack,
        );
      case _Phase.areaIntro:
        return IqAreaIntroView(
          key: ValueKey('iq-page-area-${_session.areaNumber}'),
          area: _session.area,
          areaNumber: _session.areaNumber,
          index: _session.index,
          total: _session.totalItems,
          itemsPerArea: _session.itemsPerArea,
          onGo: () => setState(() => _phase = _Phase.puzzle),
          onBack: _handleBack,
        );
      case _Phase.puzzle:
        final index = _session.index;
        final puzzleId = _session.current.id;
        return IqPuzzleView(
          key: ValueKey('iq-page-puzzle-${_session.index}'),
          puzzle: _session.current,
          index: _session.index,
          total: _session.totalItems,
          areaNumber: _session.areaNumber,
          itemsPerArea: _session.itemsPerArea,
          onSubmit: (response, durationMs) =>
              _onSubmit(puzzleId, index, response, durationMs),
          onBack: _handleBack,
        );
      case _Phase.saving:
        return const _Saving(key: ValueKey('iq-page-saving'));
      case _Phase.saveError:
        return Center(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                      'Deine Antworten bleiben erhalten. Das Kinderprofil konnte noch nicht zum Speichern geladen werden.',
                      style: iqText(18)),
                  const SizedBox(height: 16),
                  IqPrimaryButton(
                      label: 'Speichern erneut versuchen', onPressed: _finish),
                ])));
      case _Phase.result:
        return IqResultView(
          key: const ValueKey('iq-page-result'),
          result: _result!,
          previous: _previous,
          reward: _reward,
          alreadyRewardedToday: _alreadyRewarded,
          saveFailed: _saveFailed,
          onRetry: _saveFailed ? () => unawaited(_finish()) : null,
          onReview: () => setState(() => _phase = _Phase.review),
          onDone: () => Navigator.of(context).pop(),
        );
      case _Phase.review:
        return IqReviewView(
          key: const ValueKey('iq-page-review'),
          answered: _session.answered,
          onBack: () => setState(() => _phase = _Phase.result),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.appState.state.settings;
    final reduce = settings.reduceAnimations || settings.calmMode;
    Widget content = _Switcher(
      reduced: reduce || LumoMotion.reduced(context),
      pageKey: _pageKey(),
      child: _page(),
    );
    if (_owner.retired) {
      content = Center(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                    'Das Kinderprofil wurde gewechselt. Öffne den Test für das ausgewählte Kind neu.',
                    style: iqText(18)),
                const SizedBox(height: 16),
                IqPrimaryButton(
                    label: 'Zurück',
                    onPressed: () => Navigator.of(context).maybePop()),
              ])));
    } else if (_phase == _Phase.puzzle || _phase == _Phase.areaIntro) {
      content = ExamCompanionScope(
        appState: widget.appState,
        generation: _owner.generation,
        taskId: '$_sessionId-${_session.current.id}',
        subject: 'IQ-Rätsel',
        unit: _session.area.title,
        prompt: _phase == _Phase.areaIntro
            ? _session.area.instruction
            : _session.current.question,
        instruction: _session.current is IqMemoryPuzzle
            ? 'Merke dir die gezeigte Reihenfolge. Tippe danach die Felder an und bestätige mit Weiter. Die Wiederholung des Auftrags zeigt die Folge nicht erneut.'
            : 'Wähle eine Antwortkarte. Vor Weiter kannst du die Auswahl ändern. Während des Tests gibt Lumo keine Hinweise zur Lösung.',
        child: content,
      );
    }
    if (reduce && !MediaQuery.disableAnimationsOf(context)) {
      content = MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: content,
      );
    }
    return PopScope(
      canPop: _canPopDirectly,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: LumoVisualTokens.night,
        body: LumoSceneBackground(
          scene: LumoScene.tests,
          dimmed: true,
          child: SafeArea(child: content),
        ),
      ),
    );
  }

  String _pageKey() => switch (_phase) {
        _Phase.start => 'start',
        _Phase.areaIntro => 'area-${_session.areaNumber}',
        _Phase.puzzle => 'puzzle-${_session.index}',
        _Phase.saving => 'saving',
        _Phase.saveError => 'save-error',
        _Phase.result => 'result',
        _Phase.review => 'review',
      };
}

/// Blendet zwischen den Seiten weich über (ohne Bewegung: sofort).
class _Switcher extends StatelessWidget {
  const _Switcher({
    required this.reduced,
    required this.pageKey,
    required this.child,
  });

  final bool reduced;
  final String pageKey;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: reduced ? Duration.zero : LumoMotion.page,
        switchInCurve: LumoMotion.enter,
        switchOutCurve: Curves.easeIn,
        layoutBuilder: (current, previous) => Stack(
          fit: StackFit.expand,
          children: [...previous, if (current != null) current],
        ),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(.04, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(pageKey), child: child),
      );
}

class _Saving extends StatelessWidget {
  const _Saving({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: LumoVisualTokens.cyanBright,
              ),
            ),
            const SizedBox(height: 16),
            Text('Lumo zählt deine Denkpunkte …',
                style: iqText(17, weight: FontWeight.w900)),
          ],
        ),
      );
}

/// „Test wirklich beenden?“ – ohne Speichern.
class _ExitDialog extends StatelessWidget {
  const _ExitDialog();

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: IqPanel(
                strong: true,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Test wirklich beenden?',
                      textAlign: TextAlign.center,
                      style: iqText(23, weight: FontWeight.w900, height: 1.2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dein Fortschritt geht dabei verloren. '
                      'Es wird nichts gespeichert.',
                      textAlign: TextAlign.center,
                      style: iqText(15,
                          weight: FontWeight.w700,
                          color: LumoVisualTokens.muted,
                          height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    IqPrimaryButton(
                      key: const ValueKey('iq-exit-stay'),
                      label: 'Weitermachen',
                      icon: Icons.play_arrow_rounded,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    const SizedBox(height: 10),
                    IqPrimaryButton(
                      key: const ValueKey('iq-exit-confirm'),
                      label: 'Beenden',
                      icon: Icons.close_rounded,
                      outlined: true,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
