/// Lernstand für die Nachhilfe aus den vorhandenen Antwortdaten ([Attempt]).
///
/// Unterscheidet, was die Daten wirklich zeigen: selbstständig richtig,
/// richtig mit Hilfe, falsch, ein möglicherweise wiederkehrendes
/// Fehlermuster, fehlende Daten, später bestätigtes Verständnis und
/// Wiederholungsbedarf. Bei wenigen Antworten wird nichts behauptet.
///
/// Die Bearbeitungszeit ([Attempt.durationMs]) wird bewusst nicht gelesen:
/// Geschwindigkeit entscheidet nicht über Verständnis.
library;

import '../school/attempt.dart';
import '../school/error_patterns.dart';
import 'lumo_nachhilfe.dart';

enum NachhilfeBefund {
  /// Zu wenige Antworten zu dieser Kompetenz: keine Aussage.
  fehlendeDaten,

  /// Mindestens eine Antwort ohne Hilfe richtig.
  selbststaendigRichtig,

  /// Mindestens eine Antwort mit Hilfe richtig (zählt nicht als Verständnis).
  richtigMitHilfe,

  /// Mindestens eine falsche Antwort.
  falsch,

  /// Dasselbe Fehlermuster mindestens zweimal – ein möglicher Hinweis, keine
  /// Diagnose.
  moeglichesFehlermuster,

  /// Nach Hilfe oder Fehlern später mindestens zweimal ohne Hilfe richtig.
  spaeterBestaetigt,

  /// Von den letzten drei Antworten ohne Hilfe mindestens zwei falsch.
  wiederholungNoetig,
}

/// Einordnung einer einzelnen Antwort.
NachhilfeBefund einordnen(Attempt antwort) => !antwort.correct
    ? NachhilfeBefund.falsch
    : antwort.hintUsed
        ? NachhilfeBefund.richtigMitHilfe
        : NachhilfeBefund.selbststaendigRichtig;

class NachhilfeLernstand {
  const NachhilfeLernstand._({
    required this.kompetenz,
    required this.antworten,
    required this.selbststaendigRichtig,
    required this.richtigMitHilfe,
    required this.falsch,
    required this.muster,
    required this.befunde,
  });

  /// Erst ab so vielen Antworten werden Muster, Bestätigung oder
  /// Wiederholungsbedarf genannt.
  static const int mindestAntworten = 3;

  final String kompetenz;
  final int antworten;
  final int selbststaendigRichtig;
  final int richtigMitHilfe;
  final int falsch;

  /// Mindestens zweimal aufgetretene Fehlermuster, häufigstes zuerst.
  final List<(String, int)> muster;
  final Set<NachhilfeBefund> befunde;

  bool get aussagekraeftig => !befunde.contains(NachhilfeBefund.fehlendeDaten);

  /// Eine belegte, wiederkehrende Schwierigkeit: Lumo zeigt dann gleich vor.
  bool get wiederholteSchwaeche =>
      befunde.contains(NachhilfeBefund.moeglichesFehlermuster) ||
      befunde.contains(NachhilfeBefund.wiederholungNoetig);

  /// Häufigstes Muster in der Sprache der Nachhilfe (für die Wegwahl).
  NachhilfeFehlermuster get haeufigstesMuster {
    if (muster.isEmpty) return NachhilfeFehlermuster.keines;
    return switch (muster.first.$1) {
      'Zehner beim Übergang vergessen' ||
      'Zehner beim Übergang nicht abgezogen' =>
        NachhilfeFehlermuster.zehnerVergessen,
      'kleinere Einerziffer von der größeren abgezogen' =>
        NachhilfeFehlermuster.einerUmgedreht,
      'Minus statt Plus gerechnet' ||
      'Plus statt Minus gerechnet' =>
        NachhilfeFehlermuster.rechenzeichen,
      'Ziffern vertauscht' => NachhilfeFehlermuster.zifferndreher,
      'um eins verzählt' => NachhilfeFehlermuster.einsDaneben,
      'Plus statt Mal gerechnet' => NachhilfeFehlermuster.plusStattMal,
      'in der Malreihe um einen Schritt verrutscht' =>
        NachhilfeFehlermuster.reiheVerrutscht,
      _ => NachhilfeFehlermuster.keines,
    };
  }

  /// Ein ruhiger Satz für das Kind – nur bei belastbaren Daten, ohne
  /// Prozentzahlen und ohne Fehler aufzuzählen.
  String? get kindSatz {
    if (!aussagekraeftig) return null;
    if (befunde.contains(NachhilfeBefund.spaeterBestaetigt)) {
      return 'Solche Aufgaben hast du schon mehrmals allein geschafft. Ein kleiner Tipp reicht bestimmt.';
    }
    if (befunde.contains(NachhilfeBefund.wiederholungNoetig)) {
      return 'Diese Aufgaben üben wir heute noch einmal in Ruhe zusammen.';
    }
    if (befunde.contains(NachhilfeBefund.moeglichesFehlermuster)) {
      return 'Ich zeige dir gleich einen Weg, der bei solchen Aufgaben gut hilft.';
    }
    return null;
  }

  /// Startstufe auf der Hilfeleiter aus Versuchen und Lernstand.
  NachhilfeStufe startStufe(LumoNachhilfe tutor, {required int versuche}) =>
      befunde.contains(NachhilfeBefund.spaeterBestaetigt) && versuche < 3
          ? NachhilfeStufe.hinweis
          : tutor.startStufe(
              versuche: versuche, wiederholteSchwaeche: wiederholteSchwaeche);

  /// Wertet nur Antworten derselben [kompetenz] (und, falls angegeben,
  /// desselben [fach]s) aus, in zeitlicher Reihenfolge.
  static NachhilfeLernstand aus(
    Iterable<Attempt> alle, {
    required String kompetenz,
    String? fach,
    ErrorPatternDetector detector = const ErrorPatternDetector(),
  }) {
    final liste = alle
        .where((a) =>
            a.competency == kompetenz && (fach == null || a.subject == fach))
        .toList()
      ..sort((x, y) => x.at.compareTo(y.at));
    var selbst = 0, mitHilfe = 0, falsch = 0;
    for (final a in liste) {
      switch (einordnen(a)) {
        case NachhilfeBefund.selbststaendigRichtig:
          selbst++;
        case NachhilfeBefund.richtigMitHilfe:
          mitHilfe++;
        default:
          falsch++;
      }
    }
    final befunde = <NachhilfeBefund>{};
    var muster = const <(String, int)>[];
    if (liste.length < mindestAntworten) {
      befunde.add(NachhilfeBefund.fehlendeDaten);
    } else {
      if (selbst > 0) befunde.add(NachhilfeBefund.selbststaendigRichtig);
      if (mitHilfe > 0) befunde.add(NachhilfeBefund.richtigMitHilfe);
      if (falsch > 0) befunde.add(NachhilfeBefund.falsch);
      final zaehler = <String, int>{};
      for (final a in liste) {
        final m = detector.detect(a);
        if (m != null) zaehler[m] = (zaehler[m] ?? 0) + 1;
      }
      muster = [
        for (final e in zaehler.entries)
          if (e.value >= 2) (e.key, e.value)
      ]..sort((x, y) => y.$2.compareTo(x.$2));
      if (muster.isNotEmpty) {
        befunde.add(NachhilfeBefund.moeglichesFehlermuster);
      }
      // Später bestätigt: nach der letzten Hilfe oder dem letzten Fehler noch
      // mindestens zweimal ohne Hilfe richtig.
      final letzteHilfe = liste.lastIndexWhere((a) => a.hintUsed || !a.correct);
      if (letzteHilfe >= 0) {
        final danach = liste
            .skip(letzteHilfe + 1)
            .where((a) => a.correct && !a.hintUsed)
            .length;
        if (danach >= 2) befunde.add(NachhilfeBefund.spaeterBestaetigt);
      }
      final ohneHilfe = liste.where((a) => !a.hintUsed).toList();
      if (ohneHilfe.length >= 3) {
        final letzte = ohneHilfe.sublist(ohneHilfe.length - 3);
        if (letzte.where((a) => !a.correct).length >= 2) {
          befunde.add(NachhilfeBefund.wiederholungNoetig);
        }
      }
    }
    return NachhilfeLernstand._(
      kompetenz: kompetenz,
      antworten: liste.length,
      selbststaendigRichtig: selbst,
      richtigMitHilfe: mitHilfe,
      falsch: falsch,
      muster: List.unmodifiable(muster),
      befunde: Set.unmodifiable(befunde),
    );
  }
}
