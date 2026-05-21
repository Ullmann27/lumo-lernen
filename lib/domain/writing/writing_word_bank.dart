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
//   - Spaeter erweiterbar pro Klassenstufe.
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

  static List<WritingWordTask> get all => List.unmodifiable(_grade1);

  static List<WritingWordTask> forGrade(int grade) =>
      List.unmodifiable(_grade1.where((t) => t.grade == grade));

  static WritingWordTask? byId(String id) {
    for (final t in _grade1) {
      if (t.id == id) return t;
    }
    return null;
  }
}
