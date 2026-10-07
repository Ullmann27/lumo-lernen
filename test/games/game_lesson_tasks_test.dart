import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/games/game_level_catalog.dart';
import 'package:lumo_lernen/domain/games/game_level_model.dart';
import 'package:lumo_lernen/domain/games/game_lesson_tasks.dart';

void main() {
  final levels = GameLevelCatalog.levels.where((l) => const [
    GameMiniType.numberPath, GameMiniType.wordForest, GameMiniType.mixedQuiz,
  ].contains(l.miniType));
  test('Every new curriculum route has complete, unique, answerable tasks', () {
    expect(levels.length, 26);
    for (final level in levels) {
      for (var i = 0; i < (level.id == 13 ? 10 : 5); i++) {
        final t = GameLessonTasks.task(level, i);
        expect(t.prompt, isNotEmpty, reason: 'Level ${level.id}');
        expect(t.explanation, isNotEmpty);
        expect(t.choices.length, greaterThanOrEqualTo(3));
        expect(t.choices.toSet().length, t.choices.length);
        if (t.orderWords) {
          final words = t.answer.split(' ');
          expect(t.choices.toSet(), words.toSet());
        } else {
          expect(t.choices.where((x) => x == t.answer), hasLength(1));
        }
      }
    }
  });
  test('Number path covers 1–10, missing numbers and fixed counting steps', () {
    final path = GameLevelCatalog.byId(13)!;
    expect(List.generate(10, (i) => GameLessonTasks.task(path, i).answer),
      List.generate(10, (i) => '${i + 1}'));
    for (var i = 0; i < 5; i++) {
      final missing = GameLessonTasks.task(GameLevelCatalog.byId(14)!, i);
      expect(int.parse(missing.answer), missing.numbers.first + 1);
      expect(int.parse(missing.answer), missing.numbers.last - 1);
      final steps = GameLessonTasks.task(GameLevelCatalog.byId(36)!, i);
      final difference = steps.numbers[1] - steps.numbers[0];
      expect(difference, anyOf(2, 5));
      expect(int.parse(steps.answer), steps.numbers.last + difference);
    }
  });
  test('Clock choices agree with actual hands, including half hours', () {
    for (var i = 0; i < 5; i++) {
      final t = GameLessonTasks.task(GameLevelCatalog.byId(32)!, i);
      expect(t.minute, anyOf(0, 30));
      expect(t.answer, '${t.hour}:${t.minute == 0 ? '00' : '30'} Uhr');
    }
  });
  test('Listening words have correct first and last phoneme letters', () {
    for (final id in [21, 22]) {
      for (var i = 0; i < 5; i++) {
        final t = GameLessonTasks.task(GameLevelCatalog.byId(id)!, i);
        expect(t.speech, isNotEmpty);
        expect(t.answer, id == 21 ? t.speech[0].toUpperCase() : t.speech[t.speech.length - 1].toUpperCase());
      }
    }
  });
}
