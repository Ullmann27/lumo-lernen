import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/learning/lumo_abc_tafel_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ABC shows its own Lumo artwork, 26 entries and a readable guide',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LumoAbcTafelScreen()));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Entdecke dein ABC!'), findsOneWidget);
    expect(find.byKey(const ValueKey('abc-original-lumo-fox')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('abc-letter-A')), findsOneWidget);
    expect(find.text('Wähle deinen ersten Buchstaben!'), findsOneWidget);
    expect(find.text('A a'), findsOneWidget);
    // The list still contains the same 26 index slots; the lazy grid keeps
    // its children correct as we scroll to the end.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('abc-letter-Z')),
      420,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Z z'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a letter selects and offers replay without audio setup',
      (tester) async {
    final wasEnabled = LumoVoice.instance.isEnabled;
    LumoVoice.instance.isEnabled = false;
    try {
      await tester.pumpWidget(const MaterialApp(home: LumoAbcTafelScreen()));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.byKey(const ValueKey('abc-letter-A')));
      await tester.pump();
      expect(find.text('A wie Affe'), findsOneWidget);
      expect(find.byKey(const ValueKey('abc-replay-sound')), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      LumoVoice.instance.isEnabled = wasEnabled;
    }
  });

  testWidgets('real Flutter ABC renders on phone, Fold cover and inner screen',
      (tester) async {
    final folder = Directory('visual-evidence')..createSync(recursive: true);
    final screens = <(String, Size)>[
      ('phone_390x844', const Size(390, 844)),
      ('fold_cover_320x780', const Size(320, 780)),
      ('fold_open_840x760', const Size(840, 760)),
    ];
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    for (final (name, size) in screens) {
      await tester.binding.setSurfaceSize(size);
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: const MaterialApp(home: LumoAbcTafelScreen()),
      ));
      await tester.pump(const Duration(milliseconds: 450));
      expect(find.text('Entdecke dein ABC!'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final layer = key.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      // RenderRepaintBoundary rasterization runs outside fake-async. The
      // normal testWidgets clock otherwise deadlocks for ten minutes in CI.
      await tester.runAsync(() async {
        final image = await layer.toImage(pixelRatio: 1.5);
        try {
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          expect(data, isNotNull);
          await File('${folder.path}/abc_premium_$name.png')
              .writeAsBytes(data!.buffer.asUint8List(), flush: true);
        } finally {
          image.dispose();
        }
      });
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
