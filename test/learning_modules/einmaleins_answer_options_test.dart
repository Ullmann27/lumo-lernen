// Every multiplication task offers four different answers between 1 and 100.
// 10 x 10 used to offer only two (90 and 100), because wrong answers above 100
// were dropped and nothing filled the gap.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/learning_modules/einmaleins/einmaleins_screen.dart';

void main() {
  test('every task of the Einmaleins has four different answers up to 100', () {
    for (var a = 1; a <= 10; a++) {
      for (var b = 2; b <= 10; b++) {
        for (var seed = 0; seed < 25; seed++) {
          final answers = einmaleinsAnswers(a, b, math.Random(seed));
          final reason = '$a x $b, seed $seed: $answers';
          expect(answers, hasLength(4), reason: reason);
          expect(answers.toSet(), hasLength(4), reason: reason);
          expect(answers, contains(a * b), reason: reason);
          expect(answers.every((value) => value >= 1 && value <= 100), isTrue,
              reason: reason);
        }
      }
    }
  });

  test('10 x 10 fills up below the result', () {
    final answers = einmaleinsAnswers(10, 10, math.Random(1));
    expect(answers, contains(100));
    expect(answers.where((value) => value < 100), hasLength(3));
  });
}
