import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/school_exercise_generator.dart';
import '../../core/lumo_voice.dart';

class LearningContent extends StatefulWidget {
  const LearningContent({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<LearningContent> createState() => _LearningContentState();
}

class _LearningContentState extends State<LearningContent> {
  final _factory = ExerciseFactory();
  late LumoTask _task;
  String? _picked;
  bool _answered = false;
  int _questionNum = 1;
  final int _totalQuestions = 10;

  @override
  void initState() {
    super.initState();
    _task = _nextTask();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LumoVoice.instance.speak('Arbeite wie im Heft. Ruhig lesen, dann erst antworten.');
    });
  }

  LumoTask _nextTask() {
    final st = widget.appState.state;
    return _factory.next(
      grade: st.grade,
      subject: st.subject,
      unit: st.unit == 'Alle' ? 'Alle' : st.unit,
      weakSkills: st.weakSkills,
      avoidUnits: {},
    );
  }

  void _answer(String choice) {
    if (_answered) return;
    setState(() {
      _picked = choice;
      _answered = true;
    });

    final correct = choice == _task.answer;
    if (correct) {
      widget.appState.correctAnswer(_task.unit);
      widget.appState.recordLearningAnswer(subject: _task.subject, unit: _task.unit, correct: true, hintUsed: false);
      LumoVoice.instance.speak('Super! Das war richtig!');
      Timer(const Duration(milliseconds: 1100), _nextQuestion);
    } else {
      widget.appState.wrongAnswer(_task.unit);
      widget.appState.recordLearningAnswer(subject: _task.subject, unit: _task.unit, correct: false, hintUsed: false);
      LumoVoice.instance.speak('Die richtige Antwort wäre ${_task.answer}.');
    }
  }

  void _nextQuestion() {
    if (!mounted) return;
    setState(() {
      _questionNum = (_questionNum < _totalQuestions) ? _questionNum + 1 : 1;
      _task = _nextTask();
      _picked = null;
      _answered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.appState.state;
    final title = st.subject == 'Alle' ? 'Gemischte Übung' : st.subject;
    final chip = st.subject == 'Alle'
        ? 'Klasse ${st.grade} • gemischt'
        : '${st.subject} • ${st.unit == 'Alle' ? 'alle Themen' : st.unit}';
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 560;
      return SingleChildScrollView(
        padding: EdgeInsets.all(compact ? 14 : 26),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: const TextStyle(fontFamily: 'Nunito', fontSize: 34, fontWeight: FontWeight.w900, color: LumoColors.ink900, height: 1.05)),
                    const SizedBox(height: 8),
                    const Text('Arbeite wie im Heft. Ruhig lesen, dann erst antworten.', style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w800, color: LumoColors.ink500, height: 1.35)),
                  ]),
                ),
                Container(
                  decoration: BoxDecoration(color: LumoColors.orangeSurface, shape: BoxShape.circle, boxShadow: [BoxShadow(color: LumoColors.orange.withOpacity(.20), blurRadius: 14, offset: const Offset(0, 6))]),
                  child: IconButton(icon: const Icon(Icons.volume_up_rounded, color: LumoColors.orange, size: 26), onPressed: () => LumoVoice.instance.speak('Aufgabe ${_task.prompt}')),
                ),
              ]),
              const SizedBox(height: 22),
              _ProgressHeader(current: _questionNum, total: _totalQuestions, subject: chip),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(compact ? 22 : 30),
                decoration: lumoCard(gradient: const LinearGradient(colors: [Color(0xFFFFF4BD), Color(0xFFFFF8DC)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_task.subject, style: LumoTextStyles.label.copyWith(color: LumoColors.orange, fontSize: 13)),
                  const SizedBox(height: 10),
                  Text(_task.prompt, style: TextStyle(fontFamily: 'Nunito', fontSize: compact ? 30 : 40, fontWeight: FontWeight.w900, color: LumoColors.ink900, height: 1.12)),
                  const SizedBox(height: 18),
                  _NumberAid(task: _task, picked: _picked, answered: _answered),
                ]),
              ),
              const SizedBox(height: 24),
              Text('Wähle die richtige Antwort:', style: LumoTextStyles.label.copyWith(color: LumoColors.ink500, fontSize: 14)),
              const SizedBox(height: 14),
              _ChoiceGrid(task: _task, picked: _picked, answered: _answered, onTap: _answer),
              if (_answered && _picked != null) ...[
                const SizedBox(height: 22),
                _ExplanationCard(correct: _picked == _task.answer, explanation: _task.explanation, correctAnswer: _task.answer, onNext: _nextQuestion),
              ],
            ]),
          ),
        ),
      );
    });
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.current, required this.total, required this.subject});
  final int current;
  final int total;
  final String subject;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: lumoCard(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text('Aufgabe $current von $total', maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Nunito', fontSize: 19, fontWeight: FontWeight.w900, color: LumoColors.ink900)),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 230),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(color: LumoColors.orangeSurface, borderRadius: BorderRadius.circular(LumoRadius.pill), border: Border.all(color: LumoColors.orange.withOpacity(.2))),
              child: Text(subject, style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w900, color: LumoColors.orange), maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(LumoRadius.pill), child: LinearProgressIndicator(value: current / total, minHeight: 8, color: LumoColors.orange, backgroundColor: LumoColors.orange.withOpacity(.14))),
      ]),
    );
  }
}

class _NumberAid extends StatelessWidget {
  const _NumberAid({required this.task, required this.picked, required this.answered});
  final LumoTask task;
  final String? picked;
  final bool answered;

  @override
  Widget build(BuildContext context) {
    final numbers = task.choices.map(int.tryParse).whereType<int>().toList()..sort();
    final answer = int.tryParse(task.answer);
    if (numbers.length < 3 || answer == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(.72), borderRadius: BorderRadius.circular(LumoRadius.lg), border: Border.all(color: Colors.white.withOpacity(.9), width: 1.4)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Zahlenhilfe', style: TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w900, color: LumoColors.ink500)),
        const SizedBox(height: 14),
        Stack(alignment: Alignment.center, children: [
          Container(height: 6, decoration: BoxDecoration(color: LumoColors.orange.withOpacity(.18), borderRadius: BorderRadius.circular(LumoRadius.pill))),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: numbers.map((n) {
            final selected = picked == '$n';
            final correct = answered && n == answer;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected || correct ? 42 : 34,
              height: selected || correct ? 42 : 34,
              decoration: BoxDecoration(color: correct ? const Color(0xFF22C55E) : selected ? LumoColors.orange : Colors.white, shape: BoxShape.circle, border: Border.all(color: correct ? const Color(0xFF22C55E) : LumoColors.orange.withOpacity(.55), width: 2), boxShadow: selected || correct ? LumoShadow.pill : []),
              child: Center(child: Text('$n', style: TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w900, color: selected || correct ? Colors.white : LumoColors.ink900))),
            );
          }).toList()),
        ]),
      ]),
    );
  }
}

class _ChoiceGrid extends StatelessWidget {
  const _ChoiceGrid({required this.task, required this.picked, required this.answered, required this.onTap});
  final LumoTask task;
  final String? picked;
  final bool answered;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 460;
      final itemWidth = compact ? constraints.maxWidth : (constraints.maxWidth - 24) / 3;
      return Wrap(spacing: 12, runSpacing: 12, children: task.choices.map((c) => SizedBox(width: itemWidth, child: _ChoiceChip(label: c, picked: picked, correct: task.answer, answered: answered, onTap: onTap))).toList());
    });
  }
}

class _ChoiceChip extends StatefulWidget {
  const _ChoiceChip({required this.label, required this.picked, required this.correct, required this.answered, required this.onTap});
  final String label;
  final String? picked;
  final String correct;
  final bool answered;
  final ValueChanged<String> onTap;

  @override
  State<_ChoiceChip> createState() => _ChoiceChipState();
}

class _ChoiceChipState extends State<_ChoiceChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isCorrect = widget.label == widget.correct;
    final isPicked = widget.label == widget.picked;
    final Color bg;
    final Color border;
    final Color textColor;
    if (!widget.answered) {
      bg = _hovered ? LumoColors.orangeSurface : Colors.white;
      border = _hovered ? LumoColors.orange : LumoColors.ink100;
      textColor = LumoColors.ink900;
    } else if (isCorrect) {
      bg = const Color(0xFFDCFCE7);
      border = const Color(0xFF22C55E);
      textColor = const Color(0xFF14532D);
    } else if (isPicked) {
      bg = const Color(0xFFFFE4E6);
      border = const Color(0xFFF43F5E);
      textColor = const Color(0xFF881337);
    } else {
      bg = Colors.white;
      border = LumoColors.ink100;
      textColor = LumoColors.ink300;
    }
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => widget.onTap(widget.label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(LumoRadius.pill), border: Border.all(color: border, width: 2), boxShadow: !widget.answered && _hovered ? LumoShadow.pill : []),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (widget.answered && isCorrect) const Padding(padding: EdgeInsets.only(right: 7), child: Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 20)),
            if (widget.answered && isPicked && !isCorrect) const Padding(padding: EdgeInsets.only(right: 7), child: Icon(Icons.cancel_rounded, color: Color(0xFFF43F5E), size: 20)),
            Flexible(child: Text(widget.label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Nunito', fontSize: 24, fontWeight: FontWeight.w900, color: textColor))),
          ]),
        ),
      ),
    );
  }
}

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({required this.correct, required this.explanation, required this.correctAnswer, required this.onNext});
  final bool correct;
  final String explanation;
  final String correctAnswer;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: lumoCard(gradient: LinearGradient(colors: correct ? [const Color(0xFFDCFCE7), const Color(0xFFF0FFF4)] : [const Color(0xFFFFE4E6), const Color(0xFFFFF1F2)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(correct ? Icons.celebration_rounded : Icons.lightbulb_rounded, color: correct ? const Color(0xFF22C55E) : const Color(0xFFF59E0B), size: 26),
          const SizedBox(width: 10),
          Expanded(child: Text(correct ? 'Super gemacht! ⭐' : 'Nicht aufgeben!', style: TextStyle(fontFamily: 'Nunito', fontSize: 17, fontWeight: FontWeight.w900, color: correct ? const Color(0xFF14532D) : const Color(0xFF78350F)))),
        ]),
        const SizedBox(height: 8),
        Text(explanation, style: LumoTextStyles.body.copyWith(color: correct ? const Color(0xFF166534) : const Color(0xFF92400E))),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: onNext,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [LumoColors.orange, LumoColors.orangeLight]), borderRadius: BorderRadius.circular(LumoRadius.pill), boxShadow: LumoShadow.pill),
              child: const Text('Weiter →', style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ),
        ),
      ]),
    );
  }
}
