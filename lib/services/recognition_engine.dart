class RecognitionResult {
  final String type;
  final String answer;
  final String? explanation;

  const RecognitionResult({
    required this.type,
    required this.answer,
    this.explanation,
  });
}

class RecognitionEngine {
  static RecognitionResult recognize(String input) {
    final trimmed = input.trim();

    // Addition: e.g. "12 + 7"
    final addMatch = RegExp(r'^(\d+)\s*\+\s*(\d+)$').firstMatch(trimmed);
    if (addMatch != null) {
      final a = int.parse(addMatch.group(1)!);
      final b = int.parse(addMatch.group(2)!);
      return RecognitionResult(
        type: 'Addition',
        answer: '${a + b}',
        explanation: '$a + $b = ${a + b}',
      );
    }

    // Subtraction: e.g. "18 - 5"
    final subMatch = RegExp(r'^(\d+)\s*-\s*(\d+)$').firstMatch(trimmed);
    if (subMatch != null) {
      final a = int.parse(subMatch.group(1)!);
      final b = int.parse(subMatch.group(2)!);
      return RecognitionResult(
        type: 'Subtraktion',
        answer: '${a - b}',
        explanation: '$a - $b = ${a - b}',
      );
    }

    // Number sequence: e.g. "2, 4, 6, ?"
    final seqMatch =
        RegExp(r'^(\d+),\s*(\d+),\s*(\d+),\s*\?$').firstMatch(trimmed);
    if (seqMatch != null) {
      final a = int.parse(seqMatch.group(1)!);
      final b = int.parse(seqMatch.group(2)!);
      final c = int.parse(seqMatch.group(3)!);
      final diff = b - a;
      if (c - b == diff) {
        return RecognitionResult(
          type: 'Zahlenreihe',
          answer: '${c + diff}',
          explanation:
              'Die Differenz ist $diff. Nächste Zahl: $c + $diff = ${c + diff}',
        );
      }
    }

    // Initial letter: "Anfangsbuchstabe <word>"
    final initMatch =
        RegExp(r'[Aa]nfangsbuchstabe\s+(\w+)').firstMatch(trimmed);
    if (initMatch != null) {
      final word = initMatch.group(1)!;
      return RecognitionResult(
        type: 'Anfangsbuchstabe',
        answer: word[0].toUpperCase(),
        explanation: '"$word" beginnt mit "${word[0].toUpperCase()}".',
      );
    }

    // Rhyme: "Was reimt sich auf <word>"
    final rhymeMatch =
        RegExp(r'[Ww]as reimt sich auf (\w+)', caseSensitive: false)
            .firstMatch(trimmed);
    if (rhymeMatch != null) {
      final word = rhymeMatch.group(1)!.toLowerCase();
      final rhymes = _rhymes[word];
      if (rhymes != null && rhymes.isNotEmpty) {
        return RecognitionResult(
          type: 'Reimwort',
          answer: rhymes.first,
          explanation: '"${rhymes.join(', ')}" reimt sich auf "$word".',
        );
      }
      return const RecognitionResult(
        type: 'Reimwort',
        answer: 'Kein Reimwort gefunden',
        explanation: 'Tipp: Wörter reimen sich, wenn ihre Endsilben gleich sind.',
      );
    }

    // Grade: "Neue Note <subject> <grade>"
    final gradeMatch =
        RegExp(r'[Nn]eue Note\s+(\w+)\s+(\d)').firstMatch(trimmed);
    if (gradeMatch != null) {
      final subject = gradeMatch.group(1)!;
      final grade = gradeMatch.group(2)!;
      return RecognitionResult(
        type: 'Note gespeichert',
        answer: 'Note $grade in $subject gespeichert',
        explanation: 'Lumo hat deine Note gemerkt und passt deine Aufgaben an.',
      );
    }

    return const RecognitionResult(
      type: 'Unbekannt',
      answer: 'Bitte formuliere deine Aufgabe anders.',
      explanation: 'Beispiel: "12 + 7" oder "Was reimt sich auf Haus?"',
    );
  }

  static const Map<String, List<String>> _rhymes = {
    'haus': ['Maus', 'Laus', 'Klaus', 'raus'],
    'ball': ['Stall', 'Hall', 'Schall', 'Tal'],
    'hund': ['bunt', 'rund', 'Mund', 'Stund'],
    'baum': ['Raum', 'Traum', 'Schaum', 'Kaum'],
    'kind': ['Wind', 'blind', 'Rind', 'findet'],
    'schule': ['Stühle', 'Kühle', 'Mühle'],
    'buch': ['Tuch', 'Fluch', 'Brauch', 'Fach'],
    'tag': ['lag', 'Sag', 'mag', 'pfleg'],
  };
}
