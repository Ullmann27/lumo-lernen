/// Reihenfolge der Erklärweisen für „Hilf mir“ und „Anders erklären“ in den
/// normalen Übungen (nie in Tests und Schularbeiten – dort ist „Hilf mir“
/// gar nicht sichtbar).
///
/// Die ersten drei Hilfen sind die bisherigen Tippstufen des
/// [TaskHintService]. Danach wechselt Lumo die Erklärweise, statt denselben
/// Hinweis zu wiederholen: bei Rechnungen die Rechenwege der Nachhilfe
/// (z. B. Zehnerstangen → Zahlenstrahl), dann ein Alltagsbild, dann
/// „gemeinsam“. Englisch, Lesen und Sachunterricht nutzen die Wege ihrer
/// Fach-Nachhilfe. Kein Text verrät das Ergebnis der Aufgabe.
library;

import 'lumo_nachhilfe.dart';

/// Eine Erklärweise mit kindgerechtem Titel und Text.
class HilfeVariante {
  const HilfeVariante({
    required this.methode,
    required this.titel,
    required this.text,
  });

  /// Stabiler Schlüssel (wird mit der Antwort gespeichert), z. B. „tipp“,
  /// „zahlenstrahl“, „bild“.
  final String methode;

  /// Kurzer Titel für das Kind, z. B. „Anders erklärt: auf dem Zahlenstrahl“.
  final String titel;
  final String text;
}

abstract final class HilfeFolge {
  static const String tipp = 'tipp';
  static const String anders = 'anders';
  static const String genauer = 'genauer';
  static const String alltagsbild = 'alltagsbild';
  static const String gemeinsam = 'gemeinsam';

  static String _material(NachhilfeWeg weg) => switch (weg) {
        NachhilfeWeg.rechenrahmen => 'mit dem Rechenrahmen',
        NachhilfeWeg.zahlenstrahl => 'auf dem Zahlenstrahl',
        NachhilfeWeg.zerlegen => 'mit Zerlegen',
        NachhilfeWeg.verdoppeln => 'mit Verdoppeln',
        NachhilfeWeg.tauschen => 'mit Tauschen',
        NachhilfeWeg.stangen => 'mit Zehnerstangen',
        NachhilfeWeg.punktefeld => 'mit dem Punktefeld',
        NachhilfeWeg.kernaufgabe => 'mit einer Kernaufgabe',
      };

  static String titelFuerWeg(NachhilfeWeg weg) =>
      'Anders erklärt: ${_material(weg)}';

  /// Die drei bisherigen Tippstufen als eigene Erklärweisen.
  static List<HilfeVariante> stufen(String stufe1, String stufe2, String stufe3) =>
      [
        HilfeVariante(methode: tipp, titel: 'Kleiner Tipp', text: stufe1),
        HilfeVariante(methode: anders, titel: 'Anders gesagt', text: stufe2),
        HilfeVariante(
            methode: genauer, titel: 'Noch genauer', text: stufe3),
      ];

  /// Rechenwege der Nachhilfe als Text (nur Denkanstöße an der
  /// Originalaufgabe), dann das Alltagsbild der „anderen Erklärung“.
  static List<HilfeVariante> rechenwege(NachhilfeAufgabe aufgabe,
      {LumoNachhilfe tutor = const LumoNachhilfe()}) {
    final varianten = <HilfeVariante>[];
    for (final weg in tutor.wegeFuer(aufgabe)) {
      final plan = tutor.plan(aufgabe, weg, NachhilfeStufe.hinweis);
      // Lumos erster Handgriff am Material und der Denkanstoß dazu.
      final text = plan.weg == NachhilfeWeg.zahlenstrahl && aufgabe.typ.bis100
          ? _zahlenstrahl100(aufgabe)
          : plan.schritte.map((s) => s.text).join(' ').trim();
      if (text.isEmpty) continue;
      varianten.add(HilfeVariante(
          methode: plan.weg.name, titel: titelFuerWeg(plan.weg), text: text));
    }
    final alltag = tutor.plan(
        aufgabe, tutor.wegFuer(aufgabe), NachhilfeStufe.andereErklaerung);
    final alltagText = alltag.schritte.map((s) => s.text).join(' ').trim();
    if (alltagText.isNotEmpty) {
      varianten.add(HilfeVariante(
          methode: alltagsbild,
          titel: 'Anders erklärt: mit einem Alltagsbild',
          text: alltagText));
    }
    return varianten;
  }

  /// Zahlenstrahl im Zahlenraum 100: große Zehnersprünge, dann kleine
  /// Einersprünge. Gefragt wird nur ein Zwischenschritt, nie das Ergebnis.
  static String _zahlenstrahl100(NachhilfeAufgabe x) {
    final a = x.a, b = x.b, bz = b ~/ 10, be = b % 10;
    final vor = x.typ.istPlus;
    final richtung = vor ? 'nach vorne' : 'zurück';
    final start = 'Stell dir den Zahlenstrahl vor: Du stehst auf der $a.';
    if (bz == 0) {
      return '$start Spring zuerst bis zum ${vor ? 'nächsten' : 'vorigen'} '
          'Zehner und dann weiter $richtung. Wie viele Sprünge sind es bis '
          'zum Zehner?';
    }
    final zehner = bz == 1 ? 'einen großen Zehnersprung' : '$bz große Zehnersprünge';
    if (be == 0) {
      return '$start Die $b sind $zehner $richtung. Nur die Zehnerziffer '
          'ändert sich – zähl beim Springen in Zehnern mit.';
    }
    final einer = be == 1 ? 'einen kleinen Einersprung' : '$be kleine Einersprünge';
    return '$start Mach zuerst $zehner $richtung, danach $einer. Auf welcher '
        'Zahl landest du nach den Zehnersprüngen?';
  }

  /// Letzte Erklärweise: gemeinsam, Schritt für Schritt.
  static HilfeVariante gemeinsamSchritt({required bool nachhilfeVerfuegbar}) =>
      HilfeVariante(
        methode: gemeinsam,
        titel: 'Jetzt gemeinsam',
        text: nachhilfeVerfuegbar
            ? 'Jetzt machen wir es gemeinsam: Tippe auf „Schritt für Schritt '
                'mit Lumo“. Dort machst du jeden Schritt selbst, und ich warte '
                'auf dich.'
            : 'Jetzt machen wir es gemeinsam: Lies die Frage Wort für Wort '
                'mit mir. Streiche dann eine Antwort, die sicher nicht passt, '
                'und prüfe die übrigen noch einmal mit der Frage.',
      );

  /// Ganze Folge ohne doppelte Texte (gleicher Text = gleiche Hilfe).
  static List<HilfeVariante> folge({
    required List<HilfeVariante> stufen,
    List<HilfeVariante> wege = const [],
    required bool nachhilfeVerfuegbar,
  }) {
    final gesehen = <String>{};
    final methoden = <String>{};
    final liste = <HilfeVariante>[];
    String norm(String t) =>
        t.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    for (final v in [
      ...stufen,
      ...wege,
      gemeinsamSchritt(nachhilfeVerfuegbar: nachhilfeVerfuegbar),
    ]) {
      if (v.text.trim().isEmpty) continue;
      if (!gesehen.add(norm(v.text)) || !methoden.add(v.methode)) continue;
      liste.add(v);
    }
    return List.unmodifiable(liste);
  }
}
