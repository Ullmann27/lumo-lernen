import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/school_exercise_generator.dart';
import '../../core/lumo_voice.dart';

class LearningContent extends StatefulWidget {
  const LearningContent({
    super.key,
    required this.appState,
  });

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

    if (choice == _task.answer) {
      widget.appState.correctAnswer(_task.unit);
      LumoVoice.instance.speak('Super! Das war richtig!');
      Timer(const Duration(milliseconds: 1100), _nextQuestion);
    } else {
      widget.appState.wrongAnswer(_task.unit);
      LumoVoice.instance.speak('Fast! Die richtige Antwort wäre ${_task.answer}.');
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
    final chip = st.subject == 'Alle' ? 'Klasse ${st.grade} • gemischt' : '${st.subject} • ${st.unit == 'Alle' ? 'alle Themen' : st.unit}';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(26, 26, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontFamily: 'Nunito', fontSize: 32, fontWeight: FontWeight.w900, color: LumoColors.ink900)),
                  const Text('Arbeite wie im Heft.\nRuhig lesen, dann erst antworten.', style: TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w700, color: LumoColors.ink500, height: 1.35)),
                ],
              ),
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
            padding: const EdgeInsets.all(24),
            decoration: lumoCard(gradient: const LinearGradient(colors: [Color(0xFFFFF4BD), Color(0xFFFFF8DC)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_task.subject, style: LumoTextStyles.label.copyWith(color: LumoColors.orange)),
              const SizedBox(height: 8),
              Text(_task.prompt, style: const TextStyle(fontFamily: 'Nunito', fontSize: 34, fontWeight: FontWeight.w900, color: LumoColors.ink900, height: 1.2)),
            ]),
          ),
          const SizedBox(height: 22),
          Text('Wähle die richtige Antwort:', style: LumoTextStyles.label.copyWith(color: LumoColors.ink500, fontSize: 13)),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 12, children: _task.choices.map((c) => _ChoiceChip(label: c, picked: _picked, correct: _task.answer, answered: _answered, onTap: _answer)).toList()),
          if (_answered && _picked != null) ...[
            const SizedBox(height: 22),
            _ExplanationCard(correct: _picked == _task.answer, explanation: _task.explanation, correctAnswer: _task.answer, onNext: _nextQuestion),
          ],
        ],
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: lumoCard(),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Aufgabe $current / $total', style: const TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w900, color: LumoColors.ink900)),
            const SizedBox(height: 6),
            ClipRRect(borderRadius: BorderRadius.circular(LumoRadius.pill), child: LinearProgressIndicator(value: current / total, minHeight: 8, color: LumoColors.orange, backgroundColor: LumoColors.orange.withOpacity(.14))),
          ]),
        ),
        const SizedBox(width: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: LumoColors.orangeSurface, borderRadius: BorderRadius.circular(LumoRadius.pill), border: Border.all(color: LumoColors.orange.withOpacity(.2))),
          child: Text(subject, style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w800, color: LumoColors.orange), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
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
    Color bg;
    Color border;
    Color textColor;
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
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(LumoRadius.pill), border: Border.all(color: border, width: 2), boxShadow: !widget.answered && _hovered ? LumoShadow.pill : []),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (widget.answered && isCorrect) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 18)),
            if (widget.answered && isPicked && !isCorrect) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.cancel_rounded, color: Color(0xFFF43F5E), size: 18)),
            Text(widget.label, style: TextStyle(fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.w900, color: textColor)),
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
          Text(correct ? 'Super gemacht! ⭐' : 'Fast – nicht aufgeben!', style: TextStyle(fontFamily: 'Nunito', fontSize: 17, fontWeight: FontWeight.w900, color: correct ? const Color(0xFF14532D) : const Color(0xFF78350F))),
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
