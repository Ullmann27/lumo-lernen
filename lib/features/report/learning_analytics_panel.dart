import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/school/learning_chart_data.dart';
import '../../widgets/design/lumo_subject_style.dart';
import '../teacher_demo/holo_widgets.dart';

/// Shared live charts for parents and teachers. Receives only an owner-scoped
/// projection; it has no demo generator, storage writes, or network requests.
class LearningAnalyticsPanel extends StatefulWidget {
  const LearningAnalyticsPanel({super.key, required this.data});

  final LearningChartData data;

  @override
  State<LearningAnalyticsPanel> createState() => _LearningAnalyticsPanelState();
}

class _LearningAnalyticsPanelState extends State<LearningAnalyticsPanel> {
  String? _subject;
  LearningChartData get data => widget.data;

  @override
  void didUpdateWidget(covariant LearningAnalyticsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.studentId != data.studentId ||
        !data.subjectActivity.any((item) => item.subject == _subject)) {
      _subject = null;
    }
  }

  static const _colors = [
    HoloPalette.cyan,
    HoloPalette.amber,
    HoloPalette.violet,
    HoloPalette.mint,
  ];

  @override
  Widget build(BuildContext context) {
    final selected = _subject;
    final eligible = data.competencies
        .where((item) => selected == null || item.subject == selected)
        .toList();
    final radar = eligible.take(6).toList();
    final subjects = data.subjects
        .where((subject) => selected == null || subject == selected)
        .take(_colors.length).toList();
    final activity = data.subjectActivity
        .where((item) => selected == null || item.subject == selected)
        .toList();
    return HoloPanel(
      key: const ValueKey('live-learning-analytics'),
      shimmer: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Lernanalyse · echte Aufgaben',
              style: TextStyle(
                  color: HoloPalette.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
          const SizedBox(height: 8),
          if (data.total == 0)
            const Text(
              'Noch keine protokollierten Antworten für dieses Kind. '
              'Nach dem Üben erscheinen hier die tatsächlichen Ergebnisse.',
              key: ValueKey('live-learning-empty'),
              style: TextStyle(color: HoloPalette.muted, height: 1.4),
            )
          else ...[
            Text(
              '${data.total} protokollierte Antworten · '
              '${data.independentTotal} ohne Hilfe · '
              '${data.assistedTotal} mit Hilfe',
              key: const ValueKey('live-learning-summary'),
              style: const TextStyle(
                  color: HoloPalette.text, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              data.independentTotal == 0
                  ? 'Noch keine selbstständigen Antworten.'
                  : '${data.independentCorrect} von ${data.independentTotal} '
                      'ohne Hilfe richtig (${(data.accuracy! * 100).round()} %)',
              key: const ValueKey('live-learning-independent-summary'),
              style: const TextStyle(color: HoloPalette.text),
            ),
            const SizedBox(height: 6),
            const Text(
              'Radar und Verlauf nutzen nur Antworten ohne Hilfe. '
              'Aufgaben mit Hilfe bleiben getrennt im Aktivitätszähler. '
              'Zeit und Tempo verändern die Trefferquote nicht. '
              'Kleine Stichproben sind noch keine sichere Kompetenzbewertung.',
              style: TextStyle(
                  color: HoloPalette.muted, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 16),
            const Text('Fach auswählen',
                style: TextStyle(color: HoloPalette.text,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _filterChip(null, 'Alle Fächer'),
                for (final item in data.subjectActivity)
                  _filterChip(item.subject, item.subject),
              ],
            ),
            const SizedBox(height: 16),
            _activityPanel(activity),
            const SizedBox(height: 20),
            LayoutBuilder(builder: (context, constraints) {
              final radarContent = _radar(radar, eligible.length);
              final trendContent = _trend(subjects);
              if (constraints.maxWidth < 660) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    radarContent,
                    const SizedBox(height: 20),
                    trendContent,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: radarContent),
                  const SizedBox(width: 24),
                  Expanded(child: trendContent),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _filterChip(String? subject, String label) {
    final selected = _subject == subject;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
      child: ChoiceChip(
        key: ValueKey('live-subject-filter-${subject ?? 'all'}'),
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _subject = subject),
        materialTapTargetSize: MaterialTapTargetSize.padded,
        showCheckmark: false,
        backgroundColor: HoloPalette.night,
        selectedColor: HoloPalette.cyan,
        labelStyle: TextStyle(
          color: selected ? HoloPalette.deep : HoloPalette.text,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(color: HoloPalette.cyan.withValues(alpha: .65)),
      ),
    );
  }

  /// Einheitliche Fachfarbe (wie Symbole im Eltern- und Lehrkräftebereich).
  Color _subjectColor(String subject) => LumoSubjectStyle.of(subject).color;

  String _percent(double? rate) =>
      rate == null ? 'Keine Messung' : '${(rate * 100).round()} %';

  String _seconds(double milliseconds) =>
      (milliseconds / 1000).toStringAsFixed(1).replaceAll('.', ',');

  Widget _activityPanel(List<LearningSubjectActivity> entries) {
    const body = TextStyle(color: HoloPalette.text, height: 1.4);
    const muted = TextStyle(color: HoloPalette.muted, fontSize: 12, height: 1.4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Genauigkeit, Hilfen und Bearbeitungszeit',
            style: TextStyle(color: HoloPalette.text, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        for (final entry in entries)
          Padding(
            key: ValueKey('live-subject-activity-${entry.subject}'),
            padding: const EdgeInsets.only(bottom: 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: HoloPalette.night.withValues(alpha: .75),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _subjectColor(entry.subject)
                    .withValues(alpha: .35)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      LumoSubjectBadge(subject: entry.subject, size: 30),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(entry.subject, style: body.copyWith(
                            color: _subjectColor(entry.subject),
                            fontWeight: FontWeight.w800)),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Text(entry.independent == 0
                        ? 'Noch keine Antworten ohne Hilfe'
                        : 'Ohne Hilfe richtig: ${entry.independentCorrect}/${entry.independent} '
                          '(${_percent(entry.independentAccuracy)})', style: body),
                    if (entry.independentAccuracy != null) ...[
                      const SizedBox(height: 5),
                      LinearProgressIndicator(
                        value: entry.independentAccuracy,
                        minHeight: 8,
                        color: _subjectColor(entry.subject),
                        backgroundColor: HoloPalette.deep,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Hilfenutzung ist keine Kompetenzangabe: als Anzahl
                    // formuliert, damit kein Prozentwert als Leistung gelesen wird.
                    Text('Hilfe genutzt bei ${entry.assisted} von '
                        '${entry.total} Antworten', style: body),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(
                      value: entry.helpRate,
                      minHeight: 6,
                      color: HoloPalette.violet,
                      backgroundColor: HoloPalette.deep,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 8),
                    Text(entry.medianIndependentMs == null
                        ? 'Bearbeitungszeit: keine erfasste Zeit ohne Hilfe'
                        : 'Bearbeitungszeit (Median): ${_seconds(entry.medianIndependentMs!)} s '
                          '· ${entry.timedIndependent} von ${entry.independent} '
                          'Antworten ohne Hilfe mit Zeitmessung', style: muted),
                  ],
                ),
              ),
            ),
          ),
        const Text('Aktivität aus dem vorhandenen Aufgabenprotokoll. '
            'Hilfenutzung ist kein Fehler. Zeitwerte dienen nur der Orientierung '
            'und verändern weder Trefferquote noch Förderempfehlung.',
            style: muted),
      ],
    );
  }

  Widget _radar(List<LearningChartCount> entries, int eligibleCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Kompetenz-Radar · ohne Hilfe',
            style: TextStyle(
                color: HoloPalette.text, fontWeight: FontWeight.w800)),
        if (entries.length >= 3)
          Semantics(
            label: 'Kompetenz-Radar ohne Hilfe. Skala null bis hundert Prozent. '
                '${entries.map((entry) => '${entry.subject}, '
                    '${entry.competency}: ${entry.correct} von '
                    '${entry.total} Antworten ohne Hilfe richtig').join('. ')}',
            child: SizedBox(
              height: 210,
              child: CustomPaint(painter: _LiveRadarPainter(entries)),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              entries.isEmpty
                  ? 'Für das Kompetenz-Radar fehlen noch selbstständig beantwortete Aufgaben.'
                  : 'Für ein Radar sind drei selbstständig geübte Kompetenzen nötig. '
                      'Die vorhandenen Ergebnisse stehen bereits hier.',
              style: const TextStyle(color: HoloPalette.muted, fontSize: 12),
            ),
          ),
        for (var index = 0; index < entries.length; index++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '${index + 1}. ${entries[index].subject} · '
              '${entries[index].competency}\n'
              '${entries[index].correct} von ${entries[index].total} ohne Hilfe richtig '
              '(${(entries[index].accuracy * 100).round()} %)'
              '${entries[index].hasEnoughEvidence ? '' : ' · kleine Stichprobe'}',
              style: const TextStyle(color: HoloPalette.text, height: 1.35),
            ),
          ),
        if (eligibleCount > entries.length)
          const Text('Angezeigt: die sechs am häufigsten selbstständig geübten Kompetenzen.',
              style: TextStyle(color: HoloPalette.muted, fontSize: 12)),
      ],
    );
  }

  Widget _trend(List<String> subjects) {
    final colors = subjects.map(_subjectColor).toList(growable: false);
    final hasRecentData = data.weeks.any((week) =>
        subjects.any((subject) => week.subjects.containsKey(subject)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Lernverlauf ohne Hilfe · letzte 28 Tage',
            style: TextStyle(
                color: HoloPalette.text, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (!hasRecentData)
          const Text('In diesem Zeitraum sind keine Antworten ohne Hilfe protokolliert.',
              style: TextStyle(color: HoloPalette.muted))
        else ...[
          SizedBox(
            height: 180,
            child: CustomPaint(
                painter: _LiveTrendPainter(data, subjects, colors)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              for (var index = 0; index < subjects.length; index++)
                Text(subjects[index],
                    style: TextStyle(
                        color: colors[index], fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          for (final week in data.weeks)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '${_date(week.start)}–'
                '${_date(DateTime(week.endExclusive.year, week.endExclusive.month, week.endExclusive.day - 1))}: '
                '${subjects.map((subject) {
                  final count = week.subjects[subject];
                  return count == null
                      ? '$subject: keine Antworten ohne Hilfe'
                      : '$subject: ${count.correct}/${count.total} ohne Hilfe richtig';
                }).join(' · ')}',
                style: const TextStyle(
                    color: HoloPalette.muted, fontSize: 12, height: 1.4),
              ),
            ),
        ],
        const SizedBox(height: 6),
        const Text(
          'Die Kurven zeigen selbstständige Trefferquoten je Siebentagesabschnitt. '
          'Lücken bleiben offen; fehlende Antworten ohne Hilfe werden nicht als 0 % gewertet. '
          'Unterschiedlich schwierige Aufgaben sind nicht direkt vergleichbar.',
          style:
              TextStyle(color: HoloPalette.muted, fontSize: 12, height: 1.4),
        ),
        if (_subject == null && data.subjects.length > subjects.length)
          const Text('Angezeigt: die vier in diesem Zeitraum am häufigsten selbstständig geübten Fächer.',
              style: TextStyle(color: HoloPalette.muted, fontSize: 12)),
      ],
    );
  }
}

String _date(DateTime date) => '${date.day}.${date.month}.';

void _paintLabel(Canvas canvas, String text, Offset center,
    {Color color = HoloPalette.muted}) {
  final painter = TextPainter(
    text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(
      canvas, center - Offset(painter.width / 2, painter.height / 2));
}

class _LiveRadarPainter extends CustomPainter {
  _LiveRadarPainter(this.entries);
  final List<LearningChartCount> entries;

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.length < 3 || size.shortestSide <= 56) return;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 28;
    Offset at(int index, double value) {
      final angle = -math.pi / 2 + math.pi * 2 * index / entries.length;
      return center + Offset(math.cos(angle), math.sin(angle)) * radius * value;
    }

    final grid = Paint()
      ..color = HoloPalette.cyan.withValues(alpha: .2)
      ..style = PaintingStyle.stroke;
    for (final level in [.25, .5, .75, 1.0]) {
      final path = Path();
      for (var index = 0; index < entries.length; index++) {
        final point = at(index, level);
        if (index == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path..close(), grid);
    }
    final shape = Path();
    for (var index = 0; index < entries.length; index++) {
      canvas.drawLine(center, at(index, 1), grid);
      _paintLabel(canvas, '${index + 1}', at(index, 1.2));
      final point = at(index, entries[index].accuracy);
      if (index == 0) {
        shape.moveTo(point.dx, point.dy);
      } else {
        shape.lineTo(point.dx, point.dy);
      }
    }
    shape.close();
    canvas.drawPath(
        shape, Paint()..color = HoloPalette.cyan.withValues(alpha: .18));
    canvas.drawPath(
        shape,
        Paint()
          ..color = HoloPalette.cyan
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    _paintLabel(canvas, '0–100 %',
        Offset(size.width - 32, size.height - 10));
  }

  @override
  bool shouldRepaint(_LiveRadarPainter oldDelegate) =>
      oldDelegate.entries != entries;
}

class _LiveTrendPainter extends CustomPainter {
  _LiveTrendPainter(this.data, this.subjects, this.colors);
  final LearningChartData data;
  final List<String> subjects;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 80 || size.height <= 50) return;
    const left = 38.0;
    final width = size.width - left - 22;
    final height = size.height - 34;
    double x(int index) => left + width * index / 3;
    double y(double value) => 6 + height * (1 - value);
    final grid = Paint()..color = HoloPalette.cyan.withValues(alpha: .15);
    for (final value in [0.0, .5, 1.0]) {
      canvas.drawLine(Offset(left, y(value)),
          Offset(left + width, y(value)), grid);
      _paintLabel(canvas, '${(value * 100).round()} %', Offset(16, y(value)));
    }
    for (var index = 0; index < 4; index++) {
      _paintLabel(canvas, _date(data.weeks[index].start),
          Offset(x(index), size.height - 8));
    }
    for (var subjectIndex = 0; subjectIndex < subjects.length; subjectIndex++) {
      final color = colors[subjectIndex];
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2;
      Offset? previous;
      for (var index = 0; index < data.weeks.length; index++) {
        final value = data.weeks[index].accuracyFor(subjects[subjectIndex]);
        if (value == null) {
          previous = null;
          continue;
        }
        final point = Offset(x(index), y(value));
        if (previous != null) canvas.drawLine(previous, point, paint);
        canvas.drawCircle(point, 3.5, paint);
        previous = point;
      }
    }
  }

  @override
  bool shouldRepaint(_LiveTrendPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.subjects != subjects;
}
