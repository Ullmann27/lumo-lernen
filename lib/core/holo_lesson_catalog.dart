/// Aufgabenkatalog der Holo-Lernräume (Godot-Route `learning` → Szene `holo`).
///
/// Jede Holo-Darstellung gehört zu genau einer geprüften Aufgabe des
/// regulären Generators: Die Textaufgabe „Im Korb liegen … Äpfel“ und die
/// Satzaufgaben (Tunwort im Satz, Satz bauen). Der Katalog liefert die
/// Aufgabe, die Zwillingsaufgabe mit gleicher Struktur und alle Daten, die der
/// Holo-Raum braucht. Antworten, Sterne und Lernprotokoll bleiben in der App.
library;

/// Ein geprüfter Satz für Tunwort- und Satzbau-Aufgaben (Klasse 1/2).
class HoloSentence {
  const HoloSentence({
    required this.words,
    required this.types,
    required this.verbIndex,
    required this.question,
    this.demo = 'none',
  });

  /// Wörter ohne Satzzeichen; der Satz endet mit einem Punkt.
  final List<String> words;

  /// Wortart je Wort: artikel, nomen, adjektiv, verb, andere.
  final List<String> types;
  final int verbIndex;

  /// Die Frage, mit der Lumo zum Tunwort führt („Was tut der Fuchs?“).
  final String question;

  /// Was Lumo vormachen kann: jump, wave, nod oder none.
  final String demo;

  String get sentence => '${words.join(' ')}.';
  String get verb => words[verbIndex];

  Map<String, Object> toPayload() => <String, Object>{
        'sentence': sentence,
        'words': List<String>.unmodifiable(words),
        'types': List<String>.unmodifiable(types),
        'verbIndex': verbIndex,
        'question': question,
        'demo': demo,
      };
}

class HoloLessonCatalog {
  const HoloLessonCatalog._();

  static const String korbStory = 'korb_aepfel';

  /// Heinz' Textaufgabe als Generator-Geschichte (a + b mit Zehnerübergang).
  static String korbPrompt(int a, int b) =>
      'Im Korb liegen $a Äpfel. Lumo legt $b dazu. Wie viele sind es jetzt?';

  static final RegExp _korbPattern = RegExp(
      r'^Im Korb liegen (\d{1,2}) Äpfel\. Lumo legt (\d{1,2}) dazu\. Wie viele sind es jetzt\?$');

  /// Tunwort im Satz (Deutsch Klasse 2, Einheit „Tunwörter“).
  /// Das Tunwort steht an verschiedenen Stellen, damit die Lage nichts verrät.
  static const List<HoloSentence> verbSentences = <HoloSentence>[
    HoloSentence(
        words: <String>['Der', 'kleine', 'Fuchs', 'springt'],
        types: <String>['artikel', 'adjektiv', 'nomen', 'verb'],
        verbIndex: 3,
        question: 'Was tut der Fuchs?',
        demo: 'jump'),
    HoloSentence(
        words: <String>['Die', 'Ente', 'schwimmt', 'im', 'Teich'],
        types: <String>['artikel', 'nomen', 'verb', 'andere', 'nomen'],
        verbIndex: 2,
        question: 'Was tut die Ente?'),
    HoloSentence(
        words: <String>['Lumo', 'winkt', 'den', 'Kindern'],
        types: <String>['nomen', 'verb', 'artikel', 'nomen'],
        verbIndex: 1,
        question: 'Was tut Lumo?',
        demo: 'wave'),
    HoloSentence(
        words: <String>['Mia', 'malt', 'ein', 'buntes', 'Bild'],
        types: <String>['nomen', 'verb', 'artikel', 'adjektiv', 'nomen'],
        verbIndex: 1,
        question: 'Was tut Mia?'),
    HoloSentence(
        words: <String>['Im', 'Garten', 'singt', 'ein', 'Vogel'],
        types: <String>['andere', 'nomen', 'verb', 'artikel', 'nomen'],
        verbIndex: 2,
        question: 'Was tut der Vogel?'),
    HoloSentence(
        words: <String>['Der', 'Hund', 'bellt', 'am', 'Zaun'],
        types: <String>['artikel', 'nomen', 'verb', 'andere', 'nomen'],
        verbIndex: 2,
        question: 'Was tut der Hund?'),
    HoloSentence(
        words: <String>['Opa', 'liest', 'die', 'Zeitung'],
        types: <String>['nomen', 'verb', 'artikel', 'nomen'],
        verbIndex: 1,
        question: 'Was tut Opa?'),
    HoloSentence(
        words: <String>['Die', 'Katze', 'schläft', 'auf', 'dem', 'Sofa'],
        types: <String>['artikel', 'nomen', 'verb', 'andere', 'artikel', 'nomen'],
        verbIndex: 2,
        question: 'Was tut die Katze?'),
    HoloSentence(
        words: <String>['Am', 'Morgen', 'hüpft', 'der', 'Hase'],
        types: <String>['andere', 'nomen', 'verb', 'artikel', 'nomen'],
        verbIndex: 2,
        question: 'Was tut der Hase?',
        demo: 'jump'),
  ];

  /// Satz bauen (Deutsch Klasse 1, Einheit „Erste Sätze“): kurze Sätze
  /// mit lauter verschiedenen Wörtern, damit genau eine Reihenfolge stimmt.
  static const List<HoloSentence> orderSentences = <HoloSentence>[
    HoloSentence(
        words: <String>['Der', 'kleine', 'Fuchs', 'springt'],
        types: <String>['artikel', 'adjektiv', 'nomen', 'verb'],
        verbIndex: 3,
        question: 'Was tut der Fuchs?',
        demo: 'jump'),
    HoloSentence(
        words: <String>['Mia', 'malt', 'ein', 'Bild'],
        types: <String>['nomen', 'verb', 'artikel', 'nomen'],
        verbIndex: 1,
        question: 'Was tut Mia?'),
    HoloSentence(
        words: <String>['Die', 'Ente', 'schwimmt'],
        types: <String>['artikel', 'nomen', 'verb'],
        verbIndex: 2,
        question: 'Was tut die Ente?'),
    HoloSentence(
        words: <String>['Lumo', 'winkt', 'den', 'Kindern'],
        types: <String>['nomen', 'verb', 'artikel', 'nomen'],
        verbIndex: 1,
        question: 'Was tut Lumo?',
        demo: 'wave'),
    HoloSentence(
        words: <String>['Die', 'Katze', 'schläft'],
        types: <String>['artikel', 'nomen', 'verb'],
        verbIndex: 2,
        question: 'Was tut die Katze?'),
    HoloSentence(
        words: <String>['Opa', 'liest', 'die', 'Zeitung'],
        types: <String>['nomen', 'verb', 'artikel', 'nomen'],
        verbIndex: 1,
        question: 'Was tut Opa?'),
    HoloSentence(
        words: <String>['Der', 'Hase', 'hüpft', 'weit'],
        types: <String>['artikel', 'nomen', 'verb', 'adjektiv'],
        verbIndex: 2,
        question: 'Was tut der Hase?',
        demo: 'jump'),
  ];

  static String verbPrompt(HoloSentence item) =>
      'Lies den Satz: „${item.sentence}“\nWelches Wort ist das Tunwort?';

  static String orderPrompt(List<String> shuffledWords) =>
      'Bilde einen Satz aus diesen Wörtern: ${shuffledWords.join(' · ')}';

  static final RegExp _verbPattern =
      RegExp(r'^Lies den Satz: „(.+)“\nWelches Wort ist das Tunwort\?$');
  static const String _orderPrefix = 'Bilde einen Satz aus diesen Wörtern: ';

  /// Vier Antwortkarten für die Textaufgabe: richtige Summe, je eins daneben
  /// und der typische Fehler „nur die Einer“ (a + b − 10).
  static List<int> mathChoices(int a, int b, int seed) {
    final sum = a + b;
    final values = <int>[sum - 1, sum, sum + 1, sum - 10];
    final shift = seed.abs() % values.length;
    return <int>[...values.sublist(shift), ...values.sublist(0, shift)];
  }

  /// Gleiche Struktur, andere Zahlen: wieder ein Zehnerübergang bis 20, aber
  /// eine andere Summe, damit die Lösung nicht abgeschrieben werden kann.
  static (int, int) twinNumbers(int a, int b, int seed) {
    final pairs = <(int, int)>[
      for (var x = 3; x <= 9; x++)
        for (var y = 3; y <= 9; y++)
          if (x + y > 10 && x + y <= 18 && x + y != a + b && x != a) (x, y),
    ];
    return pairs[seed.abs() % pairs.length];
  }

  static bool isBridgingAddition(int a, int b) =>
      a >= 2 && a <= 9 && b >= 2 && b <= 9 && a + b > 10 && a + b <= 20;

  /// Holo-Daten für eine Textaufgabe des Generators, sonst null.
  static Map<String, Object>? wordProblemPayload({
    required String prompt,
    required Object? correctAnswer,
    required List<String> choiceLabels,
    required String taskId,
  }) {
    final match = _korbPattern.firstMatch(prompt);
    if (match == null) return null;
    final a = int.parse(match[1]!);
    final b = int.parse(match[2]!);
    if (!isBridgingAddition(a, b)) return null;
    if ('$correctAnswer' != '${a + b}') return null;
    final choices = <int>[];
    for (final label in choiceLabels) {
      final value = int.tryParse(label.trim());
      if (value == null || value < 0 || value > 40 || choices.contains(value)) {
        return null;
      }
      choices.add(value);
    }
    if (choices.length < 3 || choices.length > 4 || !choices.contains(a + b)) {
      return null;
    }
    final seed = taskId.hashCode;
    final (twinA, twinB) = twinNumbers(a, b, seed);
    return <String, Object>{
      'kind': 'holo_word_problem',
      'story': korbStory,
      'a': a,
      'b': b,
      'prompt': prompt,
      'choices': List<int>.unmodifiable(choices),
      'twin': <String, Object>{
        'story': korbStory,
        'a': twinA,
        'b': twinB,
        'prompt': korbPrompt(twinA, twinB),
        'choices': mathChoices(twinA, twinB, seed ~/ 7),
      },
    };
  }

  /// Holo-Daten für eine Satzaufgabe des Generators, sonst null.
  static Map<String, Object>? sentencePayload({
    required String prompt,
    required Object? correctAnswer,
    required String taskId,
  }) {
    final seed = taskId.hashCode;
    final verb = _verbPattern.firstMatch(prompt);
    if (verb != null) {
      final index =
          verbSentences.indexWhere((item) => item.sentence == verb[1]);
      if (index < 0 || '$correctAnswer' != verbSentences[index].verb) {
        return null;
      }
      final twin = verbSentences[
          (index + 1 + seed.abs() % (verbSentences.length - 1)) %
              verbSentences.length];
      return <String, Object>{
        'kind': 'holo_sentence',
        'mode': 'verb',
        ...verbSentences[index].toPayload(),
        'twin': twin.toPayload(),
      };
    }
    if (prompt.startsWith(_orderPrefix)) {
      final index = orderSentences
          .indexWhere((item) => item.sentence == '$correctAnswer');
      if (index < 0) return null;
      final twin = orderSentences[
          (index + 1 + seed.abs() % (orderSentences.length - 1)) %
              orderSentences.length];
      return <String, Object>{
        'kind': 'holo_sentence',
        'mode': 'order',
        ...orderSentences[index].toPayload(),
        'twin': twin.toPayload(),
      };
    }
    return null;
  }
}
