import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../app/app_theme.dart';
import '../../../core/game_progress_repository.dart';
import '../../../core/math_task_templates.dart';
import '../../../domain/games/game_level_model.dart';
import '../../shared/widgets/lumo_companion_avatar.dart';
import '../../shared/widgets/lumo_premium_effects.dart';

/// Sprint 6 - Erstes spielbares Mini-Game.
///
/// Konzept "Lumo sammelt Sterne":
///   - 5 Aufgaben hintereinander
///   - Pro richtige Antwort: 1 Stern + Lumo huepft auf naechstes Feld
///   - Pro falsche Antwort: kurzer Hinweis, Aufgabe bleibt
///   - 5 Sterne richtig = Level geschafft -> 3 Sterne fuer Catalog
///   - 4 richtig (1 falsch beim 1. Versuch) = 2 Sterne
///   - 3 richtig = 1 Stern
class StarsPathGame extends StatefulWidget {
  const StarsPathGame({
    super.key,
    required this.appState,
    required this.level,
    this.onResult,
  });

  final LumoAppState appState;
  final GameLevel level;
  /// Wird mit der erreichten Sternzahl (0-3) aufgerufen wenn Spiel endet.
  final ValueChanged<int>? onResult;

  @override
  State<StarsPathGame> createState() => _StarsPathGameState();
}

class _StarsPathGameState extends State<StarsPathGame> {
  static const _totalTasks = 5;
  static const _seedLevelFactor = 1000;
  static const _seedTaskStep = 97;
  static const _seedAttemptStep = 17;
  static const _seedFallbackStep = 31;
  static const _seedShuffleOffset = 41;
  static const _maxUniquenessAttempts = 12;
  static const _repo = GameProgressRepository();

  int _currentIndex = 0;
  int _correct = 0;
  int _wrongFirstTry = 0;
  bool _attemptedThisTask = false;
  int? _selectedOption;
  bool _revealed = false;
  int _confettiTrigger = 0;
  late final List<MathConcreteTask> _tasks;

  String get _childId {
    final st = widget.appState.state;
    final safeName = st.childName.trim().isEmpty
        ? 'kind'
        : st.childName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return 'local_${safeName}_${st.grade}';
  }

  @override
  void initState() {
    super.initState();
    _tasks = _buildTasks();
  }

  MathConcreteTask get _currentTask => _tasks[_currentIndex];

  List<MathConcreteTask> _buildTasks() {
    final grade = math.max(widget.level.gradeFloor, widget.appState.state.grade);
    final units = _unitsForLevel(grade);
    final uniqueKeys = <_TaskFingerprint>{};
    final tasks = <MathConcreteTask>[];

    for (var i = 0; i < _totalTasks; i++) {
      MathConcreteTask? selected;
      for (var attempt = 0; attempt < _maxUniquenessAttempts; attempt++) {
        final seed = widget.level.id * _seedLevelFactor +
            i * _seedTaskStep +
            attempt * _seedAttemptStep;
        final unit = units[(i + attempt) % units.length];
        final generated = MathTaskTemplates.generate(
          grade: grade,
          unit: unit,
          seed: seed,
        );
        final key = _TaskFingerprint(
          prompt: generated.prompt,
          answer: generated.answer,
          pattern: generated.promptPattern,
        );
        if (uniqueKeys.add(key)) {
          selected = _withShuffledChoices(generated, seed + _seedShuffleOffset);
          break;
        }
      }
      tasks.add(
        selected ??
            _withShuffledChoices(
              MathTaskTemplates.generate(
                grade: grade,
                unit: units.first,
                seed: widget.level.id * _seedLevelFactor + i * _seedFallbackStep,
              ),
              widget.level.id * _seedLevelFactor +
                  i * _seedFallbackStep +
                  _seedShuffleOffset,
            ),
      );
    }
    return tasks;
  }

  MathConcreteTask _withShuffledChoices(MathConcreteTask task, int seed) {
    final shuffledChoices = List<String>.from(task.choices);
    final random = math.Random(seed);
    shuffledChoices.shuffle(random);
    return MathConcreteTask(
      unit: task.unit,
      prompt: task.prompt,
      answer: task.answer,
      choices: shuffledChoices,
      explanation: task.explanation,
      visual: task.visual,
      difficulty: task.difficulty,
      promptPattern: task.promptPattern,
    );
  }

  List<String> _unitsForLevel(int grade) {
    final available = MathTaskTemplates.templatesForGrade(grade)
        .map((t) => t.unit)
        .toSet()
        .toList(growable: false);
    List<String> preferred = const <String>['Plus bis 10'];
    final title = widget.level.title.toLowerCase();
    final subject = widget.level.subject.toLowerCase();

    if (widget.level.miniType == GameMiniType.mixedQuiz) {
      preferred = <String>['Plus bis 20', 'Minus bis 20', 'Zahlenstrahl', 'Geld', 'Uhrzeit', 'Geometrie Formen'];
    } else if (widget.level.miniType == GameMiniType.numberPath || title.contains('zahlenweg') || title.contains('zahl')) {
      preferred = <String>['Zahlenstrahl', 'Vergleichen', 'Gerade und ungerade'];
    } else if (title.contains('minus')) {
      preferred = <String>['Minus bis 10', 'Minus bis 20', 'Minus bis 100'];
    } else if (title.contains('plus')) {
      preferred = <String>['Plus bis 10', 'Plus bis 20', 'Plus bis 100'];
    } else if (subject.contains('deutsch')) {
      preferred = <String>['Zahl in Worten', 'Vergleichen'];
    } else if (subject.contains('sach')) {
      preferred = <String>['Zeit', 'Geometrie Formen', 'Geld'];
    }

    final filtered = preferred.where(available.contains).toList(growable: false);
    if (filtered.isNotEmpty) return filtered;
    if (available.isNotEmpty) return available;
    final defaultUnit = MathTaskTemplates.templates.first.unit;
    return <String>[defaultUnit];
  }

  void _selectOption(int idx) {
    if (_revealed) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedOption = idx);
  }

  void _confirm() {
    if (_selectedOption == null || _revealed) return;
    final selectedText = _currentTask.choices[_selectedOption!];
    final isCorrect = selectedText == _currentTask.answer;
    setState(() {
      _revealed = true;
      if (isCorrect) {
        _correct++;
        _confettiTrigger++;
        HapticFeedback.mediumImpact();
      } else {
        if (!_attemptedThisTask) _wrongFirstTry++;
        _attemptedThisTask = true;
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _next() {
    if (!_revealed) return;
    final isCorrect = _currentTask.choices[_selectedOption!] == _currentTask.answer;
    if (!isCorrect) {
      // Bei falsch: gleiche Aufgabe nochmal, aber Versuch wird gezaehlt
      setState(() {
        _selectedOption = null;
        _revealed = false;
      });
      return;
    }
    if (_currentIndex >= _totalTasks - 1) {
      _finishGame();
      return;
    }
    setState(() {
      _currentIndex++;
      _selectedOption = null;
      _revealed = false;
      _attemptedThisTask = false;
    });
  }

  Future<void> _finishGame() async {
    // Stern-Berechnung: alle richtig + max 1 fehler = 3, sonst weniger
    int stars;
    if (_correct == _totalTasks && _wrongFirstTry == 0) {
      stars = 3;
    } else if (_correct == _totalTasks) {
      stars = 2;
    } else if (_correct >= 3) {
      stars = 1;
    } else {
      stars = 0;
    }
    await _repo.recordResult(
      childId: _childId,
      levelId: widget.level.id,
      starsEarned: stars,
    );
    if (!mounted) return;
    widget.onResult?.call(stars);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultDialog(
        stars: stars,
        levelTitle: widget.level.title,
        correctCount: _correct,
        totalTasks: _totalTasks,
        onClose: () {
          Navigator.of(context).pop(); // dialog
          Navigator.of(context).pop(); // game screen
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7E6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: LumoColors.ink700),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          widget.level.title,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            color: LumoColors.ink900,
            fontSize: 18,
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                children: [
                  _PathHeader(currentIndex: _currentIndex, correct: _correct, total: _totalTasks),
                  const SizedBox(height: 14),
                  Expanded(child: _buildTaskCard()),
                  const SizedBox(height: 12),
                  _buildActionButton(),
                ],
              ),
            ),
          ),
          if (_confettiTrigger > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: LumoConfettiBurst(trigger: _confettiTrigger),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskCard() {
    final task = _currentTask;
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(LumoRadius.xl),
          boxShadow: LumoShadow.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LumoCompanionAvatar(
                  mood: _revealed
                      ? (_currentTask.choices[_selectedOption!] == task.answer
                          ? LumoCompanionMood.cheer
                          : LumoCompanionMood.help)
                      : LumoCompanionMood.idle,
                  size: 56,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Aufgabe ${_currentIndex + 1} von $_totalTasks',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: LumoColors.ink500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              task.prompt,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: 26,
                color: LumoColors.ink900,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 24),
            ...List<Widget>.generate(task.choices.length, (i) {
              final c = task.choices[i];
              final selected = _selectedOption == i;
              final isCorrect = c == task.answer;
              Color bg = Colors.white;
              Color border = LumoColors.ink100;
              Color fg = LumoColors.ink900;
              if (_revealed) {
                if (isCorrect) {
                  bg = const Color(0xFF10B981);
                  border = const Color(0xFF059669);
                  fg = Colors.white;
                } else if (selected) {
                  bg = const Color(0xFFFED7AA);
                  border = const Color(0xFFEA580C);
                  fg = const Color(0xFF7C2D12);
                }
              } else if (selected) {
                bg = LumoColors.orange;
                border = const Color(0xFFD97706);
                fg = Colors.white;
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: GestureDetector(
                  onTap: () => _selectOption(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(LumoRadius.lg),
                      border: Border.all(color: border, width: 2),
                      boxShadow: selected || (_revealed && isCorrect)
                          ? [BoxShadow(color: border.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            c,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: fg,
                            ),
                          ),
                        ),
                        if (_revealed && isCorrect)
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                        if (_revealed && selected && !isCorrect)
                          const Icon(Icons.cancel_outlined, color: Color(0xFF7C2D12), size: 22),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    final label = _revealed
        ? (_currentTask.choices[_selectedOption!] == _currentTask.answer
            ? (_currentIndex >= _totalTasks - 1 ? 'Spiel beenden' : 'Weiter')
            : 'Nochmal probieren')
        : 'Antwort bestaetigen';
    final enabled = _revealed || _selectedOption != null;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? LumoColors.orange : const Color(0xFFE0E0E0),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LumoRadius.pill)),
          elevation: enabled ? 4 : 0,
        ),
        onPressed: enabled ? (_revealed ? _next : _confirm) : null,
        child: Text(
          label,
          style: const TextStyle(fontFamily: 'Nunito', fontSize: 17, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _TaskFingerprint {
  const _TaskFingerprint({
    required this.prompt,
    required this.answer,
    required this.pattern,
  });

  final String prompt;
  final String answer;
  final String pattern;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _TaskFingerprint &&
        other.prompt == prompt &&
        other.answer == answer &&
        other.pattern == pattern;
  }

  @override
  int get hashCode => Object.hash(prompt, answer, pattern);
}

// ─────────────────── PFAD-HEADER ───────────────────

class _PathHeader extends StatelessWidget {
  const _PathHeader({required this.currentIndex, required this.correct, required this.total});
  final int currentIndex;
  final int correct;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        boxShadow: [
          BoxShadow(
            color: LumoColors.orange.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List<Widget>.generate(total, (i) {
          final isPast = i < currentIndex;
          final isCurrent = i == currentIndex;
          final isStar = i < correct;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isStar
                          ? LumoColors.gold
                          : (isCurrent ? LumoColors.orange : (isPast ? const Color(0xFFFED7AA) : const Color(0xFFEEEEEE))),
                      shape: BoxShape.circle,
                      boxShadow: isCurrent
                          ? [BoxShadow(color: LumoColors.orange.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 3))]
                          : null,
                    ),
                    child: isStar
                        ? const Text('⭐', style: TextStyle(fontSize: 18))
                        : (isCurrent
                            ? const Text('🦊', style: TextStyle(fontSize: 18))
                            : null),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────── ERGEBNIS-DIALOG ───────────────────

class _ResultDialog extends StatelessWidget {
  const _ResultDialog({
    required this.stars,
    required this.levelTitle,
    required this.correctCount,
    required this.totalTasks,
    required this.onClose,
  });
  final int stars;
  final String levelTitle;
  final int correctCount;
  final int totalTasks;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final headline = stars == 3
        ? 'Perfekt!'
        : stars == 2
            ? 'Super gemacht!'
            : stars == 1
                ? 'Du hast es geschafft!'
                : 'Probier es nochmal';
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LumoRadius.xl)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LumoCompanionAvatar(mood: LumoCompanionMood.cheer, size: 80),
            const SizedBox(height: 14),
            Text(
              headline,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: 24,
                color: LumoColors.ink900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              levelTitle,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: LumoColors.ink500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(3, (i) {
                final earned = i < stars;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    earned ? '⭐' : '☆',
                    style: TextStyle(fontSize: 40, color: earned ? null : LumoColors.ink300),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),
            Text(
              '$correctCount von $totalTasks Aufgaben richtig',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: LumoColors.ink600,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: LumoColors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LumoRadius.pill)),
                  elevation: 0,
                ),
                onPressed: onClose,
                child: const Text(
                  'Zurueck zur Spielewelt',
                  style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
