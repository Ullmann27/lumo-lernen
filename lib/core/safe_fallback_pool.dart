import 'school_exercise_generator.dart';

/// Deterministische, pädagogisch sortierte Fallback-Aufgaben pro Fach und Klasse.
/// Wird genutzt, wenn der Generator oder die Qualitätsprüfung eine Aufgabe ablehnt.
///
/// Regeln:
/// - Antwort liegt immer in choices.
/// - Keine doppelten Antwortkarten.
/// - Rechtschreibung nutzt echte Schreibvarianten, keine fremden korrekten Wörter.
/// - Englisch und Sachunterricht fallen nicht mehr auf Deutsch zurück.
class SafeFallbackPool {
  const SafeFallbackPool();

  LumoTask pick({
    required String subject,
    required int grade,
    required int counter,
    required String unit,
    required int difficulty,
    String? missionTag,
  }) {
    final normalizedSubject = _normalizeSubject(subject);
    final pool = _poolFor(normalizedSubject, grade);
    final entry = pool[counter % pool.length];
    return LumoTask(
      id: 'fallback_${normalizedSubject}_${grade}_${counter % pool.length}',
      grade: grade,
      subject: normalizedSubject,
      unit: entry.unit ?? unit,
      prompt: entry.prompt,
      choices: entry.choices,
      answer: entry.answer,
      explanation: entry.explanation,
      visual: entry.visual,
      difficulty: difficulty,
      missionTag: missionTag ?? 'fallback',
    );
  }

  String _normalizeSubject(String subject) {
    return switch (subject) {
      'Mathematik' => 'Mathematik',
      'Englisch' => 'Englisch',
      'Sachunterricht' => 'Sachunterricht',
      'Lesen' || 'Schreiben' || 'Rechtschreibung' || 'Deutsch' => subject,
      _ => 'Deutsch',
    };
  }

  List<_Fb> _poolFor(String subject, int grade) {
    final boundedGrade = grade.clamp(1, 4).toInt();
    if (subject == 'Mathematik') return _math[boundedGrade] ?? _math[1]!;
    if (subject == 'Englisch') return _english[boundedGrade] ?? _english[1]!;
    if (subject == 'Sachunterricht') return _science[boundedGrade] ?? _science[1]!;
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
      _Fb('Was ist das Doppelte von 6?', '12', ['12', '11', '13'], 'Doppelt heißt 6 + 6 = 12.', 'dots'),
    ],
    3: [
      _Fb('24 + 18 = ?', '42', ['42', '41', '43'], '24 + 18 = 42.', 'dots'),
      _Fb('50 - 23 = ?', '27', ['27', '26', '28'], '50 minus 23 ergibt 27.', 'line'),
      _Fb('Was ist die Hälfte von 18?', '9', ['9', '8', '10'], 'Hälfte heißt 18 : 2 = 9.', 'dots'),
      _Fb('7 mal 4 = ?', '28', ['28', '27', '29'], '7 mal 4 ergibt 28.', 'sequence'),
    ],
    4: [
      _Fb('36 + 27 = ?', '63', ['63', '62', '64'], '36 + 27 = 63.', 'dots'),
      _Fb('100 - 47 = ?', '53', ['53', '52', '54'], '100 minus 47 ergibt 53.', 'line'),
      _Fb('8 mal 9 = ?', '72', ['72', '71', '73'], '8 mal 9 ergibt 72.', 'sequence'),
      _Fb('Was ist die Hälfte von 60?', '30', ['30', '29', '31'], 'Hälfte heißt 60 : 2 = 30.', 'dots'),
    ],
  };

  static const Map<int, List<_Fb>> _deutsch = {
    1: [
      _Fb('Welche Schreibweise ist richtig?', 'Ball', ['Ball', 'Bal', 'Bahl'], 'Ball schreibt man mit ll.', 'auto', unit: 'Rechtschreibung'),
      _Fb('Welches Wort beginnt mit M?', 'Mama', ['Mama', 'Brot', 'Igel'], 'Mama beginnt mit M.', 'auto'),
      _Fb('Wie viele Silben hat Banane?', '3', ['3', '2', '4'], 'Ba-na-ne sind drei Silben.', 'syllables'),
      _Fb('Welcher Artikel passt zu Haus?', 'das', ['das', 'der', 'die'], 'Es heißt das Haus.', 'auto'),
    ],
    2: [
      _Fb('Was reimt sich auf Maus?', 'Haus', ['Haus', 'Hund', 'Kerze'], 'Maus und Haus klingen am Ende gleich.', 'auto'),
      _Fb('Welches Wort ist ein Tunwort?', 'lesen', ['lesen', 'Hund', 'rot'], 'Lesen sagt, was jemand macht.', 'auto'),
      _Fb('Welcher Satz ist richtig?', 'Der Fuchs liest.', ['Der Fuchs liest.', 'liest der Fuchs', 'Fuchs der liest'], 'Ein Satz beginnt groß und endet mit Punkt.', 'auto'),
      _Fb('Welche Schreibweise ist richtig?', 'kommen', ['kommen', 'komen', 'komenn'], 'Kommen schreibt man mit mm.', 'auto', unit: 'Rechtschreibung'),
    ],
    3: [
      _Fb('Welche Schreibweise ist richtig?', 'Sonne', ['Sonne', 'Sone', 'Sohne'], 'Sonne schreibt man mit nn.', 'auto', unit: 'Rechtschreibung'),
      _Fb('Welches Wort beschreibt, wie etwas ist?', 'rot', ['rot', 'Hund', 'lesen'], 'Ein Wiewort beschreibt eine Eigenschaft.', 'auto'),
      _Fb('Welches Zeichen kommt am Ende von: Lumo liest', '.', ['.', '!', '?'], 'Ein Aussagesatz endet mit Punkt.', 'auto'),
      _Fb('Welcher Artikel passt zu Sonne?', 'die', ['die', 'der', 'das'], 'Es heißt die Sonne.', 'auto'),
    ],
    4: [
      _Fb('Welcher Satz ist richtig geschrieben?', 'Wir spielen heute.', ['Wir spielen heute.', 'wir spielen heute', 'Wir Spielen heute.'], 'Satzanfang groß, sonstige Wörter klein.', 'auto'),
      _Fb('Welches Wort ist ein Hauptwort?', 'Schule', ['Schule', 'rot', 'lesen'], 'Hauptwörter schreibt man groß.', 'auto'),
      _Fb('Welche Schreibweise ist richtig?', 'Freund', ['Freund', 'Froind', 'Freunt'], 'Freund schreibt man mit eu und d.', 'auto', unit: 'Rechtschreibung'),
      _Fb('Was reimt sich auf Sonne?', 'Tonne', ['Tonne', 'Mond', 'Stern'], 'Sonne und Tonne klingen am Ende gleich.', 'auto'),
    ],
  };

  static const Map<int, List<_Fb>> _english = {
    1: [
      _Fb('Was heißt red auf Deutsch?', 'Rot', ['Rot', 'Blau', 'Grün'], 'Red heißt Rot.', 'auto', unit: 'Farben'),
      _Fb('Was heißt cat auf Deutsch?', 'Katze', ['Katze', 'Hund', 'Vogel'], 'Cat heißt Katze.', 'auto', unit: 'Tiere'),
      _Fb('Was heißt one auf Deutsch?', 'eins', ['eins', 'zwei', 'drei'], 'One heißt eins.', 'auto', unit: 'Zahlen'),
    ],
    2: [
      _Fb('Was heißt blue auf Deutsch?', 'Blau', ['Blau', 'Rot', 'Gelb'], 'Blue heißt Blau.', 'auto', unit: 'Farben'),
      _Fb('Was heißt dog auf Deutsch?', 'Hund', ['Hund', 'Katze', 'Fisch'], 'Dog heißt Hund.', 'auto', unit: 'Tiere'),
      _Fb('Was heißt book auf Deutsch?', 'Buch', ['Buch', 'Stift', 'Tasche'], 'Book heißt Buch.', 'auto', unit: 'Schulsachen'),
    ],
    3: [
      _Fb('Was heißt green auf Deutsch?', 'Grün', ['Grün', 'Blau', 'Rot'], 'Green heißt Grün.', 'auto', unit: 'Farben'),
      _Fb('Was heißt mother auf Deutsch?', 'Mutter', ['Mutter', 'Vater', 'Kind'], 'Mother heißt Mutter.', 'auto', unit: 'Familie'),
      _Fb('Was heißt hand auf Deutsch?', 'Hand', ['Hand', 'Fuß', 'Kopf'], 'Hand heißt Hand.', 'auto', unit: 'Körper'),
    ],
    4: [
      _Fb('Was heißt yellow auf Deutsch?', 'Gelb', ['Gelb', 'Grün', 'Blau'], 'Yellow heißt Gelb.', 'auto', unit: 'Farben'),
      _Fb('Was heißt schoolbag auf Deutsch?', 'Schultasche', ['Schultasche', 'Bleistift', 'Buch'], 'Schoolbag heißt Schultasche.', 'auto', unit: 'Schulsachen'),
      _Fb('Was heißt goodbye auf Deutsch?', 'Auf Wiedersehen', ['Auf Wiedersehen', 'Hallo', 'Danke'], 'Goodbye heißt Auf Wiedersehen.', 'auto', unit: 'Begrüßung'),
    ],
  };

  static const Map<int, List<_Fb>> _science = {
    1: [
      _Fb('Welches Tier macht Honig?', 'Biene', ['Biene', 'Katze', 'Hund'], 'Bienen machen Honig.', 'auto', unit: 'Tiere'),
      _Fb('Womit sehen wir?', 'Augen', ['Augen', 'Ohren', 'Hände'], 'Wir sehen mit den Augen.', 'auto', unit: 'Körper'),
      _Fb('Wann fällt oft Schnee?', 'Winter', ['Winter', 'Sommer', 'Frühling'], 'Im Winter fällt oft Schnee.', 'auto', unit: 'Jahreszeiten'),
    ],
    2: [
      _Fb('Was braucht eine Pflanze zum Wachsen?', 'Wasser', ['Wasser', 'Stein', 'Schuh'], 'Pflanzen brauchen Wasser und Licht.', 'auto', unit: 'Pflanzen'),
      _Fb('Bei welcher Ampelfarbe darf man gehen?', 'Grün', ['Grün', 'Rot', 'Gelb'], 'Bei Grün darf man gehen.', 'auto', unit: 'Verkehr'),
      _Fb('Was fällt aus Wolken?', 'Regen', ['Regen', 'Sand', 'Blätter'], 'Regen fällt aus Wolken.', 'auto', unit: 'Wetter'),
    ],
    3: [
      _Fb('Welches Tier lebt oft im Wasser?', 'Fisch', ['Fisch', 'Hund', 'Biene'], 'Fische leben im Wasser.', 'auto', unit: 'Tiere'),
      _Fb('Welcher Teil der Pflanze ist meist grün?', 'Blatt', ['Blatt', 'Wurzel', 'Stein'], 'Blätter sind meist grün.', 'auto', unit: 'Pflanzen'),
      _Fb('Wie viele Tage hat eine Woche?', '7', ['7', '5', '12'], 'Eine Woche hat sieben Tage.', 'auto', unit: 'Zeit und Kalender'),
    ],
    4: [
      _Fb('Wozu dient ein Fahrradhelm?', 'Schützen', ['Schützen', 'Kochen', 'Lesen'], 'Ein Helm schützt den Kopf.', 'auto', unit: 'Verkehr'),
      _Fb('Was zeigt ein Thermometer?', 'Temperatur', ['Temperatur', 'Uhrzeit', 'Länge'], 'Ein Thermometer zeigt die Temperatur.', 'auto', unit: 'Wetter'),
      _Fb('Was kommt nach dem Frühling?', 'Sommer', ['Sommer', 'Winter', 'Herbst'], 'Nach dem Frühling kommt der Sommer.', 'auto', unit: 'Jahreszeiten'),
    ],
  };
}

class _Fb {
  const _Fb(this.prompt, this.answer, this.choices, this.explanation, this.visual, {this.unit});

  final String prompt;
  final String answer;
  final List<String> choices;
  final String explanation;
  final String visual;
  final String? unit;
}
