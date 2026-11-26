import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/tutoring/lumo_nachhilfe.dart';
import 'package:lumo_lernen/features/tutoring/lumo_nachhilfe_screen.dart';

/// Bilder der visuellen Erklärungen für die Abnahme (Fold7 außen 1080×2340,
/// innen 2176×1812). Nur mit LUMO_NACHHILFE_CAPTURES=<Ordner> werden Dateien
/// geschrieben; ohne die Variable prüft der Test nur, dass alles fehlerfrei
/// rendert.
final _ziel = Platform.environment['LUMO_NACHHILFE_CAPTURES'];
const _rahmen = ValueKey('nachhilfe-capture');

Future<void> _foto(WidgetTester tester, String name, double dpr) async {
  expect(tester.takeException(), isNull, reason: name);
  if (_ziel == null) return;
  await tester.runAsync(() async {
    await Future.wait(find
        .byType(Image)
        .evaluate()
        .map((e) => precacheImage((e.widget as Image).image, e)));
  });
  await tester.pump();
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_rahmen));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: dpr);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final datei = File('$_ziel/$name.png');
    await datei.parent.create(recursive: true);
    await datei.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> _tippe(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 40));
}

Future<void> _eintippen(WidgetTester tester, int zahl) async {
  for (final z in '$zahl'.split('')) {
    await _tippe(tester, ValueKey('nachhilfe-ziffer-$z'));
  }
  await _tippe(tester, const ValueKey('nachhilfe-ziffer-ok'));
}

typedef _Szene = ({
  String name,
  NachhilfeAufgabe aufgabe,
  NachhilfeStufe stufe,
  NachhilfeWeg? weg,
  Future<void> Function(WidgetTester tester) ablauf,
});

Future<void> _weiter(WidgetTester tester, [int mal = 1]) async {
  for (var i = 0; i < mal; i++) {
    await _tippe(tester, const ValueKey('nachhilfe-weiter'));
    await tester.pump(const Duration(milliseconds: 900));
  }
}

final List<_Szene> _szenen = [
  (
    name: '01_mal_6x7_lumo_zeigt_fuenf_reihen',
    aufgabe: NachhilfeAufgabe.mal(6, 7)!,
    stufe: NachhilfeStufe.vorzeigen,
    weg: null,
    ablauf: (t) => _weiter(t),
  ),
  (
    name: '02_mal_6x7_gemeinsam_kind_tippt',
    aufgabe: NachhilfeAufgabe.mal(6, 7)!,
    stufe: NachhilfeStufe.teilschritt,
    weg: null,
    ablauf: (t) async {
      await _weiter(t);
      await _eintippen(t, 3);
    },
  ),
  (
    name: '03_mal_9x4_zehn_reihen_gedacht',
    aufgabe: NachhilfeAufgabe.mal(9, 4)!,
    stufe: NachhilfeStufe.teilschritt,
    weg: null,
    ablauf: (t) async {
      await _weiter(t);
      await _eintippen(t, 40);
      await t.pump(const Duration(milliseconds: 900));
    },
  ),
  (
    name: '04_mal_7x5_feld_gedreht',
    aufgabe: NachhilfeAufgabe.mal(7, 5)!,
    stufe: NachhilfeStufe.teilschritt,
    weg: null,
    ablauf: (t) => _weiter(t),
  ),
  (
    name: '05_plus_37_25_stangen_unterwegs',
    aufgabe: NachhilfeAufgabe.additionBis100(37, 25)!,
    stufe: NachhilfeStufe.vorzeigen,
    weg: NachhilfeWeg.stangen,
    ablauf: (t) async {
      await _tippe(t, const ValueKey('nachhilfe-weiter'));
      await t.pump(const Duration(milliseconds: 330));
    },
  ),
  (
    name: '06_plus_37_25_gemeinsam_zehner_voll',
    aufgabe: NachhilfeAufgabe.additionBis100(37, 25)!,
    stufe: NachhilfeStufe.teilschritt,
    weg: NachhilfeWeg.stangen,
    ablauf: (t) async {
      await _weiter(t);
      await _eintippen(t, 57);
      await t.pump(const Duration(milliseconds: 900));
      await _weiter(t);
      await _eintippen(t, 3);
      await t.pump(const Duration(milliseconds: 900));
    },
  ),
  (
    name: '07_plus_37_25_zahlenstrahl',
    aufgabe: NachhilfeAufgabe.additionBis100(37, 25)!,
    stufe: NachhilfeStufe.vorzeigen,
    weg: NachhilfeWeg.zahlenstrahl,
    ablauf: (t) => _weiter(t, 3),
  ),
  (
    name: '08_minus_62_25_zehner_aufmachen',
    aufgabe: NachhilfeAufgabe.subtraktionBis100(62, 25)!,
    stufe: NachhilfeStufe.vorzeigen,
    weg: NachhilfeWeg.stangen,
    ablauf: (t) => _weiter(t, 3),
  ),
  (
    name: '09_minus_13_5_rechenrahmen_bis_zehn',
    aufgabe: NachhilfeAufgabe.subtraktion(13, 5)!,
    stufe: NachhilfeStufe.vorzeigen,
    weg: NachhilfeWeg.rechenrahmen,
    ablauf: (t) => _weiter(t),
  ),
  (
    name: '10_plus_8_5_eierkarton',
    aufgabe: NachhilfeAufgabe.addition(8, 5)!,
    stufe: NachhilfeStufe.andereErklaerung,
    weg: null,
    ablauf: (t) => _weiter(t),
  ),
  (
    name: '11_mal_6x7_teller',
    aufgabe: NachhilfeAufgabe.mal(6, 7)!,
    stufe: NachhilfeStufe.andereErklaerung,
    weg: null,
    ablauf: (t) async {},
  ),
  (
    name: '12_minus_62_25_muenzen',
    aufgabe: NachhilfeAufgabe.subtraktionBis100(62, 25)!,
    stufe: NachhilfeStufe.andereErklaerung,
    weg: null,
    ablauf: (t) async {},
  ),
  (
    name: '13_pruefen_allein',
    aufgabe: NachhilfeAufgabe.subtraktionBis100(62, 25)!,
    stufe: NachhilfeStufe.ueben,
    weg: null,
    ablauf: (t) async {
      await _tippe(t, const ValueKey('nachhilfe-ziffer-3'));
    },
  ),
  (
    name: '14_hinweis_37_25',
    aufgabe: NachhilfeAufgabe.additionBis100(37, 25)!,
    stufe: NachhilfeStufe.hinweis,
    weg: null,
    ablauf: (t) => _weiter(t),
  ),
];

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
  });

  for (final (geraet, physisch) in [
    ('fold_aussen_1080x2340', const Size(1080, 2340)),
    ('fold_innen_2176x1812', const Size(2176, 1812)),
  ]) {
    for (final szene in _szenen) {
      testWidgets('${szene.name} · $geraet', (tester) async {
        const dpr = 2.625;
        tester.view.physicalSize = physisch;
        tester.view.devicePixelRatio = dpr;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Nunito', useMaterial3: true),
          home: RepaintBoundary(
            key: _rahmen,
            child: LumoNachhilfeScreen(
              aufgabe: szene.aufgabe,
              startStufe: szene.stufe,
              reduceMotion: false,
            ),
          ),
        ));
        await tester.pump(const Duration(milliseconds: 900));
        if (szene.weg != null) {
          await _tippe(tester, ValueKey('nachhilfe-weg-${szene.weg!.name}'));
          await tester.pump(const Duration(milliseconds: 900));
        }
        await szene.ablauf(tester);
        // Sichtbar: zurück nach oben, damit Lumo und Material im Bild sind.
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 4000));
        await tester.pump(const Duration(milliseconds: 40));
        await _foto(tester, '${szene.name}__$geraet', dpr);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 2));
      });
    }
  }
}
