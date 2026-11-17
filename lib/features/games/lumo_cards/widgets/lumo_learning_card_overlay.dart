import 'package:flutter/material.dart';

import '../../../../app/app_state.dart';
import '../../../../core/learning_attempt_id.dart';
import '../../../../core/lumo_companion_pose.dart';
import '../../../../core/school_exercise_generator.dart';
import '../../../../core/task_hint_service.dart';
import '../../../../core/task_quality_guard.dart';
import '../../../../domain/learning/lumo_learning_domain.dart';
import '../../../companion/lumo_companion_pose_image.dart';
import '../../../learning/adapters/legacy_lumo_task_adapter.dart';
import '../../../learning/widgets/interactive_task_workspace.dart';
import '../../../learning/widgets/learning_question_coach.dart';
import '../learning_question_repository.dart';
import '../lumo_cards_models.dart';

/// A checked learning turn inside the existing card game. The controller keeps
/// the turn, answer key and +1 star rule; exploring and hints never play a card.
class LumoLearningCardOverlay extends StatefulWidget {
  const LumoLearningCardOverlay({
    super.key,
    required this.appState,
    required this.roundId,
    required this.question,
    required this.onAnswer,
  });

  final LumoAppState appState;
  final String roundId;
  final LearningQuestion question;
  final ValueChanged<int> onAnswer;

  @override
  State<LumoLearningCardOverlay> createState() =>
      _LumoLearningCardOverlayState();
}

class _LumoLearningCardOverlayState extends State<LumoLearningCardOverlay> {
  late String _taskId;
  late LumoTask _lesson;
  TaskInstance? _workspace;
  TaskWorkspaceInteraction? _interaction;
  String? _activeObjectId;
  int _helpLevel = 0;
  bool _submitted = false;

  bool get _valid =>
      LearningQuestionRepository.acceptsLearningQuestion(widget.question);
  String get _hint =>
      const TaskHintService().explain(_lesson, level: _helpLevel.clamp(1, 3));

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(covariant LumoLearningCardOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.question, widget.question) ||
        oldWidget.roundId != widget.roundId) {
      _prepare();
    }
  }

  void _prepare() {
    _taskId = 'cards:${widget.roundId}:question:${newLearningAttemptId()}';
    _helpLevel = 0;
    _submitted = false;
    _interaction = null;
    _activeObjectId = null;
    final question = widget.question;
    final isMath = RegExp(r'\d').hasMatch(question.prompt) &&
        RegExp(r'[+−×÷=*]|\d\s*[-·:/x]|(?:Zahl|Hälfte|Viertel|größer|kleiner|gerade|mal|geteilt)',
                caseSensitive: false)
            .hasMatch(question.prompt);
    final isLanguage = RegExp(
            r'Wort|Wörter|Buchstab|Reim|Satz|Mehrzahl|Einzahl|Begleiter|Silbe|Nomen|Verb|Artikel|schreibt',
            caseSensitive: false)
        .hasMatch(question.prompt);
    _lesson = LumoTask(
      id: _taskId,
      grade: widget.appState.state.grade.clamp(1, 4),
      subject: isMath
          ? 'Mathematik'
          : isLanguage
              ? 'Deutsch'
              : 'Sachunterricht',
      unit: 'Denkpause',
      prompt: question.prompt,
      choices: question.options,
      answer: _valid ? question.options[question.correctIndex] : '',
      explanation: question.hint ?? 'Prüfe jede Antwort an der Frage.',
      visual: 'auto',
    );
    // The renderer is supplemental. It may never replace the game's question
    // with a different fallback and then score against the old answer key.
    _workspace = _valid && const TaskQualityGuard().validate(_lesson)
        ? const LegacyLumoTaskAdapter().toTaskInstance(
            task: _lesson,
            childId: 'local-game-question',
            difficulty: 1,
            now: DateTime.fromMillisecondsSinceEpoch(0))
        : null;
  }

  void _answer(int index) {
    if (!_valid ||
        _submitted ||
        index < 0 ||
        index >= widget.question.options.length) {
      return;
    }
    setState(() => _submitted = true);
    widget.onAnswer(index);
  }

  void _changed(TaskWorkspaceInteraction event) {
    if (!mounted || _submitted || event.taskId != _workspace?.taskInstanceId) {
      return;
    }
    setState(() => _interaction = event);
  }

  @override
  Widget build(BuildContext context) {
    final visibleIds = _interaction?.visibleState['objectIds'];
    final objectIds = <String>{
      'question-prompt',
      if (visibleIds is List) ...visibleIds.whereType<String>(),
    }.toList(growable: false);
    return Positioned.fill(
      child: Material(
        color: const Color(0xDB06152C),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF173D6A), Color(0xFF0B2244)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(26),
                    border:
                        Border.all(color: const Color(0xFF60CFE4), width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black38,
                          blurRadius: 24,
                          offset: Offset(0, 12))
                    ],
                  ),
                  child: LearningQuestionCoach(
                    appState: widget.appState,
                    taskId: _taskId,
                    subject: _lesson.subject,
                    unit: 'Denkpause im Kartenspiel',
                    prompt: widget.question.prompt,
                    choices: {
                      for (var i = 0; i < widget.question.options.length; i++)
                        i: widget.question.options[i]
                    },
                    active: _valid,
                    answering: _valid && !_submitted,
                    helpUsed: _helpLevel > 0,
                    helpText: _helpLevel > 0 ? _hint : null,
                    objectIds: objectIds,
                    focusObjectId: _interaction?.objectId ?? 'question-prompt',
                    visibleExplanation: _interaction?.explanation,
                    stepId: _interaction?.action,
                    onFocus: (id) => setState(() => _activeObjectId = id),
                    onHint: _submitted
                        ? null
                        : () => setState(
                            () => _helpLevel = (_helpLevel + 1).clamp(1, 3)),
                    onConfirmedChoice: _answer,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(children: [
                            LumoCompanionPoseImage(
                                pose: LumoCompanionPose.think, size: 48),
                            SizedBox(width: 12),
                            Expanded(
                                child: Text('Deine Denkpause',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white))),
                            Icon(Icons.star_rounded, color: Color(0xFFFFD47A)),
                            Text('+1',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFFFD47A))),
                          ]),
                          const SizedBox(height: 12),
                          const Text(
                              'Schau genau hin. Wähle eine Antwort, um deinen Spielzug fortzusetzen.',
                              style: TextStyle(
                                  fontSize: 16, color: Color(0xFFD0E4F5))),
                          const SizedBox(height: 16),
                          Text(widget.question.prompt,
                              key: const ValueKey('cards-learning-question'),
                              style: const TextStyle(
                                  fontSize: 25,
                                  height: 1.25,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white)),
                          if (!_valid) ...[
                            const SizedBox(height: 16),
                            const Text(
                                'Diese Frage konnte nicht eindeutig geprüft werden. Verlasse die Runde und lade sie erneut.',
                                style: TextStyle(
                                    fontSize: 17, color: Color(0xFFFFDBA3))),
                            TextButton.icon(
                                onPressed: () => Navigator.maybePop(context),
                                icon: const Icon(Icons.arrow_back),
                                label: const Text('Zurück'),
                                style: TextButton.styleFrom(
                                    minimumSize: const Size(48, 48))),
                          ] else ...[
                            if (_workspace != null) ...[
                              const SizedBox(height: 16),
                              InteractiveTaskWorkspace(
                                key: ValueKey(_workspace!.taskInstanceId),
                                task: _workspace!,
                                enabled: !_submitted,
                                helpLevel: _helpLevel,
                                activeObjectId: _activeObjectId,
                                reduceMotion:
                                    MediaQuery.disableAnimationsOf(context) ||
                                        widget.appState.state.settings
                                            .reduceAnimations ||
                                        widget.appState.state.settings.calmMode,
                                onInteraction: _changed,
                              ),
                            ],
                            if (_helpLevel > 0)
                              Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  child: Semantics(
                                      liveRegion: true,
                                      child: Text(_hint,
                                          style: const TextStyle(
                                              fontSize: 18,
                                              color: Color(0xFFFFDCA2))))),
                            const SizedBox(height: 16),
                            for (var i = 0;
                                i < widget.question.options.length;
                                i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: OutlinedButton(
                                  key: ValueKey('cards-learning-answer-$i'),
                                  onPressed:
                                      _submitted ? null : () => _answer(i),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(48, 56),
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    backgroundColor: const Color(0xFF1B4B77),
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(
                                        color: Color(0xFF79D6E8), width: 1.4),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(17)),
                                  ),
                                  child: Row(children: [
                                    Text('${String.fromCharCode(65 + i)} · ',
                                        style: const TextStyle(
                                            fontSize: 18,
                                            color: Color(0xFFFFD47A),
                                            fontWeight: FontWeight.w900)),
                                    Expanded(
                                        child: Text(widget.question.options[i],
                                            style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w800))),
                                  ]),
                                ),
                              ),
                            if (_submitted)
                              const Text('Deine Antwort wird übernommen …',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16)),
                          ],
                        ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
