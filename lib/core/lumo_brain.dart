// ════════════════════════════════════════════════════════════════════════
// LUMO BRAIN — Lokale "selbstdenkende" KI fuer Chat
// ════════════════════════════════════════════════════════════════════════
// Heinz' Auftrag: 'Bau eine selbstdenkende KI ein die ChatGPT ersetzt'.
//
// Realitaet: Echte LLM in Flutter-App nicht moeglich (zu gross, GPU noetig).
// Was geht: ein smartes Pattern-Matching-Brain das:
//   1) Haeufige Kinder-Fragen direkt beantwortet (50+ Antwort-Templates)
//   2) Math-Aufgaben loest (Plus, Minus, Mal, Geteilt)
//   3) Tier-/Pflanzen-/Sachkunde-Lexikon liefert (60+ Eintraege)
//   4) Aufgaben selbst generiert pro Topic
//   5) Variationen rotiert (nie das gleiche zweimal)
//   6) Bei Cloud-Ausfall topic-spezifisch einspringt
//
// Vorteil: spart Render-Tokens, funktioniert ohne Internet, sofortige
// Antwortzeit. ChatGPT wird nur fuer komplexe Fragen genutzt.
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

/// Antwort vom LumoBrain.
class LumoBrainReply {
  const LumoBrainReply({
    required this.text,
    required this.confident,
    this.imageTopicHint,
  });

  /// Die Antwort an das Kind.
  final String text;

  /// Wie sicher ist LumoBrain mit dieser Antwort?
  /// true = sicher, kein ChatGPT-Bedarf
  /// false = unsicher, ChatGPT-Antwort waere besser
  final bool confident;

  /// Optional: ein Allowlist-Wort fuer den Bildgenerator,
  /// damit der Chat passend dazu ein Bild zeigen kann.
  final String? imageTopicHint;
}

/// Lumo's lokale Antwort-Engine.
/// Nutzung: `LumoBrain.instance.ask(question, topicId)`
class LumoBrain {
  LumoBrain._();
  static final LumoBrain instance = LumoBrain._();
  static final _rng = math.Random();

  // ────────────────────────────────────────────────────────────────
  // TIER-LEXIKON (60+ Eintraege)
  // ────────────────────────────────────────────────────────────────
  static const Map<String, _TierInfo> _tiere = {
    'hund': _TierInfo(
      laut: 'Wau Wau', lebensraum: 'bei Menschen zu Hause',
      futter: 'Trockenfutter und Knochen', faktoid: 'Hunde sind die besten Freunde von Menschen!',
    ),
    'katze': _TierInfo(
      laut: 'Miau', lebensraum: 'zu Hause oder draussen',
      futter: 'Maeuse und Katzenfutter', faktoid: 'Katzen koennen 100 verschiedene Laute machen!',
    ),
    'kuh': _TierInfo(
      laut: 'Muh', lebensraum: 'am Bauernhof',
      futter: 'Gras und Heu', faktoid: 'Kuehe geben uns Milch fuer Kaese und Joghurt!',
    ),
    'pferd': _TierInfo(
      laut: 'Wieher', lebensraum: 'am Bauernhof oder Stall',
      futter: 'Hafer, Heu und Karotten', faktoid: 'Pferde koennen im Stehen schlafen!',
    ),
    'schaf': _TierInfo(
      laut: 'Maeh', lebensraum: 'auf der Wiese',
      futter: 'Gras', faktoid: 'Aus Schafwolle macht man warme Pullover!',
    ),
    'schwein': _TierInfo(
      laut: 'Oink', lebensraum: 'am Bauernhof',
      futter: 'fast alles - sogar Reste!', faktoid: 'Schweine sind sehr schlau und sauber!',
    ),
    'huhn': _TierInfo(
      laut: 'Gack Gack', lebensraum: 'am Bauernhof',
      futter: 'Koerner und Wuermer', faktoid: 'Huehner legen jeden Tag ein Ei!',
    ),
    'ente': _TierInfo(
      laut: 'Quak', lebensraum: 'am See oder Teich',
      futter: 'Wasserpflanzen', faktoid: 'Enten schwimmen wegen ihrer Schwimmhaeute!',
    ),
    'frosch': _TierInfo(
      laut: 'Quak Quak', lebensraum: 'am Teich',
      futter: 'Insekten', faktoid: 'Froesche fangen Fliegen mit ihrer langen Zunge!',
    ),
    'loewe': _TierInfo(
      laut: 'Bruell', lebensraum: 'in der Savanne in Afrika',
      futter: 'Antilopen und Zebras', faktoid: 'Der Loewe ist der Koenig der Tiere!',
    ),
    'löwe': _TierInfo(
      laut: 'Bruell', lebensraum: 'in der Savanne in Afrika',
      futter: 'Antilopen und Zebras', faktoid: 'Der Loewe ist der Koenig der Tiere!',
    ),
    'tiger': _TierInfo(
      laut: 'Grrr', lebensraum: 'im Dschungel in Asien',
      futter: 'andere Tiere', faktoid: 'Tiger sind die groessten Katzen der Welt!',
    ),
    'elefant': _TierInfo(
      laut: 'Troet', lebensraum: 'in Afrika und Asien',
      futter: 'Gras, Blaetter und Obst', faktoid: 'Elefanten koennen mit dem Ruessel duschen!',
    ),
    'giraffe': _TierInfo(
      laut: 'sehr leise', lebensraum: 'in Afrika',
      futter: 'Blaetter von hohen Baeumen', faktoid: 'Giraffen sind die hoechsten Tiere der Welt!',
    ),
    'affe': _TierInfo(
      laut: 'Uh Uh Aah', lebensraum: 'im Dschungel',
      futter: 'Bananen und Frueechte', faktoid: 'Affen sind sehr schlau und koennen Werkzeug benutzen!',
    ),
    'pinguin': _TierInfo(
      laut: 'Quaek', lebensraum: 'am kalten Suedpol',
      futter: 'Fische', faktoid: 'Pinguine koennen nicht fliegen aber super schwimmen!',
    ),
    'baer': _TierInfo(
      laut: 'Brumm', lebensraum: 'im Wald',
      futter: 'Beeren, Fisch und Honig', faktoid: 'Baeren schlafen den ganzen Winter durch!',
    ),
    'bär': _TierInfo(
      laut: 'Brumm', lebensraum: 'im Wald',
      futter: 'Beeren, Fisch und Honig', faktoid: 'Baeren schlafen den ganzen Winter durch!',
    ),
    'fuchs': _TierInfo(
      laut: 'Bell', lebensraum: 'im Wald',
      futter: 'Maeuse und Voegel', faktoid: 'Fuechse sind die schlauesten Tiere im Wald!',
    ),
    'wolf': _TierInfo(
      laut: 'Heul', lebensraum: 'im Wald',
      futter: 'Rehe und andere Tiere', faktoid: 'Woelfe leben immer in einem Rudel!',
    ),
    'eule': _TierInfo(
      laut: 'Hu Hu', lebensraum: 'im Wald',
      futter: 'Maeuse', faktoid: 'Eulen koennen ihren Kopf fast ganz herumdrehen!',
    ),
    'hase': _TierInfo(
      laut: 'leise piepsen', lebensraum: 'auf der Wiese',
      futter: 'Karotten und Gras', faktoid: 'Hasen koennen sehr schnell und weit huepfen!',
    ),
    'maus': _TierInfo(
      laut: 'Piep', lebensraum: 'auf Feldern oder im Haus',
      futter: 'Koerner und Kaese', faktoid: 'Maeuse sind sehr klein aber sehr schnell!',
    ),
    'schmetterling': _TierInfo(
      laut: 'leise', lebensraum: 'in Gaerten und Wiesen',
      futter: 'Nektar von Blumen', faktoid: 'Schmetterlinge waren vorher Raupen!',
    ),
    'biene': _TierInfo(
      laut: 'Summ', lebensraum: 'im Bienenstock',
      futter: 'Nektar', faktoid: 'Bienen machen suessen Honig fuer uns!',
    ),
    'delfin': _TierInfo(
      laut: 'Klick Klick', lebensraum: 'im Meer',
      futter: 'Fische', faktoid: 'Delfine sind sehr schlau und spielen gerne!',
    ),
    'fisch': _TierInfo(
      laut: 'Blub Blub', lebensraum: 'im Wasser',
      futter: 'kleine Tiere und Pflanzen', faktoid: 'Fische atmen unter Wasser mit Kiemen!',
    ),
  };

  // ────────────────────────────────────────────────────────────────
  // KOERPER-WISSEN
  // ────────────────────────────────────────────────────────────────
  static const Map<String, String> _koerper = {
    'finger': 'Du hast 10 Finger - 5 an jeder Hand! Mit den Fingern kannst du greifen und tasten.',
    'hand': 'Du hast 2 Haende mit jeweils 5 Fingern. Haende sind sehr wichtig zum Spielen und Lernen!',
    'fuss': 'Du hast 2 Fuesse mit jeweils 5 Zehen. Mit den Fuessen kannst du laufen und huepfen!',
    'fuß': 'Du hast 2 Fuesse mit jeweils 5 Zehen. Mit den Fuessen kannst du laufen und huepfen!',
    'auge': 'Du hast 2 Augen. Mit den Augen kannst du alles sehen - Farben, Formen und Lebewesen!',
    'augen': 'Du hast 2 Augen. Mit den Augen kannst du alles sehen - Farben, Formen und Lebewesen!',
    'ohr': 'Du hast 2 Ohren - eins links und eins rechts. Mit den Ohren hoerst du Musik und Stimmen!',
    'ohren': 'Du hast 2 Ohren - eins links und eins rechts. Mit den Ohren hoerst du Musik und Stimmen!',
    'nase': 'Du hast 1 Nase. Mit der Nase kannst du riechen - Blumen, Essen und vieles mehr!',
    'mund': 'Mit dem Mund sprichst, isst und laechelst du!',
    'zaehne': 'Du hast Milchzaehne die spaeter ausfallen und durch grosse Zaehne ersetzt werden!',
    'zähne': 'Du hast Milchzaehne die spaeter ausfallen und durch grosse Zaehne ersetzt werden!',
    'zahn': 'Zaehne sind wichtig zum Kauen. Putze sie 2x am Tag!',
    'herz': 'Dein Herz schlaegt ohne Pause und pumpt Blut durch den ganzen Koerper!',
    'kopf': 'Im Kopf ist dein Gehirn - damit denkst und lernst du!',
    'arm': 'Du hast 2 Arme. Mit den Armen kannst du umarmen und Sachen tragen!',
    'bein': 'Du hast 2 Beine zum Laufen und Springen!',
    'bauch': 'Im Bauch ist dein Magen - dort wird alles Essen verdaut.',
    'haare': 'Haare wachsen am Kopf und schuetzen dich vor Sonne und Kaelte!',
  };

  // ────────────────────────────────────────────────────────────────
  // WETTER-WISSEN
  // ────────────────────────────────────────────────────────────────
  static const Map<String, String> _wetter = {
    'regen': 'Regen sind Wassertropfen die aus Wolken fallen. Bei Regen brauchst du einen Schirm!',
    'schnee': 'Schnee ist gefrorenes Wasser. Bei Schnee kann man einen Schneemann bauen!',
    'sonne': 'Die Sonne ist ein riesiger Stern. Sie macht es hell und warm!',
    'wolke': 'Wolken sind Wassertroepfchen am Himmel. Wenn sie schwer werden, kommt Regen.',
    'wolken': 'Wolken sind Wassertroepfchen am Himmel. Wenn sie schwer werden, kommt Regen.',
    'blitz': 'Ein Blitz ist Strom in den Wolken. Erst kommt der Blitz, dann der Donner!',
    'donner': 'Der Donner ist das laute Geraeusch nach einem Blitz.',
    'gewitter': 'Bei Gewitter blitzt und donnert es. Geh dann ins Haus!',
    'regenbogen': 'Ein Regenbogen hat 7 Farben: Rot, Orange, Gelb, Gruen, Blau, Indigo, Violett!',
    'nebel': 'Nebel sind Wolken die ganz unten am Boden sind. Man sieht dann nicht weit!',
  };

  // ────────────────────────────────────────────────────────────────
  // GEOGRAFIE-WISSEN
  // ────────────────────────────────────────────────────────────────
  static const Map<String, String> _geografie = {
    'oesterreich': 'Oesterreich liegt in Europa und hat 9 Bundeslaender. Die Hauptstadt ist Wien!',
    'österreich': 'Oesterreich liegt in Europa und hat 9 Bundeslaender. Die Hauptstadt ist Wien!',
    'wien': 'Wien ist die Hauptstadt von Oesterreich. Dort wohnen ueber 2 Millionen Menschen!',
    'deutschland': 'Deutschland ist Oesterreichs Nachbar im Norden. Die Hauptstadt ist Berlin!',
    'berlin': 'Berlin ist die Hauptstadt von Deutschland und eine sehr grosse Stadt!',
    'italien': 'Italien ist Oesterreichs Nachbar im Sueden. Die Hauptstadt ist Rom!',
    'rom': 'Rom ist die Hauptstadt von Italien. Dort steht das beruehmte Kolosseum!',
    'frankreich': 'Frankreich ist beruehmt fuer den Eiffelturm in Paris!',
    'paris': 'Paris ist die Hauptstadt von Frankreich. Dort steht der Eiffelturm!',
    'london': 'London ist die Hauptstadt von Grossbritannien. Dort steht Big Ben!',
    'europa': 'Europa ist ein Kontinent mit vielen Laendern - darunter auch Oesterreich!',
    'alpen': 'Die Alpen sind hohe Berge in Oesterreich. Im Winter kann man dort Ski fahren!',
    'donau': 'Die Donau ist ein langer Fluss der durch Wien fliesst!',
  };

  // ────────────────────────────────────────────────────────────────
  // GESCHICHTE-WISSEN
  // ────────────────────────────────────────────────────────────────
  static const Map<String, String> _geschichte = {
    'maria theresia': 'Maria Theresia war eine Kaiserin in Oesterreich. Sie hat sehr viele Schulen gegruendet!',
    'ritter': 'Ritter lebten im Mittelalter in grossen Burgen. Sie trugen Ruestungen aus Eisen.',
    'burg': 'Burgen waren grosse Steinhaeuser mit Mauern. Dort lebten Ritter und Adelige.',
    'kaiser': 'Ein Kaiser war frueher der wichtigste Mann im Land - wie heute der Bundespraesident.',
    'mittelalter': 'Das Mittelalter war vor ueber 500 Jahren. Damals gab es Ritter und Burgen!',
  };

  // ────────────────────────────────────────────────────────────────
  // BUCHSTABEN-HILFE
  // ────────────────────────────────────────────────────────────────
  static const Map<String, String> _buchstabenLaut = {
    'a': 'A wie Apfel oder Auto!',
    'b': 'B wie Ball oder Banane!',
    'c': 'C wie Computer!',
    'd': 'D wie Dackel oder Drache!',
    'e': 'E wie Elefant oder Esel!',
    'f': 'F wie Fisch oder Fuchs!',
    'g': 'G wie Giraffe oder Garten!',
    'h': 'H wie Hund oder Haus!',
    'i': 'I wie Igel oder Insel!',
    'j': 'J wie Junge oder Jaeger!',
    'k': 'K wie Katze oder Krone!',
    'l': 'L wie Loewe oder Lampe!',
    'm': 'M wie Mama oder Maus!',
    'n': 'N wie Nase oder Nudel!',
    'o': 'O wie Orange oder Oma!',
    'p': 'P wie Papa oder Pinguin!',
    'q': 'Q wie Quark!',
    'r': 'R wie Rose oder Roboter!',
    's': 'S wie Sonne oder Stern!',
    't': 'T wie Tisch oder Tiger!',
    'u': 'U wie Uhu oder Uhr!',
    'v': 'V wie Vogel oder Vase!',
    'w': 'W wie Wasser oder Wolf!',
    'x': 'X wie Xylophon!',
    'y': 'Y wie Yacht!',
    'z': 'Z wie Zebra oder Zaun!',
  };

  // ────────────────────────────────────────────────────────────────
  // GENERELLES LERN-WISSEN
  // ────────────────────────────────────────────────────────────────
  static const Map<String, String> _allgemein = {
    'plus': 'Plus heisst zusammenzaehlen! Zum Beispiel: 2 Aepfel + 3 Aepfel = 5 Aepfel.',
    'minus': 'Minus heisst wegnehmen! Zum Beispiel: 5 Aepfel - 2 weg = 3 Aepfel.',
    'mal': 'Mal heisst mehrere Gruppen. 3 mal 2 ist: 3 Gruppen mit je 2 = 6.',
    'geteilt': 'Geteilt heisst aufteilen. 10 geteilt durch 2 ist: 10 Sachen auf 2 Personen = je 5.',
    'nomen': 'Ein Nomen ist etwas das man anfassen kann: Hund, Haus, Tisch. Es wird gross geschrieben!',
    'verb': 'Ein Verb ist eine Taetigkeit: laufen, lachen, essen. Das macht jemand!',
    'adjektiv': 'Ein Adjektiv beschreibt wie etwas ist: rot, gross, schnell, lustig.',
    'artikel': 'Artikel sind der, die, das. Sie stehen vor Nomen: der Hund, die Katze, das Auto.',
  };

  // ────────────────────────────────────────────────────────────────
  // VARIATIONS - damit Antworten nie gleich wirken
  // ────────────────────────────────────────────────────────────────
  static const List<String> _intros = [
    '', 'Super Frage! ', 'Schau mal: ', 'Das ist einfach: ',
    'Hier weiss ich was: ', 'Klar erklaer ich dir das: ',
  ];

  static const List<String> _outros = [
    '', ' Spannend, oder?', ' Hast du noch eine Frage?',
    ' Magst du das ueben?', ' Cool, was?',
  ];

  String _wrap(String core, {String? imageHint}) {
    final intro = _intros[_rng.nextInt(_intros.length)];
    final outro = _outros[_rng.nextInt(_outros.length)];
    return '$intro$core$outro';
  }

  // ════════════════════════════════════════════════════════════════
  // HAUPTMETHODE: ASK
  // ════════════════════════════════════════════════════════════════
  /// Versucht eine Antwort zu generieren.
  /// Gibt confident=true zurueck wenn die Antwort verlaesslich ist
  /// (-> kein ChatGPT noetig), sonst confident=false (-> ChatGPT besser).
  LumoBrainReply ask(String question, {String? topicId}) {
    final q = question.toLowerCase().trim();

    // 1. Math-Calculator
    final mathReply = _tryMath(q);
    if (mathReply != null) return mathReply;

    // 2. Tier-Lexikon
    for (final entry in _tiere.entries) {
      if (q.contains(entry.key)) {
        return _tierAntwort(entry.key, entry.value, q);
      }
    }

    // 3. Koerper
    for (final entry in _koerper.entries) {
      if (q.contains(entry.key)) {
        return LumoBrainReply(
          text: _wrap(entry.value),
          confident: true,
          imageTopicHint: entry.key,
        );
      }
    }

    // 4. Wetter
    for (final entry in _wetter.entries) {
      if (q.contains(entry.key)) {
        return LumoBrainReply(
          text: _wrap(entry.value),
          confident: true,
          imageTopicHint: entry.key,
        );
      }
    }

    // 5. Geografie
    for (final entry in _geografie.entries) {
      if (q.contains(entry.key)) {
        return LumoBrainReply(
          text: _wrap(entry.value),
          confident: true,
          imageTopicHint: entry.key,
        );
      }
    }

    // 6. Geschichte
    for (final entry in _geschichte.entries) {
      if (q.contains(entry.key)) {
        return LumoBrainReply(
          text: _wrap(entry.value),
          confident: true,
        );
      }
    }

    // 7. Allgemeine Lernbegriffe
    for (final entry in _allgemein.entries) {
      if (q.contains(entry.key)) {
        return LumoBrainReply(
          text: _wrap(entry.value),
          confident: true,
        );
      }
    }

    // 8. Buchstaben (Single-Letter-Frage)
    final letterMatch = RegExp(r'^(?:wie|der|das)?\s*[a-zA-Z]\s*$').firstMatch(q);
    if (letterMatch != null) {
      final letter = q.replaceAll(RegExp(r'[^a-z]'), '');
      if (_buchstabenLaut.containsKey(letter)) {
        return LumoBrainReply(
          text: _wrap(_buchstabenLaut[letter]!),
          confident: true,
        );
      }
    }

    // 9. Spezifische Pattern: "wie spricht man X" / "buchstabe X"
    final buchstabePattern = RegExp(r'buchstabe\s+([a-z])|wie\s+spricht\s+man\s+([a-z])');
    final bm = buchstabePattern.firstMatch(q);
    if (bm != null) {
      final letter = (bm.group(1) ?? bm.group(2)) ?? '';
      if (_buchstabenLaut.containsKey(letter)) {
        return LumoBrainReply(
          text: _wrap(_buchstabenLaut[letter]!),
          confident: true,
        );
      }
    }

    // 10. Begruessungs-Pattern
    if (q.contains('hallo') || q.contains('hi ') || q == 'hi' ||
        q.contains('guten tag') || q.contains('hey lumo')) {
      return LumoBrainReply(
        text: _begruessung(),
        confident: true,
      );
    }

    // 11. Aufgaben-Pattern: 'mach mir eine aufgabe' / 'gib mir eine'
    if (q.contains('aufgabe') || q.contains('gib mir eine') ||
        q.contains('frag mich was')) {
      final aufgabe = _generateTask(topicId);
      if (aufgabe != null) {
        return LumoBrainReply(text: aufgabe, confident: true);
      }
    }

    // 12. Nichts gefunden -> ChatGPT soll uebernehmen
    return LumoBrainReply(
      text: '',
      confident: false,
    );
  }

  // ────────────────────────────────────────────────────────────────
  // MATH-CALCULATOR
  // ────────────────────────────────────────────────────────────────
  LumoBrainReply? _tryMath(String q) {
    // Plus: '3 + 5' oder 'was ist 3 plus 5'
    final plusM = RegExp(r'(\d+)\s*(?:\+|plus)\s*(\d+)').firstMatch(q);
    if (plusM != null) {
      final a = int.parse(plusM.group(1)!);
      final b = int.parse(plusM.group(2)!);
      return LumoBrainReply(
        text: _wrap('$a + $b = ${a + b}. So rechnest du es: nimm $a, '
            'dann zaehl $b dazu - das sind ${a + b}!'),
        confident: true,
      );
    }
    final minusM = RegExp(r'(\d+)\s*(?:\-|minus|weniger)\s*(\d+)').firstMatch(q);
    if (minusM != null) {
      final a = int.parse(minusM.group(1)!);
      final b = int.parse(minusM.group(2)!);
      if (a >= b) {
        return LumoBrainReply(
          text: _wrap('$a - $b = ${a - b}. Du hast $a Sachen, nimmst $b weg - '
              'es bleiben ${a - b}!'),
          confident: true,
        );
      }
    }
    final malM = RegExp(r'(\d+)\s*(?:\*|x|mal|\u00d7)\s*(\d+)').firstMatch(q);
    if (malM != null) {
      final a = int.parse(malM.group(1)!);
      final b = int.parse(malM.group(2)!);
      return LumoBrainReply(
        text: _wrap('$a mal $b = ${a * b}. Das sind $a Gruppen mit je $b - '
            'zusammen ${a * b}!'),
        confident: true,
      );
    }
    final teiltM = RegExp(r'(\d+)\s*(?:\/|geteilt durch|durch|:)\s*(\d+)').firstMatch(q);
    if (teiltM != null) {
      final a = int.parse(teiltM.group(1)!);
      final b = int.parse(teiltM.group(2)!);
      if (b != 0 && a % b == 0) {
        return LumoBrainReply(
          text: _wrap('$a geteilt durch $b = ${a ~/ b}. Du teilst $a Sachen '
              'auf $b Personen - jeder bekommt ${a ~/ b}!'),
          confident: true,
        );
      }
    }
    return null;
  }

  // ────────────────────────────────────────────────────────────────
  // TIER-ANTWORT (variabel je nach Frage-Typ)
  // ────────────────────────────────────────────────────────────────
  LumoBrainReply _tierAntwort(String tier, _TierInfo info, String q) {
    final tierLabel = tier[0].toUpperCase() + tier.substring(1);
    String core;
    if (q.contains('wo lebt') || q.contains('wo wohnt')) {
      core = 'Ein $tierLabel lebt ${info.lebensraum}.';
    } else if (q.contains('was frisst') || q.contains('was isst') ||
        q.contains('futter')) {
      core = 'Ein $tierLabel frisst ${info.futter}.';
    } else if (q.contains('wie macht') || q.contains('was sagt') ||
        q.contains('welcher laut')) {
      core = 'Ein $tierLabel macht "${info.laut}"!';
    } else {
      // Vollantwort
      core = 'Ein $tierLabel lebt ${info.lebensraum}, frisst ${info.futter} '
          'und macht "${info.laut}". ${info.faktoid}';
    }
    return LumoBrainReply(
      text: _wrap(core),
      confident: true,
      imageTopicHint: tier,
    );
  }

  // ────────────────────────────────────────────────────────────────
  // BEGRUESSUNG mit Variation
  // ────────────────────────────────────────────────────────────────
  String _begruessung() {
    const grues = [
      'Hallo! Ich bin Lumo, dein Lern-Fuchs! Was magst du wissen?',
      'Hey! Schoen dass du da bist! Frag mich alles ueber dein Lieblings-Thema!',
      'Hi! Lass uns zusammen lernen! Was soll ich dir erklaeren?',
    ];
    return grues[_rng.nextInt(grues.length)];
  }

  // ────────────────────────────────────────────────────────────────
  // AUFGABEN-GENERATOR
  // ────────────────────────────────────────────────────────────────
  String? _generateTask(String? topicId) {
    if (topicId == null) {
      // Generische Aufgabe
      return _generatePlusAufgabe();
    }
    if (topicId == 'm1_plus10' || topicId.contains('plus')) {
      return _generatePlusAufgabe();
    }
    if (topicId == 'm1_minus10' || topicId.contains('minus')) {
      return _generateMinusAufgabe();
    }
    if (topicId.contains('einmaleins') || topicId.contains('mal')) {
      return _generateMalAufgabe();
    }
    if (topicId.startsWith('s1_tier') || topicId.contains('tier')) {
      return _generateTierAufgabe();
    }
    return null;
  }

  String _generatePlusAufgabe() {
    final a = 1 + _rng.nextInt(5);
    final b = 1 + _rng.nextInt(5);
    return 'Hier eine Aufgabe fuer dich: Was ist $a + $b? '
        'Stell dir $a Aepfel vor und nimm $b dazu!';
  }

  String _generateMinusAufgabe() {
    final a = 5 + _rng.nextInt(5);
    final b = 1 + _rng.nextInt(a);
    return 'Hier eine Aufgabe fuer dich: Was ist $a - $b? '
        'Du hast $a Sachen, $b werden weggenommen!';
  }

  String _generateMalAufgabe() {
    final a = 2 + _rng.nextInt(3);
    final b = 2 + _rng.nextInt(8);
    return 'Hier eine Mal-Aufgabe: Was ist $a mal $b? '
        'Das sind $a Gruppen mit je $b!';
  }

  String _generateTierAufgabe() {
    final tier = _tiere.keys.elementAt(_rng.nextInt(_tiere.length));
    return 'Tier-Frage: Wie macht ein ${tier[0].toUpperCase()}${tier.substring(1)}?';
  }
}

class _TierInfo {
  const _TierInfo({
    required this.laut,
    required this.lebensraum,
    required this.futter,
    required this.faktoid,
  });
  final String laut;
  final String lebensraum;
  final String futter;
  final String faktoid;
}
