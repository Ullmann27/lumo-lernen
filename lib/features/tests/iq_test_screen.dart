import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/iq/iq_test_repository.dart';
import '../../core/iq/iq_test_session.dart';
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

enum _Phase { start, areaIntro, puzzle, saving, result, review }

/// Lumo Knobel-Test: Rätsel wie im IQ-Test, aber ohne IQ-Zahl (kein normierter Test).
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
    try {
      final id = await appState.school.activeStudentId();
      if (id != null) return id;
    } catch (_) {
      // Ohne lesbare Zuordnung gilt die Ersatzkennung.
    }
    final state = appState.state;
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
  late final IqTestSession _session = widget.session ??
      IqTestSession(grade: widget.appState.state.grade);
  _Phase _phase = _Phase.start;
  IqTestResult? _previous;
  IqTestResult? _result;
  IqReward _reward = IqReward.none;
  bool _alreadyRewarded = false;
  bool _saveFailed = false;
  DateTime? _startedAt;

  @override
  void initState() {
    super.initState();
    _loadPrevious();
  }

  Future<void> _loadPrevious() async {
    try {
      final id = await IqTestScreen.studentIdFor(widget.appState);
      final latest = await widget.repository.latest(id);
      if (mounted && _result == null) setState(() => _previous = latest);
    } catch (_) {
      // Ohne frühere Ergebnisse startet die Seite eben ohne „Letztes Mal“.
    }
  }

  // ------------------------------------------------------------- Ablauf

  void _start() {
    _startedAt = widget.now();
    setState(() =>
        _phase = _session.atAreaStart ? _Phase.areaIntro : _Phase.puzzle);
  }

  void _onSubmit(List<int> response, int durationMs) {
    _session.answer(response, durationMs: durationMs);
    if (_session.finished) {
      _finish();
      return;
    }
    setState(() =>
        _phase = _session.atAreaStart ? _Phase.areaIntro : _Phase.puzzle);
  }

  Future<void> _finish() async {
    setState(() => _phase = _Phase.saving);
    final finishedAt = widget.now();
    final studentId = await IqTestScreen.studentIdFor(widget.appState);
    final result = _session.result(
      id: 'iq-${finishedAt.microsecondsSinceEpoch}',
      studentId: studentId,
      finishedAt: finishedAt,
      durationMs: finishedAt.difference(_startedAt ?? finishedAt).inMilliseconds,
    );

    // Früher gespeicherte Ergebnisse (vor dem Speichern des neuen) für den
    // Tagescheck der Belohnung und den Vergleich.
    var earlier = const <IqTestResult>[];
    try {
      earlier = await widget.repository.loadAll(studentId);
    } catch (_) {
      // Ohne lesbare Ergebnisse gibt es keinen Vergleich.
    }
    var saved = true;
    try {
      await widget.repository.save(result);
    } catch (_) {
      saved = false;
    }
    try {
      await widget.appState.attemptLog.appendAll(_attempts(result));
    } catch (_) {
      // Das Protokoll darf das Ergebnis nie verhindern.
    }

    var reward = IqReward.none;
    var already = false;
    if (saved) {
      already = widget.rewards.alreadyDoneOn(earlier, finishedAt);
      if (!already) {
        reward = widget.rewards.forResult(result);
        if (!reward.isEmpty) {
          widget.appState.addRewards(stars: reward.stars, xp: reward.xp);
          try {
            await widget.appState.flushRewards();
          } catch (_) {
            // Die Sterne bleiben vorgemerkt und werden später gespeichert.
          }
        }
      }
    }
    IqTestResult? previous;
    for (final item in earlier) {
      if (previous == null || item.finishedAt.isAfter(previous.finishedAt)) {
        previous = item;
      }
    }
    if (!mounted) return;
    setState(() {
      _result = result;
      _previous = previous;
      _reward = reward;
      _alreadyRewarded = already;
      _saveFailed = !saved;
      _phase = _Phase.result;
    });
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

  bool get _canPopDirectly => _phase == _Phase.start || _phase == _Phase.result;

  Future<void> _handleBack() async {
    switch (_phase) {
      case _Phase.start:
      case _Phase.result:
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
        return IqPuzzleView(
          key: ValueKey('iq-page-puzzle-${_session.index}'),
          puzzle: _session.current,
          index: _session.index,
          total: _session.totalItems,
          areaNumber: _session.areaNumber,
          itemsPerArea: _session.itemsPerArea,
          onSubmit: _onSubmit,
          onBack: _handleBack,
        );
      case _Phase.saving:
        return const _Saving(key: ValueKey('iq-page-saving'));
      case _Phase.result:
        return IqResultView(
          key: const ValueKey('iq-page-result'),
          result: _result!,
          previous: _previous,
          reward: _reward,
          alreadyRewardedToday: _alreadyRewarded,
          saveFailed: _saveFailed,
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
