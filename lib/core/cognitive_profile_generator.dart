import '../domain/cognitive/cognitive_profile.dart';

class CognitiveProfileGenerator {
  const CognitiveProfileGenerator._();

  static const testVersion = 'lumo-cog-v1-2026-10-06';
  static const questionsPerDomain = 10;
  static const totalQuestions = questionsPerDomain * 5;

  static final _verbalBanks = <int, List<List<String>>>{
    1: <List<String>>[
      ['Welpe', 'Kätzchen', 'Hund verhält sich zu Welpe wie Katze zu …'],
      ['hell', 'dunkel', 'Tag ist meist hell. Nacht ist meist …'],
      ['Obst', 'Gemüse', 'Apfel gehört zu Obst. Karotte gehört zu …'],
      ['fliegt', 'schwimmt', 'Vogel fliegt. Fisch …'],
      ['Fuß', 'Hand', 'Schuh gehört zum Fuß. Handschuh gehört zur …'],
      [
        'kalt',
        'klein',
        'Gegenteil von warm ist kalt. Gegenteil von groß ist …'
      ],
      [
        'Mittwoch',
        'Donnerstag',
        'Montag, Dienstag, Mittwoch – welcher Tag folgt?'
      ],
      ['Farbe', 'Form', 'Rot ist eine Farbe. Kreis ist eine …'],
      [
        'essen',
        'trinken',
        'Bei Hunger können wir essen. Bei Durst können wir …'
      ],
      ['lesen', 'hören', 'Ein Buch kann man lesen. Ein Lied kann man …'],
    ],
    2: <List<String>>[
      ['Honig', 'Milch', 'Biene passt zu Honig. Kuh passt zu …'],
      ['Herbst', 'Winter', 'Frühling, Sommer, Herbst – was folgt?'],
      ['Straße', 'Wasser', 'Auto fährt auf der Straße. Schiff fährt auf …'],
      [
        'laut',
        'schnell',
        'Leise ist das Gegenteil von laut. Langsam ist das Gegenteil von …'
      ],
      ['Brot', 'Möbel', 'Bäcker macht Brot. Tischler macht …'],
      [
        'Wald',
        'Stadt',
        'Viele Bäume bilden einen Wald. Viele Häuser bilden eine …'
      ],
      [
        'Praxis',
        'Schule',
        'Arzt arbeitet in einer Praxis. Lehrer arbeitet in einer …'
      ],
      ['sehen', 'hören', 'Mit dem Auge sehen wir. Mit dem Ohr …'],
      ['Zeit', 'Länge', 'Minute misst Zeit. Meter misst …'],
      [
        'Antwort',
        'Lösung',
        'Auf eine Frage folgt eine Antwort. Zu einem Problem suchen wir eine …'
      ],
    ],
    3: <List<String>>[
      ['Buch', 'Film', 'Kapitel gehört zum Buch. Szene gehört zum …'],
      ['Temperatur', 'Gewicht', 'Thermometer misst Temperatur. Waage misst …'],
      ['Folge', 'Antwort', 'Ursache führt zu Folge. Frage führt zu …'],
      ['Richtung', 'Zeit', 'Kompass zeigt Richtung. Uhr zeigt …'],
      ['blühen', 'sprechen', 'Pflanzen können blühen. Menschen können …'],
      [
        'ähnlich',
        'entgegengesetzt',
        'Synonyme bedeuten ähnlich. Gegenteile bedeuten …'
      ],
      [
        'Buch',
        'Musikstück',
        'Autor schreibt ein Buch. Komponist schafft ein …'
      ],
      ['Raum', 'Zeit', 'Landkarte ordnet Raum. Zeitstrahl ordnet …'],
      [
        'Begründung',
        'Beleg',
        'Ein Argument braucht Begründung. Eine Behauptung braucht einen …'
      ],
      [
        'Beobachtung',
        'Ergebnis',
        'Experiment liefert Beobachtung. Rechnung liefert …'
      ],
    ],
    4: <List<String>>[
      [
        'Abstimmung',
        'Experiment',
        'Demokratie nutzt Abstimmungen. Wissenschaft nutzt …'
      ],
      [
        'Herstellung',
        'Verbrauch',
        'Produktion bedeutet Herstellung. Konsum bedeutet …'
      ],
      [
        'Begründung',
        'Untersuchung',
        'Eine These braucht Begründung. Eine Frage braucht oft eine …'
      ],
      [
        'Umwandlung',
        'Kreislauf',
        'Energie kann umgewandelt werden. Wasser bewegt sich im …'
      ],
      [
        'Karte',
        'Geschichte',
        'Maßstab hilft bei Karten. Zeitachse hilft bei …'
      ],
      [
        'Absatz',
        'Buch',
        'Mehrere Sätze bilden einen Absatz. Mehrere Kapitel bilden ein …'
      ],
      ['Ursache', 'Wirkung', 'Regen ist die Ursache. Nasse Straßen sind die …'],
      [
        'nutzen',
        'schützen',
        'Ressourcen soll man bewusst nutzen. Umwelt soll man …'
      ],
      [
        'Hypothese',
        'Ergebnis',
        'Aus Beobachtungen entsteht eine Hypothese. Durch Prüfung entsteht ein …'
      ],
      [
        'Zufall',
        'Standpunkt',
        'Perspektive bedeutet Blickwinkel. Ein Argument unterstützt einen …'
      ],
    ],
  };

  static List<CognitiveQuestion> forGrade(int grade) {
    final g = grade.clamp(1, 4);
    final out = <CognitiveQuestion>[];
    for (var i = 0; i < questionsPerDomain; i++) {
      out.add(_pattern(g, i));
      out.add(_quantitative(g, i));
      out.add(_verbal(g, i));
      out.add(_spatial(g, i));
      out.add(_memory(g, i));
    }
    return List.unmodifiable(out);
  }

  /// Validates the visible problem, including its arithmetic or spatial rule.
  /// Language analogies are checked against the reviewed finite word bank.
  static List<String> problems(CognitiveQuestion q) {
    final issues = <String>[];
    final canonical = q.choices.map((s) => s.trim().toLowerCase()).toList();
    if (q.id.isEmpty ||
        q.grade < 1 ||
        q.grade > 4 ||
        q.difficulty < 1 ||
        q.difficulty > 5 ||
        q.prompt.trim().isEmpty ||
        q.explanation.trim().isEmpty) {
      issues.add('invalid_metadata');
    }
    if (canonical.length != 4 ||
        canonical.toSet().length != 4 ||
        canonical.any((s) => s.isEmpty) ||
        q.choices.where((s) => s == q.correctAnswer).length != 1) {
      issues.add('ambiguous_choices');
    }
    String? expected;
    switch (q.domain) {
      case CognitiveDomain.patternReasoning:
        if (q.prompt.startsWith('Welche Zahl folgt?')) {
          final values = RegExp(r'\d+')
              .allMatches(q.prompt)
              .map((m) => int.parse(m[0]!))
              .toList();
          if (values.length == 4) {
            final step = values[1] - values[0];
            if (step != 0 &&
                values[2] - values[1] == step &&
                values[3] - values[2] == step) {
              expected = '${values.last + step}';
            }
          }
        } else if (q.prompt.startsWith('Setze das Muster fort:')) {
          final symbols = q.prompt.split(':').last.trim().split(RegExp(r'\s+'));
          if (symbols.isNotEmpty && symbols.last == '?') {
            final shown = symbols.sublist(0, symbols.length - 1);
            for (var period = 1; period <= shown.length ~/ 2; period++) {
              if ([
                for (var i = 0; i < shown.length; i++)
                  shown[i] == shown[i % period]
              ].every((v) => v)) {
                expected = shown[shown.length % period];
                break;
              }
            }
          }
        }
      case CognitiveDomain.quantitativeReasoning:
        final patterns = <String>[
          r'^Lumo hat (\d+) Sterne und bekommt (\d+) dazu\. Wie viele hat er\?$',
          r'^(\d+) gleiche Gruppen haben je (\d+) Punkte\. Wie viele Punkte sind es\?$',
          r'^Rechne im Kopf: \((\d+) \+ (\d+)\) × 2 = \?$',
          r'^(\d+) gleiche Dinge kosten je (\d+) Euro\. Bezahlt werden (\d+) Euro\. Wie viel Wechselgeld bleibt\?$',
        ];
        if (q.grade >= 1 && q.grade <= 4) {
          final match = RegExp(patterns[q.grade - 1]).firstMatch(q.prompt);
          if (match != null) {
            final a = int.parse(match[1]!), b = int.parse(match[2]!);
            expected = '${switch (q.grade) {
              1 => a + b,
              2 => a * b,
              3 => (a + b) * 2,
              _ => int.parse(match[3]!) - a * b,
            }}';
          }
        }
      case CognitiveDomain.verbalReasoning:
        final entries = _verbalBanks[q.grade] ?? const <List<String>>[];
        final matching =
            entries.where((entry) => entry[2] == q.prompt).toList();
        if (matching.length == 1) expected = matching.single[1];
      case CognitiveDomain.spatialReasoning:
        const arrows = ['↑', '→', '↓', '←'];
        final match = RegExp(
                r'^Der Pfeil ([↑→↓←]) wird um (90|180|270)° nach (rechts|links) gedreht\. Wohin zeigt er danach\?$')
            .firstMatch(q.prompt);
        if (match != null) {
          final steps = int.parse(match[2]!) ~/ 90;
          expected = arrows[(arrows.indexOf(match[1]!) +
                  (match[3] == 'rechts' ? steps : -steps)) %
              arrows.length];
        }
      case CognitiveDomain.workingMemory:
        final stimulus = q.stimulus;
        if (stimulus == null ||
            q.stimulusVisibleMs <= 0 ||
            !RegExp(r'^\d(?:\s+\d)+$').hasMatch(stimulus)) {
          issues.add('invalid_memory_stimulus');
          break;
        }
        final digits = stimulus.trim().split(RegExp(r'\s+'));
        final position = RegExp(r'^Welche Zahl stand an Position (\d+)\?$')
            .firstMatch(q.prompt);
        if (position != null) {
          final index = int.parse(position[1]!) - 1;
          if (index >= 0 && index < digits.length) expected = digits[index];
        } else if (q.prompt ==
            'Welche Antwort zeigt die gemerkte Folge rückwärts?') {
          expected = digits.reversed.join(' – ');
        }
    }
    if (expected == null || expected != q.correctAnswer) {
      issues.add('answer_not_supported_by_givens');
    }
    return issues;
  }

  static CognitiveQuestion _pattern(int g, int i) {
    if (i.isEven) {
      final step = g + 1 + (i % 3);
      final start = 1 + g * 2 + i;
      final a = start;
      final b = a + step;
      final c = b + step;
      final d = c + step;
      final answer = d + step;
      return _choice(
        id: 'g${g}_pattern_$i',
        grade: g,
        domain: CognitiveDomain.patternReasoning,
        prompt: 'Welche Zahl folgt?  $a – $b – $c – $d – ?',
        answer: '$answer',
        rawChoices: <String>[
          '$answer',
          '${answer + step}',
          '${answer - 1}',
          '${answer + 1}'
        ],
        explanation: 'Der Abstand ist jedes Mal $step.',
        difficulty: 1 + i ~/ 2,
        rotate: i,
      );
    }
    const shapes = <String>['●', '▲', '■', '◆'];
    final offset = (g + i) % shapes.length;
    final first = shapes[offset];
    final second = shapes[(offset + 1) % shapes.length];
    final third = shapes[(offset + 2) % shapes.length];
    final useThree = g >= 3 || i >= 7;
    final sequence = useThree
        ? '$first $second $third $first $second $third ?'
        : '$first $second $first $second $first ?';
    final answer = useThree ? first : second;
    return _choice(
      id: 'g${g}_pattern_$i',
      grade: g,
      domain: CognitiveDomain.patternReasoning,
      prompt: 'Setze das Muster fort:  $sequence',
      answer: answer,
      rawChoices: shapes,
      explanation: useThree
          ? 'Drei Formen wiederholen sich.'
          : 'Zwei Formen wechseln sich ab.',
      difficulty: 1 + i ~/ 2,
      rotate: i,
    );
  }

  static CognitiveQuestion _quantitative(int g, int i) {
    final base = 2 + i + g;
    if (g == 1) {
      final add = 1 + i % 5;
      final answer = base + add;
      return _choice(
        id: 'g${g}_quant_$i',
        grade: g,
        domain: CognitiveDomain.quantitativeReasoning,
        prompt:
            'Lumo hat $base Sterne und bekommt $add dazu. Wie viele hat er?',
        answer: '$answer',
        rawChoices: <String>[
          '$answer',
          '${answer - 1}',
          '${answer + 1}',
          '${answer + 2}'
        ],
        explanation: '$base + $add = $answer.',
        difficulty: 1 + i ~/ 2,
        rotate: i + 1,
      );
    }
    if (g == 2) {
      final groups = 2 + i % 4;
      final each = 2 + (i + 1) % 5;
      final answer = groups * each;
      return _choice(
        id: 'g${g}_quant_$i',
        grade: g,
        domain: CognitiveDomain.quantitativeReasoning,
        prompt:
            '$groups gleiche Gruppen haben je $each Punkte. Wie viele Punkte sind es?',
        answer: '$answer',
        rawChoices: <String>[
          '$answer',
          '${answer + each}',
          '${answer - each}',
          '${groups + each}',
          // Bei 2 × 2 sind Ergebnis und „Gruppen + je“ beide 4.
          // Echte Rechenfehler anbieten statt Platzhalter zu brauchen.
          '${answer + 1}',
          '${answer - 1}',
        ],
        explanation: '$groups × $each = $answer.',
        difficulty: 1 + i ~/ 2,
        rotate: i + 1,
      );
    }
    if (g == 3) {
      final a = 10 + i * 3;
      final b = 3 + i % 5;
      final answer = (a + b) * 2;
      return _choice(
        id: 'g${g}_quant_$i',
        grade: g,
        domain: CognitiveDomain.quantitativeReasoning,
        prompt: 'Rechne im Kopf: ($a + $b) × 2 = ?',
        answer: '$answer',
        rawChoices: <String>[
          '$answer',
          '${answer - 2}',
          '${answer + 2}',
          '${a + b}'
        ],
        explanation: 'Zuerst addieren, dann verdoppeln.',
        difficulty: 1 + i ~/ 2,
        rotate: i + 1,
      );
    }
    final price = 4 + i;
    final count = 2 + i % 4;
    // Das Wechselgeld wechselt von Aufgabe zu Aufgabe (3 bis 9 Euro); früher war es immer 10.
    final answer = 3 + (i * 2) % 7;
    final paid = price * count + answer;
    return _choice(
      id: 'g${g}_quant_$i',
      grade: g,
      domain: CognitiveDomain.quantitativeReasoning,
      prompt:
          '$count gleiche Dinge kosten je $price Euro. Bezahlt werden $paid Euro. Wie viel Wechselgeld bleibt?',
      answer: '$answer',
      // Typische Fehler: Gesamtpreis statt Wechselgeld, um eins verrechnet.
      rawChoices: <String>[
        '$answer',
        '${price * count}',
        '${answer + 1}',
        '${answer - 1}',
        '${answer + 2}',
      ],
      explanation:
          '$count × $price = ${price * count}. Von $paid bleiben $answer Euro.',
      difficulty: 1 + i ~/ 2,
      rotate: i + 1,
    );
  }

  static CognitiveQuestion _verbal(int g, int i) {
    final banks = _verbalBanks;
    final item = banks[g]![i];
    final answer = item[1];
    final distractorA = item[0];
    final distractorB = i > 0 ? banks[g]![i - 1][1] : banks[g]![9][1];
    final distractorC = i < 9 ? banks[g]![i + 1][1] : banks[g]![0][1];
    return _choice(
      id: 'g${g}_verbal_$i',
      grade: g,
      domain: CognitiveDomain.verbalReasoning,
      prompt: item[2],
      answer: answer,
      rawChoices: <String>[
        answer,
        distractorA,
        distractorB,
        distractorC,
        // Weitere echte Begriffe statt künstlicher Platzhalter, falls
        // eine Antwort in den benachbarten Wortpaaren doppelt vorkommt.
        ...banks[g]!.map((entry) => entry[1]),
      ],
      explanation: 'Die Beziehung muss auf beide Wortpaare gleich passen.',
      difficulty: 1 + i ~/ 2,
      rotate: i + 2,
    );
  }

  static CognitiveQuestion _spatial(int g, int i) {
    const arrows = <String>['↑', '→', '↓', '←'];
    final startIndex = (i + g) % 4;
    final quarterTurns = 1 + (i % (g >= 3 ? 3 : 2));
    final clockwise = i.isEven;
    final delta = clockwise ? quarterTurns : -quarterTurns;
    final answerIndex = (startIndex + delta) % 4;
    final normalized = answerIndex < 0 ? answerIndex + 4 : answerIndex;
    final start = arrows[startIndex];
    final answer = arrows[normalized];
    final degrees = quarterTurns * 90;
    return _choice(
      id: 'g${g}_spatial_$i',
      grade: g,
      domain: CognitiveDomain.spatialReasoning,
      prompt:
          'Der Pfeil $start wird um $degrees° ${clockwise ? 'nach rechts' : 'nach links'} gedreht. Wohin zeigt er danach?',
      answer: answer,
      rawChoices: arrows,
      explanation:
          'Drehe den Pfeil gedanklich um $quarterTurns Vierteldrehung${quarterTurns == 1 ? '' : 'en'}.',
      difficulty: 1 + i ~/ 2,
      rotate: i + 3,
    );
  }

  static CognitiveQuestion _memory(int g, int i) {
    final length = 3 + g + (i ~/ 4);
    final digits = <int>[];
    for (var k = 0; k < length; k++) {
      digits.add(1 + ((g * 7 + i * 3 + k * 5) % 9));
    }
    final stimulus = digits.join('  ');
    if (i.isEven) {
      final position = 1 + (i % length);
      final answer = '${digits[position - 1]}';
      final options = <String>[
        answer,
        '${digits[position % length]}',
        '${digits[(position + 1) % length]}',
        '${1 + (digits[position - 1] + 3) % 9}',
      ];
      return _choice(
        id: 'g${g}_memory_$i',
        grade: g,
        domain: CognitiveDomain.workingMemory,
        prompt: 'Welche Zahl stand an Position $position?',
        answer: answer,
        rawChoices: <String>[
          ...options,
          // Eine Merkaufgabe braucht vier verschiedene echte Ziffern.
          for (var digit = 1; digit <= 9; digit++) '$digit',
        ],
        explanation: 'Die Merkfolge wurde nur kurz gezeigt.',
        difficulty: 1 + i ~/ 2,
        rotate: i,
        stimulus: stimulus,
        stimulusVisibleMs: 3500 + g * 350,
      );
    }
    final reversed = digits.reversed.join(' – ');
    final shifted = <int>[...digits];
    final first = shifted.removeAt(0);
    shifted.add(first);
    final raw = <String>[
      reversed,
      shifted.reversed.join(' – '),
      shifted.join(' – '),
      digits.join(' – '),
    ];
    return _choice(
      id: 'g${g}_memory_$i',
      grade: g,
      domain: CognitiveDomain.workingMemory,
      prompt: 'Welche Antwort zeigt die gemerkte Folge rückwärts?',
      answer: reversed,
      rawChoices: <String>[
        ...raw,
        // Weitere plausible Merkfolgen mit genau einer falschen Ziffer.
        // Die vollständige Sequenz bleibt lesbar, auch bei Dopplungen.
        for (var offset = 1; offset <= 8; offset++)
          '${(digits.last + offset - 1) % 9 + 1} – ${digits.reversed.skip(1).join(' – ')}',
      ],
      explanation: 'Beginne bei der letzten Zahl und gehe zur ersten zurück.',
      difficulty: 1 + i ~/ 2,
      rotate: i,
      stimulus: stimulus,
      stimulusVisibleMs: 3500 + g * 350,
    );
  }

  static CognitiveQuestion _choice({
    required String id,
    required int grade,
    required CognitiveDomain domain,
    required String prompt,
    required String answer,
    required List<String> rawChoices,
    required String explanation,
    required int difficulty,
    required int rotate,
    String? stimulus,
    int stimulusVisibleMs = 0,
  }) {
    // Die richtige Lösung gehört immer in die ersten vier Auswahlfelder.
    // Fehlende Ablenker sind ein Fehler im jeweiligen Aufgabentyp – niemals
    // bedeutungslose Platzhalter für Kinder erzeugen.
    final unique = <String>[answer];
    for (final candidate in rawChoices) {
      if (candidate.trim().isNotEmpty && !unique.contains(candidate)) {
        unique.add(candidate);
      }
    }
    if (unique.length < 4) {
      throw StateError('Weniger als vier echte Antworten für $id');
    }
    final choices = unique.take(4).toList();
    final shift = rotate % choices.length;
    final rotated = <String>[
      ...choices.skip(shift),
      ...choices.take(shift),
    ];
    final question = CognitiveQuestion(
      id: id,
      grade: grade,
      domain: domain,
      prompt: prompt,
      choices: List.unmodifiable(rotated),
      correctAnswer: answer,
      explanation: explanation,
      difficulty: difficulty.clamp(1, 5),
      stimulus: stimulus,
      stimulusVisibleMs: stimulusVisibleMs,
    );
    final issues = problems(question);
    if (issues.isNotEmpty) {
      throw StateError("Unchecked cognitive question $id: $issues");
    }
    return question;
  }
}
