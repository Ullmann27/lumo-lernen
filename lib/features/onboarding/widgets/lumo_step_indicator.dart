// ════════════════════════════════════════════════════════════════════════
// LUMO STEP INDICATOR — Visueller Fortschritt durchs Onboarding
// ════════════════════════════════════════════════════════════════════════
// Design-Polish nach Heinz' Wunsch: 'klarere Hauptaktionen, hochwertigere
// Fortschrittsanzeigen, weniger Chaos auf einzelnen Screens'.
//
// Kinder sehen sofort: wo bin ich? wie viele Schritte fehlen noch?
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../../../app/app_theme.dart';

/// Zeigt 4 Punkte (oder N) horizontal, der aktive ist groesser und
/// in der Akzentfarbe. Frueher abgeschlossene Punkte sind gefuellt
/// in Akzentfarbe (mit Check-Icon), zukuenftige sind grau.
class LumoStepIndicator extends StatelessWidget {
  const LumoStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.accent = LumoColors.orange,
  });

  final int currentStep; // 0-indexed
  final int totalSteps;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (i) {
        final isPast = i < currentStep;
        final isCurrent = i == currentStep;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _StepDot(
            isPast: isPast,
            isCurrent: isCurrent,
            accent: accent,
            index: i,
          ),
        );
      }),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.isPast,
    required this.isCurrent,
    required this.accent,
    required this.index,
  });

  final bool isPast;
  final bool isCurrent;
  final Color accent;
  final int index;

  @override
  Widget build(BuildContext context) {
    final size = isCurrent ? 28.0 : 16.0;
    Color bg;
    if (isPast) {
      bg = accent;
    } else if (isCurrent) {
      bg = accent;
    } else {
      bg = Colors.white;
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      width: isCurrent ? 32.0 : size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: isCurrent
              ? accent
              : (isPast ? accent : accent.withOpacity(0.3)),
          width: isCurrent ? 2.5 : 1.5,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: accent.withOpacity(0.45),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: isPast
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 11)
          : (isCurrent
              ? Text('${index + 1}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ))
              : null),
    );
  }
}
