import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/learning/lab/learning_lab_catalog.dart';

void main() {
  test('six local topic worlds preserve grade gates and four distinct problems',
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
    for (final topic in LabCatalog.topics.where((t) =>
        t.mode != LabMode.bridge &&
        t.mode != LabMode.fraction &&
        t.mode != LabMode.pattern)) {
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

  test('equivalent fractions are correct and undefined fractions are rejected',
      () {
    final problem = LabCatalog.topics
        .firstWhere((topic) => topic.mode == LabMode.fraction)
        .problems
        .first;
    expect(problem.accepts('6 / 8'), isTrue);
    expect(problem.accepts('75/100'), isTrue);
    expect(problem.accepts('3/0'), isFalse);
    expect(problem.accepts('0/0'), isFalse);
    expect(problem.accepts('6/7'), isFalse);
    expect(problem.accepts('3/4/1'), isFalse);
  });

  test('pattern options are graded from the checked repeating group', () {
    final topic =
        LabCatalog.topics.singleWhere((topic) => topic.mode == LabMode.pattern);
    final first = topic.problems.first;
    expect(first.pattern, ['Kreis', 'Dreieck', 'Kreis', 'Dreieck', 'Kreis']);
    expect(first.expected, 'Dreieck');
    for (final problem in topic.problems) {
      expect(problem.isValid, isTrue);
      expect(problem.modelAccepts([]), isFalse);
      expect(problem.modelAccepts([-1]), isFalse);
      expect(problem.modelAccepts([problem.tokens.length]), isFalse);
      for (var i = 0; i < problem.tokens.length; i++) {
        expect(
            problem.modelAccepts([i]), problem.tokens[i] == problem.expected);
      }
      expect(problem.accepts(problem.expected.toLowerCase()), isTrue);
    }
  });

  test('a malformed model cannot pass the pre-display validation', () {
    final source = LabCatalog.topics.first.problems.first;
    final bad = LabProblem(
        id: source.id,
        mode: source.mode,
        prompt: source.prompt,
        guidedPrompt: source.guidedPrompt,
        expected: '14',
        workedExample: source.workedExample,
        hints: source.hints,
        reflection: source.reflection,
        start: 8,
        addend: 5,
        modelTarget: 2);
    expect(bad.isValid, isFalse);
  });
}
