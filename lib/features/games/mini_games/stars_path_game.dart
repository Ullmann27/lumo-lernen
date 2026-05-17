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
    // Generiere 5 Aufgaben passend zur Level-Klasse
    final grade = math.max(widget.level.gradeFloor, widget.appState.state.grade);
    _tasks = List<MathConcreteTask>.generate(_totalTasks, (i) {
      final seed = widget.level.id * 1000 + i * 17;
      // Klasse 1: Plus bis 10 / Minus bis 10 / Mengenvergleich
      // Klasse 2: Plus bis 20 / Minus bis 20
      String unit = 'Plus bis 10';
      if (widget.level.title.toLowerCase().contains('minus')) unit = 'Minus bis 10';
      if (widget.level.id >= 16) unit = 'Plus bis 20';
      if (widget.level.id == 17) unit = 'Minus bis 20';
      return MathTaskTemplates.generate(grade: grade, unit: unit, seed: seed);
    });
  }

  MathConcreteTask get _currentTask => _tasks[_currentIndex];

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
