import 'package:flutter/material.dart';

import '../../../theme/lumo_visual_tokens.dart';

/// Die Abschnitte einer Nachhilfestunde mit Lumo.
enum LumoTutoringPhase {
  warmUp('Aufwärmen', Icons.wb_sunny_outlined),
  explain('Erklären', Icons.lightbulb_outline_rounded),
  together('Gemeinsam üben', Icons.groups_2_outlined),
  alone('Allein üben', Icons.emoji_people_rounded),
  review('Rückblick', Icons.flag_outlined);

  const LumoTutoringPhase(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Ablauf wie bei einer Nachhilfelehrerin: zwei Aufgaben zum Aufwärmen, dann
/// erklärt Lumo das Thema, dann üben beide zusammen, dann das Kind allein.
class LumoTutoringHourPlan {
  const LumoTutoringHourPlan._();

  static const warmUpTasks = 2;
  static const togetherTasks = 3;

  /// Abschnitt für die Aufgabe [questionNum] (ab 1).
  static LumoTutoringPhase phaseFor(int questionNum,
      {required bool explained, bool finished = false}) {
    if (finished) return LumoTutoringPhase.review;
    if (questionNum <= warmUpTasks) return LumoTutoringPhase.warmUp;
    if (!explained) return LumoTutoringPhase.explain;
    if (questionNum <= warmUpTasks + togetherTasks) {
      return LumoTutoringPhase.together;
    }
    return LumoTutoringPhase.alone;
  }

  /// Was Lumo zu Beginn eines Abschnitts sagt.
  static String introFor(LumoTutoringPhase phase, String unit) =>
      switch (phase) {
        LumoTutoringPhase.warmUp =>
          'Wir wärmen uns mit zwei Aufgaben auf. Ganz in Ruhe.',
        LumoTutoringPhase.explain =>
          'Jetzt erkläre ich dir $unit Schritt für Schritt.',
        LumoTutoringPhase.together =>
          'Jetzt üben wir zusammen. Ich zeige dir, worauf es ankommt.',
        LumoTutoringPhase.alone =>
          'Jetzt probierst du es allein. Ich schaue nur zu.',
        LumoTutoringPhase.review => 'Schauen wir, was du heute geschafft hast.',
      };
}

/// Leiste mit den fünf Abschnitten der Stunde.
class LumoTutoringPhaseBar extends StatelessWidget {
  const LumoTutoringPhaseBar({super.key, required this.phase});
  final LumoTutoringPhase phase;

  @override
  Widget build(BuildContext context) {
    final current = phase.index;
    return Semantics(
      label: 'Nachhilfestunde, Abschnitt ${current + 1} von '
          '${LumoTutoringPhase.values.length}: ${phase.label}',
      excludeSemantics: true,
      child: Container(
        key: const ValueKey('tutoring-phase'),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: const Color(0xE00A2E5C),
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: LumoVisualTokens.cyan.withValues(alpha: .5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nachhilfe mit Lumo · ${phase.label}',
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Row(children: [
              for (final step in LumoTutoringPhase.values) ...[
                if (step.index > 0) const SizedBox(width: 5),
                Expanded(
                  child: Container(
                    height: 7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: step.index < current
                          ? LumoVisualTokens.cyanBright
                          : step.index == current
                              ? const Color(0xFFFFD36A)
                              : const Color(0x3365DFFF),
                    ),
                  ),
                ),
              ],
            ]),
          ],
        ),
      ),
    );
  }
}

/// Lumo erklärt das Thema Schritt für Schritt, bevor gemeinsam geübt wird.
class LumoTutoringExplainCard extends StatelessWidget {
  const LumoTutoringExplainCard({
    super.key,
    required this.unit,
    required this.steps,
    required this.onContinue,
    this.onOpenPictureCourse,
    this.onSpeak,
    this.illustration,
  });

  final String unit;
  final List<String> steps;
  final VoidCallback onContinue;
  final VoidCallback? onOpenPictureCourse;
  final VoidCallback? onSpeak;

  /// Darstellung zum Thema (z. B. Rechentrick-Karte), ohne Lösung.
  final Widget? illustration;

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('tutoring-explain'),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xF00F3F7A),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: LumoVisualTokens.cyanBright, width: 1.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lumo erklärt: $unit',
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
            const SizedBox(height: 10),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: LumoVisualTokens.cyanBright,
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              color: Color(0xFF07214A),
                              fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(steps[i],
                          style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 16,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ],
                ),
              ),
            if (illustration != null) ...[
              const SizedBox(height: 6),
              illustration!,
            ],
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (onOpenPictureCourse != null)
                OutlinedButton.icon(
                  key: const ValueKey('tutoring-picture-course'),
                  onPressed: onOpenPictureCourse,
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF73D4ED))),
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Bildkurs mit Lumo ansehen'),
                ),
              if (onSpeak != null)
                OutlinedButton.icon(
                  onPressed: onSpeak,
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF73D4ED))),
                  icon: const Icon(Icons.volume_up_rounded),
                  label: const Text('Vorlesen'),
                ),
              FilledButton.icon(
                key: const ValueKey('tutoring-continue'),
                onPressed: onContinue,
                style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    backgroundColor: LumoVisualTokens.cyanBright,
                    foregroundColor: const Color(0xFF07214A)),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Jetzt gemeinsam üben'),
              ),
            ]),
          ],
        ),
      );
}

/// Rückblick am Ende der Stunde – nur aus echten Ergebnissen dieser Stunde.
class LumoTutoringReview {
  const LumoTutoringReview({required this.canNow, required this.tomorrow});

  final List<String> canNow;
  final String tomorrow;

  factory LumoTutoringReview.from({
    required String unit,
    required int alone,
    required int together,
    required int twinWins,
    required Map<String, int> mistakes,
  }) {
    final canNow = <String>[
      if (alone > 0)
        '$unit: ${alone == 1 ? 'eine Aufgabe' : '$alone Aufgaben'} ganz allein gelöst.',
      if (together > 0)
        '$unit: ${together == 1 ? 'eine Aufgabe' : '$together Aufgaben'} mit Hilfe geschafft.',
      if (twinWins > 0)
        'Eine Aufgabe, die vorher schwer war, hast du später richtig gelöst.',
    ];
    if (canNow.isEmpty) {
      canNow.add('Du hast dir $unit angeschaut. Das war ein Anfang.');
    }
    String tomorrow;
    if (mistakes.isNotEmpty) {
      final top = mistakes.entries.reduce((a, b) => b.value > a.value ? b : a);
      tomorrow = 'Das üben wir morgen: $unit, besonders „${top.key}“.';
    } else if (together >= alone) {
      tomorrow = 'Das üben wir morgen: $unit noch einmal – mit weniger Hilfe.';
    } else {
      tomorrow = 'Das üben wir morgen: kurz $unit wiederholen, '
          'dann darfst du ein neues Thema wählen.';
    }
    return LumoTutoringReview(canNow: canNow, tomorrow: tomorrow);
  }
}

class LumoTutoringReviewCard extends StatelessWidget {
  const LumoTutoringReviewCard({super.key, required this.review});
  final LumoTutoringReview review;

  static const _text = TextStyle(
      fontFamily: 'Nunito',
      fontSize: 16,
      height: 1.35,
      fontWeight: FontWeight.w700,
      color: Colors.white);

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('tutoring-review'),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xF00A3768),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFFD36A), width: 1.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Das kannst du jetzt',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFFD36A))),
            const SizedBox(height: 8),
            for (final line in review.canNow)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF6CF0B5), size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(line, style: _text)),
                    ]),
              ),
            const SizedBox(height: 6),
            Text(review.tomorrow,
                key: const ValueKey('tutoring-tomorrow'), style: _text),
          ],
        ),
      );
}
