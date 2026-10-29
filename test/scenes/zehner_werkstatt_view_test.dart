import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/learning/widgets/lumo_place_value_workshop.dart';
import 'package:lumo_lernen/features/learning/scenes/place_value/place_value_material.dart';
import 'package:lumo_lernen/widgets/fox/living/lumo_living_character.dart';

import '../helpers/lumo_capture.dart';

/// Die Zehner-Werkstatt mit lebendem Lumo, mit Animationen, auf echten
/// Gerätegrößen. Mit LUMO_SCENE_CAPTURES=<Ordner> entstehen dabei echte
/// Flutter-Renderings jedes Schritts und Einzelbilder der Verwandlungen.
final _out = Platform.environment['LUMO_SCENE_CAPTURES'];
const _boundary = ValueKey('werkstatt-capture');

const _sizes = <String, (Size, double)>{
  'phone': (Size(412, 915), 1),
  'fold-cover-text2': (Size(344, 882), 2),
  'fold-open': (Size(690, 829), 1),
  'fold-open-landscape': (Size(882, 690), 1),
};

/// Schreibt das aktuelle Bild ohne weitere Frames, damit Einzelbilder einer
/// Verwandlung genau den gepumpten Zeitpunkt zeigen.
Future<void> _shot(WidgetTester tester, String name) async {
  final out = _out;
  if (out == null) return;
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$out/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

/// Lässt Bilder dekodieren; die Original-Posen laden asynchron.
Future<void> _settleImages(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _frames(WidgetTester tester, int milliseconds) async {
  for (var t = 0; t < milliseconds; t += 50) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

Widget _app(Size size, double textScale, Widget child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MediaQuery(
        data: MediaQueryData(
            size: size, textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          backgroundColor: const Color(0xFF071A3A),
          body: SingleChildScrollView(
            child: RepaintBoundary(
              key: _boundary,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF0B2A5C), Color(0xFF061634)]),
                ),
                padding: const EdgeInsets.all(14),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  setUpAll(loadLumoCaptureFonts);

  for (final entry in _sizes.entries) {
    final (size, textScale) = entry.value;
    testWidgets('84 animated from counting to explaining on ${entry.key}',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final semantics = tester.ensureSemantics();
      final results = <LumoPlaceValueTransfer>[];
      await tester.pumpWidget(_app(size, textScale,
          LumoPlaceValueWorkshop(number: 84, onTransferChecked: results.add)));
      await _settleImages(tester);
      final name = entry.key;
      expect(find.bySemanticsLabel(LumoLivingState.greet.semanticLabel),
          findsOneWidget);
      await _frames(tester, 600);
      await _shot(tester, '$name-01-greet');

      // Nach der Begrüßung folgt Lumo der Absicht der Lern-Engine.
      await _frames(tester, 1200);
      expect(find.bySemanticsLabel(LumoLivingState.explain.semanticLabel),
          findsOneWidget);

      // Das Kind zählt drei Stangen: 10, 20, 30.
      for (final i in [0, 1, 2]) {
        await _tap(tester, 'lumo-tens-block-$i');
        await _frames(tester, 250);
      }
      expect(find.text('30'), findsWidgets);
      expect(find.bySemanticsLabel(LumoLivingState.listen.semanticLabel),
          findsOneWidget);
      await _shot(tester, '$name-02-counting');
      for (var i = 3; i < 8; i++) {
        await _tap(tester, 'lumo-tens-block-$i');
        await _frames(tester, 100);
      }
      await _frames(tester, 500);
      expect(find.text('84 = 80 + 4'), findsOneWidget);
      expect(find.bySemanticsLabel(LumoLivingState.approve.semanticLabel),
          findsOneWidget);
      await _shot(tester, '$name-03-counted');

      // Methodenwechsel: Eine Stange öffnet sich in zehn Würfel.
      await _tap(tester, 'lumo-place-value-bundle-mode');
      for (final ms in [120, 300, 500]) {
        await tester.pump(Duration(milliseconds: ms == 120 ? 120 : 180));
        await _shot(tester, '$name-04-open-${ms}ms');
      }
      await _frames(tester, 600);
      expect(find.byKey(const ValueKey('lumo-loose-cube-13')), findsOneWidget);
      expect(find.bySemanticsLabel(LumoLivingState.think.semanticLabel),
          findsOneWidget);

      // Lumo zeigt das Bündeln vor und gibt die Würfel zurück.
      await _tap(tester, 'lumo-place-value-demo');
      expect(find.bySemanticsLabel(LumoLivingState.demonstrate.semanticLabel),
          findsOneWidget);
      for (final ms in [500, 1300, 2000]) {
        await tester.pump(Duration(milliseconds: ms == 500 ? 500 : 750));
        await _shot(tester, '$name-05-demo-${ms}ms');
      }
      await _frames(tester, 600);

      // Das Kind wählt zehn Würfel und bündelt selbst.
      for (var i = 0; i < 10; i++) {
        await _tap(tester, 'lumo-loose-cube-$i');
      }
      await _frames(tester, 300);
      expect(find.text('10 Würfel ausgewählt'), findsOneWidget);
      await _shot(tester, '$name-06-selected');
      await _tap(tester, 'lumo-bundle-ten');
      for (final ms in [150, 400, 650]) {
        await tester.pump(const Duration(milliseconds: 250));
        await _shot(tester, '$name-07-bundle-${ms}ms');
      }
      await _frames(tester, 700);
      expect(find.textContaining('8 Zehner und 4 Einer'), findsOneWidget);
      expect(find.byKey(const ValueKey('lumo-tens-block-7')), findsOneWidget);
      await _shot(tester, '$name-08-bundled');

      // Ohne Lumos Hilfe eine andere Zahl bauen; ein Fehler macht Mut.
      await _tap(tester, 'lumo-place-value-build-next');
      await _frames(tester, 500);
      expect(find.bySemanticsLabel(LumoLivingState.idea.semanticLabel),
          findsOneWidget);
      for (var i = 0; i < 4; i++) {
        await _tap(tester, 'lumo-build-add-ten');
      }
      for (var i = 0; i < 7; i++) {
        await _tap(tester, 'lumo-build-add-one');
      }
      await _tap(tester, 'lumo-build-check');
      await _frames(tester, 200);
      expect(find.bySemanticsLabel(LumoLivingState.encourage.semanticLabel),
          findsOneWidget);
      expect(find.textContaining('Jede Stange zählt zehn'), findsOneWidget);
      await _frames(tester, 400);
      await _shot(tester, '$name-09-encourage');
      await _tap(tester, 'lumo-build-add-ten');
      await _frames(tester, 400);
      await _tap(tester, 'lumo-build-check');
      await _frames(tester, 500);
      expect(find.bySemanticsLabel(LumoLivingState.listen.semanticLabel),
          findsOneWidget);
      await _shot(tester, '$name-10-explain');
      expect(results, isEmpty);

      // Erklär es Lumo: richtig, aber nach einem Fehler = mit Übung.
      await _tap(tester, 'lumo-comprehension-7');
      await _frames(tester, 300);
      expect(results.single.number, 57);
      expect(results.single.independent, isFalse);
      expect(find.bySemanticsLabel(LumoLivingState.encourage.semanticLabel),
          findsOneWidget);
      await _frames(tester, 900);
      await _shot(tester, '$name-11-done-practice');
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets('real independent success celebrates once', (tester) async {
    const size = Size(412, 915);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();
    final results = <LumoPlaceValueTransfer>[];
    await tester.pumpWidget(_app(size, 1,
        LumoPlaceValueWorkshop(number: 84, onTransferChecked: results.add)));
    await _settleImages(tester);
    for (var i = 0; i < 8; i++) {
      await _tap(tester, 'lumo-tens-block-$i');
    }
    await _tap(tester, 'lumo-place-value-build-next');
    for (var i = 0; i < 5; i++) {
      await _tap(tester, 'lumo-build-add-ten');
    }
    for (var i = 0; i < 7; i++) {
      await _tap(tester, 'lumo-build-add-one');
    }
    await _tap(tester, 'lumo-build-check');
    await _tap(tester, 'lumo-comprehension-7');
    expect(results.single.independent, isTrue);
    expect(find.bySemanticsLabel(LumoLivingState.celebrate.semanticLabel),
        findsOneWidget);
    for (final ms in [200, 500, 800]) {
      await tester.pump(const Duration(milliseconds: 300));
      await _shot(tester, 'phone-12-celebrate-${ms}ms');
    }
    await _frames(tester, 1200);
    expect(find.text('57 = 50 + 7'), findsOneWidget);
    expect(results, hasLength(1));
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('reduce motion: end states at once, still demonstration',
      (tester) async {
    const size = Size(344, 882);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(size, 1.3,
        const LumoPlaceValueWorkshop(number: 84, reduceMotion: true)));
    await tester.pump();
    await _tap(tester, 'lumo-place-value-bundle-mode');
    // Ohne Flug sind alle vierzehn Würfel sofort da.
    expect(find.byKey(const ValueKey('lumo-loose-cube-13')), findsOneWidget);
    expect(find.text('Lumo zeigt: 10 Einer = 1 Zehner'), findsNothing);
    await _tap(tester, 'lumo-place-value-demo');
    expect(find.text('Lumo zeigt: 10 Einer = 1 Zehner'), findsOneWidget);
    // Keine Endlosschleife: Nach dem Tipp-Ripple steht die Szene still.
    await tester.pump(const Duration(seconds: 2));
    expect(tester.binding.hasScheduledFrame, isFalse);
    await _shot(tester, 'fold-cover-calm-demo');
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(412, 915), const Size(344, 882)]) {
    testWidgets('eight rods form balanced four plus four rows at ${size.width}dp',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_app(size, 1,
          const LumoPlaceValueWorkshop(number: 84, reduceMotion: true)));
      await tester.pump();
      final positions = [
        for (var i = 0; i < 8; i++)
          tester.getTopLeft(find.byKey(ValueKey('lumo-tens-block-$i')))
      ];
      for (var i = 1; i < 4; i++) {
        expect(positions[i].dy, closeTo(positions[0].dy, .5));
      }
      for (var i = 5; i < 8; i++) {
        expect(positions[i].dy, closeTo(positions[4].dy, .5));
      }
      expect(positions[4].dy, greaterThan(positions[0].dy + 40));
      expect(tester.takeException(), isNull);
    });
  }

  for (final (size, expected) in [
    (const Size(344, 882), 96.0),
    (const Size(690, 829), 132.0),
    (const Size(882, 690), 164.0),
  ]) {
    testWidgets('original Lumo has responsive ${expected.toInt()}dp presence at ${size.width}dp',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_app(size, 1,
          const LumoPlaceValueWorkshop(number: 84, reduceMotion: true)));
      await tester.pump();
      final lumo = find.byType(LumoLivingCharacter);
      expect(lumo, findsOneWidget);
      expect(tester.getSize(lumo).width, closeTo(expected, 1));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Lumos moving demonstration hides its ten source cubes',
      (tester) async {
    const size = Size(412, 915);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(size, 1,
        const LumoPlaceValueWorkshop(number: 84)));
    await _settleImages(tester);
    await _frames(tester, 1600);
    await _tap(tester, 'lumo-place-value-bundle-mode');
    // First let the 950ms opening transformation finish. Otherwise both
    // concurrent movements deliberately mask their combined source cubes.
    await _frames(tester, 1250);
    final afterOpening = tester.widgetList<PlaceValueCube>(
        find.byType(PlaceValueCube)).where((cube) => cube.hidden).length;
    expect(afterOpening, 0);
    await _tap(tester, 'lumo-place-value-demo');
    await tester.pump(const Duration(milliseconds: 50));
    // The ten moving pixels represent the actual ten pieces, not a second
    // overlapping set of unchanged cubes beneath the animated flight.
    final hiddenSource = tester.widgetList<PlaceValueCube>(
        find.byType(PlaceValueCube)).where((cube) => cube.hidden).length;
    expect(hiddenSource, 10);
    await _frames(tester, 2400);
    final hiddenAfter = tester.widgetList<PlaceValueCube>(
        find.byType(PlaceValueCube)).where((cube) => cube.hidden).length;
    expect(hiddenAfter, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every child action has a touch target of at least 48 dp',
      (tester) async {
    const size = Size(344, 882);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(
        size, 1, const LumoPlaceValueWorkshop(number: 84, reduceMotion: true)));
    await tester.pump();
    void expectTarget(String key) {
      final box = tester.getSize(find.byKey(ValueKey(key)));
      expect(box.width, greaterThanOrEqualTo(48), reason: key);
      expect(box.height, greaterThanOrEqualTo(48), reason: key);
    }

    for (var i = 0; i < 8; i++) {
      expectTarget('lumo-tens-block-$i');
    }
    expectTarget('lumo-place-value-count-mode');
    expectTarget('lumo-place-value-bundle-mode');
    await _tap(tester, 'lumo-place-value-bundle-mode');
    for (var i = 0; i < 14; i++) {
      expectTarget('lumo-loose-cube-$i');
    }
    expectTarget('lumo-place-value-demo');
    expectTarget('lumo-bundle-ten');
    expect(tester.takeException(), isNull);
  });
}
