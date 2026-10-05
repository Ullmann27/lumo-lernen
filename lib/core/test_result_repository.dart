import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Fragen pro Test (Tests-Bildschirm und Übung zeigen dieselbe Zahl).
const int kLumoTestQuestions = 10;

/// Ein abgeschlossener Test: wie viele der Fragen beim ersten Versuch
/// richtig waren.
class TestResult {
  const TestResult({
    required this.subject,
    required this.correct,
    required this.total,
    required this.finishedAt,
  });

  final String subject;
  final int correct;
  final int total;
  final DateTime finishedAt;

  Map<String, Object> toJson() => {
        'subject': subject,
        'correct': correct,
        'total': total,
        'finishedAt': finishedAt.toIso8601String(),
      };

  static TestResult? fromJson(Object? json) {
    if (json is! Map) return null;
    final subject = json['subject'];
    final correct = json['correct'];
    final total = json['total'];
    final finishedAt = DateTime.tryParse('${json['finishedAt']}');
    if (subject is! String ||
        correct is! int ||
        total is! int ||
        total <= 0 ||
        finishedAt == null) {
      return null;
    }
    return TestResult(
      subject: subject,
      correct: correct.clamp(0, total),
      total: total,
      finishedAt: finishedAt,
    );
  }
}

/// Letztes Testergebnis und Bestleistung pro Fach (Tests-Bildschirm, Bild 05).
class TestResultSummary {
  const TestResultSummary({this.last, this.best = const {}});

  final TestResult? last;
  final Map<String, TestResult> best;
}

/// Speichert Testergebnisse pro Kind lokal auf dem Gerät.
class TestResultRepository {
  const TestResultRepository();

  String _key(String childName) {
    final safe = childName.trim().toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9äöüß]+'),
          '_',
        );
    return 'lumo.test_results.${safe.isEmpty ? 'kind' : safe}';
  }

  Future<TestResultSummary> load(String childName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(childName));
      if (raw == null || raw.isEmpty) return const TestResultSummary();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const TestResultSummary();
      final best = <String, TestResult>{};
      final rawBest = decoded['best'];
      if (rawBest is Map) {
        rawBest.forEach((subject, value) {
          final result = TestResult.fromJson(value);
          if (subject is String && result != null) best[subject] = result;
        });
      }
      return TestResultSummary(
        last: TestResult.fromJson(decoded['last']),
        best: best,
      );
    } catch (_) {
      return const TestResultSummary();
    }
  }

  /// Merkt sich das Ergebnis als letztes und, wenn es den bisher besten
  /// Anteil richtiger Antworten übertrifft, als Bestleistung des Fachs.
  Future<TestResultSummary> record(String childName, TestResult result) async {
    final current = await load(childName);
    final best = Map<String, TestResult>.from(current.best);
    final previous = best[result.subject];
    if (previous == null ||
        result.correct / result.total > previous.correct / previous.total) {
      best[result.subject] = result;
    }
    final summary = TestResultSummary(last: result, best: best);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(childName),
        jsonEncode({
          'last': result.toJson(),
          'best': {
            for (final entry in best.entries) entry.key: entry.value.toJson(),
          },
        }),
      );
    } catch (_) {
      // Ein nicht gespeichertes Ergebnis darf den Test nicht blockieren.
    }
    return summary;
  }
}
