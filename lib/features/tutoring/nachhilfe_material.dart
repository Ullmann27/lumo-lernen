import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/tutoring/lumo_nachhilfe.dart';

/// Anschauungsmaterial der Lumo-Nachhilfe.
///
/// Jeder Würfel, jeder Punkt und Lumo auf dem Zahlenstrahl behält seine
/// Identität und gleitet sichtbar an den neuen Platz, statt plötzlich im
/// neuen Zustand zu erscheinen. Mit [reduceMotion] (Elterneinstellung oder
/// System) springt das Material ohne Animation.

const _blau = Color(0xFF3C8DFF);
const _blauHell = Color(0xFF9CC8FF);
const _gold = Color(0xFFFFB938);
const _goldHell = Color(0xFFFFE08A);
const _text =
    TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800);
const _klein = TextStyle(
    color: Color(0xFFB4D7E9), fontSize: 16, fontWeight: FontWeight.w700);

Duration _dauer(bool reduceMotion, [int extraMs = 0]) =>
    reduceMotion ? Duration.zero : Duration(milliseconds: 650 + extraMs);

// ---------------------------------------------------------------------------
// Zehnerstangen und Einerwürfel

/// Platz eines Würfels: Bereich (0 liegt da, 1 daneben/dazu, 2 weggenommen),
/// Spalte und Zeile in Würfeleinheiten.
@visibleForTesting
class WuerfelPlatz {
  const WuerfelPlatz(this.bereich, this.spalte, this.zeile,
      {this.inStange = false});
  final int bereich;
  final double spalte;
  final double zeile;
  final bool inStange;

  @override
  bool operator ==(Object other) =>
      other is WuerfelPlatz &&
      other.bereich == bereich &&
      other.spalte == spalte &&
      other.zeile == zeile &&
      other.inStange == inStange;

  @override
  int get hashCode => Object.hash(bereich, spalte, zeile, inStange);
}

/// Ordnet jedem Würfel der Aufgabe a ± b einen festen Platz zu. Würfel
/// 0 … a−1 gehören zur ersten Zahl, ab 100 zur zweiten Zahl. Der Zustand ist
/// absolut ([NachhilfeAktion.stangen]); dieselbe Zuordnung in jedem Schritt
/// sorgt dafür, dass genau die bewegten Würfel wandern.
@visibleForTesting
Map<int, WuerfelPlatz> wuerfelPlaetze(
    {required int a,
    required int b,
    required bool minus,
    required NachhilfeAktion zustand}) {
  final plaetze = <int, WuerfelPlatz>{};
  final hz = zustand.wert('zehner'), he = zustand.wert('einer');
  final r0 = a ~/ 10, l0 = a % 10;
  WuerfelPlatz einzeln(int bereich, int index, double versatz) => WuerfelPlatz(
      bereich, versatz + (index % 5) * 1.15, 4 + (index ~/ 5) * 1.15);
  final hauptStangen = <List<int>>[];
  final pool = <int>[];
  if (!minus) {
    final bz = b ~/ 10, be = b % 10;
    final dz = zustand.wert('dazuZehner'), de = zustand.wert('dazuEiner');
    final bewegtStangen = bz - dz, bewegtEiner = be - de;
    for (var r = 0; r < r0; r++) {
      hauptStangen.add([for (var j = 0; j < 10; j++) 10 * r + j]);
    }
    for (var r = 0; r < bewegtStangen; r++) {
      hauptStangen.add([for (var j = 0; j < 10; j++) 100 + 10 * r + j]);
    }
    pool.addAll([for (var j = 0; j < l0; j++) 10 * r0 + j]);
    pool.addAll([for (var j = 0; j < bewegtEiner; j++) 100 + 10 * bz + j]);
    final gebuendelt = math.max(0, hz - hauptStangen.length);
    for (var g = 0; g < gebuendelt && pool.length >= 10; g++) {
      hauptStangen.add(pool.sublist(0, 10));
      pool.removeRange(0, 10);
    }
    // Was noch daneben liegt (zweite Zahl).
    for (var r = bewegtStangen; r < bz; r++) {
      for (var j = 0; j < 10; j++) {
        plaetze[100 + 10 * r + j] = WuerfelPlatz(
            1, (r - bewegtStangen) * 1.3, j.toDouble(),
            inStange: true);
      }
    }
    final dazuVersatz = (bz - bewegtStangen) * 1.3 + (dz > 0 ? 0.6 : 0);
    for (var j = bewegtEiner; j < be; j++) {
      plaetze[100 + 10 * bz + j] = einzeln(1, j - bewegtEiner, dazuVersatz);
    }
  } else {
    final wz = zustand.wert('wegZehner'), we = zustand.wert('wegEiner');
    final aufgemacht = math.max(0, r0 - wz - hz);
    final stangen = [
      for (var r = 0; r < r0; r++) [for (var j = 0; j < 10; j++) 10 * r + j]
    ];
    // Weggenommene Stangen: die letzten; aufgemacht wird die davor.
    for (var r = 0; r < hz; r++) {
      hauptStangen.add(stangen[r]);
    }
    for (var w = 0; w < wz; w++) {
      final stange = stangen[r0 - 1 - w];
      for (var j = 0; j < 10; j++) {
        plaetze[stange[j]] =
            WuerfelPlatz(2, w * 1.3, j.toDouble(), inStange: true);
      }
    }
    pool.addAll([for (var j = 0; j < l0; j++) 10 * r0 + j]);
    for (var u = 0; u < aufgemacht; u++) {
      pool.addAll(stangen[r0 - wz - 1 - u]);
    }
    final weg = pool.take(we).toList();
    pool.removeRange(0, math.min(we, pool.length));
    final wegVersatz = wz * 1.3 + (wz > 0 ? 0.6 : 0);
    for (var i = 0; i < weg.length; i++) {
      plaetze[weg[i]] = einzeln(2, i, wegVersatz);
    }
  }
  for (var s = 0; s < hauptStangen.length; s++) {
    for (var j = 0; j < hauptStangen[s].length; j++) {
      plaetze[hauptStangen[s][j]] =
          WuerfelPlatz(0, s * 1.3, j.toDouble(), inStange: true);
    }
  }
  final einerVersatz = hauptStangen.length * 1.3 + 0.6;
  for (var i = 0; i < pool.length && i < he + 10; i++) {
    plaetze[pool[i]] = einzeln(0, i, einerVersatz);
  }
  return plaetze;
}

class NachhilfeStangenFeld extends StatelessWidget {
  const NachhilfeStangenFeld({
    super.key,
    required this.aufgabe,
    required this.zustand,
    this.reduceMotion = false,
  });

  final NachhilfeAufgabe aufgabe;
  final NachhilfeAktion zustand;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final minus = aufgabe.typ.istMinus;
    final plaetze = wuerfelPlaetze(
        a: aufgabe.a, b: aufgabe.b, minus: minus, zustand: zustand);
    final hz = zustand.wert('zehner'), he = zustand.wert('einer');
    final dz = zustand.wert('dazuZehner'), de = zustand.wert('dazuEiner');
    final wz = zustand.wert('wegZehner'), we = zustand.wert('wegEiner');
    final liegt = 10 * hz + he;
    final zweiter = minus ? 10 * wz + we : 10 * dz + de;
    return LayoutBuilder(builder: (context, constraints) {
      final breite = constraints.maxWidth;
      // 10 Stangen + Abstand + 5 Einer passen in eine Zeile.
      final w = (breite / 20.5).clamp(11.0, 26.0);
      final band = 10 * w + 8;
      // Ohne Zehner in der zweiten Zahl reicht unten ein schmaler Streifen.
      final kurz = aufgabe.b < 10;
      final unten = kurz ? 2.5 * w + 8 : band;
      final unterTitel = minus ? 'Weggenommen: $zweiter' : 'Daneben: $zweiter';
      final hoehe = 30 + band + 34 + unten;
      return Semantics(
        label: minus
            ? 'Es liegen $hz Zehnerstangen und $he Einerwürfel. Weggenommen: $zweiter.'
            : 'Es liegen $hz Zehnerstangen und $he Einerwürfel. Daneben liegen noch $zweiter.',
        child: SizedBox(
          height: hoehe,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned(
              left: 0,
              top: 0,
              child: Text('Es liegen: $liegt',
                  key: const ValueKey('nachhilfe-stangen-stand'), style: _text),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 30 + band + 6,
              child: Container(height: 2, color: const Color(0x553B7FA6)),
            ),
            Positioned(
              left: 0,
              top: 30 + band + 10,
              child: Text(unterTitel, style: _klein),
            ),
            for (final eintrag in plaetze.entries)
              AnimatedPositioned(
                key: ValueKey('nachhilfe-wuerfel-${eintrag.key}'),
                duration: _dauer(reduceMotion, (eintrag.key % 10) * 18),
                curve: Curves.easeInOutCubic,
                left: eintrag.value.spalte * w,
                top: eintrag.value.bereich == 0
                    ? 30 + eintrag.value.zeile * w
                    : 30 +
                        band +
                        34 +
                        (kurz && !eintrag.value.inStange
                                ? eintrag.value.zeile - 4
                                : eintrag.value.zeile) *
                            w,
                width: w,
                height: w,
                child: AnimatedOpacity(
                  duration: _dauer(reduceMotion),
                  opacity: eintrag.value.bereich == 2 ? 0.6 : 1,
                  child: _Wuerfel(
                    farbe: eintrag.value.bereich == 2
                        ? const Color(0xFF8DA3B8)
                        : eintrag.key >= 100
                            ? _gold
                            : _blau,
                    inStange: eintrag.value.inStange,
                  ),
                ),
              ),
          ]),
        ),
      );
    });
  }
}

class _Wuerfel extends StatelessWidget {
  const _Wuerfel({required this.farbe, required this.inStange});
  final Color farbe;
  final bool inStange;

  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsets.all(inStange ? 0.5 : 1.5),
        decoration: BoxDecoration(
          color: farbe,
          borderRadius: BorderRadius.circular(inStange ? 2 : 4),
          border: Border.all(color: const Color(0x99FFFFFF), width: 1),
          boxShadow: const [
            BoxShadow(
                color: Color(0x55000000), blurRadius: 2, offset: Offset(0, 1))
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// Zahlenstrahl bis 100

/// Zahlenstrahl mit Bögen für jeden Sprung. Der neueste Bogen wird sichtbar
/// gezeichnet, Lumo gleitet mit.
class NachhilfeZahlenstrahl extends StatelessWidget {
  const NachhilfeZahlenstrahl({
    super.key,
    required this.von,
    required this.bis,
    required this.position,
    required this.spruenge,
    this.reduceMotion = false,
  });

  /// Sichtbarer Bereich (auf Zehner gerundet).
  final int von;
  final int bis;
  final int position;
  final List<(int, int)> spruenge;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final breite = constraints.maxWidth;
      const rand = 18.0;
      final schritt = (breite - 2 * rand) / math.max(1, bis - von);
      double x(int zahl) => rand + (zahl - von) * schritt;
      return Semantics(
        label: 'Zahlenstrahl von $von bis $bis. Lumo steht auf $position.',
        child: SizedBox(
          height: 204,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                key: ValueKey('nachhilfe-bogen-${spruenge.length}'),
                tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
                duration: _dauer(reduceMotion, 150),
                curve: Curves.easeInOut,
                builder: (context, t, _) => CustomPaint(
                  painter: _StrahlMaler(
                      von: von,
                      bis: bis,
                      spruenge: spruenge,
                      fortschritt: t,
                      x: x),
                ),
              ),
            ),
            AnimatedPositioned(
              key: const ValueKey('nachhilfe-strahl-lumo'),
              duration: _dauer(reduceMotion, 150),
              curve: Curves.easeInOutCubic,
              left: x(position) - 16,
              top: 146,
              child: const Icon(Icons.pets_rounded,
                  color: Color(0xFFFF9F43), size: 32),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Text('Lumo steht auf $position',
                  key: const ValueKey('nachhilfe-strahl-stand'),
                  textAlign: TextAlign.center,
                  style: _text),
            ),
          ]),
        ),
      );
    });
  }
}

class _StrahlMaler extends CustomPainter {
  _StrahlMaler({
    required this.von,
    required this.bis,
    required this.spruenge,
    required this.fortschritt,
    required this.x,
  });

  final int von;
  final int bis;
  final List<(int, int)> spruenge;
  final double fortschritt;
  final double Function(int) x;

  @override
  void paint(Canvas canvas, Size size) {
    const linieY = 96.0;
    final linie = Paint()
      ..color = const Color(0xFFB7C7D6)
      ..strokeWidth = 3;
    canvas.drawLine(Offset(x(von), linieY), Offset(x(bis), linieY), linie);
    for (var z = von; z <= bis; z++) {
      final zehner = z % 10 == 0;
      final funf = z % 5 == 0;
      canvas.drawLine(
          Offset(
              x(z),
              linieY -
                  (zehner
                      ? 12
                      : funf
                          ? 8
                          : 5)),
          Offset(
              x(z),
              linieY +
                  (zehner
                      ? 12
                      : funf
                          ? 8
                          : 5)),
          linie..strokeWidth = zehner ? 3 : 1.5);
    }
    final beschriftet = <int>{
      for (var z = von; z <= bis; z++)
        if (z % 10 == 0) z,
      for (final s in spruenge) ...[s.$1, s.$2],
    };
    for (final z in beschriftet) {
      final tp = TextPainter(
        text: TextSpan(
            text: '$z',
            style: TextStyle(
                fontFamily: 'Nunito',
                color: z % 10 == 0 ? Colors.white : _goldHell,
                fontSize: 15,
                fontWeight: FontWeight.w800)),
        textDirection: TextDirection.ltr,
      )..layout();
      // Zehner in der ersten Zeile, Sprungziele darunter: nichts überlappt.
      tp.paint(canvas,
          Offset(x(z) - tp.width / 2, linieY + (z % 10 == 0 ? 14 : 32)));
    }
    for (var i = 0; i < spruenge.length; i++) {
      final (a, b) = spruenge[i];
      if (a == b) continue;
      final t = i == spruenge.length - 1 ? fortschritt : 1.0;
      final start = x(a), ende = x(b);
      final hoehe = math.min(46.0, 14 + (ende - start).abs() * 0.35);
      final bogen = Path()..moveTo(start, linieY);
      bogen.quadraticBezierTo(
          (start + ende) / 2, linieY - 2 * hoehe, ende, linieY);
      final metrik = bogen.computeMetrics().first;
      canvas.drawPath(
          metrik.extractPath(0, metrik.length * t),
          Paint()
            ..color = (b - a).abs() >= 10 ? _blauHell : _goldHell
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5
            ..strokeCap = StrokeCap.round);
      if (t > 0.6) {
        final tp = TextPainter(
          text: TextSpan(
              text: b > a ? '+${b - a}' : '−${a - b}',
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas,
            Offset((start + ende) / 2 - tp.width / 2, linieY - hoehe - 20));
      }
    }
  }

  @override
  bool shouldRepaint(_StrahlMaler old) =>
      old.fortschritt != fortschritt ||
      old.spruenge.length != spruenge.length ||
      old.von != von ||
      old.bis != bis;
}

// ---------------------------------------------------------------------------
// Punktefeld

/// Punktefeld fürs Einmaleins: Reihen gleiten herein, der bekannte Teil wird
/// blau, gedachte Reihen erscheinen gestrichelt, beim Drehen wandert jeder
/// Punkt an seinen neuen Platz.
class NachhilfePunktefeld extends StatelessWidget {
  const NachhilfePunktefeld(
      {super.key, required this.zustand, this.reduceMotion = false});

  final NachhilfeAktion zustand;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final r = zustand.wert('zeilen'), c = zustand.wert('spalten');
    final gedreht = zustand.wert('gedreht') == 1;
    final reihen = gedreht ? c : r, je = gedreht ? r : c;
    final sichtbar = zustand.wert('sichtbar');
    final markiert = zustand.wert('markiert');
    final geister = zustand.wert('geister');
    return LayoutBuilder(builder: (context, constraints) {
      final groesste = math.max(r, c);
      final zelle =
          math.min(34.0, (constraints.maxWidth - 8) / math.max(10, groesste));
      // Das Feld steht in der Mitte; beim Drehen wandert es mit.
      final mitte = (math.max(10, groesste) - je) * zelle / 2;
      final feldHoehe = math.max(groesste, reihen + geister) * zelle;
      return Semantics(
        label: '$reihen Reihen mit je $je Punkten'
            '${markiert > 0 && markiert < reihen ? ', $markiert Reihen sind blau' : ''}',
        child: Column(children: [
          Text(
              '$reihen ${reihen == 1 ? 'Reihe' : 'Reihen'} mit je $je ${je == 1 ? 'Punkt' : 'Punkten'}',
              key: const ValueKey('nachhilfe-punkte-stand'),
              style: _text),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: _dauer(reduceMotion),
            height: feldHoehe,
            width: zelle * math.max(10, groesste),
            child: Stack(clipBehavior: Clip.none, children: [
              for (var g = 0; g < 10 - reihen && g < 10; g++)
                for (var j = 0; j < je; j++)
                  Positioned(
                    key: ValueKey('nachhilfe-geist-$g-$j'),
                    left: mitte + j * zelle,
                    top: (reihen + g) * zelle,
                    width: zelle,
                    height: zelle,
                    child: AnimatedOpacity(
                      duration: _dauer(reduceMotion),
                      opacity: g < geister ? 1 : 0,
                      child: Center(
                        child: Container(
                          width: zelle * 0.66,
                          height: zelle * 0.66,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xAA9CC8FF), width: 2),
                          ),
                        ),
                      ),
                    ),
                  ),
              for (var i = 0; i < r; i++)
                for (var j = 0; j < c; j++)
                  _punkt(i, j, r, gedreht, sichtbar, markiert, zelle, mitte),
              if (markiert > 0 && markiert < sichtbar)
                AnimatedPositioned(
                  key: const ValueKey('nachhilfe-punkte-trenner'),
                  duration: _dauer(reduceMotion),
                  left: mitte - 4,
                  top: markiert * zelle - 1.5,
                  width: je * zelle + 8,
                  height: 3,
                  child: Container(color: _goldHell),
                ),
            ]),
          ),
        ]),
      );
    });
  }

  Widget _punkt(int i, int j, int r, bool gedreht, int sichtbar, int markiert,
      double zelle, double mitte) {
    final zeile = gedreht ? j : i;
    final spalte = gedreht ? r - 1 - i : j;
    final da = zeile < sichtbar;
    final blau = zeile < markiert;
    return AnimatedPositioned(
      key: ValueKey('nachhilfe-punkt-$i-$j'),
      duration: _dauer(reduceMotion, (zeile * 40).clamp(0, 400)),
      curve: Curves.easeInOutCubic,
      left: mitte + (da ? spalte : spalte - 1.5) * zelle,
      top: zeile * zelle,
      width: zelle,
      height: zelle,
      child: AnimatedOpacity(
        duration: _dauer(reduceMotion),
        opacity: da ? 1 : 0,
        child: Center(
          child: AnimatedContainer(
            duration: _dauer(reduceMotion),
            width: zelle * 0.74,
            height: zelle * 0.74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.35, -0.4),
                colors: blau
                    ? const [Color(0xFFBFE0FF), _blau]
                    : const [Color(0xFFFFE6A8), Color(0xFFF08A24)],
              ),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x55000000),
                    blurRadius: 3,
                    offset: Offset(0, 1))
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Alltagsbild der anderen Erklärung

class NachhilfeBildkarte extends StatelessWidget {
  const NachhilfeBildkarte(
      {super.key, required this.bild, this.reduceMotion = false});

  final NachhilfeAktion bild;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final motiv = NachhilfeMotiv
        .values[bild.wert('motiv').clamp(0, NachhilfeMotiv.values.length - 1)];
    final a = bild.wert('a'), b = bild.wert('b');
    final Widget inhalt = switch (motiv) {
      NachhilfeMotiv.eierkarton => _eierkarton(a, b),
      NachhilfeMotiv.packung => _packung(a, b),
      NachhilfeMotiv.muenzen => _muenzen(a, b),
      NachhilfeMotiv.teller => _teller(a, b),
      NachhilfeMotiv.finger => _finger(a, b),
    };
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduceMotion ? 1 : 0.85, end: 1),
      duration: _dauer(reduceMotion),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: Semantics(
        label: switch (motiv) {
          NachhilfeMotiv.eierkarton =>
            'Eierkarton mit $a Eiern, daneben $b Eier',
          NachhilfeMotiv.packung => 'Zehnerpackung und einzelne Stücke',
          NachhilfeMotiv.muenzen => 'Zehn-Cent-Münzen und Ein-Cent-Münzen',
          NachhilfeMotiv.teller => '$a Teller mit je $b Erdbeeren',
          NachhilfeMotiv.finger => '$a Finger, $b davon eingeklappt',
        },
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6), child: inhalt),
      ),
    );
  }

  Widget _ei(Color farbe, double g) => Container(
        width: g * 0.72,
        height: g * 0.9,
        decoration: BoxDecoration(
          color: farbe,
          borderRadius: BorderRadius.all(Radius.elliptical(g * 0.36, g * 0.45)),
          boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 2)],
        ),
      );

  Widget _eierkarton(int a, int b) {
    const g = 34.0;
    final drin = math.min(a, 10);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 18,
      runSpacing: 10,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFB98A5E),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: [
            for (var reihe = 0; reihe < 2; reihe++)
              Row(mainAxisSize: MainAxisSize.min, children: [
                for (var i = 0; i < 5; i++)
                  Container(
                    width: g,
                    height: g,
                    margin: const EdgeInsets.all(2),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8C6239),
                      borderRadius: BorderRadius.circular(g / 2),
                    ),
                    child: reihe * 5 + i < drin
                        ? _ei(const Color(0xFFFFF4E0), g)
                        : null,
                  ),
              ]),
          ]),
        ),
        Wrap(spacing: 4, runSpacing: 4, children: [
          for (var i = 0; i < b; i++) _ei(_goldHell, g),
        ]),
      ],
    );
  }

  Widget _stueck(Color farbe, {bool weg = false}) => Container(
        width: 14,
        height: 40,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: weg ? farbe.withValues(alpha: 0.35) : farbe,
          borderRadius: BorderRadius.circular(5),
          border:
              weg ? Border.all(color: const Color(0xFFFF8A80), width: 2) : null,
        ),
      );

  Widget _packung(int a, int b) {
    final einzeln = a - 10;
    final minus = b < 0;
    final menge = b.abs();
    return Column(children: [
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Container(
            width: 96,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF7A5CFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Text('10',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900)),
          ),
          Wrap(children: [
            for (var i = 0; i < einzeln; i++) _stueck(const Color(0xFF73D4ED)),
          ]),
        ],
      ),
      const SizedBox(height: 8),
      Text(minus ? 'Weg kommen: $menge' : 'Dazu kommen: $menge', style: _klein),
      const SizedBox(height: 4),
      Wrap(alignment: WrapAlignment.center, children: [
        for (var i = 0; i < menge; i++) _stueck(_gold, weg: minus),
      ]),
    ]);
  }

  Widget _muenze(int wert) => Container(
        width: wert == 10 ? 46 : 32,
        height: wert == 10 ? 46 : 32,
        margin: const EdgeInsets.all(3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.4),
            colors: wert == 10
                ? const [Color(0xFFFFF0A8), Color(0xFFD9A400)]
                : const [Color(0xFFFFC7A0), Color(0xFFB8642E)],
          ),
          border: Border.all(color: const Color(0x88FFFFFF), width: 2),
        ),
        child: Text('$wert',
            style: TextStyle(
                color: const Color(0xFF3B2600),
                fontSize: wert == 10 ? 18 : 15,
                fontWeight: FontWeight.w900)),
      );

  Widget _muenzen(int a, int b) {
    Widget reihe(int betrag) =>
        Wrap(alignment: WrapAlignment.center, children: [
          for (var i = 0; i < betrag ~/ 10; i++) _muenze(10),
          for (var i = 0; i < betrag % 10; i++) _muenze(1),
        ]);
    return Column(children: [
      Text('Du hast $a Cent', style: _klein),
      reihe(a),
      const SizedBox(height: 6),
      Text(b < 0 ? 'Du zahlst ${-b} Cent' : 'Du bekommst $b Cent',
          style: _klein),
      if (b > 0) reihe(b),
    ]);
  }

  Widget _teller(int r, int c) => Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var t = 0; t < r; t++)
            Container(
              width: 74,
              height: 74,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: const Color(0xFFCFE3F0), width: 4),
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                spacing: 2,
                runSpacing: 2,
                children: [
                  for (var i = 0; i < c; i++)
                    Container(
                      width: 10,
                      height: 11,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE53935),
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(3),
                            bottom: Radius.circular(6)),
                      ),
                    ),
                ],
              ),
            ),
        ],
      );

  Widget _finger(int a, int b) => Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        children: [
          for (var i = 0; i < a; i++)
            AnimatedContainer(
              duration: _dauer(reduceMotion, i * 30),
              width: 22,
              height: i >= a - b ? 26 : 64,
              decoration: BoxDecoration(
                color: i >= a - b
                    ? const Color(0xFF8A7765)
                    : const Color(0xFFFFCFA8),
                borderRadius: BorderRadius.circular(11),
              ),
            ),
        ],
      );
}

// ---------------------------------------------------------------------------
// Ziffernblock für Zwischenschritte

/// Große Zifferntasten (mindestens 56 × 56 dp) für Eingaben bis 100.
class NachhilfeZiffernblock extends StatelessWidget {
  const NachhilfeZiffernblock({
    super.key,
    required this.eingabe,
    required this.onZiffer,
    required this.onLoeschen,
    required this.onFertig,
    this.kompakt = false,
  });

  /// Handy: zwei Reihen mit je sechs Tasten statt vier Reihen.
  final bool kompakt;
  final String eingabe;
  final ValueChanged<int> onZiffer;
  final VoidCallback onLoeschen;
  final VoidCallback onFertig;

  @override
  Widget build(BuildContext context) {
    Widget taste(String text, VoidCallback? onTap,
            {Key? key,
            Color farbe = const Color(0xFF1D415B),
            IconData? icon,
            String? hinweis}) =>
        Padding(
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            width: kompakt ? 54 : 72,
            height: kompakt ? 56 : 60,
            child: FilledButton(
              key: key,
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: farbe,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: icon != null
                  ? Icon(icon, size: 30, semanticLabel: hinweis)
                  : Text(text,
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w900)),
            ),
          ),
        );
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        key: const ValueKey('nachhilfe-eingabe'),
        width: 150,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F9FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _gold, width: 3),
        ),
        child: Text(eingabe.isEmpty ? '?' : eingabe,
            style: const TextStyle(
                color: Color(0xFF12366A),
                fontSize: 34,
                fontWeight: FontWeight.w900)),
      ),
      const SizedBox(height: 8),
      ...() {
        Widget ziffer(int z) => taste('$z', () => onZiffer(z),
            key: ValueKey('nachhilfe-ziffer-$z'));
        final loeschen = taste('', eingabe.isEmpty ? null : onLoeschen,
            key: const ValueKey('nachhilfe-ziffer-loeschen'),
            icon: Icons.backspace_rounded,
            hinweis: 'Löschen');
        final fertig = taste('', eingabe.isEmpty ? null : onFertig,
            key: const ValueKey('nachhilfe-ziffer-ok'),
            farbe: const Color(0xFF2E9E62),
            icon: Icons.check_rounded,
            hinweis: 'Fertig');
        final reihen = kompakt
            ? [
                [for (var z = 1; z <= 6; z++) ziffer(z)],
                [ziffer(7), ziffer(8), ziffer(9), ziffer(0), loeschen, fertig],
              ]
            : [
                [ziffer(1), ziffer(2), ziffer(3)],
                [ziffer(4), ziffer(5), ziffer(6)],
                [ziffer(7), ziffer(8), ziffer(9)],
                [loeschen, ziffer(0), fertig],
              ];
        return [
          for (final reihe in reihen)
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, children: reihe),
            ),
        ];
      }(),
    ]);
  }
}
