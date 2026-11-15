import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

import '../../../app/app_state.dart';
import '../../../core/game_progress_repository.dart';
import '../../../core/lumo_learning_session_contract.dart';
import '../../../core/lumo_voice.dart';
import '../../../domain/games/game_level_model.dart';
import '../../../domain/games/mini_game_learning_task.dart';
import '../../../domain/games/mini_game_round.dart';
import '../../../domain/learning/lumo_learning_domain.dart';
import '../../../domain/tutoring/native_learning_activity.dart';
import '../../lumo3d/lumo3d_launcher.dart';
import '../../../widgets/fox/lumo_companion_requests.dart';
import '../../learning/widgets/interactive_task_workspace.dart';
import '../../shared/widgets/lumo_companion_avatar.dart';
import '../shared/lumo_board_game_stage.dart';
import '../shared/lumo_game_pause_scope.dart';

/// Shared live learning route for the five existing mini-game screens.
/// It only consumes the canonical LUMO contract; game logic owns every answer.
class MiniGameLearningScreen extends StatefulWidget {
  const MiniGameLearningScreen(
      {super.key, required this.appState, required this.level, this.onResult});

  final LumoAppState appState;
  final GameLevel level;
  final ValueChanged<int>? onResult;

  @override
  State<MiniGameLearningScreen> createState() => _MiniGameLearningScreenState();
}

class _MiniGameLearningScreenState extends State<MiniGameLearningScreen>
    with WidgetsBindingObserver {
  final _bus = LumoCompanionRequests.instance;
  final _clock = LumoGameTurnClock();
  final _scroll = ScrollController();
  final _proposal = TextEditingController();
  static const _repository = GameProgressRepository();
  late final int _generation, _grade;
  late final String _name, _childId;
  LearningProfileLease? _lease;
  MiniGameRoundController? _controller;
  LumoCompanionTaskContext? _published;
  LumoLearningIdentity? _proposalIdentity;
  int _proposalToken = 0;
  bool _nativeOpen = false, _nativeReturnPending = false, _foreground = true;
  TaskInstance? _workspace;
  bool _loading = true, _busy = false, _quiet = false, _slow = false;
  bool _showHelp = false, _supportStopped = false, _hasProposal = false;
  bool _reading = false, _resultShown = false, _profileChanged = false;
  int _handledRequest = -1, _replay = 0, _step = 0, _voiceRevision = 0;
  int _queuedHelp = 0;
  String? _error, _workspaceMessage, _activeObjectId, _subtitle;
  List<String> _workspaceIds = const [];
  final _marked = <int>{};

  MiniGameRound? get _round => _controller?.round;
  bool get _currentProfile {
    final lease = _lease;
    return !_profileChanged &&
        !widget.appState.resetting &&
        widget.appState.profileGeneration == _generation &&
        widget.appState.state.childName == _name &&
        widget.appState.state.grade == _grade &&
        (lease == null ||
            (widget.appState.canUseLearningLease(lease) &&
                widget.appState.school.cachedActiveStudentId ==
                    (lease.logStudentId == 'self' ? null : lease.studentId)));
  }

  bool get _canWork =>
      !_loading &&
      !_busy &&
      _error == null &&
      (!_clock.value || _nativeOpen) &&
      _currentProfile &&
      _controller?.canWork == true;
  bool get _reduced =>
      _quiet ||
      _supportStopped ||
      widget.appState.state.settings.reduceAnimations ||
      widget.appState.state.settings.calmMode;
  bool get _owns =>
      mounted &&
      _currentProfile &&
      (ModalRoute.of(context)?.isCurrent ?? true) &&
      identical(_bus.taskContext.value, _published);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _generation = widget.appState.profileGeneration;
    _name = widget.appState.state.childName;
    _grade = widget.appState.state.grade;
    final safe = _name.trim().isEmpty
        ? 'kind'
        : _name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    _childId = 'local_${safe}_$_grade';
    widget.appState.addListener(_profileListener);
    _clock.addListener(_pauseListener);
    _bus.learningAction.addListener(_actionListener);
    _bus.learningPresentation.addListener(_presentationListener);
    _bus.learningAudio.addListener(_audioListener);
    _bus.learningCancellation.addListener(_cancellationListener);
    _bus.helpRequested.addListener(_legacyHelp);
    unawaited(_open());
  }

  Future<void> _open() async {
    if (_busy || !_currentProfile) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lease = _lease ?? await widget.appState.captureLearningProfile();
      if (!mounted || !_currentProfile || lease.generation != _generation)
        return;
      _lease = lease;
      final owner = sha256.convert(utf8.encode(lease.studentId)).toString();
      final controller = await MiniGameRoundController.open(
        owner: owner,
        level: widget.level,
        store: _PreferenceRoundStore(
            childId: _childId, owner: owner, levelId: widget.level.id),
        canUseProfile: () => mounted && _currentProfile,
        saveLevel: (stars) async {
          await _repository.recordResult(
              childId: _childId, levelId: widget.level.id, starsEarned: stars);
        },
        award: (resultId, stars, xp) => widget.appState.recordMiniGameResult(
            lease: lease,
            resultId: resultId,
            levelId: widget.level.id,
            stars: stars,
            xp: xp),
      );
      if (!mounted || !_currentProfile) {
        controller.close();
        return;
      }
      _controller?.close();
      _controller = controller;
      _prepareTask();
      setState(() {
        _loading = false;
      });
      _publish();
      if (controller.round.finishRequested) {
        await _mutate(() async {
          await controller.settleResult();
          return true;
        });
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'Die angefangene Runde konnte nicht sicher geladen werden. '
              'Dein vorhandener Spielstand bleibt erhalten. Versuche das Laden erneut.';
        });
    }
  }

  void _prepareTask() {
    final round = _round;
    if (round == null) return;
    _workspace = round.task.workspace(
        roundId: round.id,
        childId: _childId,
        difficulty: widget.level.gradeFloor);
    _workspaceIds = const [];
    _workspaceMessage = null;
    _activeObjectId = 'game-question';
    _showHelp = false;
    _supportStopped = false;
    _hasProposal = false;
    _proposal.clear();
    _marked.clear();
    _replay = 0;
    _step = 0;
    _subtitle = null;
    _queuedHelp = 0;
  }

  void _profileListener() {
    if (!mounted || _profileChanged || _currentProfile) return;
    _profileChanged = true;
    _stopLocalVoice();
    if (_published != null && identical(_bus.taskContext.value, _published)) {
      _bus.clearTask(_published);
    }
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      if (_nativeReturnPending) {
        _clock.resume();
        setState(() {
          _nativeOpen = false;
          _nativeReturnPending = false;
        });
      }
      _publish();
    } else if (!_nativeOpen) {
      _stopSupport();
      _bus.clearTask(_published);
    }
  }

  void _pauseListener() {
    if (!mounted || _nativeOpen) return;
    if (_clock.value) {
      if (_owns) _bus.cancelLearningInteraction(reason: 'mini_game_paused');
      _stopLocalVoice();
    }
    setState(() {});
    _publish();
  }

  Future<void> _mutate(Future<bool> Function() operation) async {
    if (_busy || !_currentProfile || _controller == null) return;
    final previousTask = '${_round!.id}:${_round!.index}';
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await operation();
      while (_queuedHelp > (_round?.response.help ?? 0) &&
          _controller!.canUseProfile &&
          !_round!.response.solved(_round!.task)) {
        final help = _queuedHelp;
        _queuedHelp = 0;
        await _controller!.help(help);
      }
      if (_round!.finishRequested && !_round!.rewarded) {
        await _controller!.settleResult();
      }
      if (!mounted || !_currentProfile) return;
      if (previousTask != '${_round!.id}:${_round!.index}') {
        _stopLocalVoice();
        _prepareTask();
        if (_scroll.hasClients) _scroll.jumpTo(0);
      }
    } catch (_) {
      if (mounted)
        _error = _currentProfile
            ? 'Noch nicht gespeichert. Deine Eingabe bleibt erhalten. '
                'Tippe auf „Speichern erneut versuchen“.'
            : 'Das Kinderprofil wurde gewechselt. Öffne die Runde für das passende Profil erneut.';
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
        _publish();
        if (_round?.rewarded == true && _currentProfile) _showResult();
      }
    }
  }

  void _publish() {
    if (!_foreground && !_nativeOpen) return;
    final round = _round;
    if (round == null || _workspace == null) return;
    final id = _workspace!.taskInstanceId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          (!_foreground && !_nativeOpen) ||
          !_currentProfile ||
          _workspace?.taskInstanceId != id ||
          !(ModalRoute.of(context)?.isCurrent ?? true)) return;
      final current = _round!;
      final response = current.response;
      final task = current.task;
      final last = response.attempts.isEmpty ? null : response.attempts.last;
      final ids = _objectIds;
      final taskContext = LumoCompanionTaskContext(
        taskId: id,
        subject: switch (task.subject) {
          LearningSubject.mathematik => 'Mathematik',
          LearningSubject.deutsch => 'Deutsch',
          LearningSubject.sachkunde => 'Sachunterricht',
          LearningSubject.englisch => 'Englisch',
          LearningSubject.logik => 'Logik',
        },
        unit: widget.level.title,
        prompt: task.prompt,
        answering: _canWork,
        attempts: response.attempts.length,
        helpLevel: response.help,
        lastAnswer: last,
        lastCorrect: last == null ? null : task.accepts(last),
        localHelp: _supportStopped ? null : _visibleExplanation,
        explanation: _supportStopped ? null : _visibleExplanation,
        errorType: last != null && !task.accepts(last)
            ? 'confirmed_answer_mismatch'
            : null,
        activity: 'mini_game',
        ownerSection: 'games',
        profileGeneration: _generation,
        stepId:
            'level-${widget.level.id}/task-${current.index}/${response.solved(task) ? 'review' : 'work'}-$_step',
        objectIds: ids,
        answerChoices:
            task.input == MiniGameInput.boxes ? const [] : task.choices,
        allowedActions: {
          ...lumoDefaultLearningActions,
          LumoLearningAction.look,
          LumoLearningAction.point,
          LumoLearningAction.highlight,
          if (task.input != MiniGameInput.boxes &&
              task.input != MiniGameInput.orderedWords)
            LumoLearningAction.proposeAnswer,
        },
        isExplanation: _showHelp && !_supportStopped,
      );
      _published = taskContext;
      _bus.publishTask(taskContext);
      final identity = _bus.learningIdentity.value;
      if (identity != null && _owns && !_supportStopped && !_clock.value) {
        final target =
            ids.contains(_activeObjectId) ? _activeObjectId! : 'game-question';
        _bus.publishLearningPresentation(LumoLearningPresentation(
          identity: identity,
          gazeObjectId: target,
          pointObjectId: _showHelp ? target : null,
          expression: response.solved(task) ? 'encouraging' : 'attentive',
          animationState: _showHelp ? 'pointing' : 'observing',
        ));
      }
    });
  }

  List<String> get _objectIds {
    final task = _round!.task;
    return <String>{
      'game-question',
      'game-model',
      'game-answers',
      if (task.cue.isNotEmpty) 'game-cue',
      if (task.picture.isNotEmpty) 'game-picture',
      for (var i = 0; i < task.choices.length; i++) 'game-answer-$i',
      if (task.input == MiniGameInput.boxes)
        for (var i = 0; i < 10; i++) 'box-$i',
      if (task.input == MiniGameInput.count)
        for (var i = 0; i < task.count!; i++) 'dot-$i',
      if (task.input == MiniGameInput.house) ...[
        'house-roof',
        'house-given',
        'house-gap'
      ],
      if (task.input == MiniGameInput.letters)
        for (var i = 0; i < task.word.length; i++) 'word-letter-$i',
      if (task.input == MiniGameInput.orderedWords) ...[
        'word-order',
        for (var i = 0; i < task.choices.length; i++) 'word-token-$i',
      ],
      if (task.hour != null) ...['clock-face', 'clock-hour', 'clock-minute'],
      if (_writtenTask)
        for (var i = 0; i < _digits; i++) 'place-value-$i',
      ..._workspaceIds,
    }.toList(growable: false);
  }

  String get _visibleExplanation {
    final round = _round!;
    if (round.response.solved(round.task)) return round.task.explanation;
    if (_showHelp && round.response.help > 0)
      return round.task.hints[round.response.help - 1];
    return _workspaceMessage ?? widget.level.learningGoal;
  }

  void _actionListener() {
    final action = _bus.learningAction.value;
    if (!_owns ||
        action == null ||
        action.requestId == _handledRequest ||
        !_bus.isCurrentLearningIdentity(action.identity)) return;
    _handledRequest = action.requestId;
    switch (action.action) {
      case LumoLearningAction.stop:
        _stopSupport();
      case LumoLearningAction.hint:
      case LumoLearningAction.explain:
        _help();
      case LumoLearningAction.repeat:
        if (!_canWork) return;
        setState(() {
          _replay++;
          _supportStopped = false;
          _step++;
        });
        _publish();
        if (_round!.task.speech.isNotEmpty)
          unawaited(_read(_round!.task.speech));
      case LumoLearningAction.slower:
        if (!_canWork) return;
        setState(() {
          _slow = true;
          _supportStopped = false;
        });
        _publish();
        if (_round!.task.speech.isNotEmpty)
          unawaited(_read(_round!.task.speech));
      case LumoLearningAction.proposeAnswer:
        if (!_canWork || action.candidate == null) return;
        final text = action.candidate!.trim();
        if (text.isEmpty || text.length > 160) return;
        setState(() {
          _proposalToken++;
          _proposalIdentity = action.identity;
          _proposal.text = text;
          _hasProposal = true;
        });
      case LumoLearningAction.look:
      case LumoLearningAction.point:
      case LumoLearningAction.highlight:
        if (!_canWork || !_objectIds.contains(action.objectId)) return;
        setState(() {
          _activeObjectId = action.objectId;
          _supportStopped = false;
        });
        if (action.action != LumoLearningAction.look) _noteHelp(1);
        _publish();
    }
  }

  void _send(LumoLearningAction action) {
    if (!_owns) return;
    final identity = _bus.learningIdentity.value;
    if (identity != null)
      _bus.requestLearningAction(action, identity: identity);
  }

  void _legacyHelp() {
    if (_owns) _help();
  }

  void _help() {
    if (!_canWork) return;
    setState(() {
      _showHelp = true;
      _supportStopped = false;
    });
    _noteHelp((_round!.response.help + 1).clamp(1, 3));
  }

  void _noteHelp(int level) {
    if (_round == null || !_currentProfile) return;
    _queuedHelp = math.max(_queuedHelp, level);
    if (_busy) return;
    unawaited(_mutate(() async {
      final next = _queuedHelp;
      _queuedHelp = 0;
      return _controller!.help(next);
    }));
  }

  void _stopSupport() {
    _stopLocalVoice();
    if (!mounted) return;
    setState(() {
      _supportStopped = true;
      _showHelp = false;
      _activeObjectId = null;
      _workspaceMessage = null;
      _subtitle = null;
      _hasProposal = false;
      _proposalIdentity = null;
      _proposal.clear();
    });
    _publish();
  }

  void _cancellationListener() {
    final cancellation = _bus.learningCancellation.value;
    if (cancellation == null ||
        cancellation.reason == 'task_changed' ||
        cancellation.reason == 'context_changed') return;
    if (identical(_bus.taskContext.value, _published)) _stopSupport();
  }

  void _presentationListener() {
    final event = _bus.learningPresentation.value;
    if (!_owns ||
        event == null ||
        _supportStopped ||
        !_bus.isCurrentLearningIdentity(event.identity)) return;
    final id = event.pointObjectId ?? event.gazeObjectId;
    if (id != null && _objectIds.contains(id) && id != _activeObjectId) {
      setState(() {
        _activeObjectId = id;
      });
    }
  }

  void _audioListener() {
    final frame = _bus.learningAudio.value;
    if (!_owns ||
        frame == null ||
        _supportStopped ||
        !_bus.isCurrentLearningIdentity(frame.identity)) return;
    if (_subtitle != frame.subtitle)
      setState(() {
        _subtitle = frame.subtitle;
      });
  }

  void _workspaceEvent(TaskWorkspaceInteraction event) {
    if (_nativeOpen || !_foreground) return;
    if (!mounted ||
        !_currentProfile ||
        _workspace?.taskInstanceId != event.taskId) return;
    final ids = event.visibleState['objectIds'];
    setState(() {
      _workspaceIds =
          ids is List ? ids.whereType<String>().toSet().toList() : const [];
      if (!_supportStopped) {
        _workspaceMessage = event.explanation;
        _activeObjectId = event.objectId;
      }
      _step++;
    });
    if (event.isHelp) _noteHelp(1);
    _publish();
  }

  Future<void> _read(String text) async {
    if (!_currentProfile ||
        _clock.value ||
        !widget.appState.state.settings.voiceEnabled) return;
    final revision = ++_voiceRevision;
    final taskId = _workspace?.taskInstanceId;
    _reading = true;
    final voice = LumoVoice.instance;
    try {
      await voice.stop();
      if (!mounted || !_currentProfile || revision != _voiceRevision) return;
      await voice.configure(
          rate: widget.appState.state.settings.voiceRate * (_slow ? .75 : 1));
      if (!mounted ||
          !_currentProfile ||
          revision != _voiceRevision ||
          taskId != _workspace?.taskInstanceId) return;
      await voice.speakAndWait(text, style: VoiceStyle.explain);
      if (mounted &&
          revision == _voiceRevision &&
          voice.status.value == VoiceStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Das Wort kann gerade nicht vorgelesen werden. Bild und Buchstaben bleiben zum Üben sichtbar.')));
      }
    } catch (_) {
      // The exact word stays available; no recognition or audio failure is graded.
    } finally {
      if (revision == _voiceRevision) {
        _reading = false;
        await voice.configure(rate: widget.appState.state.settings.voiceRate);
      }
    }
  }

  void _stopLocalVoice() {
    ++_voiceRevision;
    if (!_reading) return;
    _reading = false;
    unawaited(LumoVoice.instance.stop());
    unawaited(LumoVoice.instance
        .configure(rate: widget.appState.state.settings.voiceRate));
  }

  Future<void> _confirm([String? proposal]) async {
    if (!_foreground || _nativeOpen || !_canWork) return;
    if (proposal != null &&
        (_proposalIdentity == null ||
            !_bus.isCurrentLearningIdentity(_proposalIdentity!))) return;
    _stopLocalVoice();
    await _mutate(() => _controller!.answer(proposal));
    if (!mounted || _round == null) return;
    setState(() {
      _hasProposal = false;
    });
    _publish();
  }

  void _showResult() {
    if (_resultShown || !mounted || _round?.rewarded != true) return;
    _resultShown = true;
    _stopLocalVoice();
    final round = _round!;
    widget.onResult?.call(round.levelStars);
    showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialog) => LumoGameResultBack(
                child: AlertDialog(
              title: const Text('Geschafft!'),
              content: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                const LumoCompanionAvatar(
                    mood: LumoCompanionMood.cheer, size: 96),
                Text(
                    '${round.solvedCount} von ${round.tasks.length} Aufgaben gelöst.',
                    key: const ValueKey('mini-game-result-count')),
                const SizedBox(height: 8),
                Text(
                    '${round.independentCount} beim ersten Versuch ohne Hinweis. '
                    'Deine ${round.walletStars} Sterne und ${round.xp} XP sind gespeichert.'),
                const SizedBox(height: 8),
                Text(round.independentCount < round.tasks.length
                    ? 'Ein weiterer Durchgang übt dasselbe Lernziel. Du kannst die Hinweise wieder nutzen.'
                    : 'Du hast diese Aufgaben ohne Hinweis gelöst. Der nächste freigeschaltete Level wartet in der Spielewelt.'),
              ])),
              actions: [
                TextButton(
                    style:
                        TextButton.styleFrom(minimumSize: const Size(48, 48)),
                    onPressed: () {
                      Navigator.of(dialog).pop();
                      _resultShown = false;
                      unawaited(_mutate(() => _controller!.restart()));
                    },
                    child: const Text('Noch einmal')),
                FilledButton(
                    style:
                        FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                    onPressed: () {
                      Navigator.of(dialog).pop();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Zur Spielewelt')),
              ],
            )));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.appState.removeListener(_profileListener);
    _clock.removeListener(_pauseListener);
    _bus.learningAction.removeListener(_actionListener);
    _bus.learningPresentation.removeListener(_presentationListener);
    _bus.learningAudio.removeListener(_audioListener);
    _bus.learningCancellation.removeListener(_cancellationListener);
    _bus.helpRequested.removeListener(_legacyHelp);
    _stopLocalVoice();
    _controller?.close();
    final published = _published;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _bus.clearTask(published));
    _clock.dispose();
    _scroll.dispose();
    _proposal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final round = _round;
    final task = round?.task;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
          disableAnimations:
              _reduced || MediaQuery.disableAnimationsOf(context)),
      child: LumoGamePauseScope(
          clock: _clock,
          onRestart: () {
            if (_busy ||
                _loading ||
                _controller == null ||
                _controller!.hasPending ||
                !_currentProfile) return;
            _resultShown = false;
            unawaited(_mutate(() => _controller!.restart()));
          },
          child: Scaffold(
            backgroundColor: LumoBoardColors.backdrop,
            appBar: AppBar(
              backgroundColor: LumoBoardColors.backdrop,
              foregroundColor: Colors.white,
              leading: IconButton(
                  tooltip: 'Pausieren / Zurück',
                  constraints:
                      const BoxConstraints(minWidth: 48, minHeight: 48),
                  onPressed: _clock.pause,
                  icon: const Icon(Icons.pause_rounded)),
              title: Text(widget.level.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 19)),
              actions: [
                IconButton(
                    key: const ValueKey('mini-game-quiet'),
                    tooltip: _quiet ? 'Ruhiger Modus aktiv' : 'Ruhiger Modus',
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: () => setState(() {
                          _quiet = !_quiet;
                        }),
                    icon: Icon(_quiet
                        ? Icons.self_improvement
                        : Icons.motion_photos_off))
              ],
            ),
            body: LumoBoardGameStage(
                child: SafeArea(
              child: _loading || round == null
                  ? Center(
                      child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            if (_loading) const CircularProgressIndicator(),
                            Text(
                                _error ??
                                    'Deine Lernspiel-Runde wird vorbereitet.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white)),
                            if (!_loading)
                              _button('mini-game-load-retry',
                                  'Runde erneut laden', Icons.refresh, _open),
                          ])))
                  : SingleChildScrollView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      child: Center(
                          child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 840),
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    LumoBoardRoundProgress(
                                        currentIndex: round.index,
                                        total: round.tasks.length,
                                        correct: round.solvedCount,
                                        reduceMotion: _reduced),
                                    const SizedBox(height: 12),
                                    Container(
                                        padding: const EdgeInsets.all(18),
                                        decoration: lumoBoardGlass(),
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    LumoCompanionAvatar(
                                                        size: 58,
                                                        mood: round.response
                                                                .solved(task!)
                                                            ? LumoCompanionMood
                                                                .cheer
                                                            : _showHelp
                                                                ? LumoCompanionMood
                                                                    .help
                                                                : LumoCompanionMood
                                                                    .idle),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                        child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                          Text(
                                                              'Lernziel · ${widget.level.learningGoal}',
                                                              key: const ValueKey(
                                                                  'mini-game-learning-goal'),
                                                              style: const TextStyle(
                                                                  fontSize: 15,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
                                                                  color:
                                                                      LumoBoardColors
                                                                          .ink)),
                                                          if (_controller!
                                                              .restored)
                                                            const Text(
                                                                'Deine angefangene Runde ist wieder da.',
                                                                key: ValueKey(
                                                                    'mini-game-resumed'),
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                    color: LumoBoardColors
                                                                        .mutedInk)),
                                                        ])),
                                                  ]),
                                              const SizedBox(height: 18),
                                              Semantics(
                                                  header: true,
                                                  child: Text(task.prompt,
                                                      key: const ValueKey(
                                                          'mini-game-question'),
                                                      style: const TextStyle(
                                                          fontSize: 24,
                                                          height: 1.25,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          color: LumoBoardColors
                                                              .ink))),
                                              const SizedBox(height: 18),
                                              _model(task, round.response),
                                              const SizedBox(height: 16),
                                              _controls(task),
                                              if (_showHelp &&
                                                  round.response.help > 0 &&
                                                  !_supportStopped) ...[
                                                const SizedBox(height: 12),
                                                Semantics(
                                                    liveRegion: true,
                                                    child: Text(
                                                        'Hinweis ${round.response.help} von 3: ${task.hints[round.response.help - 1]}',
                                                        key: const ValueKey(
                                                            'mini-game-hint'),
                                                        style: const TextStyle(
                                                            fontSize: 17,
                                                            height: 1.35,
                                                            color:
                                                                LumoBoardColors
                                                                    .ink))),
                                                _button(
                                                    'mini-game-self-try',
                                                    'Ich möchte es selbst versuchen',
                                                    Icons.touch_app,
                                                    () => _send(
                                                        LumoLearningAction
                                                            .stop)),
                                              ],
                                              if (_subtitle?.isNotEmpty ??
                                                  false)
                                                Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 12),
                                                    child: Text(_subtitle!,
                                                        key: const ValueKey(
                                                            'mini-game-subtitle'),
                                                        style: const TextStyle(
                                                            color:
                                                                LumoBoardColors
                                                                    .ink,
                                                            fontSize: 16))),
                                              if (_hasProposal)
                                                _proposalEditor(task),
                                              const SizedBox(height: 16),
                                              if (task.input !=
                                                      MiniGameInput.boxes &&
                                                  task.input !=
                                                      MiniGameInput
                                                          .orderedWords)
                                                _choices(task, round.response),
                                              if (round.response.attempts
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 12),
                                                Semantics(
                                                    liveRegion: true,
                                                    child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Icon(
                                                              round.response
                                                                      .solved(
                                                                          task)
                                                                  ? Icons
                                                                      .check_circle
                                                                  : Icons
                                                                      .refresh_rounded,
                                                              color: round
                                                                      .response
                                                                      .solved(
                                                                          task)
                                                                  ? const Color(
                                                                      0xFF087B56)
                                                                  : const Color(
                                                                      0xFF9A4B06)),
                                                          const SizedBox(
                                                              width: 8),
                                                          Expanded(
                                                              child: Text(
                                                                  round.response
                                                                          .solved(
                                                                              task)
                                                                      ? task
                                                                          .explanation
                                                                      : _retryText(
                                                                          task,
                                                                          round
                                                                              .response),
                                                                  key: const ValueKey(
                                                                      'mini-game-feedback'),
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          17,
                                                                      color: LumoBoardColors
                                                                          .ink))),
                                                        ])),
                                              ],
                                              if (_profileChanged)
                                                const Padding(
                                                    padding: EdgeInsets.all(12),
                                                    child: Text(
                                                        'Das Kinderprofil wurde gewechselt. Öffne die Lernspiel-Runde für das passende Profil erneut.',
                                                        key: ValueKey(
                                                            'mini-game-profile-changed'),
                                                        style: TextStyle(
                                                            color: Color(
                                                                0xFF84260F)))),
                                              if (_error != null) ...[
                                                const SizedBox(height: 12),
                                                Text(_error!,
                                                    key: const ValueKey(
                                                        'mini-game-save-error'),
                                                    style: const TextStyle(
                                                        color:
                                                            Color(0xFF84260F),
                                                        fontWeight:
                                                            FontWeight.w700)),
                                                _button(
                                                    'mini-game-save-retry',
                                                    'Speichern erneut versuchen',
                                                    Icons.save,
                                                    !_busy && _currentProfile
                                                        ? () =>
                                                            _mutate(() async {
                                                              await _controller!
                                                                  .retry();
                                                              return true;
                                                            })
                                                        : null),
                                              ],
                                              const SizedBox(height: 16),
                                              _button(
                                                  'mini-game-check',
                                                  _busy
                                                      ? 'Wird gespeichert …'
                                                      : round.response
                                                              .solved(task)
                                                          ? round.index + 1 ==
                                                                  round.tasks
                                                                      .length
                                                              ? 'Spiel beenden'
                                                              : 'Weiter'
                                                          : task.input ==
                                                                  MiniGameInput
                                                                      .boxes
                                                              ? 'Prüfen'
                                                              : task.input ==
                                                                      MiniGameInput
                                                                          .orderedWords
                                                                  ? 'Satz prüfen'
                                                                  : 'Antwort prüfen',
                                                  round.response.solved(task)
                                                      ? Icons.arrow_forward
                                                      : Icons.check,
                                                  _canAdvance
                                                      ? () => _mutate(() =>
                                                          _controller!.next())
                                                      : _canConfirm
                                                          ? () => _confirm()
                                                          : null),
                                            ])),
                                  ])))),
            )),
          )),
    );
  }

  bool get _canAdvance =>
      !_busy &&
      !_loading &&
      _error == null &&
      !_clock.value &&
      _currentProfile &&
      _controller?.hasPending == false &&
      _round?.response.solved(_round!.task) == true &&
      !_round!.finishRequested;

  bool get _canConfirm {
    if (!_canWork) return false;
    final task = _round!.task, response = _round!.response;
    if (task.input == MiniGameInput.boxes) return true;
    if (task.input == MiniGameInput.orderedWords)
      return response.order.length == task.choices.length;
    return response.selected != null &&
        (response.attempts.isEmpty ||
            response.selected != response.attempts.last);
  }

  Widget _button(
          String key, String label, IconData icon, VoidCallback? action) =>
      Padding(
          padding: const EdgeInsets.only(top: 8),
          child: FilledButton.icon(
              key: ValueKey(key),
              onPressed: action,
              style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 52),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              icon: Icon(icon),
              label: Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800))));

  Future<void> _openNativeLearning() async {
    final before = _bus.learningIdentity.value;
    if (!_canWork || !_owns || _nativeOpen || before == null) return;
    final taskId = _workspace!.taskInstanceId;
    _stopLocalVoice();
    _hasProposal = false;
    _proposalIdentity = null;
    _showHelp = true;
    await _mutate(() => _controller!
        .help(_round!.response.help < 1 ? 1 : _round!.response.help));
    await WidgetsBinding.instance.endOfFrame;
    final current = _bus.learningIdentity.value;
    if (!mounted ||
        !_foreground ||
        !_canWork ||
        !_owns ||
        _error != null ||
        taskId != _workspace?.taskInstanceId ||
        current == null ||
        before.sessionId != current.sessionId ||
        before.taskId != current.taskId ||
        current.cancelEpoch - before.cancelEpoch !=
            current.revision - before.revision) return;
    setState(() => _nativeOpen = true);
    try {
      await launchLumo3D(context,
          scene: 'learning',
          appState: widget.appState,
          subject: _published!.subject,
          learning: NativeLearningActivity.forTask(_workspace!));
    } finally {
      if (mounted && taskId == _workspace?.taskInstanceId) {
        if (_foreground) _clock.resume();
        setState(() {
          _nativeReturnPending = !_foreground;
          _nativeOpen = !_foreground;
        });
        if (!_nativeOpen) _publish();
      }
    }
  }

  Widget _controls(MiniGameLearningTask task) =>
      Wrap(spacing: 8, runSpacing: 8, children: [
        _smallControl(
            'mini-game-native-learning',
            'Mit Lumo in 3D',
            Icons.view_in_ar_rounded,
            _canWork && !_nativeOpen
                ? () => unawaited(_openNativeLearning())
                : null),
        _smallControl(
            'mini-game-help',
            _round!.response.help == 0 ? 'Hilf mir' : 'Anders erklären',
            Icons.lightbulb_outline,
            _canWork ? () => _send(LumoLearningAction.hint) : null),
        _smallControl('mini-game-repeat', 'Noch einmal', Icons.replay,
            _canWork ? () => _send(LumoLearningAction.repeat) : null),
        _smallControl(
            'mini-game-slower',
            _slow ? 'Langsamer aktiv' : 'Langsamer',
            Icons.slow_motion_video,
            _canWork ? () => _send(LumoLearningAction.slower) : null),
        _smallControl('mini-game-stop', 'Stopp', Icons.stop_circle_outlined,
            _currentProfile ? () => _send(LumoLearningAction.stop) : null),
        if (task.speech.isNotEmpty)
          _smallControl(
              'mini-game-listen',
              'Wort anhören',
              Icons.volume_up,
              _canWork
                  ? () {
                      _supportStopped = false;
                      unawaited(_read(task.speech));
                    }
                  : null),
      ]);

  Widget _smallControl(
          String key, String text, IconData icon, VoidCallback? action) =>
      OutlinedButton.icon(
          key: ValueKey(key),
          onPressed: action,
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: LumoBoardColors.ink,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
          icon: Icon(icon, size: 21),
          label: Text(text));

  Widget _choices(MiniGameLearningTask task, MiniGameResponse response) =>
      LayoutBuilder(builder: (context, constraints) {
        final two = constraints.maxWidth > 540 &&
            MediaQuery.textScalerOf(context).scale(1) < 1.5;
        final width =
            two ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;
        return Wrap(spacing: 12, runSpacing: 10, children: [
          for (var i = 0; i < task.choices.length; i++)
            SizedBox(
                width: width,
                child: OutlinedButton(
                  key: task.input == MiniGameInput.letters
                      ? ValueKey('letter-choice-${task.choices[i]}')
                      : widget.level.miniType == GameMiniType.starsPath ||
                              widget.level.miniType == GameMiniType.numberHouse
                          ? ValueKey('math-option-$i')
                          : ValueKey('lesson-answer-${task.choices[i]}'),
                  style: OutlinedButton.styleFrom(
                      animationDuration: _reduced
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      minimumSize: const Size(48, 58),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      foregroundColor: LumoBoardColors.ink,
                      backgroundColor: response.selected == task.choices[i]
                          ? const Color(0xFFD5F5FB)
                          : Colors.white,
                      side: BorderSide(
                          width: response.selected == task.choices[i] ? 3 : 1.5,
                          color: _activeObjectId == 'game-answer-$i'
                              ? const Color(0xFFA66100)
                              : const Color(0xFF248B9E))),
                  onPressed: _canWork
                      ? () =>
                          _mutate(() => _controller!.select(task.choices[i]))
                      : null,
                  child: Row(children: [
                    Expanded(
                        child: Text(task.choices[i],
                            style: const TextStyle(
                                fontSize: 23, fontWeight: FontWeight.w900))),
                    if (response.selected == task.choices[i])
                      Icon(
                          response.solved(task)
                              ? Icons.check_circle
                              : Icons.radio_button_checked,
                          size: 24),
                  ]),
                )),
        ]);
      });

  Widget _proposalEditor(MiniGameLearningTask task) {
    final captured = _proposalIdentity;
    final token = _proposalToken;
    String? matching() {
      final candidate = _proposal.text.trim().toLowerCase();
      final values = task.choices
          .where((value) => value.toLowerCase() == candidate)
          .toList();
      return values.length == 1 ? values.single : null;
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 16),
      const Text('LUMO hat einen Antwortvorschlag gehört. Prüfe ihn selbst.',
          style: TextStyle(
              color: LumoBoardColors.ink, fontWeight: FontWeight.w700)),
      TextField(
          key: const ValueKey('mini-game-answer-proposal'),
          controller: _proposal,
          enabled: _canWork,
          maxLength: 160,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: LumoBoardColors.ink),
          decoration:
              const InputDecoration(labelText: 'Dein bearbeitbarer Vorschlag')),
      _button(
          'mini-game-proposal-confirm',
          'Diese Antwort bestätigen',
          Icons.check,
          _canWork && matching() != null
              ? () {
                  if (!_hasProposal ||
                      token != _proposalToken ||
                      captured == null ||
                      _proposalIdentity?.matches(captured) != true) return;
                  unawaited(_confirm(matching()));
                }
              : null),
    ]);
  }

  String _retryText(MiniGameLearningTask task, MiniGameResponse response) {
    if (task.input == MiniGameInput.boxes)
      return 'Du hast ${response.boxes.where((box) => box).length} Kästchen angemalt. '
          'Das Ziel ist ${task.targetCount}. Du kannst deine Menge verändern und erneut prüfen.';
    if (task.input == MiniGameInput.letters)
      return 'Der eingesetzte Buchstabe passt noch nicht zum ganzen Wort. '
          'Die Aufgabe bleibt da. Wähle einen anderen Buchstaben oder bitte um Hilfe.';
    return 'Deine Antwort passt noch nicht. Die Aufgabe bleibt da. '
        'Prüfe die sichtbaren Angaben und versuche es noch einmal.';
  }

  bool get _writtenTask =>
      _round?.task.visual.type == VisualType.writtenArithmetic;
  int get _digits {
    final data = _round!.task.visual.data;
    return math.max('${data['a']}'.length, '${data['b']}'.length);
  }

  Widget _model(MiniGameLearningTask task, MiniGameResponse response) {
    if (task.input == MiniGameInput.boxes) return _boxes(task, response);
    if (task.input == MiniGameInput.letters) return _letters(task, response);
    if (task.input == MiniGameInput.house) return _house(task, response);
    if (task.input == MiniGameInput.orderedWords)
      return _orderedWords(task, response);
    if (task.input == MiniGameInput.count) return _count(task);
    if (_writtenTask) return _written(task);
    return Column(children: [
      if (task.hour != null) ...[
        Semantics(
            label: 'Analoge Uhr mit Stunden- und Minutenzeiger',
            child: SizedBox(
                width: 190,
                height: 190,
                child: CustomPaint(
                    painter: _MiniGameClockPainter(
                        task.hour!, task.minute, _activeObjectId)))),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _smallControl(
              'mini-game-hour-hand',
              'Kurzer Zeiger',
              Icons.watch_later_outlined,
              _canWork
                  ? () => _focus(
                      'clock-hour', 'Der kurze Zeiger zeigt die Stunden.')
                  : null),
          _smallControl(
              'mini-game-minute-hand',
              'Langer Zeiger',
              Icons.timer_outlined,
              _canWork
                  ? () => _focus(
                      'clock-minute', 'Der lange Zeiger zeigt die Minuten.')
                  : null),
        ]),
      ],
      if (task.picture.isNotEmpty) _picture(task.picture),
      if (task.cue.isNotEmpty)
        Text(task.cue,
            key: const ValueKey('mini-game-cue'),
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: LumoBoardColors.ink)),
      if (task.numbers.isNotEmpty)
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final number in task.numbers)
            Container(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFDFF5FB),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(number < 0 ? '?' : '$number',
                    style: const TextStyle(
                        fontSize: 25,
                        color: LumoBoardColors.ink,
                        fontWeight: FontWeight.w900)))
        ]),
      const SizedBox(height: 12),
      InteractiveTaskWorkspace(
          task: _workspace!,
          enabled: _canWork,
          reduceMotion: _reduced,
          slow: _slow,
          replaySerial: _replay,
          activeObjectId: _supportStopped ? null : _activeObjectId,
          helpLevel: _showHelp && !_supportStopped ? response.help : 0,
          showSolution: response.solved(task),
          onInteraction: _workspaceEvent),
    ]);
  }

  void _focus(String id, String explanation) {
    if (!_canWork) return;
    setState(() {
      _activeObjectId = id;
      _workspaceMessage = explanation;
      _step++;
    });
    _publish();
  }

  Widget _boxes(MiniGameLearningTask task, MiniGameResponse response) =>
      Column(children: [
        Text('${task.targetCount}',
            style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w900,
                color: Color(0xFF935500))),
        Text('Deine Menge: ${response.boxes.where((box) => box).length} von 10',
            key: const ValueKey('mini-game-visible-quantity'),
            style: const TextStyle(fontSize: 17, color: LumoBoardColors.ink)),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, constraints) {
          // Keep the mathematical 2 × 5 ten-frame, even on a very small viewport.
          // Horizontal scrolling protects each 48 dp cell instead of shrinking it.
          final side =
              math.max(48.0, math.min(64.0, (constraints.maxWidth - 24) / 5));
          return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(children: [
                for (var row = 0; row < 2; row++)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(children: [
                        for (var column = 0; column < 5; column++)
                          Padding(
                              padding:
                                  EdgeInsets.only(right: column == 4 ? 0 : 6),
                              child: Semantics(
                                  key:
                                      ValueKey('color-box-${row * 5 + column}'),
                                  label:
                                      'Kästchen ${row * 5 + column + 1}, ${response.boxes[row * 5 + column] ? 'angemalt' : 'leer'}',
                                  selected: response.boxes[row * 5 + column],
                                  button: true,
                                  child: SizedBox(
                                      width: side,
                                      height: side,
                                      child: Material(
                                        color: response.boxes[row * 5 + column]
                                            ? const Color(0xFFFFB73E)
                                            : Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            side: BorderSide(
                                                width: _activeObjectId ==
                                                        'box-${row * 5 + column}'
                                                    ? 4
                                                    : 2,
                                                color:
                                                    const Color(0xFF95560D))),
                                        child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            onTap: _canWork
                                                ? () => _mutate(() =>
                                                    _controller!.toggleBox(
                                                        row * 5 + column))
                                                : null,
                                            child: response
                                                    .boxes[row * 5 + column]
                                                ? const Icon(Icons.check,
                                                    color: Color(0xFF573000),
                                                    size: 28)
                                                : const Icon(Icons.add,
                                                    color: Color(0xFF95560D),
                                                    size: 20)),
                                      )))),
                      ])),
              ]));
        }),
      ]);

  Widget _letters(MiniGameLearningTask task, MiniGameResponse response) =>
      Column(children: [
        _picture(task.picture),
        const SizedBox(height: 10),
        Wrap(
            spacing: 6,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < task.word.length; i++)
                SizedBox(
                    width: 48,
                    height: 64,
                    child: OutlinedButton(
                      key: ValueKey('word-letter-$i'),
                      onPressed: _canWork
                          ? () => _focus(
                              'word-letter-$i',
                              i == task.gapIndex
                                  ? 'Hier fehlt der Buchstabe an Stelle ${i + 1}.'
                                  : 'An Stelle ${i + 1} steht ${task.word[i]}.')
                          : null,
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 64),
                          padding: EdgeInsets.zero,
                          foregroundColor: LumoBoardColors.ink,
                          backgroundColor: i == task.gapIndex
                              ? const Color(0xFFFFEDB8)
                              : Colors.white,
                          side: BorderSide(
                              width: i == task.gapIndex ||
                                      _activeObjectId == 'word-letter-$i'
                                  ? 3
                                  : 1,
                              color: const Color(0xFF477B9D))),
                      child: Text(
                          i == task.gapIndex
                              ? response.selected ?? '?'
                              : task.word[i],
                          style: const TextStyle(
                              fontSize: 29, fontWeight: FontWeight.w900)),
                    )),
            ]),
      ]);

  Widget _house(MiniGameLearningTask task, MiniGameResponse response) {
    final house = task.house!;
    Widget room(String id, String text, String label) => SizedBox(
        width: 108,
        child: OutlinedButton(
            onPressed: _canWork ? () => _focus(id, label) : null,
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 84),
                backgroundColor:
                    id == 'house-gap' ? const Color(0xFFFFE7A3) : Colors.white,
                foregroundColor: LumoBoardColors.ink,
                side: BorderSide(
                    color: const Color(0xFF1C7F9E),
                    width: _activeObjectId == id ? 4 : 2)),
            child: Text(text,
                style: const TextStyle(
                    fontSize: 34, fontWeight: FontWeight.w900))));
    final given = room('house-given', '${house.visibleRoom}',
        'Im gegebenen Zimmer steht ${house.visibleRoom}.');
    final missing = room('house-gap', response.selected ?? '?',
        'Dieses Zimmer ergänzt die Menge bis ${house.roof}.');
    return Column(children: [
      Semantics(
          label: 'Dachzahl ${house.roof}',
          child: Container(
              width: 240,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: const BoxDecoration(
                  color: Color(0xFF164F79),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(52))),
              child: Text('${house.roof}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 38,
                      color: Colors.white,
                      fontWeight: FontWeight.w900)))),
      const SizedBox(height: 8),
      Wrap(spacing: 12, runSpacing: 8, children: [
        if (house.missingLeft) missing else given,
        if (house.missingLeft) given else missing,
      ]),
      const SizedBox(height: 12),
      Text(task.cue,
          style: const TextStyle(
              color: LumoBoardColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w800)),
    ]);
  }

  Widget _orderedWords(MiniGameLearningTask task, MiniGameResponse response) =>
      Column(children: [
        Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            constraints: const BoxConstraints(minHeight: 64),
            decoration: BoxDecoration(
                color: const Color(0xFFDFF4FA),
                borderRadius: BorderRadius.circular(14)),
            child: Text(
                response.order.isEmpty
                    ? 'Dein Satz entsteht hier.'
                    : response.order.map((i) => task.choices[i]).join(' '),
                key: const ValueKey('mini-game-word-order'),
                style: const TextStyle(
                    fontSize: 24,
                    color: LumoBoardColors.ink,
                    fontWeight: FontWeight.w800))),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (var i = 0; i < task.choices.length; i++)
            _smallControl(
                'mini-game-word-$i',
                task.choices[i],
                response.order.contains(i) ? Icons.check : Icons.add,
                _canWork && !response.order.contains(i)
                    ? () => _mutate(() => _controller!.orderWord(i))
                    : null)
        ]),
        _smallControl('mini-game-order-reset', 'Neu ordnen', Icons.replay,
            _canWork ? () => _mutate(_controller!.clearOrder) : null),
      ]);

  Widget _count(MiniGameLearningTask task) => Column(children: [
        Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < task.count!; i++)
                SizedBox(
                    width: 52,
                    height: 52,
                    child: Semantics(
                        label:
                            'Punkt ${i + 1}${_marked.contains(i) ? ', markiert' : ''}',
                        child: Material(
                            shape: const CircleBorder(),
                            color: const Color(0xFFFFBF4B),
                            child: InkWell(
                                customBorder: const CircleBorder(),
                                key: ValueKey('mini-game-dot-$i'),
                                onTap: _canWork
                                    ? () {
                                        setState(() {
                                          if (!_marked.add(i))
                                            _marked.remove(i);
                                        });
                                        _focus('dot-$i',
                                            'Du hast ${_marked.length} verschiedene Punkte markiert.');
                                      }
                                    : null,
                                child: _marked.contains(i)
                                    ? const Icon(Icons.check,
                                        color: Color(0xFF6E3E00))
                                    : null)))),
            ]),
        const SizedBox(height: 12),
        const Text('Du kannst jeden Punkt einmal markieren.',
            style: TextStyle(color: LumoBoardColors.mutedInk, fontSize: 15)),
      ]);

  Widget _written(MiniGameLearningTask task) {
    final data = task.visual.data;
    final a = '${data['a']}'.padLeft(_digits, ' '),
        b = '${data['b']}'.padLeft(_digits, ' ');
    return Column(children: [
      Text(
          data['operation'] == 'subtraction'
              ? 'Minus · gleiche Stellen untereinander'
              : 'Plus · gleiche Stellen untereinander',
          style: const TextStyle(
              color: LumoBoardColors.ink, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (var i = 0; i < _digits; i++)
          SizedBox(
              width: 58,
              child: OutlinedButton(
                onPressed: _canWork
                    ? () => _focus('place-value-$i',
                        'Diese Spalte zeigt ${a[i].trim().isEmpty ? 0 : a[i]} oben und ${b[i].trim().isEmpty ? 0 : b[i]} unten. Beginne rechts bei den Einern.')
                    : null,
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 110),
                    padding: const EdgeInsets.all(8),
                    side: BorderSide(
                        color: const Color(0xFF1C7F9E),
                        width: _activeObjectId == 'place-value-$i' ? 4 : 1.5)),
                child: Column(children: [
                  Text(['E', 'Z', 'H', 'T'][_digits - i - 1],
                      style: const TextStyle(color: LumoBoardColors.mutedInk)),
                  Text(a[i],
                      style: const TextStyle(
                          color: LumoBoardColors.ink,
                          fontSize: 30,
                          fontWeight: FontWeight.w900)),
                  Text(b[i],
                      style: const TextStyle(
                          color: LumoBoardColors.ink,
                          fontSize: 30,
                          fontWeight: FontWeight.w900)),
                  const Divider(color: LumoBoardColors.ink),
                  const Text('?',
                      style:
                          TextStyle(color: LumoBoardColors.ink, fontSize: 25)),
                ]),
              )),
      ]),
    ]);
  }

  Widget _picture(String key) {
    const pictograms = {
      'mouse': '🐭',
      'dog': '🐕',
      'cat': '🐱',
      'horse': '🐎',
      'fish': '🐟',
      'sun': '☀️',
      'car': '🚗',
      'tree': '🌳',
      'apple': '🍎',
      'book': '📖',
      'house': '🏠',
      'flower': '🌸',
      'bird': '🐦',
      'school': '🏫',
      'friend': '🧑‍🤝‍🧑',
      'games': '🎮',
      'rain': '🌧️',
      'star': '⭐',
      'milk': '🥛',
      'banana': '🍌',
      'elephant': '🐘',
      'tomato': '🍅',
    };
    final emoji = pictograms[key];
    if (emoji != null)
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(emoji,
              key: const ValueKey('mini-game-picture'),
              style: const TextStyle(fontSize: 88)));
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Icon(
            switch (key) {
              'house' => Icons.home_rounded,
              'fish' => Icons.set_meal_rounded,
              'ball' => Icons.sports_soccer_rounded,
              'star' => Icons.star_rounded,
              'tree' => Icons.park_rounded,
              'hat' => Icons.checkroom_rounded,
              'egg' => Icons.egg_rounded,
              'money' => Icons.payments_rounded,
              'animal' ||
              'cat' ||
              'dog' ||
              'horse' ||
              'mouse' =>
                Icons.pets_rounded,
              'rain' => Icons.water_drop_rounded,
              'sun' => Icons.wb_sunny_rounded,
              'snow' => Icons.ac_unit_rounded,
              'storm' => Icons.thunderstorm_rounded,
              'cloud' => Icons.cloud_rounded,
              'plant' || 'flower' => Icons.local_florist_rounded,
              'car' => Icons.directions_car_rounded,
              'apple' => Icons.apple,
              'book' => Icons.menu_book,
              'bird' => Icons.flutter_dash,
              'table' => Icons.table_restaurant,
              'school' => Icons.school,
              'friend' => Icons.people_alt,
              'games' => Icons.sports_esports,
              'milk' => Icons.local_drink,
              _ => Icons.category,
            },
            key: const ValueKey('mini-game-picture'),
            size: 88,
            color: const Color(0xFF196C92)));
  }
}

class _PreferenceRoundStore implements MiniGameRoundStore {
  const _PreferenceRoundStore(
      {required this.childId, required this.owner, required this.levelId});
  final String childId, owner;
  final int levelId;
  @override
  Future<String?> read() => const GameProgressRepository()
      .loadRound(childId: childId, owner: owner, levelId: levelId);
  @override
  Future<void> write(String snapshot) =>
      const GameProgressRepository().saveRound(
          childId: childId, owner: owner, levelId: levelId, snapshot: snapshot);
}

class _MiniGameClockPainter extends CustomPainter {
  const _MiniGameClockPainter(this.hour, this.minute, this.focus);
  final int hour, minute;
  final String? focus;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero), radius = size.shortestSide / 2 - 4;
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFF6FAFE));
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = const Color(0xFF1C5C7D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    for (var number = 1; number <= 12; number++) {
      final angle = number * math.pi / 6 - math.pi / 2;
      final label = TextPainter(
          textDirection: TextDirection.ltr,
          text: TextSpan(
              text: '$number',
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF12364B))))
        ..layout();
      final at =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * .79;
      label.paint(canvas, at - Offset(label.width / 2, label.height / 2));
    }
    void hand(
        double angle, double length, bool selected, Color color, double width) {
      final end =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * length;
      if (selected)
        canvas.drawLine(
            center,
            end,
            Paint()
              ..color = const Color(0xFFFFC250)
              ..strokeWidth = width + 8
              ..strokeCap = StrokeCap.round);
      canvas.drawLine(
          center,
          end,
          Paint()
            ..color = color
            ..strokeWidth = width
            ..strokeCap = StrokeCap.round);
    }

    hand((hour % 12 + minute / 60) * math.pi / 6 - math.pi / 2, .47,
        focus == 'clock-hour', const Color(0xFF173D69), 7);
    hand(minute * math.pi / 30 - math.pi / 2, .68, focus == 'clock-minute',
        const Color(0xFF008C9B), 4);
    canvas.drawCircle(center, 6, Paint()..color = const Color(0xFF173D69));
  }

  @override
  bool shouldRepaint(covariant _MiniGameClockPainter old) =>
      hour != old.hour || minute != old.minute || focus != old.focus;
}
