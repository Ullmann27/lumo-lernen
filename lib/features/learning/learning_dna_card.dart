import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../domain/learning/learning_dna.dart';
import '../../widgets/fox/lumo_idle_fox.dart';

/// Eltern-Karte: vollstaendige Lern-DNA mit allen Feldern.
class LearningDnaParentCard extends StatelessWidget {
  const LearningDnaParentCard({super.key, required this.dna});

  final LearningDna dna;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: const Color(0xFFD8B4FE), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.15),
            blurRadius: 18,
            offset: const Offset(0, 6),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 14),
          _recentProgressBlock(),
          if (dna.strengths.isNotEmpty) ...[
            const SizedBox(height: 14),
            _strengthsBlock(),
          ],
          if (dna.weaknesses.isNotEmpty) ...[
            const SizedBox(height: 14),
            _weaknessesBlock(),
          ],
          if (dna.errorBreakdown.isNotEmpty) ...[
            const SizedBox(height: 14),
            _errorBreakdownBlock(),
          ],
          const SizedBox(height: 14),
          _preferredTaskBlock(),
          if (dna.frustrationSignals.isNotEmpty) ...[
            const SizedBox(height: 14),
            _frustrationBlock(),
          ],
          if (dna.nextRecommendation != null) ...[
            const SizedBox(height: 14),
            _recommendationBlock(),
          ],
          if (dna.nextRubric.isNotEmpty) ...[
            const SizedBox(height: 14),
            _nextRubricBlock(),
          ],
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Text('🧬', style: TextStyle(fontSize: 24)),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lumo Lern-DNA',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF581C87),
                ),
              ),
              Text(
                'Was Lumo bisher über das Lernen weiß',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _recentProgressBlock() {
    return _SectionBox(
      title: 'Letzter Fortschritt',
      emoji: '📈',
      child: Text(
        dna.recentProgress,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: LumoColors.ink700,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _strengthsBlock() {
    return _SectionBox(
      title: 'Stärken',
      emoji: '💪',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: dna.strengths.map((s) => _skillRow(s, positive: true)).toList(),
      ),
    );
  }

  Widget _weaknessesBlock() {
    return _SectionBox(
      title: 'Schwächen',
      emoji: '🎯',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: dna.weaknesses.map((s) => _skillRow(s, positive: false)).toList(),
      ),
    );
  }

  Widget _skillRow(DnaSkillEntry entry, {required bool positive}) {
    final color = positive ? const Color(0xFF10B981) : const Color(0xFFEA580C);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              entry.subject,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.skillLabel,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: LumoColors.ink700,
              ),
            ),
          ),
          Container(
            width: 60,
            height: 6,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(99),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: entry.score.clamp(0.05, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBreakdownBlock() {
    final entries = dna.errorBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return _SectionBox(
      title: 'Fehlerarten',
      emoji: '🔍',
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: entries.take(6).map((e) => _errorChip(e.key, e.value)).toList(),
      ),
    );
  }

  Widget _errorChip(String key, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFFFCD34D), width: 1),
      ),
      child: Text(
        '$key  $count×',
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF92400E),
        ),
      ),
    );
  }

  Widget _preferredTaskBlock() {
    return _SectionBox(
      title: 'Bevorzugte Aufgabenart',
      emoji: dna.preferredTaskType.emoji,
      child: Text(
        dna.preferredTaskType.germanLabel,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: LumoColors.ink700,
        ),
      ),
    );
  }

  Widget _frustrationBlock() {
    return _SectionBox(
      title: 'Frustrations-Signale',
      emoji: '⚠️',
      tintColor: const Color(0xFFFEE2E2),
      borderColor: const Color(0xFFFCA5A5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: dna.frustrationSignals.map((s) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              s.message,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB91C1C),
                height: 1.4,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _recommendationBlock() {
    final rec = dna.nextRecommendation!;
    return _SectionBox(
      title: 'Lumo empfiehlt',
      emoji: '✨',
      tintColor: const Color(0xFFDCFCE7),
      borderColor: const Color(0xFF6EE7B7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rec.title,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF064E3B),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            rec.reason,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF065F46),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  rec.priority.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                rec.subject,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF065F46),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nextRubricBlock() {
    return _SectionBox(
      title: 'Nächste Rubrik',
      emoji: '📍',
      child: Text(
        dna.nextRubric,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: LumoColors.ink700,
        ),
      ),
    );
  }
}

class _SectionBox extends StatelessWidget {
  const _SectionBox({
    required this.title,
    required this.emoji,
    required this.child,
    this.tintColor,
    this.borderColor,
  });
  final String title;
  final String emoji;
  final Widget child;
  final Color? tintColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tintColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor ?? const Color(0xFFE9D5FF),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF6D28D9),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

/// Kindgerechte Kurz-Version der Lern-DNA.
/// Drei Zeilen, viel Emoji, positives Framing.
class LearningDnaChildCard extends StatelessWidget {
  const LearningDnaChildCard({super.key, required this.dna});

  final LearningDna dna;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7E6), Color(0xFFFFEFCC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: LumoColors.orange.withOpacity(0.35), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: LumoColors.orange.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const LumoIdleFox(size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  dna.childHeadline,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _kidLine(emoji: '⭐', text: 'Du hast schon ${dna.totalCorrect} Aufgaben richtig!'),
          if (dna.nextRubric.isNotEmpty)
            _kidLine(emoji: '🎯', text: 'Heute üben wir: ${dna.nextRubric}'),
          if (dna.frustrationSignals.isNotEmpty)
            _kidLine(emoji: '🌟', text: 'Lumo ist sehr stolz auf dich. Schritt für Schritt!'),
        ],
      ),
    );
  }

  Widget _kidLine({required String emoji, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF78350F),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
