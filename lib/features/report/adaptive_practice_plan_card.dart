import 'package:flutter/material.dart';

import '../../domain/school/adaptive_practice_plan.dart';
import '../../theme/lumo_visual_tokens.dart';

/// Shared, local-only plan for child/parent and individual teacher reports.
class AdaptivePracticePlanCard extends StatelessWidget {
  const AdaptivePracticePlanCard({super.key, required this.plan});
  final AdaptivePracticePlan plan;

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('adaptive-practice-plan'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xE60B2A55),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x8837D2FD)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Dein persönlicher Lernplan', style: TextStyle(
              fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w900,
              color: LumoVisualTokens.white,
            )),
            const SizedBox(height: 6),
            const Text(
              'Lumo nutzt die letzten bis zu zehn selbstständig beantworteten '
              'Aufgaben pro Kompetenz. Übungen mit Hilfe werden getrennt '
              'gezählt. Das sind Vorschläge, keine Noten oder Diagnosen.',
              style: _body,
            ),
            if (plan.steps.isEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Für einen persönlichen Vorschlag braucht Lumo mindestens '
                'fünf selbstständige Antworten zu einer Kompetenz.',
                style: _body,
              ),
            ] else
              for (final step in plan.steps) ...[
                const SizedBox(height: 12),
                _PlanStep(step: step),
              ],
          ],
        ),
      );
}

const _body = TextStyle(
  fontFamily: 'Nunito', color: Color(0xFFD6E8FF),
  fontSize: 14, height: 1.35, fontWeight: FontWeight.w700,
);

class _PlanStep extends StatelessWidget {
  const _PlanStep({required this.step});
  final AdaptivePracticeStep step;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (step.focus) {
      PracticeFocus.guidedPractice => (
        Icons.lightbulb_outline_rounded, const Color(0xFFFFB86B)),
      PracticeFocus.consolidate => (
        Icons.auto_stories_rounded, LumoVisualTokens.cyanBright),
      PracticeFocus.review => (
        Icons.refresh_rounded, LumoVisualTokens.gold),
      PracticeFocus.extend => (
        Icons.trending_up_rounded, const Color(0xFF7BE08C)),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF14355F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(step.title, style: _body.copyWith(
                color: color, fontWeight: FontWeight.w900))),
            ]),
            const SizedBox(height: 6),
            Text('${step.subject} · ${step.unit}', style: _body.copyWith(
              color: LumoVisualTokens.white, fontWeight: FontWeight.w900)),
            if (step.competency != step.unit)
              Text(step.competency, style: _body),
            const SizedBox(height: 6),
            Text('${step.independentCorrect} von ${step.independentAttempts} '
                'zuletzt ohne Hilfe richtig · ${step.guidedAttempts} '
                'mit Hilfe im Protokoll', style: _body),
            const SizedBox(height: 6),
            Text(step.method, style: _body),
          ],
        ),
      ),
    );
  }
}
