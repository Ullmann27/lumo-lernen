import 'attempt.dart';
import 'learning_analysis.dart';

enum PracticeFocus { guidedPractice, consolidate, review, extend }

/// A recommendation, not a diagnosis or a newly generated exercise.
/// All counts refer to recorded, unaided responses from the named topic.
class AdaptivePracticeStep {
  const AdaptivePracticeStep({
    required this.subject,
    required this.unit,
    required this.competency,
    required this.focus,
    required this.independentAttempts,
    required this.independentCorrect,
    required this.guidedAttempts,
    required this.lastIndependentAt,
  });

  final String subject;
  final String unit;
  final String competency;
  final PracticeFocus focus;
  final int independentAttempts;
  final int independentCorrect;
  final int guidedAttempts;
  final DateTime lastIndependentAt;

  String get title => switch (focus) {
        PracticeFocus.guidedPractice => 'Gemeinsam üben',
        PracticeFocus.consolidate => 'Festigen',
        PracticeFocus.review => 'Kurz wiederholen',
        PracticeFocus.extend => 'Nächsten Schritt probieren',
      };

  String get method {
    if (focus == PracticeFocus.review) {
      return 'Mit wenigen bekannten Aufgaben auffrischen. Bei Bedarf helfen.';
    }
    if (focus == PracticeFocus.extend) {
      return 'Freiwillig eine etwas anspruchsvollere Aufgabe im Thema probieren.';
    }
    if (competency.contains('Zehnerübergang')) {
      return 'Mit Zehnerfeldern und kleinen Rechenschritten erklären; '
          'danach selbst probieren lassen.';
    }
    if (competency == 'Einmaleins') {
      return 'Punktfelder und Malreihen zeigen; danach ohne Hilfe üben.';
    }
    final label = '$subject $unit $competency'.toLowerCase();
    if (label.contains('silben') || label.contains('laut') ||
        label.contains('lesen') || label.contains('vorlesen')) {
      return 'Laute und Silben vormachen, gemeinsam lesen, danach selbst lesen.';
    }
    if (label.contains('schreib') || label.contains('diktat')) {
      return 'Ein Beispielwort langsam zeigen, sprechen und selbst schreiben.';
    }
    return 'Ein Beispiel gemeinsam lösen, anders erklären und anschließend '
        'eine ähnliche Aufgabe selbst probieren lassen.';
  }
}

/// Derived entirely from the existing attempt log. No new database, rewards,
/// cloud access, or invented observations. Callers must supply a single owner.
class AdaptivePracticePlan {
  const AdaptivePracticePlan._(this.steps);
  final List<AdaptivePracticeStep> steps;

  static const minIndependent = 5;
  static const reviewAfter = Duration(days: 7);
  static const maxSteps = 3;

  static AdaptivePracticePlan fromAttempts(
    Iterable<Attempt> attempts, {
    required String studentId,
    required DateTime now,
  }) {
    if (studentId.trim().isEmpty) {
      return const AdaptivePracticePlan._([]);
    }
    final seen = <String>{};
    final groups = <(String, String, String), List<Attempt>>{};
    for (final a in attempts) {
      if (a.studentId != studentId ||
          a.id.trim().isEmpty ||
          a.subject.trim().isEmpty ||
          a.unit.trim().isEmpty ||
          a.competency.trim().isEmpty ||
          a.at.isAfter(now) ||
          LearningAnalysis.assessmentSubjects.contains(a.subject) ||
          !seen.add(a.id)) {
        continue;
      }
      groups.putIfAbsent((a.subject, a.unit, a.competency), () => []).add(a);
    }

    final candidates = <AdaptivePracticeStep>[];
    for (final entry in groups.entries) {
      final independent = entry.value.where((a) => !a.hintUsed).toList()
        ..sort((a, b) {
          final time = a.at.compareTo(b.at);
          return time != 0 ? time : a.id.compareTo(b.id);
        });
      if (independent.length < minIndependent) continue;
      // A bounded recent sample responds to improvement without erasing the
      // lifetime record. Assisted work is shown separately, never as mastery.
      final sample = independent.length > 10
          ? independent.sublist(independent.length - 10)
          : independent;
      final correct = sample.where((a) => a.correct).length;
      final ratio = correct / sample.length;
      final correctDays = {
        for (final a in sample.where((a) => a.correct))
          (a.at.toLocal().year, a.at.toLocal().month, a.at.toLocal().day),
      };
      final last = sample.last.at;
      final PracticeFocus focus;
      if (ratio < .60) {
        focus = PracticeFocus.guidedPractice;
      } else if (ratio < .85 || correctDays.length < 2) {
        focus = PracticeFocus.consolidate;
      } else if (now.difference(last) >= reviewAfter) {
        focus = PracticeFocus.review;
      } else {
        focus = PracticeFocus.extend;
      }
      candidates.add(AdaptivePracticeStep(
        subject: entry.key.$1,
        unit: entry.key.$2,
        competency: entry.key.$3,
        focus: focus,
        independentAttempts: sample.length,
        independentCorrect: correct,
        guidedAttempts: entry.value.where((a) => a.hintUsed).length,
        lastIndependentAt: last,
      ));
    }

    candidates.sort((a, b) {
      final priority = a.focus.index.compareTo(b.focus.index);
      if (priority != 0) return priority;
      final ratio = (a.independentCorrect * b.independentAttempts)
          .compareTo(b.independentCorrect * a.independentAttempts);
      if (ratio != 0) return ratio;
      final age = a.lastIndependentAt.compareTo(b.lastIndependentAt);
      if (age != 0) return age;
      final subject = a.subject.compareTo(b.subject);
      if (subject != 0) return subject;
      final unit = a.unit.compareTo(b.unit);
      return unit != 0 ? unit : a.competency.compareTo(b.competency);
    });

    // No contradictory directions for the same exercise route.
    final topics = <(String, String)>{};
    return AdaptivePracticePlan._(List.unmodifiable(
      candidates.where((a) => topics.add((a.subject, a.unit))).take(maxSteps),
    ));
  }
}
