import 'school_exercise_generator.dart';

/// Immediate offline explanations of the next step, never the stored answer.
class TaskHintService {
  const TaskHintService();

  String explain(LumoTask task) {
    final unit = task.unit.toLowerCase();
    final prompt = task.prompt.toLowerCase();
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
      if (unit.contains('symmetrie'))
        return 'Stell dir vor, du faltest die Form. Eine Spiegelachse liegt dort, wo beide Hälften genau aufeinanderpassen. Prüfe auch andere Faltlinien.';
      if (unit.contains('umfang'))
        return 'Beim Umfang gehst du außen um die ganze Figur. Addiere alle Seitenlängen; beim Rechteck gibt es jede Länge zweimal.';
      if (unit.contains('flächen'))
        return 'Beim Flächeninhalt zählst du die Kästchen im Inneren. Multipliziere beim Rechteck die Länge mit der Breite.';
      if (unit.contains('bruch')) {
        if (unit.contains('erweiter'))
          return 'Multipliziere die obere und die untere Zahl mit derselben vorgegebenen Zahl. Der Wert des Bruchs bleibt dabei gleich.';
        if (prompt.contains('+'))
          return 'Die unteren Zahlen sind gleich: Die Teile bleiben also gleich groß. Addiere nur die oberen Zahlen und behalte die untere Zahl bei.';
        return 'Teile die ganze Menge in zwei gleich große Gruppen. Eine dieser Gruppen ist die Hälfte.';
      }
      if (unit.contains('uhrzeit'))
        return 'Bei einer Uhrzeit steht zuerst die Stunde und nach dem Doppelpunkt die Minute. Eine volle Stunde hat dort 00 Minuten.';
      if (unit.contains('zeit') || prompt.contains('minuten'))
        return 'Eine Stunde besteht aus 60 Minuten. Wandle zuerst die ganzen Stunden um und zähle übrige Minuten dazu.';
      if (unit.contains('länge'))
        return 'Ein Meter sind 100 Zentimeter. Rechne zuerst die ganzen Meter um und zähle übrige Zentimeter dazu.';
      if (unit.contains('masse'))
        return 'Ein Kilogramm sind 1000 Gramm. Wandle die Kilogramm um und zähle die übrigen Gramm dazu.';
      if (unit.contains('hohl') || prompt.contains('milliliter'))
        return 'Ein Liter sind 1000 Milliliter. Wandle die Liter um und zähle die übrigen Milliliter dazu.';
      if (unit.contains('mittelwert'))
        return 'Addiere zuerst alle angegebenen Werte. Teile die Summe anschließend durch die Anzahl der Werte.';
      if (unit.contains('geld'))
        return 'Lies zuerst, wie viel eine Münze oder ein Schein wert ist. Zähle immer diesen Wert weiter, bis du beim gesuchten Betrag bist.';
      if (unit.contains('zehner'))
        return 'In einer zweistelligen Zahl zeigt die linke Ziffer die Zehner, die rechte Ziffer die Einer. Prüfe, wonach die Frage fragt.';
      if (unit.contains('verdoppel') || unit.contains('halbier'))
        return 'Doppelt heißt: dieselbe Menge zweimal. Halbieren heißt: die Menge auf zwei gleich große Gruppen verteilen.';
      if (unit.contains('gerade'))
        return 'Bilde Paare. Bleibt nichts übrig, ist die Zahl gerade. Bleibt eines übrig, ist sie ungerade.';
      if (unit.contains('zahlenstrahl') || unit.contains('zahlenreihe'))
        return 'Lies die Zahlen in ihrer Reihenfolge. Prüfe, wie groß ein Schritt ist, und gehe diesen Schritt auch an der Lücke weiter.';
      if (unit.contains('vergleich') || unit.contains('mengen'))
        return 'Vergleiche beide Seiten. Bei Zahlen beginnst du mit der größten Stelle. Die offene Seite des Vergleichszeichens zeigt zur größeren Zahl.';
      if (unit.contains('text') || unit.contains('sachaufgabe'))
        return 'Was weißt du schon, und was wird gesucht? Etwas kommt dazu: plus. Etwas geht weg: minus. Gleich große Gruppen: mal oder geteilt. Rechne bei mehreren Schritten einen nach dem anderen.';
      if (prompt.contains('×') || unit.contains('einmaleins'))
        return 'Denke an gleich große Gruppen. Zähle in Schritten der ersten Zahl oder nutze eine Malaufgabe, die du schon kennst.';
      if (prompt.contains(':') || unit.contains('division'))
        return 'Verteile die Menge in gleich große Gruppen. Prüfe mit der passenden Malaufgabe, ob deine Aufteilung stimmt.';
      if (prompt.contains('-') || prompt.contains('−'))
        return 'Beginne bei der ersten Zahl und nimm die zweite Menge weg. Bei großen Zahlen hilft es, zuerst Zehner und dann Einer abzuziehen.';
      if (prompt.contains('+'))
        return 'Beginne mit der ersten Menge und lege die zweite dazu. Wenn es hilft, ergänze zuerst bis zum nächsten Zehner und zähle dann den Rest.';
      return 'Lies, was genau gesucht wird. Prüfe Zahlen, Form oder Reihenfolge und vergleiche jede Antwort mit der Frage.';
    }
    if (task.subject == 'Englisch')
      return 'Sprich das gesuchte Wort langsam. Überlege, zu welcher Gruppe es gehört, etwa Farbe, Zahl oder Tier. Vergleiche dann die angebotenen Wörter.';
    if (task.subject == 'Sachunterricht')
      return 'Achte auf das entscheidende Wort in der Frage. Vergleiche jede Möglichkeit mit dem, was du beobachten kannst oder schon gelernt hast. Schließe unpassende Möglichkeiten aus.';
    if (task.subject == 'Lesen')
      return 'Lies den Text noch einmal langsam. Suche die Stelle, die genau zur Frage passt. Deine Antwort muss im Text belegt sein.';
    if (unit.contains('silb'))
      return 'Sprich das Wort ganz langsam und klatsche die gesprochenen Silben. Zähle die Klatscher, nicht die Buchstaben.';
    if (unit.contains('endlaut'))
      return 'Sprich das Wort bis ganz zum Ende und höre auf den letzten Laut. Laut und geschriebener Buchstabe können verschieden sein.';
    if (unit.contains('anfang') || unit.contains('laut'))
      return 'Sprich das Wort langsam und höre auf den ersten Laut. Ein Laut kann mit mehreren Buchstaben geschrieben werden, etwa Sch.';
    if (unit.contains('reim'))
      return 'Sprich beide Wörter laut. Beim Reim klingt der Teil ab dem letzten betonten Vokal gleich; nur ähnliche Buchstaben reichen nicht.';
    if (unit.contains('artikel'))
      return 'Probiere der, die und das vor dem Namenwort. Sprich jede Verbindung langsam und achte auf das ganze Wort.';
    if (unit.contains('mehrzahl'))
      return 'Stell dir ein Ding und dann mehrere davon vor. Sprich beide Formen. Oft ändern sich Wortende oder Vokal.';
    if (unit.contains('wortart') ||
        unit.contains('namen') ||
        unit.contains('tunwort') ||
        unit.contains('wiewort'))
      return 'Ein Namenwort benennt etwas, ein Tunwort sagt, was geschieht, und ein Wiewort beschreibt eine Eigenschaft. Prüfe die Wörter einzeln.';
    if (unit.contains('zeitform') || unit.contains('verbform'))
      return 'Achte darauf, wer etwas tut und wann es passiert. Probiere die Form mit dem passenden Fürwort und dem Zeitwort im Satz.';
    if (unit.contains('satz') ||
        unit.contains('rede') ||
        unit.contains('komma'))
      return 'Lies den ganzen Satz. Achte auf Wortstellung, Satzanfang und Satzende. Bei wörtlicher Rede wird das Gesprochene mit Anführungszeichen markiert.';
    return 'Sprich das Wort langsam. Achte auf die Stelle, nach der gefragt wird, und vergleiche die Schreibweisen Buchstabe für Buchstabe.';
  }
}
