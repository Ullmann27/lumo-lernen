import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../app/app_theme.dart';
import '../../../core/game_progress_repository.dart';
import '../../../domain/games/game_level_model.dart';
import '../../learning/widgets/lumo_math_visuals.dart';
import '../../shared/widgets/lumo_companion_avatar.dart';
import '../../shared/widgets/lumo_premium_effects.dart';

/// Sprint 8 - Rechenhaus-Mini-Game.
///
/// 5 Aufgaben zur Zahlzerlegung:
///   - Dach = Summe
///   - eine Kammer ist sichtbar
///   - fehlende Kammer wird gewaehlt
/// Klasse 1: Summe 5-10.
/// Klasse 2+: Summe 10-20.
class NumberHouseGame extends StatefulWidget {
  const NumberHouseGame({
    super.key,
    required this.appState,
    required this.level,
    this.onResult,
  });

  final LumoAppState appState;
  final GameLevel level;
  final ValueChanged<int>? onResult;

  @override
  State<NumberHouseGame> createState() => _NumberHouseGameState();
}

class _NumberHouseGameState extends State<NumberHouseGame> {
  static const _totalTasks = 5;
  static const _repo = GameProgressRepository();

  late final List<_HouseTask> _tasks;
  int _currentIndex = 0;
  int _correct = 0;
  int _wrongFirstTry = 0;
  bool _attemptedThisTask = false;
  int? _selectedOption;
  bool _revealed = false;
  int _confettiTrigger = 0;

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
    final grade = math.max(widget.level.gradeFloor, widget.appState.state.grade);
    _tasks = List<_HouseTask>.generate(_totalTasks, (i) {
      return _HouseTask.generate(
        grade: grade,
        seed: widget.level.id * 1000 + i * 31,
      );
    });
  }

  _HouseTask get _currentTask => _tasks[_currentIndex];

  void _selectOption(int idx) {
    if (_revealed) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedOption = idx);
  }

  void _confirm() {
    if (_selectedOption == null || _revealed) return;
    final selected = _currentTask.choices[_selectedOption!];
    final isCorrect = selected == _currentTask.answer;
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
    final stars = _starsForResult();
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
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  int _starsForResult() {
    if (_correct == _totalTasks && _wrongFirstTry == 0) return 3;
    if (_correct == _totalTasks) return 2;
    if (_correct >= 3) return 1;
    return 0;
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
                  _HouseHeader(currentIndex: _currentIndex, correct: _correct, total: _totalTasks),
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
    final selectedIsCorrect = _selectedOption != null && task.choices[_selectedOption!] == task.answer;
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
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
                      ? (selectedIsCorrect ? LumoCompanionMood.cheer : LumoCompanionMood.help)
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
            const SizedBox(height: 18),
            const Text(
              'Welche Zahl fehlt im Rechenhaus?',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: 25,
                color: LumoColors.ink900,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${task.visibleRoom} + ? = ${task.roof}',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: LumoColors.ink600,
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: MathHouseVisual(
                roof: task.roof,
                leftRoom: task.missingLeft ? null : task.visibleRoom,
                rightRoom: task.missingLeft ? task.visibleRoom : null,
                size: 210,
              ),
            ),
            const SizedBox(height: 22),
            ...List<Widget>.generate(task.choices.length, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: _ChoiceTile(
                  label: '${task.choices[i]}',
                  selected: _selectedOption == i,
                  correct: task.choices[i] == task.answer,
                  revealed: _revealed,
                  onTap: () => _selectOption(i),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    final isCorrect = _selectedOption != null && _currentTask.choices[_selectedOption!] == _currentTask.answer;
    final label = _revealed
        ? (isCorrect ? (_currentIndex >= _totalTasks - 1 ? 'Spiel beenden' : 'Weiter') : 'Nochmal probieren')
        : 'Antwort bestätigen';
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

class _HouseTask {
  const _HouseTask({
    required this.roof,
    required this.visibleRoom,
    required this.answer,
    required this.missingLeft,
    required this.choices,
  });

  final int roof;
  final int visibleRoom;
  final int answer;
  final bool missingLeft;
  final List<int> choices;

  static _HouseTask generate({required int grade, required int seed}) {
    final random = math.Random(seed);
    final minRoof = grade <= 1 ? 5 : 10;
    final maxRoof = grade <= 1 ? 10 : 20;
    final roof = minRoof + random.nextInt(maxRoof - minRoof + 1);
    final answer = 1 + random.nextInt(roof - 1);
    final visible = roof - answer;
    final choices = _buildChoices(answer: answer, max: maxRoof);
    return _HouseTask(
      roof: roof,
      visibleRoom: visible,
      answer: answer,
      missingLeft: random.nextBool(),
      choices: choices,
    );
  }

  static List<int> _buildChoices({required int answer, required int max}) {
    final values = <int>{answer};
    for (final delta in <int>[1, -1, 2, -2, 3, -3, 4, -4]) {
      final next = answer + delta;
      if (next >= 0 && next <= max) values.add(next);
      if (values.length >= 4) break;
    }
    var fill = 0;
    while (values.length < 4) {
      if (fill <= max) values.add(fill);
      fill++;
    }
    final list = values.toList()..sort();
    return list;
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.selected,
    required this.correct,
    required this.revealed,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool correct;
  final bool revealed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.white;
    Color border = LumoColors.ink100;
    Color fg = LumoColors.ink900;
    if (revealed) {
      if (correct) {
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
    return GestureDetector(
      onTap: revealed ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(LumoRadius.lg),
          border: Border.all(color: border, width: 2),
          boxShadow: selected || (revealed && correct)
              ? [BoxShadow(color: border.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: fg,
                ),
              ),
            ),
            if (revealed && correct) const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
            if (revealed && selected && !correct) const Icon(Icons.cancel_outlined, color: Color(0xFF7C2D12), size: 22),
          ],
        ),
      ),
    );
  }
}

class _HouseHeader extends StatelessWidget {
  const _HouseHeader({required this.currentIndex, required this.correct, required this.total});
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
          final isCurrent = i == currentIndex;
          final isDone = i < correct;
          return Expanded(
            child: Container(
              height: 36,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDone ? LumoColors.gold : (isCurrent ? LumoColors.orange : const Color(0xFFEEEEEE)),
                borderRadius: BorderRadius.circular(LumoRadius.pill),
                boxShadow: isCurrent
                    ? [BoxShadow(color: LumoColors.orange.withOpacity(0.45), blurRadius: 10, offset: const Offset(0, 3))]
                    : null,
              ),
              child: Text(
                isDone ? '⭐' : (isCurrent ? '🏠' : ''),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          );
        }),
      ),
    );
  }
}

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
                  'Zurück zur Spielewelt',
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
