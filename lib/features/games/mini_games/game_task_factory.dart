import 'dart:math' as math;

import '../../../core/german_task_templates.dart';
import '../../../core/math_task_templates.dart';
import '../../../domain/games/game_level_model.dart';

class GameQuizTask {
  const GameQuizTask({
    required this.unit,
    required this.prompt,
    required this.answer,
    required this.choices,
  });

  final String unit;
  final String prompt;
  final String answer;
  final List<String> choices;
}

abstract class GameTaskFactory {
  GameTaskFactory._();

  static GameQuizTask generate({
    required GameLevel level,
    required int appGrade,
    required int seed,
  }) {
    final clampedGrade = math.max(1, math.min(4, appGrade));
    final normalizedGrade = math.max(level.gradeFloor, clampedGrade);
    if (_usesGermanTemplates(level)) {
      final unit = resolveGermanUnit(level);
      final task = GermanTaskTemplates.generate(
        grade: normalizedGrade,
        unit: unit,
        seed: seed,
      );
      return GameQuizTask(
        unit: task.unit,
        prompt: task.prompt,
        answer: task.answer,
        choices: task.choices,
      );
    }

    final unit = resolveMathUnit(level, grade: normalizedGrade);
    final task = MathTaskTemplates.generate(
      grade: normalizedGrade,
      unit: unit,
      seed: seed,
    );
    return GameQuizTask(
      unit: task.unit,
      prompt: task.prompt,
      answer: task.answer,
      choices: task.choices,
    );
  }

  static String resolveMathUnit(GameLevel level, {required int grade}) {
    final mapped = _mathUnitByLevelId[level.id];
    if (mapped != null) return mapped;
    if (level.miniType == GameMiniType.numberPath) return 'Zahlenstrahl';
    if (level.miniType == GameMiniType.mixedQuiz) return grade >= 3 ? 'Textaufgaben' : 'Plus bis 20';
    if (grade >= 3) return 'Einmaleins';
    return grade >= 2 ? 'Plus bis 20' : 'Plus bis 10';
  }

  static String resolveGermanUnit(GameLevel level) {
    final mapped = _germanUnitByLevelId[level.id];
    if (mapped != null) return mapped;
    switch (level.gradeFloor) {
      case 1:
        return 'Anfangslaute';
      case 2:
        return 'Wortfamilien';
      case 3:
        return 'Wortarten';
      default:
        return 'Satz bauen';
    }
  }

  static bool _usesGermanTemplates(GameLevel level) {
    if (level.miniType == GameMiniType.wordForest) return true;
    return level.miniType == GameMiniType.mixedQuiz &&
        level.subject.toLowerCase() == 'deutsch';
  }

  static const Map<int, String> _mathUnitByLevelId = <int, String>{
    1: 'Plus bis 10',
    2: 'Mengenvergleich',
    3: 'Plus bis 10',
    4: 'Mengenvergleich',
    5: 'Plus bis 10',
    6: 'Mengenvergleich',
    7: 'Plus bis 10',
    8: 'Plus bis 10',
    9: 'Plus bis 10',
    10: 'Plus bis 10',
    11: 'Minus bis 10',
    12: 'Minus bis 10',
    13: 'Zahlenstrahl',
    14: 'Zahlenstrahl',
    15: 'Plus bis 20',
    16: 'Plus bis 20',
    17: 'Minus bis 20',
    18: 'Vergleichen',
    19: 'Verdoppeln und Halbieren',
    20: 'Minus bis 20',
    31: 'Textaufgaben',
    32: 'Uhrzeit',
    33: 'Textaufgaben',
    34: 'Vergleichen',
    35: 'Textaufgaben',
    36: 'Zahlenstrahl',
    37: 'Verdoppeln und Halbieren',
    39: 'Plus bis 100',
    40: 'Textaufgaben',
    41: 'Einmaleins',
    42: 'Einmaleins',
    45: 'Minus bis 100',
    46: 'Einmaleins',
    48: 'Schriftliche Addition',
    49: 'Schriftliche Subtraktion',
    50: 'Textaufgaben',
  };

  static const Map<int, String> _germanUnitByLevelId = <int, String>{
    21: 'Anfangslaute',
    22: 'Endlaute',
    23: 'Silben',
    24: 'Reime',
    25: 'Wort-Bild schreiben',
    26: 'Buchstaben-Lautierung',
    27: 'Artikel',
    28: 'Einzahl und Mehrzahl',
    29: 'Wortfamilien',
    30: 'Alle',
    38: 'Wortarten',
    43: 'Synonyme',
    44: 'Zeitformen',
    47: 'Satz bauen',
  };
}
