import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/german_task_templates.dart';
import '../../core/math_task_templates.dart';
import '../../domain/school/attempt.dart';
import '../../domain/school/competency.dart';
import '../../domain/school/learning_analysis.dart';
import 'demo_class_data.dart';

/// Eine gelöste Aufgabe aus einer Hausaufgabe.
class HomeworkItemResult {
  const HomeworkItemResult({
    required this.prompt,
    required this.expected,
    required this.given,
    required this.durationMs,
    required this.hintUsed,
  });

  final String prompt;
  final String expected;
  final String given;
  final int durationMs;
  final bool hintUsed;

  /// Automatische Prüfung: Antwort gegen die Lösung des Aufgabengenerators.
  bool get correct => checkHomeworkAnswer(given: given, expected: expected);

  Map<String, Object?> toJson() => {
        'q': prompt,
        'e': expected,
        'a': given,
        'ms': durationMs,
        'h': hintUsed,
      };

  static HomeworkItemResult fromJson(Map<String, Object?> json) =>
      HomeworkItemResult(
        prompt: '${json['q'] ?? ''}',
        expected: '${json['e'] ?? ''}',
        given: '${json['a'] ?? ''}',
        durationMs: (json['ms'] as num?)?.toInt() ?? 0,
        hintUsed: json['h'] == true,
      );
}

/// Vergleicht eine Antwort mit der erwarteten Lösung, unabhängig von
/// Leerzeichen und Groß-/Kleinschreibung.
bool checkHomeworkAnswer({required String given, required String expected}) {
  String norm(String v) => v.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  return given.trim().isNotEmpty && norm(given) == norm(expected);
}

/// Fächer der Hausaufgaben mit automatischer Prüfung (Auswahlantworten aus den
/// Aufgabengeneratoren der App). Weitere Fächer folgen schrittweise, sobald
/// ihre Aufgaben ohne Bild- oder Schreibfläche prüfbar sind.
const List<String> homeworkSubjects = ['Mathematik', 'Deutsch'];

/// Schulstufen, für die Hausaufgaben gestaltet werden können.
const List<int> homeworkGrades = [1, 2, 3, 4];

/// Eine automatisch prüfbare Hausaufgaben-Aufgabe.
class HomeworkTask {
  const HomeworkTask({
    required this.prompt,
    required this.answer,
    required this.choices,
    required this.explanation,
  });

  final String prompt;
  final String answer;
  final List<String> choices;
  final String explanation;
}

/// Themen brauchen Bilder oder freie Schreibflächen und sind deshalb (noch)
/// nicht als Auswahl-Hausaufgabe geeignet.
const Set<String> _nichtAlsAuswahl = {'Wort-Bild-Zuordnung'};

HomeworkTask homeworkTaskFor({
  required String subject,
  required String unit,
  required int grade,
  required int seed,
}) {
  if (subject == 'Deutsch') {
    final t = GermanTaskTemplates.generate(grade: grade, unit: unit, seed: seed);
    return HomeworkTask(
        prompt: t.prompt,
        answer: t.answer,
        choices: t.choices,
        explanation: t.explanation);
  }
  final t = MathTaskTemplates.generate(grade: grade, unit: unit, seed: seed);
  return HomeworkTask(
      prompt: t.prompt,
      answer: t.answer,
      choices: t.choices,
      explanation: t.explanation);
}

final Map<(String, int), List<String>> _themenCache = {};

/// Themen, aus denen für [subject] und Schulstufe [grade] eine Hausaufgabe
/// entstehen kann: eigene Aufgabenfamilie bis zu dieser Stufe, und jede
/// Probeaufgabe hat Text, mindestens zwei Antworten und die Lösung darunter.
List<String> homeworkUnitsFor(String subject, int grade) {
  final stufe = grade.clamp(1, 4).toInt();
  return _themenCache.putIfAbsent((subject, stufe), () {
    final List<String> kandidaten;
    if (subject == 'Mathematik') {
      kandidaten = [
        for (final u in homeworkMathUnits)
          if (MathTaskTemplates.templates
              .any((t) => t.unit == u && t.grade <= stufe))
            u,
      ];
    } else if (subject == 'Deutsch') {
      final mitStufe = <String, int>{};
      for (final t in GermanTaskTemplates.templates) {
        if (t.grade > stufe || _nichtAlsAuswahl.contains(t.unit)) continue;
        mitStufe.update(t.unit, (g) => g < t.grade ? g : t.grade,
            ifAbsent: () => t.grade);
      }
      kandidaten = mitStufe.keys.toList()
        ..sort((a, b) {
          final g = mitStufe[a]!.compareTo(mitStufe[b]!);
          return g != 0 ? g : a.compareTo(b);
        });
    } else {
      return const <String>[];
    }
    return List<String>.unmodifiable([
      for (final unit in kandidaten)
        if (List.generate(8, (i) => i * 7919 + 13).every((seed) {
          final t = homeworkTaskFor(
              subject: subject, unit: unit, grade: stufe, seed: seed);
          return t.prompt.trim().isNotEmpty &&
              t.choices.length >= 2 &&
              t.choices.contains(t.answer);
        }))
          unit,
    ]);
  });
}

int _stableHash(String value) {
  var h = 17;
  for (final unit in value.codeUnits) {
    h = (h * 31 + unit) & 0x7ffffff;
  }
  return h;
}

/// Eine von der Lehrkraft gestaltete Hausaufgabe.
class DemoHomework {
  const DemoHomework({
    required this.id,
    required this.subject,
    required this.unit,
    required this.count,
    required this.due,
    required this.note,
    required this.studentIds,
    required this.createdAt,
    this.results = const {},
    this.grade,
  });

  final String id;
  final String subject;
  final String unit;
  final int count;
  final DateTime due;
  final String note;
  final List<String> studentIds;
  final DateTime createdAt;

  /// Ergebnisse je Kind (Demo-Schüler-ID).
  final Map<String, List<HomeworkItemResult>> results;

  /// Schulstufe der Aufgaben. Ältere gespeicherte Hausaufgaben haben keine
  /// und nutzen weiter die Schulstufe des Kindes.
  final int? grade;

  bool isDoneBy(String studentId) =>
      (results[studentId]?.length ?? 0) >= count;

  /// Aufgaben der Hausaufgabe, stabil je Kind aus dem Aufgabengenerator.
  /// [grade] gilt nur für ältere Hausaufgaben ohne eigene Schulstufe.
  List<HomeworkTask> tasksFor(String studentId, {int grade = 2}) {
    final base = _stableHash('$id|$studentId');
    return [
      for (var i = 0; i < count; i++)
        homeworkTaskFor(
            subject: subject,
            unit: unit,
            grade: this.grade ?? grade,
            seed: base + i * 31),
    ];
  }

  DemoHomework withResult(String studentId, List<HomeworkItemResult> items) =>
      DemoHomework(
        id: id,
        subject: subject,
        unit: unit,
        count: count,
        due: due,
        note: note,
        studentIds: studentIds,
        createdAt: createdAt,
        results: {...results, studentId: items},
        grade: grade,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'sub': subject,
        'unit': unit,
        'n': count,
        'due': due.toIso8601String(),
        'note': note,
        'kids': studentIds,
        'at': createdAt.toIso8601String(),
        if (grade != null) 'g': grade,
        'res': {
          for (final e in results.entries)
            e.key: [for (final r in e.value) r.toJson()],
        },
      };

  static DemoHomework? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final due = DateTime.tryParse('${raw['due']}');
    final at = DateTime.tryParse('${raw['at']}');
    if (due == null || at == null || raw['id'] is! String) return null;
    final kids = [
      for (final k in (raw['kids'] as List? ?? const []))
        if (isDemoStudentId('$k')) '$k',
    ];
    final res = <String, List<HomeworkItemResult>>{};
    final rawRes = raw['res'];
    if (rawRes is Map) {
      for (final e in rawRes.entries) {
        final list = e.value;
        if (list is! List) continue;
        res['${e.key}'] = [
          for (final item in list)
            if (item is Map)
              HomeworkItemResult.fromJson(item.cast<String, Object?>()),
        ];
      }
    }
    return DemoHomework(
      id: raw['id'] as String,
      subject: '${raw['sub'] ?? 'Mathematik'}',
      unit: '${raw['unit'] ?? ''}',
      count: (raw['n'] as num?)?.toInt() ?? 5,
      due: due,
      note: '${raw['note'] ?? ''}',
      studentIds: kids,
      createdAt: at,
      results: res,
      grade: switch (raw['g']) {
        final num g when g >= 1 && g <= 4 => g.toInt(),
        _ => null,
      },
    );
  }
}

/// Auswertung einer erledigten Hausaufgabe für die Lehrkraft.
class HomeworkEvaluation {
  HomeworkEvaluation(this.homework, this.studentId, this.items)
      : analysis = LearningAnalysis.analyze([
          for (var i = 0; i < items.length; i++)
            Attempt(
              id: '${homework.id}-$studentId-$i',
              studentId: studentId,
              subject: homework.subject,
              unit: homework.unit,
              competency: const CompetencyClassifier().classify(
                  subject: homework.subject,
                  unit: homework.unit,
                  prompt: items[i].prompt),
              correct: items[i].correct,
              at: homework.createdAt,
              hintUsed: items[i].hintUsed,
              prompt: items[i].prompt,
              given: items[i].given,
              expected: items[i].expected,
              durationMs: items[i].durationMs,
            ),
        ], now: homework.createdAt);

  final DemoHomework homework;
  final String studentId;
  final List<HomeworkItemResult> items;
  final LearningAnalysis analysis;

  int get correct => items.where((i) => i.correct).length;
  int get wrong => items.length - correct;
  int get hints => items.where((i) => i.hintUsed).length;
  int get percent => items.isEmpty ? 0 : (correct * 100 / items.length).round();
  double get averageSeconds => items.isEmpty
      ? 0
      : items.map((i) => i.durationMs).reduce((a, b) => a + b) /
          items.length /
          1000;
}

/// Speichert Demo-Hausaufgaben lokal auf diesem Gerät, getrennt von allen
/// echten Kinderprofilen. Es gibt keine Übertragung an andere Geräte.
class DemoHomeworkStore {
  static const String storageKey = 'lumo_teacher_demo_homework_v1';

  Future<List<DemoHomework>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (DemoHomework.tryFromJson(item) case final hw?) hw,
      ];
    } on FormatException {
      return const [];
    }
  }

  Future<void> saveAll(List<DemoHomework> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        storageKey, jsonEncode([for (final h in list) h.toJson()]));
  }

  Future<List<DemoHomework>> add(DemoHomework homework) async {
    final list = [...await load(), homework];
    await saveAll(list);
    return list;
  }

  Future<List<DemoHomework>> recordResult(
      String homeworkId, String studentId, List<HomeworkItemResult> items) async {
    final list = [
      for (final h in await load())
        h.id == homeworkId ? h.withResult(studentId, items) : h,
    ];
    await saveAll(list);
    return list;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }
}
