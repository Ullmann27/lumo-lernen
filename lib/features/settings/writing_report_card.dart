// ════════════════════════════════════════════════════════════════════════
// WRITING REPORT CARD — Phase 6b vom Schreibcoach-Plan
// ════════════════════════════════════════════════════════════════════════
// Zeigt im Elternbereich, was Lumo aus den Schreibversuchen gelernt hat:
//   - wie viele Buchstaben/Woerter geuebt wurden,
//   - welche Buchstaben Foerderbedarf haben,
//   - welche Woerter im Diktat geschafft wurden,
//   - eine kurze, freundliche Lumo-Empfehlung.
//
// Klein gehalten: lokale FutureBuilder-Karte, kein neuer Engine,
// keine Architektur-Aenderung. Daten kommen direkt aus
// WritingProgressRepository (Phase 6).
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/writing_progress_repository.dart';
import '../../domain/writing/writing_progress.dart';
import '../writing/writing_feature_flags.dart';

class WritingReportCard extends StatefulWidget {
  const WritingReportCard({super.key});

  @override
  State<WritingReportCard> createState() => _WritingReportCardState();
}

class _WritingReportCardState extends State<WritingReportCard> {
  final _repo = WritingProgressRepository();
  late Future<WritingProgress> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.load();
  }

  Future<void> _refresh() async {
    final next = _repo.load();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    if (!WritingFeatureFlags.enableProgressTracking) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<WritingProgress>(
      future: _future,
      builder: (context, snap) {
        final progress = snap.data ?? WritingProgress.empty;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: lumoCard(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFFAF5FF)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(progress),
              const SizedBox(height: 12),
              if (snap.connectionState == ConnectionState.waiting)
                _waiting()
              else if (progress.totalAttempts == 0)
                _emptyState()
              else
                _content(progress),
            ],
          ),
        );
      },
    );
  }

  Widget _header(WritingProgress progress) {
    return Row(children: [
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFEDE9FE),
          borderRadius: BorderRadius.circular(LumoRadius.lg),
        ),
        child: const Center(child: Text('✏️', style: TextStyle(fontSize: 28))),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Schreibcoach – Übungsstand',
                style:
                    LumoTextStyles.heading2.copyWith(color: LumoColors.ink900)),
            const SizedBox(height: 4),
            Text(
              progress.lastPracticedAt == null
                  ? 'Noch keine Übung gespeichert'
                  : 'Zuletzt geübt: ${_date(progress.lastPracticedAt!)}',
              style: LumoTextStyles.caption.copyWith(color: LumoColors.ink600),
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Aktualisieren',
        icon:
            Icon(Icons.refresh_rounded, color: LumoColors.ink600, size: 22),
        onPressed: _refresh,
      ),
    ]);
  }

  Widget _waiting() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('Lade Übungsdaten …',
            style: LumoTextStyles.body.copyWith(color: LumoColors.ink600)),
      );

  Widget _emptyState() => Text(
        'Lumo wartet auf die ersten Schreibversuche. Sobald dein Kind im Schreibcoach oder im Wortdiktat übt, erscheinen hier Stärken und Förderbedarf.',
        style: LumoTextStyles.body.copyWith(color: LumoColors.ink700),
      );

  Widget _content(WritingProgress progress) {
    final practiced = progress.practicedLetters.length;
    final weak = progress.weakLetters;
    final words = progress.completedWords.toList()..sort();
    final accuracyPct = (progress.overallAccuracy * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          _statChip('Geübt', '$practiced Buchstaben', const Color(0xFF8B5CF6)),
          _statChip('Versuche', '${progress.totalAttempts}',
              const Color(0xFF6366F1)),
          _statChip('Treffer', '$accuracyPct %', const Color(0xFF10B981)),
          if (words.isNotEmpty)
            _statChip('Wörter', '${words.length}', const Color(0xFFFCD34D),
                ink: const Color(0xFF92400E)),
        ]),
        const SizedBox(height: 14),
        if (weak.isNotEmpty) ...[
          Text('Förderbedarf',
              style:
                  LumoTextStyles.label.copyWith(color: LumoColors.orange)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: weak
                .take(8)
                .map((l) => _letterPill(l, accent: const Color(0xFFEA580C)))
                .toList(),
          ),
          const SizedBox(height: 12),
        ],
        if (words.isNotEmpty) ...[
          Text('Geschafft im Diktat',
              style: LumoTextStyles.label.copyWith(color: LumoColors.teal)),
          const SizedBox(height: 4),
          Text(
            _formatWords(words.take(8).toList()),
            style: LumoTextStyles.body.copyWith(color: LumoColors.ink700),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(LumoRadius.md),
            border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('🦊', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _recommendation(progress, weak),
                style: LumoTextStyles.body.copyWith(
                    color: LumoColors.ink900, fontWeight: FontWeight.w700),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _statChip(String label, String value, Color color, {Color? ink}) {
    final textColor = ink ?? color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label,
            style: LumoTextStyles.caption.copyWith(
                color: textColor, fontWeight: FontWeight.w700)),
        const SizedBox(width: 6),
        Text(value,
            style: LumoTextStyles.caption.copyWith(
                color: textColor, fontWeight: FontWeight.w900)),
      ]),
    );
  }

  Widget _letterPill(String letter, {required Color accent}) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withOpacity(0.45)),
      ),
      child: Text(letter,
          style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: accent)),
    );
  }

  String _formatWords(List<String> words) {
    if (words.isEmpty) return '–';
    return words
        .map((w) => w.length <= 1
            ? w
            : '${w[0]}${w.substring(1).toLowerCase()}')
        .join(', ');
  }

  String _recommendation(WritingProgress progress, List<String> weak) {
    if (weak.isEmpty && progress.completedWords.isEmpty) {
      return 'Schöner Start! Lumo schlägt vor: gleich noch ein paar Buchstaben üben, dann das Wortdiktat probieren.';
    }
    if (weak.isEmpty) {
      return 'Lumo sagt: läuft super! Heute ruhig ein neues Wort im Diktat probieren.';
    }
    final pick = weak.take(2).toList();
    final letters = pick.length == 1
        ? pick.first
        : '${pick.first} und ${pick.last}';
    return 'Lumo empfiehlt: Diese Woche $letters noch einmal üben.';
  }

  String _date(DateTime v) {
    final d = v.day.toString().padLeft(2, '0');
    final m = v.month.toString().padLeft(2, '0');
    return '$d.$m.${v.year}';
  }
}
