import 'dart:math';

import '../../core/math_task_templates.dart';
import 'game_level_model.dart';

/// The fixed game level determines the learning goal, including when an
/// older child revisits it. No fallback to an unrelated classroom topic.
abstract class GameMathTasks {
  /// [legacyCards] liefert die Antwortkarten wie bis Build 2082 (Ablenker in
  /// Klasse 1 bis 20, sonst unbegrenzt). Nur zum Wiederherstellen von Runden,
  /// die vor der Begrenzung auf den Zahlenraum gespeichert wurden.
  static MathConcreteTask starsPath(GameLevel level, int index,
      {bool legacyCards = false}) {
    if (level.miniType != GameMiniType.starsPath || index < 0) {
      throw ArgumentError('Diese Stufe gehört nicht zum Rechenpfad.');
    }
    final task = _starsPath(level, index, legacyCards);
    if (!isValidStarsTask(level, task)) {
      throw StateError('Die Rechenaufgabe wurde nicht freigegeben.');
    }
    return task;
  }

  /// Independent arithmetic/quantity verification before a variant is shown.
  /// An unrelated fallback must never silently change the level's goal.
  static bool isValidStarsTask(GameLevel level, MathConcreteTask task) {
    if (task.prompt.trim().isEmpty ||
        task.explanation.trim().isEmpty ||
        task.choices.length < 2 ||
        task.choices.toSet().length != task.choices.length ||
        task.choices.where((value) => value == task.answer).length != 1) {
      return false;
    }
    final answer = int.tryParse(task.answer);
    if (answer == null || answer < 0) return false;
    if (level.id == 4) {
      return RegExp('●').allMatches(task.prompt).length == answer;
    }
    final operands = RegExp(r'\d+')
        .allMatches(task.prompt)
        .map((match) => int.parse(match.group(0)!))
        .toList();
    if (operands.length != 2) return false;
    final a = operands[0], b = operands[1];
    if (level.id == 6) return a != b && answer == max(a, b);
    if (task.prompt.contains('+')) return answer == a + b;
    if (task.prompt.contains('−') || task.prompt.contains('-'))
      return answer == a - b;
    if (task.prompt.contains('×') || task.prompt.contains('·'))
      return answer == a * b;
    return false;
  }

  static MathConcreteTask _starsPath(
      GameLevel level, int index, bool legacyCards) {
    final random = Random(level.id * 1000 + index * 17);
    final grade = level.gradeFloor;
    final id = level.id;
    // Auch die falschen Karten bleiben im Zahlenraum der Stufe. Früher
    // zeigte „Minus bis 10“ z. B. 15 bei 8 − 7 (Plus statt Minus) und
    // „Plus bis 100“ Karten bis 200.
    final range = switch (id) {
      1 || 11 => 5,
      3 => 7,
      16 || 17 => 20,
      39 || 45 || 41 || 42 || 46 => 100,
      _ => 10,
    };
    // Die Karten kommen aus derselben Quelle wie beim Üben: Die Lösung
    // liegt der Größe nach an wechselnder Stelle, falsche Karten sind
    // typische Fehler. Früher war sie immer die zweitkleinste Karte.
    MathConcreteTask numeric(String prompt, int answer, String explanation,
        {String visual = 'dots', List<int> typical = const <int>[]}) {
      final shuffled = MathTaskTemplates.numberChoices(
          answer, random.nextInt(1 << 30),
          typical: typical,
          // Bis Build 2082 waren alle betroffenen Stufen außer Klasse 1
          // höher eingestuft; ihre Karten waren dort unbegrenzt.
          max: legacyCards ? (grade == 1 ? 20 : null) : range);
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
              : 'Der Nachbartrick: $a + $a = ${a + a}. Passe um ${b - a} an: ${a + b}.',
          typical: MathTaskTemplates.additionErrors(a, b));
    }
    if ([41, 42, 46].contains(id)) {
      final row = id == 42
          ? 3
          : id == 41
              ? (index.isEven ? 2 : 5)
              : (index.isEven ? 10 : 4);
      final multiplier = 1 + random.nextInt(10);
      return numeric('$row × $multiplier = ?', row * multiplier,
          // Dieselbe Deutung wie im Einmaleins-Modul und in den Tipps:
          // a × b heißt „a-mal die b“.
          '$row × $multiplier heißt $row-mal die $multiplier: ${List.filled(row, '$multiplier').join(' + ')} = ${row * multiplier}.',
          visual: 'groups',
          typical: <int>[
            row * (multiplier - 1),
            row * (multiplier + 1),
            (row - 1) * multiplier,
            (row + 1) * multiplier,
            row + multiplier,
          ]);
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
    final cap = range;
    final a = 1 + random.nextInt(cap - 1);
    final b = subtract ? 1 + random.nextInt(a) : 1 + random.nextInt(cap - a);
    final answer = subtract ? a - b : a + b;
    return numeric(
        '$a ${subtract ? '−' : '+'} $b = ?',
        answer,
        subtract
            ? 'Nimm von $a genau $b weg. Es bleiben $answer.'
            : 'Zu $a kommen $b dazu. Zusammen sind es $answer.',
        visual: subtract ? 'line' : 'dots',
        typical: subtract
            ? MathTaskTemplates.subtractionErrors(a, b)
            : MathTaskTemplates.additionErrors(a, b));
  }

  static GameHouseTask numberHouse(GameLevel level, int index) {
    if (level.miniType != GameMiniType.numberHouse || index < 0) {
      throw ArgumentError('Diese Stufe gehört nicht zum Rechenhaus.');
    }
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
    // Typisch: das sichtbare Zimmer oder die Dachzahl nennen, sich verzählen.
    final choices = <int>[
      for (final value in MathTaskTemplates.numberChoices(
          answer, random.nextInt(1 << 30),
          typical: <int>[roof - answer, roof, answer - 1, answer + 1],
          max: roof))
        int.parse(value),
    ];
    final task = GameHouseTask(
        roof: roof,
        visibleRoom: roof - answer,
        answer: answer,
        missingLeft: random.nextBool(),
        choices: choices);
    if (!task.isValid) throw StateError('Das Rechenhaus ist nicht lösbar.');
    return task;
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

  bool get isValid =>
      roof >= 1 &&
      roof <= 100 &&
      visibleRoom >= 0 &&
      answer >= 0 &&
      visibleRoom + answer == roof &&
      choices.length >= 2 &&
      choices.toSet().length == choices.length &&
      choices.every((value) => value >= 0 && value <= roof) &&
      choices.where((value) => value == answer).length == 1;
}
