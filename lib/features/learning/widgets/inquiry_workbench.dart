import 'package:flutter/material.dart';

import '../../../domain/learning/lumo_learning_domain.dart';

/// Small experiments chosen by the actual question. A closed circuit and an
/// interrupted wire have different outcomes; a calendar remains a cycle. None
/// of these controls marks an answer in the lesson.
class InquiryWorkbench extends StatefulWidget {
  const InquiryWorkbench(
      {super.key, required this.task, required this.enabled});
  final TaskInstance task;
  final bool enabled;

  static String? kindFor(TaskInstance task) {
    final unit = task.parameters['unit'];
    final text = task.prompt.toLowerCase();
    if (task.subject == LearningSubject.logik &&
        (unit == 'Reihenfolgen' || unit == 'Schlussfolgern') &&
        (text.contains('nebeneinander') ||
            text.startsWith('von links nach rechts stehen')) &&
        task.options.length >= 3 &&
        task.options.length <= 5) {
      return 'lineup';
    }
    if (task.subject == LearningSubject.logik &&
        unit == 'Regeln kombinieren' &&
        text.startsWith('welche zahl erfüllt alle drei regeln:')) {
      return 'rules';
    }
    if (task.subject != LearningSubject.sachkunde) return null;
    if (unit == 'Stromkreise' &&
        (text.contains('unterbrochen') || text.contains('schalter'))) {
      return 'circuit';
    }
    if (unit == 'Wasserkreislauf') return 'water';
    if ((unit == 'Zeit und Kalender' || unit == 'Monate und Wochentage') &&
        RegExp('montag|dienstag|mittwoch|donnerstag|freitag|samstag|sonntag|wochentag')
            .hasMatch(text)) {
      return 'week';
    }
    return null;
  }

  @override
  State<InquiryWorkbench> createState() => _InquiryWorkbenchState();
}

class _InquiryWorkbenchState extends State<InquiryWorkbench> {
  bool _closed = false;
  bool _wire = true;
  final _order = <String>[];
  final _crossed = <String>{};
  int _day = 0;
  int _phase = -1;
  static const _days = [
    'Montag',
    'Dienstag',
    'Mittwoch',
    'Donnerstag',
    'Freitag',
    'Samstag',
    'Sonntag'
  ];

  @override
  Widget build(BuildContext context) {
    final kind = InquiryWorkbench.kindFor(widget.task);
    final content = <Widget>[];
    switch (kind) {
      case 'rules':
        final rules = widget.task.prompt
            .split(':')
            .last
            .replaceAll('?', '')
            .trim()
            .split(RegExp(r',\s*| und '));
        content.addAll([
          const Text(
              'Welche Zahl hält allen Regeln stand? Streiche Gegenbeispiele selbst aus.'),
          for (final rule in rules)
            Row(children: [
              const Icon(Icons.rule, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text(rule))
            ]),
          Wrap(spacing: 6, children: [
            for (final option in widget.task.options)
              FilterChip(
                  label: Text(option.label,
                      style: TextStyle(
                          decoration: _crossed.contains(option.label)
                              ? TextDecoration.lineThrough
                              : null)),
                  selected: _crossed.contains(option.label),
                  selectedColor: const Color(0xffe5bdb3),
                  checkmarkColor: const Color(0xff713d32),
                  showCheckmark: false,
                  onSelected: widget.enabled
                      ? (selected) => setState(() {
                            if (selected) {
                              _crossed.add(option.label);
                            } else {
                              _crossed.remove(option.label);
                            }
                          })
                      : null),
          ]),
        ]);
      case 'lineup':
        content.addAll([
          const Text(
              'Stelle die Kinder von links nach rechts auf. Prüfe jeden Hinweis.'),
          Wrap(spacing: 6, children: [
            for (final option in widget.task.options)
              ActionChip(
                  label: Text(option.label),
                  onPressed: widget.enabled && !_order.contains(option.label)
                      ? () => setState(() => _order.add(option.label))
                      : null)
          ]),
          Wrap(spacing: 6, runSpacing: 5, children: [
            for (var i = 0; i < widget.task.options.length; i++)
              InputChip(
                  key: ValueKey('lineup-slot-$i'),
                  label: Text(i < _order.length
                      ? '${i + 1} · ${_order[i]}'
                      : '${i + 1} · …'),
                  onDeleted: widget.enabled && i < _order.length
                      ? () => setState(() => _order.removeAt(i))
                      : null),
          ]),
        ]);
      case 'circuit':
        final on = _closed && _wire;
        content.addAll([
          const Text(
              'Wann leuchtet die Lampe? Verändere zuerst nur eine Sache.'),
          SizedBox(
              height: 106,
              width: double.infinity,
              child: CustomPaint(
                painter: _CircuitPainter(_closed, _wire),
                child: Align(
                    alignment: const Alignment(.7, 0),
                    child: Icon(on ? Icons.lightbulb : Icons.lightbulb_outline,
                        size: 42,
                        semanticLabel: on ? 'Lampe leuchtet' : 'Lampe aus',
                        color: on ? Colors.amber : const Color(0xffb4c8dd))),
              )),
          Wrap(spacing: 8, children: [
            FilterChip(
                key: const ValueKey('circuit-switch'),
                label: const Text('Schalter zu'),
                selected: _closed,
                onSelected:
                    widget.enabled ? (v) => setState(() => _closed = v) : null),
            FilterChip(
                key: const ValueKey('circuit-wire'),
                label: const Text('Kabel verbunden'),
                selected: _wire,
                onSelected:
                    widget.enabled ? (v) => setState(() => _wire = v) : null),
          ]),
        ]);
      case 'water':
        const states = [
          (
            Icons.water_rounded,
            'Wasser im See',
            'Wärme kann Wasser verdunsten lassen.'
          ),
          (
            Icons.waves_rounded,
            'Wasserdampf in der Luft',
            'Wasserdampf ist unsichtbar. Beim Abkühlen können Tröpfchen entstehen.'
          ),
          (
            Icons.cloud_rounded,
            'Tröpfchen in der Wolke',
            'Viele kleine Tröpfchen bilden eine Wolke. Größere Tropfen fallen als Regen.'
          ),
          (
            Icons.water_drop_rounded,
            'Niederschlag',
            'Regenwasser kann versickern oder über Bäche und Flüsse zurück in Seen fließen.'
          ),
        ];
        content.addAll([
          const Text(
              'Verfolge einen Tropfen. Was kann als Nächstes passieren?'),
          Wrap(spacing: 8, children: [
            for (var i = 0; i < states.length; i++)
              IconButton.filledTonal(
                  tooltip: states[i].$2,
                  icon: Icon(states[i].$1),
                  isSelected: _phase == i,
                  onPressed:
                      widget.enabled ? () => setState(() => _phase = i) : null)
          ]),
          if (_phase >= 0)
            Text(states[_phase].$2,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          if (_phase >= 0) Text(states[_phase].$3),
        ]);
      case 'week':
        content.addAll([
          const Text('Fahre auf dem Wochenband einen Tag vor oder zurück.'),
          Wrap(spacing: 4, children: [
            for (var i = 0; i < _days.length; i++)
              ChoiceChip(
                  label: Text(_days[i].substring(0, 2)),
                  tooltip: _days[i],
                  selected: _day == i,
                  onSelected:
                      widget.enabled ? (_) => setState(() => _day = i) : null)
          ]),
          Row(children: [
            IconButton(
                tooltip: 'Einen Tag zurück',
                icon: const Icon(Icons.chevron_left),
                onPressed: widget.enabled
                    ? () => setState(() => _day = (_day + 6) % 7)
                    : null),
            Expanded(child: Text(_days[_day], textAlign: TextAlign.center)),
            IconButton(
                tooltip: 'Einen Tag vor',
                icon: const Icon(Icons.chevron_right),
                onPressed: widget.enabled
                    ? () => setState(() => _day = (_day + 1) % 7)
                    : null),
          ]),
        ]);
      default:
        return const SizedBox.shrink();
    }
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xffe7f5f0)),
      padding: const EdgeInsets.all(14),
      child: DefaultTextStyle(
          style: const TextStyle(
              fontFamily: 'Nunito',
              color: Color(0xff143d40),
              fontSize: 15,
              height: 1.35),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final item in content)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3), child: item)
          ])),
    );
  }
}

class _CircuitPainter extends CustomPainter {
  const _CircuitPainter(this.closed, this.wire);
  final bool closed;
  final bool wire;
  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = const Color(0xff237a78)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final x = size.width * .16,
        far = size.width * .85,
        a = size.width * .38,
        b = size.width * .63;
    final top = 15.0, bottom = size.height - 12, mid = size.height * .5;
    void line(double x1, double y1, double x2, double y2) =>
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), pen);
    line(x, mid - 5, x, top);
    line(x, top, a, top);
    line(a, top, b, closed ? top : top - 12);
    line(b, top, far, top);
    line(far, top, far, mid - 20);
    line(far, mid + 20, far, bottom);
    line(far, bottom, wire ? x : b, bottom);
    if (!wire) line(x, bottom, a, bottom);
    line(x, bottom, x, mid + 5);
    line(x - 12, mid - 5, x + 12, mid - 5);
    line(x - 6, mid + 5, x + 6, mid + 5);
    for (final point in [Offset(a, top), Offset(b, top)]) {
      canvas.drawCircle(point, 4, pen);
    }
  }

  @override
  bool shouldRepaint(_CircuitPainter old) =>
      old.closed != closed || old.wire != wire;
}
