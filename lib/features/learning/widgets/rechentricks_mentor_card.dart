import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/math/lumo_rechentricks.dart';

/// 2026-06-05 Iter 21: Visuelle Karte fuer eine Rechentricks-Erklärung.
///
/// Inspiration: Mildenberger "Meine Rechentricks" Poster.
/// Layout: Avatar links, Catchphrase oben, Aufgabe darunter, dann
/// die Schritte als nummerierte Pills, zuletzt das Ergebnis.
class RechentricksMentorCard extends StatelessWidget {
  const RechentricksMentorCard({super.key, required this.explanation});

  final RechentricksExplanation explanation;

  @override
  Widget build(BuildContext context) {
    final m = explanation.mentor;
    final accent = Color(m.color);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withOpacity(0.08),
            accent.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: accent.withOpacity(0.45), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 2026-06-06 Iter 31: Premium-Avatar-PNG mit Emoji-Fallback.
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: accent, width: 1.8),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: m.avatarAsset != null
                      ? Image.asset(
                          m.avatarAsset!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(m.emoji,
                                style: const TextStyle(fontSize: 32)),
                          ),
                        )
                      : Center(
                          child: Text(m.emoji,
                              style: const TextStyle(fontSize: 32)),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.name,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '„${m.catchphrase}"',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: LumoColors.ink700,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(LumoRadius.md),
              border: Border.all(color: accent.withOpacity(0.35)),
            ),
            child: Text(
              'Aufgabe: ${explanation.taskText}',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: LumoColors.ink900,
              ),
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < explanation.steps.length; i++) ...[
            _StepLine(
              index: i + 1,
              text: explanation.steps[i],
              accent: accent,
            ),
            if (i < explanation.steps.length - 1) const SizedBox(height: 6),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(LumoRadius.pill),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 18, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      explanation.resultText,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({
    required this.index,
    required this.text,
    required this.accent,
  });
  final int index;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          margin: const EdgeInsets.only(top: 1),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withOpacity(0.18),
            border: Border.all(color: accent.withOpacity(0.7), width: 1.2),
          ),
          child: Text(
            '$index',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: LumoColors.ink700,
                height: 1.25,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
