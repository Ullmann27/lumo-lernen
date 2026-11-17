import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/learning/lab/learning_lab_catalog.dart';

void main() {
  test(
      'six local topic worlds preserve grade gates and four distinct problems',
      () {
    expect(LabCatalog.topics.length, 6);
    expect(
        LabCatalog.forGrade(1).any((t) => t.mode == LabMode.fraction), isFalse);
    expect(LabCatalog.forGrade(4).length, 6);
    for (final topic in LabCatalog.topics) {
      final problems = topic.problems;
      expect(problems.length, greaterThanOrEqualTo(4));
      expect(problems.map((p) => p.id).toSet().length, problems.length);
      expect(problems.map((p) => p.expected).toSet().length, greaterThan(1));
      for (final p in problems) {
        expect(p.isValid, isTrue, reason: p.id);
        expect(p.accepts(p.expected), isTrue);
        expect(p.accepts(''), isFalse);
        expect(p.hints.length, 5);
        expect(p.workedExample, isNotEmpty);
        expect(p.guidedPrompt, isNotEmpty);
        expect(p.reflection, isNotEmpty);
      }
    }
  });

  test('bridge problems and worked steps are arithmetically consistent', () {
    for (final p in LabCatalog.topics.first.problems) {
      expect(p.expected, '${p.start + p.addend}');
      expect(p.modelTarget, 10 - p.start);
      expect(p.addend, greaterThan(p.modelTarget));
      expect(p.accepts('  ${p.expected}  '), isTrue);
      expect(p.errorTag('${p.start}'), 'start_instead_of_sum');
      expect(p.errorTag('${p.start + p.addend - 1}'), 'one_off');
      expect(p.errorTag('123456'), 'needs_check');
      expect(p.errorTag(p.expected), isNull);
    }
  });

  test('fractions accept spacing but reject changed denominator and decimals',
      () {
    final p = LabCatalog.topics
        .firstWhere((t) => t.mode == LabMode.fraction)
        .problems
        .first;
    expect(p.accepts(' ${p.modelTarget} / ${p.denominator} '), isTrue);
    expect(p.accepts('${p.modelTarget}/${p.denominator + 1}'), isFalse);
    expect(
        p.errorTag('${p.denominator}/${p.modelTarget}'), 'fraction_reversed');
    expect(
        p.errorTag('${p.modelTarget}/${p.denominator + 1}'), 'whole_changed');
    expect(p.accepts('0.75'), isFalse);
  });

  test('token solution uses stable indices and distractors cannot solve it',
      () {
    for (final topic in LabCatalog.topics
        .where((t) => const [LabMode.word, LabMode.english, LabMode.nature]
            .contains(t.mode))) {
      for (final p in topic.problems) {
        expect(p.tokenOrder.toSet().length, p.tokenOrder.length);
        expect(
            p.tokenOrder.every((i) => i >= 0 && i < p.tokens.length), isTrue);
        expect(p.tokens.length, greaterThan(p.tokenOrder.length));
        expect(p.modelAccepts(p.tokenOrder), isTrue);
        expect(p.modelAccepts(p.tokenOrder.reversed.toList()), isFalse);
      }
    }
  });

  test('pattern choices continue the visible repetition exactly once', () {
    final topic = LabCatalog.topics.singleWhere((t) => t.mode == LabMode.pattern);
    for (final problem in topic.problems) {
      expect(problem.isValid, isTrue);
      final expected = problem.pattern[problem.pattern.length % problem.repeatLength];
      expect(problem.expected, expected);
      final accepted = [
        for (var i = 0; i < problem.tokens.length; i++)
          if (problem.modelAccepts([i])) problem.tokens[i],
      ];
      expect(accepted, [expected]);
      expect(problem.modelAccepts([]), isFalse);
      expect(problem.modelAccepts([0, 1]), isFalse);
    }
  });

  test('language grading follows the actual learning goal', () {
    final german = LabCatalog.topics
        .firstWhere((t) => t.mode == LabMode.word)
        .problems
        .first;
    expect(german.accepts(german.expected.toLowerCase()), isFalse);
    expect(german.errorTag(german.expected.toLowerCase()), 'noun_capital');
    final english = LabCatalog.topics
        .firstWhere((t) => t.mode == LabMode.english)
        .problems
        .first;
    expect(english.accepts(english.expected.toUpperCase()), isTrue);
    expect(english.accepts('an unrelated sentence'), isFalse);
    final nature = LabCatalog.topics
        .firstWhere((t) => t.mode == LabMode.nature)
        .problems
        .first;
    expect(nature.accepts(nature.expected.toLowerCase()), isTrue);
    expect(nature.errorTag('Blüte'), 'plant_function');
  });
}
