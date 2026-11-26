import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/school/attempt.dart';
import 'package:lumo_lernen/domain/school/learning_guidance.dart';
import 'package:lumo_lernen/domain/tutoring/fach_nachhilfe.dart';
import 'package:lumo_lernen/domain/tutoring/lumo_nachhilfe.dart';
import 'package:lumo_lernen/features/report/learning_guidance_panel.dart';
import 'package:lumo_lernen/features/teacher_demo/holo_widgets.dart';
import 'package:lumo_lernen/features/tutoring/fach_nachhilfe_screen.dart';
import 'package:lumo_lernen/features/tutoring/lumo_nachhilfe_screen.dart';

/// Abnahmebilder Team A5 (Fold7 außen 1080×2340, innen 2176×1812). Dateien
/// entstehen nur mit A5_CAPTURES=<Ordner>; ohne die Variable prüft der Test
/// nur fehlerfreies Rendern. Alle Antworten sind Testdaten.
final _ziel = Platform.environment['A5_CAPTURES'];
const _rahmen = ValueKey('a5-capture');

Future<void> _frames(WidgetTester tester, [int n = 30]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<void> _foto(WidgetTester tester, String name) async {
  expect(tester.takeException(), isNull, reason: name);
  if (_ziel == null) return;
  await tester.runAsync(() async {
    await Future.wait(find.byType(Image).evaluate().map(
        (e) => precacheImage((e.widget as Image).image, e)));
  });
  await tester.pump(const Duration(milliseconds: 50));
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_rahmen));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2.625);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final datei = File('$_ziel/$name.png');
    await datei.parent.create(recursive: true);
    await datei.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

FachAufgabe _a(String fach, String thema, String prompt, String antwort,
        List<String> auswahl, {String erklaerung = ''}) =>
    FachAufgabe.aus(
        fach: fach,
        thema: thema,
        prompt: prompt,
        antwort: antwort,
        auswahl: auswahl,
        erklaerung: erklaerung)!;

final _horse = _a('Englisch', 'Tiere', 'Was bedeutet „horse“?', 'Pferd',
    ['Küken', 'Esel', 'Pferd', 'Fisch']);
final _cow = _a('Englisch', 'Tiere', 'Was bedeutet „cow“?', 'Kuh',
    ['Kuh', 'Hund', 'Schaf', 'Maus'],
    erklaerung: 'Das englische Wort „cow“ bedeutet Kuh.');
final _sheep = _a('Englisch', 'Tiere', 'Was bedeutet „sheep“?', 'Schaf',
    ['Ziege', 'Schaf', 'Hund', 'Kuh']);
final _lesen = _a(
    'Lesen',
    'Sätze lesen',
    'Lea will draußen malen. Der Wind weht das Papier weg. Lea malt deshalb '
        'in der Küche weiter.\nWarum wechselt Lea den Ort?',
    'Der Wind weht das Papier weg.',
    ['Die Farben sind leer.', 'Die Sonne ist zu hell.', 'Der Wind weht das Papier weg.']);
final _lesen2 = _a('Lesen', 'Sätze lesen',
    'Ben fährt mit dem Rad zur Schule.\nWohin fährt Ben?', 'zur Schule',
    ['zur Schule', 'zum See', 'zum Markt']);
final _su = _a(
    'Sachunterricht',
    'Wasserkreislauf',
    'Was passiert mit Wasser, wenn die Sonne es stark erwärmt?',
    'Es verdunstet.',
    ['Es gefriert.', 'Es wird zu Stein.', 'Es wird schwerer.', 'Es verdunstet.']);
final _su2 = _a('Sachunterricht', 'Wasserkreislauf', 'Wo entspringt ein Bach?',
    'an einer Quelle', ['im Meer', 'in einer Wolke', 'an einer Quelle', 'in der Mündung']);

List<Attempt> _protokoll() {
  final jetzt = DateTime.now();
  var n = 0;
  Attempt a(String subject, String unit, String komp, String prompt,
          {bool ok = true,
          bool hilfe = false,
          String? check,
          String ref = '',
          int tage = 1}) =>
      Attempt(
        id: 'a5-${n++}',
        studentId: 'kind-a5',
        subject: subject,
        unit: unit,
        competency: komp,
        correct: ok,
        hintUsed: hilfe,
        prompt: prompt,
        check: check,
        reference: ref,
        at: jetzt.subtract(Duration(days: tage, minutes: n)),
      );
  const v = Attempt.vergleichNachHilfe;
  return [
    for (var i = 0; i < 6; i++)
      a('Mathematik', 'Plus bis 20', 'Addition mit Zehnerübergang',
          '${8 + i % 2} + ${5 + i % 3} = ?',
          ok: i != 1, tage: 2 + i),
    a('Mathematik', 'Plus bis 20', 'Addition mit Zehnerübergang', '8 + 5 = ?',
        hilfe: true, tage: 3),
    a('Mathematik', 'Plus bis 20', 'Addition mit Zehnerübergang', '7 + 6 = ?',
        check: v, ref: '8 + 5 = ?', tage: 3),
    a('Mathematik', 'Plus bis 20', 'Addition mit Zehnerübergang', '9 + 4 = ?',
        hilfe: true, tage: 1),
    a('Mathematik', 'Plus bis 20', 'Addition mit Zehnerübergang', '8 + 6 = ?',
        check: v, ref: '9 + 4 = ?', tage: 1),
    a('Englisch', 'Tiere', 'Englisch Tiere', 'Was bedeutet „horse“?',
        hilfe: true, tage: 1),
    a('Englisch', 'Tiere', 'Englisch Tiere', 'Was bedeutet „sheep“?',
        check: v, ref: 'Was bedeutet „horse“?', tage: 1),
    a('Sachunterricht', 'Wasserkreislauf', 'Wasserkreislauf',
        'Was passiert mit Wasser, wenn die Sonne es stark erwärmt?',
        hilfe: true, ok: false, tage: 1),
    a('Sachunterricht', 'Wasserkreislauf', 'Wasserkreislauf',
        'Wo entspringt ein Bach?',
        check: v,
        ok: false,
        ref: 'Was passiert mit Wasser, wenn die Sonne es stark erwärmt?',
        tage: 1),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Nunito')
          ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    final emoji = File('/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf');
    if (emoji.existsSync()) {
      final bytes = emoji.readAsBytesSync();
      await (FontLoader('NotoColorEmoji')
            ..addFont(Future.value(ByteData.sublistView(bytes))))
          .load();
    }
  });

  for (final (geraet, physisch) in [
    ('fold_aussen_1080x2340', const Size(1080, 2340)),
    ('fold_innen_2176x1812', const Size(2176, 1812)),
  ]) {
    Future<void> zeige(WidgetTester tester, Widget seite) async {
      tester.view.physicalSize = physisch;
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            fontFamily: 'Nunito',
            fontFamilyFallback: const ['NotoColorEmoji'],
            useMaterial3: true),
        home: RepaintBoundary(key: _rahmen, child: seite),
      ));
      await _frames(tester, 70);
    }

    testWidgets('Englisch · $geraet', (tester) async {
      for (final (stufe, name) in [
        (NachhilfeStufe.andereErklaerung, 'englisch_2_bilder'),
        (NachhilfeStufe.vorzeigen, 'englisch_3_situation'),
        (NachhilfeStufe.teilschritt, 'englisch_4_ausschliessen'),
        (NachhilfeStufe.ueben, 'englisch_5_pruefen'),
      ]) {
        await zeige(
            tester,
            FachNachhilfeScreen(
              key: ValueKey(name),
              aufgabe: _horse,
              beispiel: _cow,
              pruefung: _sheep,
              startStufe: stufe,
              onSpeak: (t, {bool langsam = false}) async {},
            ));
        if (stufe == NachhilfeStufe.teilschritt) {
          await tester.tap(find.byKey(const ValueKey('fach-weg-Fisch')));
          await _frames(tester, 6);
        }
        if (stufe == NachhilfeStufe.ueben) {
          final f = find.byKey(const ValueKey('fach-pruef-Schaf'));
          await tester.ensureVisible(f);
          await tester.tap(f);
          await _frames(tester, 10);
          await tester.drag(find.byType(Scrollable).first, const Offset(0, 900));
          await _frames(tester, 4);
        }
        await _foto(tester, '${name}__$geraet');
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Lesen · $geraet', (tester) async {
      for (final (stufe, name) in [
        (NachhilfeStufe.andereErklaerung, 'lesen_2_laute'),
        (NachhilfeStufe.vorzeigen, 'lesen_3_vorlesen'),
        (NachhilfeStufe.teilschritt, 'lesen_4_satz_finden'),
      ]) {
        await zeige(
            tester,
            FachNachhilfeScreen(
              key: ValueKey(name),
              aufgabe: _lesen,
              pruefung: _lesen2,
              startStufe: stufe,
              onSpeak: (t, {bool langsam = false}) async {},
            ));
        if (stufe == NachhilfeStufe.vorzeigen) await _frames(tester, 60);
        if (stufe == NachhilfeStufe.teilschritt) {
          final f = find.byKey(const ValueKey('fach-satz-1'));
          await tester.ensureVisible(f);
          await tester.tap(f);
          await _frames(tester, 6);
        }
        await _foto(tester, '${name}__$geraet');
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Sachunterricht · $geraet', (tester) async {
      for (final (stufe, name) in [
        (NachhilfeStufe.andereErklaerung, 'sachunterricht_2_alltag'),
        (NachhilfeStufe.vorzeigen, 'sachunterricht_3_schaubild'),
      ]) {
        await zeige(
            tester,
            FachNachhilfeScreen(
                key: ValueKey(name),
                aufgabe: _su,
                pruefung: _su2,
                startStufe: stufe));
        if (stufe == NachhilfeStufe.vorzeigen &&
            physisch.width < physisch.height) {
          final f = find.byKey(const ValueKey('fach-schaubild'));
          await tester.ensureVisible(f);
          await _frames(tester, 4);
        }
        await _foto(tester, '${name}__$geraet');
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Mathe-Nachhilfe Methodenwechsel · $geraet', (tester) async {
      await zeige(
          tester,
          LumoNachhilfeScreen(
            aufgabe: NachhilfeAufgabe.additionBis100(37, 25)!,
            startStufe: NachhilfeStufe.ueben,
            schonVersucht: const {NachhilfeWeg.stangen},
          ));
      // Zwei Fehlversuche in der Prüfaufgabe, dann anders erklärt.
      for (var i = 0; i < 2; i++) {
        for (final z in ['1', '1']) {
          await tester.tap(find.byKey(ValueKey('nachhilfe-ziffer-$z')));
          await tester.pump();
        }
        await tester.tap(find.byKey(const ValueKey('nachhilfe-ziffer-ok')));
        await _frames(tester, 6);
      }
      final weiter = find.byKey(const ValueKey('nachhilfe-pruef-mit-lumo'));
      await tester.ensureVisible(weiter);
      await tester.tap(weiter);
      await _frames(tester, 20);
      expect(find.textContaining('Wir probieren es anders'), findsOneWidget);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 900));
      await _frames(tester, 4);
      await _foto(tester, 'mathe_methodenwechsel__$geraet');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Eltern „Später bestätigt“ · $geraet', (tester) async {
      final guidance = LearningGuidance.fromAttempts(_protokoll(),
          studentId: 'kind-a5', now: DateTime.now());
      await zeige(
          tester,
          Scaffold(
            backgroundColor: HoloPalette.deep,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: LearningGuidancePanel(guidance: guidance),
              ),
            ),
          ));
      expect(find.byKey(const ValueKey('guidance-later-confirmed')),
          findsOneWidget);
      await _foto(tester, 'eltern_spaeter_bestaetigt__$geraet');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
