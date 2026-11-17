import 'package:flutter/material.dart';

import '../../../core/lumo_personal_daily_tutor_planner.dart';

/// A compact and accessible next-step panel. Every action is tied to an
/// observed learning skill belonging to the active child; no invented scores.
class LumoPersonalDailyPlanCard extends StatelessWidget {
  const LumoPersonalDailyPlanCard({
    super.key,
    required this.steps,
    required this.onStart,
  });

  final List<LumoDailyTutorStep> steps;
  final ValueChanged<LumoDailyTutorStep> onStart;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();
    return Container(
      key: const ValueKey('lumo-personal-daily-plan'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xF00A3768), Color(0xF0071B3E)],
        ),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0xB04EDCFF), width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Heute mit Lumo',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Aus deinem bisherigen Lernen zusammengestellt',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              color: Color(0xFFE0F5FF),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 9),
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) const Divider(color: Color(0x4465DFFF)),
            Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    switch (steps[i].kind) {
                      LumoDailyTutorStepKind.revise =>
                        Icons.auto_stories_rounded,
                      LumoDailyTutorStepKind.practice =>
                        Icons.lightbulb_rounded,
                      LumoDailyTutorStepKind.confidence =>
                        Icons.star_rounded,
                      LumoDailyTutorStepKind.check => Icons.extension_rounded,
                    },
                    color: const Color(0xFF66DFFE),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(steps[i].title,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          )),
                      if (steps[i].pauseAfter) const Text('Danach ist Zeit für eine freiwillige Pause.', style: TextStyle(color: Color(0xFF9EEAFF), fontSize: 12)),
                      if (steps[i].reason.isNotEmpty) Text(steps[i].reason,
                        style: const TextStyle(color: Color(0xFF8DEBFF), fontSize: 12)),
                      Text(steps[i].description,
                          softWrap: true,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            height: 1.25,
                            color: Color(0xFFDEEFF9),
                          )),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  key: ValueKey('lumo-daily-plan-start-$i'),
                  tooltip: '${steps[i].title}: ${steps[i].description}',
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    backgroundColor: const Color(0xFF3AADD1),
                    foregroundColor: const Color(0xFF062344),
                  ),
                  onPressed: () => onStart(steps[i]),
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
