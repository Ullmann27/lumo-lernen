import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/school/learning_chart_data.dart';
import '../teacher_demo/holo_widgets.dart';

/// Shared live charts for parents and teachers. Receives only an owner-scoped
/// projection; it has no demo generator, storage writes, or network requests.
class LearningAnalyticsPanel extends StatelessWidget {
  const LearningAnalyticsPanel({super.key, required this.data});

  final LearningChartData data;

  static const _colors = [
    HoloPalette.cyan,
    HoloPalette.amber,
    HoloPalette.violet,
    HoloPalette.mint,
  ];

  @override
  Widget build(BuildContext context) {
    final radar = data.competencies.take(6).toList();
    final subjects = data.subjects.take(_colors.length).toList();
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
            LayoutBuilder(builder: (context, constraints) {
              final radarContent = _radar(radar);
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

  Widget _radar(List<LearningChartCount> entries) {
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
        if (data.competencies.length > entries.length)
          const Text('Angezeigt: die sechs am häufigsten selbstständig geübten Kompetenzen.',
              style: TextStyle(color: HoloPalette.muted, fontSize: 12)),
      ],
    );
  }

  Widget _trend(List<String> subjects) {
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
                painter: _LiveTrendPainter(data, subjects, _colors)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              for (var index = 0; index < subjects.length; index++)
                Text(subjects[index],
                    style: TextStyle(
                        color: _colors[index], fontWeight: FontWeight.w700)),
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
        if (data.subjects.length > subjects.length)
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
