/// Fach-Nachhilfe für Englisch, Lesen und Sachunterricht – mehrstufig wie die
/// Mathe-Nachhilfe ([NachhilfeStufe]): kleiner Tipp → andere Erklärung →
/// Lumo zeigt → gemeinsam → selbst prüfen an einer ähnlichen Aufgabe.
///
/// - Englisch: das Wort genau anschauen, Bilder zu den Antworten (mit Rätsel),
///   eine einfache Situation an einem anderen Wort, gemeinsam ausschließen.
///   Lumos Stimme ist deutsch: Englische Wörter werden nur gezeigt, nie
///   vorgesprochen – es wird keine Aussprache behauptet.
/// - Lesen: die Frage genau lesen, schwierige Laute gezielt, Lumo liest
///   langsam vor (vorhandener „Langsamer“-Weg der Stimme), den passenden Satz
///   finden, eigenständiger Leseversuch an einer ähnlichen Aufgabe.
/// - Sachunterricht: das wichtige Wort, ein lebensnahes Beispiel, ein
///   animiertes Schaubild zum Thema, gemeinsam ausschließen.
///
/// Keine Stufe an der Originalaufgabe verrät die Lösung: Jeder Text und jede
/// Beschriftung wird mit [FachNachhilfe.verraet] geprüft und sonst durch einen
/// allgemeinen Denkanstoß ersetzt bzw. mit „?“ verdeckt. Vollständig gezeigt
/// wird nur an einer anderen, ähnlichen Aufgabe. Nie in Tests/Schularbeiten.
library;

import '../../core/school_exercise_generator.dart';
import 'hilfe_folge.dart';
import 'lumo_nachhilfe.dart';

part 'fach_nachhilfe_daten.dart';

enum FachNachhilfeFach { englisch, lesen, sachunterricht }

/// Richtung einer Englisch-Aufgabe.
enum EnglischRichtung { englischDeutsch, deutschEnglisch }

/// Eine geprüfte Auswahlaufgabe aus Englisch, Lesen oder Sachunterricht.
class FachAufgabe {
  const FachAufgabe._({
    required this.fach,
    required this.thema,
    required this.prompt,
    required this.antwort,
    required this.auswahl,
    required this.erklaerung,
    required this.schulstufe,
  });

  final FachNachhilfeFach fach;

  /// Thema (Unit-Schlüssel wie im Übungsbereich).
  final String thema;
  final String prompt;
  final String antwort;
  final List<String> auswahl;
  final String erklaerung;
  final int schulstufe;

  static const _faecher = {
    'Englisch': FachNachhilfeFach.englisch,
    'Lesen': FachNachhilfeFach.lesen,
    'Sachunterricht': FachNachhilfeFach.sachunterricht,
  };

  /// Nur echte Auswahlaufgaben der drei Fächer mit der Lösung unter den
  /// Antworten; Schreib- und Zeichenaufgaben liefern null.
  static FachAufgabe? ausTask(LumoTask task) => aus(
        fach: task.subject,
        thema: task.unit,
        prompt: task.prompt,
        antwort: task.answer,
        auswahl: task.choices,
        erklaerung: task.explanation,
        schulstufe: task.grade,
        handschrift: task.handwriting || task.visual == 'shape_trace',
      );

  static FachAufgabe? aus({
    required String fach,
    required String thema,
    required String prompt,
    required String antwort,
    required List<String> auswahl,
    String erklaerung = '',
    int schulstufe = 1,
    bool handschrift = false,
  }) {
    final f = _faecher[fach];
    if (f == null || handschrift) return null;
    final a = antwort.trim();
    final optionen = [
      for (final c in auswahl)
        if (c.trim().isNotEmpty) c.trim(),
    ];
    if (a.isEmpty || optionen.length < 2 || !optionen.contains(a)) return null;
    if (prompt.trim().isEmpty) return null;
    return FachAufgabe._(
      fach: f,
      thema: thema,
      prompt: prompt.trim(),
      antwort: a,
      auswahl: List.unmodifiable(optionen),
      erklaerung: erklaerung,
      schulstufe: schulstufe.clamp(1, 4).toInt(),
    );
  }

  String get fachName => switch (fach) {
        FachNachhilfeFach.englisch => 'Englisch',
        FachNachhilfeFach.lesen => 'Lesen',
        FachNachhilfeFach.sachunterricht => 'Sachunterricht',
      };

  String get themaText => Curriculum.prettifyUnit(thema);

  // ---- Englisch ---------------------------------------------------------

  static final _zitat = RegExp('„([^“]+)“');

  /// Das gefragte Wort oder der gefragte Satz (aus „…“).
  String? get gefragt => _zitat.firstMatch(prompt)?.group(1)?.trim();

  EnglischRichtung get richtung => prompt.contains('auf Englisch')
      ? EnglischRichtung.deutschEnglisch
      : EnglischRichtung.englischDeutsch;

  bool get istSatz => prompt.contains('dieser Satz');

  // ---- Lesen ------------------------------------------------------------

  List<String> get _zeilen => prompt
      .split('\n')
      .map((z) => z.trim())
      .where((z) => z.isNotEmpty)
      .toList();

  /// Die Frage (letzte Zeile).
  String get frage => _zeilen.isEmpty ? prompt : _zeilen.last;

  /// Der Lesetext ohne Frage und ohne Vorsatz wie „Lies:“.
  String get lesetext {
    final z = _zeilen;
    if (z.length < 2) return '';
    return z
        .sublist(0, z.length - 1)
        .join(' ')
        .replaceFirst(RegExp(r'^(Lies|Schau genau):\s*'), '')
        .replaceFirst(RegExp(r'^Die Sätze sind durcheinander:\s*'), '')
        .trim();
  }

  /// Sätze des Lesetextes.
  List<String> get saetze => lesetext
      .split(RegExp(r'(?<=[.!?])\s+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  bool get istBildWort => prompt.contains('zu diesem Bild');
  bool get istReihenfolge => prompt.startsWith('Die Sätze sind durcheinander');
  bool get istWortWahl => prompt.contains('Welches Wort passt?');

  /// Bild (Emoji) einer „Bild und Wort“-Aufgabe.
  String? get bildZeichen =>
      istBildWort ? lesetext.replaceAll(RegExp(r'[\s.]'), '') : null;

  @override
  bool operator ==(Object other) =>
      other is FachAufgabe && other.prompt == prompt && other.antwort == antwort;

  @override
  int get hashCode => Object.hash(prompt, antwort);
}

/// Bildkarte: ein Wort mit Bild (Emoji), Farbfläche oder Punktmenge.
class FachBildkarte {
  const FachBildkarte(this.wort, {this.bild, this.farbe, this.menge});
  final String wort;
  final String? bild;
  final int? farbe;
  final int? menge;

  bool get hatBild => bild != null || farbe != null || menge != null;

  static FachBildkarte fuer(String wort) => FachBildkarte(wort,
      bild: _bilder[wort],
      farbe: _farben[wort.toLowerCase()],
      menge: _zahlwoerter[wort.toLowerCase()]);
}

/// Ein Knoten des Schaubilds; [verdeckt] = Beschriftung würde die Lösung
/// verraten und wird als „?“ gezeigt.
class FachSchaubildKnoten {
  const FachSchaubildKnoten(this.bild, this.titel, this.text,
      {this.verdeckt = false});
  final String bild;
  final String titel;
  final String text;
  final bool verdeckt;
}

class FachSchaubild {
  const FachSchaubild(this.titel, this.knoten, {this.kreis = false});
  final String titel;
  final List<FachSchaubildKnoten> knoten;
  final bool kreis;
}

/// Was das Material der Stufe zeigt.
enum FachMaterialArt {
  /// Englisches oder deutsches Wort groß, Buchstabe für Buchstabe.
  wort,

  /// Bildkarten zu allen Antworten (oder zum gegebenen Wort).
  bildkarten,

  /// Kleine Situation: Lumo, ein Bild und eine Sprechblase.
  szene,

  /// Text mit hervorgehobenen Wörtern (Fragewort, wichtige Wörter).
  markierung,

  /// Wörter oder Sätze mit hervorgehobenen schwierigen Lauten.
  laute,

  /// Lumo liest Satz für Satz langsam vor (Satz leuchtet auf).
  vorlesen,

  /// Den Satz antippen, der hilft.
  satzWahl,

  /// Gemeinsam ausschließen: unpassende Antworten antippen.
  ausschliessen,

  /// Animiertes Schaubild (Sachunterricht).
  schaubild,

  /// Lebensnahes Beispiel (Alltagsbild).
  alltag,

  /// Ähnliche Aufgabe ganz allein (Prüfung).
  pruefen,
}

class FachMaterial {
  const FachMaterial(
    this.art, {
    this.wort,
    this.karten = const [],
    this.szeneBild,
    this.sprechblase,
    this.saetze = const [],
    this.markiert = const [],
    this.schaubild,
    this.richtigerSatz,
    this.auswahl = const [],
    this.falsche = const {},
    this.bild,
  });

  final FachMaterialArt art;
  final String? wort;
  final List<FachBildkarte> karten;
  final FachBildkarte? szeneBild;
  final String? sprechblase;
  final List<String> saetze;

  /// Hervorzuhebende Wörter oder Buchstabengruppen.
  final List<String> markiert;
  final FachSchaubild? schaubild;

  /// Index des Satzes, den das Kind finden soll (nur [FachMaterialArt.satzWahl]).
  final int? richtigerSatz;

  /// Antworten (Ausschließen, Prüfung).
  final List<String> auswahl;

  /// Sicher unpassende Antworten (nur für die Rückmeldung beim Ausschließen;
  /// die richtige wird nie bestätigt).
  final Set<String> falsche;

  /// Bild der Aufgabe (z. B. Emoji bei „Bild und Wort“).
  final String? bild;
}

/// Ein Schritt der Fach-Nachhilfe für eine Stufe.
class FachPlan {
  const FachPlan({
    required this.original,
    required this.aufgabe,
    required this.stufe,
    required this.methode,
    required this.titel,
    required this.text,
    required this.sprechText,
    required this.material,
    required this.abschluss,
    this.langsam = false,
  });

  final FachAufgabe original;

  /// Die Aufgabe, an der gearbeitet wird (bei „Lumo zeigt“ ggf. ein Beispiel,
  /// bei „Selbst prüfen“ immer eine ähnliche Aufgabe).
  final FachAufgabe aufgabe;
  final NachhilfeStufe stufe;

  /// Erklärweise (Schlüssel, wird mit der Antwort gespeichert).
  final String methode;
  final String titel;
  final String text;

  /// Was Lumo spricht: ohne englische Wörter (deutsche Stimme).
  final String sprechText;
  final FachMaterial material;
  final String abschluss;

  /// Lumo liest langsam (vorhandener „Langsamer“-Weg der Stimme).
  final bool langsam;

  bool get anBeispiel => aufgabe != original;
}

/// Ergebnis der eigenständigen Vergleichsaufgabe (Stufe 5).
class FachPruefung {
  const FachPruefung({
    required this.aufgabe,
    required this.antwort,
    required this.versuche,
    required this.methode,
  });

  final FachAufgabe aufgabe;
  final String antwort;
  final int versuche;

  /// Zuletzt gezeigte Erklärweise vor der Prüfung.
  final String methode;

  bool get richtig => antwort == aufgabe.antwort;

  /// Nur beim ersten Versuch richtig zählt als selbstständig.
  bool get selbststaendig => richtig && versuche == 1;
}

/// Pädagogische Logik der Fach-Nachhilfe (rein, deterministisch).
class FachNachhilfe {
  const FachNachhilfe();

  static const _stopp = {
    'der', 'die', 'das', 'den', 'dem', 'des', 'ein', 'eine', 'einen', 'einem',
    'einer', 'und', 'oder', 'mit', 'von', 'vom', 'zum', 'zur', 'auf', 'aus',
    'ist', 'sind', 'war', 'im', 'in', 'am', 'an', 'es', 'er', 'sie', 'wir',
    'ich', 'du', 'ihr', 'nur', 'sehr', 'wird', 'nicht', 'kein', 'keine',
    'sich', 'als', 'wie', 'was', 'wer', 'wo', 'zu', 'bei', 'für', 'um',
    'nach', 'über', 'unter', 'vor', 'dass', 'ganz', 'man', 'kann', 'hat',
    'haben', 'dann', 'noch', 'auch', 'so', 'ja', 'nein', 'wenn', 'immer',
    'dein', 'deine', 'mein', 'meine', 'sein', 'seine', 'ihre', 'the', 'a',
    'is', 'to', 'of', 'and', 'you', 'i', 'it', 'meist', 'meistens',
    'oft', 'viel', 'viele', 'wenig', 'etwas', 'alle', 'jeden', 'jede',
  };

  static List<String> _woerter(String s) => s
      .toLowerCase()
      .split(RegExp(r'[^a-zäöüß0-9]+'))
      .where((w) => w.isNotEmpty)
      .toList();

  /// Verrät [text] die Lösung von [aufgabe]? Prüft die ganze Antwort und
  /// jedes bedeutungstragende Antwortwort (auch als Wortanfang: „verdunstet“
  /// in „Verdunsten“), ausgenommen Wörter, die schon in der Frage stehen.
  bool verraet(String text, FachAufgabe aufgabe) {
    final t = _woerter(text);
    if (t.isEmpty) return false;
    final a = _woerter(aufgabe.antwort);
    if (a.isEmpty) return false;
    final kette = ' ${t.join(' ')} ';
    if (kette.contains(' ${a.join(' ')} ')) return true;
    final frage = _woerter(aufgabe.prompt).toSet();
    for (final w in a) {
      if (_stopp.contains(w) || frage.contains(w)) continue;
      if (RegExp(r'^\d+$').hasMatch(w)) {
        if (t.contains(w)) return true;
        continue;
      }
      if (w.length < 4) continue;
      final stamm = w.length <= 5
          ? w
          : w.substring(0, w.length - 2 < 5 ? 5 : w.length - 2);
      if (t.any((x) => x == w || x.startsWith(stamm))) return true;
    }
    return false;
  }

  String _sicher(String text, FachAufgabe a, String ersatz) {
    for (final t in [
      text,
      ersatz,
      'Lies die Frage noch einmal langsam und prüfe jede Antwort einzeln.',
    ]) {
      if (!verraet(t, a)) return t;
    }
    return 'Denk in Ruhe nach und prüfe jede Antwort einzeln.';
  }

  /// Englische Wörter spricht Lumos deutsche Stimme nicht: Zitate in „…“
  /// werden durch „das englische Wort“ ersetzt.
  String sprechbar(String text, FachAufgabe a) {
    if (a.fach != FachNachhilfeFach.englisch) return text;
    // Deutsch und damit sprechbar: das Thema und – bei „Wie heißt … auf
    // Englisch?“ – das gegebene deutsche Wort.
    final deutsch = {
      a.themaText,
      if (a.richtung == EnglischRichtung.deutschEnglisch) a.gefragt ?? '',
      'weil', 'deshalb', 'damit',
    };
    return text
        .replaceAllMapped(RegExp('zu „([^“]+)“'), (m) =>
            deutsch.contains(m.group(1)) ? m.group(0)! : 'zum Wort auf der Karte')
        .replaceAllMapped(RegExp('„([^“]+)“'), (m) =>
            deutsch.contains(m.group(1)) ? m.group(0)! : 'das Wort auf der Karte');
  }

  /// Methoden je Stufe für dieses Fach (Methodenfolge der Hilfeleiter).
  static String methodeFuer(FachAufgabe a, NachhilfeStufe stufe) =>
      switch ((a.fach, stufe)) {
        (_, NachhilfeStufe.ueben) => 'pruefen',
        (_, NachhilfeStufe.teilschritt) => 'ausschliessen',
        (FachNachhilfeFach.englisch, NachhilfeStufe.hinweis) => 'wort',
        (FachNachhilfeFach.englisch, NachhilfeStufe.andereErklaerung) =>
          'bild',
        (FachNachhilfeFach.englisch, NachhilfeStufe.vorzeigen) => 'situation',
        (FachNachhilfeFach.lesen, NachhilfeStufe.hinweis) => 'frage',
        (FachNachhilfeFach.lesen, NachhilfeStufe.andereErklaerung) => 'laute',
        (FachNachhilfeFach.lesen, NachhilfeStufe.vorzeigen) => 'vorlesen',
        (FachNachhilfeFach.sachunterricht, NachhilfeStufe.hinweis) =>
          'schluesselwort',
        (FachNachhilfeFach.sachunterricht, NachhilfeStufe.andereErklaerung) =>
          'alltag',
        (FachNachhilfeFach.sachunterricht, NachhilfeStufe.vorzeigen) =>
          'schaubild',
      };

  /// Startstufe wie in der Mathe-Nachhilfe: erst ein kleiner Tipp, nach zwei
  /// Versuchen andere Worte, nach drei Versuchen zeigt Lumo.
  NachhilfeStufe startStufe({required int versuche}) =>
      const LumoNachhilfe().startStufe(versuche: versuche);

  /// Ein passendes Beispiel für „Lumo zeigt“ (Englisch): gleiche Richtung und
  /// Art, andere Lösung, die Lösung der Originalaufgabe kommt nicht vor.
  bool passtAlsBeispiel(FachAufgabe original, FachAufgabe beispiel) =>
      beispiel.fach == original.fach &&
      beispiel.thema == original.thema &&
      beispiel.prompt != original.prompt &&
      beispiel.antwort != original.antwort &&
      (original.fach != FachNachhilfeFach.englisch ||
          (beispiel.richtung == original.richtung &&
              beispiel.istSatz == original.istSatz)) &&
      !verraet('${beispiel.prompt} ${beispiel.antwort} ${beispiel.erklaerung}',
          original);

  /// Eine ähnliche, eigenständige Aufgabe für „Selbst prüfen“.
  bool passtAlsPruefung(FachAufgabe original, FachAufgabe pruefung) =>
      pruefung.fach == original.fach &&
      pruefung.thema == original.thema &&
      pruefung.prompt != original.prompt &&
      pruefung.antwort != original.antwort;

  /// Baut die Stufe. [beispiel] (andere ähnliche Aufgabe) nutzt „Lumo zeigt“
  /// im Englischen; [pruefung] ist die Vergleichsaufgabe der Stufe 5.
  FachPlan plan(FachAufgabe original, NachhilfeStufe stufe,
      {FachAufgabe? beispiel, FachAufgabe? pruefung}) {
    final methode = methodeFuer(original, stufe);
    if (stufe == NachhilfeStufe.ueben) {
      final p = pruefung != null && passtAlsPruefung(original, pruefung)
          ? pruefung
          : null;
      return _pruefen(original, p);
    }
    if (stufe == NachhilfeStufe.teilschritt) {
      final satz = original.fach == FachNachhilfeFach.lesen
          ? _satzWahl(original)
          : null;
      if (satz != null) return satz;
      return _plan(
        original,
        stufe,
        methode,
        'Gemeinsam ausschließen',
        'Wir machen es gemeinsam: Tippe auf zwei Antworten, die sicher nicht '
            'passen. Sag dir jedes Mal, warum. Die letzte Entscheidung '
            'triffst du dann selbst in deiner Aufgabe.',
        FachMaterial(FachMaterialArt.ausschliessen,
            auswahl: original.auswahl,
            falsche: {
              for (final c in original.auswahl)
                if (c != original.antwort) c,
            }),
      );
    }
    return switch (original.fach) {
      FachNachhilfeFach.englisch => _englisch(original, stufe, methode,
          beispiel != null && passtAlsBeispiel(original, beispiel)
              ? beispiel
              : null),
      FachNachhilfeFach.lesen => _lesen(original, stufe, methode),
      FachNachhilfeFach.sachunterricht =>
        _sachunterricht(original, stufe, methode),
    };
  }

  FachPlan _plan(FachAufgabe a, NachhilfeStufe stufe, String methode,
      String titel, String text, FachMaterial material,
      {FachAufgabe? an, bool langsam = false, String? sprech}) {
    final sicher = an == null
        ? _sicher(text, a, _allgemein(a, stufe))
        : text; // An einem Beispiel darf Lumo es ganz zeigen.
    return FachPlan(
      original: a,
      aufgabe: an ?? a,
      stufe: stufe,
      methode: methode,
      titel: titel,
      text: sicher,
      sprechText: sprechbar(sprech ?? sicher, a),
      material: material,
      langsam: langsam,
      abschluss: stufe == NachhilfeStufe.ueben
          ? 'Super! Jetzt schaffst du auch deine Aufgabe.'
          : 'Jetzt probierst du deine Aufgabe selbst.',
    );
  }

  /// Allgemeiner Denkanstoß, wenn ein Text die Lösung verraten würde.
  String _allgemein(FachAufgabe a, NachhilfeStufe stufe) =>
      switch (a.fach) {
        FachNachhilfeFach.englisch =>
          'Lies das Englische Wort für Wort. Welche Wörter kennst du schon? '
              'Vergleiche dann jede Antwort damit.',
        FachNachhilfeFach.lesen =>
          'Lies den Text noch einmal langsam, Satz für Satz. Suche die Stelle, '
              'die genau zur Frage passt.',
        FachNachhilfeFach.sachunterricht =>
          'Denk an deinen Alltag: Wo hast du so etwas schon erlebt – zu Hause, '
              'in der Schule oder draußen? Prüfe jede Antwort damit.',
      };

  // ---- Englisch ---------------------------------------------------------

  FachPlan _englisch(FachAufgabe a, NachhilfeStufe stufe, String methode,
      FachAufgabe? beispiel) {
    final g = a.gefragt ?? '';
    final thema = '„${a.themaText}“';
    final deEn = a.richtung == EnglischRichtung.deutschEnglisch;
    switch (stufe) {
      case NachhilfeStufe.hinweis:
        final String text;
        if (a.istSatz) {
          text = deEn
              ? 'Gesucht ist der englische Satz für „$g“. Achte auf das erste '
                  'Wort: Ist es eine Frage, eine Bitte oder eine Aussage? '
                  'Welche englischen Wörter kennst du schon?'
              : 'Lies den englischen Satz Wort für Wort. Welche Wörter kennst '
                  'du schon? Ein Fragezeichen am Ende heißt: Jemand fragt '
                  'etwas.';
        } else if (deEn) {
          text = 'Gesucht ist das englische Wort für „$g“. Es gehört zum '
              'Thema $thema. Lies die englischen Wörter: Was andere Wörter '
              'bedeuten, kannst du ausschließen.';
        } else {
          final n = g.replaceAll(' ', '').length;
          text = 'Schau dir das Wort genau an: „$g“ hat $n Buchstaben und '
              'gehört zum Thema $thema. Hast du es schon in einem Lied, Buch '
              'oder Spiel gelesen?';
        }
        return _plan(a, stufe, methode, 'Das Wort genau anschauen', text,
            FachMaterial(FachMaterialArt.wort, wort: g));
      case NachhilfeStufe.andereErklaerung:
        if (a.istSatz) {
          return _plan(
              a,
              stufe,
              methode,
              'Anders erklärt: die Situation',
              'Stell dir die Situation vor: Wo würde jemand das sagen – in der '
                  'Schule, beim Essen oder beim Spielen? Welche Antwort passt '
                  'zu dieser Situation?',
              FachMaterial(FachMaterialArt.szene,
                  sprechblase: deEn ? null : g));
        }
        if (deEn) {
          final karte = FachBildkarte.fuer(g);
          return _plan(
              a,
              stufe,
              methode,
              'Anders erklärt: mit einem Bild',
              karte.hatBild
                  ? 'Das Bild zeigt „$g“. Lies jedes englische Wort langsam. '
                      'Welches passt zu diesem Bild?'
                  : 'Stell dir „$g“ als Bild vor. Lies jedes englische Wort '
                      'langsam. Welches passt zu deinem Bild?',
              FachMaterial(FachMaterialArt.bildkarten, karten: [karte]));
        }
        final raetsel = _raetsel[a.antwort];
        final mitRaetsel = raetsel != null && !verraet(raetsel, a);
        return _plan(
            a,
            stufe,
            methode,
            'Anders erklärt: mit Bildern',
            mitRaetsel
                ? 'Hier sind alle Antworten als Bilder. Ein Rätsel zu „$g“: '
                    '$raetsel Welches Bild passt?'
                : 'Hier sind alle Antworten als Bilder. Denk an das Thema '
                    '$thema: Welches Bild könnte „$g“ sein?',
            FachMaterial(FachMaterialArt.bildkarten,
                karten: [for (final c in a.auswahl) FachBildkarte.fuer(c)]));
      case NachhilfeStufe.vorzeigen:
        if (beispiel == null) {
          return _plan(
              a,
              stufe,
              methode,
              'Lumo zeigt, wie man vorgeht',
              'So gehe ich vor: Ich lese das Englische langsam. Ich suche ein '
                  'Wort, das ich kenne. Ich stelle mir ein Bild dazu vor. Dann '
                  'prüfe ich jede Antwort, ob sie zu meinem Bild passt.',
              FachMaterial(FachMaterialArt.szene,
                  sprechblase: deEn ? null : g));
        }
        final bg = beispiel.gefragt ?? '';
        final englisch = deEn ? beispiel.antwort : bg;
        final deutsch = deEn ? bg : beispiel.antwort;
        final bild = FachBildkarte.fuer(deutsch);
        final text = beispiel.istSatz
            ? 'Schau, wie ich es bei einem neuen Beispiel mache: Jemand sagt '
                '„$englisch“. Ich kenne die Wörter und denke an die Situation. '
                'Das heißt: $deutsch Jetzt du bei deiner Aufgabe.'
            : 'Schau, wie ich es bei einem neuen Beispiel mache: Lumo sieht '
                '${bild.bild ?? 'ein Bild'} und sagt „$englisch“. „$englisch“ '
                'heißt $deutsch. So merke ich es mir: Bild anschauen, Wort '
                'lesen, Bedeutung sagen. Jetzt du bei deiner Aufgabe.';
        return _plan(
            a,
            stufe,
            methode,
            'Lumo zeigt es an einem anderen Beispiel',
            text,
            FachMaterial(FachMaterialArt.szene,
                szeneBild: bild, sprechblase: englisch),
            an: beispiel,
            sprech: beispiel.istSatz
                ? 'Schau, wie ich es bei einem neuen Beispiel mache. Ich kenne '
                    'die Wörter und denke an die Situation. Das heißt: '
                    '$deutsch Jetzt du bei deiner Aufgabe.'
                : 'Schau, wie ich es bei einem neuen Beispiel mache. Das '
                    'englische Wort neben dem Bild heißt $deutsch. So merke '
                    'ich es mir: Bild anschauen, Wort lesen, Bedeutung sagen. '
                    'Jetzt du bei deiner Aufgabe.');
      case NachhilfeStufe.teilschritt:
      case NachhilfeStufe.ueben:
        throw StateError('Wird in plan() behandelt');
    }
  }

  // ---- Lesen ------------------------------------------------------------

  static const _lautgruppen = [
    'sch', 'ch', 'ck', 'tz', 'pf', 'qu', 'ei', 'ie', 'eu', 'äu', 'au', 'st',
    'sp', 'ng', 'nk', 'ß',
  ];

  static String? _fragewort(String frage) {
    final w = frage.trim().split(RegExp(r'\s+')).firstOrNull ?? '';
    return switch (w.toLowerCase()) {
      'wer' || 'wem' || 'wen' => 'Wer',
      'was' => 'Was',
      'wo' => 'Wo',
      'wohin' => 'Wohin',
      'woher' => 'Woher',
      'wann' => 'Wann',
      'warum' || 'wieso' || 'weshalb' => 'Warum',
      'wie' => 'Wie',
      'welche' || 'welcher' || 'welches' || 'welchen' => 'Welche',
      _ => null,
    };
  }

  static String _fragewortTipp(String? wort) => switch (wort) {
        'Wer' => 'Such im Text nach einer Person oder einem Tier.',
        'Was' => 'Such im Text, was jemand tut, hat oder sieht.',
        'Wo' => 'Such im Text nach einem Ort.',
        'Wohin' => 'Such im Text, wohin jemand geht oder fährt.',
        'Woher' => 'Such im Text, woher etwas kommt.',
        'Wann' => 'Such im Text nach einer Zeit.',
        'Warum' => 'Such im Text nach einem Grund. Oft stehen dort Wörter wie '
            '„weil“, „deshalb“ oder „damit“.',
        'Wie' => 'Such im Text, wie etwas ist oder wie etwas gemacht wird.',
        _ => 'Lies die Frage zweimal. Was genau will sie wissen?',
      };

  FachPlan _lesen(FachAufgabe a, NachhilfeStufe stufe, String methode) {
    final fw = _fragewort(a.frage);
    switch (stufe) {
      case NachhilfeStufe.hinweis:
        final String text;
        if (a.istBildWort) {
          text = 'Sag leise, was du auf dem Bild siehst. Hör auf den ersten '
              'Laut. Lies dann jedes Wort genau – welches beginnt mit diesem '
              'Laut?';
        } else if (a.istWortWahl) {
          text = 'Lies die Beschreibung Wort für Wort. Was ist gemeint? Lies '
              'dann jedes Antwortwort ganz genau – sie sehen sich ähnlich!';
        } else if (a.istReihenfolge) {
          text = 'Überlege: Was muss zuerst passieren, damit das andere '
              'möglich ist? Lies jeden Satz und stell dir ihn wie ein Bild vor.';
        } else {
          text = 'Die Frage beginnt mit „${fw ?? a.frage.split(' ').first}“. '
              '${_fragewortTipp(fw)}';
        }
        return _plan(a, stufe, methode, 'Die Frage genau lesen', text,
            FachMaterial(FachMaterialArt.markierung,
                saetze: [a.frage],
                markiert: [if (fw != null) a.frage.split(' ').first],
                bild: a.bildZeichen));
      case NachhilfeStufe.andereErklaerung:
        final woerter = a.istBildWort || a.istWortWahl
            ? a.auswahl
            : [
                for (final w in a.lesetext.split(RegExp(r'[\s.,!?:;]+')))
                  if (w.length >= 3) w,
              ];
        final mitLaut = <String>[];
        final laute = <String>{};
        for (final w in woerter) {
          final klein = w.toLowerCase();
          for (final l in _lautgruppen) {
            if (klein.contains(l)) {
              if (!mitLaut.contains(w)) mitLaut.add(w);
              laute.add(l);
            }
          }
        }
        final beispiele = [
          for (final w in mitLaut)
            if (a.istBildWort || a.istWortWahl || !verraet(w, a)) w,
        ].take(3).toList();
        final String text;
        if (a.istBildWort || a.istWortWahl) {
          text = 'Diese Wörter sehen sich ähnlich. Lies jedes Wort Laut für '
              'Laut und achte auf den Anfang und das Ende. '
              '${laute.isEmpty ? '' : 'Diese Buchstaben gehören zusammen: ${laute.take(3).map((l) => '„$l“').join(', ')}.'}';
        } else if (beispiele.isEmpty) {
          text = 'Lies langsam und sprich jeden Laut deutlich. Lange Wörter '
              'liest du in Silben: Klatsch bei jeder Silbe.';
        } else {
          text = 'Manche Buchstaben gehören zusammen und ergeben einen Laut: '
              '${laute.take(3).map((l) => '„$l“').join(', ')}. Lies diese '
              'Wörter ganz langsam: ${beispiele.map((w) => '„$w“').join(', ')}.';
        }
        return _plan(a, stufe, methode, 'Anders erklärt: schwierige Laute',
            text.trim(),
            FachMaterial(FachMaterialArt.laute,
                saetze: a.istBildWort || a.istWortWahl
                    ? a.auswahl
                    : a.saetze,
                markiert: laute.toList(),
                bild: a.bildZeichen));
      case NachhilfeStufe.vorzeigen:
        final zuLesen = a.istBildWort ? a.auswahl : a.saetze;
        final text = a.istBildWort
            ? 'Hör gut zu: Ich lese dir alle Wörter langsam vor. Schau dabei '
                'auf das Bild.'
            : 'Hör gut zu: Ich lese dir den Text ganz langsam vor. Lies leise '
                'mit – jeder Satz leuchtet auf.';
        return _plan(a, stufe, methode, 'Lumo liest langsam vor', text,
            FachMaterial(FachMaterialArt.vorlesen,
                saetze: zuLesen, bild: a.bildZeichen),
            langsam: true,
            // Vorgelesen wird nur der Lesetext (oder die Wörter), nie, welche
            // Antwort richtig ist.
            sprech: '$text ${zuLesen.join(a.istBildWort ? ', ' : ' ')}');
      case NachhilfeStufe.teilschritt:
      case NachhilfeStufe.ueben:
        throw StateError('Wird in plan() behandelt');
    }
  }

  /// „Gemeinsam“ im Lesen: den Satz finden, der hilft. Bei der Reihenfolge:
  /// den ersten (oder letzten) Satz suchen – nie den gefragten selbst.
  FachPlan? _satzWahl(FachAufgabe a) {
    final s = a.saetze;
    if (s.length < 2) return null;
    String norm(String x) => FachNachhilfe._woerter(x).join(' ');
    if (a.istReihenfolge) {
      final reihe = a.erklaerung
          .replaceFirst(RegExp(r'^Richtige Reihenfolge:\s*'), '')
          .split('→')
          .map((x) => x.trim())
          .where((x) => x.isNotEmpty)
          .toList();
      if (reihe.length != s.length) return null;
      final zuerstGefragt = a.frage.contains('zuerst');
      final ziel = zuerstGefragt ? reihe.last : reihe.first;
      final index = s.indexWhere((x) => norm(x) == norm(ziel));
      if (index < 0 || norm(ziel) == norm(a.antwort)) return null;
      return _plan(
          a,
          NachhilfeStufe.teilschritt,
          'satz',
          'Gemeinsam: Satz finden',
          zuerstGefragt
              ? 'Wir machen es gemeinsam: Tippe auf den Satz, der ganz am Ende '
                  'passiert. Dann findest du in deiner Aufgabe den Anfang.'
              : 'Wir machen es gemeinsam: Tippe auf den Satz, der ganz am '
                  'Anfang passiert. Dann ordnest du in deiner Aufgabe weiter.',
          FachMaterial(FachMaterialArt.satzWahl,
              saetze: s, richtigerSatz: index));
    }
    final antwort = norm(a.antwort);
    if (antwort.isEmpty) return null;
    final treffer = [
      for (var i = 0; i < s.length; i++)
        if (' ${norm(s[i])} '.contains(' $antwort ')) i,
    ];
    if (treffer.length != 1) return null;
    return _plan(
        a,
        NachhilfeStufe.teilschritt,
        'satz',
        'Gemeinsam: Satz finden',
        'Wir machen es gemeinsam: Tippe auf den Satz, der dir bei der Frage '
            'hilft. Die Antwort suchst du dann selbst in deiner Aufgabe.',
        FachMaterial(FachMaterialArt.satzWahl,
            saetze: s, richtigerSatz: treffer.single));
  }

  // ---- Sachunterricht ---------------------------------------------------

  /// Bedeutungstragende Wörter der Frage (Namenwörter, keine Fragewörter).
  List<String> schluesselwoerter(FachAufgabe a) {
    final woerter = a.frage
        .split(RegExp(r'[\s,.?!:;„“()]+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final ergebnis = <String>[];
    for (var i = 0; i < woerter.length; i++) {
      final w = woerter[i];
      final gross = RegExp(r'^[A-ZÄÖÜ]').hasMatch(w);
      if (!gross || i == 0 || w.length < 3) continue;
      if (_stopp.contains(w.toLowerCase())) continue;
      if (!ergebnis.contains(w)) ergebnis.add(w);
    }
    return ergebnis.take(3).toList();
  }

  FachPlan _sachunterricht(
      FachAufgabe a, NachhilfeStufe stufe, String methode) {
    final schaubildId = _schaubildFuer(a.thema);
    switch (stufe) {
      case NachhilfeStufe.hinweis:
        final k = [
          for (final w in schluesselwoerter(a))
            if (!verraet(w, a)) w,
        ];
        final text = k.isEmpty
            ? 'Lies die Frage langsam. Das Thema ist „${a.themaText}“. Was '
                'weißt du schon darüber?'
            : 'Wichtig in der Frage: ${k.map((w) => '„$w“').join(' und ')}. '
                'Das Thema ist „${a.themaText}“. Was weißt du schon darüber? '
                'Streiche im Kopf Antworten, die gar nicht dazu passen.';
        return _plan(a, stufe, methode, 'Auf das wichtige Wort achten', text,
            FachMaterial(FachMaterialArt.markierung,
                saetze: [a.frage], markiert: k));
      case NachhilfeStufe.andereErklaerung:
        final beispiele = _alltag[schaubildId] ?? const <String>[];
        final passend =
            beispiele.where((b) => !verraet(b, a)).firstOrNull;
        return _plan(
            a,
            stufe,
            methode,
            'Anders erklärt: ein Beispiel aus dem Alltag',
            passend ??
                'Denk an deinen Alltag: Wo hast du so etwas schon erlebt – zu '
                    'Hause, in der Schule oder draußen? Erzähl es dir selbst in '
                    'einem Satz. Welche Antwort passt dazu?',
            const FachMaterial(FachMaterialArt.alltag));
      case NachhilfeStufe.vorzeigen:
        final vorlage = _schaubilder[schaubildId];
        if (vorlage == null) {
          // Denk-Karte: die wichtigen Wörter in der Mitte, die Antworten
          // ringsum – ohne eine davon hervorzuheben.
          final k = schluesselwoerter(a).where((w) => !verraet(w, a));
          return _plan(
              a,
              stufe,
              methode,
              'Lumo zeigt eine Denk-Karte',
              'Schau dir die Denk-Karte an: In der Mitte steht, worum es geht. '
                  'Ringsum stehen die Antworten. Ich prüfe jede: Passt sie zur '
                  'Mitte? Mach es mir nach.',
              FachMaterial(FachMaterialArt.schaubild,
                  schaubild: FachSchaubild(
                      k.isEmpty ? a.themaText : k.join(' · '),
                      [
                        for (final c in a.auswahl)
                          FachSchaubildKnoten('❔', c, ''),
                      ])));
        }
        final knoten = [
          for (final n in vorlage.knoten)
            FachSchaubildKnoten(n.bild, n.titel,
                verraet(n.text, a) ? '?' : n.text,
                verdeckt: verraet(n.text, a) || verraet(n.titel, a)),
        ];
        return _plan(
            a,
            stufe,
            methode,
            'Lumo zeigt ein Schaubild',
            'Schau dir das Schaubild „${vorlage.titel}“ an. Ich zeige dir '
                'Schritt für Schritt, wie alles zusammenhängt. Bei „?“ denkst '
                'du selbst nach: Welche Stelle passt zu deiner Frage?',
            FachMaterial(FachMaterialArt.schaubild,
                schaubild: FachSchaubild(vorlage.titel, [
                  for (final n in knoten)
                    n.verdeckt
                        ? FachSchaubildKnoten(n.bild,
                            verraet(n.titel, a) ? '?' : n.titel, '?',
                            verdeckt: true)
                        : n,
                ], kreis: vorlage.kreis)));
      case NachhilfeStufe.teilschritt:
      case NachhilfeStufe.ueben:
        throw StateError('Wird in plan() behandelt');
    }
  }

  // ---- Prüfung ----------------------------------------------------------

  FachPlan _pruefen(FachAufgabe original, FachAufgabe? p) {
    if (p == null) {
      return _plan(
          original,
          NachhilfeStufe.ueben,
          'pruefen',
          'Selbst prüfen',
          'Für eine ähnliche Aufgabe habe ich gerade keine passende. Probier '
              'jetzt deine Aufgabe ganz allein.',
          const FachMaterial(FachMaterialArt.pruefen));
    }
    final text = switch (original.fach) {
      FachNachhilfeFach.lesen =>
        'Jetzt liest du ganz allein – ohne Vorlesen. Lies langsam und wähle '
            'dann die passende Antwort.',
      _ => 'Jetzt prüfen wir, ob du es verstanden hast: Löse diese ähnliche '
          'Aufgabe ganz allein.',
    };
    return FachPlan(
      original: original,
      aufgabe: p,
      stufe: NachhilfeStufe.ueben,
      methode: 'pruefen',
      titel: 'Selbst prüfen',
      text: text,
      sprechText: text,
      material: FachMaterial(FachMaterialArt.pruefen, auswahl: p.auswahl),
      abschluss: 'Super! Jetzt schaffst du auch deine Aufgabe.',
    );
  }

  /// Erklärweisen für „Hilf mir“ in der normalen Übung (als Text, ohne
  /// Prüfung): Stufen 1–3 dieses Fachs und das Ausschließen.
  List<HilfeVariante> hilfeVarianten(FachAufgabe a, {FachAufgabe? beispiel}) {
    final varianten = <HilfeVariante>[];
    for (final stufe in [
      NachhilfeStufe.hinweis,
      NachhilfeStufe.andereErklaerung,
      NachhilfeStufe.vorzeigen,
    ]) {
      final p = plan(a, stufe, beispiel: beispiel);
      var text = p.text;
      if (p.material.art == FachMaterialArt.vorlesen) {
        text = 'Lies den Text ganz langsam, Satz für Satz. Mach nach jedem '
            'Satz eine kleine Pause. Du kannst ihn dir auch mit „Tipp '
            'anhören“ vorlesen lassen.';
      } else if (p.material.art == FachMaterialArt.bildkarten &&
          a.richtung == EnglischRichtung.englischDeutsch &&
          !a.istSatz) {
        final raetsel = _raetsel[a.antwort];
        text = raetsel != null && !verraet(raetsel, a)
            ? 'Ein Rätsel zu „${a.gefragt}“: $raetsel Welche Antwort passt?'
            : 'Stell dir jede Antwort als Bild vor. Welches Bild könnte '
                '„${a.gefragt}“ sein? Denk an das Thema „${a.themaText}“.';
      } else if (p.material.art == FachMaterialArt.schaubild &&
          p.material.schaubild != null) {
        final sb = p.material.schaubild!;
        final kette = sb.knoten
            .where((k) => !k.verdeckt && k.text.isNotEmpty)
            .map((k) => '${k.titel}: ${k.text}')
            .take(4)
            .join(' → ');
        text = kette.isEmpty
            ? p.text
            : 'Denk an das Schaubild „${sb.titel}“: $kette. Welche Stelle '
                'passt zu deiner Frage?';
      }
      if (verraet(text, a) && !p.anBeispiel) continue;
      varianten.add(HilfeVariante(
          methode: p.methode,
          titel: p.titel.startsWith('Anders') || p.titel.startsWith('Lumo')
              ? p.titel
              : 'Anders erklärt: ${p.titel}',
          text: text));
    }
    varianten.add(HilfeVariante(
        methode: 'ausschliessen',
        titel: 'Anders erklärt: ausschließen',
        text: _sicher(
            'Streiche zuerst eine Antwort, die sicher nicht passt. Sag dir, '
                'warum. Dann die nächste. Was bleibt übrig?',
            a,
            'Streiche zuerst eine Antwort, die sicher nicht passt, und sag '
                'dir, warum. Prüfe dann die anderen noch einmal.')));
    return varianten;
  }
}
