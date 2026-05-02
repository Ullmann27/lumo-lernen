import 'school_exercise_generator.dart';

class LumoMission {
  const LumoMission({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.subject,
    required this.targetUnit,
    required this.minutes,
    required this.targetTasks,
    required this.rewardStars,
    required this.rewardXp,
    required this.kindMessage,
  });

  final String id;
  final String title;
  final String subtitle;
  final String subject;
  final String targetUnit;
  final int minutes;
  final int targetTasks;
  final int rewardStars;
  final int rewardXp;
  final String kindMessage;
}

class LumoMissionProgress {
  const LumoMissionProgress({
    required this.mission,
    required this.completedTasks,
    required this.correctTasks,
    required this.wrongTasks,
  });

  final LumoMission mission;
  final int completedTasks;
  final int correctTasks;
  final int wrongTasks;

  bool get finished => completedTasks >= mission.targetTasks;
  double get percent => mission.targetTasks == 0 ? 0 : (completedTasks / mission.targetTasks).clamp(0, 1).toDouble();

  String get childStatusText {
    if (finished) return 'Mission geschafft! Lumo ist stolz auf dich.';
    final left = mission.targetTasks - completedTasks;
    if (left == 1) return 'Noch eine Aufgabe, dann ist die Mission fertig.';
    return 'Noch $left kleine Schritte bis zum Ziel.';
  }
}

class LumoMissionEngine {
  const LumoMissionEngine();

  List<LumoMission> dailyMissions({
    required int grade,
    required Map<String, int> weakSkills,
    String preferredSubject = 'Alle',
  }) {
    final weakest = _weakestUnit(weakSkills);
    final missions = <LumoMission>[
      LumoMission(
        id: 'daily-warmup-g$grade',
        title: 'Kleine Startmission',
        subtitle: '3 leichte Aufgaben zum Reinkommen',
        subject: preferredSubject == 'Alle' ? 'Mathematik' : preferredSubject,
        targetUnit: weakest ?? 'Alle',
        minutes: 5,
        targetTasks: 3,
        rewardStars: 6,
        rewardXp: 30,
        kindMessage: 'Wir starten ganz ruhig. Nur drei kleine Aufgaben.',
      ),
      LumoMission(
        id: 'ten-minute-focus-g$grade',
        title: '10-Minuten-Fuchsmission',
        subtitle: 'Gemischtes Training ohne Stress',
        subject: 'Alle',
        targetUnit: weakest ?? 'Alle',
        minutes: 10,
        targetTasks: 8,
        rewardStars: 14,
        rewardXp: 90,
        kindMessage: 'Ich suche Aufgaben aus, die wirklich gut zu dir passen.',
      ),
      LumoMission(
        id: 'schoolwork-mini-g$grade',
        title: 'Schularbeit-Probe',
        subtitle: 'Wie in der Schule, aber freundlich',
        subject: 'Alle',
        targetUnit: 'Alle',
        minutes: 15,
        targetTasks: 12,
        rewardStars: 24,
        rewardXp: 160,
        kindMessage: 'Das ist eine ruhige Probe. Lies zuerst genau, dann antworte.',
      ),
    ];

    if (weakest != null) {
      missions.insert(
        1,
        LumoMission(
          id: 'smart-repeat-${weakest.hashCode}-g$grade',
          title: 'Lumo-Wiederholung',
          subtitle: 'Wir üben etwas, das bald leichter wird',
          subject: _subjectForUnit(weakest),
          targetUnit: weakest,
          minutes: 7,
          targetTasks: 5,
          rewardStars: 10,
          rewardXp: 60,
          kindMessage: 'Ich habe etwas gefunden, das wir mit kleinen Schritten staerken koennen.',
        ),
      );
    }

    return missions;
  }

  List<LumoTask> buildMissionTasks({
    required ExerciseFactory factory,
    required LumoMission mission,
    required int grade,
    required Map<String, int> weakSkills,
  }) {
    final tasks = <LumoTask>[];
    final avoid = <String>{};
    for (var i = 0; i < mission.targetTasks; i++) {
      tasks.add(
        factory.next(
          grade: grade,
          subject: mission.subject,
          unit: mission.targetUnit,
          weakSkills: weakSkills,
          avoidUnits: avoid,
        ),
      );
      avoid.add(tasks.last.unit);
      if (avoid.length > 8) avoid.clear();
    }
    return tasks;
  }

  String? _weakestUnit(Map<String, int> weakSkills) {
    if (weakSkills.isEmpty) return null;
    final entries = weakSkills.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }

  String _subjectForUnit(String unit) {
    for (final entry in Curriculum.subjects.entries) {
      if (entry.value.contains(unit)) return entry.key;
    }
    return 'Alle';
  }
}
