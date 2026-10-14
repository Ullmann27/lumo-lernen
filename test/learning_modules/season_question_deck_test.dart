import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/learning_modules/jahreszeiten/season_question_deck.dart';

void main() {
  test('30 unique season questions without successive identical answers',
      () {
    for (var seed = 0; seed < 300; seed++) {
      final deck = SeasonQuestionDeck(random: math.Random(seed)).build();
      expect(deck, hasLength(SeasonQuestionDeck.questionCount));
      expect(deck.map((question) => question.id).toSet(), hasLength(30),
          reason: 'question IDs must be unique in every round (seed $seed)');
      expect(
          deck.map((question) => question.hint ?? question.id).toSet(),
          hasLength(30),
          reason: 'visible questions must not repeat (seed $seed)');
      expect(deck.where((question) => question.isImage), hasLength(4));
      expect(deck.where((question) => !question.isImage), hasLength(26));
      expect(deck.every((question) => question.seasonIndex >= 0 &&
          question.seasonIndex <= 3), isTrue);
      for (var index = 1; index < deck.length; index++) {
        expect(deck[index].seasonIndex, isNot(deck[index - 1].seasonIndex),
            reason: 'same season immediately repeated at task $index, seed $seed');
      }
    }
  });

  test('fixed seed reproduces the same deck for bug reproduction', () {
    final first = SeasonQuestionDeck(random: math.Random(41)).build();
    final second = SeasonQuestionDeck(random: math.Random(41)).build();
    expect(first.map((q) => q.id).toList(),
        second.map((q) => q.id).toList());
  });
}
