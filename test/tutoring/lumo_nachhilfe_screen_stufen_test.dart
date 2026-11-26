import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/tutoring/lumo_nachhilfe.dart';
import 'package:lumo_lernen/domain/tutoring/native_learning_activity.dart';
import 'package:lumo_lernen/features/tutoring/lumo_nachhilfe_screen.dart';
import 'package:lumo_lernen/features/tutoring/nachhilfe_material.dart';

/// Widget-Prüfungen der fünf Hilfestufen in der 2D-Nachhilfe.
Future<void> _zeige(
  WidgetTester tester,
  NachhilfeAufgabe aufgabe, {
  NachhilfeStufe stufe = NachhilfeStufe.hinweis,
  NachhilfeFehlermuster fehler = NachhilfeFehlermuster.keines,
  bool reduceMotion = true,
  double textScale = 1,
  ValueChanged<NachhilfePruefung>? onPruefung,
  Size groesse = const Size(412, 892),
  Future<bool> Function(BuildContext, NativeLearningActivity)? open3D,
}) async {
  await tester.binding.setSurfaceSize(groesse);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
          size: groesse, textScaler: TextScaler.linear(textScale)),
      child: LumoNachhilfeScreen(
        aufgabe: aufgabe,
        startStufe: stufe,
        fehler: fehler,
        reduceMotion: reduceMotion,
        onPruefung: onPruefung,
        open3D: open3D,
      ),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _tippe(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _eintippen(WidgetTester tester, int zahl) async {
  for (final z in '$zahl'.split('')) {
    await _tippe(tester, ValueKey('nachhilfe-ziffer-$z'));
  }
  await _tippe(tester, const ValueKey('nachhilfe-ziffer-ok'));
}

String _sichtbarerText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
    .join('\n');

void main() {
  testWidgets('Stufe 1 Einmaleins: Punktefeld und Denkanstoß ohne Lösung',
      (tester) async {
    final x = NachhilfeAufgabe.mal(6, 7)!;
    await _zeige(tester, x);
    expect(find.byType(NachhilfePunktefeld), findsOneWidget);
    expect(find.text('6 Reihen mit je 7 Punkten'), findsOneWidget);
    await _tippe(tester, const ValueKey('nachhilfe-weiter'));
    expect(find.textContaining('Kennst du 5 · 7?'), findsOneWidget);
    expect(_sichtbarerText(tester), isNot(contains('42')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Stufe 2 Plus bis 20: Eierkarton und eigene Zwischenfrage',
      (tester) async {
    await _zeige(tester, NachhilfeAufgabe.addition(8, 5)!,
        stufe: NachhilfeStufe.andereErklaerung);
    expect(find.byType(NachhilfeBildkarte), findsOneWidget);
    expect(find.textContaining('Eierkarton'), findsOneWidget);
    await _tippe(tester, const ValueKey('nachhilfe-weiter'));
    expect(find.byType(NachhilfeZiffernblock), findsOneWidget);
    await _eintippen(tester, 2);
    expect(find.text('Genau! 2.'), findsOneWidget);
    await _tippe(tester, const ValueKey('nachhilfe-weiter'));
    expect(find.byKey(const ValueKey('nachhilfe-zur-aufgabe')), findsOneWidget);
    expect(_sichtbarerText(tester), isNot(contains('= 13')));
  });

  testWidgets(
      'Stufe 3 Kopfrechnen: Zehnerstangen gleiten sichtbar, nicht sprunghaft',
      (tester) async {
    await _zeige(tester, NachhilfeAufgabe.additionBis100(37, 25)!,
        stufe: NachhilfeStufe.vorzeigen, reduceMotion: false);
    expect(find.byType(NachhilfeStangenFeld), findsOneWidget);
    // Würfel 100 ist der erste Würfel der ersten Zehnerstange von 25.
    final wuerfel = find.byKey(const ValueKey('nachhilfe-wuerfel-100'));
    final vorher = tester.getTopLeft(wuerfel);
    await _tippe(tester, const ValueKey('nachhilfe-weiter'));
    await tester.pump(const Duration(milliseconds: 300));
    final mitte = tester.getTopLeft(wuerfel);
    await tester.pump(const Duration(milliseconds: 800));
    final nachher = tester.getTopLeft(wuerfel);
    expect(mitte, isNot(vorher), reason: 'Der Würfel ist unterwegs.');
    expect(mitte, isNot(nachher), reason: 'Er erscheint nicht sofort am Ziel.');
    expect(nachher.dy, lessThan(vorher.dy),
        reason: 'Die Stange wandert nach oben zu den liegenden Stangen.');
    expect(find.textContaining('36 + 20 = 56'), findsOneWidget,
        reason: 'Lumo zeigt es an einer Zwillingsaufgabe.');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Stufe 4 Einmaleins: Kind tippt 5 · 7 selbst, Lumo wartet, Rest bleibt',
      (tester) async {
    await _zeige(tester, NachhilfeAufgabe.mal(6, 7)!,
        stufe: NachhilfeStufe.teilschritt);
    expect(find.byType(NachhilfeZiffernblock), findsNothing,
        reason: 'Zuerst legt Lumo das Feld hin.');
    await _tippe(tester, const ValueKey('nachhilfe-weiter'));
    expect(find.text('Du bist dran'), findsOneWidget);
    expect(find.byKey(const ValueKey('nachhilfe-weiter')), findsNothing,
        reason: 'Lumo wartet auf die Eingabe des Kindes.');
    final feld =
        tester.widget<NachhilfePunktefeld>(find.byType(NachhilfePunktefeld));
    expect(feld.zustand.wert('markiert'), 0);
    // Falsche Eingabe: Hilfe zum Schritt, Material bleibt stehen.
    await _eintippen(tester, 30);
    expect(find.textContaining('Hälfte von 10 · 7'), findsOneWidget);
    expect(
        tester
            .widget<NachhilfePunktefeld>(find.byType(NachhilfePunktefeld))
            .zustand
            .wert('markiert'),
        0);
    await _eintippen(tester, 35);
    expect(find.text('Genau! 35.'), findsOneWidget);
    expect(
        tester
            .widget<NachhilfePunktefeld>(find.byType(NachhilfePunktefeld))
            .zustand
            .wert('markiert'),
        5);
    await _tippe(tester, const ValueKey('nachhilfe-weiter'));
    expect(find.textContaining('35 + 7'), findsOneWidget);
    expect(find.byKey(const ValueKey('nachhilfe-zur-aufgabe')), findsOneWidget);
    expect(_sichtbarerText(tester), isNot(contains('42')));
  });

  testWidgets('Stufe 4: nach zwei falschen Eingaben zeigt Lumo den Schritt',
      (tester) async {
    await _zeige(tester, NachhilfeAufgabe.subtraktionBis100(62, 25)!,
        stufe: NachhilfeStufe.teilschritt);
    await _tippe(tester, const ValueKey('nachhilfe-weiter'));
    await _eintippen(tester, 40);
    await _eintippen(tester, 44);
    expect(find.textContaining('Ich zeige es dir einmal: 42'), findsOneWidget);
    expect(find.byKey(const ValueKey('nachhilfe-weiter')), findsOneWidget);
    expect(find.text('Es liegen: 42'), findsOneWidget);
  });

  testWidgets('Minus bis 20: Perlen wegschieben, zu viel weg wird gemeldet',
      (tester) async {
    await _zeige(tester, NachhilfeAufgabe.subtraktion(13, 5)!,
        stufe: NachhilfeStufe.teilschritt);
    expect(find.text('Links: 10 + 3 Perlen'), findsOneWidget);
    await _tippe(tester, const ValueKey('nachhilfe-weiter'));
    // Unten alle drei weg: Perle 0 in Reihe 2 antippen.
    await _tippe(tester, const ValueKey('nachhilfe-perle-2-0'));
    expect(find.text('Links: 10 + 0 Perlen'), findsOneWidget);
    expect(find.byKey(const ValueKey('nachhilfe-zur-aufgabe')), findsOneWidget);
    expect(_sichtbarerText(tester), isNot(contains('= 8')));
  });

  testWidgets('Stufe 5: eigenständige Prüfaufgabe zählt nur beim ersten Mal',
      (tester) async {
    final meldungen = <NachhilfePruefung>[];
    final x = NachhilfeAufgabe.subtraktionBis100(62, 25)!;
    await _zeige(tester, x,
        stufe: NachhilfeStufe.ueben, onPruefung: meldungen.add);
    final twin = const LumoNachhilfe()
        .plan(x, NachhilfeWeg.stangen, NachhilfeStufe.ueben)
        .aufgabe;
    expect(find.text('${twin.text} = ?'), findsOneWidget);
    expect(find.text('Prüfaufgabe – ganz allein'), findsOneWidget);
    expect(find.byType(NachhilfeStangenFeld), findsNothing,
        reason: 'Ganz allein: kein Material, keine Schritte.');
    await _eintippen(tester, twin.ergebnis);
    expect(meldungen, hasLength(1));
    expect(meldungen.single.selbststaendig, isTrue);
    expect(meldungen.single.prompt, '${twin.text} = ?');
    expect(
        find.text('Richtig! Das hast du ganz allein gelöst.'), findsOneWidget);
    expect(find.byKey(const ValueKey('nachhilfe-zur-aufgabe')), findsOneWidget);
  });

  testWidgets('Stufe 5: zweimal falsch → ehrlich gemeldet, dann mit Lumo üben',
      (tester) async {
    final meldungen = <NachhilfePruefung>[];
    final x = NachhilfeAufgabe.mal(6, 7)!;
    await _zeige(tester, x,
        stufe: NachhilfeStufe.ueben, onPruefung: meldungen.add);
    final twin = const LumoNachhilfe()
        .plan(x, NachhilfeWeg.kernaufgabe, NachhilfeStufe.ueben)
        .aufgabe;
    await _eintippen(tester, twin.a + twin.b);
    expect(
        find.textContaining('Mal heißt nicht zusammenzählen'), findsOneWidget);
    expect(meldungen, isEmpty);
    await _eintippen(tester, twin.ergebnis + 1);
    expect(meldungen.single.richtig, isFalse);
    expect(meldungen.single.selbststaendig, isFalse);
    await _tippe(tester, const ValueKey('nachhilfe-pruef-mit-lumo'));
    expect(find.byType(NachhilfePunktefeld), findsOneWidget);
    expect(meldungen, hasLength(1), reason: 'Üben mit Lumo zählt nicht.');
  });

  testWidgets('Zahlenstrahl bis 100: Lumo springt in Zehnern, dann zum Zehner',
      (tester) async {
    await _zeige(tester, NachhilfeAufgabe.additionBis100(37, 25)!,
        stufe: NachhilfeStufe.teilschritt);
    await _tippe(tester, const ValueKey('nachhilfe-weg-zahlenstrahl'));
    expect(find.byType(NachhilfeZahlenstrahl), findsOneWidget);
    expect(find.text('Lumo steht auf 37'), findsOneWidget);
    await _tippe(tester, const ValueKey('nachhilfe-weiter'));
    await _eintippen(tester, 57);
    expect(find.text('Lumo steht auf 57'), findsOneWidget);
    await _tippe(tester, const ValueKey('nachhilfe-weiter'));
    await _eintippen(tester, 3);
    expect(find.text('Lumo steht auf 60'), findsOneWidget);
    expect(_sichtbarerText(tester), isNot(contains('62')));
  });

  testWidgets('Tauschaufgabe: das Punktefeld dreht sich', (tester) async {
    await _zeige(tester, NachhilfeAufgabe.mal(7, 5)!,
        stufe: NachhilfeStufe.teilschritt);
    expect(find.text('7 Reihen mit je 5 Punkten'), findsOneWidget);
    await _tippe(tester, const ValueKey('nachhilfe-weiter'));
    expect(find.text('5 Reihen mit je 7 Punkten'), findsOneWidget);
  });

  testWidgets(
      'Hilfeleiter: alle fünf Stufen wählbar, „Mehr Hilfe“ führt weiter',
      (tester) async {
    await _zeige(tester, NachhilfeAufgabe.additionBis100(37, 25)!);
    for (final stufe in NachhilfeStufe.values) {
      expect(find.byKey(ValueKey('nachhilfe-stufe-${stufe.name}')),
          findsOneWidget);
    }
    await _tippe(tester, const ValueKey('nachhilfe-mehr-hilfe'));
    expect(find.textContaining('mit anderen Worten'), findsOneWidget);
  });

  testWidgets('3D nur für Plus bis 20 angeboten', (tester) async {
    Future<bool> open3D(BuildContext c, NativeLearningActivity a) async =>
        false;
    await _zeige(tester, NachhilfeAufgabe.mal(6, 7)!, open3D: open3D);
    expect(find.byKey(const ValueKey('nachhilfe-3d')), findsNothing);
    await _zeige(tester, NachhilfeAufgabe.addition(8, 5)!, open3D: open3D);
    expect(find.byKey(const ValueKey('nachhilfe-3d')), findsOneWidget);
  });

  for (final (name, groesse) in [
    ('Handy 1080×2340', const Size(412, 892)),
    ('Fold innen 2176×1812', const Size(829, 690)),
  ]) {
    testWidgets('$name: Touch-Flächen ≥ 48 dp, große Schrift ohne Überlauf',
        (tester) async {
      for (final (x, stufe) in [
        (NachhilfeAufgabe.mal(6, 7)!, NachhilfeStufe.teilschritt),
        (NachhilfeAufgabe.additionBis100(37, 25)!, NachhilfeStufe.vorzeigen),
        (NachhilfeAufgabe.subtraktion(13, 5)!, NachhilfeStufe.andereErklaerung),
        (NachhilfeAufgabe.subtraktionBis100(62, 25)!, NachhilfeStufe.ueben),
      ]) {
        await _zeige(tester, x, stufe: stufe, textScale: 1.6, groesse: groesse);
        await _tippe(tester, ValueKey('nachhilfe-stufe-${stufe.name}'));
        if (find
            .byKey(const ValueKey('nachhilfe-weiter'))
            .evaluate()
            .isNotEmpty) {
          await _tippe(tester, const ValueKey('nachhilfe-weiter'));
        }
        expect(tester.takeException(), isNull, reason: '${x.text} $stufe');
        for (final type in [
          FilledButton,
          OutlinedButton,
          ChoiceChip,
          IconButton,
          InkResponse,
        ]) {
          for (final element in find.byType(type).evaluate()) {
            final size = tester.getSize(find.byWidget(element.widget));
            expect(size.width, greaterThanOrEqualTo(48),
                reason: '$type ${x.text}');
            expect(size.height, greaterThanOrEqualTo(48),
                reason: '$type ${x.text}');
          }
        }
      }
    });
  }

  testWidgets('Muster aus dem Verlauf wählt still den Weg, ohne Rückmeldung',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: LumoNachhilfeScreen(
        aufgabe: NachhilfeAufgabe.additionBis100(37, 25)!,
        startWeg: NachhilfeWeg.zahlenstrahl,
        reduceMotion: true,
        lernstandSatz:
            'Ich zeige dir gleich einen Weg, der bei solchen Aufgaben gut hilft.',
      ),
    ));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(NachhilfeZahlenstrahl), findsOneWidget);
    expect(find.byKey(const ValueKey('nachhilfe-rueckmeldung')), findsNothing);
    expect(find.byKey(const ValueKey('nachhilfe-lernstand')), findsOneWidget);
  });
}
