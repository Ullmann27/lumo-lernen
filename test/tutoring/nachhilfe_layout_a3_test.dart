import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/tutoring/lumo_nachhilfe.dart';
import 'package:lumo_lernen/features/tutoring/lumo_nachhilfe_screen.dart';
import 'package:lumo_lernen/widgets/design/lumo_design_system.dart';

/// Layout der Nachhilfe-Seite auf Handy und Fold (Nacharbeit Team A3):
/// Ziffernblock ohne Scrollen erreichbar, Lumo als echter Fuchs auf dem
/// Zahlenstrahl, Fold-Innenbildschirm ohne leeres unteres Drittel.

const _handy = Size(412, 892); // Fold7 außen 1080×2340 bei 2,625
const _kleinesHandy = Size(360, 640);
const _foldInnen = Size(829, 690); // Fold7 innen 2176×1812 bei 2,625

Future<void> _zeige(
  WidgetTester tester,
  NachhilfeAufgabe aufgabe,
  NachhilfeStufe stufe, {
  required Size groesse,
  double textScale = 1,
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
        reduceMotion: true,
      ),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _weiter(WidgetTester tester) async {
  final weiter = find.byKey(const ValueKey('nachhilfe-weiter'));
  await tester.ensureVisible(weiter);
  await tester.pump();
  await tester.tap(weiter);
  await tester.pump(const Duration(milliseconds: 50));
}

/// Jede Taste liegt vollständig im Bildschirm, ohne dass gescrollt wurde.
void _ziffernblockSichtbar(WidgetTester tester, Size groesse, String grund) {
  for (final key in [
    'nachhilfe-eingabe',
    for (var z = 0; z <= 9; z++) 'nachhilfe-ziffer-$z',
    'nachhilfe-ziffer-loeschen',
    'nachhilfe-ziffer-ok',
  ]) {
    final finder = find.byKey(ValueKey(key));
    expect(finder, findsOneWidget, reason: '$grund $key');
    final rect = tester.getRect(finder);
    expect(rect.top, greaterThanOrEqualTo(0), reason: '$grund $key oben');
    expect(rect.bottom, lessThanOrEqualTo(groesse.height),
        reason: '$grund $key liegt unter dem sichtbaren Bereich');
    if (key != 'nachhilfe-eingabe') {
      expect(rect.width, greaterThanOrEqualTo(48), reason: '$grund $key');
      expect(rect.height, greaterThanOrEqualTo(48), reason: '$grund $key');
    }
  }
}

void main() {
  for (final (name, groesse) in [
    ('Handy', _handy),
    ('kleines Handy', _kleinesHandy),
    ('Fold innen', _foldInnen),
  ]) {
    for (final textScale in [1.0, 1.3]) {
      testWidgets(
          '$name ×$textScale: Ziffernblock ohne Scrollen erreichbar '
          '(Gemeinsam und Prüfung)', (tester) async {
        await _zeige(tester, NachhilfeAufgabe.mal(6, 7)!,
            NachhilfeStufe.teilschritt,
            groesse: groesse, textScale: textScale);
        await _weiter(tester);
        // Ohne Scrollen: die Ansicht steht wieder ganz oben.
        for (final scrollable in find.byType(Scrollable).evaluate()) {
          final state = (scrollable as StatefulElement).state as ScrollableState;
          if (state.position.axis == Axis.vertical) {
            state.position.jumpTo(0);
          }
        }
        await tester.pump();
        _ziffernblockSichtbar(tester, groesse, '$name Gemeinsam');
        expect(tester.takeException(), isNull);

        await _zeige(tester, NachhilfeAufgabe.subtraktionBis100(62, 25)!,
            NachhilfeStufe.ueben,
            groesse: groesse, textScale: textScale);
        _ziffernblockSichtbar(tester, groesse, '$name Prüfung');
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Zahlenstrahl bis 100: Lumo ist der echte Fuchs, keine Pfote',
      (tester) async {
    for (final groesse in [_handy, _foldInnen]) {
      await _zeige(tester, NachhilfeAufgabe.additionBis100(37, 25)!,
          NachhilfeStufe.vorzeigen,
          groesse: groesse);
      await tester.tap(find.byKey(const ValueKey('nachhilfe-weg-zahlenstrahl')));
      await tester.pump(const Duration(milliseconds: 50));
      await _weiter(tester);
      await _weiter(tester);
      final fuchs = find.byKey(const ValueKey('nachhilfe-strahl-fuchs'));
      expect(fuchs, findsOneWidget);
      final bild = tester.widget<Image>(
          find.descendant(of: fuchs, matching: find.byType(Image)));
      expect((bild.image as ResizeImage).imageProvider,
          isA<AssetImage>().having((a) => a.assetName, 'asset',
              LumoDesignFoxPose.cheer.assetPath));
      expect(find.byIcon(Icons.pets_rounded), findsNothing);
      // Der Fuchs steht unter der Beschriftung und über dem Standsatz.
      final stand = tester.getRect(
          find.byKey(const ValueKey('nachhilfe-strahl-stand')));
      expect(tester.getRect(fuchs).bottom, lessThanOrEqualTo(stand.top + 1));
    }
  });

  testWidgets('Zahlenstrahl bis 20: Lumo auf dem Stein ist der echte Fuchs',
      (tester) async {
    await _zeige(tester, NachhilfeAufgabe.addition(8, 5)!,
        NachhilfeStufe.vorzeigen,
        groesse: _handy);
    final zahlenstrahl =
        find.byKey(const ValueKey('nachhilfe-weg-zahlenstrahl'));
    if (zahlenstrahl.evaluate().isNotEmpty) {
      await tester.tap(zahlenstrahl);
      await tester.pump(const Duration(milliseconds: 50));
    }
    await _weiter(tester);
    final fuchs = find.byKey(const ValueKey('nachhilfe-stein-fuchs'));
    expect(fuchs, findsOneWidget);
    expect(find.descendant(of: fuchs, matching: find.byType(Image)),
        findsOneWidget);
    expect(find.byIcon(Icons.pets_rounded), findsNothing);
    // Die Steinleiste rollt mit: Lumos Stein ist sichtbar.
    final rect = tester.getRect(fuchs);
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(_handy.width));
  });

  testWidgets('Fold innen: Material und Knöpfe nutzen die ganze Höhe',
      (tester) async {
    await _zeige(tester, NachhilfeAufgabe.additionBis100(37, 25)!,
        NachhilfeStufe.vorzeigen,
        groesse: _foldInnen);
    await tester.tap(find.byKey(const ValueKey('nachhilfe-weg-zahlenstrahl')));
    await tester.pump(const Duration(milliseconds: 50));
    await _weiter(tester);
    await _weiter(tester);
    final material =
        tester.getRect(find.byKey(const ValueKey('nachhilfe-material')));
    // Panel reicht bis zum unteren Rand (nur Rand und Abstand frei).
    expect(material.bottom, greaterThan(_foldInnen.height - 60));
    final weiter =
        tester.getRect(find.byKey(const ValueKey('nachhilfe-weiter')));
    expect(weiter.bottom, greaterThan(_foldInnen.height - 140),
        reason: 'Knöpfe stehen unten statt in der Mitte');
    expect(weiter.bottom, lessThanOrEqualTo(_foldInnen.height));
    // Die bisherigen Schritte füllen die Lücke neben dem Material.
    expect(find.byKey(const ValueKey('nachhilfe-weg-bisher')), findsOneWidget);
    expect(find.textContaining('Unser Weg bisher'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Handy: Weg-Liste bleibt dem Fold vorbehalten', (tester) async {
    await _zeige(tester, NachhilfeAufgabe.additionBis100(37, 25)!,
        NachhilfeStufe.vorzeigen,
        groesse: _handy);
    await _weiter(tester);
    expect(find.byKey(const ValueKey('nachhilfe-weg-bisher')), findsNothing);
  });
}
