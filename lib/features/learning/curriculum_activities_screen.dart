import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/curriculum/primary_activity_catalog.dart';
import '../../core/school_exercise_generator.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../journal/lumo_journal_screen.dart';
import '../lumo3d/lumo3d_launcher.dart';
import 'cross_grade_practice_screen.dart';

class CurriculumActivitiesScreen extends StatelessWidget {
  const CurriculumActivitiesScreen({
    super.key,
    required this.grade,
    required this.subject,
    this.appState,
  });

  final int grade;
  final String subject;
  final LumoAppState? appState;

  @override
  Widget build(BuildContext context) {
    final activities = PrimaryActivityCatalog.forGrade(grade, subject: subject);
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
                    DropdownButtonFormField<String>(
                      key: const ValueKey('practical-subject-selector'),
                      initialValue: subject,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF123760),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: const InputDecoration(
                          labelText: 'Praktische Lernaufgaben auswählen',
                          labelStyle:
                              TextStyle(color: LumoVisualTokens.cyanBright)),
                      items: [
                        for (final name in PrimaryActivityCatalog.all
                            .map((activity) => activity.subject)
                            .toSet())
                          DropdownMenuItem(value: name, child: Text(name)),
                      ],
                      onChanged: (name) {
                        if (name == null || name == subject) return;
                        Navigator.of(context).pushReplacement<void, void>(
                            MaterialPageRoute(
                                builder: (_) => CurriculumActivitiesScreen(
                                    grade: grade,
                                    subject: name,
                                    appState: appState)));
                      },
                    ),
                    const SizedBox(height: 16),
                    for (final activity in activities) ...[
                      _ActivityCard(activity: activity, appState: appState),
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
          border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.38)),
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
                'Hören oder Beobachten. Lies den Auftrag, probiere ihn aus '
                'und erkläre deine Beobachtung. Offene Ergebnisse besprichst '
                'du mit einer erwachsenen Person.',
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
  const _ActivityCard({required this.activity, this.appState});
  final CurriculumActivity activity;
  final LumoAppState? appState;

  @override
  Widget build(BuildContext context) {
    final accent = _accent(activity.subject);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.alphaBlend(accent.withOpacity(.18), const Color(0xEF0C315D)),
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
                  gradient:
                      LinearGradient(colors: [accent, accent.withOpacity(.48)]),
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
          Text('Dein Lernziel: ${activity.competency}',
              style: TextStyle(color: accent, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0x9910355F),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.22)),
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
          const SizedBox(height: 12),
          const Text(
              '1 · Lies den Auftrag und bereite das Material vor.\n'
              '2 · Probiere ihn aus und beobachte genau.\n'
              '3 · Erkläre: Was hast du gemacht? Was hast du bemerkt? '
              'Was möchtest du noch ausprobieren?',
              style: TextStyle(
                  color: LumoVisualTokens.white, height: 1.45, fontSize: 14)),
          if (activity.requiresAdult) ...[
            const SizedBox(height: 10),
            const Text('Führe diese Aufgabe mit einer erwachsenen Person aus.',
                style: TextStyle(
                    color: Color(0xFFFFC96B),
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
          ],
          if (appState != null) ...[
            const SizedBox(height: 14),
            if (_nativeScene != null)
              OutlinedButton.icon(
                  key: ValueKey('activity-${activity.id}-workshop'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      foregroundColor: Colors.white),
                  onPressed: () => launchLumo3D(context,
                      scene: _nativeScene!,
                      grade: activity.grade,
                      subject: activity.subject,
                      appState: appState),
                  icon: Icon(_icon(activity.subject)),
                  label: Text(_nativeScene == 'rhythm'
                      ? 'In der Rhythmuswerkstatt üben'
                      : 'In der Bauwelt ausprobieren')),
            if (_linkedPractice != null)
              OutlinedButton.icon(
                  key: ValueKey('activity-${activity.id}-practice'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      foregroundColor: Colors.white),
                  onPressed: () {
                    final practice = _linkedPractice!;
                    Navigator.of(context).push<void>(MaterialPageRoute(
                        builder: (_) => CrossGradePracticeScreen(
                            profileName: appState!.state.childName,
                            enrolledGrade: appState!.state.grade,
                            lessonGrade: activity.grade,
                            subject: practice.subject,
                            unit: practice.unit,
                            appState: appState)));
                  },
                  icon: const Icon(Icons.touch_app_rounded),
                  label: Text('Digital üben: ${_linkedPractice!.unit}')),
            FilledButton.icon(
                key: ValueKey('activity-${activity.id}-journal'),
                style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                        builder: (_) =>
                            LumoJournalScreen(appState: appState!))),
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Beobachtung im Journal festhalten')),
            const SizedBox(height: 8),
            Text(
                'Verwende dort den Titel „${activity.title}“. '
                'Beschreibe dein eigenes Ergebnis. Eine automatische '
                'Richtig-oder-falsch-Bewertung gibt es für diesen Auftrag nicht.',
                style: const TextStyle(
                    color: LumoVisualTokens.muted, fontSize: 13, height: 1.4)),
          ],
        ],
      ),
    );
  }

  String? get _nativeScene => switch (activity.subject) {
        'Musik' => 'rhythm',
        'Technik und Design' => 'build',
        _ => null,
      };

  /// Link only to a real, grade-matching unit in the current generator.
  /// Opening the supplementary exercise does not certify the practical work.
  ({String subject, String unit})? get _linkedPractice {
    final (subject, terms) = switch (activity.subject) {
      'Verkehrs- und Mobilitätsbildung' => ('Sachunterricht', ['Verkehr']),
      'Kunst und Gestaltung' => (
          'Mathematik',
          ['Symmetrie', 'Geometrie Formen']
        ),
      'Deutsch' => ('Lesen', ['Lesesinn', 'Reihenfolge']),
      'Englisch' => ('Englisch', ['Alltag', 'Begruessung', 'Hobbys']),
      'Sachunterricht'
          when activity.id.contains('observe') ||
              activity.id.contains('habitat') =>
        ('Sachunterricht', ['Pflanzen', 'Tiere']),
      _ => ('', const <String>[]),
    };
    if (subject.isEmpty) return null;
    final units = Curriculum.unitsForGrade(subject, activity.grade,
        currentGradeOnly: true);
    for (final term in terms) {
      for (final unit in units) {
        if (unit.toLowerCase().contains(term.toLowerCase())) {
          return (subject: subject, unit: unit);
        }
      }
    }
    return null;
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
