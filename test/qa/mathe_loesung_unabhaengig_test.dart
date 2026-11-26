import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/task_quality_guard.dart';

/// Mathematik: Lösungen unabhängig nachrechnen.
///
/// Jede Mathe-Rubrik aller Klassen wird mit 300 Startwerten erzeugt. Für jede
/// Aufgabe mit Rechenstruktur rechnet ein eigener Löser aus dem Aufgabentext
/// (nicht aus dem Generator) die Lösung nach. Zusätzlich gilt für jede
/// Aufgabe: Lösung genau einmal unter den Karten, Ablenker verschieden und
/// falsch, Zahlen im Zahlenraum der Klasse (Lehrplan VS 2023: Klasse 1 bis
/// 20, Klasse 2 bis 100, Klasse 3 bis 1000, Klasse 4 bis 1 000 000).
///
/// Neue Aufgabenmuster fallen auf: Jedes Muster (Teil der Aufgaben-ID) ist
/// entweder durch einen Löser abgedeckt oder steht in [_reviewedLists] als
/// feste, gelesene Liste. Ein unbekanntes Muster lässt den Test scheitern.
const _seeds = 300;

const _reviewedLists = <String, String>{
  'mathe-formen-erkennen': 'feste Formenliste (Ecken/Seiten), gelesen',
  'mathe-zahlwort-erkennen': 'Zahlwörter 0-20, gelesen',
  'mathe-menge-vergleichen': 'Bildmengen, Lösung aus Symbolanzahl geprüft',
  'mathe-tag-stunden': 'feste Zeitspannen-Liste, gelesen (2026-11-26)',
  'mathe-geld-mehr': 'Preisvergleich, Lösung aus Preisen geprüft',
  'mathe-symmetrie-form': 'Faltliste ja/nein, gelesen',
  'mathe-symmetrieachsen': 'Achsenliste, gelesen',
  'mathe-uhrzeit-viertel-halbe': 'Uhrzeit steht nur im Bild (Uhr-Feld)',
  'mathe-nachzeichnen-dreieck': 'Zeichenaufgabe ohne Auswahl',
  'mathe-nachzeichnen-kreis': 'Zeichenaufgabe ohne Auswahl',
  'mathe-nachzeichnen-quadrat': 'Zeichenaufgabe ohne Auswahl',
  'mathe-nachzeichnen-rechteck': 'Zeichenaufgabe ohne Auswahl',
  'mathe-nachzeichnen-stern': 'Zeichenaufgabe ohne Auswahl',
};

/// Muster, deren Karten typische Lesefehler sind und nicht Nachbarwerte:
/// Die Lage nach Größe ist dort kein Lösungsweg.
const _rankExempt = <String, String>{
  'mathe-uhrzeit-viertel-halbe':
      'Uhr ablesen: Karten = nächste Stunde, vertauschte Zeiger, falsche '
          'Viertelstunde; die Zeit steht nur im Bild',
};

int _int(String text) => int.parse(text.replaceAll(RegExp(r'[\s\u00a0.]'), ''));

String _euro(int cents) => cents % 100 == 0
    ? '${cents ~/ 100} €'
    : '${cents ~/ 100},${(cents % 100).toString().padLeft(2, '0')} €';

int _cents(String text) {
  final parts = text.split(',');
  return int.parse(parts[0]) * 100 +
      (parts.length > 1 ? int.parse(parts[1].padRight(2, '0')) : 0);
}

String _sign(int a, int b) => a < b ? '<' : (a > b ? '>' : '=');

/// Unabhängige Lösung aus dem Aufgabentext oder null (kein Löser).
String? solve(String prompt, String pattern) {
  final p = prompt.replaceAll('\u00a0', ' ');
  RegExpMatch? m(String source) => RegExp(source).firstMatch(p);
  int g(RegExpMatch match, int i) => _int(match.group(i)!);
  RegExpMatch? r;

  if ((r = m(r'^(?:Schriftlich: )?(\d+) ([+\-×:]) (\d+) = \?$')) != null) {
    final a = g(r!, 1), b = g(r, 3);
    return switch (r.group(2)) {
      '+' => '${a + b}',
      '-' => '${a - b}',
      '×' => '${a * b}',
      _ => a % b == 0 ? '${a ~/ b}' : '${a ~/ b} Rest ${a % b}',
    };
  }
  if ((r = m(r'^(\d+),(\d) \+ (\d+),(\d) = \?$')) != null) {
    final tenths = (g(r!, 1) * 10 + g(r, 2)) + (g(r, 3) * 10 + g(r, 4));
    return '${tenths ~/ 10},${tenths % 10}';
  }
  if ((r = m(r'^(\d+)/(\d+) \+ (\d+)/(\d+) = \?$')) != null &&
      r!.group(2) == r.group(4)) {
    return '${g(r, 1) + g(r, 3)}/${g(r, 2)}';
  }
  if ((r = m(r'Erweitere den Bruch (\d+)/(\d+) mit (\d+)')) != null) {
    return '${g(r!, 1) * g(r, 3)}/${g(r, 2) * g(r, 3)}';
  }
  for (final (unit, small, factor) in const [
    ('kg', 'g', 1000),
    ('Liter', 'Milliliter', 1000),
    ('Meter', 'Zentimeter', 100),
  ]) {
    final big = switch (unit) {
      'kg' => 'Gramm',
      'Liter' => 'Milliliter',
      _ => 'Zentimeter',
    };
    if ((r = m('^Wie viele $big sind (\\d+) $unit(?: und (\\d+) $small)?\\?\$')) !=
        null) {
      return '${g(r!, 1) * factor + (r.group(2) == null ? 0 : g(r, 2))}';
    }
  }
  if (p == 'Wie viele Zentimeter sind ein halber Meter?') return '50';
  if ((r = m(r'^Wie viele Minuten sind (\d+) Stunden?(?: und (\d+) Minuten)?\?$')) !=
      null) {
    return '${g(r!, 1) * 60 + (r.group(2) == null ? 0 : g(r, 2))}';
  }
  if ((r = m(r'Ein Band ist (\d+) cm lang\. Wie viele Zentimeter fehlen auf 1 Meter')) !=
      null) {
    return '${100 - g(r!, 1)}';
  }
  if ((r = m(r'^Zwei Bänder sind (\d+) cm und (\d+) cm lang')) != null) {
    return '${g(r!, 1) + g(r, 2)}';
  }
  if ((r = m(r'^Ein Seil ist (\d+) cm lang, ein Band ist (\d+) cm lang')) != null) {
    return '${g(r!, 1) - g(r, 2)}';
  }
  if ((r = m(r'Rechteck ist (\d+) cm lang und (\d+) cm breit\. Wie groß ist der (Umfang|Flächeninhalt)')) !=
      null) {
    final a = g(r!, 1), b = g(r, 2);
    return r.group(3) == 'Umfang' ? '${2 * (a + b)} cm' : '${a * b} cm²';
  }
  if ((r = m(r'^Was ist das Doppelte von (\d+)\?$')) != null) {
    return '${2 * g(r!, 1)}';
  }
  if ((r = m(r'^Was ist die Hälfte von (\d+)\?$')) != null) {
    return g(r!, 1).isEven ? '${g(r, 1) ~/ 2}' : 'UNGERADE';
  }
  if ((r = m(r'^Wie viele (Zehner|Einer) hat (\d+)\?$')) != null) {
    final n = g(r!, 2);
    return r.group(1) == 'Zehner' ? '${n ~/ 10}' : '${n % 10}';
  }
  if ((r = m(r'^Ist (\d+) gerade oder ungerade\?$')) != null) {
    return g(r!, 1).isEven ? 'gerade' : 'ungerade';
  }
  if ((r = m(r'^Wie oft passt (\d+) in (\d+)\?$')) != null) {
    return g(r!, 2) % g(r, 1) == 0 ? '${g(r, 2) ~/ g(r, 1)}' : 'REST';
  }
  if ((r = m(r'^(?:Knobelaufgabe: )?Welches Zeichen passt\? ([\d ]+) ⬜ ([\d ]+)$')) !=
      null) {
    return _sign(g(r!, 1), g(r, 2));
  }
  if ((r = m(r'Welches Zeichen gehört in die Lücke\? (\d+) ([+\-−]) (\d+) ⬜ (\d+)')) !=
      null) {
    final left = r!.group(2) == '+' ? g(r, 1) + g(r, 3) : g(r, 1) - g(r, 3);
    return _sign(left, g(r, 4));
  }
  if ((r = m(r'^Wie viele (\d+)-€-(Münzen|Scheine) ergeben (\d+) €\?$')) != null) {
    final n = g(r!, 3) ~/ g(r, 1);
    final word = r.group(2) == 'Münzen'
        ? (n == 1 ? 'Münze' : 'Münzen')
        : (n == 1 ? 'Schein' : 'Scheine');
    return g(r, 3) % g(r, 1) == 0 ? '$n $word' : 'REST';
  }
  if ((r = m(r'Welchen Wert hat die Ziffer (\d) in ([\d ]+)\?')) != null) {
    final digits = r!.group(2)!.replaceAll(' ', '');
    final digit = r.group(1)!;
    if (digit.allMatches(digits).length != 1) return 'MEHRDEUTIG';
    final place = digits.length - 1 - digits.indexOf(digit);
    final value = int.parse(digit) * _pow10(place);
    return _grouped(value);
  }
  if ((r = m(r'★ ([+\-−]) (\d+) = (\d+)')) != null) {
    return r!.group(1) == '+' ? '${g(r, 3) - g(r, 2)}' : '${g(r, 3) + g(r, 2)}';
  }
  if ((r = m(r'(\d+) ([+\-−·×]) ★ = (\d+)')) != null) {
    final a = g(r!, 1), c = g(r, 3);
    return switch (r.group(2)) {
      '+' => '${c - a}',
      '·' || '×' => c % a == 0 ? '${c ~/ a}' : 'REST',
      _ => '${a - c}',
    };
  }
  if ((r = m(r'★ [·×] (\d+) = (\d+)')) != null) {
    return g(r!, 2) % g(r, 1) == 0 ? '${g(r, 2) ~/ g(r, 1)}' : 'REST';
  }
  if ((r = m(r'^Welche Zahl fehlt\? (.+)$')) != null) {
    final items = r!.group(1)!.split(', ');
    final known = <(int, int)>[
      for (var i = 0; i < items.length; i++)
        if (items[i] != '_') (i, int.parse(items[i])),
    ];
    final gap = items.indexOf('_');
    final step = (known[1].$2 - known[0].$2) ~/ (known[1].$1 - known[0].$1);
    return '${known[0].$2 + (gap - known[0].$1) * step}';
  }
  if ((r = m(r'^Was ist (die Hälfte|ein Viertel|ein Achtel) von (\d+)\?$')) != null) {
    final divisor = switch (r!.group(1)) {
      'die Hälfte' => 2,
      'ein Viertel' => 4,
      _ => 8,
    };
    return g(r, 2) % divisor == 0 ? '${g(r, 2) ~/ divisor}' : 'REST';
  }
  if ((r = m(r'^Runde ([\d ]+) auf (Zehner|Hunderter|Tausender)\.$')) != null) {
    final n = g(r!, 1);
    final step = switch (r.group(2)) {
      'Zehner' => 10,
      'Hunderter' => 100,
      _ => 1000,
    };
    return _grouped(((n + step ~/ 2) ~/ step) * step);
  }
  if ((r = m(r'Ein Quadrat hat die Seitenlänge (\d+) cm\. Wie groß ist der (Umfang|Flächeninhalt)')) !=
      null) {
    final a = g(r!, 1);
    return r.group(2) == 'Umfang' ? '${4 * a} cm' : '${a * a} cm²';
  }
  if ((r = m(r'^\S+ hat (\d+) Sticker\. \S+ hat (\d+) Sticker mehr als \S+\. Wie viele Sticker haben beide zusammen')) !=
      null) {
    return '${2 * g(r!, 1) + g(r, 2)}';
  }
  if ((r = m(r'kauft (?:einen|eine|ein) .+? um (\d+) € und zahlt mit (\d+) €\. Wie viel Wechselgeld')) !=
      null) {
    return '${g(r!, 2) - g(r, 1)} €';
  }
  if ((r = m(r'wohnen (\d+) Menschen\. In einem Jahr ziehen (\d+) Menschen weg')) != null) {
    return '${g(r!, 1) - g(r, 2)}';
  }
  if ((r = m(r'am Vormittag (\d+) Schritte und am Nachmittag (\d+) Schritte')) != null ||
      (r = m(r'in der ersten Runde (\d+) Punkte und in der zweiten Runde (\d+) Punkte')) != null ||
      (r = m(r'sammelt bei Lumos Kart-Spiel (\d+) Punkte\. In der zweiten Runde kommen (\d+) Punkte dazu')) !=
          null) {
    return '${g(r!, 1) + g(r, 2)}';
  }
  if ((r = m(r'kauft (\d+) Packungen\. In jeder Packung sind (\d+) \S+\. \S+ bekommt noch (\d+) \S+ dazu\. Von allen \S+ verschenkt \S+ (\d+)\.')) !=
      null) {
    return '${g(r!, 1) * g(r, 2) + g(r, 3) - g(r, 4)}';
  }
  if ((r = m(r'hat (\d+) \S+\. \S+ bekommt (\d+) dazu und verschenkt dann (\d+)\.')) != null) {
    return '${g(r!, 1) + g(r, 2) - g(r, 3)}';
  }
  // Abenteuer: Zahlenmauer, Zahlenrätsel, Uhr, Markt.
  if ((r = m(r'Unten liegen (\d+), (\d+) und (\d+)\. Welche Zahl steht ganz oben')) !=
      null) {
    return '${g(r!, 1) + 2 * g(r, 2) + g(r, 3)}';
  }
  if ((r = m(r'Unten liegen (\d+), (\d+) und (\d+), oben steht (\d+)\. Welche Zahl steht in der Mitte (links|rechts)')) !=
      null) {
    final left = g(r!, 1) + g(r, 2), right = g(r, 2) + g(r, 3);
    if (left + right != g(r, 4)) return 'MAUER_FALSCH';
    return r.group(5) == 'links' ? '$left' : '$right';
  }
  if ((r = m(r'denkt sich eine Zahl und nimmt (\d+) weg\. Übrig bleiben (\d+)')) !=
      null) {
    return '${g(r!, 1) + g(r, 2)}';
  }
  if ((r = m(r'nimmt sie (\d+)-mal\. Das ergibt (\d+)')) != null) {
    return g(r!, 2) % g(r, 1) == 0 ? '${g(r, 2) ~/ g(r, 1)}' : 'REST';
  }
  if ((r = m(r'Wenn \S+ (\d+) dazuzählt, kommt (\d+) heraus')) != null) {
    return '${g(r!, 2) - g(r, 1)}';
  }
  if ((r = m(r'verdoppelt eine Zahl und bekommt (\d+)')) != null) {
    return g(r!, 1).isEven ? '${g(r, 1) ~/ 2}' : 'UNGERADE';
  }
  if ((r = m(r'beginnt um (\d+) Uhr und dauert (\d+) Stunden?')) != null) {
    final hour = g(r!, 1) + g(r, 2);
    return '${hour > 24 ? hour - 24 : hour} Uhr';
  }
  if ((r = m(r'startet um (\d+):(\d+) Uhr .* dauert (\d+) Minuten')) != null) {
    final total = g(r!, 1) * 60 + g(r, 2) + g(r, 3);
    return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')} Uhr';
  }
  if ((r = m(r'kauft am Markt (?:einen|eine|ein) .+? um (\d+) € und (?:einen|eine|ein) .+? um (\d+) €\. Wie viel kostet das zusammen')) !=
      null) {
    return '${g(r!, 1) + g(r, 2)} €';
  }
  if ((r = m(r'kauft (?:\S+ )?(?:(\d+)-mal )?(?:einen|eine|ein) [^(]+\((?:je )?([\d,]+) €\) und (?:einen|eine|ein) [^(]+\(([\d,]+) €\)\. \S+ zahlt mit (\d+) €')) !=
      null) {
    final count = r!.group(1) == null ? 1 : g(r, 1);
    return _euro(g(r, 4) * 100 - count * _cents(r.group(2)!) - _cents(r.group(3)!));
  }
  if ((r = m(r'Diagramm: Montag (\d+), Dienstag (\d+), Mittwoch (\d+), Donnerstag (\d+) Kinder\. (.*)')) !=
      null) {
    const days = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag'];
    final values = [for (var i = 1; i <= 4; i++) g(r!, i)];
    final question = r!.group(5)!;
    String extreme(int target) {
      final at = [for (var i = 0; i < 4; i++) if (values[i] == target) days[i]];
      return at.length == 1 ? at.single : 'MEHRDEUTIG';
    }

    if (question.contains('meisten')) {
      return extreme(values.reduce((a, b) => a > b ? a : b));
    }
    if (question.contains('wenigsten')) {
      return extreme(values.reduce((a, b) => a < b ? a : b));
    }
    if (question.contains('zusammen')) return '${values.reduce((a, b) => a + b)}';
    final more = RegExp(r'am (\w+) mehr da als am (\w+)').firstMatch(question);
    if (more != null) {
      return '${values[days.indexOf(more.group(1)!)] - values[days.indexOf(more.group(2)!)]}';
    }
    return null;
  }
  if ((r = m(r'Drei Kinder sammeln Sterne: (\d+), (\d+) und (\d+)\. Sie teilen')) !=
      null) {
    final sum = g(r!, 1) + g(r, 2) + g(r, 3);
    return sum % 3 == 0 ? '${sum ~/ 3}' : 'REST';
  }
  // Rechengeschichten.
  if ((r = m(r'fährt \S+ (\d+) Runden? und \S+ (\d+) Runden?')) != null) {
    return '${g(r!, 1) + g(r, 2)}';
  }
  if ((r = m(r'Beim Schulfest sind (\d+) Zuschauer, beim Kart-Rennen (\d+) Zuschauer')) !=
          null ||
      (r = m(r'sind (\d+) Zuschauer im Stadion, beim zweiten (\d+)\.')) != null) {
    return '${g(r!, 1) - g(r, 2)}';
  }
  if ((r = m(r'ist (\d+) Meter lang\. \S+ ist schon (\d+) Meter gegangen')) != null) {
    return '${g(r!, 1) - g(r, 2)}';
  }
  if ((r = m(r'(\d+) Meter am Vormittag und (\d+) Meter am Nachmittag')) != null) {
    return '${g(r!, 1) + g(r, 2)}';
  }
  if ((r = m(r'^Es gibt (\d+) \S+\. \S+ legt in jed\S+ \S+ (\d+) ')) != null) {
    return '${g(r!, 1) * g(r, 2)}';
  }
  if ((r = m(r'^(\d+) \S+ werden gerecht an (\d+) \S+ verteilt\. Wie viele')) != null) {
    return g(r!, 1) % g(r, 2) == 0 ? '${g(r, 1) ~/ g(r, 2)}' : 'REST';
  }
  if ((r = m(r'sammelt .*? (\d+) (\S+)\. Dann findet \S+ noch (\d+)')) != null) {
    return '${g(r!, 1) + g(r, 3)}';
  }
  if ((r = m(r'hat (\d+) \S+\. \S+ schenkt \S+ (\d+) davon')) != null) {
    return '${g(r!, 1) - g(r, 2)}';
  }
  if ((r = m(r'^\S+ hat (\d+) (\S+), \S+ hat (\d+) \S+\. Wie viele \S+ hat \S+ mehr als')) !=
      null) {
    return '${g(r!, 1) - g(r, 3)}';
  }
  // Sachaufgaben mit festem Bauplan.
  final numbers = [for (final n in RegExp(r'\d+').allMatches(p)) int.parse(n[0]!)];
  if (pattern == 'mathe-sachaufgabe-ein-schritt' && numbers.length == 2) {
    return '${numbers[0] + numbers[1]}';
  }
  if (pattern == 'mathe-sachaufgabe-wegnehmen' && numbers.length == 2) {
    return '${numbers[0] - numbers[1]}';
  }
  if (pattern == 'mathe-sachaufgabe-zwei-schritte' && numbers.length == 3) {
    final [a, b, c] = numbers;
    if (p.contains('mit je') && p.contains('getragen')) return '${a * b - c}';
    if (p.contains('mit je')) return '${a * b + c}';
    if (p.contains('mehr als Anna')) return '${a + (a + b)}';
    if (p.contains('kommen neu dazu') || p.contains('gehen neu auf') ||
        p.contains('hängen')) {
      return p.contains('holen') ? '${a - b + c}' : '${a + b - c}';
    }
    if (p.contains('verstecken') || p.contains('zur Rutsche')) {
      return '${a + b - c}';
    }
    if (p.contains('verkauft') || p.contains('steigen')) return '${a - b - c}';
    if (p.contains('zusammen') || p.contains('gelesen')) return '${a + b + c}';
  }
  if (pattern == 'mathe-sachaufgabe-drei-schritte') {
    if ((r = m(r'starten (\d+) Gruppen mit je (\d+) Kindern\. (\d+) Kinder kommen später dazu, (\d+) Kinder')) !=
        null) {
      return '${g(r!, 1) * g(r, 2) + g(r, 3) - g(r, 4)}';
    }
    if ((r = m(r'an (\d+) Tagen jeden Tag (\d+) gelbe und (\d+) blaue Sterne\. (\d+) Sterne')) !=
        null) {
      return '${g(r!, 1) * (g(r, 2) + g(r, 3)) - g(r, 4)}';
    }
    if ((r = m(r'(\d+) Kisten mit je (\d+) Flaschen Saft und (\d+) Kisten mit je (\d+) Flaschen Wasser\. (\d+) Flaschen bleiben')) !=
        null) {
      return '${g(r!, 1) * g(r, 2) + g(r, 3) * g(r, 4) - g(r, 5)}';
    }
    if ((r = m(r'stehen (\d+) Bücher\. Am Montag werden (\d+) ausgeliehen, am Dienstag (\d+)\. Am Mittwoch kommen (\d+) zurück')) !=
        null) {
      return '${g(r!, 1) - g(r, 2) - g(r, 3) + g(r, 4)}';
    }
    if ((r = m(r'Zug mit (\d+) Waggons sitzen (\d+) Erwachsene und (\d+) Kinder\. Am Bahnhof steigen (\d+) Personen aus und (\d+) ein')) !=
        null) {
      return '${g(r!, 2) + g(r, 3) - g(r, 4) + g(r, 5)}';
    }
    if ((r = m(r'liegen (\d+) Äpfel und (\d+) Birnen\. Eine zweite Kiste ist genau gleich gefüllt\. (\d+) Früchte')) !=
        null) {
      return '${2 * (g(r!, 1) + g(r, 2)) - g(r, 3)}';
    }
    if ((r = m(r'^(\d+) Sammelkarten werden gerecht an (\d+) Kinder verteilt\. Jedes Kind verschenkt (\d+) Karten und bekommt später (\d+)')) !=
        null) {
      if (g(r!, 1) % g(r, 2) != 0) return 'REST';
      return '${g(r, 1) ~/ g(r, 2) - g(r, 3) + g(r, 4)}';
    }
    if ((r = m(r'kauft (\d+) Hefte um je (\d+) € und ein Buch um (\d+) €\. Er zahlt mit einem (\d+)-€-Schein')) !=
        null) {
      return '${g(r!, 4) - g(r, 1) * g(r, 2) - g(r, 3)}';
    }
  }
  return null;
}

int _pow10(int n) => n == 0 ? 1 : 10 * _pow10(n - 1);

String _grouped(int value) {
  final digits = '$value';
  if (digits.length < 5) return digits;
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('\u00a0');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

String _norm(String text) => text.replaceAll('\u00a0', ' ').trim();

/// Vergleichswert einer Karte: ganze Zahl (mit gleicher Einheit) oder
/// Uhrzeit in Minuten; sonst null (Text, Bruch, Rest).
int? _comparable(String card) {
  final text = _norm(card).replaceAll(' ', '');
  final time = RegExp(r'^(\d{1,2}):(\d{2})Uhr$').firstMatch(text);
  if (time != null) {
    return int.parse(time.group(1)!) * 60 + int.parse(time.group(2)!);
  }
  final number = RegExp(
          r'^(\d+)(?:,(\d{2}))?(€|Uhr|cm|cm²|Scheine?|Münzen?|Minuten)?$')
      .firstMatch(text);
  if (number == null) return null;
  return int.parse(number.group(1)!) * 100 +
      (number.group(2) == null ? 0 : int.parse(number.group(2)!));
}

void main() {
  const guard = TaskQualityGuard();
  const limits = <int, int>{1: 20, 2: 100, 3: 1000, 4: 1000000};
  final coverage = <String, int>{};
  final solved = <String, int>{};
  // Lage der Lösung unter den Karten, nach Größe sortiert (Befund S1).
  final ranks = <String, List<int>>{};

  for (var grade = 1; grade <= 4; grade++) {
    test('Klasse $grade: alle Mathe-Rubriken, je $_seeds Startwerte', () {
      final errors = <String>[];
      for (final unit in Curriculum.unitsForGrade('Mathematik', grade)) {
        for (var seed = 0; seed < _seeds; seed++) {
          final task = ExerciseFactory(seed: seed * 104729 + grade)
              .nextExact(grade: grade, subject: 'Mathematik', unit: unit);
          final pattern = task.id.replaceFirst(RegExp(r'-\d{6,}-\d+-\d+$'), '');
          coverage[pattern] = (coverage[pattern] ?? 0) + 1;
          final where = '$grade/$unit/$seed: ${task.prompt}';
          if (guard.problems(task).isNotEmpty) {
            errors.add('$where -> ${guard.problems(task)}');
          }
          if (task.choices.isNotEmpty) {
            final normalized = task.choices.map(_norm).toList();
            if (normalized.where((c) => c == _norm(task.answer)).length != 1) {
              errors.add('$where: Lösung nicht genau einmal ${task.choices}');
            }
            if (normalized.toSet().length != normalized.length) {
              errors.add('$where: doppelte Karten ${task.choices}');
            }
          }
          // Zahlenraum der Klasse: Lösung und Zahlen im Text.
          final limit = limits[task.difficulty]!;
          final plain = task.prompt.replaceAll(RegExp(r'(\d)[\s\u00a0](\d{3})'), r'$1$2');
          for (final n in RegExp(r'\d+').allMatches(plain)) {
            if (int.parse(n[0]!) > limit &&
                !RegExp(r'Gramm|Milliliter|Meter|Minuten|Zentimeter')
                    .hasMatch(task.prompt)) {
              errors.add('$where: Zahl ${n[0]} über Zahlenraum $limit');
              break;
            }
          }
          final values = [for (final c in task.choices) _comparable(c)];
          if (task.choices.length == 4 && !values.contains(null)) {
            final sorted = [...values]..sort();
            final answerValue = _comparable(task.answer)!;
            (ranks[pattern] ??= [0, 0, 0, 0])[sorted.indexOf(answerValue)]++;
          }
          final expected = solve(task.prompt, pattern);
          if (expected == null) continue;
          solved[pattern] = (solved[pattern] ?? 0) + 1;
          if (_norm(expected) != _norm(task.answer)) {
            errors.add('$where: Lösung ${task.answer}, nachgerechnet $expected');
          }
        }
      }
      expect(errors, isEmpty, reason: errors.take(15).join('\n'));
    });
  }

  test('die Lösung ist nicht an ihrer Lage unter den Karten erkennbar', () {
    // Gleichverteilt wäre die Lösung in 50 % der Aufgaben die kleinste oder
    // größte Karte. Früher war sie bei Uhr-Abenteuer immer die zweit-
    // früheste Uhrzeit und bei den übrigen Abenteuern in rund 85 % eine
    // mittlere Karte.
    final skewed = <String>[];
    for (final entry in ranks.entries) {
      if (_rankExempt.containsKey(entry.key)) continue;
      final counts = entry.value;
      final total = counts.fold<int>(0, (a, b) => a + b);
      if (total < 200) continue;
      final outer = (counts[0] + counts[3]) / total;
      if (outer < .3 || counts.any((c) => c < total * .05)) {
        skewed.add('${entry.key}: $counts');
      }
    }
    expect(skewed, isEmpty, reason: skewed.join('\n'));
    expect(ranks.length, greaterThan(30));
  });

  test('jedes Aufgabenmuster ist nachgerechnet oder als Liste gelesen', () {
    final unknown = <String>[];
    for (final entry in coverage.entries) {
      if (_reviewedLists.containsKey(entry.key)) continue;
      final share = (solved[entry.key] ?? 0) / entry.value;
      // Rechengeschichten mischen viele Baupläne; mindestens 90 % jeder
      // anderen Familie werden von einem Löser nachgerechnet.
      if (share < .9) {
        unknown.add('${entry.key}: ${(share * 100).round()} % von ${entry.value}');
      }
    }
    expect(unknown, isEmpty,
        reason: 'Neues oder ungeprüftes Muster: Löser ergänzen oder als '
            'gelesene Liste begründen.\n${unknown.join('\n')}');
    final total = coverage.values.fold<int>(0, (a, b) => a + b);
    final checked = solved.values.fold<int>(0, (a, b) => a + b);
    // ignore: avoid_print
    print('Mathe: $total Aufgaben, ${coverage.length} Muster, '
        '$checked unabhängig nachgerechnet');
    expect(checked, greaterThan(30000));
  });
}
