import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/domain/learning/learning_dna_engine.dart';

void main() {
  const engine = LearningDnaEngine();

  for (final grade in [1, 2, 3, 4]) {
    test('new grade $grade profile has no invented strengths or weaknesses',
        () {
      final dna = engine.compute(state: LumoSessionState(grade: grade));
      expect(dna.strengths, isEmpty);
      expect(dna.weaknesses, isEmpty);
      expect(dna.totalCorrect, 0);
      expect(dna.totalIncorrect, 0);
      expect(dna.recentProgress.toLowerCase(), contains('keine antwortdaten'));
      expect(dna.totalSessions, isNull);
    });
  }

  test('untimed legacy counters cannot create competency or current-day claims',
      () {
    final dna = engine.compute(
        state: LumoSessionState(
      grade: 4,
      solved: {'Mathematik': 999},
      weakSkills: {'Deutsch:Artikel': 8},
      stars: 800,
    ));
    expect(dna.strengths, isEmpty);
    expect(dna.weaknesses, isEmpty);
    expect(dna.totalCorrect + dna.totalIncorrect, 0);
    expect(dna.recentProgress, isNot(contains('Heute')));
    expect(dna.recentProgress, isNot(contains('Woche')));
    expect(dna.frustrationSignals, isEmpty);
  });
}
