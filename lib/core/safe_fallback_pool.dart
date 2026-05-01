import 'school_exercise_generator.dart';

/// Deterministische, paedagogisch sortierte Fallback-Aufgaben
/// pro Subject und Klasse. Wird vom LegacyLumoTaskAdapter genutzt,
/// wenn der TaskQualityGuard eine generierte Aufgabe ablehnt.
///
/// Rein statisch. Keine Zufallsabhaengigkeit von SystemTime.
/// Antworten sind pro Aufgabe geprueft und liegen IMMER in choices.
class SafeFallbackPool {
  const SafeFallbackPool();

  /// Liefert eine sichere Aufgabe fuer subject + grade.
  /// counter wird vom Caller hochgezaehlt, um Rotation zu garantieren.
  LumoTask pick({
    required String subject,
    required int grade,
    required int counter,
    required String unit,
    required int difficulty,
    String? missionTag,
  }) {
    final pool = _poolFor(subject, grade);
    final entry = pool[counter % pool.length];
    return LumoTask(
      id: 'fallback_${subject}_${grade}_${counter % pool.length}',
      grade: grade,
      subject: subject,
      unit: unit,
      prompt: entry.prompt,
      choices: entry.choices,
      answer: entry.answer,
      explanation: entry.explanation,
      visual: entry.visual,
      difficulty: difficulty,
      missionTag: missionTag ?? 'fallback',
    );
  }

  List<_Fb> _poolFor(String subject, int grade) {
    final boundedGrade = grade.clamp(1, 4).toInt();
    if (subject == 'Mathematik') {
      return _math[boundedGrade] ?? _math[1]!;
    }
    return _deutsch[boundedGrade] ?? _deutsch[1]!;
  }

  static const Map<int, List<_Fb>> _math = {
    1: [
      _Fb('2 + 1 = ?', '3', ['3', '2', '4'], '2 + 1 = 3.', 'dots'),
      _Fb('5 - 2 = ?', '3', ['3', '2', '4'], '5 minus 2 ergibt 3.', 'line'),
      _Fb('Was kommt nach 7?', '8', ['8', '7', '9'], 'Nach 7 kommt 8.', 'sequence'),
      _Fb('3 + 4 = ?', '7', ['7', '6', '8'], '3 plus 4 ergibt 7.', 'dots'),
    ],
    2: [
      _Fb('8 + 5 = ?', '13', ['13', '12', '14'], 'Erst 8 + 2 = 10, dann + 3 = 13.', 'dots'),
      _Fb('14 - 6 = ?', '8', ['8', '7', '9'], '14 minus 6 ergibt 8.', 'line'),
      _Fb('Wie viele Zehner hat 23?', '2', ['2', '3', '23'], '23 hat 2 Zehner und 3 Einer.', 'ten_ones'),
      _Fb('Was ist das Doppelte von 6?', '12', ['12', '11', '13'], 'Doppelt heisst 6 + 6 = 12.', 'dots'),
    ],
    3: [
      _Fb('24 + 18 = ?', '42', ['42', '41', '43'], '24 + 18 = 42.', 'dots'),
      _Fb('50 - 23 = ?', '27', ['27', '26', '28'], '50 minus 23 ergibt 27.', 'line'),
      _Fb('Was ist die Haelfte von 18?', '9', ['9', '8', '10'], 'Haelfte heisst 18 : 2 = 9.', 'dots'),
      _Fb('7 mal 4 = ?', '28', ['28', '27', '29'], '7 mal 4 ergibt 28.', 'sequence'),
    ],
    4: [
      _Fb('36 + 27 = ?', '63', ['63', '62', '64'], '36 + 27 = 63.', 'dots'),
      _Fb('100 - 47 = ?', '53', ['53', '52', '54'], '100 minus 47 ergibt 53.', 'line'),
      _Fb('8 mal 9 = ?', '72', ['72', '71', '73'], '8 mal 9 ergibt 72.', 'sequence'),
      _Fb('Was ist die Haelfte von 60?', '30', ['30', '29', '31'], 'Haelfte heisst 60 : 2 = 30.', 'dots'),
    ],
  };

  static const Map<int, List<_Fb>> _deutsch = {
    1: [
      _Fb('Welches Wort endet mit t?', 'Brot', ['Brot', 'Hund', 'Mama'], 'Brot endet mit t.', 'auto'),
      _Fb('Welches Wort beginnt mit M?', 'Mama', ['Mama', 'Hund', 'Brot'], 'Mama beginnt mit M.', 'auto'),
      _Fb('Wie viele Silben hat Banane?', '3', ['3', '2', '4'], 'Ba-na-ne sind drei Silben.', 'syllables'),
      _Fb('Welcher Artikel passt zu Haus?', 'das', ['das', 'der', 'die'], 'Es heisst das Haus.', 'auto'),
    ],
    2: [
      _Fb('Was reimt sich auf Maus?', 'Haus', ['Haus', 'Hund', 'Mama'], 'Maus und Haus klingen gleich.', 'auto'),
      _Fb('Welches Wort ist ein Tunwort?', 'lesen', ['lesen', 'Hund', 'rot'], 'Lesen sagt, was jemand macht.', 'auto'),
      _Fb('Welcher Satz ist richtig?', 'Der Fuchs liest.', ['Der Fuchs liest.', 'liest der Fuchs', 'Fuchs der liest'], 'Ein Satz beginnt gross und endet mit Punkt.', 'auto'),
      _Fb('Welches Wort endet mit en?', 'kommen', ['kommen', 'Hund', 'Mama'], 'Kommen endet mit en.', 'auto'),
    ],
    3: [
      _Fb('Welche Schreibweise ist richtig?', 'kommen', ['kommen', 'komen', 'komenn'], 'Bei kommen schreibt man mm.', 'auto'),
      _Fb('Welches Wort beschreibt, wie etwas ist?', 'rot', ['rot', 'Hund', 'lesen'], 'Wieworter beschreiben Eigenschaften.', 'auto'),
      _Fb('Welches Zeichen kommt am Ende von: Lumo liest', '.', ['.', '!', '?'], 'Aussagesaetze enden mit Punkt.', 'auto'),
      _Fb('Welcher Artikel passt zu Sonne?', 'die', ['die', 'der', 'das'], 'Es heisst die Sonne.', 'auto'),
    ],
    4: [
      _Fb('Welcher Satz ist richtig geschrieben?', 'Wir spielen heute.', ['Wir spielen heute.', 'wir spielen heute', 'Wir Spielen heute.'], 'Satzanfang gross, sonstige Worter klein.', 'auto'),
      _Fb('Welches Wort ist ein Hauptwort?', 'Schule', ['Schule', 'rot', 'lesen'], 'Hauptworter schreibt man gross.', 'auto'),
      _Fb('Welches Wort wird gross geschrieben?', 'Hund', ['Hund', 'lesen', 'rot'], 'Hauptworter schreibt man gross.', 'auto'),
      _Fb('Was reimt sich auf Sonne?', 'Tonne', ['Tonne', 'Mond', 'Stern'], 'Sonne und Tonne klingen gleich.', 'auto'),
    ],
  };
}

class _Fb {
  const _Fb(this.prompt, this.answer, this.choices, this.explanation, this.visual);

  final String prompt;
  final String answer;
  final List<String> choices;
  final String explanation;
  final String visual;
}
