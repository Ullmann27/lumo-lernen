import 'school_exercise_generator.dart';

/// Deterministische, pädagogisch sortierte Fallback-Aufgaben pro Fach und Klasse.
/// Wird genutzt, wenn der Generator oder die Qualitätsprüfung eine Aufgabe ablehnt.
///
/// Regeln:
/// - Antwort liegt immer in choices.
/// - Keine doppelten Antwortkarten.
/// - Rechtschreibung nutzt echte Schreibvarianten, keine fremden korrekten Wörter.
/// - Englisch und Sachunterricht fallen nicht mehr pauschal auf Deutsch zurück.
/// - Das ausdrücklich gewählte Fach bleibt erhalten. Ein Themenname allein
///   darf keine Deutsch-Aufgabe in Englisch oder Sachunterricht umdeuten.
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
    final normalizedSubject = _normalizeSubject(subject, unit: unit);
    final pool = normalizedSubject == 'Logik'
        ? _logic[unit] ?? _logic['Muster']!
        : _poolFor(normalizedSubject, grade);
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

  String _normalizeSubject(String subject, {required String unit}) {
    return switch (subject) {
      'Mathematik' => 'Mathematik',
      'Englisch' => 'Englisch',
      'Sachunterricht' => 'Sachunterricht',
      'Logik' => 'Logik',
      'Deutsch' || 'Lesen' || 'Schreiben' || 'Rechtschreibung' => subject,
      _ => throw ArgumentError.value(subject, 'subject', 'Unknown learning subject'),
    };
  }

  List<_Fb> _poolFor(String subject, int grade) {
    final boundedGrade = grade.clamp(1, 4).toInt();
    if (subject == 'Mathematik') return _math[boundedGrade] ?? _math[1]!;
    if (subject == 'Englisch') return _english[boundedGrade] ?? _english[1]!;
    if (subject == 'Sachunterricht') return _science[boundedGrade] ?? _science[1]!;
    return _deutsch[boundedGrade] ?? _deutsch[1]!;
  }

  static const Map<String, List<_Fb>> _logic = {
    'Muster': [
      _Fb(
        'Das Muster wiederholt sich immer gleich: Kreis – Dreieck – Kreis – Dreieck – Kreis – ? Welche Form folgt?',
        'Dreieck', ['Dreieck', 'Kreis', 'Quadrat'],
        'Die Gruppe Kreis – Dreieck wiederholt sich. Nach Kreis folgt Dreieck.',
        'pattern', unit: 'Muster',
      ),
      _Fb(
        'Das Muster wiederholt sich immer gleich: Quadrat – Stern – Quadrat – Stern – ? Welche Form folgt?',
        'Quadrat', ['Stern', 'Quadrat', 'Kreis'],
        'Die Gruppe Quadrat – Stern wiederholt sich. Nach Stern folgt Quadrat.',
        'pattern', unit: 'Muster',
      ),
    ],
    'Zahlenmuster': [
      _Fb(
        'Gehe jedes Mal gleich viele Schritte weiter: 2 – 4 – 6 – 8 – ? Welche Zahl folgt?',
        '10', ['10', '9', '12'], 'Jeder Abstand ist 2. Auf 8 folgt 10.',
        'auto', unit: 'Zahlenmuster',
      ),
    ],
    'Reihenfolge': [
      _Fb('Von links nach rechts stehen Lumo, Mia und Ben. Wer steht in der Mitte?',
        'Mia', ['Lumo', 'Mia', 'Ben'], 'Die mittlere Figur ist Mia.',
        'auto', unit: 'Reihenfolge'),
    ],
    'Schlussfolgern': [
      _Fb('Drei Figuren stehen nebeneinander. Lumo steht links von Mia. Mia steht links von Ben. Wer steht ganz rechts?',
        'Ben', ['Lumo', 'Mia', 'Ben'], 'Von links nach rechts: Lumo – Mia – Ben. Ben steht ganz rechts.',
        'auto', unit: 'Schlussfolgern'),
    ],
    'Regeln kombinieren': [
      _Fb('Welche Zahl erfüllt alle drei Regeln: größer als 10, kleiner als 18 und gerade?',
        '14', ['14', '10', '13', '18'], 'Nur die Antwort 14 erfüllt alle drei Regeln.',
        'auto', unit: 'Regeln kombinieren'),
    ],
  };

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
      _Fb('Welche Schreibweise ist richtig?', 'Geschichte', ['Geschichte', 'Geschihte', 'Geschichhte'], 'Geschichte schreibt man mit ch.', 'auto', unit: 'Rechtschreibung'),
      _Fb('Welches Wort ist ein Wiewort?', 'mutig', ['mutig', 'Mut', 'mögen'], 'Ein Wiewort sagt, wie jemand oder etwas ist: mutig.', 'auto'),
      _Fb('Wie heißt „laufen“ in der Mitvergangenheit? Er …', 'lief', ['lief', 'läuft', 'laufte'], 'laufen – er lief.', 'auto'),
      _Fb('Welcher Satz ist ein Fragesatz?', 'Kommst du morgen mit?', ['Kommst du morgen mit?', 'Ich komme morgen mit.', 'Komm morgen mit!'], 'Ein Fragesatz endet mit einem Fragezeichen.', 'auto'),
    ],
    4: [
      _Fb('Welcher Satz ist richtig geschrieben?', 'Wir spielen heute im Garten.', ['Wir spielen heute im Garten.', 'wir spielen heute im Garten.', 'Wir Spielen heute im garten.'], 'Den Satzanfang und Namenwörter schreibt man groß, Tunwörter klein.', 'auto'),
      _Fb('Welches Wort ist ein Namenwort (Nomen)?', 'Freundschaft', ['Freundschaft', 'freundlich', 'befreunden'], 'Wörter auf -schaft sind Namenwörter. Du schreibst sie groß.', 'auto'),
      _Fb('Welche Schreibweise ist richtig?', 'Bibliothek', ['Bibliothek', 'Bibliotek', 'Biblijothek'], 'Bibliothek schreibt man mit th.', 'auto', unit: 'Rechtschreibung'),
      _Fb('Welches Wort passt? „Ich weiß, ___ du recht hast.“', 'dass', ['dass', 'das', 'des'], 'Hier passt weder „dieses“ noch „welches“. „Dass“ verbindet zwei Sätze.', 'auto'),
    ],
  };

  static const Map<int, List<_Fb>> _english = {
    1: [
      _Fb('Was heißt red auf Deutsch?', 'rot', ['rot', 'blau', 'grün'], 'red heißt rot.', 'auto', unit: 'Farben'),
      _Fb('Was heißt cat auf Deutsch?', 'Katze', ['Katze', 'Hund', 'Vogel'], 'cat heißt Katze.', 'auto', unit: 'Tiere'),
      _Fb('Was heißt one auf Deutsch?', 'eins', ['eins', 'zwei', 'drei'], 'one heißt eins.', 'auto', unit: 'Zahlen'),
    ],
    2: [
      _Fb('Was heißt blue auf Deutsch?', 'blau', ['blau', 'rot', 'gelb'], 'blue heißt blau.', 'auto', unit: 'Farben'),
      _Fb('Was heißt dog auf Deutsch?', 'Hund', ['Hund', 'Katze', 'Fisch'], 'dog heißt Hund.', 'auto', unit: 'Tiere'),
      _Fb('Was heißt book auf Deutsch?', 'Buch', ['Buch', 'Stift', 'Tasche'], 'book heißt Buch.', 'auto', unit: 'Schulsachen'),
    ],
    3: [
      _Fb('Was heißt ruler auf Deutsch?', 'Lineal', ['Lineal', 'Radiergummi', 'Heft'], 'ruler heißt Lineal.', 'auto', unit: 'Schulsachen'),
      _Fb('Was heißt weather auf Deutsch?', 'Wetter', ['Wetter', 'Wasser', 'Winter'], 'weather heißt Wetter.', 'auto', unit: 'Wetter'),
      _Fb('Was heißt breakfast auf Deutsch?', 'Frühstück', ['Frühstück', 'Mittagessen', 'Abendessen'], 'breakfast heißt Frühstück.', 'auto', unit: 'Essen'),
    ],
    4: [
      _Fb('Was heißt Wednesday auf Deutsch?', 'Mittwoch', ['Mittwoch', 'Montag', 'Donnerstag'], 'Wednesday heißt Mittwoch.', 'auto', unit: 'Wochentage'),
      _Fb('Was heißt swim auf Deutsch?', 'schwimmen', ['schwimmen', 'springen', 'singen'], 'swim heißt schwimmen.', 'auto', unit: 'Verben'),
      _Fb('Was heißt Austria auf Deutsch?', 'Österreich', ['Österreich', 'Australien', 'Deutschland'], 'Austria heißt Österreich.', 'auto', unit: 'Länder'),
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
      _Fb('Was passiert mit Wasser, wenn die Sonne es stark erwärmt?', 'Es verdunstet.', ['Es verdunstet.', 'Es gefriert.', 'Es wird mehr.'], 'Warmes Wasser verdunstet und steigt als Wasserdampf auf.', 'auto', unit: 'Wasserkreislauf'),
      _Fb('Was ist die Landeshauptstadt von Tirol?', 'Innsbruck', ['Innsbruck', 'Salzburg', 'Bregenz'], 'Innsbruck ist die Landeshauptstadt von Tirol.', 'auto', unit: 'Bundesländer Österreichs'),
      _Fb('Wie viele Tage hat ein Schaltjahr?', '366', ['366', '365', '360'], 'Ein Schaltjahr hat einen Tag mehr: den 29. Februar.', 'auto', unit: 'Zeit und Kalender'),
    ],
    4: [
      _Fb('Was braucht ein einfacher Stromkreis?', 'Batterie, Kabel und Lampe', ['Batterie, Kabel und Lampe', 'nur ein Kabel', 'nur eine Lampe'], 'Der Strom fließt von der Batterie durch Kabel und Lampe zurück.', 'auto', unit: 'Stromkreise'),
      _Fb('Welcher Fluss fließt durch Wien?', 'Donau', ['Donau', 'Inn', 'Mur'], 'Die Donau fließt durch Wien.', 'auto', unit: 'Geografie Österreich'),
      _Fb('Was steht am Anfang einer Nahrungskette?', 'eine Pflanze', ['eine Pflanze', 'ein Fuchs', 'ein Adler'], 'Pflanzen stehen am Anfang: Gras – Hase – Fuchs.', 'auto', unit: 'Ökosysteme'),
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
