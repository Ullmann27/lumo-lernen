import 'package:flutter/material.dart';

import 'demo_class_data.dart';
import 'demo_homework.dart';
import 'holo_widgets.dart';

/// Kind-Ansicht einer Hausaufgabe. Prüft jede Antwort automatisch gegen die
/// Lösung des Aufgabengenerators und misst Zeit und Hilfenutzung.
class HomeworkRunnerScreen extends StatefulWidget {
  const HomeworkRunnerScreen({
    super.key,
    required this.homework,
    required this.child,
    required this.store,
    this.clock = DateTime.now,
  });

  final DemoHomework homework;
  final DemoChild child;
  final DemoHomeworkStore store;
  final DateTime Function() clock;

  @override
  State<HomeworkRunnerScreen> createState() => _HomeworkRunnerScreenState();
}

class _HomeworkRunnerScreenState extends State<HomeworkRunnerScreen> {
  late final List<HomeworkTask> _tasks =
      widget.homework.tasksFor(widget.child.id, grade: widget.child.grade);
  final List<HomeworkItemResult> _results = [];
  late DateTime _startedAt = widget.clock();
  bool _hintShown = false;
  String? _picked;
  bool _saving = false;

  int get _index => _results.length;
  bool get _finished => _index >= _tasks.length;

  void _pick(String choice) {
    if (_picked != null) return;
    final task = _tasks[_index];
    setState(() => _picked = choice);
    final result = HomeworkItemResult(
      prompt: task.prompt,
      expected: task.answer,
      given: choice,
      durationMs: widget.clock().difference(_startedAt).inMilliseconds,
      hintUsed: _hintShown,
    );
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _results.add(result);
        _picked = null;
        _hintShown = false;
        _startedAt = widget.clock();
      });
      if (_finished) _save();
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.store
        .recordResult(widget.homework.id, widget.child.id, _results);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HoloPalette.deep,
      appBar: AppBar(
        backgroundColor: HoloPalette.night,
        foregroundColor: HoloPalette.text,
        title: const Text('Hausaufgabe'),
        actions: const [
          Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(child: DemoDataBadge())),
        ],
      ),
      body: HoloBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text(
                '${widget.child.name} · ${widget.homework.subject} · '
                '${widget.homework.unit}',
                style: const TextStyle(
                    color: HoloPalette.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800),
              ),
              if (widget.homework.note.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                HoloPanel(
                  accent: HoloPalette.amber,
                  shimmer: false,
                  child: Row(children: [
                    const Icon(Icons.edit_note_rounded,
                        color: HoloPalette.amber),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Hinweis der Lehrerin: ${widget.homework.note}',
                          style: const TextStyle(color: HoloPalette.text)),
                    ),
                  ]),
                ),
              ],
              const SizedBox(height: 16),
              if (_finished) _summary() else _taskView(),
              const SizedBox(height: 18),
              const LocalDemoNotice(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _taskView() {
    final task = _tasks[_index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
          value: _index / _tasks.length,
          minHeight: 8,
          color: HoloPalette.cyan,
          backgroundColor: Colors.white12,
        ),
        const SizedBox(height: 8),
        Text('Aufgabe ${_index + 1} von ${_tasks.length}',
            style: const TextStyle(color: HoloPalette.muted)),
        const SizedBox(height: 12),
        HoloPanel(
          child: Text(
            task.prompt,
            key: const ValueKey('homework-prompt'),
            textAlign: TextAlign.center,
            style: TextStyle(
                color: HoloPalette.text,
                fontSize: task.prompt.length > 40 ? 22 : 30,
                fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            for (final c in task.choices)
              SizedBox(
                // Wörter und Sätze (Deutsch) brauchen mehr Breite als Zahlen.
                width: task.choices.any((x) => x.length > 8) ? 280 : 140,
                child: HoloButton(
                  key: ValueKey('homework-choice-$c'),
                  label: c,
                  accent: _picked == null
                      ? HoloPalette.cyan
                      : c == task.answer
                          ? HoloPalette.mint
                          : (c == _picked ? HoloPalette.rose : HoloPalette.blue),
                  onPressed: _picked == null ? () => _pick(c) : null,
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (_hintShown)
          HoloPanel(
            accent: HoloPalette.violet,
            shimmer: false,
            child: Text('Lumo hilft: ${task.explanation}',
                style: const TextStyle(color: HoloPalette.text)),
          )
        else
          Center(
            child: HoloButton(
              key: const ValueKey('homework-hint'),
              label: 'Lumo, hilf mir',
              icon: Icons.lightbulb_rounded,
              accent: HoloPalette.violet,
              onPressed:
                  _picked == null ? () => setState(() => _hintShown = true) : null,
            ),
          ),
      ],
    );
  }

  Widget _summary() {
    final eval = HomeworkEvaluation(widget.homework, widget.child.id, _results);
    return HoloPanel(
      accent: HoloPalette.mint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Geschafft!',
              style: TextStyle(
                  color: HoloPalette.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            '${eval.correct} von ${eval.items.length} richtig. '
            'Deine Lehrerin sieht jetzt, wie es dir gegangen ist.',
            style: const TextStyle(color: HoloPalette.text, fontSize: 16),
          ),
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: LinearProgressIndicator(color: HoloPalette.mint),
            ),
          const SizedBox(height: 14),
          HoloButton(
            label: 'Zurück zur Lehrerin',
            icon: Icons.arrow_back_rounded,
            onPressed:
                _saving ? null : () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }
}
