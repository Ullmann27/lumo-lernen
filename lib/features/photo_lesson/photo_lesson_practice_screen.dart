import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/learning_journey.dart';
import '../../core/lumo_learning_narration.dart';
import '../../core/lumo_learning_session_contract.dart';
import '../../core/lumo_voice.dart';
import '../../core/school_exercise_generator.dart';
import '../../core/task_hint_service.dart';
import '../../core/task_quality_guard.dart';
import '../../core/tutor_coordination_engine.dart';
import '../../core/writing_target_parser.dart';
import '../../domain/learning/lumo_learning_domain.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../../widgets/fox/lumo_companion_requests.dart';
import '../learning/adapters/legacy_lumo_task_adapter.dart';
import '../learning/renderers/adaptive_task_renderer.dart';
import '../learning/renderers/writing_task_renderer.dart';
import '../learning/widgets/interactive_task_workspace.dart';
import 'photo_lesson_session.dart';

/// The five checked tasks produced by a photo use the same learning objects as
/// regular practice. OCR is a topic suggestion, never an assessed child answer.
class PhotoLessonPracticeScreen extends StatefulWidget {
  const PhotoLessonPracticeScreen({
    super.key,
    required this.appState,
    required this.lease,
    required this.repository,
    required this.session,
  });
  final LumoAppState appState;
  final LearningProfileLease lease;
  final PhotoLessonSessionRepository repository;
  final PhotoLessonSession session;

  @override
  State<PhotoLessonPracticeScreen> createState() =>
      _PhotoLessonPracticeScreenState();
}

class _PhotoLessonPracticeScreenState extends State<PhotoLessonPracticeScreen>
    with WidgetsBindingObserver {
  static const _adapter = LegacyLumoTaskAdapter();
  static const _guard = TaskQualityGuard();
  static const _hints = TaskHintService();
  final _proposal = TextEditingController();
  final _scroll = ScrollController();
  final _narration = LumoLearningNarration();
  int _speechSerial = 0;
  LumoLearningIdentity? _speechIdentity;
  late PhotoLessonSession _session;
  late TaskInstance _task;
  PhotoLessonSession? _pending;
  bool _saving = false, _quiet = false, _slow = false, _helpVisible = false;
  bool _showProposal = false, _profileChanged = false;
  int _replay = 0, _handledRequest = -1, _step = 0;
  String? _error, _workspaceText, _activeObjectId, _subtitle;
  List<String> _objectIds = const [];
  LumoCompanionTaskContext? _published;

  LumoCompanionRequests get _bus => LumoCompanionRequests.instance;
  bool get _ownsProfile =>
      !widget.appState.resetting &&
      widget.appState.profileGeneration == widget.lease.generation &&
      widget.appState.canUseLearningLease(widget.lease);
  bool get _editable =>
      !_saving &&
      _pending == null &&
      !_profileChanged &&
      _ownsProfile &&
      !_session.currentCompleted &&
      !_session.needsEvidenceSync;
  bool get _reduced =>
      _quiet ||
      widget.appState.state.settings.calmMode ||
      widget.appState.state.settings.reduceAnimations;
  String get _help =>
      _workspaceText ??
      _hints.explain(_session.task,
          level: _session.helpLevel == 0 ? 1 : _session.helpLevel);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _session = widget.session;
    _prepareTask();
    widget.appState.addListener(_profileUpdated);
    _bus.learningAction.addListener(_actionRequested);
    _bus.learningPresentation.addListener(_presentationChanged);
    _bus.learningAudio.addListener(_audioChanged);
    _bus.helpRequested.addListener(_legacyHelp);
    _bus.learningIdentity.addListener(_identityChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _publish();
      if (_session.needsEvidenceSync) unawaited(_persist());
    });
  }

  void _prepareTask() {
    _task = _adapter.toTaskInstance(
        task: _session.task,
        childId: widget.lease.studentId,
        difficulty: _session.task.difficulty);
    _helpVisible = _session.helpLevel > 0;
    _workspaceText = null;
    _objectIds = const [];
    _activeObjectId = null;
    _subtitle = null;
    _showProposal = false;
    _proposal.clear();
    _step = 0;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _speechSerial++;
    _bus.learningIdentity.removeListener(_identityChanged);
    _narration.dispose();
    unawaited(LumoVoice.instance
        .configure(rate: widget.appState.state.settings.voiceRate));
    widget.appState.removeListener(_profileUpdated);
    _bus.learningAction.removeListener(_actionRequested);
    _bus.learningPresentation.removeListener(_presentationChanged);
    _bus.learningAudio.removeListener(_audioChanged);
    _bus.helpRequested.removeListener(_legacyHelp);
    final context = _published;
    if (context != null) _bus.clearTask(context);
    _proposal.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _stop();
  }

  void _identityChanged() {
    final speaking = _speechIdentity;
    if (speaking != null && !_bus.isCurrentLearningIdentity(speaking)) {
      _speechIdentity = null;
      _speechSerial++;
      unawaited(_narration.stop());
    }
  }

  Future<void> _read(String text) async {
    if (!mounted ||
        !_ownsTask ||
        _saving ||
        ModalRoute.of(context)?.isCurrent != true ||
        !widget.appState.state.settings.voiceEnabled) {
      return;
    }
    final captured = _bus.learningIdentity.value;
    if (captured == null) return;
    final serial = ++_speechSerial;
    _speechIdentity = captured;
    final rate = widget.appState.state.settings.voiceRate;
    try {
      await _narration.stop();
      if (!mounted ||
          serial != _speechSerial ||
          !_bus.isCurrentLearningIdentity(captured)) {
        return;
      }
      await LumoVoice.instance.configure(rate: _slow ? rate * .7 : rate);
      if (!mounted ||
          serial != _speechSerial ||
          !_bus.isCurrentLearningIdentity(captured)) {
        return;
      }
      await _narration.read(text);
    } catch (_) {
      // Audio availability does not change a child's answer or assessment.
      if (mounted && serial == _speechSerial) setState(() => _subtitle = text);
    } finally {
      if (serial == _speechSerial) {
        _speechIdentity = null;
        await LumoVoice.instance.configure(rate: rate);
      }
    }
  }

  void _queueRead(String text) {
    final taskId = _session.task.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scheduleMicrotask(() {
        if (mounted && _session.task.id == taskId && _ownsTask) {
          unawaited(_read(text));
        }
      });
    });
  }

  void _profileUpdated() {
    if (!mounted) return;
    if (!_ownsProfile && !_profileChanged) {
      _stop();
      setState(() => _profileChanged = true);
      final context = _published;
      if (context != null) _bus.clearTask(context);
    }
  }

  void _publish() {
    if (!mounted || !_ownsProfile || _profileChanged) return;
    final attempts = _session.attemptsFor(_session.task.id);
    final last = attempts.isEmpty ? null : attempts.last;
    final context = LumoCompanionTaskContext(
      subject: _session.task.subject,
      unit: _session.task.unit,
      prompt: _session.task.prompt,
      taskId: '${_session.id}:${_session.task.id}',
      answering: _editable,
      attempts: attempts.length,
      helpLevel: _session.helpLevel,
      lastAnswer: last?.given,
      lastCorrect: last?.correct,
      profileGeneration: widget.lease.generation,
      activity: 'photo-practice',
      ownerSection: 'home',
      stepId: 'photo:${_session.cursor}:$_step',
      objectIds: ['photo_prompt', ..._objectIds],
      answerChoices: _session.task.choices,
      localHelp: _help,
      explanation:
          _session.currentCompleted ? _session.task.explanation : _help,
      isExplanation: _helpVisible || _session.currentCompleted,
      allowedActions: {
        ...lumoDefaultLearningActions,
        if (_editable && _session.task.choices.isNotEmpty)
          LumoLearningAction.proposeAnswer,
        if (_objectIds.isNotEmpty) ...{
          LumoLearningAction.look,
          LumoLearningAction.point,
          LumoLearningAction.highlight,
        },
      },
    );
    _published = context;
    _bus.publishTask(context);
  }

  bool get _ownsTask =>
      _ownsProfile && identical(_bus.taskContext.value, _published);

  void _legacyHelp() {
    if (_ownsTask) unawaited(_hint());
  }

  void _actionRequested() {
    final request = _bus.learningAction.value;
    if (request == null ||
        request.requestId == _handledRequest ||
        !_ownsTask ||
        !_bus.isCurrentLearningIdentity(request.identity)) {
      return;
    }
    _handledRequest = request.requestId;
    switch (request.action) {
      case LumoLearningAction.hint:
      case LumoLearningAction.explain:
        unawaited(_hint());
      case LumoLearningAction.repeat:
        _repeat();
      case LumoLearningAction.slower:
        _slower();
      case LumoLearningAction.stop:
        _stop(cancelBus: false);
      case LumoLearningAction.proposeAnswer:
        if (_editable && request.candidate != null) {
          setState(() {
            _proposal.text = request.candidate!;
            _showProposal = true;
          });
        }
      case LumoLearningAction.highlight:
      case LumoLearningAction.look:
      case LumoLearningAction.point:
        if (_objectIds.contains(request.objectId)) {
          setState(() => _activeObjectId = request.objectId);
          _bus.publishLearningPresentation(LumoLearningPresentation(
            identity: request.identity,
            gazeObjectId: request.objectId,
            pointObjectId: request.action == LumoLearningAction.look
                ? null
                : request.objectId,
            animationState: request.action.name,
            expression: 'attentive',
          ));
        }
    }
  }

  void _presentationChanged() {
    final presentation = _bus.learningPresentation.value;
    if (!mounted ||
        !_ownsTask ||
        presentation == null ||
        !_bus.isCurrentLearningIdentity(presentation.identity)) {
      return;
    }
    final id = presentation.pointObjectId ?? presentation.gazeObjectId;
    if (id == null || _objectIds.contains(id)) {
      setState(() => _activeObjectId = id);
    }
  }

  void _audioChanged() {
    final audio = _bus.learningAudio.value;
    if (!mounted ||
        !_ownsTask ||
        audio == null ||
        !_bus.isCurrentLearningIdentity(audio.identity)) {
      return;
    }
    // No inferred syllable timers: only actual player subtitles and separately
    // published object presentation cross the learning seam.
    setState(() => _subtitle = audio.audible ? audio.subtitle : null);
  }

  void _stop({bool cancelBus = true}) {
    if (!mounted) return;
    if (cancelBus && _ownsTask) {
      _bus.cancelLearningInteraction(reason: 'photo-child-stop');
    }
    _speechSerial++;
    _speechIdentity = null;
    unawaited(_narration.stop());
    unawaited(LumoVoice.instance
        .configure(rate: widget.appState.state.settings.voiceRate));
    setState(() {
      _subtitle = null;
      _activeObjectId = null;
      _helpVisible = false;
    });
    _publish();
  }

  void _repeat() {
    if (!_ownsProfile || _saving) return;
    setState(() {
      _replay++;
      _subtitle = null;
    });
    _queueRead(_helpVisible ? _help : _session.task.prompt);
  }

  void _slower() {
    if (!_ownsProfile || _saving) return;
    setState(() => _slow = true);
    _repeat();
  }

  Future<void> _hint() async {
    if (!_editable) return;
    final next = _session.helpLevel < 3 ? _session.helpLevel + 1 : 3;
    setState(() {
      _helpVisible = true;
      _workspaceText = null;
    });
    await _persist(_session.withHelp(next));
    if (mounted && _error == null && _ownsTask) _queueRead(_help);
  }

  void _interaction(TaskWorkspaceInteraction interaction) {
    if (!mounted ||
        interaction.taskId != _task.taskInstanceId ||
        !_ownsProfile) {
      return;
    }
    final rawIds = interaction.visibleState['objectIds'];
    setState(() {
      _objectIds = rawIds is List
          ? rawIds.whereType<String>().toList(growable: false)
          : const [];
      _workspaceText = interaction.explanation;
      _step++;
    });
    if (interaction.isHelp && _editable && _session.helpLevel == 0) {
      unawaited(_persist(_session.withHelp(1)));
    } else {
      _publish();
    }
  }

  void _answer(AdaptiveTaskAnswer answer) {
    if (!_editable || answer.task.taskInstanceId != _task.taskInstanceId) {
      return;
    }
    final options = _task.options
        .where((option) => '${option.payload}' == '${answer.answer}');
    if (options.length != 1) return;
    final label = options.single.label;
    unawaited(_accept(label, _guard.matchesAnswer(_session.task, label),
        helpUsed: answer.hintUsed));
  }

  void _writing(WritingTaskResult result) {
    if (!_editable ||
        result.task.taskInstanceId != _task.taskInstanceId ||
        result.skipped) {
      return;
    }
    final typed = result.typedAnswer;
    if (typed == null) {
      unawaited(_accept('Schreibversuch', null));
    } else {
      String clean(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ');
      unawaited(_accept(
          typed,
          clean(typed) ==
              clean(WritingTargetParser.parse(_session.task.prompt))));
    }
  }

  Future<void> _accept(String value, bool? correct,
      {bool helpUsed = false}) async {
    if (!_editable) return;
    var source = _session;
    if (helpUsed && source.helpLevel == 0) source = source.withHelp(1);
    setState(() {
      _showProposal = false;
      _proposal.clear();
    });
    await _persist(source.answer(value, correct: correct));
  }

  void _confirmProposal() {
    if (!_editable) return;
    final proposal = _proposal.text.trim();
    final matches = _session.task.choices
        .where((c) => c.toLowerCase() == proposal.toLowerCase());
    if (matches.length != 1) {
      setState(() => _error =
          'Ich konnte das keiner Antwortkarte sicher zuordnen. Ändere den Text oder tippe die passende Karte an.');
      return;
    }
    final label = matches.single;
    unawaited(_accept(label, _guard.matchesAnswer(_session.task, label)));
  }

  /// Save the accepted attempt first, then replay its opaque identity into the
  /// existing idempotent journey writer. A crash at either boundary resumes the
  /// same observation; no stars, XP, school grades or duplicate attempts arise.
  Future<void> _persist([PhotoLessonSession? next]) async {
    if (_saving || !_ownsProfile) return;
    if (next != null) _pending = next;
    setState(() {
      _saving = true;
      _error = null;
    });
    _publish();
    try {
      final candidate = _pending;
      if (candidate != null) {
        await widget.repository.save(candidate, replacing: _session);
        final changedTask = candidate.task.id != _session.task.id ||
            candidate.id != _session.id;
        _session = candidate;
        _pending = null;
        if (changedTask && mounted) _prepareTask();
      }
      if (_session.needsEvidenceSync) {
        await widget.appState.prepareLearningLease(widget.lease);
        await widget.lease.profile.loadJourney();
        for (var i = _session.syncedAttempts;
            i < _session.attempts.length;
            i++) {
          if (!_ownsProfile) throw StateError('The learning profile changed');
          final attempt = _session.attempts[i];
          final correct = attempt.correct;
          if (correct == null) continue;
          final task =
              _session.tasks.singleWhere((t) => t.id == attempt.taskId);
          await widget.lease.profile.recordJourneyEvidence(
            subject: task.subject,
            unit: task.unit,
            evidence: LearningEvidence(
              taskId: attempt.id,
              problemId: TutorTaskScope.problemIdentity(
                  task.subject, task.unit, task.prompt),
              correct: correct,
              helpLevel: attempt.helpLevel,
            ),
          );
        }
        final synced =
            _session.change(syncedAttempts: _session.attempts.length);
        await widget.repository.save(synced, replacing: _session);
        _session = synced;
      }
    } catch (_) {
      if (mounted) {
        _error = _ownsProfile
            ? 'Dein Lernschritt wartet noch aufs Speichern. Bitte erneut versuchen.'
            : 'Das Kinderprofil hat gewechselt. Öffne die Übung im passenden Profil erneut.';
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        _publish();
      }
    }
  }

  Future<void> _next() async {
    if (_saving ||
        _pending != null ||
        !_session.currentCompleted ||
        !_ownsProfile) {
      return;
    }
    final unfinished =
        _session.tasks.indexWhere((t) => !_session.completed(t.id));
    if (unfinished < 0) return;
    await _persist(_session.change(cursor: unfinished));
    if (!mounted || _error != null || !_ownsProfile) return;
    if (_scroll.hasClients) _scroll.jumpTo(0);
    _publish();
  }

  Future<void> _practiceMore() async {
    if (_saving ||
        !_session.complete ||
        _session.needsEvidenceSync ||
        !_ownsProfile) {
      return;
    }
    final source = _session.recommendedPractice ?? _session.tasks.last;
    final next = ExerciseFactory().nextExact(
      grade: source.grade,
      subject: source.subject,
      unit: source.unit,
    );
    await _persist(PhotoLessonSession.start([next]));
    if (mounted && _error == null && _scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final attempts = _session.attemptsFor(_session.task.id);
    final last = attempts.isEmpty ? null : attempts.last;
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: const Color(0xFF071A34),
        appBar: AppBar(
            title: const Text('Deine Foto-Übungen'),
            backgroundColor: const Color(0xFF0C2B50),
            foregroundColor: Colors.white),
        body: LumoSceneBackground(
          scene: LumoScene.library,
          dimmed: true,
          child: SafeArea(
              child: SingleChildScrollView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            child: Center(
                child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                        '${_session.completedCount} von ${_session.tasks.length} Aufgaben bearbeitet',
                        style: const TextStyle(
                            color: Color(0xFFBBD8F7), fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('${_session.task.subject} · ${_session.task.unit}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    const Text(
                        'Nutze die Lernobjekte und wähle deine Antwort. Nach einem Hinweis probierst du selbst weiter.',
                        style:
                            TextStyle(color: Color(0xFFDBE9F7), fontSize: 16)),
                    const SizedBox(height: 16),
                    if (_profileChanged)
                      const Text(
                          'Das Kinderprofil hat gewechselt. Kehre zur Foto-Lektion zurück.',
                          style: TextStyle(color: Colors.white, fontSize: 18))
                    else if (_session.complete && !_session.needsEvidenceSync)
                      _completion()
                    else ...[
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        _control('Hilf mir', Icons.lightbulb_outline,
                            _editable ? () => unawaited(_hint()) : null),
                        _control('Noch einmal', Icons.replay,
                            _saving ? null : _repeat),
                        _control('Langsamer', Icons.slow_motion_video,
                            _saving ? null : _slower),
                        _control('Anders erklären', Icons.swap_horiz,
                            _editable ? () => unawaited(_hint()) : null),
                        _control('Stopp', Icons.stop_circle_outlined, _stop),
                        _control('Selbst versuchen', Icons.touch_app_outlined,
                            _stop),
                        _control(
                            _quiet ? 'Ruhig: an' : 'Ruhiger Modus',
                            Icons.spa_outlined,
                            () => setState(() => _quiet = !_quiet)),
                      ]),
                      const SizedBox(height: 16),
                      if (_helpVisible)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Semantics(
                                liveRegion: true,
                                child: Text(_help,
                                    style: const TextStyle(
                                        color: Color(0xFFFFDEA0),
                                        fontSize: 18)))),
                      if (_subtitle != null)
                        Text(_subtitle!,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 17)),
                      AbsorbPointer(
                          absorbing: !_editable,
                          child: AdaptiveTaskRenderer(
                            key: ValueKey('${_session.id}:${_session.task.id}'),
                            task: _task,
                            requestedHelpLevel: _session.helpLevel,
                            reduceMotion: _reduced,
                            slow: _slow,
                            replaySerial: _replay,
                            activeObjectId: _activeObjectId,
                            onInteraction: _interaction,
                            onAnswered: _answer,
                            onWritingSubmitted: _writing,
                            onShapeTraced: (result) {
                              if (_editable &&
                                  result.task.taskInstanceId ==
                                      _task.taskInstanceId &&
                                  result.correct) {
                                unawaited(_accept('Form geübt', null));
                              }
                            },
                          )),
                      if (_showProposal) ...[
                        const SizedBox(height: 16),
                        const Text(
                            'Habe ich dich richtig verstanden? Ändere oder bestätige deine Antwort.',
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
                        TextField(
                            key: const ValueKey('photo-answer-proposal'),
                            controller: _proposal,
                            maxLength: 80,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                                labelText: 'Dein Antwortvorschlag')),
                        _control('Diese Antwort prüfen', Icons.check,
                            _editable ? _confirmProposal : null),
                        _control('Vorschlag verwerfen', Icons.close,
                            () => setState(() => _showProposal = false)),
                      ],
                      if (last != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Semantics(
                                liveRegion: true,
                                child: Text(
                                    last.correct == null
                                        ? 'Dein Versuch ist gespeichert. Du hast geübt.'
                                        : last.correct!
                                            ? '✓ Richtig. ${_session.task.explanation}'
                                            : 'Noch nicht. Probiere einen Hinweis und wähle erneut.',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 18)))),
                      if (_session.currentCompleted)
                        Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: _control(
                                'Nächste Aufgabe',
                                Icons.arrow_forward,
                                _saving ? null : () => unawaited(_next()))),
                    ],
                    if (_saving)
                      const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('Dein Lernschritt wird gespeichert …',
                              style: TextStyle(color: Colors.white))),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: const TextStyle(
                              color: Color(0xFFFFDEA0), fontSize: 16)),
                      if (_pending != null || _session.needsEvidenceSync)
                        _control('Speichern erneut versuchen', Icons.refresh,
                            _saving ? null : () => unawaited(_persist())),
                    ],
                  ]),
            )),
          )),
        ),
      ),
    );
  }

  Widget _control(String text, IconData icon, VoidCallback? action) =>
      OutlinedButton.icon(
        onPressed: action,
        icon: Icon(icon),
        label: Text(text),
        style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: Colors.white,
            disabledForegroundColor: const Color(0xFF9FB3C8),
            backgroundColor: const Color(0xFF143B62),
            side: const BorderSide(color: Color(0xFF62CBE5))),
      );

  Widget _completion() {
    final recommended = _session.recommendedPractice;
    final assessed = _session.tasks
        .where((task) => _session
            .attemptsFor(task.id)
            .any((attempt) => attempt.correct != null))
        .length;
    return LumoGlassCard(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Icon(Icons.check_circle_outline,
          color: Color(0xFF8AE5C5), size: 56),
      const Text('Deine Foto-Übungen sind gespeichert',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
      const SizedBox(height: 12),
      Text(
          assessed == 0
              ? 'Deine Zeichen- oder Schreibversuche sind als Übung gespeichert.'
              : '${_session.independentCount} von $assessed bewerteten Aufgaben waren beim ersten Versuch ohne Hilfe richtig.',
          style: const TextStyle(color: Colors.white, fontSize: 18)),
      const SizedBox(height: 8),
      Text(
          assessed == 0
              ? 'Du hast es selbst versucht. Mit einer neuen Vorlage kannst du weiterüben.'
              : recommended == null
                  ? 'Alle bewerteten Aufgaben klappten selbstständig. Als Nächstes passt eine andere Aufgabe zum gleichen Thema.'
                  : 'Bei „${recommended.unit}“ hast du einen Hinweis oder einen weiteren Versuch genutzt. Übe dieses Thema noch einmal mit einer neuen Aufgabe.',
          style: const TextStyle(color: Color(0xFFD2E3F4), fontSize: 17)),
      const SizedBox(height: 16),
      _control('Eine passende Folgeaufgabe', Icons.auto_stories_outlined,
          _saving ? null : () => unawaited(_practiceMore())),
      const SizedBox(height: 8),
      _control('Zur Foto-Lektion', Icons.arrow_back,
          () => Navigator.of(context).pop()),
    ]));
  }
}
