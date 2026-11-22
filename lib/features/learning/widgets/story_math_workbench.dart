import 'package:flutter/material.dart';

import '../../../domain/learning/lumo_learning_domain.dart';
import '../../../widgets/design/lumo_task_object_art.dart';

/// The story's quantities belong to the child. Counting, sketching and jotting
/// down intermediate results neither choose an answer nor grant progress.
class StoryMathWorkbench extends StatefulWidget {
  const StoryMathWorkbench(
      {super.key, required this.task, this.enabled = true});

  final TaskInstance task;
  final bool enabled;

  @override
  State<StoryMathWorkbench> createState() => _StoryMathWorkbenchState();
}

class _StoryMathWorkbenchState extends State<StoryMathWorkbench> {
  final _marked = <int>{};
  bool _planning = false;
  final _operators = <int, String>{};

  @override
  void didUpdateWidget(covariant StoryMathWorkbench oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.taskInstanceId != widget.task.taskInstanceId) {
      _marked.clear();
      _operators.clear();
      _planning = false;
    }
  }

  static const _ink = Color(0xffeff7ff);
  static const _amber = Color(0xffffca69);
  static const _mint = Color(0xff74e4d9);

  @override
  Widget build(BuildContext context) {
    final data = widget.task.visualPayload.data;
    final amounts = RegExp(r'\b\d+\b').allMatches(widget.task.prompt).toList();
    final names = [
      for (final amount in amounts)
        // Keep the actual surrounding quantity and its unit. Never guess an operation
        // from the position or value of a number in a multi-step story.
        _quantityText(widget.task.prompt, amount)
    ];
    final first = data['storyStart'];
    final change = data['storyChange'];
    final subtraction = data['storySubtract'] == true;
    final oneStep = first is int && change is int;
    final equations = data['storyEquations'];
    final steps = equations is List && equations.isNotEmpty
        ? equations.length
        : switch (widget.task.parameters['visual']) {
            'story_three' => 3,
            'story_two' => 2,
            _ => widget.task.parameters['grade'] == 4 ? 3 : 2,
          };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xff113653),
        border: Border.all(color: const Color(0xff367187)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(oneStep ? 'Lege die Geschichte' : 'Dein Rechenplan',
              style: const TextStyle(
                  color: _ink, fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 6),
          if (oneStep) ...[
            Text(
                subtraction
                    ? 'Am Anfang sind es $first. Streiche $change Stück weg.'
                    : 'Zähle die beiden Mengen. Tippe jedes Stück an, wenn du es gezählt hast.',
                style: const TextStyle(color: _ink)),
            const SizedBox(height: 8),
            _counters(first, 0, _amber, subtraction),
            if (!subtraction) ...[
              const SizedBox(height: 7),
              _counters(change, first, _mint, false),
            ],
          ] else ...[
            Text(
                steps >= 3
                    ? 'Welche Angaben brauchst du, welche sind überflüssig? Schätze zuerst die Größenordnung.'
                    : 'Welche Angaben gehören zusammen? Markiere sie und finde eine Zwischenfrage.',
                style: TextStyle(color: _ink)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, children: [
              for (var i = 0; i < names.length; i++)
                FilterChip(
                  key: ValueKey('story-fact-$i'),
                  label: Text(names[i]),
                  labelStyle: const TextStyle(
                      fontFamily: 'Nunito',
                      color: _ink,
                      fontWeight: FontWeight.w700),
                  backgroundColor: const Color(0xff234852),
                  selectedColor: const Color(0xff23665d),
                  checkmarkColor: _mint,
                  selected: _marked.contains(i),
                  onSelected: widget.enabled ? (_) => _toggle(i) : null,
                )
            ]),
            if (!_planning)
              TextButton.icon(
                key: const ValueKey('story-plan-open'),
                style: TextButton.styleFrom(foregroundColor: _mint),
                icon: const Icon(Icons.edit_note),
                label: const Text('Eigenen Rechenweg notieren'),
                onPressed: widget.enabled
                    ? () => setState(() => _planning = true)
                    : null,
              )
            else
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (var i = 0; i < steps; i++)
                  Row(children: [
                    Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Tooltip(
                            message: 'Rechenzeichen für Schritt ${i + 1}',
                            child: DropdownButton<String>(
                              key: ValueKey('story-operator-$i'),
                              hint: const Icon(Icons.functions, color: _mint),
                              value: _operators[i],
                              dropdownColor: const Color(0xff17364e),
                              style: const TextStyle(
                                  color: _ink,
                                  fontFamily: 'Nunito',
                                  fontSize: 20),
                              items: [
                                for (final op in ['+', '−', '×', '÷'])
                                  DropdownMenuItem(value: op, child: Text(op))
                              ],
                              onChanged: widget.enabled
                                  ? (op) => setState(() => _operators[i] = op!)
                                  : null,
                            ))),
                    Expanded(
                        child: TextField(
                      key: ValueKey(
                          'story-notes-${widget.task.taskInstanceId}-$i'),
                      enabled: widget.enabled,
                      style: const TextStyle(color: _ink),
                      decoration: InputDecoration(
                        labelText: i == 0
                            ? 'Meine erste Rechnung'
                            : 'Mein nächster Schritt',
                        labelStyle: const TextStyle(color: Color(0xffc2d5dd)),
                      ),
                    )),
                  ]),
                if (steps >= 3)
                  const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                          'Vergleiche dein Ergebnis mit deiner Schätzung. Passt die Einheit zur Frage?',
                          style: TextStyle(color: _amber))),
              ]),
          ]
        ]),
      ),
    );
  }

  String _quantityText(String prompt, RegExpMatch match) {
    // Include a following unit/noun phrase when one is written. A bare number
    // before a verb ("7 werden gegessen") stays bare.
    final tail = prompt.substring(match.end);
    final phrase = RegExp(
      r'^\s*(€|(?:[a-zäöüß]+e[nrms]?\s+)?[A-ZÄÖÜ][a-zäöüß-]+|cm²?|kg|ml)\b',
    ).firstMatch(tail);
    return [
      match[0]!,
      if (tail.trimLeft().startsWith('€'))
        '€'
      else if (phrase != null)
        phrase[1]!
    ].join(' ');
  }

  void _toggle(int i) => setState(() {
        if (!_marked.add(i)) _marked.remove(i);
      });

  Widget _picture(bool secondGroup, Color color) {
    final text = widget.task.prompt.toLowerCase();
    String? asset;
    IconData? icon;
    if (text.contains('äpfel') || text.contains('apfelstück')) {
      asset = secondGroup && text.contains('birnen') ? 'birne' : 'apfel';
    } else if (text.contains('bücher')) {
      asset = 'buch';
    } else if (text.contains('papiersterne')) {
      asset = 'stern';
    } else if (text.contains('kekse')) {
      icon = Icons.cookie;
    } else if (text.contains('buntstifte')) {
      icon = Icons.edit;
      color = secondGroup ? Colors.blue : Colors.red;
    } else if (text.contains('kinder')) {
      icon = Icons.person;
    } else if (text.contains('tulpen')) {
      icon = Icons.local_florist;
    }
    if (asset != null) return LumoTaskObjectArt(name: asset, size: 30);
    return Icon(icon ?? Icons.circle,
        size: icon == null ? 25 : 30, color: color);
  }

  Widget _counters(int count, int offset, Color color, bool remove) =>
      Wrap(spacing: 3, runSpacing: 3, children: [
        for (var i = 0; i < count; i++)
          Semantics(
            button: true,
            label: 'Plättchen ${offset + i + 1}',
            selected: _marked.contains(offset + i),
            child: InkWell(
              key: ValueKey('story-counter-${offset + i}'),
              borderRadius: BorderRadius.circular(24),
              onTap: widget.enabled ? () => _toggle(offset + i) : null,
              child: SizedBox.square(
                dimension: 44,
                child: Center(
                    child: Stack(alignment: Alignment.center, children: [
                  Opacity(
                      opacity: _marked.contains(offset + i) ? .42 : 1.0,
                      child: ExcludeSemantics(
                          child: _picture(offset != 0, color))),
                  if (_marked.contains(offset + i))
                    DecoratedBox(
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Color(0xee163346)),
                        child: Icon(remove ? Icons.close : Icons.check,
                            size: 21, color: Colors.white)),
                ])),
              ),
            ),
          ),
      ]);
}
