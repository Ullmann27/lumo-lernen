import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/settings/local_voice_license_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late String license;
  setUpAll(() async {
    // Real asset I/O belongs to the real event loop, not the widget clock.
    license = await rootBundle
        .loadString('assets/audio/voice/lumo_free/LICENSE-MODEL.txt');
  });

  for (final (name, size, textScale) in [
    ('small phone', const Size(320, 568), 2.0),
    ('fold', const Size(967, 805), 1.0),
    ('tablet', const Size(1024, 768), 1.5),
  ]) {
    testWidgets('model terms require explicit assent without overflow on $name',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      expect(license, contains('Open RAIL-M'));
      bool? accepted;
      await tester.pumpWidget(MaterialApp(
        builder: (_, child) => MediaQuery(
          data: MediaQueryData(
              size: size, textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Builder(builder: (context) {
          return Scaffold(
            body: FilledButton(
              onPressed: () async {
                accepted = await LocalVoiceLicenseDialog.show(context);
              },
              child: const Text('Test öffnen'),
            ),
          );
        }),
      ));
      await tester.runAsync(() async {
        await tester.tap(find.text('Test öffnen'));
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      final allow =
          find.widgetWithText(FilledButton, 'Lokale Stimme freigeben');
      expect(tester.widget<FilledButton>(allow).onPressed, isNull);
      expect(accepted, isNull);
      expect(find.textContaining('kein Sprach-API-Aufruf'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final checkbox = find.byType(Checkbox);
      await tester.ensureVisible(checkbox);
      await tester.pump(const Duration(milliseconds: 350));
      expect(tester.getRect(checkbox).center.dy, lessThan(size.height));
      await tester.tap(checkbox);
      await tester.pump();
      expect(tester.widget<FilledButton>(allow).onPressed, isNotNull);
      await tester.ensureVisible(allow);
      await tester.runAsync(() async {
        await tester.tap(allow);
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump(const Duration(milliseconds: 350));
      expect(accepted, true);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('closing the license dialog does not authorize anything',
      (tester) async {
    bool? accepted;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
          builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    accepted = await LocalVoiceLicenseDialog.show(context);
                  },
                  child: const Text('Öffnen'),
                ),
              )),
    ));
    await tester.runAsync(() async {
      await tester.tap(find.text('Öffnen'));
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump(const Duration(milliseconds: 350));
    await tester.ensureVisible(find.text('Abbrechen'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.runAsync(() async {
      await tester.tap(find.text('Abbrechen'));
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump(const Duration(milliseconds: 350));
    expect(accepted, false);
    expect(tester.takeException(), isNull);
  });
}
