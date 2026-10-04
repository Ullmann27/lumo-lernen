import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/games/lumo_cards/learning_question_repository.dart';

void main() {
  testWidgets(
      'Denkpause uses each current class and varies correct answer positions',
      (tester) async {
    final repo = LearningQuestionRepository.instance;
    repo.debugReset();
    await repo.init();
    expect(repo.count, 200);
    final positions = <int>{};
    for (var grade = 1; grade <= 4; grade++) {
      final allowed = grade <= 2
          ? [
              for (final subject in ['math', 'german'])
                ...(jsonDecode(File(
                            'assets/learning_questions/grade${grade}_$subject.json')
                        .readAsStringSync()) as List)
                    .map((q) => (q as Map)['prompt'])
            ].toSet()
          : <Object?>{};
      for (var seed = 0; seed < 100; seed++) {
        final q = repo.randomForGrade(grade, Random(seed));
        expect(q.options.length, greaterThanOrEqualTo(2));
        expect(q.correctIndex, inInclusiveRange(0, q.options.length - 1));
        expect(q.options.toSet().length, q.options.length);
        expect(q.hint, isNotEmpty);
        if (grade <= 2) expect(allowed, contains(q.prompt));
        positions.add(q.correctIndex);
      }
    }
    expect(positions, containsAll([0, 1, 2, 3]));
    repo.debugReset();
  });
}
