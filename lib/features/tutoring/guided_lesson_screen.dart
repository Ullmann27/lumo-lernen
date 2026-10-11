import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/lumo_voice.dart';
import '../../domain/tutoring/guided_lesson_catalog.dart';
import '../../domain/tutoring/tutoring_session_planner.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../../widgets/design/lumo_learning_module_frame.dart';
import '../../widgets/fox/lumo_character.dart';
import '../../widgets/fox/lumo_companion_requests.dart';
import '../../widgets/lumo_speech_controls.dart';
import '../learning_modules/learning_module_progress.dart';
import 'guided_math_illustration.dart';

/// Real five-part instruction using existing tutoring types, central voice,
/// companion bus and the captured-owner learning writer.
class GuidedLessonScreen extends StatefulWidget {
  const GuidedLessonScreen({
    super.key,
    required this.appState,
    required this.lesson,
    required this.discovery,
  });

  final LumoAppState appState;
  final GuidedLesson lesson;
  final bool discovery;

  @override
  State<GuidedLessonScreen> createState() => _GuidedLessonScreenState();
}

class _GuidedLessonScreenState extends State<GuidedLessonScreen> {
  static int _nextSession = 0;
  final _session = ++_nextSession;
  final _lumo = LumoCharacterController();
  late final int _generation;
  late final _progress = LearningModuleProgress(
    appState: widget.appState,
    subject: 'Mathematik',
    unit: widget.lesson.schoolUnit,
    discoveryTarget: widget.discovery ? widget.lesson.discoveryTarget : null,
  );
  int _index = 0;
  int _serial = 0;
  int _attempts = 0;
  int _helpLevel = 0;
  int _solved = 0;
  int _independentSolved = 0;
  int _replay = 0;
  bool _ready = false;
  bool _busy = false;
  bool _passed = false;
  bool _stale = false;
  bool _ownsVoice = false;
  bool _completed = false;
  bool _showExplanation = false;
  int _voiceSequence = 0;
  String? _blocked;
  String? _lastAnswer;
  bool? _lastCorrect;
  String? _feedback;
  String? _previousHelp;
  GuidedLessonStep? _easier;
  List<String> _choices = [];
  LumoCompanionTaskContext? _published;

  GuidedLessonStep get _step => _easier ?? widget.lesson.steps[_index];
  bool get _current =>
      mounted &&
      !_stale &&
      widget.appState.profileGeneration == _generation &&
      (widget.discovery || widget.lesson.grade <= widget.appState.state.grade);
  bool get _quiet =>
      widget.appState.state.settings.reduceAnimations ||
      widget.appState.state.settings.calmMode ||
      MediaQuery.disableAnimationsOf(context);

  static const _body = TextStyle(
      color: LumoVisualTokens.white,
      fontFamily: 'Nunito',
      fontSize: 18,
      height: 1.4,
      fontWeight: FontWeight.w700);

  @override
  void initState() {
    super.initState();
    _generation = widget.appState.profileGeneration;
    _progress.addListener(_saveChanged);
    widget.appState.addListener(_profileChanged);
    LumoCompanionRequests.instance.helpRequested.addListener(_help);
    LumoVoice.instance.status.addListener(_voiceChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_load()));
  }

  Future<void> _load() async {
    if (!mounted || _stale) return;
    // Explain a forbidden school route before touching a lease: _current
    // intentionally rejects it, and otherwise left the gate stuck on Loading.
    if (!widget.discovery &&
        widget.lesson.grade > widget.appState.state.grade) {
      setState(() {
        _ready = true;
        _blocked = 'Ein Thema aus einer höheren Schulstufe gehört zu '
            '„Mit Lumo Neues entdecken“. Deine Schulklasse bleibt gleich.';
      });
      return;
    }
    try {
      final owner = await widget.appState.captureLearningProfile();
      await widget.appState.prepareLearningLease(owner);
      if (!_current || !widget.appState.isCurrentLearningLease(owner)) return;
      if (widget.discovery) {
        await owner.profile.loadDiscovery();
        if (!_current) return;
        if (!owner.profile.canDiscover(widget.lesson.grade)) {
          setState(() {
            _ready = true;
            _blocked = 'Bitte gib das Gerät einer erwachsenen Person. '
                'Dieses Thema braucht eine eigene Entdeckungsfreigabe.';
          });
          return;
        }
      }
      setState(() => _ready = true);
      _startStep();
      if (widget.discovery) {
        LumoCompanionRequests.instance
            .recordLearningEvent(LumoLearningEventKind.exploreTopicRequested);
      }
      _lumo.hello();
    } catch (_) {
      if (!_current) return;
      setState(() {
        _ready = true;
        _blocked = 'Deine gespeicherten Lerndaten konnten nicht sicher '
            'geladen werden. Sie bleiben unverändert.';
      });
    }
  }

  void _saveChanged() {
    if (mounted) setState(() {});
  }

  void _profileChanged() {
    if (_stale ||
        (widget.appState.profileGeneration == _generation &&
            (widget.discovery ||
                widget.lesson.grade <= widget.appState.state.grade))) {
      return;
    }
    _stale = true;
    _stopOwnedVoice();
    final task = _published;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LumoCompanionRequests.instance.clearTask(task);
      if (mounted) setState(() {});
    });
  }

  void _startStep() {
    if (!_current) return;
    _stopOwnedVoice();
    setState(() {
      _serial++;
      _choices = _step.isQuestion
          ? (_step.choices..shuffle(math.Random(_session * 31 + _serial)))
          : [];
      _attempts = 0;
      _helpLevel = 0;
      _passed = !_step.isQuestion;
      _lastAnswer = null;
      _lastCorrect = null;
      _feedback = null;
      _previousHelp = null;
      _showExplanation = false;
      _replay++;
    });
    _publish();
    if (_step.type == TutoringStepType.recap && !_completed) {
      _completed = true;
      LumoCompanionRequests.instance
          .recordLearningEvent(LumoLearningEventKind.lessonCompleted);
      _lumo.cheer();
    }
    final settings = widget.appState.state.settings;
    if (settings.voiceEnabled &&
        settings.autoReadEnabled &&
        !settings.calmMode) {
      unawaited(_read(_step.instruction));
    }
  }

  void _publish() {
    if (!_current || !_ready || _blocked != null) return;
    _published = LumoCompanionTaskContext(
      taskId: 'guided-$_session-$_serial',
      subject: 'Mathematik',
      unit: widget.lesson.schoolUnit,
      prompt: _step.instruction,
      answering: _step.isQuestion && !_passed,
      attempts: _attempts,
      helpLevel: _helpLevel,
      lastAnswer: _lastAnswer,
      lastCorrect: _lastCorrect,
      localHelp: _step.isQuestion ? _step.help(level: _helpLevel + 1) : null,
      previousHelp: _previousHelp,
      activity: widget.discovery ? 'discovery' : 'guided_lesson',
      ownerSection: 'learn',
      profileGeneration: _generation,
    );
    LumoCompanionRequests.instance.publishTask(_published!);
  }

  Future<void> _answer(String answer) async {
    if (!_current ||
        _busy ||
        _passed ||
        !_step.isQuestion ||
        _progress.hasPending) {
      return;
    }
    final step = _step;
    final serial = _serial;
    final correct = step.accepts(answer);
    setState(() {
      _busy = true;
      _attempts++;
      _lastAnswer = answer;
    });
    _publish();
    LumoCompanionRequests.instance
        .recordLearningEvent(LumoLearningEventKind.answerSubmitted);
    // Only independent school answers count as school skills/Daily.
    // Prerequisite and accompanied examples are not fabricated mastery.
    final saved = widget.discovery || step.isIndependent
        ? await _progress.saveAnswer(
            correct: correct,
            hintUsed: _helpLevel > 0,
            prompt: step.instruction,
            given: answer,
            expected: step.expected,
            discoveryStep: step.observation!,
          )
        : true;
    if (!_current || serial != _serial) return;
    setState(() {
      _busy = false;
      if (!saved) {
        _blocked = 'Die Freigabe oder das Kinderprofil wurde geändert. '
            'Bitte gehe zur Lernübersicht zurück.';
        return;
      }
      _lastCorrect = correct;
      _passed = correct;
      if (correct) {
        _solved++;
        if (step.isIndependent) _independentSolved++;
        _feedback = step.isIndependent
            ? 'Du hast selbst gerechnet. Gut gemacht!'
            : 'Das passt! Weiter geht es in deinem Tempo.';
      } else {
        _feedback = _attempts == 1
            ? 'Fast! Probiere es noch einmal. Wenn du magst, hilft dir ein Tipp.'
            : 'Wir können es mit kleineren Schritten probieren. '
                'Du entscheidest, ob du Hilfe möchtest.';
      }
    });
    if (!saved) return;
    _publish();
    final requests = LumoCompanionRequests.instance;
    requests.recordInteraction(LumoInteractionKind.answerChecked);
    requests.recordLearningEvent(correct
        ? LumoLearningEventKind.answerCorrect
        : LumoLearningEventKind.answerIncorrect);
    if (correct) {
      _lumo.cheer();
    } else {
      _lumo.comfort();
    }
    if (widget.appState.state.settings.autoReadEnabled &&
        widget.appState.state.settings.voiceEnabled &&
        !widget.appState.state.settings.calmMode) {
      unawaited(_read(_feedback!,
          style: correct ? VoiceStyle.celebrate : VoiceStyle.comfort));
    }
  }

  void _help() {
    if (!_current ||
        !_ready ||
        _blocked != null ||
        _busy ||
        _passed ||
        !_step.isQuestion) {
      return;
    }
    final requests = LumoCompanionRequests.instance;
    requests.recordLearningEvent(LumoLearningEventKind.hintRequested);
    setState(() {
      _helpLevel = (_helpLevel + 1).clamp(1, 3);
      _previousHelp = _step.help(level: _helpLevel);
    });
    _publish();
    requests.recordLearningEvent(LumoLearningEventKind.hintAccepted);
    _lumo.think();
    if (widget.appState.state.settings.autoReadEnabled &&
        widget.appState.state.settings.voiceEnabled &&
        !widget.appState.state.settings.calmMode) {
      unawaited(_read(_previousHelp!));
    }
  }

  void _easierPractice() {
    if (!_current || _busy || _progress.hasPending || _easier != null) return;
    LumoCompanionRequests.instance
        .recordLearningEvent(LumoLearningEventKind.taskRepeated);
    setState(() => _easier = widget.lesson.easierPractice);
    _startStep();
  }

  void _replayExample() {
    if (!_current || _busy || _progress.hasPending) return;
    setState(() => _replay++);
    LumoCompanionRequests.instance
        .recordLearningEvent(LumoLearningEventKind.taskRepeated);
  }

  Future<void> _next() async {
    if (!_current || _busy || !_passed || _progress.hasPending) return;
    if (_step.type == TutoringStepType.recap) {
      await Navigator.of(context).maybePop();
      return;
    }
    if (_easier != null) {
      setState(() => _easier = null);
      _startStep();
      return;
    }
    if (widget.discovery && _step.type == TutoringStepType.showExample) {
      setState(() => _busy = true);
      final saved = await _progress.saveDiscoveryIntroduction();
      if (!_current) return;
      setState(() => _busy = false);
      if (!saved) {
        setState(() => _blocked = 'Die Entdeckungsfreigabe wurde geändert. '
            'Deine bisherigen Daten bleiben erhalten.');
        return;
      }
    }
    setState(() => _index++);
    _startStep();
  }

  Future<void> _read(String text,
      {VoiceStyle style = VoiceStyle.explain}) async {
    if (!_current || !widget.appState.state.settings.voiceEnabled) return;
    final sequence = ++_voiceSequence;
    _ownsVoice = true;
    await LumoVoice.instance.stop();
    if (!_current || sequence != _voiceSequence) return;
    await LumoVoice.instance.speak(text, style: style, waitForCompletion: true);
    if (sequence == _voiceSequence) _ownsVoice = false;
  }

  void _stopOwnedVoice() {
    _voiceSequence++;
    if (!_ownsVoice) return;
    _ownsVoice = false;
    unawaited(LumoVoice.instance.stop());
  }

  void _voiceChanged() {
    if (!_current || !_ownsVoice) return;
    if (LumoVoice.instance.status.value == VoiceStatus.speaking) {
      _lumo.talk();
    } else if (LumoVoice.instance.status.value == VoiceStatus.preparing) {
      _lumo.think();
    }
  }

  bool _canLeave() {
    if (!_progress.hasPending) return true;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Wir speichern noch. '
            'Bitte versuche das Speichern bei Bedarf erneut.')));
    return false;
  }

  Future<void> _navigate(LumoSection section) async {
    final navigator = Navigator.of(context);
    if (section == LumoSection.learn) {
      await navigator.maybePop();
      return;
    }
    // Akademie -> hub -> lesson is a real nested route stack. Popping only the
    // lesson left the hub covering Games/Profile even after the section changed.
    final app = widget.appState;
    navigator.popUntil((route) => route.isFirst);
    app.setSection(section);
  }

  Widget _answerChoice(String answer) {
    final selected = _lastAnswer == answer && _lastCorrect != null;
    final correct = selected && _lastCorrect == true;
    final color = selected
        ? correct
            ? const Color(0xFF155A47)
            : const Color(0xFF693C69)
        : const Color(0xFF124A88);
    return Semantics(
      button: true,
      enabled: !_busy && !_passed,
      onTap: _busy || _passed ? null : () => unawaited(_answer(answer)),
      selected: selected,
      label: selected
          ? '$answer, ${correct ? "richtig" : "noch einmal versuchen"}'
          : answer,
      excludeSemantics: true,
      child: FilledButton(
        key: ValueKey('guided-answer-$answer'),
        onPressed: _busy || _passed ? null : () => unawaited(_answer(answer)),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color,
          disabledForegroundColor: Colors.white,
          textStyle: _body.copyWith(fontSize: 22),
          side: selected
              ? BorderSide(
                  color: correct
                      ? const Color(0xFF83EACD)
                      : const Color(0xFFEFC2E7),
                  width: 2)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selected) ...[
              Icon(correct ? Icons.check_circle_rounded : Icons.refresh_rounded,
                  size: 22),
              const SizedBox(width: 8),
            ],
            Flexible(child: Text(answer, textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }

  Widget _continueButton() => FilledButton.icon(
        key: const ValueKey('guided-continue'),
        onPressed: _busy ? null : () => unawaited(_next()),
        style: FilledButton.styleFrom(
            minimumSize: const Size(64, 56),
            backgroundColor: LumoVisualTokens.gold,
            foregroundColor: const Color(0xFF172844)),
        icon: Icon(_step.type == TutoringStepType.recap
            ? Icons.home_rounded
            : Icons.arrow_forward_rounded),
        label: Text(
            _step.type == TutoringStepType.recap
                ? 'Zur Lernübersicht'
                : _easier != null
                    ? 'Zurück zu meiner Aufgabe'
                    : 'Weiter',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      );

  @override
  void dispose() {
    widget.appState.removeListener(_profileChanged);
    LumoCompanionRequests.instance.helpRequested.removeListener(_help);
    LumoVoice.instance.status.removeListener(_voiceChanged);
    _stopOwnedVoice();
    final task = _published;
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => LumoCompanionRequests.instance.clearTask(task));
    _progress.removeListener(_saveChanged);
    _progress.dispose();
    _lumo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _stale || _blocked != null) {
      return Scaffold(
        backgroundColor: LumoVisualTokens.night,
        appBar: AppBar(
          backgroundColor: LumoVisualTokens.night,
          foregroundColor: LumoVisualTokens.white,
          title: Text(widget.lesson.title),
        ),
        body: LumoSceneBackground(
          scene: LumoScene.learning,
          showPlaceholderLabel: false,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: LumoGlassCard(
                child: Column(children: [
                  Text(
                      _stale
                          ? 'Das Kinderprofil wurde gewechselt.'
                          : _blocked ?? 'Wir laden deinen Lernweg…',
                      style: _body),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Zur Lernübersicht'),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
    }
    final step = _step;
    final size = MediaQuery.sizeOf(context);
    final fixedContinue = size.width < 600 && size.height >= 480;
    return PopScope(
      canPop: !_progress.hasPending,
      child: LumoLearningModuleFrame(
        appState: widget.appState,
        title: widget.discovery ? 'Neues entdecken' : 'Lumo erklärt es mir',
        moduleTitle: widget.lesson.title,
        icon: widget.discovery ? Icons.explore_rounded : Icons.school_rounded,
        taskIndex: _index,
        totalTasks: widget.lesson.steps.length,
        progressLabel: 'Schritt',
        correctAnswers: _solved,
        correctCaption: 'gelöst',
        progressComplete: _completed,
        hasMistake: _lastCorrect == false,
        characterController: _lumo,
        guidance: 'Du gibst das Tempo vor.',
        mistakeGuidance: 'Wir probieren es gemeinsam.',
        canLeave: _canLeave,
        onNavigate: _navigate,
        scrollResetKey: _serial,
        footer: fixedContinue && _passed
            ? Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child:
                    SizedBox(width: double.infinity, child: _continueButton()))
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(step.title,
                key: const ValueKey('guided-step-title'),
                style:
                    _body.copyWith(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text(
                step.type == TutoringStepType.showExample
                    ? switch (widget.lesson.concept) {
                        GuidedMathConcept.bridgeTen =>
                          'Fülle zuerst den Zehner. Dann zähle die übrigen '
                              'Äpfel dazu.',
                        GuidedMathConcept.equalGroups =>
                          'Gleiche Gruppen lassen sich als Plusrechnung '
                              'und als Malrechnung beschreiben.',
                        GuidedMathConcept.subtractTen =>
                          'Nimm zuerst bis zehn weg. Nimm dann den Rest weg. '
                              'Zusammen sind es genau ${step.b} Äpfel.',
                      }
                    : step.instruction,
                style: _body),
            const SizedBox(height: 16),
            GuidedMathIllustration(
                key: ValueKey('guided-illustration-$_serial-$_replay'),
                lesson: widget.lesson,
                step: step,
                reduceMotion: _quiet),
            if (step.type == TutoringStepType.showExample) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 10, runSpacing: 8, children: [
                OutlinedButton.icon(
                  onPressed: _replayExample,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Beispiel noch einmal'),
                ),
                TextButton.icon(
                    onPressed: () =>
                        setState(() => _showExplanation = !_showExplanation),
                    icon: Icon(_showExplanation
                        ? Icons.expand_less_rounded
                        : Icons.menu_book_rounded),
                    label: Text(_showExplanation
                        ? 'Erklärung einklappen'
                        : 'Erklärung lesen')),
              ]),
              if (_showExplanation)
                Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(step.instruction, style: _body)),
            ],
            if (step.isQuestion) ...[
              const SizedBox(height: 16),
              LumoLessonAnswerGrid(
                crossAxisCount:
                    step.answerKind == GuidedAnswerKind.repeatedAddition ||
                            MediaQuery.textScalerOf(context).scale(1) > 1.35
                        ? 1
                        : 2,
                children: [
                  for (final answer in _choices) _answerChoice(answer),
                ],
              ),
            ],
            if (_feedback != null) ...[
              const SizedBox(height: 12),
              Text(_feedback!,
                  key: const ValueKey('guided-feedback'), style: _body),
            ],
            if (_previousHelp != null) ...[
              const SizedBox(height: 12),
              LumoLessonSurface(
                child: Text(_previousHelp!,
                    key: const ValueKey('guided-actual-hint'), style: _body),
              ),
            ],
            if (_progress.hasPending) ...[
              const SizedBox(height: 12),
              Text(_progress.error ?? _progress.savingText, style: _body),
              if (_progress.error != null)
                FilledButton(
                    onPressed: _progress.saving ? null : _progress.retry,
                    child: const Text('Erneut speichern')),
            ],
            if (step.type == TutoringStepType.recap) ...[
              const SizedBox(height: 12),
              Text(
                  '$_independentSolved neue Aufgaben selbst gelöst. '
                  '${widget.discovery ? "Der Schulfortschritt bleibt getrennt." : "Nur selbstständige Antworten zählen im Schulfortschritt."}',
                  style: _body),
            ],
            const SizedBox(height: 16),
            if (step.isQuestion && !_passed)
              Wrap(spacing: 10, runSpacing: 10, children: [
                OutlinedButton.icon(
                    onPressed: _busy ? null : _help,
                    icon: const Icon(Icons.lightbulb_rounded),
                    label: Text(_helpLevel == 0 ? 'Tipp' : 'Anderer Tipp')),
                if (_easier == null)
                  OutlinedButton(
                      onPressed: _busy ? null : _easierPractice,
                      child: const Text('Leichter üben')),
              ]),
            if (_passed && !fixedContinue) _continueButton(),
            const SizedBox(height: 16),
            if (widget.appState.state.settings.voiceEnabled)
              LumoSpeechControls(
                onRead: () => unawaited(
                    _read(_previousHelp ?? _feedback ?? step.instruction)),
                showStopWhenIdle: true,
              )
            else
              const Text(
                  'Die Stimme ist ausgeschaltet. '
                  'Du kannst die Erklärung hier lesen.',
                  style: _body),
            ValueListenableBuilder<String?>(
              valueListenable: LumoVoice.instance.lastError,
              builder: (_, error, __) => error == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(error, style: _body)),
            ),
          ],
        ),
      ),
    );
  }
}
