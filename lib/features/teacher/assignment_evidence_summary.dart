import 'package:flutter/material.dart';

import '../../domain/school/school_model.dart';
import '../../theme/lumo_visual_tokens.dart';

/// Read-only result of the same profile-bound responses used for progress.
/// Time spent is never interpreted as mastery or shown as a ranking.
class AssignmentEvidenceSummary extends StatelessWidget {
  const AssignmentEvidenceSummary({super.key, required this.progress});
  final AssignmentProgress progress;

  @override
  Widget build(BuildContext context) {
    if (progress.done == 0) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 6),
        Text(
          '${progress.independentCorrect} von ${progress.independent} '
          'ohne Hilfe richtig · ${progress.guided} mit Hilfe bearbeitet',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            color: Color(0xFFD6E8FF),
          ),
        ),
        if (progress.answers.isNotEmpty)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              key: ValueKey('assignment-evidence-${progress.answers.first.id}'),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              iconColor: LumoVisualTokens.cyanBright,
              collapsedIconColor: LumoVisualTokens.cyanBright,
              title: const Text(
                'Antworten ansehen',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: LumoVisualTokens.cyanBright,
                ),
              ),
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Gezählt werden die ersten Antworten zum Thema seit der '
                    'Zuweisung. Weitere Übungen verändern dieses Ergebnis nicht.',
                    style: TextStyle(color: Color(0xFFD6E8FF), fontSize: 12),
                  ),
                ),
                for (var i = 0; i < progress.answers.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          progress.answers[i].correct
                              ? Icons.check_circle_outline_rounded
                              : Icons.lightbulb_outline_rounded,
                          color: progress.answers[i].correct
                              ? const Color(0xFF7BE08C)
                              : LumoVisualTokens.gold,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                progress.answers[i].prompt.isEmpty
                                    ? 'Aufgabe ${i + 1}: '
                                      '${progress.answers[i].competency}'
                                    : progress.answers[i].prompt,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (progress.answers[i].given.isNotEmpty)
                                Text(
                                  'Antwort: ${progress.answers[i].given}',
                                  style: const TextStyle(
                                      color: Color(0xFFD6E8FF)),
                                ),
                              if (!progress.answers[i].correct &&
                                  progress.answers[i].expected.isNotEmpty)
                                Text(
                                  'Lösung: ${progress.answers[i].expected}',
                                  style: const TextStyle(
                                      color: LumoVisualTokens.gold),
                                ),
                              Text(
                                progress.answers[i].hintUsed
                                    ? 'Mit Unterstützung bearbeitet'
                                    : 'Selbstständig beantwortet',
                                style: const TextStyle(
                                    color: Color(0xFFD6E8FF), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
