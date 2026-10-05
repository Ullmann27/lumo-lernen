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

  List<String> _numberChoices(int answer, {int spread = 0}) {
    final step = spread > 0 ? spread : (answer > 200 ? 10 : 1);
    final options = <int>{answer};
    final candidates = <int>[
      answer + step, answer - step, answer + 2 * step, answer - 2 * step,
      answer + 10, answer - 10, answer + 1, answer - 1,
    ]..shuffle(_random);
    for (final c in candidates) {
      if (c >= 0) options.add(c);
      if (options.length == 4) break;
    }
    return _shuffle(options.map((n) => '$n').toList());
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

  /// Meist Inhalte der eigenen Klasse, manchmal Wiederholung von früher.
  List<T> _preferGrade<T>(List<T> all, int g, int Function(T) gradeOf) {
    final current = all.where((e) => gradeOf(e) == g).toList();
    final earlier = all.where((e) => gradeOf(e) <= g).toList();
    if (current.isNotEmpty && _random.nextInt(10) < 7) return current;
    return earlier.isNotEmpty ? earlier : all;
  }

  AdventureTask _math(String unit, String prompt, int answer, String why,
          {int spread = 0, String suffix = ''}) =>
      AdventureTask(
        subject: 'Mathematik',
        unit: unit,
        prompt: prompt,
        answer: '$answer$suffix',
        choices: suffix.isEmpty
            ? _numberChoices(answer, spread: spread)
            : _numberChoices(answer, spread: spread)
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
    switch (kind) {
      case 0:
        final a = _between(2, max ~/ 2);
        final b = _between(2, max - a);
        return _math(
            'Rechengeschichten',
            '$hero sammelt $place $a $pl. Dann findet $hero noch $b $pl. '
                'Wie viele $pl hat $hero jetzt?',
            a + b,
            '$a $pl und noch $b dazu: $a + $b = ${a + b}. Super gesammelt!');
      case 1:
        final a = _between(4, max);
        final b = _between(2, a - 1);
        return _math(
            'Rechengeschichten',
            '$hero hat $a $pl. $hero schenkt $friend $b davon. '
                'Wie viele $pl hat $hero noch?',
            a - b,
            'Verschenken heißt wegnehmen: $a − $b = ${a - b}. Wie lieb von $hero!');
      case 2:
        final a = _between(4, max);
        final b = _between(1, a - 2);
        return _math(
            'Rechengeschichten',
            '$hero hat $a $pl, $friend hat $b $pl. '
                'Wie viele $pl hat $hero mehr als $friend?',
            a - b,
            'Den Unterschied findest du mit Minus: $a − $b = ${a - b}.');
      case 3:
        final a = _between(1, max ~/ 2);
        final b = _between(1, max ~/ 2);
        return _math(
            'Rechengeschichten',
            'Bei Lumos Kart-Rennen fährt $hero $a Runden und $friend $b Runden. '
                'Wie viele Runden fahren beide zusammen?',
            a + b,
            'Zusammen heißt plus: $a + $b = ${a + b}. Brumm, brumm!');
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
              '$hero kauft $n Packungen mit je $k $pl und bekommt noch $b geschenkt. '
                  'Davon verschenkt $hero $c. Wie viele $pl hat $hero am Ende?',
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
          '$friend baut eine Zahlenmauer. Jeder Stein ist die Summe der zwei '
              'Steine darunter. Unten liegen $a, $b und $c, oben steht $peak. '
              'Welche Zahl steht in der Mitte links?',
          left,
          'Links in der Mitte: $a + $b = $left. Probe: $left + $right = $peak.');
    }
    return _math(
        'Zahlenmauer',
        '$friend baut eine Zahlenmauer aus drei Reihen. Jeder Stein ist die '
            'Summe der zwei Steine darunter. Unten liegen $a, $b und $c. '
            'Welche Zahl steht ganz oben?',
        peak,
        'Mitte: $a + $b = $left und $b + $c = $right. Oben: $left + $right = $peak.');
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
      final a = _between(1, 9);
      final b = _between(1, 10 - a);
      return _math(
          'Marktstand',
          '$hero kauft am Markt einen Ball um $a € und ein Buch um $b €. '
              'Wie viel kostet das zusammen?',
          a + b,
          '$a € + $b € = ${a + b} €.',
          suffix: ' €');
    }
    if (g == 2) {
      final price = _between(11, 89);
      final paid = price <= 50 ? 50 : 100;
      return _math(
          'Marktstand',
          '$hero kauft eine Spielzeug-Rakete um $price € und zahlt mit $paid €. '
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
    final wrong = <String>{
      for (final delta in [10, -10, 50, -50, 100, -100])
        if (change + delta > 0) _euro(change + delta),
    }.toList()
      ..shuffle(_random);
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
      explanation: '$a + $b = $sum. $sum $answer $other – '
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
        choices: _choicesWith('$end Uhr', [
          '${end + 1} Uhr',
          '${end - 1} Uhr',
          '${start + hours + 2} Uhr',
          '$start Uhr',
        ]),
        explanation: '$start Uhr + $hours = $end Uhr.',
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
      choices: _choicesWith('$answer Uhr', [
        '${fmt(total + 10)} Uhr',
        '${fmt(total - 10)} Uhr',
        '${fmt(total + 60)} Uhr',
        '${fmt(total - 15)} Uhr',
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
    final hero = _hero();
    final others = adventureOpposites
        .expand((p) => p)
        .where((w) => w != answer && w != shown)
        .toList()
      ..shuffle(_random);
    return AdventureTask(
      subject: 'Deutsch',
      unit: 'Gegenteil-Geschichten',
      prompt: 'Verkehrte Welt! $hero ist heute gar nicht $shown – '
          '$hero ist genau das Gegenteil. Was ist $hero?',
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
      '${base.split(' ').last} + ${item[0]}',
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
      prompt: 'Wer bin ich? ${riddle[1]} ${riddle[2]} ${riddle[3]}',
      answer: riddle[0],
      choices: _choicesWith(riddle[0], others),
      explanation: 'Gut geraten: Das ist ${riddle[0]}! ${riddle[3]}',
      visual: 'science',
    );
  }

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
    // Jänner/Februar Winter, März–Mai Frühling, Juni–August Sommer,
    // September–November Herbst, Dezember Winter (meteorologisch).
    final season = seasons[((month + 1) % 12) ~/ 3];
    return AdventureTask(
      subject: 'Sachunterricht',
      unit: 'Monate und Wochentage',
      prompt: 'In welcher Jahreszeit liegt der ${adventureMonths[month]} bei uns '
          'in Österreich meistens?',
      answer: season,
      choices: _shuffle([...seasons]),
      explanation: 'Der ${adventureMonths[month]} gehört meistens zum $season.',
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
          ? 'Lumo fliegt mit dem Ballon über ${state[0]}. '
              'Wie heißt die Landeshauptstadt?'
          : 'Lumo landet in ${state[1]}. In welchem Bundesland ist das?',
      answer: answer,
      choices: _choicesWith(answer, others),
      explanation: '${state[1]} ist die Landeshauptstadt von ${state[0]}.',
      visual: 'science',
    );
  }

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
      explanation: '${three.join(', ')} gehören zu ${main[0]}. '
          '$odd gehört zu ${other[0]}.',
    );
  }

  AdventureTask _secretCode(int g) {
    final word = _pick(adventureCodeWords);
    String encode(String w) =>
        w.split('').map((c) => '${c.codeUnitAt(0) - 64}').join('-');
    final others = adventureCodeWords
        .where((w) => w != word && (w.length - word.length).abs() <= 1)
        .toList()
      ..shuffle(_random);
    return AdventureTask(
      subject: 'Logik',
      unit: 'Geheimcode',
      prompt: 'Geheimbotschaft von Lumo! Im Code ist A = 1, B = 2, C = 3 und so '
          'weiter bis Z = 26. Welches Wort heißt ${encode(word)}?',
      answer: word,
      choices: _choicesWith(word, others.isEmpty ? adventureCodeWords : others),
      explanation: '${word.split('').map((c) => '$c = ${c.codeUnitAt(0) - 64}').join(', ')}.',
    );
  }
}
