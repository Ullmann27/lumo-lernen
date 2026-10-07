import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/onboarding/lumo_onboarding_holo_screen.dart';

Future<void> _capture(
  WidgetTester tester,
  GlobalKey boundaryKey,
  String name,
) async {
  await tester.pump(const Duration(milliseconds: 320));
  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = (await tester.runAsync(() => boundary.toImage(pixelRatio: 1)))!;
  try {
    final data = await tester
        .runAsync(() => image.toByteData(format: ui.ImageByteFormat.png));
    expect(data, isNotNull);
    final directory = Directory('.ci-results/onboarding-visual')
      ..createSync(recursive: true);
    final file = File('${directory.path}/$name.png');
    file.writeAsBytesSync(data!.buffer.asUint8List(), flush: true);
    expect(file.lengthSync(), greaterThan(15000));
  } finally {
    image.dispose();
  }
}

Future<GlobalKey> _pumpOnboarding(
  WidgetTester tester,
  Size size,
) async {
  await tester.binding.setSurfaceSize(size);
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RepaintBoundary(
        key: key,
        child: LumoOnboardingScreen(onFinished: (_) {}),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 380));
  return key;
}

Future<void> _tapText(WidgetTester tester, String label) async {
  final finder = find.text(label);
  expect(finder, findsWidgets);
  await tester.ensureVisible(finder.last);
  await tester.tap(finder.last);
  await tester.pump(const Duration(milliseconds: 340));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('captures real onboarding runtime states at phone size',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final key = await _pumpOnboarding(tester, const Size(360, 800));
    await _capture(tester, key, 'welcome-360x800');

    await _tapText(tester, "Los geht's!");
    expect(find.text('Wie heißt du?'), findsOneWidget);
    await _capture(tester, key, 'name-360x800');

    await _tapText(tester, 'Weiter');
    expect(find.text('Wie alt bist du?'), findsOneWidget);
    await _capture(tester, key, 'age-360x800');

    await _tapText(tester, 'Weiter');
    expect(find.text('In welche Klasse gehst du?'), findsOneWidget);
    await _capture(tester, key, 'class-360x800');
  });

  testWidgets(
      'captures responsive onboarding at phone, fold-landscape and wide',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final entry in <(Size, String)>[
      (const Size(480, 800), 'welcome-480x800'),
      (const Size(840, 560), 'welcome-840x560'),
      (const Size(1024, 800), 'welcome-1024x800'),
    ]) {
      final key = await _pumpOnboarding(tester, entry.$1);
      expect(find.text('Willkommen'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _capture(tester, key, entry.$2);
    }
  });
}
