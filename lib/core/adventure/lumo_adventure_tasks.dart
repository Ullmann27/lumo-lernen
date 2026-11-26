import 'dart:math';

import 'adventure_word_data.dart';

/// Eine fertige Abenteuer-Aufgabe (Auswahlaufgabe mit vier Antworten).
class AdventureTask {
  const AdventureTask({
    required this.subject,
    required this.unit,
    required this.prompt,
    required this.answer,
    required this.choices,
    required this.explanation,
    this.visual = 'auto',
  });

  final String subject;
  final String unit;
  final String prompt;
  final String answer;
  final List<String> choices;
  final String explanation;
  final String visual;
}

/// Lumos Abenteuer-Aufgaben: Geschichten mit Lumo und seinen Freunden
/// (auf Wunsch mit dem Namen des Kindes), Zahlenmauern, Zahlenrätsel,
/// Marktstand, Wortdetektiv, „Wer bin ich?“ und mehr. Jede Aufgabe wird aus
/// Bausteinen und Zahlen neu zusammengesetzt, darum gehen sie nie aus.
/// Zahlenräume nach österreichischem Lehrplan: Klasse 1 bis 20, Klasse 2
/// bis 100, Klasse 3 bis 1000, Klasse 4 bis 10 000.
class LumoAdventureTasks {
  LumoAdventureTasks(this._random, {String? childName})
      : _childName = _cleanName(childName);

  final Random _random;
  final String? _childName;

  /// Einheiten je Fach mit der Klasse, ab der sie vorkommen.
  static const units = <String, Map<String, int>>{
    'Mathematik': {
      'Rechengeschichten': 1,
      'Zahlenmauer': 1,
      'Zahlenrätsel': 1,
      'Marktstand': 1,
      'Platzhalter-Rätsel': 1,
      'Größer, kleiner, gleich': 1,
      'Uhr-Abenteuer': 2,
    },
    'Deutsch': {
      'Wortdetektiv': 1,
      'Silbenrätsel': 1,
      'Begleiter-Rätsel': 1,
      'Gegenteil-Geschichten': 1,
      'Wörter zusammensetzen': 2,
      'Wortarten-Jagd': 2,
      'Satzbaustelle': 2,
    },
    'Sachunterricht': {
      'Wer bin ich?': 1,
      'Monate und Wochentage': 1,
      'Österreich-Reise': 3,
    },
    'Logik': {
      'Was passt nicht?': 1,
      'Geheimcode': 2,
    },
  };

  static List<String> unitsFor(String subject, int grade,
          {bool currentGradeOnly = false}) =>
      [
        for (final entry in (units[subject] ?? const <String, int>{}).entries)
          if (entry.value <= grade &&
              (!currentGradeOnly || entry.value == grade || grade == 1))
            entry.key,
      ];

  static bool handles(String subject, String unit) =>
      units[subject]?.containsKey(unit) ?? false;

  static String? _cleanName(String? name) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty || trimmed.length > 16) return null;
    if (!RegExp(r'^[A-Za-zÄÖÜäöüß\- ]+$').hasMatch(trimmed)) return null;
    return trimmed.split(' ').first;
  }

  AdventureTask generate(
      {required String subject, required String unit, required int grade}) {
    final g = grade.clamp(1, 4).toInt();
    return switch (unit) {
      'Rechengeschichten' => _story(g),
      'Zahlenmauer' => _wall(g),
      'Zahlenrätsel' => _numberRiddle(g),
      'Marktstand' => _market(g),
      'Platzhalter-Rätsel' => _placeholder(g),
      'Größer, kleiner, gleich' => _compare(g),
      'Uhr-Abenteuer' => _clock(g),
      'Wortdetektiv' => _spelling(g),
      'Silbenrätsel' => _syllables(g),
      'Begleiter-Rätsel' => _article(g),
      'Gegenteil-Geschichten' => _opposites(g),
      'Wörter zusammensetzen' => _compound(g),
      'Wortarten-Jagd' => _wordClass(g),
      'Satzbaustelle' => _sentence(g),
      'Wer bin ich?' => _riddle(g),
      'Monate und Wochentage' => _calendar(g),
      'Österreich-Reise' => _austria(g),
      'Was passt nicht?' => _oddOneOut(g),
      'Geheimcode' => _secretCode(g),
      _ => _story(g),
    };
  }

  // ─── Hilfen ────────────────────────────────────────────────────────

  T _pick<T>(List<T> list) => list[_random.nextInt(list.length)];
  int _between(int min, int max) => min + _random.nextInt(max - min + 1);

  /// Held der Geschichte: oft das Kind selbst, sonst ein Freund von Lumo.
  String _hero() => _childName != null && _random.nextInt(5) < 2
      ? _childName
      : _pick(adventureFriends);

  String _otherFriend(String not) {
    final pool = adventureFriends.where((f) => f != not).toList();
    return _pick(pool);
  }

  static int maxNumber(int grade) => switch (grade) {
        1 => 20,
        2 => 100,
        3 => 1000,
        _ => 10000,
      };

  /// Größte Lösung einer Einheit. Rechengeschichten der 4. Klasse rechnen
  /// im Zahlenraum bis zur Million (Befund M22), die übrigen Abenteuer
  /// bleiben bei [maxNumber].
  static int answerMax(int grade, String unit) =>
      grade >= 4 && unit == 'Rechengeschichten' ? 1000000 : maxNumber(grade);

  /// [max] begrenzt die falschen Karten, z. B. auf den Zahlenraum 20 der
  /// 1. Klasse: Eine Karte „25“ wäre dort ohne Rechnen auszuschließen.
  List<String> _numberChoices(int answer, {int spread = 0, int? max}) {
    final step = spread > 0 ? spread : (answer > 200 ? 10 : 1);
    final options = <int>{answer};
    // Große Zahlen (Klasse 4): nur Stellenfehler, keine Karte mit anderer
    // Einerziffer, die man ohne Rechnen ausschließen könnte.
    final candidates = step >= 1000
        ? (<int>[
            answer + step, answer - step, answer + 10, answer - 10,
            answer + 100, answer - 100, answer + 10 * step, answer - 10 * step,
          ]..shuffle(_random))
        : <int>[
      answer + step, answer - step, answer + 2 * step, answer - 2 * step,
      answer + 10, answer - 10, answer + 1, answer - 1,
      answer + 2, answer - 2, answer + 3, answer - 3,
    ]..shuffle(_random);
    options.addAll(_spreadAround(answer, [
      for (final c in candidates)
        if (c >= 0 && (max == null || c <= max)) c,
    ]));
    return _shuffle(options.map((n) => '$n').toList());
  }

  /// Drei falsche Werte so, dass die Lösung gleich oft die kleinste, eine
  /// mittlere oder die größte Karte ist. Feste Muster (immer −10, +10, +60
  /// Minuten; Nachbarzahlen) machten die Lösung fast immer zur zweit-
  /// kleinsten Karte: Wer das merkt, löst ohne zu rechnen.
  List<int> _spreadAround(int answer, Iterable<int> candidates) {
    final below = <int>[], above = <int>[];
    for (final c in candidates) {
      if (c < answer && !below.contains(c)) below.add(c);
      if (c > answer && !above.contains(c)) above.add(c);
    }
    final low = (3 - above.length).clamp(0, 3);
    final high = below.length.clamp(0, 3);
    final belowCount =
        low >= high ? high : low + _random.nextInt(high - low + 1);
    return [...below.take(belowCount), ...above.take(3 - belowCount)];
  }

  List<String> _choicesWith(String answer, Iterable<String> others) {
    final list = <String>[answer];
    for (final other in others) {
      if (other != answer && !list.contains(other)) list.add(other);
      if (list.length == 4) break;
    }
    return _shuffle(list);
  }

  List<String> _shuffle(List<String> list) => list..shuffle(_random);

  /// Dativ Plural: Endet der Plural nicht auf -n oder -s, kommt -n dazu
  /// (Nüsse → Nüssen, Äpfel → Äpfeln, aber Perlen, Ballons).
  static String _dativePlural(String plural) =>
      plural.endsWith('n') || plural.endsWith('s') ? plural : '${plural}n';

  /// Meist Inhalte der eigenen Klasse, manchmal Wiederholung von früher.
  List<T> _preferGrade<T>(List<T> all, int g, int Function(T) gradeOf) {
    final current = all.where((e) => gradeOf(e) == g).toList();
    final earlier = all.where((e) => gradeOf(e) <= g).toList();
    if (current.isNotEmpty && _random.nextInt(10) < 7) return current;
    return earlier.isNotEmpty ? earlier : all;
  }

  AdventureTask _math(String unit, String prompt, int answer, String why,
          {int spread = 0, String suffix = '', int? max}) =>
      AdventureTask(
        subject: 'Mathematik',
        unit: unit,
        prompt: prompt,
        answer: '$answer$suffix',
        choices: suffix.isEmpty
            ? _numberChoices(answer, spread: spread, max: max)
            : _numberChoices(answer, spread: spread, max: max)
                .map((c) => '$c$suffix')
                .toList(),
        explanation: why,
      );

  // ─── Mathematik ────────────────────────────────────────────────────

  AdventureTask _story(int g) {
    final hero = _hero();
    final friend = _otherFriend(hero);
    final object = _pick(adventureObjects);
    final pl = object[1];
    final place = _pick(adventurePlaces);
    final max = maxNumber(g);
    final kind = _random.nextInt(g == 1 ? 4 : g == 2 ? 6 : 7);
    // Klasse 1: Karten bleiben im Zahlenraum 20.
    final cap = g == 1 ? 20 : null;
    if (g >= 3 && kind <= 3) return _bigStory(g, kind, hero, friend);
    switch (kind) {
      case 0:
        final a = _between(2, max ~/ 2);
        final b = _between(2, max - a);
        return _math(
            'Rechengeschichten',
            '$hero sammelt $place $a $pl. Dann findet $hero noch $b $pl. '
                'Wie viele $pl hat $hero jetzt?',
            a + b,
            '$a $pl und noch $b dazu: $a + $b = ${a + b}. Super gesammelt!',
            max: cap);
      case 1:
        final a = _between(4, max);
        final b = _between(2, a - 1);
        return _math(
            'Rechengeschichten',
            '$hero hat $a $pl. $hero schenkt $friend $b davon. '
                'Wie viele $pl hat $hero noch?',
            a - b,
            'Verschenken heißt wegnehmen: $a − $b = ${a - b}. Wie lieb von $hero!',
            max: cap);
      case 2:
        final a = _between(4, max);
        final b = _between(2, a - 2);
        return _math(
            'Rechengeschichten',
            '$hero hat $a $pl, $friend hat $b $pl. '
                'Wie viele $pl hat $hero mehr als $friend?',
            a - b,
            'Den Unterschied findest du mit Minus: $a − $b = ${a - b}.',
            max: cap);
      case 3:
        final a = _between(2, max ~/ 2);
        final b = _between(2, max ~/ 2);
        return _math(
            'Rechengeschichten',
            'Bei Lumos Kart-Rennen fährt $hero $a Runden und $friend $b Runden. '
                'Wie viele Runden fahren beide zusammen?',
            a + b,
            'Zusammen heißt plus: $a + $b = ${a + b}. Brumm, brumm!',
            max: cap);
      case 4:
        final container = _pick(adventureContainers);
        final n = _between(2, g == 2 ? 10 : 10);
        final k = g == 4 ? _between(11, 99) : _between(2, 10);
        return _math(
            'Rechengeschichten',
            'Es gibt $n ${container[0]}. $hero legt in ${container[1]} $k $pl. '
                'Wie viele $pl sind das zusammen?',
            n * k,
            '$n-mal $k: $n · $k = ${n * k}.',
            spread: k);
      case 5:
        final n = _between(2, g == 2 ? 5 : 9);
        final k = g == 4 ? _between(6, 25) : _between(2, 10);
        return _math(
            'Rechengeschichten',
            '${n * k} $pl werden gerecht an $n Freunde verteilt. '
                'Wie viele $pl bekommt jeder Freund?',
            k,
            'Gerecht verteilen heißt teilen: ${n * k} : $n = $k, '
                'denn $n · $k = ${n * k}.');
      default:
        if (g == 4) {
          final n = _between(3, 12);
          final k = _between(12, 60);
          final b = _between(10, 200);
          final c = _between(5, n * k);
          return _math(
              'Rechengeschichten',
              '$hero kauft $n Packungen. In jeder Packung sind $k $pl. '
                  // „Von allen“ (nicht „Davon“, Befund M20) braucht den
                  // Dativ Plural: „von allen Nüssen“, nicht „Nüsse“.
                  '$hero bekommt noch $b $pl dazu. Von allen '
                  '${_dativePlural(pl)} verschenkt $hero $c. '
                  'Wie viele $pl hat $hero am Ende?',
              n * k + b - c,
              'Erst $n · $k = ${n * k}, dann + $b = ${n * k + b}, '
                  'dann − $c = ${n * k + b - c}.',
              spread: 10);
        }
        final a = _between(20, max ~/ 2);
        final b = _between(10, max ~/ 2);
        final c = _between(5, a + b - 1);
        return _math(
            'Rechengeschichten',
            '$hero hat $a $pl. $hero bekommt $b dazu und verschenkt dann $c. '
                'Wie viele $pl hat $hero am Ende?',
            a + b - c,
            'Zwei Schritte: $a + $b = ${a + b}, dann ${a + b} − $c = ${a + b - c}.',
            spread: 10);
    }
  }

  /// Rechengeschichten mit großen Zahlen (ab Klasse 3). Gezählt wird, was
  /// es in solchen Mengen wirklich gibt: Punkte, Meter, Zuschauer, Schritte.
  /// Früher hieß es „Hoppel hat 902 Erdbeeren“ oder „fährt 471 Runden“.
  AdventureTask _bigStory(int g, int kind, String hero, String friend) {
    if (g >= 4) return _millionStory(kind, hero);
    final max = maxNumber(g);
    switch (kind) {
      case 0:
        final a = _between(max ~/ 20, max ~/ 2);
        final b = _between(max ~/ 20, max - a);
        return _math(
            'Rechengeschichten',
            '$hero sammelt bei Lumos Kart-Spiel $a Punkte. In der zweiten '
                'Runde kommen $b Punkte dazu. Wie viele Punkte hat $hero jetzt?',
            a + b,
            'Es kommt etwas dazu: $a + $b = ${a + b}.',
            spread: 10);
      case 1:
        final a = _between(max ~/ 4, max);
        final b = _between(max ~/ 20, a - 1);
        return _math(
            'Rechengeschichten',
            'Der Wanderweg auf die Alm ist $a Meter lang. $hero ist schon '
                '$b Meter gegangen. Wie viele Meter fehlen noch?',
            a - b,
            'Was schon geschafft ist, ziehst du ab: $a − $b = ${a - b}.',
            spread: 10);
      case 2:
        final a = _between(max ~/ 4, max);
        final b = _between(max ~/ 20, a - 2);
        return _math(
            'Rechengeschichten',
            'Beim Schulfest sind $a Zuschauer, beim Kart-Rennen $b Zuschauer. '
                'Wie viele Zuschauer sind beim Schulfest mehr als beim Kart-Rennen?',
            a - b,
            'Den Unterschied findest du mit Minus: $a − $b = ${a - b}.',
            spread: 10);
      default:
        final a = _between(max ~/ 20, max ~/ 2);
        final b = _between(max ~/ 20, max ~/ 2);
        return _math(
            'Rechengeschichten',
            '$hero geht am Vormittag $a Schritte und am Nachmittag $b Schritte. '
                'Wie viele Schritte sind das zusammen?',
            a + b,
            'Zusammen heißt plus: $a + $b = ${a + b}.',
            spread: 10);
    }
  }

  /// Klasse 4: Zahlen von 10 000 bis 1 000 000 mit Dingen, bei denen solche
  /// Zahlen vorkommen (Befund M22: früher endete Klasse 4 bei 10 000).
  AdventureTask _millionStory(int kind, String hero) {
    // Runde Zehner, damit die Zahlen lesbar bleiben.
    int tens(int min, int max) => _between(min ~/ 10, max ~/ 10) * 10;
    switch (kind) {
      case 0:
        final a = tens(10000, 500000);
        final b = tens(10000, 400000);
        return _math(
            'Rechengeschichten',
            '$hero erreicht im Lumo-Spiel in der ersten Runde $a Punkte und '
                'in der zweiten Runde $b Punkte. Wie viele Punkte sind das zusammen?',
            a + b,
            'Beide Runden zusammen: $a + $b = ${a + b}.',
            spread: 1000);
      case 1:
        final a = tens(200000, 1000000);
        final b = tens(10000, a - 10000);
        return _math(
            'Rechengeschichten',
            'In einer Stadt wohnen $a Menschen. In einem Jahr ziehen $b '
                'Menschen weg, niemand kommt dazu. Wie viele wohnen dann noch dort?',
            a - b,
            'Wer wegzieht, wird abgezogen: $a − $b = ${a - b}.',
            spread: 1000);
      case 2:
        final a = tens(20000, 50000);
        final b = tens(10000, a - 1000);
        return _math(
            'Rechengeschichten',
            'Beim ersten Fußballspiel sind $a Zuschauer im Stadion, beim '
                'zweiten $b. Wie viele Zuschauer waren beim ersten Spiel mehr als beim zweiten?',
            a - b,
            'Den Unterschied findest du mit Minus: $a − $b = ${a - b}.',
            spread: 1000);
      default:
        final a = tens(10000, 90000);
        final b = tens(10000, 90000);
        return _math(
            'Rechengeschichten',
            'Eine Radtour hat zwei Teile: $a Meter am Vormittag und $b Meter '
                'am Nachmittag. Wie viele Meter sind das zusammen?',
            a + b,
            'Zusammen heißt plus: $a + $b = ${a + b}.',
            spread: 1000);
    }
  }

  AdventureTask _wall(int g) {
    final top = maxNumber(g);
    final limit = g == 1 ? 5 : top ~/ 4;
    final a = _between(1, limit);
    final b = _between(1, limit);
    final c = _between(1, limit);
    final left = a + b, right = b + c, peak = left + right;
    final friend = _pick(adventureFriends);
    if (g >= 2 && _random.nextBool()) {
      return _math(
          'Zahlenmauer',
          '$friend baut eine Zahlenmauer. Zwei Steine nebeneinander ergeben '
              'zusammen den Stein darüber. Unten liegen $a, $b und $c, oben '
              'steht $peak. Welche Zahl steht in der Mitte links?',
          left,
          'Links in der Mitte: $a + $b = $left. Probe: $left + $right = $peak.');
    }
    return _math(
        'Zahlenmauer',
        '$friend baut eine Zahlenmauer aus drei Reihen. Zwei Steine '
            'nebeneinander ergeben zusammen den Stein darüber. Unten liegen '
            '$a, $b und $c. Welche Zahl steht ganz oben?',
        peak,
        'Mitte: $a + $b = $left und $b + $c = $right. Oben: $left + $right = $peak.',
        max: g == 1 ? 20 : null);
  }

  AdventureTask _numberRiddle(int g) {
    final friend = _pick(adventureFriends);
    final max = maxNumber(g);
    final kind = _random.nextInt(g == 1 ? 2 : 4);
    switch (kind) {
      case 0:
        final x = _between(1, max ~/ 2);
        final k = _between(1, max ~/ 2);
        return _math(
            'Zahlenrätsel',
            '$friend denkt sich eine Zahl. Wenn $friend $k dazuzählt, kommt '
                '${x + k} heraus. Welche Zahl hat sich $friend gedacht?',
            x,
            'Rechne rückwärts: ${x + k} − $k = $x.');
      case 1:
        final x = _between(3, max);
        final k = _between(1, x - 1);
        return _math(
            'Zahlenrätsel',
            '$friend denkt sich eine Zahl und nimmt $k weg. Übrig bleiben '
                '${x - k}. Welche Zahl war es?',
            x,
            'Rechne rückwärts: ${x - k} + $k = $x.');
      case 2:
        final x = _between(2, g == 2 ? 50 : max ~/ 2);
        return _math(
            'Zahlenrätsel',
            '$friend verdoppelt eine Zahl und bekommt ${2 * x}. '
                'Wie heißt die Zahl?',
            x,
            'Verdoppeln rückwärts heißt halbieren: ${2 * x} : 2 = $x.');
      default:
        final x = _between(2, 10);
        final k = _between(2, 10);
        return _math(
            'Zahlenrätsel',
            '$friend denkt sich eine Zahl und nimmt sie $k-mal. Das ergibt '
                '${x * k}. Welche Zahl ist es?',
            x,
            'Mal rückwärts heißt geteilt: ${x * k} : $k = $x.');
    }
  }

  String _euro(int cents) {
    if (cents % 100 == 0) return '${cents ~/ 100} €';
    final euros = cents ~/ 100;
    final rest = (cents % 100).toString().padLeft(2, '0');
    return '$euros,$rest €';
  }

  AdventureTask _market(int g) {
    final hero = _hero();
    if (g == 1) {
      // Erst die Summe wählen, dann zerlegen. Früher wurde der zweite Preis
      // aus „1 bis 10 − a“ gezogen: Ein Drittel der Aufgaben ergab 10 €.
      final total = _between(2, 10);
      final a = _between(1, total - 1);
      final b = total - a;
      // Wechselnde Waren statt immer „Ball und Buch“.
      const things = <String>[
        'einen Ball', 'ein Buch', 'ein Malheft', 'einen Kreisel',
        'eine Kappe', 'ein Springseil', 'einen Drachen', 'ein Puzzle',
      ];
      final first = _pick(things);
      final second = _pick(things.where((thing) => thing != first).toList());
      return _math(
          'Marktstand',
          '$hero kauft am Markt $first um $a € und $second um $b €. '
              'Wie viel kostet das zusammen?',
          a + b,
          '$a € + $b € = ${a + b} €.',
          suffix: ' €',
          max: 20);
    }
    if (g == 2) {
      final price = _between(11, 89);
      final paid = price <= 50 ? 50 : 100;
      final thing = _pick(const <String>[
        'eine Spielzeug-Rakete', 'einen Rucksack', 'ein Kartenspiel',
        'einen Fußball', 'eine Taschenlampe', 'ein Federpennal',
      ]);
      return _math(
          'Marktstand',
          '$hero kauft $thing um $price € und zahlt mit $paid €. '
              'Wie viel Wechselgeld bekommt $hero zurück?',
          paid - price,
          'Wechselgeld: $paid € − $price € = ${paid - price} €.',
          suffix: ' €');
    }
    final goods = [...adventureMarketGoods]..shuffle(_random);
    final first = goods[0], second = goods[1];
    final p1 = first[1] as int, p2 = second[1] as int;
    final count = g == 4 ? _between(2, 4) : 1;
    final total = count * p1 + p2;
    final paid = [1000, 2000, 5000, 10000].firstWhere((note) => note > total);
    final change = paid - total;
    final firstText = count == 1
        ? '${first[0]} (${_euro(p1)})'
        : '$count-mal ${first[0]} (je ${_euro(p1)})';
    final wrong = _spreadAround(change, [
      for (final delta in [10, -10, 50, -50, 100, -100]..shuffle(_random))
        if (change + delta > 0) change + delta,
    ]).map(_euro).toList();
    return AdventureTask(
      subject: 'Mathematik',
      unit: 'Marktstand',
      prompt: 'Am Markt kauft $hero $firstText und '
          '${second[0]} (${_euro(p2)}). $hero zahlt mit ${_euro(paid)}. '
          'Wie viel Wechselgeld gibt es zurück?',
      answer: _euro(change),
      choices: _choicesWith(_euro(change), wrong),
      explanation: 'Zusammen: ${count > 1 ? '$count · ${_euro(p1)} + ' : '${_euro(p1)} + '}'
          '${_euro(p2)} = ${_euro(total)}. Zurück: ${_euro(paid)} − '
          '${_euro(total)} = ${_euro(change)}.',
    );
  }

  AdventureTask _placeholder(int g) {
    final max = maxNumber(g);
    final kind = _random.nextInt(g == 1 ? 2 : 3);
    if (kind == 2) {
      final a = _between(2, 10);
      final b = _between(2, 10);
      return _math(
          'Platzhalter-Rätsel',
          'Lumo hat eine Zahl mit einem Stern verdeckt: $a · ★ = ${a * b}. '
              'Welche Zahl versteckt sich unter dem Stern?',
          b,
          '$a · $b = ${a * b}, also ist ★ = $b.');
    }
    final a = _between(1, max ~/ 2);
    final b = _between(1, max ~/ 2);
    if (kind == 0) {
      return _math(
          'Platzhalter-Rätsel',
          'Lumo hat eine Zahl mit einem Stern verdeckt: $a + ★ = ${a + b}. '
              'Welche Zahl versteckt sich unter dem Stern?',
          b,
          'Von $a bis ${a + b} fehlen ${a + b} − $a = $b.');
    }
    final total = a + b;
    return _math(
        'Platzhalter-Rätsel',
        'Lumo hat eine Zahl mit einem Stern verdeckt: ★ − $b = $a. '
            'Welche Zahl versteckt sich unter dem Stern?',
        total,
        'Rechne zurück: $a + $b = $total, also ★ = $total.');
  }

  AdventureTask _compare(int g) {
    final max = maxNumber(g);
    final a = _between(1, max ~/ 2);
    final b = _between(1, max ~/ 2);
    final sum = a + b;
    final other = (sum + _between(-3, 3)).clamp(0, max).toInt();
    final answer = sum > other
        ? '>'
        : sum < other
            ? '<'
            : '=';
    return AdventureTask(
      subject: 'Mathematik',
      unit: 'Größer, kleiner, gleich',
      prompt: 'Welches Zeichen gehört in die Lücke? $a + $b ⬜ $other',
      answer: answer,
      choices: _shuffle(['<', '>', '=']),
      explanation: answer == '='
          ? '$a + $b = $sum. $sum = $other: Beide Seiten sind gleich groß.'
          : '$a + $b = $sum. $sum $answer $other – '
              'das Krokodil-Maul frisst immer die größere Zahl.',
    );
  }

  AdventureTask _clock(int g) {
    final hero = _hero();
    if (g == 2) {
      final start = _between(1, 8);
      final hours = _between(1, 3);
      final end = start + hours;
      return AdventureTask(
        subject: 'Mathematik',
        unit: 'Uhr-Abenteuer',
        prompt: 'Lumos Kart-Turnier beginnt um $start Uhr und dauert $hours '
            '${hours == 1 ? 'Stunde' : 'Stunden'}. Um wie viel Uhr ist es aus?',
        answer: '$end Uhr',
        // Typische Fehler: Startzeit genannt, eine Stunde verzählt.
        choices: _choicesWith('$end Uhr', [
          for (final hour in _spreadAround(end, [
            for (final h in [start, end + 1, end - 1, end + 2, end - 2]
              ..shuffle(_random))
              if (h >= 1) h,
          ]))
            '$hour Uhr',
        ]),
        explanation: 'Von $start Uhr $hours '
            '${hours == 1 ? 'Stunde' : 'Stunden'} weiter: '
            '${[for (var h = start + 1; h <= end; h++) '$h Uhr'].join(', ')}.',
      );
    }
    final startH = _between(8, 16);
    final startM = _pick([0, 15, 30, 45]);
    final dur = g == 3 ? _pick([15, 30, 45]) : _pick([25, 35, 50, 75, 90]);
    final total = startH * 60 + startM + dur;
    String fmt(int minutes) =>
        '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}';
    final answer = fmt(total);
    return AdventureTask(
      subject: 'Mathematik',
      unit: 'Uhr-Abenteuer',
      prompt: '$hero startet um ${fmt(startH * 60 + startM)} Uhr eine Wanderung '
          'auf die Alm. Sie dauert $dur Minuten. Um wie viel Uhr kommt $hero an?',
      answer: '$answer Uhr',
      // Typische Fehler: zehn Minuten verzählt, Stunde statt Minuten.
      choices: _choicesWith('$answer Uhr', [
        for (final minutes in _spreadAround(total, [
          total + 10, total - 10, total + 60, total - 60, total - 15,
          total + 15,
        ]..shuffle(_random)))
          '${fmt(minutes)} Uhr',
      ]),
      explanation: '${fmt(startH * 60 + startM)} Uhr + $dur Minuten = $answer Uhr.',
    );
  }

  // ─── Deutsch ───────────────────────────────────────────────────────

  AdventureTask _spelling(int g) {
    final item = _pick(_preferGrade(adventureSpellings, g, (s) => s.grade));
    return AdventureTask(
      subject: 'Deutsch',
      unit: 'Wortdetektiv',
      prompt: 'Wortdetektiv! Lumo hat ein Wort mehrmals geschrieben, nur einmal '
          'stimmt es. Welches Wort ist richtig geschrieben?',
      answer: item.correct,
      choices: _choicesWith(item.correct, item.wrong),
      explanation: '${item.correct} ist richtig. ${item.tip}',
    );
  }

  AdventureTask _syllables(int g) {
    final noun = _pick(_preferGrade(adventureNouns, g, (n) => n.grade));
    if (g >= 2 && noun.syllableCount >= 3 && _random.nextBool()) {
      final parts = noun.syllables.split('-');
      final missing = _random.nextInt(parts.length);
      final shown = [
        for (var i = 0; i < parts.length; i++) i == missing ? '?' : parts[i],
      ].join(' – ');
      final others = <String>{
        for (final n in adventureNouns)
          for (final s in n.syllables.split('-'))
            if (s.toLowerCase() != parts[missing].toLowerCase()) s.toLowerCase(),
      }.toList()
        ..shuffle(_random);
      final answer = missing == 0 ? parts[missing] : parts[missing].toLowerCase();
      return AdventureTask(
        subject: 'Deutsch',
        unit: 'Silbenrätsel',
        prompt: 'Silbenrätsel: $shown. Welche Silbe fehlt im Wort ${noun.word}?',
        answer: answer,
        choices: _choicesWith(
            answer,
            others.map((s) => missing == 0
                ? '${s[0].toUpperCase()}${s.substring(1)}'
                : s)),
        explanation: '${noun.word} klatscht man so: ${noun.syllables.replaceAll('-', ' – ')}.',
      );
    }
    final count = noun.syllableCount;
    return AdventureTask(
      subject: 'Deutsch',
      unit: 'Silbenrätsel',
      prompt: 'Klatsch mit Lumo! Wie viele Silben hat das Wort ${noun.word}?',
      answer: '$count',
      choices: _shuffle([
        for (final n in {count, count + 1, count > 1 ? count - 1 : count + 2,
            count + 2})
          '$n'
      ]),
      explanation: '${noun.syllables.replaceAll('-', ' – ')}: '
          'das sind $count ${count == 1 ? 'Silbe' : 'Silben'}.',
    );
  }

  AdventureTask _article(int g) {
    final noun = _pick(_preferGrade(adventureNouns, g, (n) => n.grade));
    final hero = _hero();
    return AdventureTask(
      subject: 'Deutsch',
      unit: 'Begleiter-Rätsel',
      prompt: '$hero zeigt auf ein Bild und sagt: „Schau, ___ ${noun.word}!“ '
          'Welcher Begleiter gehört in die Lücke?',
      answer: noun.article,
      choices: _shuffle(['der', 'die', 'das']),
      explanation: 'Es heißt ${noun.article} ${noun.word}.',
    );
  }

  AdventureTask _opposites(int g) {
    final pair = _pick(adventureOpposites);
    final flip = _random.nextBool();
    final shown = flip ? pair[1] : pair[0];
    final answer = flip ? pair[0] : pair[1];
    final sentence = flip ? pair[2] : pair[3];
    final others = adventureOpposites
        .expand((p) => p.take(2))
        .where((w) => w != answer && w != shown)
        .toList()
      ..shuffle(_random);
    return AdventureTask(
      subject: 'Deutsch',
      unit: 'Gegenteil-Geschichten',
      prompt: '$sentence\nWelches Wort ist das Gegenteil von „$shown“?',
      answer: answer,
      choices: _choicesWith(answer, others),
      explanation: 'Das Gegenteil von $shown ist $answer.',
    );
  }

  AdventureTask _compound(int g) {
    final item = _pick(adventureCompounds);
    final result = item[2];
    final article = result.split(' ').first;
    final word = result.substring(article.length + 1);
    final base = item[1];
    if (_random.nextBool()) {
      return AdventureTask(
        subject: 'Deutsch',
        unit: 'Wörter zusammensetzen',
        prompt: 'Lumo baut ein langes Wort: $word. Welcher Begleiter passt zu $word?',
        answer: article,
        choices: _shuffle(['der', 'die', 'das']),
        explanation: 'Das letzte Wort bestimmt den Begleiter: $base, '
            'also $result.',
      );
    }
    final answer = '${item[0]} + ${base.split(' ').last}';
    final wrong = [
      for (final other in adventureCompounds)
        if (other != item) '${other[0]} + ${base.split(' ').last}',
    ]..shuffle(_random);
    return AdventureTask(
      subject: 'Deutsch',
      unit: 'Wörter zusammensetzen',
      prompt: 'Aus welchen zwei Wörtern ist $word zusammengesetzt?',
      answer: answer,
      choices: _choicesWith(answer, wrong),
      explanation: '$word = ${item[0]} + ${base.split(' ').last}. '
          'Der Begleiter kommt vom letzten Wort: $result.',
    );
  }

  AdventureTask _wordClass(int g) {
    final animal = _pick(adventureSentenceAnimals);
    final adjective = _pick(adventureAdjectives);
    final verbPhrase = _pick(adventureVerbs);
    final place = _pick(adventureVerbPlaces);
    final verb = verbPhrase.split(' ').first;
    final article = '${animal[0][0].toUpperCase()}${animal[0].substring(1)}';
    final sentence = '$article $adjective ${animal[1]} $verbPhrase $place.';
    final kind = _random.nextInt(3);
    final (label, answer) = switch (kind) {
      0 => ('Namenwort (Nomen)', animal[1]),
      1 => ('Tunwort (Verb)', verb),
      _ => ('Wiewort (Adjektiv)', adjective),
    };
    // Der Ort enthält selbst ein Namenwort (Garten, Wiese …): Bei der Frage
    // nach dem Namenwort steht stattdessen das Verhältniswort zur Wahl.
    final placeWords = place.split(' ');
    final fourth = kind == 0 ? placeWords.first : placeWords.last;
    final options = _choicesWith(
        answer, [animal[1], verb, adjective, fourth].where((w) => w != answer));
    return AdventureTask(
      subject: 'Deutsch',
      unit: 'Wortarten-Jagd',
      prompt: 'Wortarten-Jagd im Satz: „$sentence“ Welches Wort im Satz ist ein $label?',
      answer: answer,
      choices: options,
      explanation: switch (kind) {
        0 => '${animal[1]} ist ein Namenwort: Man schreibt es groß und kann '
            '„${animal[0]}“ davorsetzen.',
        1 => '$verb ist ein Tunwort: Es sagt, was ${animal[0]} ${animal[1]} tut.',
        _ => '$adjective ist ein Wiewort: Es sagt, wie ${animal[0]} ${animal[1]} ist.',
      },
    );
  }

  AdventureTask _sentence(int g) {
    final hero = _hero();
    final object = _pick(adventureObjects);
    final place = _pick(adventurePlaces);
    final verbs = <List<String>>[
      ['sammelt', 'viele ${object[1]}'],
      ['sucht', 'bunte ${object[1]}'],
      ['zählt', 'die ${object[1]}'],
      ['findet', 'drei ${object[1]}'],
    ];
    final v = _pick(verbs);
    final correct = '$hero ${v[0]} $place ${v[1]}.';
    final wrong = [
      '$hero $place ${v[1]} ${v[0]}.',
      '${v[0]} $hero ${v[1]} $place.',
      '${_capital(place)} ${v[1]} $hero ${v[0]}.',
    ];
    return AdventureTask(
      subject: 'Deutsch',
      unit: 'Satzbaustelle',
      prompt: 'Satzbaustelle: Lumo hat die Wörter durcheinandergewirbelt. '
          'Welcher Satz ist richtig gebaut?',
      answer: correct,
      choices: _choicesWith(correct, wrong),
      explanation: 'In einem Aussagesatz steht das Tunwort an zweiter Stelle: '
          '$correct',
    );
  }

  String _capital(String s) => '${s[0].toUpperCase()}${s.substring(1)}';

  // ─── Sachunterricht ────────────────────────────────────────────────

  AdventureTask _riddle(int g) {
    final pool = adventureRiddles.where((r) => int.parse(r[4]) <= g).toList();
    final riddle = _pick(pool);
    // Falsche Antworten aus derselben Gruppe (Tier, Beruf, Körper …).
    final others = adventureRiddles
        .where((r) => r != riddle && r[5] == riddle[5])
        .map((r) => r[0])
        .toList()
      ..shuffle(_random);
    return AdventureTask(
      subject: 'Sachunterricht',
      unit: 'Wer bin ich?',
      prompt: '${_riddleQuestion(riddle[5])} ${riddle[1]} ${riddle[2]} ${riddle[3]}',
      answer: riddle[0],
      choices: _choicesWith(riddle[0], others),
      explanation: 'Das ist ${riddle[0]}! ${riddle[3]}',
      visual: 'science',
    );
  }

  /// Menschen und Tiere fragen „Wer bin ich?“, Dinge, Naturerscheinungen und
  /// Körperteile „Was bin ich?“.
  String _riddleQuestion(String group) =>
      group == 'Tier' || group == 'Beruf' ? 'Wer bin ich?' : 'Was bin ich?';

  AdventureTask _calendar(int g) {
    final kind = _random.nextInt(g == 1 ? 2 : 4);
    if (kind == 0) {
      final today = _random.nextInt(7);
      final step = _between(1, 2);
      final answer = adventureWeekdays[(today + step) % 7];
      return AdventureTask(
        subject: 'Sachunterricht',
        unit: 'Monate und Wochentage',
        prompt: 'Heute ist ${adventureWeekdays[today]}. Welcher Tag ist '
            '${step == 1 ? 'morgen' : 'übermorgen'}?',
        answer: answer,
        choices: _choicesWith(answer, [...adventureWeekdays]..shuffle(_random)),
        explanation: 'Nach ${adventureWeekdays[today]} kommt '
            '${adventureWeekdays[(today + 1) % 7]}'
            '${step == 2 ? ', dann $answer' : ''}.',
        visual: 'science',
      );
    }
    final month = _random.nextInt(12);
    if (kind == 1 || g == 1) {
      final answer = adventureMonths[(month + 1) % 12];
      return AdventureTask(
        subject: 'Sachunterricht',
        unit: 'Monate und Wochentage',
        prompt: 'Welcher Monat kommt nach ${adventureMonths[month]}?',
        answer: answer,
        choices: _choicesWith(answer, [...adventureMonths]..shuffle(_random)),
        explanation: 'Nach ${adventureMonths[month]} kommt $answer.',
        visual: 'science',
      );
    }
    if (kind == 2) {
      final step = _between(2, 5);
      final answer = adventureMonths[(month + step) % 12];
      return AdventureTask(
        subject: 'Sachunterricht',
        unit: 'Monate und Wochentage',
        prompt: 'Lumos Geburtstag ist im ${adventureMonths[month]}. Pips Geburtstag '
            'ist $step Monate später. In welchem Monat feiert Pip?',
        answer: answer,
        choices: _choicesWith(answer, [...adventureMonths]..shuffle(_random)),
        explanation: 'Zähle $step Monate weiter: ${[
          for (var i = 1; i <= step; i++) adventureMonths[(month + i) % 12]
        ].join(', ')}.',
        visual: 'science',
      );
    }
    const seasons = ['Winter', 'Frühling', 'Sommer', 'Herbst'];
    // Jänner/Februar Winter, April/Mai Frühling, Juli/August Sommer,
    // Oktober/November Herbst. März, Juni, September und Dezember werden
    // nicht gefragt: Dort wechselt die Jahreszeit nach dem Kalender erst um
    // den 21., die Antwort wäre je nach Zählweise strittig.
    final asked = month % 3 == 2 ? (month + 1) % 12 : month;
    final season = seasons[((asked + 1) % 12) ~/ 3];
    return AdventureTask(
      subject: 'Sachunterricht',
      unit: 'Monate und Wochentage',
      prompt: 'In welcher Jahreszeit liegt der ${adventureMonths[asked]} bei uns '
          'in Österreich?',
      answer: season,
      choices: _shuffle([...seasons]),
      explanation: 'Der ${adventureMonths[asked]} gehört zum $season.',
      visual: 'science',
    );
  }

  AdventureTask _austria(int g) {
    if (_random.nextInt(3) == 0) {
      final fact = _pick(austriaFacts);
      return AdventureTask(
        subject: 'Sachunterricht',
        unit: 'Österreich-Reise',
        prompt: 'Lumos Österreich-Reise: ${fact[0]}',
        answer: fact[1],
        choices: _choicesWith(fact[1], fact[2].split('|')),
        explanation: fact[3],
        visual: 'science',
      );
    }
    final state = _pick(austriaStates.where((s) => s[0] != s[1]).toList());
    final askCapital = _random.nextBool();
    final answer = askCapital ? state[1] : state[0];
    final others = austriaStates
        .map((s) => askCapital ? s[1] : s[0])
        .where((s) => s != answer)
        .toList()
      ..shuffle(_random);
    return AdventureTask(
      subject: 'Sachunterricht',
      unit: 'Österreich-Reise',
      prompt: askCapital
          ? 'Lumo fliegt mit dem Ballon über ${_stateAccusative(state[0])}. '
              'Wie heißt die Landeshauptstadt?'
          : 'Lumo landet in ${state[1]}. In welchem Bundesland ist das?',
      answer: answer,
      choices: _choicesWith(answer, others),
      explanation:
          '${state[1]} ist die Landeshauptstadt ${_stateGenitive(state[0])}.',
      visual: 'science',
    );
  }

  /// Die Steiermark und das Burgenland stehen mit Artikel: „über die
  /// Steiermark“, „die Landeshauptstadt des Burgenlandes“. Die übrigen
  /// Bundesländer stehen ohne Artikel („über Tirol“, „von Tirol“).
  static String _stateAccusative(String state) => switch (state) {
        'Steiermark' => 'die Steiermark',
        'Burgenland' => 'das Burgenland',
        _ => state,
      };

  static String _stateGenitive(String state) => switch (state) {
        'Steiermark' => 'der Steiermark',
        'Burgenland' => 'des Burgenlandes',
        _ => 'von $state',
      };

  // ─── Logik ─────────────────────────────────────────────────────────

  AdventureTask _oddOneOut(int g) {
    final categories = [...adventureCategories]..shuffle(_random);
    final main = categories[0], other = categories[1];
    final members = main[1].split('|')..shuffle(_random);
    final odd = _pick(other[1].split('|'));
    final three = members.take(3).toList();
    return AdventureTask(
      subject: 'Logik',
      unit: 'Was passt nicht?',
      prompt: 'Lumo hat vier Dinge gefunden. Was passt nicht dazu? '
          '${_shuffle([...three, odd]).join(', ')}',
      answer: odd,
      choices: _shuffle([...three, odd]),
      explanation: '${three.join(', ')} gehören ${_toGroup(main[0])}. '
          '$odd gehört ${_toGroup(other[0])}.',
    );
  }

  /// Gruppenname im Wem-Fall mit Begleiter: „gehören zum Obst“, „gehört zu
  /// den Möbelstücken“ statt „gehört zu Möbelstücke“.
  static String _toGroup(String name) =>
      const <String, String>{
        'Obst': 'zum Obst',
        'Gemüse': 'zum Gemüse',
        'Wetter': 'zum Wetter',
        'Tiere im Wald': 'zu den Tieren im Wald',
        'Fahrzeuge': 'zu den Fahrzeugen',
        'Musikinstrumente': 'zu den Musikinstrumenten',
        'Kleidungsstücke': 'zu den Kleidungsstücken',
        'Möbelstücke': 'zu den Möbelstücken',
        'Farben': 'zu den Farben',
        'Schulsachen': 'zu den Schulsachen',
      }[name] ??
      'zur Gruppe „$name“';

  /// Weitere kurze Wörter ohne Umlaute, damit es Ablenker mit gleichem
  /// Anfangsbuchstaben gibt (Befund M26: meist genügte der erste Buchstabe).
  static const _extraCodeWords = <String>[
    'HAUS', 'HAND', 'HUT', 'BANK', 'BOOT', 'MAUS', 'MOOS', 'SAND', 'SALZ',
    'KANU', 'KUH', 'WAL', 'WOLF', 'ROSE', 'RABE', 'FISCH', 'FROSCH', 'ZUG',
    'ZELT', 'IGEL', 'ESEL', 'AFFE', 'SEE', 'BERG',
  ];

  AdventureTask _secretCode(int g) {
    final word = _pick(adventureCodeWords);
    // Klasse 4: manchmal beginnt der Code bei A = 2 (verschobenes Alphabet).
    final shift = g >= 4 && _random.nextBool() ? 1 : 0;
    int code(String c) => c.codeUnitAt(0) - 64 + shift;
    String encode(String w) => w.split('').map((c) => '${code(c)}').join('-');
    final pool = <String>{...adventureCodeWords, ..._extraCodeWords}
      ..remove(word);
    List<String> pick(bool Function(String) test) =>
        pool.where(test).toList()..shuffle(_random);
    final sameLength = word.length;
    // Gleich lange Wörter zuerst: Sonst verrät schon die Anzahl der Zahlen
    // das Wort (vorher in 40 % der Aufgaben, z. B. 6 Zahlen und nur
    // KUCHEN hat 6 Buchstaben). Ab Klasse 2 dabei zuerst Wörter mit
    // demselben Anfang, dann muss man weiterlesen.
    final sameStartSameLength =
        pick((w) => w[0] == word[0] && w.length == sameLength);
    final otherStartSameLength =
        pick((w) => w[0] != word[0] && w.length == sameLength);
    final sameStart = pick((w) => w[0] == word[0] && w.length != sameLength);
    final similarLength = pick((w) =>
        w[0] != word[0] && (w.length - sameLength).abs() == 1);
    final others = g >= 2
        ? <String>[
            ...sameStartSameLength, ...otherStartSameLength, ...sameStart,
            ...similarLength,
          ]
        : <String>[
            ...otherStartSameLength, ...sameStartSameLength, ...similarLength,
            ...sameStart,
          ];
    final rule = shift == 0
        ? 'Im Code ist A = 1, B = 2, C = 3 und so weiter bis Z = 26.'
        : 'Lumo hat den Code verschoben: Jetzt ist A = 2, B = 3, C = 4 und so weiter bis Z = 27.';
    return AdventureTask(
      subject: 'Logik',
      unit: 'Geheimcode',
      prompt: 'Geheimbotschaft von Lumo! $rule Welches Wort heißt ${encode(word)}?',
      answer: word,
      choices: _choicesWith(word, others),
      explanation: '${word.split('').map((c) => '$c = ${code(c)}').join(', ')}.',
    );
  }
}
