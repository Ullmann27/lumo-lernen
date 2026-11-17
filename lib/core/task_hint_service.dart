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
        return 'Bei einer Uhrzeit steht zuerst die Stunde und nach dem Doppelpunkt die Minute. Eine volle Stunde hat dort 00 Minuten.';
      }
      if (unit.contains('zeit') || prompt.contains('minuten')) {
        return 'Eine Stunde besteht aus 60 Minuten. Wandle zuerst die ganzen Stunden um und zähle übrige Minuten dazu.';
      }
      if (unit.contains('länge')) {
        return 'Ein Meter sind 100 Zentimeter. Rechne zuerst die ganzen Meter um und zähle übrige Zentimeter dazu.';
      }
      if (unit.contains('masse')) {
        return 'Ein Kilogramm sind 1000 Gramm. Wandle die Kilogramm um und zähle die übrigen Gramm dazu.';
      }
      if (unit.contains('hohl') || prompt.contains('milliliter')) {
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
      if (unit.contains('vergleich') || unit.contains('mengen')) {
        return 'Vergleiche beide Seiten. Bei Zahlen beginnst du mit der größten Stelle. Die offene Seite des Vergleichszeichens zeigt zur größeren Zahl.';
      }
      if (unit.contains('text') || unit.contains('sachaufgabe')) {
        return 'Was weißt du schon, und was wird gesucht? Etwas kommt dazu: plus. Etwas geht weg: minus. Gleich große Gruppen: mal oder geteilt. Rechne bei mehreren Schritten einen nach dem anderen.';
      }
      if (prompt.contains('×') || unit.contains('einmaleins')) {
        return 'Denke an gleich große Gruppen. Zähle in Schritten der ersten Zahl oder nutze eine Malaufgabe, die du schon kennst.';
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
      if (prompt.contains('-') || prompt.contains('−')) {
        return 'Beginne bei der ersten Zahl und nimm die zweite Menge weg. Bei großen Zahlen hilft es, zuerst Zehner und dann Einer abzuziehen.';
      }
      if (prompt.contains('+')) {
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
      r'^Erweitere den Bruch (\d+)/(\d+) mit (\d+)\. Wie heißt der neue Bruch\?$',
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
    final wantsTens = prompt.contains('zehner') ||
        (unit.contains('zehner') && !prompt.contains('einer'));
    final wantsOnes = prompt.contains('einer');
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

  String _guidedHint(LumoTask task, int level) {
    final unit = task.unit.toLowerCase();
    if (task.subject == 'Mathematik') {
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
          return level == 2
              ? 'Starte bei $left. Nimm $right weg oder gehe $right Schritte zurück.'
              : 'Zerlege die weggenommene Menge in kleinere Schritte. Nimm sie nacheinander weg. Prüfe: Wenn du $right wieder dazuzählst, musst du bei $left ankommen.';
        }
        if (op == ':' || op == '÷') {
          return level == 2
              ? 'Verteile $left Dinge auf $right gleich große Gruppen. Wie viele liegen in einer Gruppe?'
              : 'Lege in jede der $right Gruppen immer genau ein Ding, bis alle $left verteilt sind. Prüfe dein Ergebnis mit der passenden Malaufgabe.';
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
      return level == 2
          ? 'Lege für jede Figur eine Karte. Verschiebe die Karten so, dass jede Angabe stimmt. Bei Zahlen prüfst du zuerst die beiden Grenzen.'
          : 'Prüfe jede Antwort einzeln gegen jede Angabe. Streiche sie, sobald eine Angabe nicht passt. Bei geraden Zahlen bleibt beim Bilden von Paaren nichts übrig.';
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
