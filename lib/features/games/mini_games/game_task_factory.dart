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
    final normalizedGrade = math.max(level.gradeFloor, appGrade.clamp(1, 4) as int);
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
    final title = level.title.toLowerCase();
    if (level.miniType == GameMiniType.numberPath) {
      if (title.contains('vergleich')) return 'Vergleichen';
      return 'Zahlenstrahl';
    }
    if (title.contains('uhrzeit')) return 'Uhrzeit';
    if (title.contains('einkaufen')) return 'Geld wechseln';
    if (title.contains('schriftliches plus')) return 'Schriftliche Addition';
    if (title.contains('schriftliches minus')) return 'Schriftliche Subtraktion';
    if (title.contains('plus bis 100')) return 'Plus bis 100';
    if (title.contains('minus bis 100')) return 'Minus bis 100';
    if (title.contains('einmaleins')) return 'Einmaleins';
    if (title.contains('verdoppeln') || title.contains('halbieren')) {
      return 'Verdoppeln und Halbieren';
    }
    if (title.contains('textaufgabe') || title.contains('sach')) return 'Textaufgaben';
    if (title.contains('minus bis 20')) return 'Minus bis 20';
    if (title.contains('plus bis 20')) return 'Plus bis 20';
    if (title.contains('minus')) return grade >= 2 ? 'Minus bis 20' : 'Minus bis 10';
    if (title.contains('plus')) {
      if (grade >= 3) return 'Plus bis 100';
      return grade >= 2 ? 'Plus bis 20' : 'Plus bis 10';
    }
    if (grade >= 3) return 'Einmaleins';
    return grade >= 2 ? 'Plus bis 20' : 'Plus bis 10';
  }

  static String resolveGermanUnit(GameLevel level) {
    final title = level.title.toLowerCase();
    if (title.contains('anfangslaut')) return 'Anfangslaute';
    if (title.contains('endlaut')) return 'Endlaute';
    if (title.contains('silb')) return 'Silben';
    if (title.contains('reim')) return 'Reime';
    if (title.contains('wort und bild') || title.contains('wort-bild')) {
      return 'Wort-Bild schreiben';
    }
    if (title.contains('artikel')) return 'Artikel';
    if (title.contains('einzahl') || title.contains('mehrzahl')) return 'Einzahl und Mehrzahl';
    if (title.contains('wortfamil')) return 'Wortfamilien';
    if (title.contains('wortart')) return 'Wortarten';
    if (title.contains('synonym')) return 'Synonyme';
    if (title.contains('zeitform')) return 'Zeitformen';
    if (title.contains('satz')) return 'Satz bauen';
    return 'Alle';
  }

  static bool _usesGermanTemplates(GameLevel level) {
    if (level.miniType == GameMiniType.wordForest) return true;
    return level.miniType == GameMiniType.mixedQuiz &&
        level.subject.toLowerCase() == 'deutsch';
  }
}
