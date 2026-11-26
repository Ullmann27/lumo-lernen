import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/tutoring/lumo_nachhilfe.dart';
import 'package:lumo_lernen/features/tutoring/nachhilfe_material.dart';

/// Zehnerstangen-Material: In jedem Schritt jedes Plans liegt jeder Würfel an
/// genau einem Platz, und die Bereiche zählen genau den Zustand.
void main() {
  const tutor = LumoNachhilfe();

  void pruefe(NachhilfeAufgabe feld, NachhilfeAktion zustand, String label) {
    final minus = feld.typ.istMinus;
    final plaetze =
        wuerfelPlaetze(a: feld.a, b: feld.b, minus: minus, zustand: zustand);
    int zaehle(int bereich) =>
        plaetze.values.where((p) => p.bereich == bereich).length;
    expect(zaehle(0), 10 * zustand.wert('zehner') + zustand.wert('einer'),
        reason: label);
    if (minus) {
      expect(
          zaehle(2), 10 * zustand.wert('wegZehner') + zustand.wert('wegEiner'),
          reason: label);
      expect(plaetze.length, feld.a, reason: label);
    } else {
      expect(zaehle(1),
          10 * zustand.wert('dazuZehner') + zustand.wert('dazuEiner'),
          reason: label);
      expect(plaetze.length, feld.a + feld.b, reason: label);
    }
    final belegt = <String>{};
    for (final p in plaetze.values) {
      expect(belegt.add('${p.bereich} ${p.spalte} ${p.zeile}'), isTrue,
          reason: '$label: zwei Würfel auf demselben Platz');
    }
  }

  test('alle Kopfrechenaufgaben bis 100: Würfel gehen nie verloren', () {
    var geprueft = 0;
    for (var a = 1; a <= 100; a++) {
      for (var b = 1; b <= 100; b++) {
        final x = NachhilfeAufgabe.additionBis100(a, b) ??
            NachhilfeAufgabe.subtraktionBis100(a, b);
        if (x == null) continue;
        for (final weg in tutor.wegeFuer(x)) {
          if (weg == NachhilfeWeg.zahlenstrahl) continue;
          for (final stufe in [
            NachhilfeStufe.hinweis,
            NachhilfeStufe.vorzeigen,
            NachhilfeStufe.teilschritt,
          ]) {
            final plan = tutor.plan(x, weg, stufe);
            final feld = weg == NachhilfeWeg.tauschen
                ? NachhilfeAufgabe.additionBis100(
                    plan.aufgabe.b, plan.aufgabe.a)!
                : plan.aufgabe;
            for (final s in plan.schritte) {
              if (s.aktion.art != 'stangen') continue;
              pruefe(feld, s.aktion, '${x.text} ${weg.name} ${s.id}');
              geprueft++;
            }
          }
        }
      }
    }
    expect(geprueft, greaterThan(10000));
  });

  test('Bündeln: aus zehn Einern wird eine Stange, dieselben Würfel', () {
    final x = NachhilfeAufgabe.additionBis100(37, 25)!;
    final plan =
        tutor.plan(x, NachhilfeWeg.stangen, NachhilfeStufe.teilschritt);
    final vorher = plan.schritte.firstWhere((s) => s.id == 'bisZehn').aktion;
    final nachher = plan.schritte.firstWhere((s) => s.id == 'buendeln').aktion;
    final p1 = wuerfelPlaetze(a: 37, b: 25, minus: false, zustand: vorher);
    final p2 = wuerfelPlaetze(a: 37, b: 25, minus: false, zustand: nachher);
    final lose = [
      for (final e in p1.entries)
        if (e.value.bereich == 0 && !e.value.inStange) e.key
    ];
    expect(lose, hasLength(10));
    for (final id in lose) {
      expect(p2[id]!.inStange, isTrue,
          reason: 'Würfel $id wandert in die neue Stange');
    }
  });
}
