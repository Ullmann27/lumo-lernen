import 'school_exercise_generator.dart';

/// Immediate offline explanations of the next step, never the stored answer.
class TaskHintService {
  const TaskHintService();

  String explain(LumoTask task, {int level = 1}) {
    // Fractional values need their own unit before any integer counting or
    // ten-bridge strategy is considered. Hints use only the visible givens.
    final fraction = _fractionHint(task, level);
    if (fraction != null) return fraction;
    final decimal = _decimalHint(task, level);
    if (decimal != null) return decimal;
    // Abenteuer- und Logik-Einheiten haben eigene Tipps in drei Stufen. Sie
    // richten sich nach dem Aufbau der Aufgabe, nicht nach einzelnen Zeichen
    // oder Wörtern im Text.
    final unitHint = _unitHint(task, level);
    if (unitHint != null) return unitHint;
    // Offline-Stellenwerthilfe mit drei verschiedenen Erklärungsformen.
    final placeValue = _placeValueHint(task, level);
    if (placeValue != null) return placeValue;
    if (level >= 2) return _guidedHint(task, level);
    final unit = task.unit.toLowerCase();
    final prompt = task.prompt.toLowerCase();
    if (task.subject == 'Logik') {
      return unit.contains('muster')
          ? 'Suche die Gruppe oder den Abstand, der sich wiederholt. Prüfe, ob deine Regel an jeder Stelle passt.'
          : 'Lies jede Angabe einzeln. Ordne die Figuren oder prüfe die Regeln nacheinander. Eine Antwort muss zu allen Angaben passen.';
    }
    if (task.handwriting || task.visual == 'shape_trace') {
      return 'Schau zuerst auf die Vorlage. Beginne an einem Punkt und zeichne langsam. Achte auf die Richtung und auf alle Teile der Form.';
    }
    if (task.subject == 'Mathematik') {
      if (prompt.contains('stunden hat ein tag')) {
        return 'Ein ganzer Tag umfasst Tag und Nacht. Überlege: Der Stundenzeiger läuft in dieser Zeit zweimal rund um das Zifferblatt.';
      }
      if (prompt.contains('kostet mehr')) {
        return 'Vergleiche beide Eurobeträge. Der größere Betrag ist teurer. Sind beide Zahlen gleich, kosten sie gleich viel.';
      }
      if (unit.contains('symmetrie')) {
        return 'Stell dir vor, du faltest die Form. Eine Spiegelachse liegt dort, wo beide Hälften genau aufeinanderpassen. Prüfe auch andere Faltlinien.';
      }
      if (unit.contains('umfang')) {
        return 'Beim Umfang gehst du außen um die ganze Figur. Addiere alle Seitenlängen; beim Rechteck gibt es jede Länge zweimal.';
      }
      if (unit.contains('flächen')) {
        return 'Beim Flächeninhalt zählst du die Kästchen im Inneren. Multipliziere beim Rechteck die Länge mit der Breite.';
      }
      if (unit.contains('uhrzeit')) {
        return 'Schau auf die Uhr: Der kurze Zeiger zeigt die Stunde, der lange Zeiger die Minuten. Steht der lange Zeiger auf der 12, ist es eine volle Stunde.';
      }
      if (RegExp(r'^wie viele minuten sind ').hasMatch(prompt)) {
        return 'Eine Stunde besteht aus 60 Minuten. Wandle zuerst die ganzen Stunden um und zähle übrige Minuten dazu.';
      }
      if (unit.contains('zeit')) {
        return 'Denk an deinen Tag und an den Kalender: Morgen, Mittag, Nachmittag, Abend und Nacht folgen aufeinander. Überlege, was du schon kennst, und vergleiche jede Antwort damit.';
      }
      if (unit.contains('länge')) {
        return 'Ein Meter sind 100 Zentimeter. Rechne zuerst die ganzen Meter um und zähle übrige Zentimeter dazu.';
      }
      if (unit.contains('masse')) {
        return 'Ein Kilogramm sind 1000 Gramm. Wandle die Kilogramm um und zähle die übrigen Gramm dazu.';
      }
      if (unit.contains('hohl') ||
          RegExp(r'^wie viele milliliter sind ').hasMatch(prompt)) {
        return 'Ein Liter sind 1000 Milliliter. Wandle die Liter um und zähle die übrigen Milliliter dazu.';
      }
      if (unit.contains('mittelwert')) {
        return 'Addiere zuerst alle angegebenen Werte. Teile die Summe anschließend durch die Anzahl der Werte.';
      }
      if (unit.contains('geld')) {
        return 'Lies zuerst, wie viel eine Münze oder ein Schein wert ist. Zähle immer diesen Wert weiter, bis du beim gesuchten Betrag bist.';
      }
      if (unit.contains('zehner')) {
        return 'In einer zweistelligen Zahl zeigt die linke Ziffer die Zehner, die rechte Ziffer die Einer. Prüfe, wonach die Frage fragt.';
      }
      if (unit.contains('verdoppel') || unit.contains('halbier')) {
        return 'Doppelt heißt: dieselbe Menge zweimal. Halbieren heißt: die Menge auf zwei gleich große Gruppen verteilen.';
      }
      if (unit.contains('gerade')) {
        return 'Bilde Paare. Bleibt nichts übrig, ist die Zahl gerade. Bleibt eines übrig, ist sie ungerade.';
      }
      if (unit.contains('zahlenstrahl') || unit.contains('zahlenreihe')) {
        return 'Lies die Zahlen in ihrer Reihenfolge. Prüfe, wie groß ein Schritt ist, und gehe diesen Schritt auch an der Lücke weiter.';
      }
      if (unit.contains('mengen')) {
        return 'Zähle zuerst die linke Seite, dann die rechte Seite. Wo hast du weiter gezählt? Dort sind mehr.';
      }
      final million = _millionHint(task.prompt, 1);
      if (million != null) return million;
      if (unit.contains('vergleich') || unit.contains('zahlenraum')) {
        return 'Zähle zuerst die Stellen: Die Zahl mit mehr Stellen ist größer. Bei gleich vielen Stellen vergleichst du von links, Stelle für Stelle. Die offene Seite des Zeichens zeigt zur größeren Zahl.';
      }
      if (unit.contains('diagramm')) {
        return 'Lies zuerst ab, was jeder Balken zeigt. Lies dann die Frage noch einmal: Sollst du vergleichen, zusammenzählen oder den Unterschied finden?';
      }
      if (unit.contains('text') || unit.contains('sachaufgabe')) {
        return 'Was weißt du schon, und was wird gesucht? Etwas kommt dazu: plus. Etwas geht weg: minus. Gleich große Gruppen: mal oder geteilt. Rechne bei mehreren Schritten einen nach dem anderen.';
      }
      final operation = _operation(task.prompt);
      if (operation == '×' || unit.contains('einmaleins')) {
        return 'Denke an gleich große Gruppen. Zähle in gleich großen Schritten oder nutze eine Malaufgabe, die du schon kennst.';
      }
      if (unit.contains('division') ||
          RegExp(
            r'^\s*(?:(?:Schriftlich|Blitzlicht):\s*|Rechne\s+)?\d+\s*[:÷]\s*\d+\s*(?:=\s*\?)?[.?]?\s*$',
            caseSensitive: false,
          ).hasMatch(task.prompt)) {
        return 'Verteile die Menge in gleich große Gruppen. Prüfe mit der passenden Malaufgabe, ob deine Aufteilung stimmt.';
      }
      final missing = _MissingNumber.parse(task.prompt);
      if (missing != null) {
        return missing.plus
            ? 'Hier fehlt eine Zahl. Beginne mit der ersten Menge und lege so lange dazu, bis du beim Ergebnis bist. Zähle, wie viel du dazugelegt hast.'
            : 'Hier fehlt eine Zahl. Beginne bei der ersten Zahl und gehe zurück, bis du beim Ergebnis bist. Zähle, wie viele Schritte du gegangen bist.';
      }
      // Nur eine echte Rechnung „a − b“ oder „a + b“ bekommt den Minus- oder
      // Plus-Tipp. Ein Bindestrich in „Kart-Rennen“ oder „4-mal“ ist kein
      // Minuszeichen.
      if (operation == '−') {
        return 'Beginne bei der ersten Zahl und nimm die zweite Menge weg. Bei großen Zahlen hilft es, zuerst Zehner und dann Einer abzuziehen.';
      }
      if (operation == '+') {
        return 'Beginne mit der ersten Menge und lege die zweite dazu. Wenn es hilft, ergänze zuerst bis zum nächsten Zehner und zähle dann den Rest.';
      }
      return 'Lies, was genau gesucht wird. Prüfe Zahlen, Form oder Reihenfolge und vergleiche jede Antwort mit der Frage.';
    }
    if (task.subject == 'Englisch') {
      return 'Sprich das gesuchte Wort langsam. Überlege, zu welcher Gruppe es gehört, etwa Farbe, Zahl oder Tier. Vergleiche dann die angebotenen Wörter.';
    }
    if (task.subject == 'Sachunterricht') {
      return 'Achte auf das entscheidende Wort in der Frage. Vergleiche jede Möglichkeit mit dem, was du beobachten kannst oder schon gelernt hast. Schließe unpassende Möglichkeiten aus.';
    }
    if (task.subject == 'Lesen') {
      return 'Lies den Text noch einmal langsam. Suche die Stelle, die genau zur Frage passt. Deine Antwort muss im Text belegt sein.';
    }
    if (unit.contains('silb')) {
      return 'Sprich das Wort ganz langsam und klatsche die gesprochenen Silben. Zähle die Klatscher, nicht die Buchstaben.';
    }
    if (unit.contains('endlaut')) {
      return 'Sprich das Wort bis ganz zum Ende und höre auf den letzten Laut. Laut und geschriebener Buchstabe können verschieden sein.';
    }
    if (unit.contains('anfang') || unit.contains('laut')) {
      return 'Sprich das Wort langsam und höre auf den ersten Laut. Ein Laut kann mit mehreren Buchstaben geschrieben werden, etwa Sch.';
    }
    if (unit.contains('reim')) {
      return 'Sprich beide Wörter laut. Beim Reim klingt der Teil ab dem letzten betonten Vokal gleich; nur ähnliche Buchstaben reichen nicht.';
    }
    if (unit.contains('artikel')) {
      return 'Probiere der, die und das vor dem Namenwort. Sprich jede Verbindung langsam und achte auf das ganze Wort.';
    }
    if (unit.contains('mehrzahl')) {
      return 'Stell dir ein Ding und dann mehrere davon vor. Sprich beide Formen. Oft ändern sich Wortende oder Vokal.';
    }
    if (unit.contains('wortart') ||
        unit.contains('namen') ||
        unit.contains('tunwort') ||
        unit.contains('wiewort')) {
      return 'Ein Namenwort benennt etwas, ein Tunwort sagt, was geschieht, und ein Wiewort beschreibt eine Eigenschaft. Prüfe die Wörter einzeln.';
    }
    if (unit.contains('zeitform') || unit.contains('verbform')) {
      return 'Achte darauf, wer etwas tut und wann es passiert. Probiere die Form mit dem passenden Fürwort und dem Zeitwort im Satz.';
    }
    if (unit.contains('satz') ||
        unit.contains('rede') ||
        unit.contains('komma')) {
      return 'Lies den ganzen Satz. Achte auf Wortstellung, Satzanfang und Satzende. Bei wörtlicher Rede wird das Gesprochene mit Anführungszeichen markiert.';
    }
    return 'Sprich das Wort langsam. Achte auf die Stelle, nach der gefragt wird, und vergleiche die Schreibweisen Buchstabe für Buchstabe.';
  }

  /// Rechenzeichen einer reinen Rechnung „a ○ b = ?“ (auch mit „Schriftlich:“
  /// oder „Rechne …“ davor). Texte und Geschichten liefern null.
  String? _operation(String prompt) {
    final match = RegExp(
      r'^\s*(?:(?:Schriftlich|Blitzlicht):\s*|Rechne\s+)?\d+\s*([+−\-×·*:÷])\s*\d+\s*(?:=\s*\?)?[.?]?\s*$',
      caseSensitive: false,
    ).firstMatch(prompt);
    return switch (match?.group(1)) {
      '+' => '+',
      '-' || '−' => '−',
      '×' || '·' || '*' => '×',
      ':' || '÷' => ':',
      _ => null,
    };
  }

  /// Drei geschriebene Tippstufen für Lumos Abenteuer- und Logik-Einheiten:
  /// Einstieg, Teilschritt, fast gelöst. Die Lösung selbst wird nie genannt.
  String? _unitHint(LumoTask task, int level) {
    final stage = level.clamp(1, 3).toInt() - 1;
    String pick(List<String> stages) => stages[stage];
    List<int> numbers() => RegExp(r'\d+')
        .allMatches(task.prompt)
        .map((match) => int.parse(match.group(0)!))
        .toList(growable: false);

    if (task.subject == 'Logik') {
      return switch (task.unit) {
        'Was passt nicht?' => pick(const [
            'Finde das Gemeinsame von drei Dingen. Was gehört nicht in diese Gruppe?',
            'Sag zu jedem Ding, was es ist: ein Tier, ein Obst, ein Fahrzeug? Drei gehören zur selben Gruppe.',
            'Gib der Gruppe einen Namen. Prüfe jedes Ding: Passt der Name? Das eine Ding, das nicht passt, ist gesucht.',
          ]),
        'Geheimcode' => pick(const [
            'Lies genau, welche Zahl zu A gehört. Zähle von dort im Alphabet weiter. Beginne mit der ersten Zahl.',
            'Schreibe das Alphabet auf und nummeriere die Buchstaben. Übersetze die erste und die letzte Zahl. Welche Wörter passen dazu?',
            'Übersetze Zahl für Zahl und vergleiche mit den Wörtern auf den Karten. Auch die Anzahl der Buchstaben muss stimmen.',
          ]),
        _ => null,
      };
    }
    if (task.subject != 'Mathematik') return null;
    final prompt = task.prompt;
    switch (task.unit) {
      case 'Platzhalter-Rätsel':
        final plus = RegExp(r'(\d+) \+ ★ = (\d+)').firstMatch(prompt);
        if (plus != null) {
          final start = plus[1], total = plus[2];
          return pick([
            'Der Stern ist die Zahl, die noch fehlt. Zähle von $start weiter bis $total. Wie viele Schritte sind es?',
            'Starte bei $start. Zähle weiter, bis du bei $total bist, und zähle deine Schritte mit.',
            'Du kannst auch die Umkehraufgabe rechnen: $total − $start. Prüfe danach: $start plus deine Zahl muss $total ergeben.',
          ]);
        }
        final minus = RegExp(r'★ [−-] (\d+) = (\d+)').firstMatch(prompt);
        if (minus != null) {
          final taken = minus[1], rest = minus[2];
          return pick([
            'Vom Stern werden $taken weggenommen, dann bleiben $rest. Die Zahl unter dem Stern ist also größer als $rest. Rechne zurück.',
            'Lege zu $rest wieder $taken dazu. So findest du die Zahl unter dem Stern.',
            'Rechne die Umkehraufgabe $rest + $taken. Prüfe danach: deine Zahl minus $taken muss $rest ergeben.',
          ]);
        }
        final times = RegExp(r'(\d+) [·×] ★ = (\d+)').firstMatch(prompt);
        if (times != null) {
          final factor = times[1], product = times[2];
          return pick([
            'Gesucht ist, wie oft $factor in $product passt. Denk an die Einmaleins-Reihe von $factor.',
            'Zähle in ${factor}er-Schritten bis $product. Wie viele Schritte brauchst du?',
            'Rechne die Umkehraufgabe $product : $factor. Prüfe danach mit der Malaufgabe.',
          ]);
        }
        return null;
      case 'Zahlenrätsel':
        final values = numbers();
        if (values.length < 2 && !prompt.contains('verdoppelt')) return null;
        if (prompt.contains('dazuzählt')) {
          return pick([
            'Rechne rückwärts mit der Umkehraufgabe. Dazuzählen machst du mit Wegnehmen rückgängig.',
            'Starte bei ${values[1]} und nimm ${values[0]} wieder weg.',
            'Prüfe dein Ergebnis: Deine Zahl plus ${values[0]} muss ${values[1]} ergeben.',
          ]);
        }
        if (prompt.contains('nimmt') && prompt.contains('weg')) {
          return pick([
            'Rechne rückwärts mit der Umkehraufgabe. Wegnehmen machst du mit Dazuzählen rückgängig.',
            'Starte bei ${values[1]} und zähle ${values[0]} wieder dazu.',
            'Prüfe dein Ergebnis: Deine Zahl minus ${values[0]} muss ${values[1]} ergeben.',
          ]);
        }
        if (prompt.contains('verdoppelt') && values.isNotEmpty) {
          return pick([
            'Rechne rückwärts. Verdoppeln machst du mit Halbieren rückgängig.',
            'Teile ${values[0]} in zwei gleich große Teile.',
            'Prüfe dein Ergebnis: Deine Zahl und noch einmal dieselbe Zahl müssen zusammen ${values[0]} ergeben.',
          ]);
        }
        if (RegExp(r'\d+-mal').hasMatch(prompt)) {
          return pick([
            'Rechne rückwärts. Malnehmen machst du mit Teilen rückgängig.',
            'Wie oft passt ${values[0]} in ${values[1]}? Zähle in ${values[0]}er-Schritten bis ${values[1]}.',
            'Prüfe dein Ergebnis: ${values[0]}-mal deine Zahl muss ${values[1]} ergeben.',
          ]);
        }
        return null;
      case 'Zahlenmauer':
        final asksMiddle = prompt.contains('in der Mitte');
        return pick([
          'Zwei Steine nebeneinander ergeben zusammen den Stein darüber.',
          asksMiddle
              ? 'Der gesuchte Stein liegt auf den zwei linken Steinen der unteren Reihe. Zähle diese beiden zusammen.'
              : 'Rechne zuerst die zwei Steine in der Mitte: links plus Mitte und Mitte plus rechts.',
          asksMiddle
              ? 'Prüfe mit dem obersten Stein: Dein Stein und der rechte mittlere Stein müssen zusammen die Zahl ganz oben ergeben.'
              : 'Zähle jetzt die zwei mittleren Steine zusammen. Das ist der Stein ganz oben.',
        ]);
      case 'Marktstand':
        if (prompt.contains('Wechselgeld')) {
          final multi = RegExp(r'\) und ').hasMatch(prompt);
          return pick([
            multi
                ? 'Rechne zuerst aus, was alles zusammen kostet. Erst danach kommt das Wechselgeld.'
                : 'Wechselgeld ist der Unterschied zwischen dem Geld, das du gibst, und dem Preis.',
            multi
                ? 'Zähle die Preise zusammen. Kaufst du etwas mehrmals, nimm den Preis so oft.'
                : 'Zähle vom Preis weiter bis zum Geldbetrag, mit dem bezahlt wird. Wie viel fehlt?',
            'Prüfe dein Ergebnis: Preis und Wechselgeld müssen zusammen den bezahlten Betrag ergeben.',
          ]);
        }
        return pick(const [
          'Zusammen heißt: Zähle beide Preise zusammen.',
          'Beginne mit dem größeren Preis und zähle den kleineren dazu.',
          'Prüfe dein Ergebnis: Nimm einen Preis wieder weg. Dann muss der andere Preis übrig bleiben.',
        ]);
      case 'Größer, kleiner, gleich':
        return pick(const [
          'Links steht eine Rechnung. Rechne sie zuerst aus.',
          'Vergleiche dein Ergebnis mit der Zahl rechts: Ist es größer, kleiner oder gleich groß?',
          'Die offene Seite des Zeichens zeigt immer zur größeren Zahl. Sind beide gleich groß, passt das Gleichheitszeichen.',
        ]);
      case 'Uhr-Abenteuer':
        if (RegExp(r'\d:\d\d').hasMatch(prompt)) {
          return pick(const [
            'Zähle die Minuten von der Startzeit weiter. Eine Stunde hat 60 Minuten.',
            'Gehe zuerst bis zur nächsten vollen Stunde. Wie viele Minuten sind dann noch übrig?',
            'Zähle die übrigen Minuten nach der vollen Stunde weiter. Dauert es länger als 60 Minuten, zähle zuerst eine ganze Stunde weiter.',
          ]);
        }
        return pick(const [
          'Zähle die Stunden von der Startzeit weiter.',
          'Zeige mit dem Finger auf die Startzeit am Ziffernblatt. Gehe für jede Stunde eine Zahl weiter.',
          'Prüfe dein Ergebnis: Zähle von deiner Uhrzeit die Dauer wieder zurück. Dann musst du bei der Startzeit ankommen.',
        ]);
      case 'Rechengeschichten':
        return pick(_storyHints(prompt, numbers()));
      default:
        return null;
    }
  }

  /// Tipps für Lumos Rechengeschichten. Entscheidend ist, was in der
  /// Geschichte passiert (dazubekommen, verschenken, vergleichen, gleich
  /// große Gruppen, gerecht verteilen), nicht ein Bindestrich im Text.
  List<String> _storyHints(String prompt, List<int> values) {
    const check =
        'Lies die Frage noch einmal und prüfe, ob dein Ergebnis dazu passt. Schreibe einen Antwortsatz.';
    if (prompt.contains('Packungen') ||
        (prompt.contains('dazu') && prompt.contains('verschenkt'))) {
      return const [
        'Diese Geschichte hat mehrere Schritte. Was passiert zuerst, was danach?',
        'Rechne einen Schritt nach dem anderen und schreibe jedes Zwischenergebnis auf.',
        'Was dazukommt, rechnest du plus. Was verschenkt wird, rechnest du minus. Gleich große Packungen rechnest du mal.',
      ];
    }
    if (prompt.contains('gerecht')) {
      return [
        'Gerecht verteilen heißt teilen: Jeder bekommt gleich viel.',
        if (values.length >= 2)
          'Rechne ${values[0]} : ${values[1]}. Die Malaufgabe hilft dir: ${values[1]} mal wie viel ergibt ${values[0]}?'
        else
          'Teile die ganze Menge durch die Anzahl der Freunde.',
        check,
      ];
    }
    if (prompt.contains('legt in jede')) {
      return [
        'In jedem Behälter liegt gleich viel. Gleich große Gruppen zählt man mit einer Malaufgabe zusammen.',
        if (values.length >= 2)
          'Rechne ${values[0]} mal ${values[1]}.'
        else
          'Nimm die Anzahl in einem Behälter mal die Anzahl der Behälter.',
        check,
      ];
    }
    if (prompt.contains('mehr als')) {
      return [
        'Gefragt ist der Unterschied zwischen zwei Mengen. Den Unterschied findest du mit einer Minusaufgabe.',
        if (values.length >= 2)
          'Zähle von ${values[1]} weiter bis ${values[0]}. Wie viele Schritte sind es?'
        else
          'Zähle von der kleineren Zahl weiter bis zur größeren.',
        check,
      ];
    }
    if (prompt.contains('schenkt') ||
        prompt.contains('fehlen noch') ||
        prompt.contains('ziehen')) {
      return [
        'Hier geht etwas weg. Das ist eine Minusaufgabe.',
        if (values.length >= 2)
          'Starte bei ${values[0]} und nimm ${values[1]} weg.'
        else
          'Starte bei der ersten Zahl und nimm die zweite weg.',
        check,
      ];
    }
    if (prompt.contains('zusammen') ||
        prompt.contains('findet') ||
        prompt.contains('dazu')) {
      return [
        'Hier kommt etwas dazu oder zwei Mengen werden zusammengezählt. Das ist eine Plusaufgabe.',
        if (values.length >= 2)
          'Starte bei ${values[0]} und zähle ${values[1]} dazu.'
        else
          'Starte bei der ersten Zahl und zähle die zweite dazu.',
        check,
      ];
    }
    return const [
      'Lies die Geschichte langsam. Was weißt du schon? Was wird gefragt?',
      'Kommt etwas dazu, rechnest du plus. Geht etwas weg, rechnest du minus. Bei gleich großen Gruppen rechnest du mal oder geteilt.',
      check,
    ];
  }

  String? _decimalHint(LumoTask task, int level) {
    if (task.subject != 'Mathematik') return null;
    final expression = RegExp(
      r'^\s*(?:(?:Schriftlich|Blitzlicht):\s*|Rechne\s+)?([+-]?\d+(?:[.,]\d+)?)\s*([+\-−])\s*([+-]?\d+(?:[.,]\d+)?)\s*(?:=\s*\?)?[.?]?\s*$',
    ).firstMatch(task.prompt);
    if (expression == null) return null;
    final leftText = expression[1]!.replaceAll('.', ',');
    final rightText = expression[3]!.replaceAll('.', ',');
    if (!leftText.contains(',') && !rightText.contains(',')) return null;
    int precision(String text) =>
        text.contains(',') ? text.split(',')[1].length : 0;
    final leftPlaces = precision(leftText), rightPlaces = precision(rightText);
    final places = leftPlaces > rightPlaces ? leftPlaces : rightPlaces;
    if (places > 6) {
      return 'Ordne die Zahlen nach ihren Stellenwerten. Das Komma bleibt an seiner Stelle; Nachkommastellen sind keine ganzen Gegenstände.';
    }
    String padded(String text) {
      final parts = text.split(',');
      return '${parts[0]},${(parts.length > 1 ? parts[1] : '').padRight(places, '0')}';
    }

    int? scaled(String text) {
      final digits = padded(text).replaceAll(',', '');
      if (digits.replaceAll(RegExp(r'[+-]'), '').length > 12) return null;
      return int.tryParse(digits);
    }

    final left = scaled(leftText), right = scaled(rightText);
    const units = [
      '',
      'Zehntel',
      'Hundertstel',
      'Tausendstel',
      'Zehntausendstel',
      'Hunderttausendstel',
      'Millionstel'
    ];
    final unit = units[places];
    final subtraction = expression[2] != '+';
    if (level <= 1) {
      return 'Achte auf das Komma. Einer stehen unter Einern, $unit unter $unit. '
          'Die Ziffern rechts vom Komma bezeichnen Teile eines Ganzen.';
    }
    if (level == 2 || left == null || right == null) {
      return 'Schreibe beide Zahlen mit gleich vielen Nachkommastellen: '
          '${padded(leftText)} und ${padded(rightText)}. '
          'Eine angehängte Null rechts ändert den Wert nicht. '
          '${subtraction ? "Ziehe Stellen mit gleichem Wert voneinander ab." : "Addiere Stellen mit gleichem Wert."}';
    }
    return '$leftText entspricht $left $unit; $rightText entspricht $right $unit. '
        'Rechne $left ${subtraction ? "−" : "+"} $right in $unit. '
        'Schreibe dein Ergebnis anschließend wieder mit $places Nachkommastellen. '
        'Die Einheit bleibt $unit, nicht ganze Gegenstände.';
  }

  String? _fractionHint(LumoTask task, int level) {
    if (task.subject != 'Mathematik') return null;
    final prompt = task.prompt.trim();
    final expansion = RegExp(
      r'^(?:Knobelaufgabe: )?Erweitere den Bruch (\d+)/(\d+) mit (\d+)\. Wie heißt der neue Bruch\?$',
    ).firstMatch(prompt);
    if (expansion != null) {
      final numerator = int.tryParse(expansion[1]!);
      final denominator = int.tryParse(expansion[2]!);
      final factor = int.tryParse(expansion[3]!);
      if (numerator != null &&
          denominator != null &&
          denominator > 0 &&
          factor != null &&
          factor > 0) {
        if (level <= 1) {
          return 'Beim Erweitern bleibt der Anteil gleich. Multipliziere Zähler UND Nenner mit demselben vorgegebenen Faktor.';
        }
        if (level == 2) {
          return 'Der Faktor ist $factor. Rechne oben $numerator · $factor und unten $denominator · $factor. Beide Zahlen ändern sich gemeinsam.';
        }
        return 'Teile jedes der $denominator gleich großen Stücke nochmals in $factor gleiche Teile. '
            'Auch jedes der $numerator gemeinten Stücke bekommt $factor Teile. '
            'Schreibe die beiden neuen Anzahlen als Bruch.';
      }
    }
    final expression = RegExp(
      r'^\s*(?:Rechne\s+)?(\d+)\s*/\s*(\d+)\s*([+\-−])\s*(\d+)\s*/\s*(\d+)\s*(?:=\s*\?)?[.?]?\s*$',
    ).firstMatch(prompt);
    if (expression != null) {
      final left = int.tryParse(expression[1]!);
      final denominator = int.tryParse(expression[2]!);
      final right = int.tryParse(expression[4]!);
      final rightDenominator = int.tryParse(expression[5]!);
      if (left != null &&
          right != null &&
          denominator != null &&
          denominator > 0 &&
          rightDenominator != null &&
          rightDenominator > 0) {
        final subtraction = expression[3] != '+';
        if (denominator != rightDenominator) {
          if (level <= 1) {
            return 'Die Nenner sind verschieden. Die Teile sind noch nicht gleich groß. Erweitere beide Brüche zuerst auf einen gemeinsamen Nenner.';
          }
          return level == 2
              ? 'Erweitere den ersten Bruch mit $rightDenominator und den zweiten mit $denominator. So beschreiben beide gleich große Teile.'
              : 'Der gemeinsame Nenner kann $denominator · $rightDenominator sein. Oben rechnest du zuerst $left · $rightDenominator und $right · $denominator. '
                  '${subtraction ? "Ziehe danach die neuen Zähler voneinander ab." : "Addiere danach die neuen Zähler."} Der gemeinsame Nenner bleibt stehen.';
        }
        if (level <= 1) {
          return 'Beide Brüche haben denselben Nenner. Die Teile sind gleich groß. '
              '${subtraction ? "Ziehe nur die oberen Zahlen voneinander ab." : "Addiere nur die oberen Zahlen."} Der Nenner bleibt gleich.';
        }
        if (level == 2) {
          return 'Der Nenner $denominator bedeutet: Jedes Ganze ist in $denominator gleich große Teile geteilt. '
              '${subtraction ? "Starte mit $left ${left == 1 ? 'Teil' : 'Teilen'} und nimm $right davon weg." : "Lege $left ${left == 1 ? 'Teil' : 'Teile'} hin. Lege dann $right ${right == 1 ? 'gleich großes Teil' : 'gleich große Teile'} dazu."}';
        }
        return 'Rechne mit den Zählern: $left ${subtraction ? "−" : "+"} $right. '
            'Schreibe darunter wieder $denominator. Prüfe deinen Anteil mit gleich großen Teilen eines Ganzen.';
      }
    }
    final family =
        task.unit.toLowerCase().replaceAll('ü', 'u').contains('bruch') ||
            task.visual.startsWith('fraction');
    if (!family) return null;
    final half = RegExp(r'^Was ist die Hälfte von (\d+)\?$').firstMatch(prompt);
    if (half != null) {
      if (level <= 1) {
        return 'Teile die ganze Menge in zwei gleich große Gruppen. Eine dieser Gruppen ist die Hälfte.';
      }
      return level == 2
          ? 'Verteile die ${half[1]} Dinge abwechselnd auf zwei Gruppen. Beide Gruppen müssen gleich groß sein.'
          : 'Prüfe deine Hälfte: Wenn du die beiden gleich großen Gruppen wieder zusammenlegst, müssen es insgesamt ${half[1]} sein.';
    }
    if (level <= 1) {
      return 'Ein Bruch beschreibt einen Anteil. Der Nenner unten sagt, in wie viele gleich große Teile jedes Ganze geteilt ist. Der Zähler oben sagt, wie viele Teile gemeint sind.';
    }
    return level == 2
        ? 'Teile jedes gezeichnete Ganze in genau so viele gleich große Stücke, wie der Nenner angibt. Markiere die Anzahl aus dem Zähler. Zeichne bei Bedarf mehrere Ganze.'
        : 'Prüfe einen Schritt nach dem anderen: zuerst die Größe eines Teils mit dem Nenner, dann die gemeinten Teile mit dem Zähler. Die Teile müssen gleich groß bleiben.';
  }

  String? _placeValueHint(LumoTask task, int level) {
    if (task.subject != 'Mathematik') return null;
    final prompt = task.prompt.toLowerCase();
    final unit = task.unit.toLowerCase();
    // Die Stellenwerthilfe gehört nur zur Einheit „Zehner und Einer“ oder zu
    // einer Frage nach Zehnern oder Einern. Gemeint sind die Hauptwörter
    // „Zehner“ und „Einer“ – nicht das kleine Wort „einer“ in „In einer
    // Kiste liegen …“.
    final asked = RegExp(r'\bWie viele (Zehner|Einer)\b').firstMatch(task.prompt);
    final placeValueUnit = unit.contains('zehner und einer');
    if (asked == null && !placeValueUnit) return null;
    final namesOnes = RegExp(r'\bEiner\b').hasMatch(task.prompt);
    final namesTens = RegExp(r'\bZehner\b').hasMatch(task.prompt);
    final wantsOnes = asked != null ? asked[1] == 'Einer' : namesOnes;
    final wantsTens = asked != null ? asked[1] == 'Zehner' : !namesOnes || namesTens;
    if (!wantsTens && !wantsOnes) return null;
    final match = RegExp(r'\b(\d{2})\b').firstMatch(prompt);
    if (match == null) return null;
    final number = int.parse(match.group(1)!);
    final tens = number ~/ 10;
    final ones = number % 10;
    // Erste Hilfe: die richtige Antwort nicht vorwegnehmen.
    if (level <= 1) {
      return wantsOnes
          ? 'Baue die Zahl mit Zehnerbündeln. Was nach den vollen Bündeln übrig bleibt, sind die Einer. Zähle nur diese einzelnen Dinge.'
          : 'Stell dir Stifte in Bündeln zu je zehn vor. Wie viele ganze Zehnerbündel kannst du aus dieser Zahl bilden?';
    }
    if (level == 2) {
      return 'Zerlege $number in ${tens * 10} und $ones. '
          'Denke an volle Päckchen mit je zehn Stiften und an einzelne Stifte. '
          '${wantsOnes ? "Welche einzelnen Stifte bleiben übrig?" : "Wie viele volle Päckchen sind das?"}';
    }
    // Dritter Versuch: ein neuer, gegenständlicher Zugang mit Transferaufgabe.
    final check = tens * 10 + ((ones + 1) % 10);
    return wantsOnes
        ? 'Sieh $number als $tens Zehnerstangen und $ones einzelne Würfel. '
            'Jede Stange enthält genau zehn Würfel. Die einzelnen $ones Würfel '
            'sind die Einer. Probiere danach $check: Welche Einer bleiben dort?'
        : 'Sieh $number als $tens Zehnerstangen und $ones einzelne Würfel. '
            'Jede Stange enthält genau zehn Würfel. Es sind $tens volle '
            'Zehnerstangen. Probiere danach $check: Wie viele Zehnerstangen brauchst du?';
  }

  /// Stellenwert und Runden im Zahlenraum bis zur Million (Befund M7).
  String? _millionHint(String prompt, int level) {
    if (prompt.startsWith('Welchen Wert hat die Ziffer')) {
      return switch (level) {
        1 => 'Schreib die Zahl in eine Stellenwerttafel: HT, ZT, T, H, Z, E. In welcher Spalte steht die Ziffer?',
        2 => 'Zähle von rechts: Einer, Zehner, Hunderter, Tausender, Zehntausender, Hunderttausender.',
        _ => 'Schreib die Ziffer hin und hänge für jede Stelle rechts von ihr eine Null an.',
      };
    }
    if (prompt.startsWith('Runde ') && prompt.endsWith('auf Tausender.')) {
      return switch (level) {
        1 => 'Beim Runden auf Tausender entscheidet die Hunderterziffer.',
        2 => 'Ist die Hunderterziffer 0 bis 4, rundest du ab. Ist sie 5 bis 9, rundest du auf.',
        _ => 'Suche die zwei Nachbartausender der Zahl. Zu welchem gehört sie nach der Hunderterziffer?',
      };
    }
    return null;
  }

  String _guidedHint(LumoTask task, int level) {
    final unit = task.unit.toLowerCase();
    if (task.subject == 'Mathematik') {
      final million = _millionHint(task.prompt, level);
      if (million != null) return million;
      final missing = _MissingNumber.parse(task.prompt);
      if (missing != null) return missing.hint(level);
      final expression = RegExp(
                  r'^\s*(?:(?:Schriftlich|Blitzlicht):\s*)?(\d+)\s*([+−\-×·*:÷])\s*(\d+)\s*=\s*\?\s*$')
              .firstMatch(task.prompt) ??
          RegExp(r'^\s*(?:Rechne\s+)?(\d+)\s*([+−\-×·*:÷])\s*(\d+)\s*[.?]?\s*$',
                  caseSensitive: false)
              .firstMatch(task.prompt);
      if (expression != null) {
        final left = int.parse(expression.group(1)!);
        final right = int.parse(expression.group(3)!);
        final op = expression.group(2)!;
        if (op == '+') {
          final nextTen = (left ~/ 10 + 1) * 10;
          final missing = nextTen - left;
          if (level >= 3 && left % 10 != 0 && right > missing) {
            return 'Von $left bis $nextTen fehlen $missing. '
                'Teile $right in $missing und ${right - missing}. '
                'Gehe zuerst bis $nextTen und dann die übrigen '
                '${right - missing} Schritte weiter. Wo landest du?';
          }
          // Zahlenraum 100, zweistellig: halbschriftlich „Zehner, dann
          // Einer“ statt 24 Punkte zu legen.
          if (level == 2 &&
              left >= 10 &&
              right > 10 &&
              right % 10 != 0 &&
              left + right <= 100) {
            return 'Zerlege $right in ${right ~/ 10 * 10} und ${right % 10}. '
                'Rechne zuerst $left + ${right ~/ 10 * 10}. '
                'Zähle danach die ${right % 10} Einer dazu.';
          }
          if (right > 20) {
            return level == 2
                ? 'Zerlege $right in seine Stellen. Zähle zuerst die größte Stelle zu $left dazu, dann die nächste. Schreibe jedes Zwischenergebnis auf.'
                : 'Schreibe die Zahlen untereinander: Einer unter Einer, Zehner unter Zehner. Beginne bei den Einern. Sind es zehn oder mehr, schreibe die Einer an und merke dir 1 für die nächste Stelle. Prüfe mit der Umkehraufgabe.';
          }
          return level == 2
              ? 'Starte bei $left. Zähle $right weiter. Du kannst dir die zweite Menge als Punkte legen.'
              : 'Teile $right in kleine Schritte. Gehe zuerst bis zum nächsten Zehner, wenn du ihn erreichst, und zähle dann den Rest weiter. Prüfe durch Zurückzählen.';
        }
        if (op == '-' || op == '−') {
          final toTen = left % 10;
          if (level >= 3 && toTen > 0 && right > toTen && right <= left) {
            return 'Gehe von $left zuerst $toTen Schritte bis ${left - toTen} zurück. '
                'Von den $right Schritten bleiben noch ${right - toTen}. '
                'Gehe auch diese zurück. Wo landest du? '
                'Prüfe danach durch Dazuzählen.';
          }
          if (level == 2 &&
              right > 10 &&
              right % 10 != 0 &&
              left <= 100) {
            return 'Zerlege $right in ${right ~/ 10 * 10} und ${right % 10}. '
                'Rechne zuerst $left − ${right ~/ 10 * 10}. '
                'Nimm danach die ${right % 10} Einer weg.';
          }
          if (right > 20) {
            return level == 2
                ? 'Zerlege $right in seine Stellen. Ziehe zuerst die größte Stelle von $left ab, dann die nächste. Schreibe jedes Zwischenergebnis auf.'
                : 'Schreibe die Zahlen untereinander: Einer unter Einer, Zehner unter Zehner. Beginne bei den Einern und ergänze von unten nach oben. Reicht es nicht, ergänze auf die nächste Zehnerzahl und merke dir 1. Prüfe durch Dazuzählen.';
          }
          return level == 2
              ? 'Starte bei $left. Nimm $right weg oder gehe $right Schritte zurück.'
              : 'Zerlege die weggenommene Menge in kleinere Schritte. Nimm sie nacheinander weg. Prüfe: Wenn du $right wieder dazuzählst, musst du bei $left ankommen.';
        }
        if ((op == ':' || op == '÷') && left > 100) {
          return level == 2
              ? 'Teile Stelle für Stelle und beginne ganz links. Wie oft passt $right in die erste Stelle oder in die ersten zwei Stellen von $left?'
              : 'Schreibe jedes Teilergebnis an und nimm den Rest mit zur nächsten Stelle. Prüfe am Ende mit der Probe: dein Ergebnis mal $right, plus ein Rest, wenn etwas übrig bleibt, muss $left ergeben.';
        }
        if (op == ':' || op == '÷') {
          return level == 2
              ? 'Verteile $left Dinge auf $right gleich große Gruppen. Wie viele liegen in einer Gruppe?'
              : 'Lege in jede der $right Gruppen immer genau ein Ding, bis alle $left verteilt sind. Prüfe dein Ergebnis mit der passenden Malaufgabe.';
        }
        // Große Zahlen legt und zählt niemand: Dort hilft das Zerlegen in
        // Stellen. Früher hieß es etwa „Lege 390 gleich große Gruppen“.
        if (left > 10 || right > 10) {
          final big = left > right ? left : right;
          final small = left > right ? right : left;
          return level == 2
              ? 'Zerlege $big in Hunderter, Zehner und Einer. Nimm jede Stelle mal $small. Beginne bei den Einern.'
              : 'Schreibe von jedem Teilergebnis die Einer an und merke dir die Zehner für die nächste Stelle. Zähle die gemerkte Zahl dort dazu. Prüfe mit einem Überschlag.';
        }
        return level == 2
            ? 'Lege $left gleich große Gruppen mit je $right Dingen. Zähle eine Gruppe nach der anderen.'
            : 'Zähle in Schritten von $right. Mache genau $left Schritte. Prüfe, dass jede Gruppe gleich groß ist.';
      }
    }
    if (task.subject == 'Logik') {
      if (unit.contains('zahlenmuster')) {
        return level == 2
            ? 'Vergleiche zuerst die erste und die zweite Zahl. Wie viele Schritte liegen dazwischen? Prüfe denselben Abstand bei den nächsten Zahlen.'
            : 'Nimm den Abstand, den du an allen Stellen gefunden hast. Gehe von der letzten sichtbaren Zahl genau diesen Abstand weiter.';
      }
      if (unit == 'muster') {
        return level == 2
            ? 'Suche, an welcher Stelle die erste Form wieder auftaucht. Alles davor bildet die Gruppe, die sich wiederholt.'
            : 'Sprich eine ganze Gruppe laut und beginne dann dieselbe Gruppe wieder von vorn. Welche Form ist an der Lücke an der Reihe?';
      }
      if (unit.contains('regeln')) {
        return level == 2
            ? 'Prüfe zuerst die beiden Grenzen: Welche Karten liegen dazwischen? Die Grenzen selbst gehören nicht dazu.'
            : task.prompt.contains('er-Reihe')
                ? 'Prüfe jede übrige Karte gegen die letzte Regel. Kommt die Zahl vor, wenn du in dieser Reihe weiterzählst?'
                : task.prompt.contains('ungerade')
                    ? 'Prüfe jede übrige Karte gegen die letzte Regel. Bei ungeraden Zahlen bleibt beim Bilden von Paaren eins übrig.'
                    : 'Prüfe jede übrige Karte gegen die letzte Regel. Bei geraden Zahlen bleibt beim Bilden von Paaren nichts übrig.';
      }
      return level == 2
          ? 'Lege für jedes Kind eine Karte. Verschiebe die Karten so, dass jede Angabe stimmt.'
          : 'Prüfe jede Antwort einzeln gegen jede Angabe. Streiche sie, sobald eine Angabe nicht passt.';
    }
    if (task.handwriting || task.visual == 'shape_trace') {
      return level == 2
          ? 'Suche den Startpunkt und zeichne nur den ersten Strich. Schau dann wieder auf die Vorlage.'
          : 'Vergleiche deine Zeichnung Teil für Teil mit der Vorlage. Ergänze fehlende Teile und achte auf die Richtung.';
    }
    if (task.subject == 'Lesen') {
      return level == 2
          ? 'Suche im Text die Person oder das wichtige Wort aus der Frage. Lies den Satz davor und danach noch einmal.'
          : 'Prüfe jede Antwort: Gibt es im Text eine Stelle, die sie belegt? Wähle erst, wenn du diese Stelle gefunden hast.';
    }
    return level == 2
        ? '${explain(task)} Probiere jede Antwort einzeln und begründe, ob sie zur Frage passt.'
        : '${explain(task)} Schließe zuerst eine unpassende Antwort aus. Vergleiche die übrigen noch einmal mit dem entscheidenden Wort in der Frage.';
  }
}

/// Mathematically valid missing-number expression such as 7 + ? = 12.
///
/// The explanation guides counting without revealing the unknown quantity.
/// This is intentionally local and deterministic: no generated answer text.
class _MissingNumber {
  const _MissingNumber(this.start, this.result, this.plus);
  final int start;
  final int result;
  final bool plus;

  static _MissingNumber? parse(String prompt) {
    final match = RegExp(
            r'^\s*(?:(?:Rechne|Ergänze):?\s*)?(\d+)\s*([+−\-])\s*\?\s*=\s*(\d+)\s*[.?]?\s*$')
        .firstMatch(prompt);
    if (match == null) return null;
    final start = int.parse(match.group(1)!);
    final result = int.parse(match.group(3)!);
    final plus = match.group(2) == '+';
    if (plus ? result < start : result > start) return null;
    return _MissingNumber(start, result, plus);
  }

  String hint(int level) {
    if (plus) {
      if (level < 3) {
        return 'Starte bei $start. Zähle weiter, bis du bei $result bist, und zähle dabei deine Schritte mit.';
      }
      final nextTen = (start ~/ 10 + 1) * 10;
      const check = 'Prüfe durch Zurückzählen';
      if (start % 10 != 0 && result > nextTen) {
        return 'Teile den Weg in zwei Stücke. Von $start bis $nextTen sind es '
            '${nextTen - start} Schritte. Zähle dann von $nextTen weiter bis '
            '$result. Wie viele Schritte sind es zusammen? $check: Von $result '
            'um deine Zahl zurück musst du bei $start landen.';
      }
      return 'Teile den Weg in kleine Schritte: Zähle von $start bis $result '
          'an den Fingern, jeder Finger ist ein Schritt. $check: Von $result '
          'um deine Zahl zurück musst du bei $start landen.';
    }
    if (level < 3) {
      return 'Starte bei $start. Gehe zurück, bis du bei $result bist, und zähle dabei deine Schritte mit.';
    }
    final lowerTen = start - start % 10;
    const check = 'Prüfe durch Dazuzählen';
    if (start % 10 != 0 && result < lowerTen) {
      return 'Teile den Weg in zwei Stücke. Von $start zurück bis $lowerTen '
          'sind es ${start % 10} Schritte. Gehe dann von $lowerTen weiter '
          'zurück bis $result. Wie viele Schritte sind es zusammen? $check: '
          '$result plus deine Zahl muss $start ergeben.';
    }
    return 'Teile den Weg in kleine Schritte: Gehe von $start an den Fingern '
        'zurück bis $result, jeder Finger ist ein Schritt. $check: $result '
        'plus deine Zahl muss $start ergeben.';
  }
}
