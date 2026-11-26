import 'dart:math' as math;

import '../../core/math_task_templates.dart';
import '../../domain/school/attempt.dart';
import '../../domain/school/competency.dart';
import '../../domain/school/learning_analysis.dart';
import '../../domain/school/learning_guidance.dart';

/// Kennzeichnung, die überall in der Lehrkräfte-Demo sichtbar ist.
const String demoDataLabel = 'DEMO-DATEN';

/// Präfix aller Demo-Schüler-IDs. Echte Profile tragen es nie, dadurch
/// bleiben Demo-Daten und echte Lerndaten sicher getrennt. Dieselbe Konstante
/// sperrt Demo-Kinder in der echten Eltern-/Lehrkräfte-Auswertung.
const String demoStudentPrefix = LearningGuidance.demoStudentPrefix;

bool isDemoStudentId(String id) => id.startsWith(demoStudentPrefix);

/// Ein Übungsbereich der App, aus dem Demo-Daten und Hausaufgaben entstehen.
class DemoPracticeArea {
  const DemoPracticeArea(this.subject, this.unit, this.samples);
  final String subject;
  final String unit;

  /// Beispielaufgaben für Fächer ohne Rechengenerator.
  final List<String> samples;

  bool get isMath => subject == 'Mathematik';
}

/// Übungsbereiche, die in der Demo vorkommen. Mathematik nutzt den echten
/// Aufgabengenerator der App, die übrigen Fächer echte Themennamen.
const List<DemoPracticeArea> demoPracticeAreas = [
  DemoPracticeArea('Mathematik', 'Plus bis 20', []),
  DemoPracticeArea('Mathematik', 'Minus bis 20', []),
  DemoPracticeArea('Mathematik', 'Plus bis 100', []),
  DemoPracticeArea('Mathematik', 'Minus bis 100', []),
  DemoPracticeArea('Mathematik', 'Einmaleins', []),
  DemoPracticeArea('Deutsch', 'Rechtschreibung', ['Fahrrad', 'Straße', 'Bäcker']),
  DemoPracticeArea('Deutsch', 'Silben', ['Ba-na-ne', 'Ta-fel', 'Schu-le']),
  DemoPracticeArea('Deutsch', 'Lesen verstehen', ['Wer wohnt im Baumhaus?']),
  DemoPracticeArea('Englisch', 'Farben', ['red', 'blue', 'green']),
  DemoPracticeArea('Englisch', 'Tiere', ['dog', 'cat', 'bird']),
  DemoPracticeArea('Sachkunde', 'Pflanzen', ['Wurzel', 'Blüte', 'Blatt']),
  DemoPracticeArea('Sachkunde', 'Verkehr', ['Zebrastreifen', 'Ampel']),
];

/// Mathematik-Themen, aus denen Lehrkräfte Hausaufgaben zusammenstellen.
/// Diese Themen prüft die App automatisch mit ihrem Aufgabengenerator.
const List<String> homeworkMathUnits = [
  'Plus bis 10',
  'Minus bis 10',
  'Plus bis 20',
  'Minus bis 20',
  'Plus bis 100',
  'Minus bis 100',
  'Einmaleins',
];

const List<String> demoSubjects = [
  'Mathematik',
  'Deutsch',
  'Englisch',
  'Sachkunde',
];

/// Ein Demo-Kind mit eigener Lernstärke je Kompetenz.
class DemoChild {
  const DemoChild({
    required this.id,
    required this.name,
    required this.grade,
    required this.seed,
    required this.skill,
    required this.dailyTasks,
  });

  final String id;
  final String name;
  final int grade;
  final int seed;

  /// Grundsichere Trefferquote je Kompetenz (0..1) zu Beginn des Monats.
  final Map<String, double> skill;
  final int dailyTasks;
}

const List<DemoChild> demoChildren = [
  DemoChild(
    id: '${demoStudentPrefix}1',
    name: 'Demo-Kind 1',
    grade: 2,
    seed: 1101,
    dailyTasks: 14,
    skill: {
      'Addition ohne Zehnerübergang': .94,
      'Addition mit Zehnerübergang': .74,
      'Subtraktion ohne Zehnerübergang': .88,
      'Subtraktion mit Zehnerübergang': .42,
      'Einmaleins': .86,
      'Rechtschreibung': .58,
      'Silben': .92,
      'Lesen verstehen': .83,
      'Farben': .95,
      'Tiere': .8,
      'Pflanzen': .78,
      'Verkehr': .9,
    },
  ),
  DemoChild(
    id: '${demoStudentPrefix}2',
    name: 'Demo-Kind 2',
    grade: 2,
    seed: 2203,
    dailyTasks: 10,
    skill: {
      'Addition ohne Zehnerübergang': .97,
      'Addition mit Zehnerübergang': .9,
      'Subtraktion ohne Zehnerübergang': .93,
      'Subtraktion mit Zehnerübergang': .82,
      'Einmaleins': .55,
      'Rechtschreibung': .86,
      'Silben': .9,
      'Lesen verstehen': .62,
      'Farben': .88,
      'Tiere': .9,
      'Pflanzen': .92,
      'Verkehr': .85,
    },
  ),
  DemoChild(
    id: '${demoStudentPrefix}3',
    name: 'Demo-Kind 3',
    grade: 2,
    seed: 3307,
    dailyTasks: 12,
    skill: {
      'Addition ohne Zehnerübergang': .9,
      'Addition mit Zehnerübergang': .66,
      'Subtraktion ohne Zehnerübergang': .8,
      'Subtraktion mit Zehnerübergang': .6,
      'Einmaleins': .9,
      'Rechtschreibung': .9,
      'Silben': .95,
      'Lesen verstehen': .9,
      'Farben': .7,
      'Tiere': .52,
      'Pflanzen': .86,
      'Verkehr': .94,
    },
  ),
];

/// Erzeugt reproduzierbare Übungsverläufe über 28 Tage, so als hätte das
/// Kind einen Monat mit der App geübt. Gleiches Kind und gleicher Stichtag
/// ergeben immer dieselben Daten.
class DemoClassDataGenerator {
  const DemoClassDataGenerator();

  static const int days = 28;
  static const CompetencyClassifier _classifier = CompetencyClassifier();

  List<Attempt> attemptsFor(DemoChild child, {required DateTime now}) {
    final rng = math.Random(child.seed);
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: days - 1));
    final out = <Attempt>[];
    var counter = 0;
    for (var day = 0; day < days; day++) {
      final date = start.add(Duration(days: day));
      // Am Wochenende übt das Demo-Kind weniger, manchmal gar nicht.
      final weekend = date.weekday >= DateTime.saturday;
      if (weekend && rng.nextDouble() < .5) continue;
      final tasks = weekend ? child.dailyTasks ~/ 2 : child.dailyTasks;
      final progress = day / (days - 1);
      for (var t = 0; t < tasks; t++) {
        final area = demoPracticeAreas[rng.nextInt(demoPracticeAreas.length)];
        final taskSeed = child.seed * 1000 + counter;
        String prompt;
        String expected;
        if (area.isMath) {
          final task = MathTaskTemplates.generate(
              grade: child.grade, unit: area.unit, seed: taskSeed);
          prompt = task.prompt;
          expected = task.answer;
        } else {
          prompt = area.samples[rng.nextInt(area.samples.length)];
          expected = prompt;
        }
        final competency = _classifier.classify(
            subject: area.subject, unit: area.unit, prompt: prompt);
        final base = child.skill[competency] ?? .8;
        // Leichter Lernzuwachs über den Monat, bei Schwächen etwas mehr.
        final chance = (base + progress * (1 - base) * .35).clamp(0.0, .98);
        final correct = rng.nextDouble() < chance;
        final hint = rng.nextDouble() < (1 - base) * .9;
        final seconds = 6 + (1 - base) * 22 + rng.nextDouble() * 8;
        final at = date.add(Duration(
            hours: 14 + rng.nextInt(4), minutes: rng.nextInt(60)));
        out.add(Attempt(
          id: '${child.id}-$counter',
          studentId: child.id,
          subject: area.subject,
          unit: area.unit,
          competency: competency,
          correct: correct,
          at: at,
          hintUsed: hint,
          prompt: prompt,
          expected: expected,
          given: correct ? expected : '',
          durationMs: (seconds * 1000).round(),
        ));
        counter++;
      }
    }
    return out;
  }
}

/// Fertig aufbereitete Auswertung eines Demo-Kindes. Baut auf der
/// vorhandenen [LearningAnalysis] der App auf.
class DemoChildReport {
  DemoChildReport._({
    required this.child,
    required this.attempts,
    required this.analysis,
    required this.now,
  });

  factory DemoChildReport.build(DemoChild child, {required DateTime now}) {
    final attempts =
        const DemoClassDataGenerator().attemptsFor(child, now: now);
    return DemoChildReport._(
      child: child,
      attempts: attempts,
      analysis: LearningAnalysis.analyze(attempts, now: now),
      now: now,
    );
  }

  final DemoChild child;
  final List<Attempt> attempts;
  final LearningAnalysis analysis;
  final DateTime now;

  double accuracyOf(Iterable<Attempt> list) {
    final l = list.toList();
    if (l.isEmpty) return 0;
    return l.where((a) => a.correct).length / l.length;
  }

  double get overallAccuracy => accuracyOf(attempts);

  Iterable<Attempt> bySubject(String subject) =>
      attempts.where((a) => a.subject == subject);

  /// Trefferquote je Fach für das Kompetenz-Radar.
  Map<String, double> get subjectAccuracy => {
        for (final s in demoSubjects) s: accuracyOf(bySubject(s)),
      };

  /// Trefferquote je Untergruppe (Thema) eines Fachs.
  Map<String, double> unitAccuracy(String subject) {
    final out = <String, double>{};
    for (final area in demoPracticeAreas.where((a) => a.subject == subject)) {
      out[area.unit] = accuracyOf(bySubject(subject).where((a) => a.unit == area.unit));
    }
    return out;
  }

  /// Mittlere Bearbeitungszeit je Fach in Sekunden.
  Map<String, double> get subjectSeconds {
    final out = <String, double>{};
    for (final s in demoSubjects) {
      final timed = bySubject(s).where((a) => a.durationMs != null).toList();
      out[s] = timed.isEmpty
          ? 0
          : timed.map((a) => a.durationMs!).reduce((x, y) => x + y) /
              timed.length /
              1000;
    }
    return out;
  }

  /// Anteil der Aufgaben mit Lumo-Hilfe je Fach.
  Map<String, double> get subjectHintShare {
    final out = <String, double>{};
    for (final s in demoSubjects) {
      final list = bySubject(s).toList();
      out[s] = list.isEmpty
          ? 0
          : list.where((a) => a.hintUsed).length / list.length;
    }
    return out;
  }

  /// Trefferquote je Woche (4 Werte, älteste zuerst) je Fach.
  Map<String, List<double>> get weeklyAccuracy {
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: DemoClassDataGenerator.days - 1));
    final out = <String, List<double>>{};
    for (final s in demoSubjects) {
      out[s] = [
        for (var w = 0; w < 4; w++)
          accuracyOf(bySubject(s).where((a) {
            final index = a.at.difference(start).inDays ~/ 7;
            return index == w;
          })),
      ];
    }
    return out;
  }

  /// Automatisch erkannte Schwächen in lehrertauglicher Sprache.
  List<String> get weaknesses => [
        for (final s in analysis.stats)
          if (s.level == MasteryLevel.needsHelp ||
              (s.level == MasteryLevel.developing && s.accuracy < .7))
            describeWeakness(s),
      ];

  /// Automatisch erkannte Stärken.
  List<String> get strengths => [
        for (final s in analysis.stats.reversed)
          if (s.level == MasteryLevel.secure)
            '${s.competency} (${s.subject}) sitzt sicher: ${s.percent} % richtig bei ${s.attempts} Aufgaben.',
      ];

  /// Empfehlungen für die nächsten Übungen.
  List<String> get recommendations {
    final out = <String>[];
    final suggestion = analysis.suggestion;
    if (suggestion != null) out.add(suggestion.text);
    for (final s in analysis.stats) {
      if (s.level != MasteryLevel.needsHelp) continue;
      if (s.hints * 2 >= s.attempts) {
        out.add(
            'Bei „${s.competency}“ braucht das Kind oft Lumos Hilfe. Eine kurze Hausaufgabe mit ${s.unit} festigt den Ablauf.');
      } else {
        out.add(
            'Für „${s.competency}“ eine Hausaufgabe mit 8 Aufgaben aus ${s.unit} vergeben.');
      }
    }
    return out;
  }

  /// Schwächstes Mathematik-Thema, für den Hausaufgaben-Vorschlag.
  String? get suggestedHomeworkUnit {
    for (final s in analysis.stats) {
      if (s.subject == 'Mathematik' && homeworkMathUnits.contains(s.unit)) {
        return s.unit;
      }
    }
    return null;
  }

  static String describeWeakness(CompetencyStat s) {
    final detail = '${s.percent} % richtig';
    if (s.competency.contains('Zehnerübergang')) {
      return 'Zehnerübergang bei ${s.unit} unsicher ($detail).';
    }
    if (s.competency == 'Einmaleins') {
      return 'Einmaleins noch nicht automatisiert ($detail).';
    }
    return '${s.competency} (${s.subject}) noch unsicher ($detail).';
  }
}
