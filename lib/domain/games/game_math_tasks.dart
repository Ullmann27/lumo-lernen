import 'dart:math';

import '../../core/math_task_templates.dart';
import 'game_level_model.dart';

/// The fixed game level determines the learning goal, including when an
/// older child revisits it. No fallback to an unrelated classroom topic.
abstract class GameMathTasks {
  static MathConcreteTask starsPath(GameLevel level, int index) {
    final random = Random(level.id * 1000 + index * 17);
    final grade = level.gradeFloor;
    MathConcreteTask numeric(String prompt, int answer, String explanation,
        {String visual = 'dots'}) {
      final choices = <int>{answer};
      for (final delta in [1, -1, 2, -2, 3, -3]) {
        if (answer + delta >= 0) choices.add(answer + delta);
        if (choices.length == 4) break;
      }
      final shuffled = choices.map((n) => '$n').toList()..shuffle(random);
      return MathConcreteTask(
          unit: level.title,
          prompt: prompt,
          answer: '$answer',
          choices: shuffled,
          explanation: explanation,
          visual: visual,
          difficulty: grade,
          promptPattern: 'game-level-${level.id}');
    }

    final id = level.id;
    if (id == 4) {
      final count = 2 + random.nextInt(8);
      return numeric(
          'Wie viele Punkte siehst du?\n${List.filled(count, '●').join(' ')}',
          count,
          'Zähle jeden Punkt einmal. Es sind $count Punkte.');
    }
    if (id == 6) {
      final a = 1 + random.nextInt(10);
      var b = 1 + random.nextInt(10);
      if (a == b) b = a == 10 ? 9 : a + 1;
      final answer = a > b ? '$a' : '$b';
      return MathConcreteTask(
          unit: level.title,
          prompt: 'Welche Menge ist größer: $a oder $b?',
          answer: answer,
          choices: ['$a', '$b'],
          explanation: '$answer ist die größere Zahl.',
          visual: 'compare',
          difficulty: grade,
          promptPattern: 'game-quantity-compare');
    }
    if (id == 9) {
      final a = 1 + random.nextInt(5);
      final b = index.isEven ? a : (a == 5 ? 4 : a + 1);
      return numeric(
          '$a + $b = ?',
          a + b,
          index.isEven
              ? 'Verdopple $a: $a + $a = ${a + a}.'
              : 'Der Nachbartrick: $a + $a = ${a + a}. Passe um ${b - a} an: ${a + b}.');
    }
    if ([41, 42, 46].contains(id)) {
      final row = id == 42
          ? 3
          : id == 41
              ? (index.isEven ? 2 : 5)
              : (index.isEven ? 10 : 4);
      final multiplier = 1 + random.nextInt(10);
      return numeric('$row × $multiplier = ?', row * multiplier,
          '$multiplier Gruppen mit je $row: ${List.filled(multiplier, '$row').join(' + ')} = ${row * multiplier}.',
          visual: 'groups');
    }
    if (id == 48 || id == 49) {
      final unit =
          id == 48 ? 'Schriftliche Addition' : 'Schriftliche Subtraktion';
      final template =
          MathTaskTemplates.templatesForGradeStrict(3, unit: unit).first;
      final task = template.concretize(level.id * 1000 + index * 17);
      // Die Vorlage liefert [Antwort, ...Ablenker]; StarsPath zeigt die
      // Reihenfolge direkt an, sonst waere die oberste Taste immer richtig.
      return MathConcreteTask(
        unit: task.unit,
        prompt: task.prompt,
        answer: task.answer,
        choices: [...task.choices]..shuffle(random),
        explanation: task.explanation,
        visual: task.visual,
        difficulty: task.difficulty,
        promptPattern: task.promptPattern,
      );
    }
    final subtract = [11, 12, 17, 45].contains(id);
    final cap = switch (id) {
      1 || 11 => 5,
      3 => 7,
      16 || 17 => 20,
      39 || 45 => 100,
      _ => 10,
    };
    final a = 1 + random.nextInt(cap - 1);
    final b = subtract ? 1 + random.nextInt(a) : 1 + random.nextInt(cap - a);
    final answer = subtract ? a - b : a + b;
    return numeric(
        '$a ${subtract ? '−' : '+'} $b = ?',
        answer,
        subtract
            ? 'Nimm von $a genau $b weg. Es bleiben $answer.'
            : 'Zu $a kommen $b dazu. Zusammen sind es $answer.',
        visual: subtract ? 'line' : 'dots');
  }

  static GameHouseTask numberHouse(GameLevel level, int index) {
    final random = Random(level.id * 1000 + index * 31);
    final roof = switch (level.id) {
      7 => 7,
      8 => 9,
      15 => 11 + random.nextInt(8),
      19 => (2 + random.nextInt(9)) * 2,
      37 => (10 + random.nextInt(41)) * 2,
      _ => 5 + random.nextInt(6),
    };
    final equalRooms = level.id == 19 || level.id == 37;
    final answer = equalRooms
        ? roof ~/ 2
        : level.id == 15
            ? (roof - 9) + random.nextInt(19 - roof)
            : 1 + random.nextInt(roof - 1);
    final values = <int>{answer};
    for (final delta in [1, -1, 2, -2, 3]) {
      if (answer + delta >= 0 && answer + delta <= roof) {
        values.add(answer + delta);
      }
      if (values.length == 4) break;
    }
    final choices = values.toList()..shuffle(random);
    return GameHouseTask(
        roof: roof,
        visibleRoom: roof - answer,
        answer: answer,
        missingLeft: random.nextBool(),
        choices: choices);
  }
}

class GameHouseTask {
  const GameHouseTask(
      {required this.roof,
      required this.visibleRoom,
      required this.answer,
      required this.missingLeft,
      required this.choices});
  final int roof;
  final int visibleRoom;
  final int answer;
  final bool missingLeft;
  final List<int> choices;
}
