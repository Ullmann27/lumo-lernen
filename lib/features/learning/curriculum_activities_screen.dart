import 'package:flutter/material.dart';

import '../../core/curriculum/primary_activity_catalog.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_design_system.dart';

class CurriculumActivitiesScreen extends StatelessWidget {
  const CurriculumActivitiesScreen({
    super.key,
    required this.grade,
    required this.subject,
  });

  final int grade;
  final String subject;

  @override
  Widget build(BuildContext context) {
    final activities =
        PrimaryActivityCatalog.forGrade(grade, subject: subject);
    return Scaffold(
      backgroundColor: LumoVisualTokens.night,
      body: LumoSceneBackground(
        scene: LumoScene.learning,
        dimmed: true,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Zurück',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: LumoVisualTokens.white),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              color: LumoVisualTokens.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '$grade. Klasse · praktische Lernaufgaben',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              color: LumoVisualTokens.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
                  children: [
                    const _InfoCard(),
                    const SizedBox(height: 12),
                    for (final activity in activities) ...[
                      _ActivityCard(activity: activity),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xE6123760), Color(0xE609264B)],
          ),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: LumoVisualTokens.cyan.withOpacity(.38)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.auto_awesome_rounded,
                color: LumoVisualTokens.cyanBright),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Hier zählt nicht nur eine richtige Antwort. Lumo gibt dir '
                'einen echten Arbeitsauftrag zum Gestalten, Bewegen, Bauen, '
                'Hören oder Beobachten. Ergebnisse können später von der '
                'Lehrkraft dokumentiert und rückgemeldet werden.',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: LumoVisualTokens.white,
                  fontSize: 13,
                  height: 1.38,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});
  final CurriculumActivity activity;

  @override
  Widget build(BuildContext context) {
    final accent = _accent(activity.subject);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.alphaBlend(accent.withOpacity(.18),
                const Color(0xEF0C315D)),
            const Color(0xEF071D42),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withOpacity(.58)),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [accent, accent.withOpacity(.48)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_icon(activity.subject),
                    color: Colors.white, size: 25),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        color: LumoVisualTokens.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      activity.competency,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: accent,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              if (activity.requiresAdult)
                const Tooltip(
                  message: 'Mit erwachsener Begleitung',
                  child: Icon(Icons.supervisor_account_rounded,
                      color: Color(0xFFFFC96B)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            activity.instruction,
            style: const TextStyle(
              fontFamily: 'Nunito',
              color: LumoVisualTokens.white,
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0x9910355F),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: LumoVisualTokens.cyan.withOpacity(.22)),
            ),
            child: Text(
              'Nachweis: ${activity.evidence}',
              style: const TextStyle(
                fontFamily: 'Nunito',
                color: LumoVisualTokens.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static IconData _icon(String subject) => switch (subject) {
        'Musik' => Icons.music_note_rounded,
        'Kunst und Gestaltung' => Icons.palette_rounded,
        'Technik und Design' => Icons.build_rounded,
        'Bewegung und Sport' => Icons.sports_gymnastics_rounded,
        _ => Icons.directions_walk_rounded,
      };

  static Color _accent(String subject) => switch (subject) {
        'Musik' => const Color(0xFFAB6BFF),
        'Kunst und Gestaltung' => const Color(0xFFFF67B8),
        'Technik und Design' => const Color(0xFF4FD7E8),
        'Bewegung und Sport' => const Color(0xFF61E69A),
        _ => const Color(0xFFFFC65C),
      };
}
