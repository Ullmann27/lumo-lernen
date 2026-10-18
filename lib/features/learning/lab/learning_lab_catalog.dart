/// Reviewed, offline learning objects. Answers and model targets are computed
/// locally; no child's text is sent to a provider or used as a diagnosis.
enum LabMode { bridge, word, english, nature, fraction }

class LabTopic {
  const LabTopic(this.id, this.title, this.subject, this.unit, this.minimumGrade,
      this.mode, this.goal, this.problems);

  final String id, title, subject, unit, goal;
  final int minimumGrade;
  final LabMode mode;
  final List<LabProblem> problems;
}

class LabProblem {
  const LabProblem({
    required this.id,
    required this.mode,
    required this.prompt,
    required this.guidedPrompt,
    required this.expected,
    required this.workedExample,
    required this.hints,
    required this.reflection,
    this.start = 0,
    this.addend = 0,
    this.modelTarget = 0,
    this.denominator = 4,
    this.tokens = const [],
    this.tokenOrder = const [],
  });

  final String id, prompt, guidedPrompt, expected, workedExample, reflection;
  final LabMode mode;
  final int start, addend, modelTarget, denominator;
  final List<String> tokens, hints;
  final List<int> tokenOrder;

  String _clean(String value) => value.trim().replaceAll(RegExp(r'\s+'), ' ');

  bool accepts(String value) {
    final input = _clean(value);
    if (mode == LabMode.fraction) {
      return input.replaceAll(' ', '') == expected;
    }
    if (mode == LabMode.english || mode == LabMode.nature) {
      return input.toLowerCase() == expected.toLowerCase();
    }
    return input == expected;
  }

  bool modelAccepts(List<int> selected) =>
      selected.length == tokenOrder.length &&
      List.generate(selected.length, (i) => selected[i] == tokenOrder[i])
          .every((same) => same);

  /// These are task-level observations, never assertions about a child.
  String? errorTag(String answer) {
    if (accepts(answer)) return null;
    final input = _clean(answer);
    if (mode == LabMode.bridge) {
      final number = int.tryParse(input);
      if (number == start) return 'start_instead_of_sum';
      if (number == start + addend - 1 || number == start + addend + 1) {
        return 'one_off';
      }
      if (number == 10) return 'remainder_missing';
    }
    if (mode == LabMode.fraction) {
      final parts = input.replaceAll(' ', '').split('/');
      if (parts.length == 2) {
        if (parts[0] == '$denominator' && parts[1] == '$modelTarget') {
          return 'fraction_reversed';
        }
        if (parts[0] == '$modelTarget' && parts[1] != '$denominator') {
          return 'whole_changed';
        }
      }
    }
    if (mode == LabMode.word && input.toLowerCase() == expected.toLowerCase()) {
      return 'noun_capital';
    }
    if (mode == LabMode.nature &&
        const ['wurzel', 'stängel', 'blatt', 'blüte'].contains(input.toLowerCase())) {
      return 'plant_function';
    }
    return 'needs_check';
  }

  String feedback(String answer) => switch (errorTag(answer)) {
        'start_instead_of_sum' =>
          'Das ist die Startmenge. Bei Plus kommt noch etwas dazu.',
        'one_off' =>
          'Deine Zahl liegt um eins daneben. Prüfe: Der erste Schritt beginnt nach der Startzahl.',
        'remainder_missing' =>
          'Den Zehner hast du erreicht. Jetzt fehlt noch der übrige Teil.',
        'fraction_reversed' =>
          'Die beiden Zahlen sind vertauscht. Unten steht, in wie viele gleich große Teile das Ganze geteilt ist.',
        'whole_changed' =>
          'Die Anzahl aller Teile bleibt gleich. Prüfe die untere Zahl.',
        'noun_capital' =>
          'Die Buchstaben stimmen. Dieses Wort ist ein Namenwort und beginnt groß.',
        'plant_function' =>
          'Das ist ein Pflanzenteil. Vergleiche seine Aufgabe mit der Frage.',
        _ => 'Das passt noch nicht. Vergleiche die Frage mit deinem Lösungsweg. Du kannst dir Hilfe holen.',
      };
}

class LabCatalog {
  LabCatalog._();

  static List<LabTopic> forGrade(int grade) =>
      topics.where((topic) => topic.minimumGrade <= grade).toList();

  static final List<LabTopic> topics = List.unmodifiable([
    LabTopic('bridge', 'Die Zehnerbrücke', 'Mathematik', 'Plus bis 20', 1,
        LabMode.bridge, 'Zahlen zerlegen und über die Zehn rechnen.', [
      _bridge(8, 5), _bridge(7, 5), _bridge(9, 7), _bridge(6, 5),
      _bridge(8, 6), _bridge(7, 6), _bridge(9, 5), _bridge(6, 6),
    ]),
    LabTopic('words', 'Die Wortwerkstatt', 'Deutsch', 'Silben', 1, LabMode.word,
        'Wörter aus Sprechstücken bauen und selbst schreiben.', [
      _word('Banane', ['Ba', 'na', 'ne'], 'ri'),
      _word('Tomate', ['To', 'ma', 'te'], 'la'),
      _word('Rakete', ['Ra', 'ke', 'te'], 'mi'),
      _word('Melone', ['Me', 'lo', 'ne'], 'su'),
      _word('Salami', ['Sa', 'la', 'mi'], 'no'),
      _word('Lawine', ['La', 'wi', 'ne'], 'to'),
    ]),
    LabTopic('english', 'Lumos kleine English-Welt', 'Englisch', 'Alltagswörter',
        2, LabMode.english, 'Einen Satz bauen und neue Wörter selbst erinnern.', [
      _english('cat', 'Katze', 'I see a cat.'),
      _english('dog', 'Hund', 'I see a dog.'),
      _english('apple', 'Apfel', 'I see an apple.'),
      _english('book', 'Buch', 'I see a book.'),
      _english('ball', 'Ball', 'I see a ball.'),
      _english('bird', 'Vogel', 'I see a bird.'),
    ]),
    LabTopic('nature', 'Der Weg des Wassers', 'Sachunterricht', 'Pflanzen', 1,
        LabMode.nature, 'Pflanzenteile mit ihren Aufgaben verbinden.', [
      _nature('root', 'Welcher Teil nimmt Wasser aus dem Boden auf?', 'Wurzel',
          ['Wasser im Boden', 'Wurzel', 'Stängel', 'Blatt']),
      _nature('stem', 'Welcher Teil transportiert Wasser von der Wurzel nach oben?',
          'Stängel', ['Wurzel', 'Stängel', 'Blatt']),
      _nature('leaf', 'Welcher grüne Pflanzenteil nutzt Licht zur Herstellung von Nahrung?',
          'Blatt', ['Sonnenlicht', 'Blatt', 'Nahrung für die Pflanze']),
      _nature('flower', 'Welcher Pflanzenteil kann nach der Bestäubung Früchte und Samen bilden?',
          'Blüte', ['Blüte', 'Bestäubung', 'Frucht mit Samen']),
    ]),
    LabTopic('fractions', 'Das Bruchatelier', 'Mathematik', 'Brüche', 4,
        LabMode.fraction, 'Gleich große Teile als Bruch beschreiben.', [
      _fraction(3, 4), _fraction(2, 3), _fraction(5, 6), _fraction(3, 8),
      _fraction(1, 4), _fraction(2, 5),
    ]),
  ]);

  static LabProblem _bridge(int a, int b) {
    final gap = 10 - a;
    final rest = b - gap;
    return LabProblem(
      id: 'bridge-$a-$b', mode: LabMode.bridge,
      start: a, addend: b, modelTarget: gap,
      prompt: '$a + $b = ? Rechne zuerst bis zur Zehn.',
      guidedPrompt: 'Bei $a + $b: Schiebe nur so viele Plättchen ins Feld, bis die Zehn voll ist.',
      expected: '${a + b}',
      workedExample: '$a braucht $gap bis zur Zehn. Ich zerlege $b in $gap und $rest. '
          '$a + $gap = 10. Dann 10 + $rest = ${a + b}.',
      hints: [
        'Was fehlt von $a bis zur Zehn?',
        'Plus verbindet Mengen. Zerlege die zweite Menge: erst die Zehn voll machen, dann den Rest dazulegen.',
        'Baue die Zehnerbrücke unten. Die freien Felder zeigen den ersten Teil.',
        'Ein anderes Beispiel: 9 + 4. Erst 9 + 1 = 10, dann die übrigen 3: 10 + 3 = 13.',
        'Kleiner Schritt: Zähle die freien Felder in der Zehnerreihe. Genau so viele nimmst du zuerst aus dem Vorrat.',
      ],
      reflection: 'Ich zerlege die zweite Zahl: erst zur Zehn, dann den Rest.',
    );
  }

  static LabProblem _word(String word, List<String> parts, String distractor) =>
      LabProblem(
        id: 'word-${word.toLowerCase()}', mode: LabMode.word,
        prompt: 'Schreibe das Namenwort: ${parts.join(' – ')}.',
        guidedPrompt: 'Baue „$word“ aus seinen Sprechstücken. Ein Baustein bleibt übrig.',
        expected: word,
        tokens: [parts[2], distractor, parts[0], parts[1]],
        tokenOrder: const [2, 3, 0],
        workedExample: 'Ich spreche langsam: ${parts.join(' – ')}. '
            'Ich verbinde die Sprechstücke zu $word. Als Namenwort beginnt es groß.',
        hints: [
          'Sprich die Sprechstücke der Reihe nach.',
          'Eine Silbe ist ein Sprechstück, kein einzelner Buchstabe. Aus den Sprechstücken entsteht ein Wort.',
          'Lege die Bausteine unten in Sprechreihenfolge. Tippe einen gelegten Baustein an, um ihn zurückzunehmen.',
          'Anderes Beispiel: Pa – pa – gei wird Papagei. Das Namenwort beginnt mit einem großen P.',
          'Beginne mit „${parts.first}“. Was hörst du danach? Verbinde dann alle drei Teile.',
        ],
        reflection: 'Ich spreche das Wort in Silben und verbinde sie. Namenwörter beginnen groß.',
      );

  static LabProblem _english(String word, String german, String sentence) {
    final article = word == 'apple' ? 'an' : 'a';
    return LabProblem(
      id: 'english-$word', mode: LabMode.english,
      prompt: 'Was heißt „$german“ auf Englisch? Schreibe nur das englische Wort.',
      guidedPrompt: 'Baue diesen Satz: „$sentence“ Ein Wort brauchst du nicht.',
      expected: word,
      tokens: [word, 'see', 'you', article, 'I'],
      tokenOrder: const [4, 1, 3, 0],
      workedExample: '„$german“ heißt „$word“. „$sentence“ bedeutet: Ich sehe '
          '${article == 'an' ? 'einen Apfel' : 'das Tier oder den Gegenstand'}. '
          'Ich beginne mit I, dann see, dann $article $word.',
      hints: [
        'Erinnere dich an das letzte Wort im Satz.',
        'I see bedeutet „Ich sehe“. Danach steht, was ich sehe.',
        'Baue den englischen Satz unten. Sprich ihn langsam mit.',
        'Ein anderes Beispiel: I see a house. House heißt Haus.',
        'Das gesuchte Wort beginnt mit „${word[0]}“. Sage das Wort, bevor du es schreibst.',
      ],
      reflection: 'Ich nutze einen kurzen Satz als Erinnerung und rufe das Wort danach selbst ab.',
    );
  }

  static LabProblem _nature(String id, String prompt, String answer, List<String> path) {
    final tokens = [...path.reversed, 'Stein'];
    return LabProblem(
      id: 'nature-$id', mode: LabMode.nature, prompt: prompt, expected: answer,
      guidedPrompt: 'Ordne den Weg: ${path.join(' → ')}. „Stein“ gehört nicht dazu.',
      tokens: tokens,
      tokenOrder: List.generate(path.length, (i) => path.length - 1 - i),
      workedExample: '${path.join(' → ')}. '
          '${answer == 'Wurzel' ? 'Die Wurzel nimmt Wasser aus der Erde auf.' : answer == 'Stängel' ? 'Der Stängel leitet Wasser nach oben.' : answer == 'Blatt' ? 'Das Blatt nutzt Licht, Wasser und Luft, um Nahrung herzustellen.' : 'Aus einer bestäubten Blüte können Früchte mit Samen entstehen.'}',
      hints: [
        'Frage dich: Wo passiert das in einer Pflanze?',
        'Jeder Pflanzenteil hat eine Aufgabe. Verbinde den Ort mit seiner Funktion.',
        'Ordne die Modellbausteine unten und verfolge den Weg Schritt für Schritt.',
        'Anderes Beispiel: Eine Wurzel hält eine Pflanze im Boden fest. Die Form hilft bei der Aufgabe.',
        'Gesucht ist ${answer == 'Wurzel' ? 'der Teil unter der Erde' : answer == 'Stängel' ? 'die Verbindung nach oben' : answer == 'Blatt' ? 'eine grüne Fläche am Stängel' : 'der Teil vor der Fruchtbildung'}.',
      ],
      reflection: 'Ich verbinde Pflanzenteile mit ihren Aufgaben und prüfe den Weg im Modell.',
    );
  }

  static LabProblem _fraction(int n, int d) => LabProblem(
        id: 'fraction-$n-$d', mode: LabMode.fraction,
        modelTarget: n, denominator: d,
        prompt: 'Ein Ganzes hat $d gleich große Teile. $n davon sind markiert. Schreibe den Bruch mit /.',
        guidedPrompt: 'Markiere $n von $d gleich großen Teilen.',
        expected: '$n/$d',
        workedExample: 'Das Ganze besteht aus $d gleich großen Teilen. Das ist die untere Zahl. '
            '$n Teile sind markiert. Das ist die obere Zahl: $n/$d.',
        hints: [
          'Zähle erst alle Teile, dann die markierten.',
          'Der Nenner unten beschreibt die Teilung des Ganzen. Der Zähler oben zählt die ausgewählten Teile.',
          'Markiere die Teile im Modell. Alle Sektoren sind gleich groß.',
          'Anderes Beispiel: 1 von 2 gleich großen Teilen ist 1/2. Ein markierter Teil steht über zwei Teilen insgesamt.',
          'Schreibe zuerst die Zahl der markierten Teile, dann / und dann die Anzahl aller Teile.',
        ],
        reflection: 'Unten steht die Teilung des Ganzen, oben stehen die markierten Teile.',
      );
}
