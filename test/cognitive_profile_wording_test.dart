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
  }
}
