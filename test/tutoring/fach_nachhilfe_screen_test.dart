import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/tutoring/fach_nachhilfe.dart';
import 'package:lumo_lernen/domain/tutoring/lumo_nachhilfe.dart';
import 'package:lumo_lernen/features/tutoring/fach_nachhilfe_screen.dart';

/// Fach-Nachhilfe-Seite: fünf Stufen, Ausschließen bestätigt nie die Lösung,
/// die Prüfaufgabe wird genau einmal gemeldet, nach einer nicht gelösten
/// Prüfaufgabe erklärt Lumo es anders. Englisch: keine englischen Wörter in
/// der deutschen Stimme. Lesen: langsames Vorlesen.
FachAufgabe _en(String wort, String bedeutung, List<String> auswahl) =>
    FachAufgabe.aus(
        fach: 'Englisch',
        thema: 'Tiere',
        prompt: 'Was bedeutet „$wort“?',
        antwort: bedeutung,
        auswahl: auswahl,
        erklaerung: 'Das englische Wort „$wort“ bedeutet $bedeutung.')!;

final _horse = _en('horse', 'Pferd', ['Küken', 'Esel', 'Pferd', 'Fisch']);
final _cow = _en('cow', 'Kuh', ['Kuh', 'Hund', 'Schaf', 'Maus']);
final _sheep = _en('sheep', 'Schaf', ['Ziege', 'Schaf', 'Hund', 'Kuh']);

final _lesen = FachAufgabe.aus(
    fach: 'Lesen',
    thema: 'Sätze lesen',
    prompt: 'Lea will draußen malen. Der Wind weht das Papier weg. Lea malt '
        'deshalb in der Küche weiter.\nWarum wechselt Lea den Ort?',
    antwort: 'Der Wind weht das Papier weg.',
    auswahl: [
      'Die Farben sind leer.',
      'Die Sonne ist zu hell.',
      'Der Wind weht das Papier weg.'
    ])!;

final _lesenZwilling = FachAufgabe.aus(
    fach: 'Lesen',
    thema: 'Sätze lesen',
    prompt: 'Ben fährt mit dem Rad zur Schule.\nWohin fährt Ben?',
    antwort: 'zur Schule',
    auswahl: ['zur Schule', 'zum See', 'zum Markt'])!;

final _su = FachAufgabe.aus(
    fach: 'Sachunterricht',
    thema: 'Wasserkreislauf',
    prompt: 'Was passiert mit Wasser, wenn die Sonne es stark erwärmt?',
    antwort: 'Es verdunstet.',
    auswahl: [
      'Es gefriert.',
      'Es wird zu Stein.',
      'Es wird schwerer.',
      'Es verdunstet.'
    ])!;

final _suZwilling = FachAufgabe.aus(
    fach: 'Sachunterricht',
    thema: 'Wasserkreislauf',
    prompt: 'Wo entspringt ein Bach?',
    antwort: 'an einer Quelle',
    auswahl: ['im Meer', 'in einer Wolke', 'an einer Quelle', 'in der Mündung'])!;

class _Stimme {
  final gesagt = <(String, bool)>[];
  Future<void> call(String text, {bool langsam = false}) async =>
      gesagt.add((text, langsam));
}

Future<void> _zeige(WidgetTester tester, FachNachhilfeScreen screen,
    {Size size = const Size(412, 915)}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(home: screen));
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _tippe(WidgetTester tester, Key key) async {
  final f = find.byKey(key);
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await tester.pump(const Duration(milliseconds: 50));
}

String _text(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('fach-text'))).data!;

void main() {
  testWidgets('Englisch: fünf Stufen, Bilder, Beispiel, keine Aussprache',
      (tester) async {
    final stimme = _Stimme();
    final methoden = <String>[];
    await _zeige(
        tester,
        FachNachhilfeScreen(
          aufgabe: _horse,
          beispiel: _cow,
          pruefung: _sheep,
          reduceMotion: true,
          onSpeak: stimme.call,
          onMethode: methoden.add,
        ));
    expect(find.text('Nachhilfe · Englisch'), findsOneWidget);
    expect(find.byKey(const ValueKey('fach-wort')), findsOneWidget);
    expect(find.byKey(const ValueKey('fach-stimme-hinweis')), findsOneWidget);
    await _tippe(tester, const ValueKey('fach-mehr-hilfe'));
    expect(find.byKey(const ValueKey('fach-bildkarten')), findsOneWidget);
    for (final c in _horse.auswahl) {
      expect(find.byKey(ValueKey('fach-bildkarte-$c')), findsOneWidget);
    }
    expect(_text(tester), contains('reiten'));
    await _tippe(tester, const ValueKey('fach-mehr-hilfe'));
    expect(find.byKey(const ValueKey('fach-szene')), findsOneWidget);
    expect(find.text('„cow“'), findsOneWidget);
    expect(_text(tester), contains('heißt Kuh'));
    for (final (text, _) in stimme.gesagt) {
      expect(text, isNot(contains('horse')));
      expect(text, isNot(contains('cow')));
    }
    expect(methoden, ['wort', 'bild', 'situation']);
    // Alle Touch-Ziele mindestens 48 dp.
    for (final element in find.byType(FilledButton).evaluate()) {
      final size = tester.getSize(find.byWidget(element.widget));
      expect(size.height, greaterThanOrEqualTo(48));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Gemeinsam ausschließen: die richtige Antwort wird nie bestätigt',
      (tester) async {
    await _zeige(
        tester,
        FachNachhilfeScreen(
            aufgabe: _horse,
            startStufe: NachhilfeStufe.teilschritt,
            reduceMotion: true));
    expect(find.byKey(const ValueKey('fach-ausschliessen')), findsOneWidget);
    await _tippe(tester, const ValueKey('fach-weg-Pferd'));
    final r = tester
        .widget<Text>(find.byKey(const ValueKey('fach-rueckmeldung')))
        .data!;
    expect(r, contains('Bist du dir sicher'));
    expect(r, isNot(contains('richtig')));
    await _tippe(tester, const ValueKey('fach-weg-Küken'));
    expect(find.textContaining('„Küken“ passt nicht'), findsOneWidget);
    await _tippe(tester, const ValueKey('fach-weg-Fisch'));
    expect(find.textContaining('Entscheidung triffst du in deiner Aufgabe'),
        findsOneWidget);
  });

  testWidgets(
      'Prüfaufgabe: genau einmal gemeldet; allein richtig = selbstständig',
      (tester) async {
    final gemeldet = <FachPruefung>[];
    await _zeige(
        tester,
        FachNachhilfeScreen(
            aufgabe: _horse,
            pruefung: _sheep,
            startStufe: NachhilfeStufe.ueben,
            reduceMotion: true,
            onPruefung: gemeldet.add));
    expect(find.text(_sheep.prompt), findsOneWidget);
    await _tippe(tester, const ValueKey('fach-pruef-Schaf'));
    expect(find.text('Richtig! Das hast du ganz allein gelöst.'),
        findsOneWidget);
    expect(gemeldet, hasLength(1));
    expect(gemeldet.single.selbststaendig, isTrue);
    expect(gemeldet.single.aufgabe, _sheep);
  });

  testWidgets(
      'Prüfaufgabe nicht geschafft: Lumo erklärt es anders (Methodenwechsel)',
      (tester) async {
    final gemeldet = <FachPruefung>[];
    final methoden = <String>[];
    await _zeige(
        tester,
        FachNachhilfeScreen(
            aufgabe: _su,
            pruefung: _suZwilling,
            startStufe: NachhilfeStufe.ueben,
            reduceMotion: true,
            onMethode: methoden.add,
            onPruefung: gemeldet.add));
    await _tippe(tester, const ValueKey('fach-pruef-im Meer'));
    expect(gemeldet, isEmpty, reason: 'zweiter Versuch erlaubt');
    await _tippe(tester, const ValueKey('fach-pruef-in einer Wolke'));
    expect(gemeldet, hasLength(1));
    expect(gemeldet.single.richtig, isFalse);
    expect(gemeldet.single.selbststaendig, isFalse);
    await _tippe(tester, const ValueKey('fach-anders-erklaeren'));
    expect(methoden.last, 'alltag',
        reason: 'eine neue Erklärweise statt derselben Aufgabe');
    expect(find.byKey(const ValueKey('fach-alltag')), findsOneWidget);
    await _tippe(tester, const ValueKey('fach-mehr-hilfe'));
    expect(find.byKey(const ValueKey('fach-schaubild')), findsOneWidget);
    expect(find.text('?'), findsWidgets, reason: 'verdeckte Beschriftung');
    expect(find.textContaining('verdunst'), findsNothing);
  });

  testWidgets('Lesen: Frage, Laute, langsam vorlesen, Satz finden',
      (tester) async {
    final stimme = _Stimme();
    await _zeige(
        tester,
        FachNachhilfeScreen(
            aufgabe: _lesen,
            pruefung: _lesenZwilling,
            reduceMotion: true,
            onSpeak: stimme.call),
        size: const Size(1080 / 2.625, 2340 / 2.625));
    expect(find.byKey(const ValueKey('fach-markierung')), findsOneWidget);
    await _tippe(tester, const ValueKey('fach-stufe-andereErklaerung'));
    expect(find.byKey(const ValueKey('fach-laute')), findsOneWidget);
    await _tippe(tester, const ValueKey('fach-stufe-vorzeigen'));
    expect(find.byKey(const ValueKey('fach-vorlesen')), findsOneWidget);
    expect(stimme.gesagt.last.$2, isTrue, reason: 'langsam (Langsamer-Weg)');
    expect(stimme.gesagt.last.$1, contains('Küche'));
    await _tippe(tester, const ValueKey('fach-stufe-teilschritt'));
    await _tippe(tester, const ValueKey('fach-satz-0'));
    expect(find.textContaining('Probier einen anderen'), findsOneWidget);
    await _tippe(tester, const ValueKey('fach-satz-1'));
    expect(find.textContaining('dieser Satz hilft dir'), findsOneWidget);
    await _tippe(tester, const ValueKey('fach-stufe-ueben'));
    expect(find.text(_lesenZwilling.prompt), findsOneWidget);
    expect(_text(tester), contains('ganz allein'));
    expect(tester.takeException(), isNull);
  });

  for (final (name, size) in [
    ('Handy 1080×2340', const Size(1080 / 2.625, 2340 / 2.625)),
    ('Fold innen 2176×1812', const Size(2176 / 2.625, 1812 / 2.625)),
  ]) {
    testWidgets('$name: alle Stufen ohne Überlauf, auch große Schrift',
        (tester) async {
      for (final a in [_horse, _lesen, _su]) {
        for (final stufe in NachhilfeStufe.values) {
          await tester.binding.setSurfaceSize(size);
          await tester.pumpWidget(MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                  size: size, textScaler: const TextScaler.linear(1.6)),
              child: FachNachhilfeScreen(
                key: ValueKey('${a.prompt}-${stufe.name}'),
                aufgabe: a,
                beispiel: a == _horse ? _cow : null,
                pruefung: a == _horse
                    ? _sheep
                    : a == _lesen
                        ? _lesenZwilling
                        : _suZwilling,
                startStufe: stufe,
                reduceMotion: true,
              ),
            ),
          ));
          await tester.pump(const Duration(milliseconds: 50));
          expect(tester.takeException(), isNull,
              reason: '${a.fachName} ${stufe.name}');
        }
      }
      await tester.binding.setSurfaceSize(null);
    });
  }
}
