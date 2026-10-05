import 'package:flutter/material.dart';

import '../../domain/school/attempt.dart';
import '../../domain/school/learning_analysis.dart';
import '../../theme/lumo_visual_tokens.dart';

/// Lernbericht zu einem Kind: Kompetenzen, Stärken, Schwächen, Verlauf und
/// zuletzt gemachte Fehler. Liest nur den übergebenen Datensatz; dieselbe
/// Ansicht dient später der Lehrkraft für ein einzelnes Kind.
class StudentReportView extends StatelessWidget {
  const StudentReportView({
    super.key,
    required this.analysis,
    required this.attempts,
    this.padding = const EdgeInsets.fromLTRB(14, 8, 14, 28),
  });

  final LearningAnalysis analysis;
  final List<Attempt> attempts;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: padding,
      children: [StudentReportContent(analysis: analysis, attempts: attempts)],
    );
  }
}

/// Inhalt des Berichts als Spalte ohne eigenes Scrollen, damit er auch in
/// einer längeren Seite (Lehrer-Einzelansicht) stehen kann.
class StudentReportContent extends StatelessWidget {
  const StudentReportContent(
      {super.key,
      required this.analysis,
      required this.attempts,
      this.showSuggestion = true});
  final LearningAnalysis analysis;
  final List<Attempt> attempts;

  /// Die Lehrkraft sieht die Empfehlung in einem eigenen Feld mit Knöpfen.
  final bool showSuggestion;

  @override
  Widget build(BuildContext context) {
    if (analysis.totalAttempts == 0) {
      return const _EmptyReport();
    }
    final wrongRecent = attempts.reversed.where((a) => !a.correct).take(6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryRow(analysis: analysis),
        if (showSuggestion && analysis.suggestion != null) ...[
          const SizedBox(height: 12),
          _SuggestionCard(suggestion: analysis.suggestion!),
        ],
        const SizedBox(height: 14),
        _Section(
          title: 'Was Lumo bemerkt hat',
          child: analysis.insights.isEmpty
              ? const _Muted('Noch zu wenig Aufgaben für ein sicheres Urteil. '
                  'Ab fünf Aufgaben je Thema zeigt Lumo hier Stärken und Hilfebedarf.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      for (final i in analysis.insights)
                        _InsightTile(insight: i),
                    ]),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Kompetenzen',
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final s in analysis.stats.reversed) _CompetencyRow(stat: s),
          ]),
        ),
        const SizedBox(height: 12),
        _Section(title: 'Letzte 14 Tage', child: _DayBars(days: analysis.days)),
        if (wrongRecent.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Section(
            title: 'Zuletzt falsch',
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final a in wrongRecent) _WrongTile(attempt: a),
                ]),
          ),
        ],
      ],
    );
  }
}

class _EmptyReport extends StatelessWidget {
  const _EmptyReport();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: _Muted(
              'Noch keine Aufgaben gelöst. Sobald du geübt hast, zeigt dir '
              'Lumo hier, was schon sicher sitzt und wobei du Hilfe brauchst.'),
        ),
      );
}

const _label = TextStyle(
    fontFamily: 'Nunito',
    fontWeight: FontWeight.w900,
    color: LumoVisualTokens.white);

class _Muted extends StatelessWidget {
  const _Muted(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      textAlign: TextAlign.left,
      style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          height: 1.3,
          fontWeight: FontWeight.w700,
          color: Color(0xFFD6E8FF)));
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: const Color(0xD90B2A5C),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x8837D2FD)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: _label.copyWith(fontSize: 17)),
          const SizedBox(height: 10),
          child,
        ]),
      );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.analysis});
  final LearningAnalysis analysis;

  String _last() {
    final t = analysis.lastActivity;
    if (t == null) return '–';
    final now = DateTime.now();
    final days = DateTime(now.year, now.month, now.day)
        .difference(DateTime(t.year, t.month, t.day))
        .inDays;
    if (days == 0) return 'heute';
    if (days == 1) return 'gestern';
    return 'vor $days Tagen';
  }

  @override
  Widget build(BuildContext context) {
    Widget chip(IconData icon, String value, String caption) => Container(
          constraints: const BoxConstraints(minWidth: 96),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xD90B2A5C),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x8837D2FD)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: LumoVisualTokens.cyanBright, size: 22),
            const SizedBox(height: 2),
            Text(value, style: _label.copyWith(fontSize: 20)),
            Text(caption,
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD6E8FF))),
          ]),
        );
    return Wrap(spacing: 10, runSpacing: 10, children: [
      chip(Icons.task_alt_rounded, '${analysis.totalAttempts}', 'Aufgaben'),
      chip(Icons.timer_rounded, '${analysis.totalMinutes} min', 'Lernzeit'),
      chip(Icons.history_rounded, _last(), 'zuletzt geübt'),
    ]);
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion});
  final PracticeSuggestion suggestion;

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('report-suggestion'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
              colors: [Color(0xFF1E7FE0), Color(0xFF0F4DA8)]),
          border: Border.all(color: const Color(0xFFBDF4FF), width: 1.6),
        ),
        child: Row(children: [
          const Icon(Icons.lightbulb_rounded,
              color: LumoVisualTokens.gold, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Text(suggestion.text,
                style: _label.copyWith(fontSize: 15, height: 1.25)),
          ),
        ]),
      );
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({required this.insight});
  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (insight.kind) {
      InsightKind.weakness => (Icons.flag_rounded, const Color(0xFFFFB86B)),
      InsightKind.strength => (Icons.verified_rounded, const Color(0xFF7BE08C)),
      InsightKind.comparison => (
          Icons.compare_arrows_rounded,
          LumoVisualTokens.cyanBright
        ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Expanded(child: _Muted(insight.text)),
      ]),
    );
  }
}

class _CompetencyRow extends StatelessWidget {
  const _CompetencyRow({required this.stat});
  final CompetencyStat stat;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (stat.level) {
      MasteryLevel.secure => ('sicher', const Color(0xFF7BE08C)),
      MasteryLevel.developing => ('wird besser', LumoVisualTokens.gold),
      MasteryLevel.needsHelp => ('braucht Hilfe', const Color(0xFFFFB86B)),
      MasteryLevel.unknown => ('noch offen', const Color(0xFF9DB7DA)),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(stat.competency,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _label.copyWith(fontSize: 14)),
          ),
          const SizedBox(width: 8),
          Text('${stat.percent} %', style: _label.copyWith(fontSize: 14)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: stat.accuracy,
            minHeight: 8,
            color: color,
            backgroundColor: const Color(0x33FFFFFF),
          ),
        ),
        const SizedBox(height: 2),
        Text('$text · ${stat.correct} von ${stat.attempts} richtig',
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color)),
      ]),
    );
  }
}

class _DayBars extends StatelessWidget {
  const _DayBars({required this.days});
  final List<DayCount> days;

  @override
  Widget build(BuildContext context) {
    final maxTotal = days.fold<int>(1, (m, d) => d.total > m ? d.total : m);
    return Semantics(
      label: 'Aufgaben der letzten 14 Tage',
      child: SizedBox(
        height: 84,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (final d in days)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    widthFactor: 1,
                    heightFactor:
                        d.total == 0 ? .04 : (d.total / maxTotal).clamp(.1, 1),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: d.total == 0
                            ? const Color(0x33FFFFFF)
                            : LumoVisualTokens.cyanBright,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

class _WrongTile extends StatelessWidget {
  const _WrongTile({required this.attempt});
  final Attempt attempt;

  @override
  Widget build(BuildContext context) {
    final q = attempt.prompt.isEmpty ? attempt.competency : attempt.prompt;
    final detail = (attempt.given.isEmpty && attempt.expected.isEmpty)
        ? ''
        : 'Deine Antwort: ${attempt.given.isEmpty ? '–' : attempt.given}'
            '  ·  Richtig: ${attempt.expected.isEmpty ? '–' : attempt.expected}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(q,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _label.copyWith(fontSize: 14)),
        if (detail.isNotEmpty)
          Text(detail,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFD6E8FF))),
      ]),
    );
  }
}
