import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/cognitive_profile_generator.dart';
import 'package:lumo_lernen/domain/cognitive/cognitive_profile.dart';

// Fachprüfung Mathematik 17.11.2026, Befunde M27, M29, M30, L12.
void main() {
  for (var grade = 1; grade <= 4; grade++) {
    final questions = CognitiveProfileGenerator.forGrade(grade);

    test('Klasse $grade: Drehungen ohne „nach rechts gedreht“', () {
      for (final q in questions
          .where((q) => q.domain == CognitiveDomain.spatialReasoning)) {
        // „um 90° nach rechts gedreht“ wurde als „zeigt nach rechts“ gelesen.
        expect(q.prompt, isNot(contains('nach rechts')), reason: q.id);
        expect(q.prompt, isNot(contains('nach links')), reason: q.id);
        expect(q.prompt, contains('Uhrzeigersinn'), reason: q.id);
        if (grade < 4) {
          expect(q.prompt, isNot(contains('°')),
              reason: '${q.id}: Grad erst ab Klasse 4');
        }
        expect(CognitiveProfileGenerator.problems(q), isEmpty, reason: q.id);
      }
    });

    test('Klasse $grade: Merkaufgaben fragen nach der Stelle und erklären', () {
      for (final q in questions
          .where((q) => q.domain == CognitiveDomain.workingMemory)) {
        expect(q.prompt, isNot(contains('Position')), reason: q.id);
        if (q.prompt.contains('Stelle')) {
          // Die Erklärung nennt die gezeigte Folge statt nur
          // „Die Merkfolge wurde nur kurz gezeigt.“
          final digits = q.stimulus!.trim().split(RegExp(r'\s+'));
          expect(q.explanation, contains(digits.join(' – ')), reason: q.id);
          expect(q.explanation, contains(q.correctAnswer), reason: q.id);
        }
      }
    });

    test('Klasse $grade: österreichische und kindgerechte Wortwahl', () {
      for (final q in questions) {
        expect(q.prompt, isNot(contains('Wechselgeld bleibt')), reason: q.id);
        expect(q.prompt, isNot(contains('Praxis')), reason: q.id);
        expect(q.prompt, isNot(contains('verhält sich zu')), reason: q.id);
      }
    });

    test('Klasse $grade: keine Frage doppelt im selben Test (M28)', () {
      for (final domain in CognitiveDomain.values) {
        final keys = [
          for (final q in questions.where((q) => q.domain == domain))
            '${q.prompt}|${q.stimulus}',
        ];
        expect(keys.toSet(), hasLength(keys.length), reason: domain.name);
      }
    });

    test('Klasse $grade: Muster mit wechselnder Lösung (M28)', () {
      final patterns = questions.where((q) =>
          q.domain == CognitiveDomain.patternReasoning &&
          q.prompt.startsWith('Setze'));
      final firstShape = [
        for (final q in patterns)
          q.correctAnswer ==
              q.prompt.split(':').last.trim().split(RegExp(r'\s+')).first,
      ];
      expect(firstShape.contains(false), isTrue,
          reason: 'Lösung ist nicht immer die erste Form');
    });

    test(
        'Klasse $grade: Merkfolgen altersgemäß, Ablenker gleich beginnend (M30)',
        () {
      const longest = <int, int>{1: 4, 2: 5, 3: 5, 4: 6};
      for (final q in questions
          .where((q) => q.domain == CognitiveDomain.workingMemory)) {
        final digits = q.stimulus!.trim().split(RegExp(r'\s+'));
        expect(digits.length, lessThanOrEqualTo(longest[grade]!), reason: q.id);
        if (q.prompt.contains('rückwärts')) {
          final firstDigits = {
            for (final choice in q.choices) choice.split(' – ').first,
          };
          // Wer nur die letzte gezeigte Ziffer behält, kann nicht raten.
          expect(
              q.choices
                  .where((c) => c.split(' – ').first == digits.last)
                  .length,
              greaterThanOrEqualTo(3),
              reason: '${q.id}: ${q.choices} / $firstDigits');
        }
      }
    });

    test('Klasse $grade: Wortpaare mit Ablenkern aus demselben Sachfeld (M29)',
        () {
      for (final q in questions
          .where((q) => q.domain == CognitiveDomain.verbalReasoning)) {
        for (final word in const ['These', 'Hypothese', 'Konsum', 'Synonym']) {
          expect(q.prompt, isNot(contains(word)), reason: q.id);
        }
        expect(CognitiveProfileGenerator.problems(q), isEmpty, reason: q.id);
      }
      // Keine Karte stammt aus einer anderen Frage desselben Tests.
      final answers = questions
          .where((q) => q.domain == CognitiveDomain.verbalReasoning)
          .map((q) => q.correctAnswer)
          .toList();
      for (final q in questions
          .where((q) => q.domain == CognitiveDomain.verbalReasoning)) {
        final foreign = q.choices
            .where((c) => c != q.correctAnswer && answers.contains(c))
            .toList();
        expect(foreign, isEmpty, reason: '${q.id}: ${q.choices}');
      }
    });
  }
}
