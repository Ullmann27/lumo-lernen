// ════════════════════════════════════════════════════════════════════════
// LUMO INSIGHT HEATMAP — visuelles Kompetenz-Raster fuer Eltern.
// ════════════════════════════════════════════════════════════════════════
// Heinz 2026-06-03: "echtes neues Level gegenueber LernMax". LernMax verkauft
// Kimaro (AI-Tutor) fuer 95€/Jahr als textuelles Report-Tool. Lumo zeigt
// stattdessen eine SOFORT erfassbare Heatmap-Matrix:
//   - Zeilen = Schulfach (Mathe, Deutsch, Sachunterricht, ...)
//   - Spalten = Kompetenzen ('Plus bis 10', 'Reime', ...)
//   - Farbe = Score (rot=schwach, gelb=mittel, gruen=stark, grau=neu)
// Confidence wirkt als Saettigung: niedrige Sicherheit -> blasser, hohe -> kraeftig.
//
// Datenquelle: DnaSkillEntry-Liste aus LearningDnaEngine.

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../domain/learning/learning_dna.dart';

class LumoInsightHeatmap extends StatelessWidget {
  const LumoInsightHeatmap({
    super.key,
    required this.entries,
    this.onCellTap,
  });

  final List<DnaSkillEntry> entries;
  final void Function(DnaSkillEntry entry)? onCellTap;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return _emptyState();
    }
    final bySubject = <String, List<DnaSkillEntry>>{};
    for (final e in entries) {
      bySubject.putIfAbsent(e.subject, () => <DnaSkillEntry>[]).add(e);
    }
    final subjects = bySubject.keys.toList()..sort();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBF0), Color(0xFFFFF6E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: LumoColors.orange.withOpacity(0.28), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: LumoColors.orange.withOpacity(0.14),
            blurRadius: 18,
            offset: const Offset(0, 6),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Header(),
          const SizedBox(height: 12),
          for (final subject in subjects) ...[
            _SubjectRow(
              subject: subject,
              entries: bySubject[subject]!,
              onTap: onCellTap,
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          const _Legend(),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: LumoColors.orange.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          const Text('🦊', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Noch keine Daten',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF7C2D12),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Sobald dein Kind ein paar Aufgaben loest, fuelle ich diese\nKompetenz-Karte automatisch mit echten Daten.',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF92400E),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF7A2F), Color(0xFFFFB96B)],
            ),
            borderRadius: BorderRadius.circular(LumoRadius.pill),
          ),
          child: const Text(
            '🦊 LUMO INSIGHT',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Kompetenz-Karte',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF7C2D12),
            ),
          ),
        ),
      ],
    );
  }
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({
    required this.subject,
    required this.entries,
    this.onTap,
  });

  final String subject;
  final List<DnaSkillEntry> entries;
  final void Function(DnaSkillEntry entry)? onTap;

  static const _subjectIcons = <String, String>{
    'Mathe': '🧮',
    'Mathematik': '🧮',
    'Deutsch': '📖',
    'Sachunterricht': '🌍',
    'Englisch': '🇬🇧',
    'Rechtschreibung': '✏️',
    'Schreiben': '✍️',
    'Lesen': '👀',
  };

  @override
  Widget build(BuildContext context) {
    final icon = _subjectIcons[subject] ?? '📚';
    final sorted = [...entries]..sort((a, b) => a.skillLabel.compareTo(b.skillLabel));
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LumoRadius.md),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                subject,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF7C2D12),
                ),
              ),
              const Spacer(),
              Text(
                '${sorted.length} ${sorted.length == 1 ? "Kompetenz" : "Kompetenzen"}',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF7C2D12).withOpacity(0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in sorted)
                _Cell(entry: e, onTap: onTap),
            ],
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.entry, this.onTap});
  final DnaSkillEntry entry;
  final void Function(DnaSkillEntry)? onTap;

  /// Score 0..1 + Confidence 0..1 -> Farbe + Saettigung.
  ///   score < 0.45 -> rot
  ///   0.45..0.70   -> gelb
  ///   > 0.70       -> gruen
  /// Niedrige Confidence (<0.3) -> grau-blass (zu wenig Daten).
  Color _cellColor() {
    if (entry.confidence < 0.30) return const Color(0xFFF3F4F6);
    if (entry.score < 0.45) return const Color(0xFFFCA5A5);
    if (entry.score < 0.70) return const Color(0xFFFCD34D);
    return const Color(0xFF86EFAC);
  }

  Color _borderColor() {
    if (entry.confidence < 0.30) return const Color(0xFFD1D5DB);
    if (entry.score < 0.45) return const Color(0xFFDC2626);
    if (entry.score < 0.70) return const Color(0xFFCA8A04);
    return const Color(0xFF15803D);
  }

  @override
  Widget build(BuildContext context) {
    final percent = (entry.score * 100).round();
    final showPercent = entry.confidence >= 0.30;
    return GestureDetector(
      onTap: onTap == null ? null : () => onTap!(entry),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: _cellColor(),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _borderColor(), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              entry.skillLabel,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _borderColor(),
              ),
            ),
            if (showPercent) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.80),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$percent%',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: _borderColor(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _legendDot(const Color(0xFFFCA5A5), 'Schwach'),
        const SizedBox(width: 10),
        _legendDot(const Color(0xFFFCD34D), 'Im Aufbau'),
        const SizedBox(width: 10),
        _legendDot(const Color(0xFF86EFAC), 'Sicher'),
        const SizedBox(width: 10),
        _legendDot(const Color(0xFFF3F4F6), 'Noch zu wenig Daten'),
      ],
    );
  }

  Widget _legendDot(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black12, width: 0.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF7C2D12),
          ),
        ),
      ],
    );
  }
}
