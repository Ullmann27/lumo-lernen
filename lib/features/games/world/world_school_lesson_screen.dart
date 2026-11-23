import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../core/learning_attempt_id.dart';
import '../../../core/learning_journey.dart';
import '../../../core/lumo_learning_narration.dart';
import '../../../core/lumo_sound.dart';
import '../../../domain/learning/lumo_learning_domain.dart';
import '../../../domain/world/world_school_mission.dart';
import '../../../theme/lumo_visual_tokens.dart';
import '../../../widgets/design/lumo_design_system.dart';
import '../../../widgets/fox/lumo_character.dart';
import '../../learning/adapters/legacy_lumo_task_adapter.dart';
import '../../learning/renderers/adaptive_task_renderer.dart';
import '../../learning_modules/learning_module_progress.dart';

/// The world school uses the same assessed task renderer and durable answer
/// writer as the learning app. Merely opening, leaving or viewing a hint cannot
/// produce a successful mission receipt.
class WorldSchoolLessonScreen extends StatefulWidget {
  const WorldSchoolLessonScreen({
    super.key,
    required this.appState,
    required this.request,
  });

  final LumoAppState appState;
  final WorldSchoolMissionRequest request;

  @override
  State<WorldSchoolLessonScreen> createState() =>
      _WorldSchoolLessonScreenState();
}

class _WorldSchoolLessonScreenState extends State<WorldSchoolLessonScreen> {
  final _fox = LumoCharacterController();
  final _narration = LumoLearningNarration();
  final List<LearningModuleProgress> _progress = [];
  final List<TaskInstance> _instances = [];
  LearningProfileLease? _lease;
  WorldSchoolLesson? _lesson;
  bool _loading = true;
  bool _invalid = false;
  bool _busy = false;
  bool _accepted = false;
  bool _hintUsed = false;
  bool _returning = false;
  int _index = 0;
  String _feedback = '';

  bool get _safe =>
      mounted &&
      !_invalid &&
      _lease != null &&
      widget.appState.isCurrentLearningLease(_lease!) &&
      widget.appState.state.grade == widget.request.grade;

  bool get _reduced =>
      widget.appState.state.settings.reduceAnimations ||
      widget.appState.state.settings.calmMode ||
      MediaQuery.disableAnimationsOf(context);

  LearningModuleProgress get _currentProgress => _progress[_index];

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_checkOwner);
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final lease = await widget.appState.captureLearningProfile();
      await widget.appState.prepareLearningLease(lease);
      if (!mounted) return;
      if (!widget.appState.isCurrentLearningLease(lease) ||
          widget.appState.state.grade != widget.request.grade) {
        setState(() {
          _loading = false;
          _invalid = true;
        });
        return;
      }
      final lesson = WorldSchoolLesson.start(
        request: widget.request,
        ownerId: lease.studentId,
      );
      const adapter = LegacyLumoTaskAdapter();
      for (var i = 0; i < lesson.tasks.length; i++) {
        final task = lesson.tasks[i];
        final progress = LearningModuleProgress(
          appState: widget.appState,
          subject: task.subject,
          unit: task.unit,
        );
        progress.beginPresentedTask('${widget.request.requestId}:$i');
        progress.addListener(_repaint);
        _progress.add(progress);
        _instances.add(
          adapter.toTaskInstance(
            task: task,
            childId: lease.studentId,
            difficulty: task.difficulty,
          ),
        );
      }
      setState(() {
        _lease = lease;
        _lesson = lesson;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _invalid = true;
        });
      }
    }
  }

  void _repaint() {
    if (mounted) setState(() {});
  }

  void _checkOwner() {
    if (_lease == null || _invalid || _returning) return;
    if (!_safe) {
      _lesson?.cancel();
      unawaited(_narration.stop());
      if (mounted) setState(() => _invalid = true);
    }
  }

  Future<void> _answer(AdaptiveTaskAnswer response) async {
    if (!_safe || _busy || _accepted || _lesson == null) return;
    final index = _index;
    final instance = _instances[index];
    if (response.task.taskInstanceId != instance.taskInstanceId) return;
    // Resolve the actual visible label before using the established answer
    // comparator. Parsed payloads must not lose grouping or a unit suffix.
    final options = instance.options.where(
      (option) => '${option.payload}' == '${response.answer}',
    );
    if (options.length != 1) return;
    final given = options.single.label;
    final task = _lesson!.tasks[index];
    final correct = _lesson!.accepts(index, given);
    final helped = _hintUsed || response.hintUsed;
    setState(() {
      _busy = true;
      _feedback = '';
      _hintUsed = helped;
    });
    unawaited(LumoSound.instance.play(SoundEffect.click));
    final saved = await _progress[index].saveAnswer(
      correct: correct,
      hintUsed: helped,
      prompt: task.prompt,
      given: given,
      expected: task.answer,
      problemKey: _lesson!.problemIdentity(index),
      learningEvidence: LearningEvidence(
        taskId: newLearningAttemptId(),
        problemId: _lesson!.problemIdentity(index),
        correct: correct,
        helpLevel: helped ? 3 : 0,
      ),
    );
    if (!mounted) return;
    if (!saved || !_safe || index != _index) {
      _lesson?.cancel();
      setState(() {
        _busy = false;
        _invalid = true;
      });
      return;
    }
    if (correct) {
      final accepted = _lesson!.acceptSavedAnswer(
        index: index,
        answer: given,
        currentOwnerId: _lease!.studentId,
      );
      if (!accepted) {
        setState(() {
          _busy = false;
          _invalid = true;
        });
        return;
      }
      _fox.cheer();
      unawaited(HapticFeedback.lightImpact());
      setState(() {
        _busy = false;
        _accepted = true;
        _feedback = 'Das stimmt! ${task.explanation}';
      });
    } else {
      _fox.think();
      setState(() {
        _busy = false;
        _feedback =
            'Schau noch einmal genau. Du kannst dir den Rechenweg '
            'zeigen lassen und es in Ruhe wieder versuchen.';
      });
    }
  }

  void _help() {
    if (!_safe || _busy || _accepted || _lesson == null) return;
    _currentProgress.notePresentationHelp(level: 3);
    _fox.talk();
    setState(() {
      _hintUsed = true;
      _feedback = _lesson!.tasks[_index].explanation;
    });
    unawaited(_narration.read(_feedback));
  }

  void _next() {
    if (!_safe || !_accepted || _busy || _lesson == null) return;
    unawaited(_narration.stop());
    if (_index + 1 == _lesson!.tasks.length) {
      final receipt = _lesson!.receiptForOwner(_lease!.studentId);
      if (receipt == null) return;
      _returning = true;
      Navigator.of(context).pop<Map<String, Object>>(receipt.toJson());
      return;
    }
    setState(() {
      _index++;
      _accepted = false;
      _hintUsed = false;
      _feedback = '';
    });
  }

  @override
  void dispose() {
    if (!_returning) _lesson?.cancel();
    widget.appState.removeListener(_checkOwner);
    for (final progress in _progress) {
      progress.removeListener(_repaint);
      progress.dispose();
    }
    _narration.dispose();
    _fox.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumoVisualTokens.night,
      appBar: AppBar(
        title: const Text('Lumos Weltschule'),
        backgroundColor: LumoVisualTokens.navigation,
        foregroundColor: LumoVisualTokens.white,
        leading: IconButton(
          key: const ValueKey('world-school-back'),
          tooltip: 'Zurück zur Welt',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: LumoSceneBackground(
        scene: LumoScene.learning,
        dimmed: true,
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _invalid
              ? _invalidView()
              : _lessonView(),
        ),
      ),
    );
  }

  Widget _invalidView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: LumoGlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.school_rounded,
              color: LumoVisualTokens.cyan,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Diese Schulmission konnte nicht sicher fortgesetzt werden. '
              'Kehre mit deinem gewählten Lernprofil zur Welt zurück.',
              style: _body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(minimumSize: const Size(48, 52)),
              child: const Text('Zurück zur Welt'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _lessonView() {
    final lesson = _lesson!;
    final task = lesson.tasks[_index];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LumoGlassCard(
                borderColor: LumoVisualTokens.cyan,
                child: Row(
                  children: [
                    LumoCharacter(
                      pose: LumoDesignFoxPose.bookPoint,
                      controller: _fox,
                      size: 92,
                      reduceMotion: _reduced,
                      idleHops: false,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Die Schule braucht dich!',
                            style: _body.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Löse drei Aufgaben für deinen Weltauftrag. '
                            '${widget.request.grade}. Klasse · ${task.unit}',
                            style: _body.copyWith(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                label: '${lesson.solved} von 3 Aufgaben gelöst',
                child: Row(
                  children: [
                    for (var i = 0; i < 3; i++)
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: i < lesson.solved
                                ? const Color(0xFF123D35)
                                : LumoVisualTokens.glassDeep,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              width: 1.5,
                              color: i < lesson.solved
                                  ? const Color(0xFF7DFF9A)
                                  : i == _index
                                  ? LumoVisualTokens.cyan
                                  : const Color(0xFF406079),
                            ),
                          ),
                          child: Icon(
                            i < lesson.solved
                                ? Icons.check_circle_rounded
                                : Icons.school_outlined,
                            color: i < lesson.solved
                                ? const Color(0xFF7DFF9A)
                                : LumoVisualTokens.cyan,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AbsorbPointer(
                absorbing: _busy || _accepted || !_safe,
                child: AdaptiveTaskRenderer(
                  key: ValueKey('world-school-task-$_index'),
                  task: _instances[_index],
                  onAnswered: _answer,
                  reduceMotion: _reduced,
                  requestedHelpLevel: _hintUsed ? 3 : 0,
                  guided: _hintUsed,
                  onInteraction: (interaction) {
                    if (!_safe || _busy || _accepted || !interaction.isHelp)
                      return;
                    _currentProgress.notePresentationHelp(level: 3);
                    setState(() => _hintUsed = true);
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (_feedback.isNotEmpty)
                Semantics(
                  liveRegion: true,
                  child: LumoGlassCard(
                    key: const ValueKey('world-school-feedback'),
                    borderColor: _accepted
                        ? const Color(0xFF7DFF9A)
                        : LumoVisualTokens.cyan,
                    child: Text(_feedback, style: _body),
                  ),
                ),
              if (_busy || _currentProgress.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _currentProgress.error ?? _currentProgress.savingText,
                  style: _body,
                ),
                if (_currentProgress.error != null)
                  FilledButton.icon(
                    onPressed: _currentProgress.saving
                        ? null
                        : _currentProgress.retry,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 52),
                    ),
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Speichern erneut versuchen'),
                  ),
              ],
              const SizedBox(height: 16),
              if (_accepted)
                FilledButton.icon(
                  key: const ValueKey('world-school-next'),
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7DFF9A),
                    foregroundColor: LumoVisualTokens.navigation,
                    minimumSize: const Size(48, 56),
                  ),
                  icon: Icon(
                    lesson.complete
                        ? Icons.public_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(
                    lesson.complete
                        ? 'Zurück ins Abenteuer'
                        : 'Nächste Aufgabe',
                  ),
                )
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      key: const ValueKey('world-school-help'),
                      onPressed: _safe && !_busy ? _help : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: LumoVisualTokens.white,
                        minimumSize: const Size(48, 52),
                      ),
                      icon: const Icon(Icons.lightbulb_outline_rounded),
                      label: const Text('Rechenweg zeigen'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _safe && !_busy
                          ? () => unawaited(_narration.read(task.prompt))
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: LumoVisualTokens.white,
                        minimumSize: const Size(48, 52),
                      ),
                      icon: const Icon(Icons.volume_up_rounded),
                      label: const Text('Vorlesen'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  static const _body = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 18,
    height: 1.35,
    fontWeight: FontWeight.w700,
    color: LumoVisualTokens.white,
  );
}
