/// Lumo-Nachhilfe: lokale, prüfbare Tutor-Logik für eine konkrete Aufgabe.
///
/// Fünf Hilfestufen (Auftrag Heinz, Abschnitt 5): kleiner Hinweis → andere
/// Erklärung mit Alltagsbeispiel → Lumo zeigt es sichtbar am Material →
/// gemeinsames Bearbeiten (das Kind löst jeden Zwischenschritt selbst) →
/// Verständnisprüfung an einer ähnlichen, eigenständigen Aufgabe.
///
/// Themen: Plus und Minus bis 20 mit Zehnerübergang, Kopfrechnen bis 100
/// (Zehnerstangen, Einerwürfel, Zahlenstrahl) und das kleine Einmaleins
/// (Punktefeld, Kernaufgaben, Nachbaraufgaben, Tauschaufgabe).
///
/// Die Nachhilfe arbeitet mit den vorhandenen Verträgen der App:
/// - Hilfestufen bilden [LumoTutorHelpLevel] ab; die 3D-Szene kennt weiter
///   genau die vier Stufen aus [NachhilfeStufeInfo.fuer3D],
/// - Lösungswege verweisen auf die bestehenden [RechentricksKind],
/// - Fehlermuster benutzen die vorhandenen [ErrorType]-Werte.
///
/// Sie liest nur geprüfte Aufgabendaten. Sie schreibt keinen Lernfortschritt,
/// vergibt keine Sterne und verrät nie das Ergebnis der Originalaufgabe:
/// vollständig vorgerechnet wird ausschließlich an einer Zwillingsaufgabe.
library;

import '../../core/lumo_tutor_contracts.dart';
import '../../core/math/lumo_rechentricks.dart';
import '../learning/lumo_learning_domain.dart';

part 'nachhilfe_rechenwege.dart';

/// Aufgabentypen, für die es eine durchgeplante Nachhilfe gibt.
enum NachhilfeTyp {
  /// „a + b = ?“ im Zahlenraum 20 (Generatoren g1_add_20, g2_add_20).
  additionBis20,

  /// „a − b = ?“ im Zahlenraum 20, auch mit Zehnerübergang (13 − 5).
  subtraktionBis20,

  /// Kopfrechnen „a + b = ?“ mit Ergebnis von 21 bis 100.
  additionBis100,

  /// Kopfrechnen „a − b = ?“ mit 21 ≤ a ≤ 100.
  subtraktionBis100,

  /// Kleines Einmaleins „a · b = ?“ mit 1 ≤ a, b ≤ 10.
  einmaleins,
}

extension NachhilfeTypInfo on NachhilfeTyp {
  /// Rechenzeichen, wie die Schule es schreibt.
  String get zeichen => switch (this) {
        NachhilfeTyp.additionBis20 || NachhilfeTyp.additionBis100 => '+',
        NachhilfeTyp.subtraktionBis20 || NachhilfeTyp.subtraktionBis100 => '−',
        NachhilfeTyp.einmaleins => '·',
      };

  bool get istPlus =>
      this == NachhilfeTyp.additionBis20 || this == NachhilfeTyp.additionBis100;

  bool get istMinus =>
      this == NachhilfeTyp.subtraktionBis20 ||
      this == NachhilfeTyp.subtraktionBis100;

  /// Zahlenraum 100: Zehnerstangen und Einerwürfel statt Rechenrahmen.
  bool get bis100 =>
      this == NachhilfeTyp.additionBis100 ||
      this == NachhilfeTyp.subtraktionBis100;

  String get schluessel => switch (this) {
        NachhilfeTyp.additionBis20 => 'addition_20',
        NachhilfeTyp.subtraktionBis20 => 'subtraktion_20',
        NachhilfeTyp.additionBis100 => 'addition_100',
        NachhilfeTyp.subtraktionBis100 => 'subtraktion_100',
        NachhilfeTyp.einmaleins => 'einmaleins',
      };
}

/// Lösungswege. Jeder Weg ist eine eigenständige Vorstellung derselben Rechnung.
enum NachhilfeWeg {
  /// Zwanziger-Rechenrahmen mit Fünferstruktur: erst die Zehnerreihe füllen.
  rechenrahmen,

  /// Zahlenstrahl als Steinweg: Lumo springt bis zur 10 und dann weiter.
  zahlenstrahl,

  /// Zerlegen: die zweite Zahl so teilen, dass die 10 voll wird.
  zerlegen,

  /// Nachbaraufgabe: Verdoppeln und eins dazu (nur bei Nachbarzahlen).
  verdoppeln,

  /// Tauschaufgabe: mit der größeren Zahl beginnen; beim Einmaleins das
  /// Punktefeld drehen.
  tauschen,

  /// Zahlenraum 100: Zehnerstangen und Einerwürfel, erst die Zehner.
  stangen,

  /// Einmaleins: Punktefeld Reihe für Reihe aufbauen und weiterzählen.
  punktefeld,

  /// Einmaleins: von einer Kernaufgabe (1·, 2·, 5·, 10·) ableiten.
  kernaufgabe,
}

/// Abgestufte Hilfe in der Reihenfolge der Hilfeleiter.
///
/// Die Namen sind Teil des 3D-Vertrags (Godot `tutor_plan.gd`): hinweis,
/// teilschritt, vorzeigen und ueben dürfen nicht umbenannt werden.
enum NachhilfeStufe {
  /// 1. Kleiner Hinweis: Denkanstoß ohne Lösung.
  hinweis,

  /// 2. Andere Erklärung: andere Worte, vertrautes Alltagsbeispiel.
  andereErklaerung,

  /// 3. Lumo zeigt es sichtbar am Material (an einer Zwillingsaufgabe).
  vorzeigen,

  /// 4. Gemeinsam: das Kind löst jeden Zwischenschritt selbst.
  teilschritt,

  /// 5. Verständnisprüfung an einer ähnlichen, eigenständigen Aufgabe.
  ueben,
}

/// Typische Fehlvorstellungen, aus der Antwort des Kindes ablesbar.
enum NachhilfeFehlermuster {
  keines,

  /// Um eins daneben: meist die Startzahl mitgezählt oder einen Schritt vergessen.
  einsDaneben,

  /// Minus statt plus gerechnet.
  rechenzeichen,

  /// Den Zehner beim Übergang vergessen oder doppelt gezählt.
  zehnerVergessen,

  /// Ziffern vertauscht (31 statt 13).
  zifferndreher,

  /// Minus mit Übergang: kleinere Einerziffer von der größeren abgezogen
  /// (62 − 25 → 43).
  einerUmgedreht,

  /// Einmaleins: die beiden Zahlen zusammengezählt statt mal genommen.
  plusStattMal,

  /// Einmaleins: in der Malreihe um eine Reihe verrutscht (6 · 7 → 35).
  reiheVerrutscht,
}

/// Wer den Schritt ausführt.
enum NachhilfeAkteur { lumo, kind }

extension NachhilfeWegInfo on NachhilfeWeg {
  String get titel => switch (this) {
        NachhilfeWeg.rechenrahmen => 'Rechenrahmen',
        NachhilfeWeg.zahlenstrahl => 'Zahlenstrahl',
        NachhilfeWeg.zerlegen => 'Zerlegen',
        NachhilfeWeg.verdoppeln => 'Verdoppeln',
        NachhilfeWeg.tauschen => 'Tauschen',
        NachhilfeWeg.stangen => 'Zehnerstangen',
        NachhilfeWeg.punktefeld => 'Reihe für Reihe',
        NachhilfeWeg.kernaufgabe => 'Kernaufgabe',
      };

  String get schluessel => name;

  /// Verknüpfung mit dem bestehenden Rechentricks-System.
  RechentricksKind get rechentrick => switch (this) {
        NachhilfeWeg.rechenrahmen => RechentricksKind.bridgeTen,
        NachhilfeWeg.zahlenstrahl => RechentricksKind.bridgeTen,
        NachhilfeWeg.zerlegen => RechentricksKind.bridgeTen,
        NachhilfeWeg.verdoppeln => RechentricksKind.neighborTask,
        NachhilfeWeg.tauschen => RechentricksKind.swapNumbers,
        NachhilfeWeg.stangen => RechentricksKind.stepByStep,
        NachhilfeWeg.punktefeld => RechentricksKind.stepByStep,
        NachhilfeWeg.kernaufgabe => RechentricksKind.neighborTask,
      };

  /// Passende lokale Visualisierung aus dem Tutor-Vertrag.
  LumoTutorVisualType get visual => switch (this) {
        NachhilfeWeg.rechenrahmen => LumoTutorVisualType.tenFrame,
        NachhilfeWeg.zahlenstrahl => LumoTutorVisualType.numberLine,
        NachhilfeWeg.zerlegen => LumoTutorVisualType.tenFrame,
        NachhilfeWeg.verdoppeln => LumoTutorVisualType.tenFrame,
        NachhilfeWeg.tauschen => LumoTutorVisualType.numberLine,
        NachhilfeWeg.stangen => LumoTutorVisualType.quantityDots,
        NachhilfeWeg.punktefeld => LumoTutorVisualType.quantityDots,
        NachhilfeWeg.kernaufgabe => LumoTutorVisualType.quantityDots,
      };
}

extension NachhilfeStufeInfo on NachhilfeStufe {
  String get titel => switch (this) {
        NachhilfeStufe.hinweis => 'Kleiner Tipp',
        NachhilfeStufe.andereErklaerung => 'Anders erklärt',
        NachhilfeStufe.vorzeigen => 'Lumo zeigt',
        NachhilfeStufe.teilschritt => 'Gemeinsam',
        NachhilfeStufe.ueben => 'Selbst prüfen',
      };

  /// Die vier Stufen, die die 3D-Szene kennt und streng prüft.
  static const List<NachhilfeStufe> fuer3D = [
    NachhilfeStufe.hinweis,
    NachhilfeStufe.teilschritt,
    NachhilfeStufe.vorzeigen,
    NachhilfeStufe.ueben,
  ];

  /// Startstufe der 3D-Szene: die andere Erklärung gibt es nur in 2D.
  NachhilfeStufe get in3D =>
      this == NachhilfeStufe.andereErklaerung ? NachhilfeStufe.hinweis : this;

  /// Arbeitet die Stufe an der Originalaufgabe? Dann wird ihr Ergebnis
  /// weder genannt noch abgefragt.
  bool get anOriginal =>
      this == NachhilfeStufe.hinweis ||
      this == NachhilfeStufe.andereErklaerung ||
      this == NachhilfeStufe.teilschritt;

  LumoTutorHelpLevel get hilfeStufe => switch (this) {
        NachhilfeStufe.hinweis => LumoTutorHelpLevel.hintOnly,
        NachhilfeStufe.andereErklaerung => LumoTutorHelpLevel.hintOnly,
        NachhilfeStufe.teilschritt => LumoTutorHelpLevel.guidedStep,
        NachhilfeStufe.vorzeigen => LumoTutorHelpLevel.visualExplanation,
        NachhilfeStufe.ueben => LumoTutorHelpLevel.fullMiniLesson,
      };

  static NachhilfeStufe ausHilfeStufe(LumoTutorHelpLevel level) =>
      switch (level) {
        LumoTutorHelpLevel.hintOnly => NachhilfeStufe.hinweis,
        LumoTutorHelpLevel.guidedStep => NachhilfeStufe.teilschritt,
        LumoTutorHelpLevel.visualExplanation => NachhilfeStufe.vorzeigen,
        LumoTutorHelpLevel.fullMiniLesson => NachhilfeStufe.ueben,
      };
}

extension NachhilfeFehlermusterInfo on NachhilfeFehlermuster {
  /// Abbildung auf die bestehende Fehlerdiagnose der App.
  ErrorType get fehlerart => switch (this) {
        NachhilfeFehlermuster.keines => ErrorType.none,
        NachhilfeFehlermuster.einsDaneben => ErrorType.countingError,
        NachhilfeFehlermuster.rechenzeichen => ErrorType.plusMinusConfusion,
        NachhilfeFehlermuster.zehnerVergessen => ErrorType.tenTransitionWeak,
        NachhilfeFehlermuster.zifferndreher => ErrorType.placeValueWeak,
        NachhilfeFehlermuster.einerUmgedreht => ErrorType.tenTransitionWeak,
        NachhilfeFehlermuster.plusStattMal => ErrorType.quantityError,
        NachhilfeFehlermuster.reiheVerrutscht => ErrorType.countingError,
      };

  /// Kurzer, nicht beschämender Satz an das Kind.
  String get rueckmeldung => switch (this) {
        NachhilfeFehlermuster.keines => '',
        NachhilfeFehlermuster.einsDaneben =>
          'Du warst ganz knapp dran. Wir zählen die Sprünge, nicht die Steine.',
        NachhilfeFehlermuster.rechenzeichen =>
          'Schau aufs Zeichen: Plus heißt, es kommt etwas dazu.',
        NachhilfeFehlermuster.zehnerVergessen =>
          'Die volle Zehnerreihe ist wichtig. Wir machen sie zusammen voll.',
        NachhilfeFehlermuster.zifferndreher =>
          'Die Ziffern sind richtig, nur die Reihenfolge nicht: erst der Zehner, dann die Einer.',
        NachhilfeFehlermuster.einerUmgedreht =>
          'Oben sind zu wenige Einer. Dann machen wir einen Zehner auf – umdrehen gilt nicht.',
        NachhilfeFehlermuster.plusStattMal =>
          'Mal heißt nicht zusammenzählen. Mal heißt: gleich lange Reihen.',
        NachhilfeFehlermuster.reiheVerrutscht =>
          'Ganz knapp! Du bist um eine Reihe verrutscht. Wir zählen die Reihen genau.',
      };
}

/// Eine konkrete, geprüfte Rechenaufgabe.
class NachhilfeAufgabe {
  const NachhilfeAufgabe._(this.typ, this.a, this.b);

  final NachhilfeTyp typ;
  final int a;
  final int b;

  /// Plus im Zahlenraum 20. Prüft Bereichsgrenzen; außerhalb gibt es keine
  /// Nachhilfe-Aufgabe. (Vertrag der 3D-Szene: nur dieser Typ geht in 3D.)
  static NachhilfeAufgabe? addition(int a, int b) {
    if (a < 1 || b < 1 || a + b > 20) return null;
    return NachhilfeAufgabe._(NachhilfeTyp.additionBis20, a, b);
  }

  /// Minus im Zahlenraum 20 (z. B. 13 − 5).
  static NachhilfeAufgabe? subtraktion(int a, int b) {
    if (b < 1 || a > 20 || b > a) return null;
    return NachhilfeAufgabe._(NachhilfeTyp.subtraktionBis20, a, b);
  }

  /// Kopfrechnen Plus mit Ergebnis von 21 bis 100 (z. B. 37 + 25).
  static NachhilfeAufgabe? additionBis100(int a, int b) {
    if (a < 1 || b < 1 || a + b <= 20 || a + b > 100) return null;
    return NachhilfeAufgabe._(NachhilfeTyp.additionBis100, a, b);
  }

  /// Kopfrechnen Minus von 21 bis 100 (z. B. 62 − 25).
  static NachhilfeAufgabe? subtraktionBis100(int a, int b) {
    if (a <= 20 || a > 100 || b < 1 || b > a) return null;
    return NachhilfeAufgabe._(NachhilfeTyp.subtraktionBis100, a, b);
  }

  /// Kleines Einmaleins: [a] Reihen mit je [b] Punkten.
  static NachhilfeAufgabe? mal(int a, int b) {
    if (a < 1 || b < 1 || a > 10 || b > 10) return null;
    return NachhilfeAufgabe._(NachhilfeTyp.einmaleins, a, b);
  }

  /// Passender Typ für eine reine Rechnung; sonst null.
  static NachhilfeAufgabe? rechnung(String operation, int a, int b) =>
      switch (operation) {
        'addition' => addition(a, b) ?? additionBis100(a, b),
        'subtraction' => subtraktion(a, b) ?? subtraktionBis100(a, b),
        'multiplication' => mal(a, b),
        _ => null,
      };

  /// Liest nur die vom Adapter geprüften Daten und vergleicht sie mit der
  /// hinterlegten Lösung. Textaufgaben oder unklare Fälle liefern null.
  static NachhilfeAufgabe? ausTask(TaskInstance task) {
    if (task.subject != LearningSubject.mathematik) return null;
    final data = task.visualPayload.data;
    final operation = data['operation'];
    if (operation is! String) return null;
    final a = data['left'];
    final b = data['right'];
    if (a is! int || b is! int) return null;
    final aufgabe = rechnung(operation, a, b);
    if (aufgabe == null) return null;
    final loesung = task.correctAnswer;
    final erwartet = loesung is int ? loesung : int.tryParse('$loesung'.trim());
    if (erwartet != aufgabe.ergebnis) return null;
    final zeichen = switch (aufgabe.typ.zeichen) {
      '+' => r'\+',
      '−' => '[-−–]',
      _ => '[×·*x]',
    };
    if (!RegExp('(^|\\D)$a\\s*$zeichen\\s*$b(\\D|\$)').hasMatch(task.prompt)) {
      return null;
    }
    return aufgabe;
  }

  int get ergebnis => switch (typ) {
        NachhilfeTyp.additionBis20 || NachhilfeTyp.additionBis100 => a + b,
        NachhilfeTyp.subtraktionBis20 ||
        NachhilfeTyp.subtraktionBis100 =>
          a - b,
        NachhilfeTyp.einmaleins => a * b,
      };

  /// Überschreitet die Rechnung einen Zehner (8 + 5, 13 − 5, 37 + 25,
  /// 62 − 25)? Beim Einmaleins gibt es keinen Zehnerübergang.
  bool get zehnerUebergang => switch (typ) {
        NachhilfeTyp.additionBis20 => a < 10 && a + b > 10,
        NachhilfeTyp.subtraktionBis20 => a > 10 && a - b < 10,
        NachhilfeTyp.additionBis100 => a % 10 + b % 10 >= 10,
        NachhilfeTyp.subtraktionBis100 => a % 10 < b % 10,
        NachhilfeTyp.einmaleins => false,
      };

  /// So viel fehlt der ersten Zahl bis zur 10.
  int get bisZehn => 10 - a;

  /// Rest der zweiten Zahl nach dem Auffüllen bis 10.
  int get rest => b - bisZehn;

  String get text => '$a ${typ.zeichen} $b';

  @override
  bool operator ==(Object other) =>
      other is NachhilfeAufgabe &&
      other.typ == typ &&
      other.a == a &&
      other.b == b;

  @override
  int get hashCode => Object.hash(typ, a, b);
}

/// Ein Handgriff am Material. Zielzustände sind absolut, damit die 3D-Szene
/// und der Flutter-Fallback dasselbe Ergebnis prüfen.
class NachhilfeAktion {
  const NachhilfeAktion._(this.art, this.werte,
      {this.optionen = const <int>[], this.zerlegungen = const <List<int>>[]});

  /// Rechenrahmen: so viele Perlen liegen links in Reihe 1 und Reihe 2.
  factory NachhilfeAktion.perlen(int reihe1, int reihe2) =>
      NachhilfeAktion._('perlen', {'reihe1': reihe1, 'reihe2': reihe2});

  /// Zahlenstrahl: Sprung von [von] nach [nach].
  factory NachhilfeAktion.huepfen(int von, int nach) =>
      NachhilfeAktion._('huepfen', {'von': von, 'nach': nach});

  /// Zerlegen: [ganz] wird in [teil1] und [teil2] geteilt. [zerlegungen]
  /// sind die Auswahlmöglichkeiten; die richtige ist enthalten.
  factory NachhilfeAktion.zerlegen(
          int ganz, int teil1, int teil2, List<List<int>> zerlegungen) =>
      NachhilfeAktion._(
          'zerlegen', {'ganz': ganz, 'teil1': teil1, 'teil2': teil2},
          zerlegungen: zerlegungen);

  /// Ergebnis wählen (nur bei Zwillingsaufgaben, nie bei der Originalaufgabe).
  factory NachhilfeAktion.ergebnis(int richtig, List<int> optionen) =>
      NachhilfeAktion._('ergebnis', {'richtig': richtig}, optionen: optionen);

  /// Nur hinschauen: Lumo zeigt auf das Material, nichts wird verändert.
  factory NachhilfeAktion.zeigen() => NachhilfeAktion._('zeigen', const {});

  /// Zehnerstangen und Einerwürfel (Zahlenraum 100), Zielzustand absolut:
  /// liegend [zehner]/[einer], daneben zum Dazulegen [dazuZehner]/[dazuEiner],
  /// zur Seite genommen [wegZehner]/[wegEiner]. Eine aufgemachte Stange
  /// zählt danach als zehn Einer.
  factory NachhilfeAktion.stangen({
    required int zehner,
    required int einer,
    int dazuZehner = 0,
    int dazuEiner = 0,
    int wegZehner = 0,
    int wegEiner = 0,
  }) =>
      NachhilfeAktion._('stangen', {
        'zehner': zehner,
        'einer': einer,
        'dazuZehner': dazuZehner,
        'dazuEiner': dazuEiner,
        'wegZehner': wegZehner,
        'wegEiner': wegEiner,
      });

  /// Punktefeld fürs Einmaleins: [zeilen] Reihen mit je [spalten] Punkten.
  /// Gedreht zeigt dasselbe Feld [spalten] Reihen mit je [zeilen] Punkten.
  /// [sichtbar], [markiert] (bekannter Teil) und [geister] (gedachte Reihen,
  /// z. B. bis 10 · b) zählen angezeigte Reihen von oben.
  factory NachhilfeAktion.punkte({
    required int zeilen,
    required int spalten,
    required int sichtbar,
    int markiert = 0,
    int geister = 0,
    bool gedreht = false,
  }) =>
      NachhilfeAktion._('punkte', {
        'zeilen': zeilen,
        'spalten': spalten,
        'sichtbar': sichtbar,
        'markiert': markiert,
        'geister': geister,
        'gedreht': gedreht ? 1 : 0,
      });

  /// Bild zur anderen Erklärung (Eierkarton, Münzen, Teller …).
  factory NachhilfeAktion.bild(NachhilfeMotiv motiv, {int a = 0, int b = 0}) =>
      NachhilfeAktion._('bild', {'motiv': motiv.index, 'a': a, 'b': b});

  final String art;
  final Map<String, int> werte;
  final List<int> optionen;
  final List<List<int>> zerlegungen;

  int wert(String key) => werte[key] ?? 0;

  Map<String, Object> toJson() => <String, Object>{
        'art': art,
        ...werte,
        if (optionen.isNotEmpty) 'optionen': List<int>.unmodifiable(optionen),
        if (zerlegungen.isNotEmpty)
          'zerlegungen': [
            for (final z in zerlegungen) List<int>.unmodifiable(z)
          ],
      };
}

/// Alltagsbilder der anderen Erklärung.
enum NachhilfeMotiv { eierkarton, packung, muenzen, teller, finger }

class NachhilfeSchritt {
  const NachhilfeSchritt({
    required this.id,
    required this.akteur,
    required this.text,
    required this.aktion,
    this.frage,
    this.hilfe,
  });

  final String id;
  final NachhilfeAkteur akteur;

  /// Kindgerechter Satz, darf vorgelesen werden.
  final String text;
  final NachhilfeAktion aktion;

  /// Zwischenergebnis, das das Kind selbst eintippt, bevor das Material sich
  /// bewegt. Nie das Ergebnis einer Originalaufgabe.
  final int? frage;

  /// Kleinere Hilfe genau für diesen Schritt (nach einer falschen Eingabe).
  final String? hilfe;

  Map<String, Object> toJson() => <String, Object>{
        'id': id,
        'wer': akteur.name,
        'text': text,
        'aktion': aktion.toJson(),
        if (frage != null) 'frage': frage!,
        if (hilfe != null) 'hilfe': hilfe!,
      };
}

/// Ein vollständiger Ablauf: eine Aufgabe, ein Weg, eine Stufe.
class NachhilfePlan {
  const NachhilfePlan({
    required this.original,
    required this.aufgabe,
    required this.weg,
    required this.stufe,
    required this.einleitung,
    required this.schritte,
    required this.lob,
    required this.abschluss,
  });

  /// Die Aufgabe, bei der das Kind hängt.
  final NachhilfeAufgabe original;

  /// Die Aufgabe, an der gearbeitet wird (bei Vorzeigen/Üben ein Zwilling).
  final NachhilfeAufgabe aufgabe;
  final NachhilfeWeg weg;
  final NachhilfeStufe stufe;
  final String einleitung;
  final List<NachhilfeSchritt> schritte;

  /// Lob für die Strategie, nicht für Schnelligkeit oder Begabung.
  final String lob;

  /// Übergabe zurück an die Originalaufgabe.
  final String abschluss;

  bool get anZwilling => aufgabe != original;

  Map<String, Object> toJson() => <String, Object>{
        'weg': weg.schluessel,
        'stufe': stufe.name,
        'a': aufgabe.a,
        'b': aufgabe.b,
        'zwilling': anZwilling,
        'einleitung': einleitung,
        'schritte': [for (final s in schritte) s.toJson()],
        'lob': lob,
        'abschluss': abschluss,
      };
}

/// Pädagogische Entscheidungslogik der Lumo-Nachhilfe (rein, deterministisch).
class LumoNachhilfe {
  const LumoNachhilfe();

  /// Verfügbare Wege in sinnvoller Reihenfolge.
  List<NachhilfeWeg> wegeFuer(NachhilfeAufgabe aufgabe) {
    if (aufgabe.typ != NachhilfeTyp.additionBis20) return _wegeNeu(aufgabe);
    final wege = <NachhilfeWeg>[];
    if (aufgabe.a < aufgabe.b && aufgabe.b - aufgabe.a > 1) {
      wege.add(NachhilfeWeg.tauschen);
    }
    wege.add(NachhilfeWeg.rechenrahmen);
    wege.add(NachhilfeWeg.zahlenstrahl);
    if (aufgabe.zehnerUebergang) wege.add(NachhilfeWeg.zerlegen);
    if ((aufgabe.a - aufgabe.b).abs() == 1 &&
        aufgabe.a <= 9 &&
        aufgabe.b <= 9) {
      wege.add(NachhilfeWeg.verdoppeln);
    }
    return wege;
  }

  /// Erkennt typische Fehlvorstellungen aus der falschen Antwort.
  NachhilfeFehlermuster erkenneFehler(
      NachhilfeAufgabe aufgabe, Object? antwort) {
    final wert = antwort is int
        ? antwort
        : int.tryParse('${antwort ?? ''}'.trim().replaceAll('−', '-'));
    final richtig = aufgabe.ergebnis;
    if (wert == null || wert == richtig) return NachhilfeFehlermuster.keines;
    if (aufgabe.typ != NachhilfeTyp.additionBis20) {
      return _fehlerNeu(aufgabe, wert);
    }
    if (richtig >= 10 && wert >= 10) {
      final gedreht = int.tryParse('$richtig'.split('').reversed.join());
      if (gedreht == wert && gedreht != richtig) {
        return NachhilfeFehlermuster.zifferndreher;
      }
    }
    if (wert == (aufgabe.a - aufgabe.b).abs() && aufgabe.a != aufgabe.b) {
      return NachhilfeFehlermuster.rechenzeichen;
    }
    if (aufgabe.zehnerUebergang &&
        (wert == richtig - 10 || wert == richtig + 10)) {
      return NachhilfeFehlermuster.zehnerVergessen;
    }
    if ((wert - richtig).abs() == 1) return NachhilfeFehlermuster.einsDaneben;
    return NachhilfeFehlermuster.keines;
  }

  /// Wählt den Weg, der zur erkannten Fehlvorstellung passt.
  /// [schonVersucht] überspringt Wege, die das Kind bereits gesehen hat.
  NachhilfeWeg wegFuer(
    NachhilfeAufgabe aufgabe, {
    NachhilfeFehlermuster fehler = NachhilfeFehlermuster.keines,
    Set<NachhilfeWeg> schonVersucht = const {},
  }) {
    final wege = wegeFuer(aufgabe);
    if (aufgabe.typ != NachhilfeTyp.additionBis20) {
      final passend = _wegFuerFehler(aufgabe, fehler, wege);
      if (!schonVersucht.contains(passend)) return passend;
      for (final weg in wege) {
        if (!schonVersucht.contains(weg)) return weg;
      }
      return wege.first;
    }
    final bevorzugt = switch (fehler) {
      // Zählfehler: Sprünge statt Einzelobjekte sichtbar machen.
      NachhilfeFehlermuster.einsDaneben => NachhilfeWeg.zahlenstrahl,
      // Plus/Minus: „dazu“ als Menge, die mehr wird.
      NachhilfeFehlermuster.rechenzeichen => NachhilfeWeg.rechenrahmen,
      // Zehnerübergang: Zerlegen macht den Zehner zum eigenen Schritt.
      NachhilfeFehlermuster.zehnerVergessen => aufgabe.zehnerUebergang
          ? NachhilfeWeg.zerlegen
          : NachhilfeWeg.rechenrahmen,
      // Zifferndreher: volle Zehnerreihe + Einer am Rechenrahmen.
      NachhilfeFehlermuster.zifferndreher => NachhilfeWeg.rechenrahmen,
      NachhilfeFehlermuster.keines ||
      NachhilfeFehlermuster.einerUmgedreht ||
      NachhilfeFehlermuster.plusStattMal ||
      NachhilfeFehlermuster.reiheVerrutscht =>
        wege.first,
    };
    if (wege.contains(bevorzugt) && !schonVersucht.contains(bevorzugt)) {
      return bevorzugt;
    }
    for (final weg in wege) {
      if (!schonVersucht.contains(weg)) return weg;
    }
    return wege.first;
  }

  /// Denkanstoß fürs kleine Einmaleins mit einer Kernaufgabe als Anker
  /// (z. B. „6 · 7 ist eine Reihe mehr als 5 · 7. Kennst du 5 · 7?“).
  /// Nennt nie das Ergebnis; auch die Texthilfe der Aufgabe nutzt ihn.
  String einmaleinsTipp(int a, int b) => _ankerTipp(a, b);

  /// Nächster Weg für „Anders zeigen“ (zyklisch).
  NachhilfeWeg naechsterWeg(NachhilfeAufgabe aufgabe, NachhilfeWeg aktuell) {
    final wege = wegeFuer(aufgabe);
    final index = wege.indexOf(aktuell);
    return wege[(index + 1) % wege.length];
  }

  /// Startstufe auf der Hilfeleiter: erst ein kleiner Tipp; nach zwei
  /// Versuchen andere Worte; nach drei Versuchen oder bei einer belegten
  /// wiederkehrenden Schwäche zeigt Lumo es sichtbar vor.
  NachhilfeStufe startStufe(
      {required int versuche, bool wiederholteSchwaeche = false}) {
    if (versuche >= 3 || wiederholteSchwaeche) return NachhilfeStufe.vorzeigen;
    if (versuche == 2) return NachhilfeStufe.andereErklaerung;
    return NachhilfeStufe.hinweis;
  }

  NachhilfeStufe? naechsteStufe(NachhilfeStufe stufe) {
    final next = stufe.index + 1;
    return next < NachhilfeStufe.values.length
        ? NachhilfeStufe.values[next]
        : null;
  }

  /// Zwillingsaufgabe mit gleicher Struktur (gleicher Weg passt, gleicher
  /// Zehnerübergang), aber anderem Ergebnis. [variante] wählt deterministisch.
  NachhilfeAufgabe zwilling(NachhilfeAufgabe aufgabe, {int variante = 0}) {
    if (aufgabe.typ != NachhilfeTyp.additionBis20) {
      return _zwillingNeu(aufgabe, variante);
    }
    final nachbar = (aufgabe.a - aufgabe.b).abs() == 1;
    List<NachhilfeAufgabe> suche({required bool streng}) {
      final kandidaten = <NachhilfeAufgabe>[];
      for (var a = 1; a <= 19; a++) {
        for (var b = 1; a + b <= 20; b++) {
          final k = NachhilfeAufgabe.addition(a, b)!;
          if (k.ergebnis == aufgabe.ergebnis) continue;
          if (k.zehnerUebergang != aufgabe.zehnerUebergang) continue;
          if (((a - b).abs() == 1 && a <= 9 && b <= 9) !=
              (nachbar && aufgabe.a <= 9 && aufgabe.b <= 9)) {
            continue;
          }
          if (streng) {
            if ((a >= 10) != (aufgabe.a >= 10)) continue;
            if ((a < b) != (aufgabe.a < aufgabe.b)) continue;
            if ((a - aufgabe.a).abs() > 2 || (b - aufgabe.b).abs() > 2) {
              continue;
            }
          }
          kandidaten.add(k);
        }
      }
      return kandidaten;
    }

    var kandidaten = suche(streng: true);
    if (kandidaten.isEmpty) kandidaten = suche(streng: false);
    kandidaten.sort((x, y) {
      final dx = (x.a - aufgabe.a).abs() + (x.b - aufgabe.b).abs();
      final dy = (y.a - aufgabe.a).abs() + (y.b - aufgabe.b).abs();
      return dx != dy
          ? dx.compareTo(dy)
          : (x.a * 100 + x.b).compareTo(y.a * 100 + y.b);
    });
    return kandidaten[variante.abs() % kandidaten.length];
  }

  /// Baut den vollständigen Ablauf für Weg und Stufe.
  NachhilfePlan plan(
      NachhilfeAufgabe original, NachhilfeWeg weg, NachhilfeStufe stufe) {
    if (original.typ != NachhilfeTyp.additionBis20 ||
        stufe == NachhilfeStufe.andereErklaerung) {
      return _planNeu(original, weg, stufe);
    }
    final aufgabe = switch (stufe) {
      NachhilfeStufe.andereErklaerung ||
      NachhilfeStufe.hinweis ||
      NachhilfeStufe.teilschritt =>
        original,
      NachhilfeStufe.vorzeigen => zwilling(original),
      NachhilfeStufe.ueben => zwilling(original, variante: 1),
    };
    final kern = _kernSchritte(aufgabe, weg);
    final schritte = <NachhilfeSchritt>[];
    switch (stufe) {
      case NachhilfeStufe.andereErklaerung:
      case NachhilfeStufe.hinweis:
        // Nur der Einstieg am Material; danach rechnet das Kind selbst.
        schritte.add(_als(kern.first, NachhilfeAkteur.lumo));
        schritte.add(NachhilfeSchritt(
          id: 'tipp',
          akteur: NachhilfeAkteur.lumo,
          text: _tipp(aufgabe, weg),
          aktion: NachhilfeAktion.zeigen(),
        ));
      case NachhilfeStufe.teilschritt:
        // Lumo macht den Anfang vor, das Kind den entscheidenden Teilschritt.
        // Der letzte Schritt (das Ergebnis) bleibt beim Kind in der Aufgabe.
        final ohneErgebnis =
            kern.where((k) => k.aktion.art != 'ergebnis').toList();
        final teil = ohneErgebnis.length > 2
            ? ohneErgebnis.sublist(0, ohneErgebnis.length - 1)
            : ohneErgebnis;
        for (var i = 0; i < teil.length; i++) {
          schritte.add(_als(
              teil[i], i == 0 ? NachhilfeAkteur.lumo : NachhilfeAkteur.kind));
        }
      case NachhilfeStufe.vorzeigen:
        for (final k in kern) {
          schritte.add(_als(k, NachhilfeAkteur.lumo));
        }
      case NachhilfeStufe.ueben:
        for (final k in kern) {
          schritte.add(_als(k, NachhilfeAkteur.kind));
        }
    }
    return NachhilfePlan(
      original: original,
      aufgabe: aufgabe,
      weg: weg,
      stufe: stufe,
      einleitung: _einleitung(original, aufgabe, weg, stufe),
      schritte: List.unmodifiable(schritte),
      lob: lobFuer(weg),
      abschluss:
          stufe == NachhilfeStufe.hinweis || stufe == NachhilfeStufe.teilschritt
              ? 'Jetzt rechnest du ${original.text} selbst fertig.'
              : 'Genauso geht ${original.text}. Probier es jetzt selbst.',
    );
  }

  /// Strategie-Lob: benennt den Denkweg (prozessbezogen), nicht Begabung.
  String lobFuer(NachhilfeWeg weg) => switch (weg) {
        NachhilfeWeg.rechenrahmen =>
          'Stark! Du hast zuerst die Zehnerreihe voll gemacht – so musst du nicht einzeln zählen.',
        NachhilfeWeg.zahlenstrahl =>
          'Super gesprungen! Erst bis zur 10, dann weiter – das ist ein kluger Weg.',
        NachhilfeWeg.zerlegen =>
          'Toll zerlegt! Du hast die Zahl so geteilt, dass die 10 voll wird.',
        NachhilfeWeg.verdoppeln =>
          'Clever! Du hast eine Verdopplung benutzt und nur eins dazugetan.',
        NachhilfeWeg.tauschen =>
          'Schlau getauscht! Mit der großen Zahl anfangen spart Arbeit.',
        NachhilfeWeg.stangen =>
          'Stark! Erst die Zehner, dann die Einer – Stück für Stück.',
        NachhilfeWeg.punktefeld =>
          'Super! Du hast Reihe für Reihe weitergezählt.',
        NachhilfeWeg.kernaufgabe =>
          'Clever! Du hast eine Malaufgabe benutzt, die du schon kennst.',
      };

  String _einleitung(NachhilfeAufgabe original, NachhilfeAufgabe aufgabe,
      NachhilfeWeg weg, NachhilfeStufe stufe) {
    final material = switch (weg) {
      NachhilfeWeg.rechenrahmen => 'mit dem Rechenrahmen',
      NachhilfeWeg.zahlenstrahl => 'auf dem Zahlenstrahl',
      NachhilfeWeg.zerlegen => 'mit Zerlegen',
      NachhilfeWeg.verdoppeln => 'mit Verdoppeln',
      NachhilfeWeg.tauschen => 'mit Tauschen',
      NachhilfeWeg.stangen => 'mit Zehnerstangen',
      NachhilfeWeg.punktefeld => 'mit dem Punktefeld',
      NachhilfeWeg.kernaufgabe => 'mit einer Kernaufgabe',
    };
    return switch (stufe) {
      NachhilfeStufe.andereErklaerung ||
      NachhilfeStufe.hinweis =>
        'Ich gebe dir einen Tipp für ${original.text} $material.',
      NachhilfeStufe.teilschritt =>
        'Wir fangen ${original.text} gemeinsam an – $material.',
      NachhilfeStufe.vorzeigen =>
        'Schau mir zu: Ich rechne ${aufgabe.text} $material. ${original.text} geht genauso.',
      NachhilfeStufe.ueben => 'Jetzt du: Rechne ${aufgabe.text} $material.',
    };
  }

  String _tipp(NachhilfeAufgabe aufgabe, NachhilfeWeg weg) {
    if (!aufgabe.zehnerUebergang) {
      return switch (weg) {
        NachhilfeWeg.tauschen =>
          'Fang mit der größeren Zahl an und zähl die kleinere dazu.',
        NachhilfeWeg.zahlenstrahl =>
          'Stell dich auf die ${aufgabe.a} und mach ${aufgabe.b} Sprünge nach vorne.',
        _ =>
          'Schieb ${aufgabe.b} Perlen dazu und schau, wie viele es jetzt sind.',
      };
    }
    return switch (weg) {
      NachhilfeWeg.rechenrahmen =>
        'Wie viele Perlen fehlen in der ersten Reihe bis zur 10?',
      NachhilfeWeg.zahlenstrahl =>
        'Spring zuerst bis zur 10. Wie weit ist das von der ${aufgabe.a}?',
      NachhilfeWeg.zerlegen =>
        'Teile die ${aufgabe.b} so, dass die ${aufgabe.a} genau 10 wird.',
      NachhilfeWeg.verdoppeln =>
        'Kennst du ${_kleiner(aufgabe)} + ${_kleiner(aufgabe)}? Dann fehlt nur noch eins.',
      NachhilfeWeg.tauschen ||
      NachhilfeWeg.stangen ||
      NachhilfeWeg.punktefeld ||
      NachhilfeWeg.kernaufgabe =>
        'Fang mit der größeren Zahl an.',
    };
  }

  int _kleiner(NachhilfeAufgabe a) => a.a < a.b ? a.a : a.b;

  NachhilfeSchritt _als(_Kern k, NachhilfeAkteur akteur) => NachhilfeSchritt(
        id: k.id,
        akteur: akteur,
        text: akteur == NachhilfeAkteur.lumo ? k.lumo : k.kind,
        aktion: k.aktion,
      );

  List<int> _ergebnisOptionen(int richtig) {
    final werte = <int>{richtig - 1, richtig, richtig + 1};
    if (richtig - 1 < 0) werte.add(richtig + 2);
    final liste = werte.where((w) => w >= 0).toList()..sort();
    return liste;
  }

  List<List<int>> _zerlegungen(int ganz, int teil1) {
    final optionen = <List<int>>[];
    for (final t in <int>{teil1 - 1, teil1, teil1 + 1}) {
      if (t >= 1 && t < ganz) optionen.add([t, ganz - t]);
    }
    return optionen;
  }

  List<_Kern> _kernSchritte(NachhilfeAufgabe aufg, NachhilfeWeg weg) {
    final a = aufg.a, b = aufg.b, e = aufg.ergebnis;
    final fuenf = a > 5 && a <= 10 ? ' Fünf rote und ${a - 5} weiße.' : '';
    final ergebnis = _Kern(
      'ergebnis',
      kind: 'Wie viel ist ${aufg.text}? Tipp auf das Ergebnis.',
      lumo: '${aufg.text} = $e.',
      aktion: NachhilfeAktion.ergebnis(e, _ergebnisOptionen(e)),
    );
    final ersteReihe = _Kern(
      'erste',
      kind: 'Schieb $a Perlen nach links in die erste Reihe.$fuenf',
      lumo: 'Ich schiebe $a Perlen nach links.$fuenf',
      aktion: NachhilfeAktion.perlen(a, 0),
    );
    final aufStart = _Kern(
      'start',
      kind: 'Tipp auf den Stein $a. Lumo springt hin.',
      lumo: 'Ich springe auf die $a.',
      aktion: NachhilfeAktion.huepfen(0, a),
    );
    switch (weg) {
      case NachhilfeWeg.stangen:
      case NachhilfeWeg.punktefeld:
      case NachhilfeWeg.kernaufgabe:
        // Gibt es bei Plus bis 20 nicht (siehe wegeFuer).
        return _kernSchritte(aufg, NachhilfeWeg.rechenrahmen);
      case NachhilfeWeg.tauschen:
        final gross = a > b ? a : b, klein = a > b ? b : a;
        return [
          _Kern(
            'tauschen',
            kind:
                '$klein + $gross ist dasselbe wie $gross + $klein. Tipp auf die größere Zahl.',
            lumo:
                '$klein + $gross ist dasselbe wie $gross + $klein. Ich starte bei $gross.',
            aktion: NachhilfeAktion.huepfen(0, gross),
          ),
          _Kern(
            'dazu',
            kind: 'Jetzt $klein Sprünge weiter. Wo landet Lumo?',
            lumo: 'Ich springe $klein weiter und lande auf $e.',
            aktion: NachhilfeAktion.huepfen(gross, e),
          ),
          ergebnis,
        ];
      case NachhilfeWeg.zahlenstrahl:
        if (!aufg.zehnerUebergang) {
          return [
            aufStart,
            _Kern(
              'dazu',
              kind: 'Jetzt $b Sprünge weiter. Wo landet Lumo?',
              lumo: 'Ich springe $b weiter und lande auf $e.',
              aktion: NachhilfeAktion.huepfen(a, e),
            ),
            ergebnis,
          ];
        }
        return [
          aufStart,
          _Kern(
            'zehn',
            kind: 'Spring bis zur 10. Tipp auf die 10.',
            lumo: 'Ich springe bis zur 10. Das sind ${aufg.bisZehn} Sprünge.',
            aktion: NachhilfeAktion.huepfen(a, 10),
          ),
          _Kern(
            'rest',
            kind:
                '${aufg.bisZehn} von den $b hast du schon gesprungen. Wie viele fehlen noch? Spring weiter.',
            lumo:
                'Von den $b sind noch ${aufg.rest} übrig. Ich springe ${aufg.rest} weiter.',
            aktion: NachhilfeAktion.huepfen(10, e),
          ),
          ergebnis,
        ];
      case NachhilfeWeg.zerlegen:
        if (!aufg.zehnerUebergang) {
          return _kernSchritte(aufg, NachhilfeWeg.rechenrahmen);
        }
        return [
          ersteReihe,
          _Kern(
            'teilen',
            kind:
                'Teile die $b in zwei Teile. Der erste Teil macht die $a zur 10.',
            lumo:
                'Der $a fehlen ${aufg.bisZehn} bis zur 10. Also teile ich $b in ${aufg.bisZehn} und ${aufg.rest}.',
            aktion: NachhilfeAktion.zerlegen(
                b, aufg.bisZehn, aufg.rest, _zerlegungen(b, aufg.bisZehn)),
          ),
          _Kern(
            'zehn',
            kind: 'Schieb den ersten Teil dazu, bis die Reihe voll ist.',
            lumo:
                'Ich schiebe ${aufg.bisZehn} dazu: $a + ${aufg.bisZehn} = 10.',
            aktion: NachhilfeAktion.perlen(10, 0),
          ),
          _Kern(
            'rest',
            kind: 'Schieb den zweiten Teil in die zweite Reihe.',
            lumo:
                'Die anderen ${aufg.rest} kommen in die zweite Reihe: 10 + ${aufg.rest} = $e.',
            aktion: NachhilfeAktion.perlen(10, aufg.rest),
          ),
          ergebnis,
        ];
      case NachhilfeWeg.verdoppeln:
        final k = _kleiner(aufg);
        return [
          _Kern(
            'doppel',
            kind: 'Schieb in beide Reihen $k Perlen. Das ist $k + $k.',
            lumo: 'Ich schiebe in beide Reihen $k Perlen: $k + $k = ${2 * k}.',
            aktion: NachhilfeAktion.perlen(k, k),
          ),
          _Kern(
            'eins',
            kind:
                'Bei ${aufg.text} ist eine Zahl um eins größer. Schieb noch eine Perle dazu.',
            lumo:
                'Eine Zahl ist um eins größer. Ich schiebe noch eine dazu: ${2 * k} + 1 = $e.',
            aktion: NachhilfeAktion.perlen(k + 1, k),
          ),
          ergebnis,
        ];
      case NachhilfeWeg.rechenrahmen:
        if (a >= 10) {
          return [
            _Kern(
              'erste',
              kind:
                  'Leg $a: eine volle Zehnerreihe und ${a - 10} in die zweite Reihe.',
              lumo:
                  '$a ist eine volle Zehnerreihe und ${a - 10} in der zweiten Reihe.',
              aktion: NachhilfeAktion.perlen(10, a - 10),
            ),
            _Kern(
              'dazu',
              kind: 'Schieb in der zweiten Reihe $b dazu.',
              lumo:
                  'Ich schiebe $b dazu: ${a - 10} + $b = ${a - 10 + b}. Mit dem Zehner sind es $e.',
              aktion: NachhilfeAktion.perlen(10, a - 10 + b),
            ),
            ergebnis,
          ];
        }
        if (!aufg.zehnerUebergang) {
          return [
            ersteReihe,
            _Kern(
              'dazu',
              kind: 'Schieb $b Perlen dazu.',
              lumo: 'Ich schiebe $b dazu. Jetzt sind es $e.',
              aktion: NachhilfeAktion.perlen(e, 0),
            ),
            ergebnis,
          ];
        }
        return [
          ersteReihe,
          _Kern(
            'zehn',
            kind: 'Mach die erste Reihe voll. Wie viele fehlen bis 10?',
            lumo:
                'Bis zur 10 fehlen ${aufg.bisZehn}. Ich mache die Reihe voll.',
            aktion: NachhilfeAktion.perlen(10, 0),
          ),
          _Kern(
            'rest',
            kind:
                'Von den $b hast du ${aufg.bisZehn} benutzt. Schieb den Rest in die zweite Reihe.',
            lumo:
                'Von den $b sind noch ${aufg.rest} übrig. Sie kommen in die zweite Reihe: 10 + ${aufg.rest} = $e.',
            aktion: NachhilfeAktion.perlen(10, aufg.rest),
          ),
          ergebnis,
        ];
    }
  }
}

/// Ein Kernschritt mit beiden Sprechweisen: Aufforderung an das Kind und
/// Ich-Form für Lumos Vorzeigen.
class _Kern {
  const _Kern(this.id,
      {required this.kind,
      required this.lumo,
      required this.aktion,
      this.frage,
      this.hilfe,
      this.nurLumo = false,
      this.auftrag});

  final String id;
  final String kind;
  final String lumo;
  final NachhilfeAktion aktion;

  /// Zwischenergebnis, das das Kind eintippt (nur Zahlenraum 100/Einmaleins).
  final int? frage;
  final String? hilfe;

  /// Reine Vorführung (Bündeln, Feld drehen): immer Lumos Handgriff.
  final bool nurLumo;

  /// Aufforderung ohne Frage für das Ende von „Gemeinsam“: diesen letzten
  /// Schritt rechnet das Kind in seiner Aufgabe.
  final String? auftrag;
}
