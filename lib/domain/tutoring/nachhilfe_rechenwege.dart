part of 'lumo_nachhilfe.dart';

// Rechenwege der Nachhilfe für Minus bis 20, Kopfrechnen bis 100 und das
// kleine Einmaleins. Plus bis 20 behält seine bisherigen, von der 3D-Szene
// geprüften Pläne in lumo_nachhilfe.dart.
//
// Grundsätze (Auftrag Heinz, Abschnitt 5):
// - Jeder Satz bezieht sich auf die Zahlen der gestellten Aufgabe.
// - An der Originalaufgabe wird ihr Ergebnis nie genannt oder abgefragt.
// - Zwischenschritte tippt das Kind selbst ein; erst dann bewegt sich das
//   Material (Zehnerstangen, Zahlenstrahl, Punktefeld).
// - Kraft der Zehn: erst bis zum Zehner, dann weiter. Beim Einmaleins sind
//   1·, 2·, 5· und 10· die Anker; Nachbaraufgaben werden davon abgeleitet.

bool _istKern(int n) => n == 1 || n == 2 || n == 5 || n == 10;

String _stangenWort(int n) => n == 1 ? 'eine Zehnerstange' : '$n Zehnerstangen';

String _zehnerWort(int n) => switch (n) {
      1 => 'einen Zehner',
      2 => 'zwei Zehner',
      3 => 'drei Zehner',
      _ => '$n Zehner',
    };

String _stangenText(int zehner, int einer) {
  final teile = <String>[
    if (zehner > 0) _stangenWort(zehner),
    if (einer > 0) '$einer Einerwürfel',
  ];
  return teile.isEmpty ? 'nichts' : teile.join(' und ');
}

String _muenzenText(int zehner, int einer) {
  final teile = <String>[
    if (zehner > 0)
      zehner == 1 ? 'eine Zehn-Cent-Münze' : '$zehner Zehn-Cent-Münzen',
    if (einer > 0)
      einer == 1 ? 'eine Ein-Cent-Münze' : '$einer Ein-Cent-Münzen',
  ];
  return teile.join(' und ');
}

String _reihenWort(int n) => n == 1 ? '1 Reihe' : '$n Reihen';

String _punkteWort(int n) => n == 1 ? '1 Punkt' : '$n Punkten';

String _wuerfelWort(int n) => n == 1 ? '1 Würfel' : '$n Würfel';

/// „ist noch 1 übrig“ / „sind noch 3 übrig“.
String _nochUebrig(int n) => n == 1 ? 'ist noch 1 übrig' : 'sind noch $n übrig';

/// Zeichnet ein Punktefeld: [sichtbar] Reihen, davon [markiert] als
/// bekannter Teil, dazu [geister] gedachte Reihen.
typedef _Feld = NachhilfeAktion Function(
    int sichtbar, int markiert, int geister);

/// Bausteine der anderen Erklärung (Stufe 2).
class _Alltag {
  const _Alltag(this.text, this.bild, {this.frage, this.fragetext, this.hilfe});
  final String text;
  final NachhilfeAktion bild;
  final int? frage;
  final String? fragetext;
  final String? hilfe;
}

extension _NachhilfeRechenwege on LumoNachhilfe {
  List<NachhilfeWeg> _wegeNeu(NachhilfeAufgabe x) {
    final a = x.a, b = x.b;
    switch (x.typ) {
      case NachhilfeTyp.additionBis20:
        return wegeFuer(x);
      case NachhilfeTyp.subtraktionBis20:
        return [
          NachhilfeWeg.rechenrahmen,
          NachhilfeWeg.zahlenstrahl,
          if (x.zehnerUebergang) NachhilfeWeg.zerlegen,
        ];
      case NachhilfeTyp.additionBis100:
        return [
          if (a < 10 && b >= 10) NachhilfeWeg.tauschen,
          NachhilfeWeg.stangen,
          NachhilfeWeg.zahlenstrahl,
        ];
      case NachhilfeTyp.subtraktionBis100:
        return const [NachhilfeWeg.stangen, NachhilfeWeg.zahlenstrahl];
      case NachhilfeTyp.einmaleins:
        final drehen = a != b;
        final erstDrehen = drehen && !_istKern(a) && _istKern(b);
        return [
          if (erstDrehen) NachhilfeWeg.tauschen,
          NachhilfeWeg.kernaufgabe,
          if (a >= 3 && a <= 5) NachhilfeWeg.punktefeld,
          if (drehen && !erstDrehen) NachhilfeWeg.tauschen,
        ];
    }
  }

  NachhilfeFehlermuster _fehlerNeu(NachhilfeAufgabe x, int wert) {
    final a = x.a, b = x.b, e = x.ergebnis;
    bool dreher() {
      if (e < 10 || wert < 10) return false;
      final gedreht = int.tryParse('$e'.split('').reversed.join());
      return gedreht == wert && gedreht != e;
    }

    switch (x.typ) {
      case NachhilfeTyp.additionBis20:
        return NachhilfeFehlermuster.keines;
      case NachhilfeTyp.einmaleins:
        if (wert == a + b) return NachhilfeFehlermuster.plusStattMal;
        if ((b >= 2 && (wert == e + b || wert == e - b)) ||
            (a >= 2 && (wert == e + a || wert == e - a))) {
          return NachhilfeFehlermuster.reiheVerrutscht;
        }
        if (dreher()) return NachhilfeFehlermuster.zifferndreher;
        return NachhilfeFehlermuster.keines;
      case NachhilfeTyp.subtraktionBis20:
      case NachhilfeTyp.subtraktionBis100:
        if (wert == a + b) return NachhilfeFehlermuster.rechenzeichen;
        if (x.zehnerUebergang) {
          final umgedreht = (a ~/ 10 - b ~/ 10) * 10 + (b % 10 - a % 10);
          if (wert == umgedreht && umgedreht != e) {
            return NachhilfeFehlermuster.einerUmgedreht;
          }
          if (wert == e + 10) return NachhilfeFehlermuster.zehnerVergessen;
        }
        if (dreher()) return NachhilfeFehlermuster.zifferndreher;
        if ((wert - e).abs() == 1) return NachhilfeFehlermuster.einsDaneben;
        return NachhilfeFehlermuster.keines;
      case NachhilfeTyp.additionBis100:
        if (x.zehnerUebergang && wert == e - 10) {
          return NachhilfeFehlermuster.zehnerVergessen;
        }
        if (wert == (a - b).abs() && a != b) {
          return NachhilfeFehlermuster.rechenzeichen;
        }
        if (dreher()) return NachhilfeFehlermuster.zifferndreher;
        if ((wert - e).abs() == 1) return NachhilfeFehlermuster.einsDaneben;
        return NachhilfeFehlermuster.keines;
    }
  }

  NachhilfeWeg _wegFuerFehler(NachhilfeAufgabe x, NachhilfeFehlermuster fehler,
      List<NachhilfeWeg> wege) {
    final material =
        x.typ.bis100 ? NachhilfeWeg.stangen : NachhilfeWeg.rechenrahmen;
    final wunsch = switch (fehler) {
      NachhilfeFehlermuster.einsDaneben => NachhilfeWeg.zahlenstrahl,
      NachhilfeFehlermuster.rechenzeichen => material,
      NachhilfeFehlermuster.zehnerVergessen ||
      NachhilfeFehlermuster.einerUmgedreht ||
      NachhilfeFehlermuster.zifferndreher =>
        !x.typ.bis100 && x.zehnerUebergang ? NachhilfeWeg.zerlegen : material,
      NachhilfeFehlermuster.plusStattMal ||
      NachhilfeFehlermuster.reiheVerrutscht =>
        wege.contains(NachhilfeWeg.punktefeld)
            ? NachhilfeWeg.punktefeld
            : NachhilfeWeg.kernaufgabe,
      NachhilfeFehlermuster.keines => wege.first,
    };
    return wege.contains(wunsch) ? wunsch : wege.first;
  }

  // ---------------------------------------------------------------------
  // Zwillingsaufgaben: gleicher Aufbau, gleiche Wege, anderes Ergebnis.

  NachhilfeAufgabe? _gleicherTyp(NachhilfeAufgabe x, int a, int b) =>
      switch (x.typ) {
        NachhilfeTyp.additionBis20 => NachhilfeAufgabe.addition(a, b),
        NachhilfeTyp.subtraktionBis20 => NachhilfeAufgabe.subtraktion(a, b),
        NachhilfeTyp.additionBis100 => NachhilfeAufgabe.additionBis100(a, b),
        NachhilfeTyp.subtraktionBis100 =>
          NachhilfeAufgabe.subtraktionBis100(a, b),
        NachhilfeTyp.einmaleins => NachhilfeAufgabe.mal(a, b),
      };

  /// Merkmale, die den Ablauf der Schritte bestimmen.
  String _signatur(NachhilfeAufgabe x) {
    final a = x.a, b = x.b;
    final az = a ~/ 10, ae = a % 10, bz = b ~/ 10, be = b % 10;
    switch (x.typ) {
      case NachhilfeTyp.additionBis20:
        return 'p20';
      case NachhilfeTyp.subtraktionBis20:
        return 'm20 ${x.zehnerUebergang} ${a <= 10}';
      case NachhilfeTyp.additionBis100:
        return 'p100 ${bz > 0} ${be > 0} ${x.zehnerUebergang} '
            '${ae + be > 10} ${a < 10 && b >= 10}';
      case NachhilfeTyp.subtraktionBis100:
        return 'm100 ${bz > 0} ${be > 0} ${x.zehnerUebergang} ${ae > 0} '
            '${az == 10}';
      case NachhilfeTyp.einmaleins:
        final erstDrehen = a != b && !_istKern(a) && _istKern(b);
        return erstDrehen ? 'mal b$b' : 'mal a$a';
    }
  }

  NachhilfeAufgabe _zwillingNeu(NachhilfeAufgabe x, int variante) {
    final wege = wegeFuer(x).map((w) => w.name).join(',');
    final signatur = _signatur(x);
    List<(NachhilfeAufgabe, int)> suche(int radius, {required bool streng}) {
      final gefunden = <(NachhilfeAufgabe, int)>[];
      for (var da = -radius; da <= radius; da++) {
        for (var db = -radius; db <= radius; db++) {
          final k = _gleicherTyp(x, x.a + da, x.b + db);
          if (k == null || k.ergebnis == x.ergebnis) continue;
          if (streng &&
              (_signatur(k) != signatur ||
                  wegeFuer(k).map((w) => w.name).join(',') != wege)) {
            continue;
          }
          gefunden.add((k, da.abs() + db.abs()));
        }
      }
      return gefunden;
    }

    var kandidaten = suche(3, streng: true);
    if (kandidaten.isEmpty) kandidaten = suche(9, streng: true);
    if (kandidaten.isEmpty) kandidaten = suche(3, streng: false);
    kandidaten.sort((p, q) => p.$2 != q.$2
        ? p.$2.compareTo(q.$2)
        : (p.$1.a * 1000 + p.$1.b).compareTo(q.$1.a * 1000 + q.$1.b));
    return kandidaten[variante.abs() % kandidaten.length].$1;
  }

  // ---------------------------------------------------------------------
  // Pläne der fünf Stufen.

  NachhilfePlan _planNeu(
      NachhilfeAufgabe original, NachhilfeWeg weg, NachhilfeStufe stufe) {
    final aufgabe = switch (stufe) {
      NachhilfeStufe.vorzeigen => zwilling(original),
      NachhilfeStufe.ueben => zwilling(original, variante: 1),
      _ => original,
    };
    final wege = wegeFuer(aufgabe);
    final w = wege.contains(weg) ? weg : wege.first;
    final kern = _kernNeu(aufgabe, w);
    final schritte = <NachhilfeSchritt>[];
    String? auftrag;
    switch (stufe) {
      case NachhilfeStufe.hinweis:
        schritte.add(_alsNeu(kern.first, NachhilfeAkteur.lumo));
        schritte.add(NachhilfeSchritt(
          id: 'tipp',
          akteur: NachhilfeAkteur.lumo,
          text: _tippNeu(aufgabe, w),
          aktion: NachhilfeAktion.zeigen(),
        ));
      case NachhilfeStufe.andereErklaerung:
        final alltag = _alltag(aufgabe);
        schritte.add(NachhilfeSchritt(
          id: 'alltag',
          akteur: NachhilfeAkteur.lumo,
          text: alltag.text,
          aktion: alltag.bild,
        ));
        if (alltag.frage != null) {
          schritte.add(NachhilfeSchritt(
            id: 'alltag-frage',
            akteur: NachhilfeAkteur.kind,
            text: alltag.fragetext!,
            aktion: alltag.bild,
            frage: alltag.frage,
            hilfe: alltag.hilfe,
          ));
        }
      case NachhilfeStufe.teilschritt:
        final gemeinsam = _gemeinsam(aufgabe, kern);
        schritte.addAll(gemeinsam.$1);
        auftrag = gemeinsam.$2;
      case NachhilfeStufe.vorzeigen:
        for (final k in kern) {
          schritte.add(_alsNeu(k, NachhilfeAkteur.lumo));
        }
      case NachhilfeStufe.ueben:
        for (final k in kern) {
          schritte.add(_alsNeu(k, NachhilfeAkteur.kind));
        }
    }
    final o = original.text;
    final einleitung = switch (stufe) {
      NachhilfeStufe.hinweis => 'Ich gebe dir einen kleinen Tipp für $o.',
      NachhilfeStufe.andereErklaerung =>
        'Ich erkläre dir $o mit anderen Worten.',
      NachhilfeStufe.vorzeigen =>
        'Schau mir zu: Ich zeige es dir an ${aufgabe.text}. Das ist fast wie deine Aufgabe $o.',
      NachhilfeStufe.teilschritt =>
        'Wir rechnen $o gemeinsam. Du rechnest jeden Schritt, ich warte auf dich.',
      NachhilfeStufe.ueben =>
        'Jetzt prüfen wir, ob du es verstanden hast: Rechne ${aufgabe.text} ganz allein.',
    };
    final abschluss = switch (stufe) {
      NachhilfeStufe.teilschritt when auftrag != null =>
        'Jetzt du: $auftrag Das rechnest du in deiner Aufgabe $o fertig.',
      NachhilfeStufe.hinweis ||
      NachhilfeStufe.andereErklaerung ||
      NachhilfeStufe.teilschritt =>
        'Jetzt rechnest du $o selbst fertig.',
      NachhilfeStufe.vorzeigen => 'Genauso geht $o. Probier es jetzt selbst.',
      NachhilfeStufe.ueben => 'Super! Jetzt schaffst du auch $o.',
    };
    final lob = w == NachhilfeWeg.tauschen &&
            aufgabe.typ == NachhilfeTyp.einmaleins
        ? 'Schlau gedreht! Gleich viele Punkte – und eine Aufgabe, die du kennst.'
        : lobFuer(w);
    return NachhilfePlan(
      original: original,
      aufgabe: aufgabe,
      weg: w,
      stufe: stufe,
      einleitung: einleitung,
      schritte: List.unmodifiable(schritte),
      lob: lob,
      abschluss: abschluss,
    );
  }

  NachhilfeSchritt _alsNeu(_Kern k, NachhilfeAkteur akteur) {
    final wer = k.nurLumo ? NachhilfeAkteur.lumo : akteur;
    return NachhilfeSchritt(
      id: k.id,
      akteur: wer,
      text: wer == NachhilfeAkteur.lumo ? k.lumo : k.kind,
      aktion: k.aktion,
      frage: wer == NachhilfeAkteur.kind ? k.frage : null,
      hilfe: wer == NachhilfeAkteur.kind ? k.hilfe : null,
    );
  }

  /// Gemeinsam: Lumo legt das Material hin, das Kind rechnet jeden
  /// Zwischenschritt. Der letzte Schritt bleibt für die Aufgabe selbst.
  (List<NachhilfeSchritt>, String?) _gemeinsam(
      NachhilfeAufgabe x, List<_Kern> kern) {
    final ohne = kern.where((k) => k.aktion.art != 'ergebnis').toList();
    final mitFrage = ohne.any((k) => k.frage != null);
    final List<_Kern> teil;
    String? auftrag;
    if (!mitFrage) {
      // Rechenrahmen und Steine zum Antippen wie bei Plus bis 20.
      teil = ohne.length > 2 ? ohne.sublist(0, ohne.length - 1) : ohne;
    } else {
      teil = ohne.length > 1 ? ohne.sublist(0, ohne.length - 1) : ohne;
      if (ohne.length > 1) auftrag = ohne.last.auftrag;
    }
    final schritte = <NachhilfeSchritt>[
      for (var i = 0; i < teil.length; i++)
        _alsNeu(teil[i], i == 0 ? NachhilfeAkteur.lumo : NachhilfeAkteur.kind),
    ];
    if (mitFrage &&
        !schritte
            .any((s) => s.akteur == NachhilfeAkteur.kind && s.frage != null)) {
      final klein = _kleineAufgabe(x);
      if (klein != null) {
        schritte.add(NachhilfeSchritt(
          id: 'klein',
          akteur: NachhilfeAkteur.kind,
          text: klein.$1,
          aktion: NachhilfeAktion.zeigen(),
          frage: klein.$2,
        ));
      }
    }
    return (schritte, auftrag);
  }

  /// Ein Teil der Rechnung, der nicht schon das Ergebnis ist.
  (String, int)? _kleineAufgabe(NachhilfeAufgabe x) {
    final az = x.a ~/ 10, ae = x.a % 10, bz = x.b ~/ 10, be = x.b % 10;
    final (String, int)? klein = switch (x.typ) {
      NachhilfeTyp.additionBis100 when be == 0 => (
          'Rechne nur mit den Zehnern: $az Zehner und $bz Zehner. Wie viele Zehner sind das?',
          az + bz
        ),
      NachhilfeTyp.additionBis100 when bz == 0 && !x.zehnerUebergang => (
          'Rechne zuerst nur die Einer: Wie viel ist $ae + $be?',
          ae + be
        ),
      NachhilfeTyp.subtraktionBis100 when be == 0 => (
          'Rechne nur mit den Zehnern: $az Zehner weniger $bz Zehner. Wie viele Zehner bleiben?',
          az - bz
        ),
      NachhilfeTyp.subtraktionBis100 when bz == 0 && !x.zehnerUebergang => (
          'Rechne zuerst nur die Einer: Wie viel ist $ae − $be?',
          ae - be
        ),
      NachhilfeTyp.subtraktionBis100 when bz == 0 && ae == 0 => (
          'Mach einen Zehner auf: 10 Würfel. Nimm $be davon weg. Wie viele Würfel bleiben?',
          10 - be
        ),
      NachhilfeTyp.einmaleins when x.a == 2 && x.b >= 6 => (
          'Mach zuerst die 10 voll: ${x.b} + ${10 - x.b} = 10. Wie viele Punkte der zweiten Reihe bleiben dann noch übrig?',
          2 * x.b - 10
        ),
      NachhilfeTyp.einmaleins when x.a == 10 => (
          'Jede Reihe hat ${x.b} Punkte. Wie viele Zehner sind 10 Reihen?',
          x.b
        ),
      _ => null,
    };
    if (klein == null || klein.$2 == x.ergebnis) return null;
    return klein;
  }

  List<_Kern> _kernNeu(NachhilfeAufgabe x, NachhilfeWeg w) {
    switch (x.typ) {
      case NachhilfeTyp.additionBis20:
        return _kernSchritte(x, w);
      case NachhilfeTyp.subtraktionBis20:
        return _kernMinus20(x, w);
      case NachhilfeTyp.additionBis100:
      case NachhilfeTyp.subtraktionBis100:
        if (w == NachhilfeWeg.zahlenstrahl) return _kernSprung100(x);
        if (w == NachhilfeWeg.tauschen) return _kernTausch100(x);
        return _kernStangen(x);
      case NachhilfeTyp.einmaleins:
        final r = x.a, c = x.b;
        final erg = _Kern('ergebnis',
            kind: '${x.text} = ${x.ergebnis}.',
            lumo: '${x.text} = ${x.ergebnis}.',
            aktion: NachhilfeAktion.ergebnis(
                x.ergebnis, _ergebnisOptionen(x.ergebnis)),
            nurLumo: true);
        NachhilfeAktion feld(int s, int m, int g) => NachhilfeAktion.punkte(
            zeilen: r, spalten: c, sichtbar: s, markiert: m, geister: g);
        if (w == NachhilfeWeg.punktefeld) {
          return [..._kernReihen(r, c, feld), erg];
        }
        if (w == NachhilfeWeg.tauschen && r != c) {
          NachhilfeAktion gedreht(int s, int m, int g) =>
              NachhilfeAktion.punkte(
                  zeilen: r,
                  spalten: c,
                  sichtbar: s,
                  markiert: m,
                  geister: g,
                  gedreht: true);
          return [
            _Kern('start',
                kind:
                    '$r · $c heißt: ${_reihenWort(r)} mit je ${_punkteWort(c)}.',
                lumo:
                    '$r · $c heißt: ${_reihenWort(r)} mit je ${_punkteWort(c)}.',
                aktion: feld(r, 0, 0),
                nurLumo: true),
            _Kern('drehen',
                kind: 'Lumo dreht das Feld.',
                lumo:
                    'Ich drehe das Feld. Jetzt sind es ${_reihenWort(c)} mit je ${_punkteWort(r)}. Es sind gleich viele Punkte: $r · $c ist dasselbe wie $c · $r.',
                aktion: gedreht(c, 0, 0),
                nurLumo: true,
                auftrag: 'Dreh das Feld: $r · $c ist dasselbe wie $c · $r.'),
            ..._kernAnker(c, r, gedreht, mitStart: false),
            erg,
          ];
        }
        return [..._kernAnker(r, c, feld, mitStart: true), erg];
    }
  }

  // ---------------------------------------------------------------------
  // Minus bis 20: Rechenrahmen, Zahlenstrahl, Zerlegen (erst bis zur 10).

  List<_Kern> _kernMinus20(NachhilfeAufgabe x, NachhilfeWeg w) {
    final a = x.a, b = x.b, e = x.ergebnis;
    final oben = a > 10 ? 10 : a, unten = a > 10 ? a - 10 : 0;
    final fuenf =
        unten == 0 && oben > 5 ? ' Fünf rote und ${oben - 5} weiße.' : '';
    final start = _Kern('erste',
        kind: unten > 0
            ? 'Schieb $a Perlen nach links: 10 oben und $unten unten.'
            : 'Schieb $a Perlen nach links in die erste Reihe.$fuenf',
        lumo: unten > 0
            ? 'Ich schiebe $a Perlen nach links: 10 oben und $unten unten.'
            : 'Ich schiebe $a Perlen nach links.$fuenf',
        aktion: NachhilfeAktion.perlen(oben, unten));
    final aufStart = _Kern('start',
        kind: 'Tipp auf den Stein $a. Lumo springt hin.',
        lumo: 'Ich springe auf die $a.',
        aktion: NachhilfeAktion.huepfen(0, a));
    final ergebnis = _Kern('ergebnis',
        kind: 'Wie viel ist ${x.text}? Tipp auf das Ergebnis.',
        lumo: '${x.text} = $e.',
        aktion: NachhilfeAktion.ergebnis(e, _ergebnisOptionen(e)));
    final ueber = x.zehnerUebergang;
    final zuerst = a - 10, rest = b - (a - 10);
    if (w == NachhilfeWeg.zahlenstrahl) {
      if (!ueber) {
        return [
          aufStart,
          _Kern('weg',
              kind: 'Jetzt $b Sprünge zurück. Wo landet Lumo?',
              lumo: 'Ich springe $b zurück und lande auf $e.',
              aktion: NachhilfeAktion.huepfen(a, e)),
          ergebnis,
        ];
      }
      return [
        aufStart,
        _Kern('zehn',
            kind: 'Spring zurück bis zur 10. Tipp auf die 10.',
            lumo: 'Ich springe zurück bis zur 10. Das sind $zuerst Sprünge.',
            aktion: NachhilfeAktion.huepfen(a, 10)),
        _Kern('rest',
            kind:
                '$zuerst von den $b bist du schon zurückgesprungen. Wie viele fehlen noch? Spring weiter zurück.',
            lumo: 'Von den $b ${_nochUebrig(rest)}. Ich springe $rest zurück.',
            aktion: NachhilfeAktion.huepfen(10, e)),
        ergebnis,
      ];
    }
    if (ueber && w == NachhilfeWeg.zerlegen) {
      return [
        start,
        _Kern('teilen',
            kind:
                'Teile die $b in zwei Teile. Mit dem ersten Teil kommst du genau zur 10 zurück.',
            lumo:
                'Von $a bis 10 sind es $zuerst. Also teile ich $b in $zuerst und $rest.',
            aktion: NachhilfeAktion.zerlegen(
                b, zuerst, rest, _zerlegungen(b, zuerst))),
        _Kern('zehn',
            kind: 'Nimm den ersten Teil unten weg. Dann sind es genau 10.',
            lumo: 'Ich nehme $zuerst unten weg: $a − $zuerst = 10.',
            aktion: NachhilfeAktion.perlen(10, 0)),
        _Kern('rest',
            kind: 'Nimm den zweiten Teil oben weg.',
            lumo: 'Die anderen $rest nehme ich oben weg: 10 − $rest = $e.',
            aktion: NachhilfeAktion.perlen(e, 0)),
        ergebnis,
      ];
    }
    if (ueber) {
      return [
        start,
        _Kern('zehn',
            kind: zuerst == 1
                ? 'Nimm zuerst die eine Perle unten weg. Dann sind es genau 10.'
                : 'Nimm zuerst die $zuerst Perlen unten weg. Dann sind es genau 10.',
            lumo: zuerst == 1
                ? 'Ich nehme zuerst die eine Perle unten weg. Jetzt sind es 10.'
                : 'Ich nehme zuerst die $zuerst Perlen unten weg. Jetzt sind es 10.',
            aktion: NachhilfeAktion.perlen(10, 0)),
        _Kern('rest',
            kind:
                'Von den $b hast du $zuerst weggenommen. Nimm den Rest oben weg.',
            lumo:
                'Von den $b ${_nochUebrig(rest)}. Ich nehme sie oben weg: 10 − $rest = $e.',
            aktion: NachhilfeAktion.perlen(e, 0)),
        ergebnis,
      ];
    }
    if (unten == 0) {
      return [
        start,
        _Kern('weg',
            kind: 'Schieb $b Perlen zurück nach rechts.',
            lumo: 'Ich schiebe $b Perlen zurück. Jetzt sind es $e.',
            aktion: NachhilfeAktion.perlen(e, 0)),
        ergebnis,
      ];
    }
    return [
      start,
      _Kern('weg',
          kind: 'Die volle Reihe oben bleibt. Nimm unten $b Perlen weg.',
          lumo:
              'Die volle Reihe bleibt. Unten nehme ich $b weg: $unten − $b = ${unten - b}. Mit der vollen Reihe sind es $e.',
          aktion: NachhilfeAktion.perlen(10, unten - b)),
      ergebnis,
    ];
  }

  // ---------------------------------------------------------------------
  // Kopfrechnen bis 100: erst die Zehner, dann bis zum nächsten Zehner,
  // dann der Rest der Einer.

  _Kern _ergebnisSchluss(NachhilfeAufgabe x) => _Kern('ergebnis',
      kind: '${x.text} = ${x.ergebnis}.',
      lumo: '${x.text} = ${x.ergebnis}.',
      aktion:
          NachhilfeAktion.ergebnis(x.ergebnis, _ergebnisOptionen(x.ergebnis)),
      nurLumo: true);

  String _zehnerschritte(int start, int anzahl, {required bool plus}) {
    final werte = <int>[
      for (var i = 0; i < anzahl; i++) start + (plus ? 10 : -10) * i
    ];
    return '${werte.join(', ')}, …';
  }

  List<_Kern> _kernStangen(NachhilfeAufgabe x, {bool mitStart = true}) {
    final a = x.a, b = x.b, e = x.ergebnis;
    final az = a ~/ 10, ae = a % 10, bz = b ~/ 10, be = b % 10;
    final schritte = <_Kern>[];
    if (x.typ.istPlus) {
      if (mitStart) {
        schritte.add(_Kern('start',
            kind: 'Hier liegt $a: ${_stangenText(az, ae)}. Daneben liegt $b.',
            lumo:
                'Ich lege $a hin: ${_stangenText(az, ae)}. Daneben liegen die $b: ${_stangenText(bz, be)}.',
            aktion: NachhilfeAktion.stangen(
                zehner: az, einer: ae, dazuZehner: bz, dazuEiner: be),
            nurLumo: true));
      }
      var z = az, wert = a;
      if (bz > 0) {
        final neu = a + 10 * bz;
        schritte.add(_Kern('zehner',
            kind: 'Leg ${_stangenWort(bz)} dazu. Wie viel ist $a + ${10 * bz}?',
            lumo: 'Ich lege ${_stangenWort(bz)} dazu: $a + ${10 * bz} = $neu.',
            frage: neu,
            hilfe:
                'Zähl in Zehnerschritten weiter: ${_zehnerschritte(a, bz, plus: true)}',
            auftrag: 'Leg noch ${_stangenWort(bz)} dazu.',
            aktion: NachhilfeAktion.stangen(
                zehner: az + bz, einer: ae, dazuEiner: be)));
        z = az + bz;
        wert = neu;
      }
      if (be > 0 && ae + be >= 10) {
        final fehlt = 10 - ae, zehner = wert + fehlt, uebrig = be - fehlt;
        schritte.add(_Kern('bisZehn',
            kind: 'Wie viele Einer fehlen von $wert bis $zehner?',
            lumo:
                'Von $wert bis $zehner ${fehlt == 1 ? 'fehlt 1 Würfel' : 'fehlen $fehlt Würfel'}. Ich lege ${_wuerfelWort(fehlt)} dazu.',
            frage: fehlt,
            hilfe:
                'Zähl die leeren Plätze: $ae Würfel liegen schon, 10 passen hinein.',
            auftrag: 'Leg so viele Einer dazu, bis der Zehner voll ist.',
            aktion: NachhilfeAktion.stangen(
                zehner: z, einer: 10, dazuEiner: uebrig)));
        schritte.add(_Kern('buendeln',
            kind: '10 Würfel sind eine neue Zehnerstange.',
            lumo:
                '10 Würfel sind eine neue Zehnerstange. Jetzt sind es $zehner.',
            auftrag: '10 Würfel werden eine neue Zehnerstange.',
            aktion: NachhilfeAktion.stangen(
                zehner: z + 1, einer: 0, dazuEiner: uebrig),
            nurLumo: true));
        if (uebrig > 0) {
          schritte.add(_Kern('rest',
              kind:
                  'Von den $be Würfeln ${_nochUebrig(uebrig)}. Leg ${uebrig == 1 ? 'ihn' : 'sie'} dazu. Wie viel ist $zehner + $uebrig?',
              lumo: uebrig == 1
                  ? 'Der letzte Würfel kommt dazu: $zehner + 1 = $e.'
                  : 'Die übrigen $uebrig Würfel kommen dazu: $zehner + $uebrig = $e.',
              frage: e,
              hilfe: '$zehner und noch $uebrig Einer.',
              auftrag:
                  'Von den $be Würfeln ${_nochUebrig(uebrig)}. Leg ${uebrig == 1 ? 'ihn' : 'sie'} dazu.',
              aktion: NachhilfeAktion.stangen(zehner: z + 1, einer: uebrig)));
        }
      } else if (be > 0) {
        schritte.add(_Kern('einer',
            kind:
                'Leg ${be == 1 ? 'den Einerwürfel' : 'die $be Einerwürfel'} dazu. Wie viel ist $wert + $be?',
            lumo:
                'Ich lege ${be == 1 ? 'den Einerwürfel' : 'die $be Einerwürfel'} dazu: $wert + $be = $e.',
            frage: e,
            hilfe: 'Die Zehner bleiben. Rechne nur die Einer: $ae + $be.',
            auftrag:
                'Leg noch ${be == 1 ? 'den Einerwürfel' : 'die $be Einerwürfel'} dazu.',
            aktion: NachhilfeAktion.stangen(zehner: z, einer: ae + be)));
      }
      return [...schritte, _ergebnisSchluss(x)];
    }
    // Minus
    schritte.add(_Kern('start',
        kind: 'Hier liegt $a: ${_stangenText(az, ae)}. Weg kommen $b.',
        lumo:
            'Ich lege $a hin: ${_stangenText(az, ae)}. Wegnehmen wollen wir $b: ${_stangenText(bz, be)}.',
        aktion: NachhilfeAktion.stangen(zehner: az, einer: ae),
        nurLumo: true));
    var z = az, wert = a, wz = 0;
    if (bz > 0) {
      final neu = a - 10 * bz;
      schritte.add(_Kern('zehner',
          kind: 'Nimm ${_stangenWort(bz)} weg. Wie viel ist $a − ${10 * bz}?',
          lumo: 'Ich nehme ${_stangenWort(bz)} weg: $a − ${10 * bz} = $neu.',
          frage: neu,
          hilfe:
              'Zähl in Zehnerschritten zurück: ${_zehnerschritte(a, bz, plus: false)}',
          auftrag: 'Nimm noch ${_stangenWort(bz)} weg.',
          aktion: NachhilfeAktion.stangen(
              zehner: az - bz, einer: ae, wegZehner: bz)));
      z = az - bz;
      wert = neu;
      wz = bz;
    }
    if (be > 0 && ae >= be) {
      schritte.add(_Kern('einer',
          kind: 'Nimm ${_wuerfelWort(be)} weg. Wie viel ist $wert − $be?',
          lumo: 'Ich nehme ${_wuerfelWort(be)} weg: $wert − $be = $e.',
          frage: e,
          hilfe: 'Die Zehner bleiben. Rechne nur die Einer: $ae − $be.',
          auftrag: 'Nimm noch ${_wuerfelWort(be)} weg.',
          aktion: NachhilfeAktion.stangen(
              zehner: z, einer: ae - be, wegZehner: wz, wegEiner: be)));
    } else if (be > 0) {
      final zehner = wert - ae, fehlt = be - ae;
      if (ae > 0) {
        schritte.add(_Kern('bisZehn',
            kind: ae == 1
                ? 'Nimm zuerst den einzelnen Würfel weg. Wie viel bleibt?'
                : 'Nimm zuerst die $ae einzelnen Würfel weg. Wie viel bleibt?',
            lumo: ae == 1
                ? 'Zuerst nehme ich den einzelnen Würfel weg: $wert − 1 = $zehner.'
                : 'Zuerst nehme ich die $ae einzelnen Würfel weg: $wert − $ae = $zehner.',
            frage: zehner,
            hilfe: 'Dann liegen nur noch die Zehnerstangen da.',
            auftrag: ae == 1
                ? 'Nimm zuerst den einzelnen Würfel weg.'
                : 'Nimm zuerst die $ae einzelnen Würfel weg.',
            aktion: NachhilfeAktion.stangen(
                zehner: z, einer: 0, wegZehner: wz, wegEiner: ae)));
      }
      schritte.add(_Kern('aufmachen',
          kind: 'Lumo macht eine Zehnerstange auf.',
          lumo:
              '${fehlt == 1 ? 'Es fehlt noch 1 Würfel' : 'Es fehlen noch $fehlt Würfel'}. Ich mache eine Zehnerstange auf: Das sind 10 einzelne Würfel.',
          auftrag: 'Mach eine Zehnerstange auf: 10 einzelne Würfel.',
          aktion: NachhilfeAktion.stangen(
              zehner: z - 1, einer: 10, wegZehner: wz, wegEiner: ae),
          nurLumo: true));
      schritte.add(_Kern('rest',
          kind:
              'Nimm noch ${_wuerfelWort(fehlt)} weg. Wie viel ist $zehner − $fehlt?',
          lumo:
              'Ich nehme noch ${_wuerfelWort(fehlt)} weg: $zehner − $fehlt = $e.',
          frage: e,
          hilfe: 'Von den 10 Würfeln bleiben ${10 - fehlt} liegen.',
          auftrag: 'Nimm noch ${_wuerfelWort(fehlt)} weg.',
          aktion: NachhilfeAktion.stangen(
              zehner: z - 1, einer: 10 - fehlt, wegZehner: wz, wegEiner: be)));
    }
    return [...schritte, _ergebnisSchluss(x)];
  }

  /// 7 + 45: mit der großen Zahl anfangen, dann wie bei den Zehnerstangen.
  List<_Kern> _kernTausch100(NachhilfeAufgabe x) {
    final getauscht = NachhilfeAufgabe.additionBis100(x.b, x.a)!;
    final bz = x.b ~/ 10, be = x.b % 10;
    return [
      _Kern('tauschen',
          kind: '${x.text} ist dasselbe wie ${getauscht.text}.',
          lumo:
              '${x.text} ist dasselbe wie ${getauscht.text}. Ich fange mit der großen Zahl ${x.b} an: ${_stangenText(bz, be)}.',
          aktion:
              NachhilfeAktion.stangen(zehner: bz, einer: be, dazuEiner: x.a),
          nurLumo: true),
      ..._kernStangen(getauscht, mitStart: false)
          .where((k) => k.id != 'ergebnis'),
      _ergebnisSchluss(x),
    ];
  }

  List<_Kern> _kernSprung100(NachhilfeAufgabe x) {
    final a = x.a, b = x.b, e = x.ergebnis;
    final ae = a % 10, bz = b ~/ 10, be = b % 10;
    final plus = x.typ.istPlus;
    final vor = plus ? 'weiter' : 'zurück';
    final op = plus ? '+' : '−';
    final schritte = <_Kern>[
      _Kern('start',
          kind: 'Lumo steht auf der $a.',
          lumo: 'Ich stelle mich auf die $a.',
          aktion: NachhilfeAktion.huepfen(a, a),
          nurLumo: true),
    ];
    var wert = a;
    if (bz > 0) {
      final neu = plus ? a + 10 * bz : a - 10 * bz;
      schritte.add(_Kern('zehner',
          kind:
              'Spring ${bz == 1 ? 'einen Zehnersprung' : '$bz Zehnersprünge'} $vor. Wo landet Lumo?',
          lumo:
              'Ich springe ${_zehnerWort(bz)} $vor: $a $op ${10 * bz} = $neu.',
          frage: neu,
          hilfe:
              'Jeder große Sprung ist 10: ${_zehnerschritte(a, bz, plus: plus)}',
          auftrag: 'Spring ${_zehnerWort(bz)} $vor.',
          aktion: NachhilfeAktion.huepfen(a, neu)));
      wert = neu;
    }
    final w = wert % 10;
    final uebergang = plus ? be > 0 && w + be >= 10 : be > w && w > 0;
    if (uebergang) {
      final fehlt = plus ? 10 - w : w;
      final zehner = plus ? wert + fehlt : wert - fehlt;
      final uebrig = be - fehlt;
      schritte.add(_Kern('bisZehn',
          kind:
              'Spring $vor bis zur $zehner. Wie viele kleine Sprünge sind das?',
          lumo: fehlt == 1
              ? 'Bis zur $zehner ist es 1 kleiner Sprung.'
              : 'Bis zur $zehner sind es $fehlt kleine Sprünge.',
          frage: fehlt,
          hilfe: 'Zähl die kleinen Striche von $wert bis $zehner.',
          auftrag: 'Spring $vor bis zur $zehner.',
          aktion: NachhilfeAktion.huepfen(wert, zehner)));
      if (uebrig > 0) {
        schritte.add(_Kern('rest',
            kind:
                'Von den $be kleinen Sprüngen fehlen noch $uebrig. Spring $uebrig $vor. Wo landet Lumo?',
            lumo: 'Noch $uebrig $vor: $zehner $op $uebrig = $e.',
            frage: e,
            hilfe: 'Von der $zehner aus $uebrig kleine Sprünge $vor.',
            auftrag: 'Spring noch $uebrig $vor.',
            aktion: NachhilfeAktion.huepfen(zehner, e)));
      }
    } else if (be > 0) {
      schritte.add(_Kern('einer',
          kind: 'Spring noch $be kleine Sprünge $vor. Wo landet Lumo?',
          lumo: 'Ich springe noch $be $vor: $wert $op $be = $e.',
          frage: e,
          hilfe: plus
              ? 'Die Zehner bleiben. Rechne nur die Einer: $ae + $be.'
              : 'Zähl $be kleine Striche $vor.',
          auftrag: 'Spring noch $be kleine Sprünge $vor.',
          aktion: NachhilfeAktion.huepfen(wert, e)));
    }
    return [...schritte, _ergebnisSchluss(x)];
  }

  // ---------------------------------------------------------------------
  // Einmaleins: Punktefeld, Kernaufgaben als Anker, Nachbaraufgaben.

  List<_Kern> _kernReihen(int r, int c, _Feld feld) => [
        _Kern('start',
            kind: '$r · $c heißt: $r Reihen mit je ${_punkteWort(c)}.',
            lumo:
                '$r · $c heißt: $r Reihen mit je ${_punkteWort(c)}. In der ersten Reihe sind $c.',
            aktion: feld(1, 1, 0),
            nurLumo: true),
        for (var i = 2; i <= r; i++)
          _Kern('reihe$i',
              kind: 'Reihe $i kommt dazu. Wie viele Punkte sind es jetzt?',
              lumo: 'Reihe $i kommt dazu: ${(i - 1) * c} + $c = ${i * c}.',
              frage: i * c,
              hilfe: 'Zähl $c weiter: ${(i - 1) * c} + $c.',
              auftrag: 'Reihe $i kommt noch dazu: ${(i - 1) * c} + $c.',
              aktion: feld(i, i, 0)),
      ];

  List<_Kern> _kernAnker(int r, int c, _Feld feld, {required bool mitStart}) {
    final k = <_Kern>[];
    if (mitStart) {
      k.add(_Kern('start',
          kind: '$r · $c heißt: ${_reihenWort(r)} mit je ${_punkteWort(c)}.',
          lumo: r == 2
              ? '2 · $c heißt: 2 Reihen mit je ${_punkteWort(c)}. In der ersten Reihe sind $c.'
              : '$r · $c heißt: ${_reihenWort(r)} mit je ${_punkteWort(c)}.',
          aktion: feld(r == 2 ? 1 : r, 0, 0),
          nurLumo: true));
    }
    final fuenf = 5 * c, zehn = 10 * c, zwei = 2 * c;
    _Kern kern5(String id) => _Kern(id,
        kind: 'Die ersten 5 Reihen kennst du: 5 · $c. Wie viel ist 5 · $c?',
        lumo: 'Die ersten 5 Reihen kenne ich: 5 · $c = $fuenf.',
        frage: fuenf,
        hilfe: '5 · $c ist die Hälfte von 10 · $c = $zehn.',
        auftrag: 'Die ersten 5 Reihen sind 5 · $c.',
        aktion: feld(r, 5, 0));
    _Kern kern10(int geister) => _Kern('zehn',
        kind: geister == 1
            ? 'Stell dir eine Reihe mehr vor: 10 Reihen. Wie viel ist 10 · $c?'
            : 'Stell dir 2 Reihen mehr vor: 10 Reihen. Wie viel ist 10 · $c?',
        lumo: 'Ich stelle mir 10 Reihen vor: 10 · $c = $zehn.',
        frage: zehn,
        hilfe: '10 · $c sind $c Zehner. Hänge an die $c eine 0 an.',
        auftrag: 'Stell dir 10 Reihen vor: 10 · $c.',
        aktion: feld(r, 0, geister));
    switch (r) {
      case 1:
        k.add(_Kern('zaehlen',
            kind: 'Zähl die Punkte in der einen Reihe. Wie viele sind es?',
            lumo: 'In der einen Reihe sind $c Punkte: 1 · $c = $c.',
            frage: c,
            hilfe: 'Tipp jeden Punkt mit dem Finger an und zähl mit.',
            auftrag: 'Zähl die Punkte in der einen Reihe.',
            aktion: feld(1, 1, 0)));
      case 2:
        k.add(_Kern('doppel',
            kind:
                'Die zweite Reihe ist genauso lang. Verdopple: Wie viel ist $c + $c?',
            lumo:
                'Die zweite Reihe kommt dazu. Das Doppelte von $c ist $c + $c = $zwei.',
            frage: zwei,
            hilfe: c >= 6
                ? 'Mach zuerst die 10 voll: $c + ${10 - c} = 10. Dann kommen noch ${zwei - 10} dazu.'
                : 'Zähl von $c aus noch $c weiter.',
            auftrag: 'Die zweite Reihe ist genauso lang. Verdopple die $c.',
            aktion: feld(2, 2, 0)));
      case 3:
        k.add(_Kern('kern',
            kind: 'Die ersten 2 Reihen kennst du: 2 · $c. Wie viel ist 2 · $c?',
            lumo: 'Die ersten 2 Reihen kenne ich: 2 · $c = $zwei.',
            frage: zwei,
            hilfe: '2 · $c ist das Doppelte: $c + $c.',
            auftrag: 'Die ersten 2 Reihen sind 2 · $c.',
            aktion: feld(3, 2, 0)));
        k.add(_Kern('dazu',
            kind:
                'Eine Reihe mit $c Punkten kommt noch dazu. Wie viel ist $zwei + $c?',
            lumo: 'Eine Reihe kommt noch dazu: $zwei + $c = ${3 * c}.',
            frage: 3 * c,
            hilfe: 'Zähl von $zwei aus $c weiter.',
            auftrag: 'Eine Reihe mit $c Punkten kommt noch dazu: $zwei + $c.',
            aktion: feld(3, 3, 0)));
      case 4:
        k.add(_Kern('kern',
            kind:
                'Stell dir eine Reihe mehr vor: 5 Reihen. Wie viel ist 5 · $c?',
            lumo: 'Ich stelle mir eine Reihe mehr vor: 5 · $c = $fuenf.',
            frage: fuenf,
            hilfe: '5 · $c ist die Hälfte von 10 · $c = $zehn.',
            auftrag: 'Stell dir 5 Reihen vor: 5 · $c.',
            aktion: feld(4, 0, 1)));
        k.add(_Kern('weg',
            kind:
                'Eine Reihe ist zu viel. Nimm sie weg: Wie viel ist $fuenf − $c?',
            lumo:
                'Eine Reihe ist zu viel. Ich nehme sie weg: $fuenf − $c = ${4 * c}.',
            frage: 4 * c,
            hilfe: 'Geh von $fuenf aus $c zurück.',
            auftrag: 'Eine Reihe ist zu viel. Nimm sie weg: $fuenf − $c.',
            aktion: feld(4, 4, 0)));
      case 5:
        k.add(_Kern('zehn',
            kind:
                'Stell dir 10 Reihen vor. 10 · $c sind $c Zehner. Wie viel ist 10 · $c?',
            lumo: 'Ich stelle mir 10 Reihen vor: 10 · $c = $zehn.',
            frage: zehn,
            hilfe: '$c Zehner: Hänge an die $c eine 0 an.',
            auftrag: 'Stell dir 10 Reihen vor: 10 · $c.',
            aktion: feld(5, 0, 5)));
        k.add(_Kern('haelfte',
            kind:
                '5 Reihen sind die Hälfte von 10 Reihen. Was ist die Hälfte von $zehn?',
            lumo: '5 Reihen sind die Hälfte: Die Hälfte von $zehn ist $fuenf.',
            frage: fuenf,
            hilfe: 'Teile $zehn in zwei gleich große Teile.',
            auftrag: '5 Reihen sind die Hälfte von 10 Reihen. Halbiere $zehn.',
            aktion: feld(5, 5, 0)));
      case 6:
        k.add(kern5('kern'));
        k.add(_Kern('dazu',
            kind:
                'Eine Reihe mit $c Punkten kommt noch dazu. Wie viel ist $fuenf + $c?',
            lumo: 'Eine Reihe kommt noch dazu: $fuenf + $c = ${6 * c}.',
            frage: 6 * c,
            hilfe: 'Zähl von $fuenf aus $c weiter.',
            auftrag: 'Eine Reihe mit $c Punkten kommt noch dazu: $fuenf + $c.',
            aktion: feld(6, 6, 0)));
      case 7:
        k.add(kern5('kern'));
        k.add(_Kern('kern2',
            kind: 'Unten sind noch 2 Reihen: 2 · $c. Wie viel ist 2 · $c?',
            lumo: 'Unten sind noch 2 Reihen: 2 · $c = $zwei.',
            frage: zwei,
            hilfe: '2 · $c ist das Doppelte: $c + $c.',
            auftrag: 'Unten sind noch 2 Reihen: 2 · $c.',
            aktion: feld(7, 5, 0)));
        k.add(_Kern('zusammen',
            kind: 'Zusammen sind es $fuenf + $zwei. Wie viel ist das?',
            lumo: 'Zusammen: $fuenf + $zwei = ${7 * c}.',
            frage: 7 * c,
            hilfe: 'Rechne erst die Zehner, dann die Einer.',
            auftrag: 'Zähl beide Teile zusammen: $fuenf + $zwei.',
            aktion: feld(7, 7, 0)));
      case 8:
        k.add(kern10(2));
        k.add(_Kern('zuviel',
            kind: '2 Reihen sind zu viel: 2 · $c. Wie viel ist 2 · $c?',
            lumo: '2 Reihen sind zu viel: 2 · $c = $zwei.',
            frage: zwei,
            hilfe: '2 · $c ist das Doppelte: $c + $c.',
            auftrag: '2 Reihen sind zu viel: 2 · $c.',
            aktion: feld(8, 0, 2)));
        k.add(_Kern('weg',
            kind: 'Nimm die 2 Reihen weg: Wie viel ist $zehn − $zwei?',
            lumo: 'Ich nehme die 2 Reihen weg: $zehn − $zwei = ${8 * c}.',
            frage: 8 * c,
            hilfe: 'Geh zuerst bis zum Zehner zurück, dann weiter.',
            auftrag: 'Nimm die 2 Reihen weg: $zehn − $zwei.',
            aktion: feld(8, 8, 0)));
      case 9:
        k.add(kern10(1));
        k.add(_Kern('weg',
            kind:
                'Eine Reihe ist zu viel. Nimm sie weg: Wie viel ist $zehn − $c?',
            lumo:
                'Eine Reihe ist zu viel. Ich nehme sie weg: $zehn − $c = ${9 * c}.',
            frage: 9 * c,
            hilfe: 'Geh von $zehn aus $c zurück.',
            auftrag: 'Eine Reihe ist zu viel. Nimm sie weg: $zehn − $c.',
            aktion: feld(9, 9, 0)));
      default:
        k.add(_Kern('zehner',
            kind:
                'Jede Reihe hat $c Punkte. 10 Reihen sind $c Zehner. Wie viel ist das?',
            lumo: '10 Reihen mit je $c sind $c Zehner: 10 · $c = $zehn.',
            frage: zehn,
            hilfe: '$c Zehner: Hänge an die $c eine 0 an.',
            auftrag: '10 Reihen mit je $c sind $c Zehner.',
            aktion: feld(10, 10, 0)));
    }
    return k;
  }

  // ---------------------------------------------------------------------
  // Stufe 1: kleiner Denkanstoß, konkret mit den Zahlen der Aufgabe.

  String _ankerTipp(int r, int c) => switch (r) {
        1 => '1 · $c ist nur eine einzige Reihe mit $c Punkten.',
        2 => '2 · $c ist das Doppelte von $c: zweimal die $c.',
        3 =>
          '3 · $c sind 3 Reihen mit je $c. Kennst du 2 · $c? Dann kommt noch eine Reihe dazu.',
        4 => '4 · $c ist eine Reihe weniger als 5 · $c. Kennst du 5 · $c?',
        5 => '5 · $c ist die Hälfte von 10 · $c.',
        6 => '6 · $c ist eine Reihe mehr als 5 · $c. Kennst du 5 · $c?',
        7 => '7 · $c sind 5 · $c und noch 2 · $c.',
        8 => '8 · $c sind 2 Reihen weniger als 10 · $c.',
        9 => '9 · $c ist eine Reihe weniger als 10 · $c. Kennst du 10 · $c?',
        _ => '10 · $c sind $c Zehner.',
      };

  String _tippNeu(NachhilfeAufgabe x, NachhilfeWeg w) {
    final a = x.a, b = x.b;
    final az = a ~/ 10, ae = a % 10, bz = b ~/ 10, be = b % 10;
    switch (x.typ) {
      case NachhilfeTyp.additionBis20:
        return _tipp(x, w);
      case NachhilfeTyp.subtraktionBis20:
        if (x.zehnerUebergang) {
          return switch (w) {
            NachhilfeWeg.zahlenstrahl =>
              'Spring zuerst zurück bis zur 10. Wie weit ist das von der $a?',
            NachhilfeWeg.zerlegen =>
              'Teile die $b so, dass du zuerst genau bei 10 ankommst.',
            _ =>
              'Wie viele Perlen musst du unten wegnehmen, damit genau 10 übrig bleiben?',
          };
        }
        if (a > 10) {
          return 'Die volle Zehnerreihe bleibt liegen. Rechne nur unten: ${a - 10} − $b.';
        }
        return w == NachhilfeWeg.zahlenstrahl
            ? 'Stell dich auf die $a und mach $b Sprünge zurück.'
            : 'Schieb $b Perlen zurück und schau, wie viele links bleiben.';
      case NachhilfeTyp.additionBis100:
        if (w == NachhilfeWeg.tauschen) {
          return 'Fang mit der großen Zahl an: ${x.text} ist dasselbe wie $b + $a.';
        }
        if (bz > 0 && be > 0) {
          return 'Zerlegen wir $b in ${10 * bz} und $be. Was passiert, wenn wir zu $a ${_zehnerWort(bz)} dazulegen?';
        }
        if (be == 0) {
          return 'Bei ${x.text} ändert sich nur die Zehnerziffer: Es kommen ${_zehnerWort(bz)} dazu. Die $ae Einer bleiben.';
        }
        if (x.zehnerUebergang) {
          return 'Wie viele Einer fehlen von $a bis zum nächsten Zehner?';
        }
        return 'Die $az Zehner bleiben gleich. Rechne nur die Einer: $ae + $be.';
      case NachhilfeTyp.subtraktionBis100:
        if (bz > 0 && be > 0) {
          return 'Zerlegen wir $b in ${10 * bz} und $be. Was bleibt, wenn wir von $a ${_zehnerWort(bz)} wegnehmen?';
        }
        if (be == 0) {
          return 'Bei ${x.text} ändert sich nur die Zehnerziffer: Es gehen ${_zehnerWort(bz)} weg. Die $ae Einer bleiben.';
        }
        if (x.zehnerUebergang && ae > 0) {
          return 'Geh zuerst zurück bis zum Zehner ${a - ae}. Wie viele Einer sind das?';
        }
        if (x.zehnerUebergang) {
          return '$a hat keine einzelnen Einer. Mach einen Zehner auf: Das sind 10 Einer.';
        }
        return 'Die $az Zehner bleiben gleich. Rechne nur die Einer: $ae − $be.';
      case NachhilfeTyp.einmaleins:
        return switch (w) {
          NachhilfeWeg.tauschen =>
            'Dreh das Punktefeld: $a · $b ist dasselbe wie $b · $a. ${_ankerTipp(b, a)}',
          NachhilfeWeg.punktefeld =>
            '$a · $b heißt: $a Reihen mit je $b Punkten. Zähl Reihe für Reihe in ${b}er-Schritten weiter.',
          _ => _ankerTipp(a, b),
        };
    }
  }

  // ---------------------------------------------------------------------
  // Stufe 2: andere Worte und ein vertrautes Alltagsbeispiel.

  _Alltag _alltag(NachhilfeAufgabe x) {
    final a = x.a, b = x.b;
    final az = a ~/ 10, ae = a % 10, bz = b ~/ 10, be = b % 10;
    final _Alltag roh;
    switch (x.typ) {
      case NachhilfeTyp.additionBis20:
        if (x.zehnerUebergang) {
          roh = _Alltag(
              'Stell dir einen Eierkarton mit 10 Plätzen vor. $a Eier liegen schon drin. Du bekommst noch $b Eier. Zuerst machst du den Karton voll.',
              NachhilfeAktion.bild(NachhilfeMotiv.eierkarton, a: a, b: b),
              frage: 10 - a,
              fragetext: 'Wie viele Eier passen noch in den Karton?',
              hilfe: 'Zähl die leeren Plätze im Karton.');
        } else if (a >= 10) {
          roh = _Alltag(
              'Du hast eine volle Zehnerpackung Stifte und ${a - 10} einzelne. Du bekommst $b Stifte dazu. Die Packung bleibt zu.',
              NachhilfeAktion.bild(NachhilfeMotiv.packung, a: a, b: b),
              frage: a - 10 + b,
              fragetext: 'Wie viele einzelne Stifte hast du dann?',
              hilfe: 'Zähl nur die einzelnen Stifte: ${a - 10} und $b.');
        } else {
          roh = _Alltag(
              'Du hast $a Murmeln in der Hand. Du bekommst $b Murmeln dazu. Zähl von $a aus weiter – nicht wieder bei 1 anfangen.',
              NachhilfeAktion.bild(NachhilfeMotiv.eierkarton, a: a, b: b),
              frage: a + 1,
              fragetext: 'Mit welcher Zahl zählst du nach der $a weiter?',
              hilfe: 'Welche Zahl kommt nach $a?');
        }
      case NachhilfeTyp.subtraktionBis20:
        if (x.zehnerUebergang) {
          roh = _Alltag(
              'Du hast $a Gummibärchen: eine volle Packung mit 10 und ${a - 10} einzelne. Du schenkst $b her. Zuerst gibst du die ${a - 10} einzelnen.',
              NachhilfeAktion.bild(NachhilfeMotiv.packung, a: a, b: -b),
              frage: b - (a - 10),
              fragetext: 'Wie viele musst du dann noch aus der Packung nehmen?',
              hilfe: 'Von den $b hast du schon ${a - 10} hergegeben.');
        } else if (a > 10) {
          roh = _Alltag(
              'Du hast eine volle Zehnerpackung Stifte und ${a - 10} einzelne. Du verschenkst $b einzelne. Die Packung bleibt zu.',
              NachhilfeAktion.bild(NachhilfeMotiv.packung, a: a, b: -b),
              frage: a - 10 - b,
              fragetext: 'Wie viele einzelne Stifte hast du dann noch?',
              hilfe: 'Rechne nur mit den einzelnen Stiften: ${a - 10} − $b.');
        } else {
          roh = _Alltag(
              'Auf dem Teller liegen $a Kekse. Du isst $b davon. Halte $a Finger hoch und klappe $b ein. Die Finger, die noch stehen, sind die Kekse, die übrig bleiben.',
              NachhilfeAktion.bild(NachhilfeMotiv.finger, a: a, b: b));
        }
      case NachhilfeTyp.additionBis100:
        final anfang =
            'Stell dir Geld vor: $a Cent sind ${_muenzenText(az, ae)}. Du bekommst $b Cent dazu: ${_muenzenText(bz, be)}.';
        final bild = NachhilfeAktion.bild(NachhilfeMotiv.muenzen, a: a, b: b);
        if (bz > 0) {
          roh = _Alltag(
              '$anfang Leg zuerst die Zehn-Cent-Münzen zusammen.', bild,
              frage: az + bz,
              fragetext: 'Wie viele Zehn-Cent-Münzen hast du dann?',
              hilfe: '$az Zehn-Cent-Münzen und noch $bz.');
        } else if (x.zehnerUebergang) {
          roh = _Alltag(
              '$anfang 10 Ein-Cent-Münzen kannst du in eine Zehn-Cent-Münze tauschen.',
              bild,
              frage: 10 - ae,
              fragetext: 'Wie viele Ein-Cent-Münzen fehlen dir bis zu 10?',
              hilfe: 'Du hast $ae. Zähl weiter bis 10.');
        } else {
          roh = _Alltag(anfang, bild,
              frage: ae + be,
              fragetext: 'Wie viele Ein-Cent-Münzen hast du dann?',
              hilfe: 'Zähl nur die Ein-Cent-Münzen: $ae und $be.');
        }
      case NachhilfeTyp.subtraktionBis100:
        final anfang =
            'Stell dir Geld vor: Du hast $a Cent – ${_muenzenText(az, ae)}. Du kaufst etwas um $b Cent.';
        final bild = NachhilfeAktion.bild(NachhilfeMotiv.muenzen, a: a, b: -b);
        if (bz > 0) {
          roh = _Alltag(
              '$anfang Zuerst zahlst du mit ${bz == 1 ? 'einer Zehn-Cent-Münze' : '$bz Zehn-Cent-Münzen'}.',
              bild,
              frage: az - bz,
              fragetext: 'Wie viele Zehn-Cent-Münzen hast du dann noch?',
              hilfe: 'Du hattest $az und gibst $bz her.');
        } else if (x.zehnerUebergang) {
          roh = _Alltag(
              '$anfang Du hast zu wenige Ein-Cent-Münzen. Darum wechselst du eine Zehn-Cent-Münze in 10 Ein-Cent-Münzen.',
              bild,
              frage: ae + 10,
              fragetext: 'Wie viele Ein-Cent-Münzen hast du nach dem Wechseln?',
              hilfe: '$ae und noch 10 dazu.');
        } else {
          roh = _Alltag(anfang, bild,
              frage: ae - be,
              fragetext: 'Wie viele Ein-Cent-Münzen bleiben dir?',
              hilfe: 'Rechne nur mit den Ein-Cent-Münzen: $ae − $be.');
        }
      case NachhilfeTyp.einmaleins:
        final r = a, c = b;
        final summe =
            r <= 6 ? List.filled(r, '$c').join(' + ') : '$c + $c + … ($r-mal)';
        final anfang =
            'Auf einem Teller liegen $c Erdbeeren. $r Teller sind $r-mal die $c: $summe.';
        final bild = NachhilfeAktion.bild(NachhilfeMotiv.teller, a: r, b: c);
        roh = switch (r) {
          1 => _Alltag('$anfang Es gibt nur einen Teller.', bild),
          2 => _Alltag('$anfang Das ist das Doppelte von $c.', bild),
          3 => _Alltag(
              '$anfang Zuerst 2 Teller, dann kommt noch einer dazu.', bild,
              frage: 2 * c,
              fragetext: 'Wie viele Erdbeeren sind auf 2 Tellern?',
              hilfe: 'Das Doppelte von $c: $c + $c.'),
          4 => _Alltag(
              '$anfang Denk an 5 Teller und nimm dann einen wieder weg.', bild,
              frage: 5 * c,
              fragetext: 'Wie viele Erdbeeren wären auf 5 Tellern?',
              hilfe: '5 Teller sind die Hälfte von 10 Tellern.'),
          5 => _Alltag('$anfang 5 Teller sind die Hälfte von 10 Tellern.', bild,
              frage: 10 * c,
              fragetext: 'Wie viele Erdbeeren wären auf 10 Tellern?',
              hilfe: '10 Teller mit je $c sind $c Zehner.'),
          6 || 7 => _Alltag(
              '$anfang Zuerst 5 Teller, dann ${r == 6 ? 'noch einer' : 'noch 2'} dazu.',
              bild,
              frage: 5 * c,
              fragetext: 'Wie viele Erdbeeren sind auf 5 Tellern?',
              hilfe: '5 Teller sind die Hälfte von 10 Tellern.'),
          8 || 9 => _Alltag(
              '$anfang Denk an 10 Teller und nimm dann ${r == 9 ? 'einen' : '2'} wieder weg.',
              bild,
              frage: 10 * c,
              fragetext: 'Wie viele Erdbeeren wären auf 10 Tellern?',
              hilfe: '10 Teller mit je $c sind $c Zehner.'),
          _ => _Alltag('$anfang 10 Teller mit je $c sind $c Zehner.', bild),
        };
    }
    if (roh.frage == null || roh.frage != x.ergebnis) return roh;
    // Die Frage dürfte das Ergebnis der Aufgabe nicht vorwegnehmen.
    return _Alltag(roh.text, roh.bild);
  }
}
