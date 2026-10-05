// ════════════════════════════════════════════════════════════════════════
// WRITING WORD BANK — Phase 5 vom Lumo-Schreibcoach-Plan
// ════════════════════════════════════════════════════════════════════════
// Diktat-Woerter fuer den Wortmodus:
//   - Lumo sagt 'Schreib Mama!'
//   - Das Wort wird NICHT als Text angezeigt (Diktat).
//   - Pro Buchstabe ein leeres Feld auf der Schreiblinie.
//   - Kind schreibt jeden Buchstaben einzeln.
//
// Auswahl orientiert sich am Plan:
//   - Buchstaben muessen vom WritingEngine schon koennen (alle 26 Grossbuchstaben
//     sind in LetterTemplates abgedeckt, daher freie Auswahl).
//   - 4-6 Buchstaben pro Wort, kindgerecht, 1. Klasse.
//   - Klasse 2-4 mit Rechtschreib-Tipps (ie, ck, tz, Doppelkonsonanten).
//   - Nur A-Z: die Buchstaben-Vorlagen kennen noch kein Ä, Ö, Ü, ß.
// ════════════════════════════════════════════════════════════════════════

class WritingWordTask {
  const WritingWordTask({
    required this.id,
    required this.word,
    required this.spokenPrompt,
    this.grade = 1,
    this.hint,
  });

  final String id;

  /// Zielwort - intern bekannt, im UI nicht als Text angezeigt.
  final String word;

  /// Was Lumo dem Kind vorsagt (z.B. 'Schreib das Wort Mama').
  final String spokenPrompt;

  /// Klassenstufe.
  final int grade;

  /// Optionaler Tipp, wenn das Kind ueberhaupt nicht weiterkommt.
  final String? hint;

  /// Buchstaben des Zielworts in Grossschreibung.
  List<String> get letters =>
      word.toUpperCase().split('').where((c) => c.trim().isNotEmpty).toList();

  int get length => letters.length;
}

class WritingWordBank {
  WritingWordBank._();

  static const List<WritingWordTask> _grade1 = [
    WritingWordTask(
      id: 'w1_mama',
      word: 'Mama',
      spokenPrompt: 'Schreib das Wort Mama!',
      hint: 'Mama beginnt mit M wie M wie Mond.',
    ),
    WritingWordTask(
      id: 'w1_papa',
      word: 'Papa',
      spokenPrompt: 'Schreib das Wort Papa!',
      hint: 'Papa beginnt mit P.',
    ),
    WritingWordTask(
      id: 'w1_oma',
      word: 'Oma',
      spokenPrompt: 'Schreib das Wort Oma!',
      hint: 'Oma beginnt mit einem runden O.',
    ),
    WritingWordTask(
      id: 'w1_opa',
      word: 'Opa',
      spokenPrompt: 'Schreib das Wort Opa!',
      hint: 'Opa beginnt mit O.',
    ),
    WritingWordTask(
      id: 'w1_haus',
      word: 'Haus',
      spokenPrompt: 'Schreib das Wort Haus!',
      hint: 'Haus beginnt mit H - zwei Striche und eine Bruecke.',
    ),
    WritingWordTask(
      id: 'w1_hase',
      word: 'Hase',
      spokenPrompt: 'Schreib das Wort Hase!',
      hint: 'Hase beginnt mit H.',
    ),
    WritingWordTask(
      id: 'w1_maus',
      word: 'Maus',
      spokenPrompt: 'Schreib das Wort Maus!',
      hint: 'Maus beginnt mit M.',
    ),
    WritingWordTask(
      id: 'w1_nase',
      word: 'Nase',
      spokenPrompt: 'Schreib das Wort Nase!',
      hint: 'Nase beginnt mit N.',
    ),
    WritingWordTask(
      id: 'w1_sonne',
      word: 'Sonne',
      spokenPrompt: 'Schreib das Wort Sonne!',
      hint: 'Sonne beginnt mit S wie eine geschwungene Schlange.',
    ),
    WritingWordTask(
      id: 'w1_blume',
      word: 'Blume',
      spokenPrompt: 'Schreib das Wort Blume!',
      hint: 'Blume beginnt mit B.',
    ),
    WritingWordTask(
      id: 'w1_limo',
      word: 'Limo',
      spokenPrompt: 'Schreib das Wort Limo!',
      hint: 'Limo beginnt mit L.',
    ),
    WritingWordTask(
      id: 'w1_lumo',
      word: 'Lumo',
      spokenPrompt: 'Schreib das Wort Lumo!',
      hint: 'Lumo wie unser Fuchs - beginnt mit L.',
    ),
  ];

  static const List<WritingWordTask> _grade2 = [
    WritingWordTask(
      id: 'w2_schule',
      word: 'Schule',
      spokenPrompt: 'Schreib das Wort Schule!',
      grade: 2,
      hint: 'Schule beginnt mit Sch – drei Buchstaben für einen Laut.',
    ),
    WritingWordTask(
      id: 'w2_garten',
      word: 'Garten',
      spokenPrompt: 'Schreib das Wort Garten!',
      grade: 2,
      hint: 'Garten: Gar und ten.',
    ),
    WritingWordTask(
      id: 'w2_katze',
      word: 'Katze',
      spokenPrompt: 'Schreib das Wort Katze!',
      grade: 2,
      hint: 'In Katze steckt tz.',
    ),
    WritingWordTask(
      id: 'w2_apfel',
      word: 'Apfel',
      spokenPrompt: 'Schreib das Wort Apfel!',
      grade: 2,
      hint: 'Apfel beginnt mit A, in der Mitte steht pf.',
    ),
    WritingWordTask(
      id: 'w2_kinder',
      word: 'Kinder',
      spokenPrompt: 'Schreib das Wort Kinder!',
      grade: 2,
      hint: 'Kin – der.',
    ),
    WritingWordTask(
      id: 'w2_wolke',
      word: 'Wolke',
      spokenPrompt: 'Schreib das Wort Wolke!',
      grade: 2,
      hint: 'Wol – ke.',
    ),
    WritingWordTask(
      id: 'w2_stern',
      word: 'Stern',
      spokenPrompt: 'Schreib das Wort Stern!',
      grade: 2,
      hint: 'Stern beginnt mit St.',
    ),
    WritingWordTask(
      id: 'w2_winter',
      word: 'Winter',
      spokenPrompt: 'Schreib das Wort Winter!',
      grade: 2,
      hint: 'Win – ter.',
    ),
  ];

  static const List<WritingWordTask> _grade3 = [
    WritingWordTask(
      id: 'w3_freund',
      word: 'Freund',
      spokenPrompt: 'Schreib das Wort Freund!',
      grade: 3,
      hint: 'Freund schreibt man mit eu und d am Ende.',
    ),
    WritingWordTask(
      id: 'w3_fahrrad',
      word: 'Fahrrad',
      spokenPrompt: 'Schreib das Wort Fahrrad!',
      grade: 3,
      hint: 'Fahrrad hat zwei r in der Mitte.',
    ),
    WritingWordTask(
      id: 'w3_spiegel',
      word: 'Spiegel',
      spokenPrompt: 'Schreib das Wort Spiegel!',
      grade: 3,
      hint: 'In Spiegel hört man ein langes i – man schreibt ie.',
    ),
    WritingWordTask(
      id: 'w3_biene',
      word: 'Biene',
      spokenPrompt: 'Schreib das Wort Biene!',
      grade: 3,
      hint: 'Biene mit ie.',
    ),
    WritingWordTask(
      id: 'w3_schnecke',
      word: 'Schnecke',
      spokenPrompt: 'Schreib das Wort Schnecke!',
      grade: 3,
      hint: 'Nach einem kurzen e kommt ck.',
    ),
    WritingWordTask(
      id: 'w3_kirsche',
      word: 'Kirsche',
      spokenPrompt: 'Schreib das Wort Kirsche!',
      grade: 3,
      hint: 'Kir – sche.',
    ),
    WritingWordTask(
      id: 'w3_wiese',
      word: 'Wiese',
      spokenPrompt: 'Schreib das Wort Wiese!',
      grade: 3,
      hint: 'Wiese mit ie.',
    ),
    WritingWordTask(
      id: 'w3_sommer',
      word: 'Sommer',
      spokenPrompt: 'Schreib das Wort Sommer!',
      grade: 3,
      hint: 'Sommer hat zwei m.',
    ),
  ];

  static const List<WritingWordTask> _grade4 = [
    WritingWordTask(
      id: 'w4_bibliothek',
      word: 'Bibliothek',
      spokenPrompt: 'Schreib das Wort Bibliothek!',
      grade: 4,
      hint: 'Bi – bli – o – thek, am Ende th und k.',
    ),
    WritingWordTask(
      id: 'w4_geschichte',
      word: 'Geschichte',
      spokenPrompt: 'Schreib das Wort Geschichte!',
      grade: 4,
      hint: 'Ge – schich – te.',
    ),
    WritingWordTask(
      id: 'w4_elefant',
      word: 'Elefant',
      spokenPrompt: 'Schreib das Wort Elefant!',
      grade: 4,
      hint: 'E – le – fant.',
    ),
    WritingWordTask(
      id: 'w4_kalender',
      word: 'Kalender',
      spokenPrompt: 'Schreib das Wort Kalender!',
      grade: 4,
      hint: 'Ka – len – der.',
    ),
    WritingWordTask(
      id: 'w4_telefon',
      word: 'Telefon',
      spokenPrompt: 'Schreib das Wort Telefon!',
      grade: 4,
      hint: 'Te – le – fon, mit f.',
    ),
    WritingWordTask(
      id: 'w4_abenteuer',
      word: 'Abenteuer',
      spokenPrompt: 'Schreib das Wort Abenteuer!',
      grade: 4,
      hint: 'A – ben – teu – er, mit eu.',
    ),
    WritingWordTask(
      id: 'w4_wasserfall',
      word: 'Wasserfall',
      spokenPrompt: 'Schreib das Wort Wasserfall!',
      grade: 4,
      hint: 'Wasser und Fall: zweimal doppelte Buchstaben.',
    ),
    WritingWordTask(
      id: 'w4_pinguin',
      word: 'Pinguin',
      spokenPrompt: 'Schreib das Wort Pinguin!',
      grade: 4,
      hint: 'Pin – gu – in.',
    ),
  ];

  /// Klasse 1 zuerst, damit bestehende Sitzungen gleich beginnen.
  static const List<WritingWordTask> _all = [..._grade1, ..._grade2, ..._grade3, ..._grade4];

  static List<WritingWordTask> get all => List.unmodifiable(_all);

  static List<WritingWordTask> forGrade(int grade) =>
      List.unmodifiable(_all.where((t) => t.grade == grade));

  static WritingWordTask? byId(String id) {
    for (final t in _all) {
      if (t.id == id) return t;
    }
    return null;
  }
}
