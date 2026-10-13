import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_brain.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/domain/learning/learning_dna_engine.dart';

void main() {
  test('Lumo tips never recommend grade-one basics to grade four', () {
    for (var i = 0; i < 80; i++) {
      final reply = LumoBrain.instance.ask(
        'Was lernen wir heute?',
        grade: 4,
      );
      expect(reply.text, isNot(contains('Plus bis 10')));
      expect(reply.text, isNot(contains('Minus bis 10')));
      expect(reply.text, isNot(contains('Buchstaben nachspuren')));
      expect(reply.text, isNot(contains('Woerter lesen')));
    }
  });

  test('learning DNA does not invent strengths without current-grade evidence',
      () {
    final state = LumoSessionState(
      grade: 4,
      subject: 'Mathematik',
      solved: const <String, int>{
        'Plus bis 10': 25,
        'Minus bis 10': 18,
      },
    );

    final dna = const LearningDnaEngine().compute(state: state);

    expect(dna.strengths, isEmpty);
    expect(
      Curriculum.unitsForGrade(
        'Mathematik',
        4,
        currentGradeOnly: true,
      ).map(Curriculum.prettifyUnit),
      contains(dna.nextRubric),
    );
    expect(dna.nextRubric, isNot('Plus bis 10 mit Zaehlbild'));
  });

  test('learning DNA reports a solved current-grade topic as evidence', () {
    final units = Curriculum.unitsForGrade(
      'Mathematik',
      4,
      currentGradeOnly: true,
    );
    expect(units, isNotEmpty);
    final unit = units.first;
    final state = LumoSessionState(
      grade: 4,
      subject: 'Mathematik',
      solved: <String, int>{
        'Plus bis 10': 30,
        unit: 6,
      },
    );

    final dna = const LearningDnaEngine().compute(state: state);

    expect(dna.strengths, isNotEmpty);
    expect(dna.strengths.first.skillLabel, Curriculum.prettifyUnit(unit));
    expect(dna.strengths.any((e) => e.skillLabel == 'Plus bis 10'), isFalse);
  });
}
