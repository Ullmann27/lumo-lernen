import 'package:flutter/material.dart';

import '../../core/school_exercise_generator.dart';

import '../../widgets/design/lumo_design_system.dart';
import '../../widgets/fox/lumo_character.dart';

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

  /// Wie viele Hilfen Lumo zu dieser Aufgabe gezeigt hat (jede eine andere
  /// Erklärweise).
  int _hintsShown = 0;
  bool get _hintShown => _hintsShown > 0;
  String? _picked;
  bool _saving = false;

  int get _index => _results.length;
  ValueKey<String> get _aktuellerSchritt =>
      ValueKey(_finished ? 'fertig' : 'aufgabe-$_index');
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
        _hintsShown = 0;
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
                '${Curriculum.prettifyUnit(widget.homework.unit)}',
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
              // Sanfter Wechsel zur nächsten Aufgabe (bei reduzierter
              // Bewegung ohne Animation).
              AnimatedSwitcher(
                duration: holoAnimationsOff(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 380),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                // Die ausblendende Aufgabe nimmt keine Tipps mehr an.
                transitionBuilder: (child, animation) => IgnorePointer(
                  ignoring: child.key != _aktuellerSchritt,
                  child: FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                              begin: const Offset(.06, 0), end: Offset.zero)
                          .animate(animation),
                      child: child,
                    ),
                  ),
                ),
                child: KeyedSubtree(
                  key: _aktuellerSchritt,
                  child: _finished ? _summary() : _taskView(),
                ),
              ),
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
        HoloPanel(child: _promptView(task)),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            for (final c in task.choices)
              SizedBox(
                // Wörter und Sätze brauchen mehr Breite als Zahlen; ganze
                // Sätze (Lesen, Sachunterricht) stehen untereinander.
                width: task.choices.any((x) => x.length > 26)
                    ? double.infinity
                    : task.choices.any((x) => x.length > 8)
                        ? 280
                        : 140,
                child: HoloButton(
                  key: ValueKey('homework-choice-$c'),
                  label: task.pictureFor(c) == null
                      ? c
                      : '${task.pictureFor(c)}  $c',
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
        if (_hintShown) ...[
          HoloPanel(
            key: ValueKey('homework-hint-$_hintsShown'),
            accent: HoloPalette.violet,
            shimmer: false,
            child: Row(children: [
              LumoCharacter(
                pose: LumoDesignFoxPose.teacherStick,
                size: 64,
                intro: false,
                idleHops: false,
                reduceMotion: holoAnimationsOff(context),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                    // Nie die Lösung: eine Hilfe der Nachhilfe bzw. ein
                    // Tippschritt, je Bitte eine andere Erklärweise.
                    '${_hintsShown == 1 ? 'Lumo hilft' : 'Lumo erklärt es anders'}: '
                    '${_hint(task)}',
                    key: const ValueKey('homework-hint-text'),
                    style: const TextStyle(
                        color: HoloPalette.text, fontSize: 17, height: 1.35)),
              ),
            ]),
          ),
          const SizedBox(height: 10),
        ],
        if (_hintsShown < _hintCount(task))
          Center(
            child: HoloButton(
              key: const ValueKey('homework-hint'),
              label: _hintShown ? 'Anders erklären' : 'Lumo, hilf mir',
              icon: _hintShown
                  ? Icons.swap_horiz_rounded
                  : Icons.lightbulb_rounded,
              accent: HoloPalette.violet,
              onPressed:
                  _picked == null ? () => setState(() => _hintsShown++) : null,
            ),
          ),
      ],
    );
  }

  int _hintCount(HomeworkTask task) =>
      task.hints.isEmpty ? 1 : task.hints.length;

  String _hint(HomeworkTask task) => task.hints.isEmpty
      ? 'Lies die Aufgabe noch einmal langsam und prüfe jede Antwort.'
      : task.hints[(_hintsShown - 1).clamp(0, task.hints.length - 1)];

  /// Aufgabe: kurze Rechnungen groß, Lesetexte als Lesekarte, Bilder groß.
  Widget _promptView(HomeworkTask task) {
    final lesetext = task.readingText;
    final bild = task.promptPicture ??
        (lesetext.startsWith('Schau genau:')
            ? lesetext.replaceFirst('Schau genau:', '').trim()
            : null);
    if (lesetext.isEmpty && bild == null) {
      return Text(
        task.prompt,
        key: const ValueKey('homework-prompt'),
        textAlign: TextAlign.center,
        style: TextStyle(
            color: HoloPalette.text,
            fontSize: task.prompt.length > 40 ? 22 : 30,
            fontWeight: FontWeight.w800),
      );
    }
    return Column(
      key: const ValueKey('homework-prompt'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (bild != null)
          Text(bild,
              key: const ValueKey('homework-picture'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 72)),
        if (lesetext.isNotEmpty && bild == null)
          Container(
            key: const ValueKey('homework-reading'),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: HoloPalette.night,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: HoloPalette.cyan.withValues(alpha: .5)),
            ),
            child: Text(
                lesetext
                    .replaceFirst(RegExp(r'^Lies:\s*'), '')
                    .replaceFirst(
                        RegExp(r'^Die Sätze sind durcheinander:\s*'), ''),
                style: const TextStyle(
                    color: HoloPalette.text,
                    fontSize: 21,
                    height: 1.5,
                    fontWeight: FontWeight.w600)),
          ),
        const SizedBox(height: 12),
        Text(bild != null && lesetext.isEmpty ? task.prompt : task.question,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: HoloPalette.text,
                fontSize: 22,
                fontWeight: FontWeight.w800)),
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
          Row(children: [
            LumoCharacter(
              key: const ValueKey('homework-lumo-jubel'),
              pose: LumoDesignFoxPose.cheer,
              size: 88,
              intro: false,
              reduceMotion: holoAnimationsOff(context),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Geschafft!',
                  style: TextStyle(
                      color: HoloPalette.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w800)),
            ),
          ]),
          const SizedBox(height: 8),
          // Ein Stern je richtiger Antwort; sie erscheinen nacheinander.
          Wrap(spacing: 4, runSpacing: 4, children: [
            for (var i = 0; i < eval.correct; i++)
              TweenAnimationBuilder<double>(
                key: ValueKey('homework-stern-$i'),
                tween: Tween(
                    begin: holoAnimationsOff(context) ? 1 : 0, end: 1),
                duration: Duration(milliseconds: 420 + i * 140),
                curve: Curves.easeOutBack,
                builder: (context, t, child) =>
                    Transform.scale(scale: t.clamp(0.0, 1.2), child: child),
                child: const Icon(Icons.star_rounded,
                    color: HoloPalette.amber, size: 30),
              ),
          ]),
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
