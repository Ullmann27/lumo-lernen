/// Lumo erkennt Verständnis – aus der vorhandenen Lernintelligenz.
///
/// Nach einer Hilfestellung bietet Lumo eine vergleichbare, eigenständige
/// Aufgabe an (Zwillingsaufgabe in der Übung, Prüfaufgabe der Nachhilfe,
/// Zwilling der 3D-Nachhilfe). Sie wird im vorhandenen Aufgabenprotokoll
/// ([Attempt]) mit [Attempt.vergleichNachHilfe] und der Ausgangsaufgabe
/// ([Attempt.reference]) gespeichert. Nur wenn das Kind sie ohne Hilfe richtig
/// löst, zählt sie als neues Indiz für Verständnis.
///
/// Bei wenigen Daten wird nichts übertrieben: Eine gelöste Vergleichsaufgabe
/// ist ein erstes Anzeichen. „Später bestätigt“ heißt es erst, wenn mindestens
/// zwei Vergleichsaufgaben zu verschiedenen Ausgangsaufgaben allein gelöst
/// wurden und die letzte Vergleichsaufgabe ebenfalls allein gelang.
///
/// Außerdem: [HilfeMethodenwechsel] wählt bei wiederholten Schwierigkeiten
/// eine andere Erklärweise, statt denselben Hinweis zu wiederholen.
library;

import '../school/attempt.dart';

enum VerstaendnisStufe {
  /// Noch keine Vergleichsaufgabe nach einer Hilfe.
  keineDaten,

  /// Die letzte Vergleichsaufgabe nach Hilfe gelang noch nicht allein.
  nochUnsicher,

  /// Eine Vergleichsaufgabe nach Hilfe allein gelöst: ein erstes Anzeichen,
  /// noch keine sichere Aussage.
  erstesAnzeichen,

  /// Mindestens zwei Vergleichsaufgaben zu verschiedenen Ausgangsaufgaben
  /// allein gelöst, die letzte ebenfalls.
  spaeterBestaetigt,
}

/// Verständnis-Indiz einer Kompetenz aus den Vergleichsaufgaben nach Hilfe.
class VerstaendnisIndiz {
  const VerstaendnisIndiz._({
    required this.fach,
    required this.thema,
    required this.kompetenz,
    required this.vergleiche,
    required this.alleinRichtig,
    required this.ausgangsaufgaben,
    required this.stufe,
    required this.zuletzt,
    required this.bezuege,
  });

  /// So viele verschiedene Ausgangsaufgaben braucht „später bestätigt“.
  static const int mindestGelegenheiten = 2;

  final String fach;
  final String thema;
  final String kompetenz;

  /// Vergleichsaufgaben nach Hilfe (jede Aufgabe einmal gezählt).
  final int vergleiche;

  /// Davon ohne Hilfe richtig gelöst.
  final int alleinRichtig;

  /// Verschiedene Ausgangsaufgaben, nach deren Hilfe eine Vergleichsaufgabe
  /// allein gelang.
  final int ausgangsaufgaben;
  final VerstaendnisStufe stufe;
  final DateTime? zuletzt;

  /// Nachvollziehbar: „Ausgangsaufgabe → Vergleichsaufgabe“, neueste zuerst
  /// (höchstens drei).
  final List<(String, String)> bezuege;

  bool get hatIndiz =>
      stufe == VerstaendnisStufe.erstesAnzeichen ||
      stufe == VerstaendnisStufe.spaeterBestaetigt;

  bool get spaeterBestaetigt => stufe == VerstaendnisStufe.spaeterBestaetigt;

  /// Ruhiger Satz für Eltern und Lehrkräfte, ohne Übertreibung.
  String get elternSatz => switch (stufe) {
        VerstaendnisStufe.keineDaten =>
          'Noch keine ähnliche Aufgabe nach einer Hilfe.',
        VerstaendnisStufe.nochUnsicher => alleinRichtig == 0
            ? 'Die ähnliche Aufgabe nach der Hilfe ging noch nicht allein – '
                'weiter gemeinsam üben.'
            : 'Zuletzt ging die ähnliche Aufgabe nach der Hilfe noch nicht '
                'allein ($alleinRichtig von $vergleiche allein gelöst).',
        VerstaendnisStufe.erstesAnzeichen => alleinRichtig == 1
            ? 'Nach einer Hilfe 1 ähnliche Aufgabe allein gelöst – ein erstes '
                'Anzeichen, noch keine sichere Aussage.'
            : 'Nach Hilfe $alleinRichtig ähnliche Aufgaben allein gelöst, aber '
                'bisher nur zu einer Aufgabe – ein erstes Anzeichen.',
        VerstaendnisStufe.spaeterBestaetigt =>
          'Später bestätigt: Nach Hilfe $alleinRichtig von $vergleiche '
              'ähnlichen Aufgaben allein gelöst (zu $ausgangsaufgaben '
              'verschiedenen Aufgaben).',
      };

  /// Wertet nur Vergleichsaufgaben nach Hilfe derselben [kompetenz] (und, wenn
  /// angegeben, desselben [fach]s) aus. Dieselbe Vergleichsaufgabe zur selben
  /// Ausgangsaufgabe zählt nur einmal (erste Antwort entscheidet).
  static VerstaendnisIndiz aus(
    Iterable<Attempt> alle, {
    required String kompetenz,
    String? fach,
  }) {
    final liste = alle
        .where((a) =>
            a.check == Attempt.vergleichNachHilfe &&
            a.competency == kompetenz &&
            (fach == null || a.subject == fach))
        .toList()
      ..sort((x, y) {
        final t = x.at.compareTo(y.at);
        return t != 0 ? t : x.id.compareTo(y.id);
      });
    final gesehen = <String>{};
    final eindeutig = <Attempt>[];
    for (final a in liste) {
      if (gesehen.add('${a.reference}|${a.prompt}')) eindeutig.add(a);
    }
    final allein = eindeutig.where((a) => a.confirmsAfterHelp).toList();
    final ausgang = {
      for (final a in allein)
        a.reference.trim().isEmpty ? 'ohne:${a.id}' : a.reference.trim(),
    };
    final VerstaendnisStufe stufe;
    if (eindeutig.isEmpty) {
      stufe = VerstaendnisStufe.keineDaten;
    } else if (!eindeutig.last.confirmsAfterHelp) {
      stufe = VerstaendnisStufe.nochUnsicher;
    } else if (allein.length >= 2 && ausgang.length >= mindestGelegenheiten) {
      stufe = VerstaendnisStufe.spaeterBestaetigt;
    } else {
      stufe = VerstaendnisStufe.erstesAnzeichen;
    }
    return VerstaendnisIndiz._(
      fach: eindeutig.isEmpty ? (fach ?? '') : eindeutig.last.subject,
      thema: eindeutig.isEmpty ? '' : eindeutig.last.unit,
      kompetenz: kompetenz,
      vergleiche: eindeutig.length,
      alleinRichtig: allein.length,
      ausgangsaufgaben: ausgang.length,
      stufe: stufe,
      zuletzt: eindeutig.isEmpty ? null : eindeutig.last.at,
      bezuege: List.unmodifiable([
        for (final a in eindeutig.reversed.take(3)) (a.reference, a.prompt),
      ]),
    );
  }

  /// Alle Kompetenzen mit mindestens einer Vergleichsaufgabe nach Hilfe,
  /// bestätigte zuerst, dann nach letzter Aktivität.
  static List<VerstaendnisIndiz> alle(Iterable<Attempt> attempts) {
    final gruppen = <(String, String)>{
      for (final a in attempts)
        if (a.check == Attempt.vergleichNachHilfe) (a.subject, a.competency),
    };
    final liste = [
      for (final (fach, kompetenz) in gruppen)
        aus(attempts, kompetenz: kompetenz, fach: fach),
    ]..sort((a, b) {
        final s = b.stufe.index.compareTo(a.stufe.index);
        if (s != 0) return s;
        final t = (b.zuletzt ?? DateTime(0)).compareTo(a.zuletzt ?? DateTime(0));
        return t != 0 ? t : a.kompetenz.compareTo(b.kompetenz);
      });
    return List.unmodifiable(liste);
  }

  /// Erklärweisen ([Attempt.method]), nach denen eine Antwort mit Hilfe
  /// trotzdem falsch war – Lumo beginnt beim nächsten Mal mit einer anderen.
  static Set<String> wenigHilfreicheMethoden(
    Iterable<Attempt> alle, {
    required String kompetenz,
    String? fach,
  }) {
    final liste = alle
        .where((a) =>
            a.competency == kompetenz &&
            (fach == null || a.subject == fach) &&
            a.method != null)
        .toList()
      ..sort((x, y) => x.at.compareTo(y.at));
    final ergebnis = <String>{};
    for (final a in liste) {
      if (!a.correct) {
        ergebnis.add(a.method!);
      } else if (!a.hintUsed || a.check == Attempt.vergleichNachHilfe) {
        // Danach allein geschafft: diese Methode hat geholfen.
        ergebnis.remove(a.method);
      }
    }
    return ergebnis;
  }
}

/// Wechselt die Erklärweise, statt denselben Hinweis zu wiederholen.
abstract final class HilfeMethodenwechsel {
  /// Erste Methode aus [folge], die noch nicht [gezeigt] wurde. Sind alle
  /// gezeigt, kommt die auf [zuletzt] folgende – nie zweimal hintereinander
  /// dieselbe, solange es mehr als eine gibt.
  static T? naechste<T>(List<T> folge,
      {Iterable<T> gezeigt = const [], T? zuletzt}) {
    if (folge.isEmpty) return null;
    final schon = gezeigt.toSet();
    for (final m in folge) {
      if (!schon.contains(m) && m != zuletzt) return m;
    }
    final i = zuletzt == null ? -1 : folge.indexOf(zuletzt);
    return folge[(i + 1) % folge.length];
  }

  /// Ordnet [folge] so, dass [wenigHilfreich] (schon ohne Erfolg gezeigte
  /// Methoden) ans Ende rücken; die übrige Reihenfolge bleibt.
  static List<T> zuerstNeue<T>(List<T> folge, Set<T> wenigHilfreich) => [
        for (final m in folge)
          if (!wenigHilfreich.contains(m)) m,
        for (final m in folge)
          if (wenigHilfreich.contains(m)) m,
      ];
}
