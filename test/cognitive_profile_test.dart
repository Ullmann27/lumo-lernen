import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/cognitive_profile_generator.dart';
import 'package:lumo_lernen/core/cognitive_profile_scorer.dart';
import 'package:lumo_lernen/domain/cognitive/cognitive_profile.dart';

void main() {
  for (var grade = 1; grade <= 4; grade++) {
    test('Denkprofil Klasse $grade enthält exakt 50 ausbalancierte Fragen', () {
      final questions = CognitiveProfileGenerator.forGrade(grade);
      expect(questions.length, 50);
      expect(questions.map((q) => q.id).toSet().length, 50);

      for (final domain in CognitiveDomain.values) {
        expect(
          questions.where((q) => q.domain == domain).length,
          10,
          reason: domain.name,
        );
      }

      for (final q in questions) {
        expect(q.grade, grade);
        expect(q.choices.length, 4);
        expect(q.choices.toSet().length, 4);
        expect(q.choices, contains(q.correctAnswer));
        expect(q.difficulty, inInclusiveRange(1, 5));
      }
    });

    test('Denkprofil Klasse $grade zeigt nie Platzhalter-Antwortkarten', () {
      // Früher füllte der Generator fehlende Karten mit „—4—“ auf; der Test auf vier
      // verschiedene Karten blieb dadurch grün. Jede Karte muss eine echte Antwort sein.
      for (final q in CognitiveProfileGenerator.forGrade(grade)) {
        for (final choice in q.choices) {
          expect(choice.trim(), isNotEmpty, reason: q.id);
          expect(RegExp(r'^[—–-]+\s*\d*\s*[—–-]*$').hasMatch(choice), isFalse,
              reason: '${q.id}: Platzhalter „$choice“');
        }
      }
    });

    test('Denkprofil Klasse $grade: Wortanalogien verraten die Lösung nicht', () {
      // Die richtige Antwort darf nicht schon als Wort in der Aufgabenstellung stehen.
      final words = RegExp(r'[A-Za-zÄÖÜäöüß]+');
      for (final q in CognitiveProfileGenerator.forGrade(grade)
          .where((q) => q.domain == CognitiveDomain.verbalReasoning)) {
        final inPrompt =
            words.allMatches(q.prompt).map((m) => m.group(0)!.toLowerCase());
        expect(inPrompt.contains(q.correctAnswer.toLowerCase()), isFalse,
            reason: '${q.id}: „${q.correctAnswer}“ steht schon in der Frage');
      }
    });

    test('Denkprofil Klasse $grade: Rechenaufgaben haben wechselnde Ergebnisse', () {
      final results = CognitiveProfileGenerator.forGrade(grade)
          .where((q) => q.domain == CognitiveDomain.quantitativeReasoning)
          .map((q) => q.correctAnswer)
          .toList();
      expect(results.toSet().length, greaterThanOrEqualTo(7),
          reason: 'Klasse $grade: $results');
    });

    test('Arbeitsgedächtnis Klasse $grade blendet echten Merkstimulus ein', () {
      final memory = CognitiveProfileGenerator.forGrade(grade)
          .where((q) => q.domain == CognitiveDomain.workingMemory)
          .toList();
      expect(memory.length, 10);
      expect(memory.every((q) => q.stimulus != null), isTrue);
      expect(memory.every((q) => q.stimulusVisibleMs >= 3500), isTrue);
    });

    test('Scorer Klasse $grade liefert fünf Bereichswerte statt IQ-Zahl', () {
      final questions = CognitiveProfileGenerator.forGrade(grade);
      final answers = <String, String>{
        for (final q in questions) q.id: q.correctAnswer,
      };
      final result = CognitiveProfileScorer.score(
        id: 'test',
        studentId: 'student',
        grade: grade,
        questions: questions,
        answers: answers,
        finishedAt: DateTime(2026, 10, 6),
        durationMs: 300000,
      );
      expect(result.totalCorrect, 50);
      expect(result.totalQuestions, 50);
      expect(result.domainScores.length, 5);
      expect(result.domainScores.every((s) => s.correct == 10), isTrue);
      expect(result.testVersion, CognitiveProfileGenerator.testVersion);
    });
  }
}
