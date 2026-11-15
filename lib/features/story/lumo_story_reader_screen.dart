// ════════════════════════════════════════════════════════════════════════
// LUMO STORY READER — Lese-Heft mit Live-Bildern + Lern-Stops
// ════════════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_state.dart';
import '../../app/lumo_companion_host.dart';
import '../../core/lumo_feature_permissions.dart';
import '../../core/learning_attempt_id.dart';
import '../../core/lumo_learning_session_contract.dart';
import '../../core/lumo_speech_listener.dart';
import '../../core/lumo_story_generator.dart';
import '../../core/lumo_story_library.dart';
import '../../core/lumo_story_summary_scoring.dart';
import '../../core/lumo_voice.dart';
import '../../theme/lumo_design_tokens.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../../widgets/design/lumo_motion.dart';
import '../../widgets/fox/lumo_companion_requests.dart';
import '../../widgets/premium/lumo_premium_card.dart';
import '../../widgets/premium/lumo_reward_burst.dart';
import '../writing/lumo_writing_coach_screen.dart';
import 'widgets/lumo_story_scene.dart';

class LumoStoryReaderScreen extends StatefulWidget {
  const LumoStoryReaderScreen({
    super.key,
    required this.story,
    required this.appState,
    this.storyId,
    this.speechListener,
  });

  final LumoStory story;
  final LumoAppState appState;

  /// Wenn null: Story ist neu und wird beim Beenden gespeichert.
  /// Wenn gesetzt: Story kommt schon aus der Bibliothek.
  final String? storyId;

  /// Optional dependency for the existing local recognition interface.
  final LumoSpeechListener? speechListener;

  @override
  State<LumoStoryReaderScreen> createState() => _LumoStoryReaderScreenState();
}

class _LumoStoryReaderScreenState extends State<LumoStoryReaderScreen>
    with WidgetsBindingObserver {
  int _pageIdx = 0;
  bool _exerciseDone = false;
  String? _selectedAnswer;
  // Zusammenfassungs-Phase nach der letzten Seite (Heinz' Wunsch:
  // "Am Schluss wird gefragt um was es geht und das Kind kann erklaeren,
  //  dann bewertet Lumo die Zusammenfassung").
  bool _inSummaryMode = false;
  bool _inBookQuiz = false;
  bool _fullBookView = false;
  int _bookQuestionIndex = 0;
  String? _bookQuizSelected;
  int _bookQuestionsCorrectFirstTry = 0;
  bool _bookQuestionHadMistake = false;
  bool _bookEvidenceHintVisible = false;
  final TextEditingController _summaryCtrl = TextEditingController();
  late final LumoSpeechListener _speech;
  late final int _profileGeneration;
  late final String _storySessionId;
  final TextEditingController _choiceProposalCtrl = TextEditingController();
  LumoCompanionTaskContext? _publishedContext;
  int? _handledLearningRequest;
  int _speechRevision = 0;
  int _voiceRevision = 0;
  int _helpLevel = 0;
  int _exerciseAttempts = 0;
  int _bookQuestionAttempts = 0;
  bool _summaryNeedsReview = false;
  bool _speechStarting = false;
  bool _pageTurnPending = false;
  bool _bookQuestionHadHelp = false;
  bool _helpVisible = false;
  bool _slow = false;
  bool _hasChoiceProposal = false;
  String? _inputMessage;
  String? _activeObjectId;
  String _speechDraftBefore = '';
  LumoStorySummaryScore? _summaryScore;
  bool _summaryEvaluated = false;
  int _summaryHits = 0;
  int _summaryStars = 0;
  bool _finishing = false;
  String? _savedStoryId;
  bool _readCountRecorded = false;

  bool get _ownsProfile =>
      _profileGeneration == widget.appState.profileGeneration;

  @override
  void initState() {
    super.initState();
    _speech = widget.speechListener ?? LumoSpeechListener();
    _speech.addListener(_speechStateChanged);
    _profileGeneration = widget.appState.profileGeneration;
    _storySessionId = widget.storyId ?? newLearningAttemptId();
    _savedStoryId = widget.storyId;
    WidgetsBinding.instance.addObserver(this);
    widget.appState.addListener(_profileStateChanged);
    final requests = LumoCompanionRequests.instance;
    requests.helpRequested.addListener(_companionHelp);
    requests.learningAction.addListener(_learningAction);
    _publishTask();
    // Reading comes first. The loudspeaker remains available on demand.
  }

  @override
  void dispose() {
    _summaryCtrl.dispose();
    _choiceProposalCtrl.dispose();
    _speechRevision++;
    _voiceRevision++;
    _speech.removeListener(_speechStateChanged);
    _speech.cancel();
    if (widget.speechListener == null) _speech.dispose();
    widget.appState.removeListener(_profileStateChanged);
    final requests = LumoCompanionRequests.instance;
    requests.helpRequested.removeListener(_companionHelp);
    requests.learningAction.removeListener(_learningAction);
    requests.clearTask(_publishedContext);
    WidgetsBinding.instance.removeObserver(this);
    LumoVoice.instance.stop();
    if (_slow) {
      unawaited(LumoVoice.instance
          .configure(rate: widget.appState.state.settings.voiceRate));
    }
    super.dispose();
  }

  Future<void> _speakText(String text) async {
    if (!mounted || !_ownsProfile) return;
    final revision = ++_voiceRevision;
    try {
      await LumoVoice.instance.configure(
          rate: widget.appState.state.settings.voiceRate * (_slow ? .75 : 1));
      if (!mounted || !_ownsProfile || revision != _voiceRevision) return;
      await LumoVoice.instance.speak(text);
    } catch (_) {}
  }

  void _speak() => unawaited(_speakText(_spokenContent));

  String get _taskId =>
      'story:$_storySessionId:${_fullBookView ? 'full' : _inSummaryMode ? 'summary' : _inBookQuiz ? 'question:$_bookQuestionIndex' : 'page:$_pageIdx'}';

  String get _spokenContent => _fullBookView
      ? widget.story.pages.map((page) => page.text).join('\n')
      : _inSummaryMode
          ? 'Erzähle mit deinen eigenen Worten: Wer war dabei? Was ist passiert? Wie ging die Geschichte aus?'
          : _inBookQuiz
              ? widget.story.bookQuestions[_bookQuestionIndex].prompt
              : widget.story.pages[_pageIdx].text;

  List<String> get _answerChoices => _fullBookView || _inSummaryMode
      ? const []
      : _inBookQuiz
          ? widget.story.bookQuestions[_bookQuestionIndex].options
          : widget.story.pages[_pageIdx].exercise?.options ?? const [];

  List<String> get _objectIds => [
        if (_fullBookView)
          for (final page in widget.story.pages)
            'full-book-page-${page.pageNum}'
        else if (_inSummaryMode) ...[
          'story-summary-prompt',
          'story-summary-text',
          if (_summaryEvaluated) 'story-summary-feedback',
        ] else if (_inBookQuiz)
          'story-book-question'
        else ...[
          'story-page-text',
          if (widget.story.pages[_pageIdx].exercise != null)
            'story-page-exercise',
        ],
        for (var i = 0; i < _answerChoices.length; i++) 'story-choice-$i',
        if (_helpVisible) 'story-help',
        if (_hasChoiceProposal) 'story-answer-proposal',
      ];

  String get _helpText {
    if (_inSummaryMode && !_fullBookView) {
      return switch (_helpLevel) {
        0 ||
        1 =>
          'Wer war dabei? Was hat die Figur erlebt? Erzähle erst einen Gedanken mit deinen eigenen Worten.',
        2 =>
          'Ordne deine Gedanken: Am Anfang …, danach …, am Ende … . Nimm dir einen Teil nach dem anderen vor.',
        _ =>
          'Lies einen kurzen Abschnitt im Volltext. Decke ihn dann gedanklich ab und erzähle nur diesen Abschnitt. Andere Wörter können genauso gut passen.',
      };
    }
    if (_inBookQuiz && !_fullBookView) {
      final page = widget.story.bookQuestions[_bookQuestionIndex].evidencePage;
      return page >= 1 && page <= widget.story.pages.length
          ? 'Lies auf Seite $page im Volltext nach. Suche den Satz, der die Frage beantwortet. Danach wählst du selbst.'
          : 'Lies die Frage noch einmal. Suche die passende Stelle im Volltext und vergleiche sie mit den Antwortmöglichkeiten.';
    }
    return _helpLevel < 2
        ? 'Lies einen Satz nach dem anderen. Wer tut etwas? Was verändert sich? Du bestimmst, wann du weiterliest.'
        : 'Suche zuerst die Figur und dann ihre Handlung. Erzähle einen Satz mit eigenen Worten. Du kannst den Abschnitt noch einmal anhören.';
  }

  bool get _ownsCompanion =>
      mounted &&
      _ownsProfile &&
      (ModalRoute.of(context)?.isCurrent ?? true) &&
      identical(
          LumoCompanionRequests.instance.taskContext.value, _publishedContext);

  void _publishTask() {
    if (widget.story.pages.isEmpty) return;
    final taskId = _taskId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_ownsProfile ||
          taskId != _taskId ||
          !(ModalRoute.of(context)?.isCurrent ?? true)) return;
      final page = widget.story.pages[_pageIdx];
      final summary = _inSummaryMode && !_fullBookView;
      final quiz = _inBookQuiz && !_fullBookView;
      final value = LumoCompanionTaskContext(
        subject: 'Deutsch',
        unit: summary
            ? 'Geschichtenrückblick'
            : quiz
                ? 'Buchfragen'
                : 'Geschichtenlesen',
        prompt: summary
            ? 'Erzähle die Geschichte „${widget.story.title}“ mit eigenen Worten.'
            : quiz
                ? widget.story.bookQuestions[_bookQuestionIndex].prompt
                : _fullBookView
                    ? 'Lies das ganze Buch „${widget.story.title}“.'
                    : '${page.text}${page.exercise == null ? '' : '\n\n${page.exercise!.prompt}'}',
        taskId: taskId,
        ownerSection: 'reading',
        activity: 'story_reading',
        profileGeneration: _profileGeneration,
        stepId: summary
            ? (_summaryEvaluated ? 'feedback' : 'retell')
            : 'read-and-explore',
        attempts: summary
            ? (_summaryEvaluated ? 1 : 0)
            : quiz
                ? _bookQuestionAttempts
                : _exerciseAttempts,
        helpLevel: _helpLevel,
        answering: !_finishing &&
            !_fullBookView &&
            (summary ? !_summaryEvaluated : _answerChoices.isNotEmpty),
        lastAnswer: summary
            ? (_summaryEvaluated ? _summaryCtrl.text : null)
            : quiz
                ? _bookQuizSelected
                : _selectedAnswer,
        // Keyword matches and speech transcripts are not correctness evidence.
        lastCorrect: summary || _fullBookView
            ? null
            : quiz
                ? (_bookQuizSelected == null
                    ? null
                    : _bookQuizSelected ==
                        widget.story.bookQuestions[_bookQuestionIndex]
                            .correctAnswer)
                : _selectedAnswer == null
                    ? null
                    : _exerciseDone,
        localHelp: _helpText,
        explanation: summary && _summaryEvaluated
            ? 'Die Rückmeldung nennt nur erkannte Stichwörter. Sie bewertet nicht, ob alle Zusammenhänge richtig erzählt wurden.'
            : _helpVisible
                ? _helpText
                : null,
        errorType: _summaryNeedsReview ? 'unconfirmed_transcription' : null,
        objectIds: _objectIds,
        answerChoices: _answerChoices,
        allowedActions: {
          ...lumoDefaultLearningActions,
          LumoLearningAction.look,
          LumoLearningAction.point,
          LumoLearningAction.highlight,
          if (!_fullBookView &&
              (summary && !_summaryEvaluated || _answerChoices.isNotEmpty))
            LumoLearningAction.proposeAnswer,
        },
        isExplanation: _helpVisible,
      );
      _publishedContext = value;
      final requests = LumoCompanionRequests.instance;
      requests.publishTask(value);
      final identity = requests.learningIdentity.value;
      if (identity != null &&
          _activeObjectId != null &&
          value.objectIds.contains(_activeObjectId)) {
        requests.publishLearningPresentation(LumoLearningPresentation(
          identity: identity,
          gazeObjectId: _activeObjectId,
          pointObjectId: _activeObjectId,
          expression: 'attentive',
          animationState: _helpVisible ? 'explaining' : 'observing',
        ));
      }
    });
  }

  void _profileStateChanged() {
    if (!mounted || _ownsProfile) return;
    _speechRevision++;
    _voiceRevision++;
    unawaited(_speech.cancel());
    unawaited(LumoVoice.instance.stop());
    LumoCompanionRequests.instance.clearTask(_publishedContext);
    setState(() {});
  }

  void _speechStateChanged() {
    if (!mounted || !_ownsProfile) return;
    setState(() {
      if (_speech.error != null) {
        _inputMessage =
            'Ich konnte deine Worte nicht sicher aufnehmen. Dein Text bleibt erhalten. Du kannst ihn tippen oder noch einmal sprechen.';
      }
    });
  }

  void _companionHelp() {
    if (_ownsCompanion) _requestStoryHelp();
  }

  void _requestStoryHelp() {
    if (!mounted || !_ownsProfile || _finishing) return;
    setState(() {
      _helpLevel = (_helpLevel + 1).clamp(1, 3);
      _helpVisible = true;
      if (_inBookQuiz) _bookQuestionHadHelp = true;
      _activeObjectId = _inSummaryMode
          ? 'story-summary-text'
          : _inBookQuiz
              ? 'story-book-question'
              : 'story-page-text';
    });
    _publishTask();
  }

  void _stopSupport() {
    _speechRevision++;
    _voiceRevision++;
    unawaited(_speech.cancel());
    unawaited(LumoVoice.instance.stop());
    if (!mounted) return;
    setState(() {
      _helpVisible = false;
      _activeObjectId = null;
      _speechStarting = false;
    });
    _publishTask();
  }

  void _learningAction() {
    final requests = LumoCompanionRequests.instance;
    final action = requests.learningAction.value;
    if (!_ownsCompanion ||
        action == null ||
        action.requestId == _handledLearningRequest ||
        !requests.isCurrentLearningIdentity(action.identity)) return;
    _handledLearningRequest = action.requestId;
    switch (action.action) {
      case LumoLearningAction.hint:
      case LumoLearningAction.explain:
        _requestStoryHelp();
      case LumoLearningAction.repeat:
        _speak();
      case LumoLearningAction.slower:
        setState(() => _slow = true);
        _speak();
      case LumoLearningAction.stop:
        _stopSupport();
      case LumoLearningAction.look:
      case LumoLearningAction.point:
      case LumoLearningAction.highlight:
        setState(() => _activeObjectId = action.objectId);
        _publishTask();
      case LumoLearningAction.proposeAnswer:
        if (_inSummaryMode) {
          if (_summaryEvaluated) return;
          setState(() {
            final previous = _summaryCtrl.text.trim();
            _summaryCtrl.text =
                '${previous.isEmpty ? '' : '$previous\n'}${action.candidate ?? ''}';
            _summaryNeedsReview = true;
          });
        } else {
          setState(() {
            _choiceProposalCtrl.text = action.candidate ?? '';
            _hasChoiceProposal = true;
          });
        }
        _publishTask();
    }
  }

  void _confirmChoiceProposal() {
    if (!_ownsProfile || _finishing) return;
    final proposed = _choiceProposalCtrl.text.trim().toLowerCase();
    final matches = _answerChoices
        .where((choice) => choice.toLowerCase() == proposed)
        .toList();
    if (matches.length != 1) {
      setState(() => _inputMessage =
          'Der erkannte Vorschlag passt noch nicht zu einer Antwort. Korrigiere ihn oder tippe deine Antwort direkt an.');
      return;
    }
    setState(() {
      _hasChoiceProposal = false;
      _inputMessage = null;
    });
    if (_inBookQuiz) {
      _chooseBookAnswer(matches.single);
    } else {
      final exercise = widget.story.pages[_pageIdx].exercise;
      if (exercise != null) _onAnswer(matches.single, exercise);
    }
  }

  void _toggleFullBook() {
    _stopSupport();
    setState(() => _fullBookView = !_fullBookView);
    _publishTask();
  }

  Widget _buildSupportControls() {
    Widget action(
            String key, IconData icon, String label, VoidCallback callback) =>
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: OutlinedButton.icon(
            key: ValueKey(key),
            onPressed: _ownsProfile && !_finishing ? callback : null,
            icon: Icon(icon, size: 20),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF5284A6)),
            ),
          ),
        );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        action('story-help', Icons.lightbulb_outline, 'Hilf mir',
            _requestStoryHelp),
        action(
            'story-repeat',
            Icons.replay_rounded,
            'Noch einmal',
            () => unawaited(
                _speakText(_helpVisible ? _helpText : _spokenContent))),
        action('story-slower', Icons.slow_motion_video, 'Langsamer', () {
          setState(() => _slow = true);
          unawaited(_speakText(_helpVisible ? _helpText : _spokenContent));
        }),
        action('story-explain-differently', Icons.view_agenda_outlined,
            'Anders erklären', _requestStoryHelp),
        action('story-stop', Icons.stop_rounded, 'Stopp', _stopSupport),
        action('story-try-myself', Icons.touch_app_outlined,
            'Ich versuche es selbst', _stopSupport),
      ]),
    );
  }

  Widget _buildSupportContent() {
    if (!_helpVisible && !_hasChoiceProposal) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_helpVisible)
          LumoGlassCard(
            key: const ValueKey('story-help-content'),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LumoCompanionHost(
                    appState: widget.appState,
                    section: 'reading',
                    subject: 'Deutsch',
                    unit: _inSummaryMode
                        ? 'Geschichtenrückblick'
                        : 'Geschichtenlesen',
                    compact: true,
                    offerOnly: true,
                    onExplainTask: _requestStoryHelp,
                    onSection: (section) {
                      if (_finishing) return;
                      if (Navigator.canPop(context)) Navigator.pop(context);
                      widget.appState.setSection(section);
                    },
                  ),
                  Text(_helpText,
                      key: const ValueKey('story-help-text'),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16, height: 1.4)),
                  const SizedBox(height: 8),
                  const Text(
                      'Jetzt bist du dran. Du kannst selbst weiterarbeiten.',
                      style: TextStyle(
                          color: LumoVisualTokens.muted, height: 1.4)),
                ]),
          ),
        if (_hasChoiceProposal) ...[
          const SizedBox(height: 8),
          LumoGlassCard(
            key: const ValueKey('story-answer-proposal'),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                      'War das deine Antwort? Prüfe den erkannten Vorschlag.',
                      style: TextStyle(color: Colors.white, height: 1.4)),
                  const SizedBox(height: 8),
                  TextField(
                    key: const ValueKey('story-answer-proposal-text'),
                    controller: _choiceProposalCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration:
                        const InputDecoration(labelText: 'Deine Antwort'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const ValueKey('story-confirm-answer-proposal'),
                    onPressed: _ownsProfile ? _confirmChoiceProposal : null,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Diese Antwort prüfen'),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        foregroundColor: Colors.white),
                  ),
                  if (_inputMessage != null)
                    Text(_inputMessage!,
                        style:
                            const TextStyle(color: Colors.white, height: 1.4)),
                ]),
          ),
        ],
      ]),
    );
  }

  bool _beginPageTurn() {
    if (_pageTurnPending || _finishing || !_ownsProfile) return false;
    _pageTurnPending = true;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _pageTurnPending = false);
    _speechRevision++;
    _voiceRevision++;
    unawaited(_speech.cancel());
    unawaited(LumoVoice.instance.stop());
    _hasChoiceProposal = false;
    _inputMessage = null;
    _activeObjectId = null;
    _helpVisible = false;
    _helpLevel = 0;
    return true;
  }

  void _openClueNotebook() {
    final notes = <(String, String)>[
      (
        'Der erste Brief',
        'Jemand hat eine Farbe beschrieben, die man bei klarem Wetter '
            'oben am Himmel sehen kann.',
      ),
      if (_pageIdx >= 2)
        (
          'Der Brunnen',
          'Drei Fundstücke sind wichtig: eine Feder, ein Stein und ein Band. '
              'Nur eine Sache ist an einem Zweig festgeknotet.',
        ),
      if (_pageIdx >= 3)
        (
          'Die Treppe',
          'An der ersten Stufe wurden drei Gegenstände gezeichnet. '
              'Vergleiche sie mit dem Brief und mit dem Fund am Brunnen.',
        ),
      if (_pageIdx >= 6)
        (
          'Die Karte',
          'Kreis, Dreieck und Stern führen nicht zum gleichen Ort. '
              'Ein Zeichen steht ausdrücklich beim letzten Weg.',
        ),
      if (_pageIdx >= 7)
        (
          'Die geheime Tür',
          'Die Zeichen an der Tür gleichen denen der alten Karte. '
              'Du brauchst kein Glück: Du brauchst deine Erinnerung.',
        ),
    ];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101D3B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(ctx).height * .74,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  const Icon(Icons.auto_stories_rounded,
                      color: LumoVisualTokens.gold, size: 30),
                  const SizedBox(width: 10),
                  const Expanded(
                      child: Text('Lumos Hinweis-Notizbuch',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 21))),
                  IconButton(
                    tooltip: 'Notizbuch schließen',
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ]),
                const Text(
                    'Hier stehen nur Beobachtungen. Die Rätsel '
                    'lösen wir nicht für dich.',
                    style: TextStyle(
                        color: LumoVisualTokens.muted,
                        height: 1.3,
                        fontSize: 14)),
                const SizedBox(height: 12),
                Flexible(
                    child: ListView.separated(
                  key: const ValueKey('lumo-story-clue-notebook'),
                  shrinkWrap: true,
                  itemCount: notes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final note = notes[index];
                    return Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: const Color(0xFF18345B),
                        border: Border.all(color: const Color(0xFF3F7197)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(note.$1,
                              style: const TextStyle(
                                  color: LumoVisualTokens.gold,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900)),
                          const SizedBox(height: 5),
                          Text(note.$2,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  height: 1.4)),
                        ],
                      ),
                    );
                  },
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _nextPage() {
    final current = widget.story.pages[_pageIdx];
    if (_inSummaryMode ||
        _inBookQuiz ||
        (current.exercise != null && !_exerciseDone) ||
        !_beginPageTurn()) return;
    if (_pageIdx + 1 >= widget.story.pages.length) {
      // Letzte Seite fertig: wenn die Geschichte keyPoints hat, starten wir
      // die Zusammenfassungs-Phase. Sonst direkt zu Finish.
      if (widget.story.bookQuestions.isNotEmpty) {
        LumoVoice.instance.stop();
        setState(() => _inBookQuiz = true);
        _publishTask();
      } else {
        _enterSummaryOrFinish();
      }
      return;
    }
    setState(() {
      _pageIdx++;
      _exerciseDone = false;
      _selectedAnswer = null;
      _exerciseAttempts = 0;
    });
    _publishTask();
    // Pages are rendered directly by _buildPage, not by a PageView.
    // The page index above is the actual navigation state.
    // Page changes never trigger automatic speech. The child reads first.
  }

  void _enterSummaryOrFinish() {
    if (widget.story.keyPoints.isNotEmpty) {
      setState(() {
        _inBookQuiz = false;
        _inSummaryMode = true;
      });
      _publishTask();
    } else {
      _showFinish();
    }
  }

  void _chooseBookAnswer(String option) {
    final question = widget.story.bookQuestions[_bookQuestionIndex];
    if (!_ownsProfile ||
        _finishing ||
        !question.options.contains(option) ||
        _bookQuizSelected == question.correctAnswer ||
        _bookQuizSelected == option) return;
    final isCorrect = option == question.correctAnswer;
    setState(() {
      _bookQuizSelected = option;
      _bookQuestionAttempts++;
      if (!isCorrect) {
        _bookQuestionHadMistake = true;
      } else if (!_bookQuestionHadMistake && !_bookQuestionHadHelp) {
        _bookQuestionsCorrectFirstTry++;
      }
    });
    HapticFeedback.selectionClick();
    _publishTask();
  }

  void _nextBookQuestion() {
    if (_bookQuizSelected !=
        widget.story.bookQuestions[_bookQuestionIndex].correctAnswer) {
      return;
    }
    if (!_beginPageTurn()) return;
    if (_bookQuestionIndex + 1 == widget.story.bookQuestions.length) {
      _enterSummaryOrFinish();
      return;
    }
    setState(() {
      _bookQuestionIndex++;
      _bookQuizSelected = null;
      _bookQuestionHadMistake = false;
      _bookQuestionHadHelp = false;
      _bookQuestionAttempts = 0;
      _bookEvidenceHintVisible = false;
    });
    _publishTask();
  }

  void _startListeningSummary() async {
    if (_speechStarting || _summaryEvaluated || !_ownsProfile || _finishing)
      return;
    setState(() => _speechStarting = true);
    final revision = ++_speechRevision;
    if (!await LumoFeaturePermissions.microphone(context, widget.appState) ||
        !mounted ||
        !_ownsProfile ||
        revision != _speechRevision) {
      if (mounted) setState(() => _speechStarting = false);
      return;
    }
    _speechDraftBefore = _summaryCtrl.text.trim();
    try {
      void accept(String text) {
        if (!mounted ||
            !_ownsProfile ||
            _summaryEvaluated ||
            !_inSummaryMode ||
            revision != _speechRevision ||
            text.trim().isEmpty) return;
        setState(() {
          _summaryCtrl.text =
              '${_speechDraftBefore.isEmpty ? '' : '$_speechDraftBefore\n'}${text.trim()}';
          _summaryNeedsReview = true;
          _inputMessage = null;
        });
        _publishTask();
      }

      await _speech.startListening(
        onResult: accept,
        onFinalResult: accept,
        onNoMatch: () {
          if (!mounted || revision != _speechRevision) return;
          setState(() => _inputMessage =
              'Ich habe keine sicheren Worte erkannt. Das ist kein Fehler in deiner Erzählung. Du kannst tippen oder noch einmal sprechen.');
        },
      );
      if (mounted && revision == _speechRevision && !_speech.available) {
        setState(() => _inputMessage =
            'Das Mikrofon ist gerade nicht bereit. Dein Text bleibt erhalten; du kannst hier weiterschreiben.');
      }
    } catch (_) {
      if (mounted && revision == _speechRevision) {
        setState(() => _inputMessage =
            'Deine Worte konnten nicht sicher aufgenommen werden. Dein Text bleibt erhalten. Versuche es noch einmal oder tippe weiter.');
      }
    } finally {
      if (mounted && revision == _speechRevision)
        setState(() => _speechStarting = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _speechRevision++;
      _voiceRevision++;
      _speech.cancel();
      LumoVoice.instance.stop();
    } else {
      _publishTask();
    }
  }

  void _stopListeningSummary() async {
    try {
      await _speech.stopListening();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  /// Conservative keyword aid, not a full semantic evaluation. Each summary
  /// can be rewarded only once while this reader is open.
  void _evaluateSummary() {
    if (!mounted || !_ownsProfile || _finishing || _summaryEvaluated) return;
    if (_speech.listening || _speechStarting || _summaryNeedsReview) {
      setState(() => _inputMessage =
          'Beende zuerst die Aufnahme und prüfe den erkannten Text. Du entscheidest, ob das deine Worte sind.');
      return;
    }
    final raw = _summaryCtrl.text.trim();
    if (raw.isEmpty) {
      setState(() => _inputMessage =
          'Erzähle erst einen Gedanken. Du kannst ihn sprechen oder tippen.');
      return;
    }
    final result = LumoStorySummaryScorer.evaluate(
      summary: raw,
      keyPoints: widget.story.keyPoints,
    );
    final hits = result.hits;
    final stars = result.stars;
    if (stars == 0) {
      setState(() => _inputMessage =
          'Ich brauche erst einige Wörter für eine Rückmeldung. Das ist noch keine Bewertung deiner Erzählung.');
      return;
    }
    final award = _summaryStars == 0;
    setState(() {
      _summaryEvaluated = true;
      _summaryHits = hits;
      _summaryScore = result;
      _inputMessage = null;
      if (award) _summaryStars = stars;
    });
    if (award) widget.appState.addRewards(stars: stars, xp: stars * 10);
    final msg = hits > 0
        ? 'Ich erkenne $hits Stichwörter aus der Geschichte. Ob die Zusammenhänge stimmen, schauen wir gemeinsam am Text nach.'
        : 'Du hast eigene Worte verwendet. Ohne passende Stichwörter kann ich nicht beurteilen, ob deine Erzählung zur Geschichte passt. Schau mit mir im Text nach.';
    unawaited(_speakText(msg));
    _publishTask();
    if (award &&
        stars >= 4 &&
        !widget.appState.state.settings.calmMode &&
        !widget.appState.state.settings.reduceAnimations &&
        !MediaQuery.disableAnimationsOf(context)) {
      showLumoRewardBurst(context, stars: stars, xp: stars * 10);
    }
  }

  void _onAnswer(String answer, StoryExercise ex) async {
    if (!_ownsProfile ||
        _finishing ||
        _exerciseDone ||
        _selectedAnswer == answer ||
        !(ex.options?.contains(answer) ?? false)) return;
    HapticFeedback.lightImpact();
    final correct = answer == ex.correctAnswer;
    setState(() {
      _selectedAnswer = answer;
      _exerciseDone = correct;
      _exerciseAttempts++;
    });
    if (correct) {
      // Keep the progress reward, but do not push a blocking modal over
      // the next reading page 1s later. That interrupted child-led reading
      // and could swallow the next mystery clue tap.
      widget.appState.addRewards(stars: 1, xp: 5);
    }
    _publishTask();
  }

  Future<void> _showFinish() async {
    if (_finishing || !_ownsProfile) return;
    setState(() => _finishing = true);
    try {
      if (_savedStoryId == null) {
        final saved = await LumoStoryLibrary.instance.addStory(widget.story);
        _savedStoryId = saved.id;
      }
      await widget.appState.flushRewards();
      if (!mounted || !_ownsProfile) return;
      if (!_readCountRecorded && _savedStoryId != null) {
        await LumoStoryLibrary.instance.incrementRead(_savedStoryId!);
        _readCountRecorded = true;
      }
      if (!mounted || !_ownsProfile) return;
      await _showFinishDialog();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16, 0, 16, 88),
        content: Text(
            'Heft oder Belohnungen konnten nicht gespeichert werden. Bitte versuche es noch einmal.'),
      ));
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }

  Future<void> _showFinishDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: LumoTokens.colors.surface,
        title: Text('🎉 ${widget.story.title} — Geschafft!',
            style: LumoTokens.typo.headlineMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Du hast die ganze Geschichte gelesen!',
                style: LumoTokens.typo.bodyLarge),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: LumoTokens.colors.successLight,
                borderRadius: LumoTokens.brMedium,
              ),
              child: Row(children: [
                Icon(Icons.save_rounded, color: LumoTokens.colors.successDeep),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Heft in deine Bibliothek gespeichert!',
                      style: LumoTokens.typo.bodyMedium
                          .copyWith(color: LumoTokens.colors.successDeep)),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Text('Neue Wörter aus dem Heft:',
                style: LumoTokens.typo.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: widget.story.newWords
                  .map((w) => Chip(
                        label: Text(w),
                        backgroundColor:
                            LumoTokens.colors.lumoLila.withOpacity(0.15),
                      ))
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final navigator = Navigator.of(context);
              navigator.pop(); // Dialog
              navigator.pop(true); // Reader: successfully saved completion
              navigator.push(
                MaterialPageRoute(
                  builder: (_) => LumoWritingCoachScreen(
                    appState: widget.appState,
                    customWords: widget.story.newWords,
                    sourceTitle: widget.story.title,
                  ),
                ),
              );
            },
            child: const Text('Wörter im Schreibcoach üben!'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('Fertig'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.story.pages.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Geschichte')),
        body: const SafeArea(
            child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
              'Dieses Heft enthält keine lesbare Seite. Wähle bitte ein anderes Heft.'),
        )),
      );
    }
    final page = widget.story.pages[_pageIdx];
    // Respect both Lumo's settings and Android's accessibility animation flag.
    final reducePageMotion = widget.appState.state.settings.reduceAnimations ||
        widget.appState.state.settings.calmMode ||
        MediaQuery.of(context).disableAnimations;
    final screen = PopScope(
      canPop: !_finishing,
      child: Scaffold(
        backgroundColor: LumoVisualTokens.night,
        body: LumoSceneBackground(
          scene: LumoScene.library,
          dimmed: true,
          child: SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                if (!_ownsProfile)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                        'Das Kinderprofil wurde gewechselt. Öffne das Heft für das aktuelle Profil neu.',
                        style: TextStyle(color: Colors.white)),
                  ),
                Expanded(
                  child: _fullBookView
                      ? _buildFullBook()
                      : _inSummaryMode
                          ? _buildSummaryPage()
                          : _inBookQuiz
                              ? _buildBookQuiz()
                              : AnimatedSwitcher(
                                  duration: reducePageMotion
                                      ? Duration.zero
                                      : const Duration(milliseconds: 320),
                                  reverseDuration: reducePageMotion
                                      ? Duration.zero
                                      : const Duration(milliseconds: 160),
                                  layoutBuilder:
                                      (currentChild, previousChildren) => Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ...previousChildren,
                                      if (currentChild != null) currentChild,
                                    ],
                                  ),
                                  transitionBuilder: (child, animation) {
                                    final turn = CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutCubic,
                                    );
                                    return AnimatedBuilder(
                                      animation: turn,
                                      child: child,
                                      builder: (context, pageChild) =>
                                          Transform(
                                        alignment: Alignment.centerRight,
                                        transform: Matrix4.identity()
                                          ..setEntry(3, 2, 0.0005)
                                          ..rotateY((1.0 - turn.value) * -0.11),
                                        child: FadeTransition(
                                          opacity: turn,
                                          child: pageChild,
                                        ),
                                      ),
                                    );
                                  },
                                  child: GestureDetector(
                                    key: ValueKey(
                                        'lumo-story-page-flip-${page.pageNum}'),
                                    behavior: HitTestBehavior.translucent,
                                    onHorizontalDragEnd: (details) {
                                      // A swipe must NEVER bypass a reading clue.
                                      if ((details.primaryVelocity ?? 0) <
                                              -480 &&
                                          (page.exercise == null ||
                                              _exerciseDone) &&
                                          !_finishing) {
                                        _nextPage();
                                      }
                                    },
                                    child: _buildPage(page),
                                  ),
                                ),
                ),
                _buildSupportControls(),
                _fullBookView
                    ? _buildFullBookBottomNav()
                    : _inSummaryMode
                        ? _buildSummaryBottomNav()
                        : _inBookQuiz
                            ? _buildBookQuizNavigation()
                            : _buildBottomNav(page),
              ],
            ),
          ),
        ),
      ),
    );
    return MediaQuery(
      data:
          MediaQuery.of(context).copyWith(disableAnimations: reducePageMotion),
      child: screen,
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(LumoTokens.space12, LumoTokens.space8,
          LumoTokens.space12, LumoTokens.space8),
      child: Row(
        children: [
          IconButton(
            icon:
                const Icon(Icons.close_rounded, color: LumoVisualTokens.white),
            onPressed: _finishing ? null : () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Text(widget.story.title,
                    style: LumoTokens.typo.titleLarge
                        .copyWith(color: LumoVisualTokens.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_pageIdx + 1) / widget.story.pages.length,
                    minHeight: 6,
                    backgroundColor: LumoVisualTokens.glassRow,
                    valueColor:
                        AlwaysStoppedAnimation(LumoVisualTokens.cyanBright),
                  ),
                ),
              ],
            ),
          ),
          if (widget.story.bookQuestions.isNotEmpty)
            IconButton(
              key: const ValueKey('lumo-story-clue-notebook-toggle'),
              tooltip: 'Gefundene Hinweise nachlesen',
              onPressed: _openClueNotebook,
              icon: const Icon(Icons.explore_rounded,
                  color: LumoVisualTokens.gold),
            ),
          IconButton(
            key: const ValueKey('lumo-full-book-toggle'),
            tooltip: _fullBookView
                ? 'Zurück zum Leseabenteuer'
                : 'Gesamtes Buch im Volltext lesen',
            icon: Icon(
                _fullBookView
                    ? Icons.menu_book_rounded
                    : Icons.chrome_reader_mode_rounded,
                color: LumoVisualTokens.cyanBright),
            onPressed: _toggleFullBook,
          ),
          IconButton(
            tooltip: 'Seite vorlesen',
            icon: const Icon(Icons.volume_up_rounded,
                color: LumoVisualTokens.cyanBright),
            onPressed: _fullBookView || !_ownsProfile ? null : _speak,
          ),
        ],
      ),
    );
  }

  Widget _buildFullBook() {
    return ListView(
      key: const ValueKey('lumo-story-complete-book'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        _buildSupportContent(),
        Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 740),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.story.title,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: LumoVisualTokens.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 25,
                  )),
              const SizedBox(height: 8),
              const Text(
                  'Dein ganzes Buch – ohne Unterbrechung. '
                  'Wenn du miträtseln möchtest, kehre zur Leseansicht zurück.',
                  style: TextStyle(
                    color: LumoVisualTokens.muted,
                    height: 1.4,
                    fontSize: 15,
                  )),
              const SizedBox(height: 18),
              for (final page in widget.story.pages) ...[
                if (widget.story.bookQuestions.isNotEmpty)
                  LumoStoryScene(
                    page: page.pageNum,
                    variant: widget.story.illustrationVariant,
                    height: MediaQuery.sizeOf(context).width > 650 ? 252 : 192,
                  ),
                const SizedBox(height: 10),
                LumoGlassCard(
                  key: ValueKey('full-book-page-${page.pageNum}'),
                  padding: const EdgeInsets.all(17),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Kapitel ${((page.pageNum - 1) ~/ 3) + 1} '
                          '· Seite ${page.pageNum}',
                          style: const TextStyle(
                            color: LumoVisualTokens.cyanBright,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          )),
                      const SizedBox(height: 12),
                      Text(page.text,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            color: LumoVisualTokens.white,
                            height: 1.65,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          )),
                    ],
                  ),
                ),
                if (page.pageNum % 3 == 0) ...[
                  const SizedBox(height: 9),
                  Text(
                      'Kapitel ${page.pageNum ~/ 3} geschafft. '
                      'Was könnte als Nächstes passieren?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: LumoVisualTokens.muted,
                          height: 1.35,
                          fontSize: 15)),
                ],
                const SizedBox(height: 14),
              ],
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildFullBookBottomNav() => Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            key: const ValueKey('lumo-return-from-full-book'),
            onPressed: _toggleFullBook,
            icon: const Icon(Icons.auto_stories_rounded),
            label: const Text('Zurück zum Leseabenteuer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: LumoVisualTokens.cyanBright,
              foregroundColor: LumoVisualTokens.navigation,
            ),
          ),
        ),
      );

  /// The child's words come first; illustration is secondary to reading.
  Widget _buildPage(LumoStoryPage page) {
    return SingleChildScrollView(
      key: const ValueKey('lumo-story-reader-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 740),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSupportContent(),
              LumoGlassCard(
                key: const ValueKey('lumo-story-visible-page-text'),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.auto_stories_rounded,
                          color: LumoVisualTokens.cyanBright, size: 21),
                      const SizedBox(width: 9),
                      Expanded(
                          child: Text(
                        'Kapitel ${(_pageIdx ~/ 3) + 1} · Seite ${page.pageNum} von ${widget.story.pages.length}',
                        style: const TextStyle(
                          color: LumoVisualTokens.cyanBright,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      )),
                    ]),
                    const SizedBox(height: 12),
                    Text(
                      page.text,
                      key: const ValueKey('lumo-story-actual-page-text'),
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        color: LumoVisualTokens.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (widget.story.bookQuestions.isNotEmpty)
                LumoStoryScene(
                  key: ValueKey('lumo-story-scene-${page.pageNum}'),
                  page: page.pageNum,
                  variant: widget.story.illustrationVariant,
                  height: MediaQuery.sizeOf(context).width > 650 ? 270 : 198,
                ),
              const SizedBox(height: 12),
              if (widget.story.bookQuestions.isEmpty)
                LumoGlassCard(
                  key: const ValueKey('lumo-story-original-fox-art'),
                  padding: const EdgeInsets.all(10),
                  child: Row(children: [
                    const LumoFoxPose(
                      pose: LumoDesignFoxPose.bookPoint,
                      size: 94,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Du liest – Lumo hilft dir',
                          style: TextStyle(
                            color: LumoVisualTokens.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Lies selbst. Bei Bedarf tippe oben auf den Lautsprecher.',
                          style: TextStyle(
                            color: LumoVisualTokens.muted,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    )),
                  ]),
                ),
              if (page.exercise != null) ...[
                const SizedBox(height: 16),
                _buildExerciseCard(page.exercise!),
              ],
              if (page.newWord != null) ...[
                const SizedBox(height: 12),
                LumoGlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  child: Row(children: [
                    const Icon(Icons.lightbulb_rounded,
                        color: LumoVisualTokens.gold),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                      'Neues Wort: ${page.newWord!}',
                      style: const TextStyle(
                        color: LumoVisualTokens.white,
                        fontWeight: FontWeight.w800,
                      ),
                    )),
                  ]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard(StoryExercise ex) {
    final answered = _selectedAnswer != null;
    return LumoGlassCard(
      borderColor:
          _exerciseDone ? const Color(0xFF70E7BD) : LumoVisualTokens.cyanBright,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(children: [
            Icon(Icons.auto_awesome_rounded, color: LumoVisualTokens.gold),
            SizedBox(width: 8),
            Expanded(
                child: Text('Lumo-Mini-Aufgabe:',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white))),
          ]),
          const SizedBox(height: 12),
          Text(ex.prompt,
              style: LumoTokens.typo.titleLarge
                  .copyWith(color: Colors.white, fontSize: 20)),
          const SizedBox(height: 16),
          if (ex.options != null)
            for (final option in ex.options!) ...[
              LumoPressable(
                enabled: !_exerciseDone && _ownsProfile,
                child: OutlinedButton.icon(
                  onPressed: _exerciseDone || !_ownsProfile
                      ? null
                      : () => _onAnswer(option, ex),
                  icon: Icon(
                      _selectedAnswer == option
                          ? (_exerciseDone
                              ? Icons.check_circle_rounded
                              : Icons.refresh_rounded)
                          : Icons.circle_outlined,
                      size: 22),
                  label: Align(
                      alignment: Alignment.centerLeft, child: Text(option)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 54),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    backgroundColor: _selectedAnswer == option
                        ? (_exerciseDone
                            ? const Color(0xFF155A4D)
                            : const Color(0xFF503A29))
                        : const Color(0xFF102A50),
                    side: BorderSide(
                        color: _selectedAnswer == option
                            ? (_exerciseDone
                                ? const Color(0xFF70E7BD)
                                : LumoVisualTokens.gold)
                            : const Color(0xFF5284A6)),
                    textStyle: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        fontWeight: FontWeight.w800),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          if (answered)
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                    _exerciseDone
                        ? 'Geschafft! Du kannst weiterlesen.'
                        : ex.type == StoryExerciseType.wordChoice
                            ? 'Noch nicht. Lies die Hinweise der vorherigen Seiten noch einmal und versuche es erneut.'
                            : 'Versuche es noch einmal. Zähle in kleinen Schritten und prüfe deine Antwort.',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.4,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          if (ex.options == null)
            ElevatedButton.icon(
              onPressed: _exerciseDone || !_ownsProfile
                  ? null
                  : () {
                      setState(() => _exerciseDone = true);
                      _publishTask();
                    },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Wort merken!'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(48, 52)),
            ),
          if (ex.type == StoryExerciseType.wordWrite)
            OutlinedButton.icon(
              key: const ValueKey('story-writing-coach'),
              onPressed: !_ownsProfile
                  ? null
                  : () async {
                      await Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => LumoWritingCoachScreen(
                              appState: widget.appState,
                              customWords: [ex.correctAnswer],
                              sourceTitle: widget.story.title,
                            ),
                          ));
                      if (mounted) _publishTask();
                    },
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Im Schreibcoach üben'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(LumoStoryPage page) {
    final canContinue = page.exercise == null || _exerciseDone;
    return Padding(
      padding: const EdgeInsets.all(LumoTokens.space16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          key: const ValueKey('lumo-story-continue'),
          onPressed:
              canContinue && !_finishing && _ownsProfile ? _nextPage : null,
          icon: Icon(_pageIdx + 1 >= widget.story.pages.length
              ? Icons.celebration_rounded
              : Icons.arrow_forward_rounded),
          label: Text(_pageIdx + 1 >= widget.story.pages.length
              ? widget.story.bookQuestions.isNotEmpty
                  ? 'Fragen zum ganzen Buch'
                  : 'Erzähl mir die Geschichte!'
              : 'Weiterlesen'),
          style: ElevatedButton.styleFrom(
            backgroundColor: LumoVisualTokens.cyanBright,
            foregroundColor: LumoVisualTokens.navigation,
            textStyle: LumoTokens.typo.labelLarge.copyWith(fontSize: 16),
            shape: RoundedRectangleBorder(borderRadius: LumoTokens.brLarge),
          ),
        ),
      ),
    );
  }

  Widget _buildBookQuiz() {
    final question = widget.story.bookQuestions[_bookQuestionIndex];
    final correct = _bookQuizSelected == question.correctAnswer;
    return SingleChildScrollView(
      key: const ValueKey('lumo-book-reading-quiz'),
      padding: const EdgeInsets.all(16),
      child: Center(
          child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 740),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSupportContent(),
            const Text('Was hast du dir aus dem Buch gemerkt?',
                style: TextStyle(
                  color: LumoVisualTokens.white,
                  fontFamily: 'Nunito',
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                )),
            const SizedBox(height: 8),
            Text(
                'Frage ${_bookQuestionIndex + 1} von ${widget.story.bookQuestions.length} '
                '· Es geht jetzt nicht um die beiden Rätsel.',
                style: const TextStyle(
                    color: LumoVisualTokens.muted, height: 1.4, fontSize: 15)),
            const SizedBox(height: 16),
            LumoGlassCard(
              key: ValueKey('lumo-book-question-$_bookQuestionIndex'),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(question.prompt,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 21,
                        height: 1.4,
                        fontWeight: FontWeight.w900,
                        color: LumoVisualTokens.white,
                      )),
                  const SizedBox(height: 16),
                  for (final option in question.options) ...[
                    Material(
                      color: _bookQuizSelected == option
                          ? option == question.correctAnswer
                              ? const Color(0xFF184C46)
                              : const Color(0xFF58373B)
                          : const Color(0xFF122F50),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        key: ValueKey(
                            'book-answer-${question.options.indexOf(option)}'),
                        borderRadius: BorderRadius.circular(16),
                        onTap: correct || !_ownsProfile
                            ? null
                            : () => _chooseBookAnswer(option),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 54),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          alignment: Alignment.centerLeft,
                          child: Row(children: [
                            Icon(
                                _bookQuizSelected == option
                                    ? correct
                                        ? Icons.check_circle_rounded
                                        : Icons.refresh_rounded
                                    : Icons.circle_outlined,
                                color: Colors.white,
                                size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(option,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ))),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                  ],
                  if (_bookQuizSelected != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      correct
                          ? 'Richtig erinnert! Du hast aufmerksam gelesen.'
                          : 'Schau noch einmal auf die Antworten. '
                              'Du darfst es erneut versuchen.',
                      key: const ValueKey('lumo-book-answer-feedback'),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                  ],
                  // Evidence pages are part of the saved book-question data.
                  // Offer a location, never the correct answer or a spoiler.
                  if (question.evidencePage >= 1 &&
                      question.evidencePage <= widget.story.pages.length) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      key: const ValueKey('lumo-book-evidence-hint-toggle'),
                      onPressed: !_ownsProfile
                          ? null
                          : () {
                              setState(() {
                                _bookEvidenceHintVisible =
                                    !_bookEvidenceHintVisible;
                                if (_bookEvidenceHintVisible) {
                                  _bookQuestionHadHelp = true;
                                  if (_helpLevel == 0) _helpLevel = 1;
                                }
                              });
                              _publishTask();
                            },
                      icon: const Icon(Icons.menu_book_rounded),
                      label: Text(_bookEvidenceHintVisible
                          ? 'Hinweis ausblenden'
                          : 'Hinweis zur Textstelle'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                    if (_bookEvidenceHintVisible)
                      Text(
                        'Schau noch einmal auf Seite ${question.evidencePage} '
                        'deines Buches. Dort findest du den Hinweis.',
                        key: const ValueKey('lumo-book-evidence-page-hint'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildBookQuizNavigation() {
    final question = widget.story.bookQuestions[_bookQuestionIndex];
    final solved = _bookQuizSelected == question.correctAnswer;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: ElevatedButton.icon(
          key: const ValueKey('lumo-book-quiz-next'),
          onPressed:
              solved && _ownsProfile && !_finishing ? _nextBookQuestion : null,
          icon: const Icon(Icons.auto_stories_rounded),
          label: Text(
              _bookQuestionIndex + 1 == widget.story.bookQuestions.length
                  ? 'Zum Buchrückblick'
                  : 'Nächste Buchfrage'),
          style: ElevatedButton.styleFrom(
            backgroundColor: LumoVisualTokens.cyanBright,
            foregroundColor: LumoVisualTokens.navigation,
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // ZUSAMMENFASSUNGS-PHASE
  // ──────────────────────────────────────────────────────────────────

  Widget _buildSummaryPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(LumoTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSupportContent(),
          // Aufgaben-Karte mit Frage
          LumoPremiumCard(
            key: const ValueKey('story-summary-prompt'),
            gradient: LinearGradient(
              colors: [LumoTokens.colors.gold, LumoTokens.colors.goldDeep],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: const [
                  Icon(Icons.auto_stories_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Worum ging es in der Geschichte?',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                const Text(
                  'Erzähl Lumo mit deinen eigenen Worten, was passiert ist. '
                  'Du kannst sprechen oder tippen.',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.4),
                ),
              ],
            ),
          ),
          if (widget.story.bookQuestions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Buchfragen: $_bookQuestionsCorrectFirstTry von '
              '${widget.story.bookQuestions.length} direkt ohne Hinweis beantwortet. '
              'Du kannst jede Textstelle noch einmal nachlesen.',
              style: const TextStyle(
                color: LumoVisualTokens.white,
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: LumoTokens.space12),
          // Eingabefeld
          LumoPremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const ValueKey('story-summary-text'),
                  controller: _summaryCtrl,
                  enabled:
                      !_summaryEvaluated && _ownsProfile && !_speech.listening,
                  onChanged: (_) => setState(() => _inputMessage = null),
                  maxLines: 5,
                  minLines: 3,
                  decoration: const InputDecoration(
                    hintText:
                        'Tipp hier deine Zusammenfassung ein oder drück "Sprechen"...',
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(
                      fontFamily: 'Nunito', fontSize: 16, height: 1.4),
                ),
                const SizedBox(height: 10),
                AnimatedBuilder(
                  animation: _speech,
                  builder: (_, __) {
                    final listening = _speech.listening;
                    return ElevatedButton.icon(
                      key: const ValueKey('lumo-summary-speech'),
                      onPressed:
                          _summaryEvaluated || !_ownsProfile || _speechStarting
                              ? null
                              : (listening
                                  ? _stopListeningSummary
                                  : _startListeningSummary),
                      icon: Icon(
                          listening ? Icons.stop_rounded : Icons.mic_rounded),
                      label: Text(listening ? 'Stopp' : 'Sprechen'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        backgroundColor: listening
                            ? LumoTokens.colors.errorSoft
                            : LumoTokens.colors.lumoLila,
                        foregroundColor: Colors.white,
                      ),
                    );
                  },
                ),
                if (_summaryNeedsReview) ...[
                  const SizedBox(height: 12),
                  const Text(
                      'Das Mikrofon kann Wörter verwechseln. Lies den Text und verbessere ihn, bevor du ihn bestätigst.'),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const ValueKey('lumo-summary-confirm-transcript'),
                    onPressed:
                        _speech.listening || _speechStarting || !_ownsProfile
                            ? null
                            : () {
                                setState(() {
                                  _summaryNeedsReview = false;
                                  _inputMessage = null;
                                });
                                _publishTask();
                              },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Das wollte ich sagen'),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 48)),
                  ),
                ],
                if (_inputMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Semantics(
                        liveRegion: true,
                        child: Text(_inputMessage!,
                            key: const ValueKey('lumo-summary-input-message'))),
                  ),
              ],
            ),
          ),
          if (_summaryEvaluated) ...[
            const SizedBox(height: LumoTokens.space12),
            _buildSummaryFeedback(),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryFeedback() {
    final total = _summaryScore?.keyPointCount ?? widget.story.keyPoints.length;
    return LumoPremiumCard(
      key: const ValueKey('story-summary-feedback'),
      gradient: LinearGradient(
        colors: _summaryStars >= 4
            ? [LumoTokens.colors.success, LumoTokens.colors.successDeep]
            : [LumoTokens.colors.lumoOrange, LumoTokens.colors.lumoOrangeDeep],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  Icons.star_rounded,
                  color: i < _summaryStars
                      ? Colors.white
                      : Colors.white.withOpacity(0.3),
                  size: 36,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ich erkenne $_summaryHits von $total Stichwörtern in deinem Text.',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Andere eigene Wörter können genauso gut passen. '
            'Ob die Zusammenhänge stimmen, prüfen wir gemeinsam am Text: '
            'Wer war dabei? Was ist passiert? Wie ging es aus?',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
          if (_summaryScore?.matchedKeyPoints.isNotEmpty ?? false) ...[
            const SizedBox(height: 10),
            Text(
                'Erkannte Stichwörter: ${_summaryScore!.matchedKeyPoints.join(', ')}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, height: 1.4)),
          ],
          const SizedBox(height: 10),
          Text('$_summaryStars Sterne für deinen Rückblick · einmal vergeben',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: const ValueKey('lumo-summary-revise'),
            onPressed: _finishing || !_ownsProfile
                ? null
                : () {
                    setState(() {
                      _summaryEvaluated = false;
                      _inputMessage = null;
                    });
                    _publishTask();
                  },
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Text ergänzen'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 48), foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBottomNav() {
    return Padding(
      padding: const EdgeInsets.all(LumoTokens.space16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: _summaryEvaluated
            ? ElevatedButton.icon(
                key: const ValueKey('lumo-summary-finish'),
                onPressed: _finishing || !_ownsProfile ? null : _showFinish,
                icon: const Icon(Icons.celebration_rounded),
                label: const Text('Fertig!'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LumoTokens.colors.lumoOrange,
                  foregroundColor: Colors.white,
                  textStyle: LumoTokens.typo.labelLarge.copyWith(fontSize: 16),
                  shape:
                      RoundedRectangleBorder(borderRadius: LumoTokens.brLarge),
                ),
              )
            : ElevatedButton.icon(
                key: const ValueKey('lumo-summary-evaluate'),
                onPressed: !_ownsProfile ||
                        _speech.listening ||
                        _speechStarting ||
                        _summaryNeedsReview
                    ? null
                    : _evaluateSummary,
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Rückmeldung holen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LumoTokens.colors.lumoLila,
                  foregroundColor: Colors.white,
                  textStyle: LumoTokens.typo.labelLarge.copyWith(fontSize: 16),
                  shape:
                      RoundedRectangleBorder(borderRadius: LumoTokens.brLarge),
                ),
              ),
      ),
    );
  }
}
