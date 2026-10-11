import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/discovery_progress.dart';
import 'package:lumo_lernen/domain/tutoring/guided_lesson_catalog.dart';
import 'package:lumo_lernen/domain/tutoring/tutoring_session_planner.dart';

void main() {
  for (final lesson in GuidedLessonCatalog.all) {
    test('${lesson.id}: complete example, guided practice and real check', () {
      lesson.discoveryTarget.validate();
      expect(lesson.steps.first.type, TutoringStepType.greeting);
      expect(lesson.steps.last.type, TutoringStepType.recap);
      final example = lesson.steps
          .indexWhere((step) => step.type == TutoringStepType.showExample);
      final guided = lesson.steps
          .indexWhere((step) => step.observation == DiscoveryStepKind.guided);
      final independent = lesson.steps.indexWhere(
          (step) => step.observation == DiscoveryStepKind.independent);
      final check = lesson.steps
          .indexWhere((step) => step.observation == DiscoveryStepKind.check);
      expect(example, greaterThan(1));
      expect(guided, greaterThan(example));
      expect(independent, greaterThan(guided));
      expect(check, greaterThan(independent));
      for (final step in lesson.steps.where((step) => step.isQuestion)) {
        expect(step.choices.toSet().length, step.choices.length);
        expect(step.choices.where(step.accepts).toList(), [step.expected]);
        expect(step.accepts('unbekannte Antwort'), false);
        expect(step.observation, isNotNull);
        expect(step.help(level: 1), isNot(step.help(level: 2)),
            reason: 'Anderer Tipp must offer a genuinely different strategy');
      }
    });
  }

  test('each explicit example and answer has an independently checked result',
      () {
    final steps = GuidedLessonCatalog.all.expand((lesson) => lesson.steps);
    for (final step in steps.where((step) => step.isQuestion)) {
      switch (step.answerKind!) {
        case GuidedAnswerKind.count:
          expect(int.parse(step.expected), step.a);
        case GuidedAnswerKind.gapToTen:
          expect(step.a + int.parse(step.expected), 10);
        case GuidedAnswerKind.remainder:
          expect(int.parse(step.expected) + (10 - step.a), step.b);
        case GuidedAnswerKind.sum:
          expect(int.parse(step.expected) - step.a, step.b);
        case GuidedAnswerKind.groups:
          expect(List.filled(step.a, step.b).reduce((a, b) => a + b),
              int.parse(step.expected));
        case GuidedAnswerKind.repeatedAddition:
          final actual = step.expected.split(' + ').map(int.parse).toList();
          expect(actual.length, step.a);
          expect(actual, everyElement(step.b));
          final totals = step.choices.map((value) =>
              value.split(' + ').map(int.parse).reduce((a, b) => a + b));
          expect(totals.where((total) => total == step.a * step.b).length, 1);
      }
    }
    final addition = GuidedLessonCatalog.bridgeTen.steps[2];
    expect(addition.a + addition.b, 12);
    final groups = GuidedLessonCatalog.equalGroups.steps[2];
    expect(groups.a * groups.b, 6);
  });

  test('bounded arithmetic sweep checks strategy steps without an AI judge',
      () {
    var cases = 0;
    for (var a = 1; a < 10; a++) {
      for (var b = 1; b <= 10; b++) {
        if (a + b <= 10 || a + b > 20) continue;
        for (final kind in [
          GuidedAnswerKind.gapToTen,
          GuidedAnswerKind.remainder,
          GuidedAnswerKind.sum,
        ]) {
          final step = GuidedLessonStep(
              type: TutoringStepType.guidedTask,
              title: 'Prüfung',
              instruction: 'Prüfung',
              a: a,
              b: b,
              answerKind: kind,
              observation: DiscoveryStepKind.guided);
          final expected = switch (kind) {
            GuidedAnswerKind.gapToTen => 10 - a,
            GuidedAnswerKind.remainder => a + b - 10,
            _ => a + b,
          };
          expect(int.parse(step.expected), expected);
          expect(step.choices.where(step.accepts).length, 1);
          cases++;
        }
      }
    }
    for (var groups = 1; groups <= 4; groups++) {
      for (var size = 1; size <= 4; size++) {
        final step = GuidedLessonStep(
            type: TutoringStepType.independentTask,
            title: 'Prüfung',
            instruction: 'Prüfung',
            a: groups,
            b: size,
            answerKind: GuidedAnswerKind.groups,
            observation: DiscoveryStepKind.independent);
        expect(step.accepts('${groups * size}'), true);
        expect(step.choices.where(step.accepts).length, 1);
        cases++;
      }
    }
    expect(cases, 151);
  });
}
