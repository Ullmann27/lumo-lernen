// Echte Aufnahmen des Lumo Knobel-Tests (kein Konzeptbild): der echte
// Bildschirm läuft mit festem Seed durch Antippen durch und wird auf
// Telefon- und Fold-Größe in PNG-Dateien geschrieben.
// Läuft nur mit LUMO_TOUR_DIR=<ordner>, sonst übersprungen.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_shell.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/iq/iq_test_repository.dart';
import 'package:lumo_lernen/core/iq/iq_test_session.dart';
import 'package:lumo_lernen/core/user_profile.dart';
import 'package:lumo_lernen/domain/iq/iq_puzzle.dart';
import 'package:lumo_lernen/features/tests/lumo_tests_screen.dart';

import '../iq/iq_test_support.dart';

final String? _out = Platform.environment['LUMO_TOUR_DIR'];
const _boundary = ValueKey('lumo-iq-capture');

const sizes = <String, Size>{
  'phone': Size(412, 915),
  'fold': Size(690, 829),
};

/// Diese Rätsel (von 0 bis 23) werden absichtlich falsch beantwortet, damit
/// der Rückblick Lösungen zeigen kann.
const _wrong = {3, 6, 10, 13, 17, 20};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadIqFonts);
  setUp(resetIqEnvironment);

  Future<void> capture(
    WidgetTester tester,
    String name, {
    double pixelRatio = 1.5,
    int frames = 4,
  }) async {
    await tester.runAsync(() async {
      await Future.wait(tester.widgetList<Image>(find.byType(Image)).map(
          (image) => precacheImage(image.image, tester.element(find.byWidget(image)))
              .catchError((_) {})));
    });
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    final render = tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary));
    await tester.runAsync(() async {
      final image = await render.toImage(pixelRatio: pixelRatio);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$_out/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  // Telefon im Querformat: Start, zwei Rätsel, Ergebnis.
  testWidgets('Knobel-Test Aufnahmen Querformat', (tester) async {
    await tester.binding.setSurfaceSize(const Size(915, 412));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = iqTestApp();
    final session = IqTestSession(grade: 2, seed: 41);
    await tester.pumpWidget(iqScreenApp(app, session: session, boundary: _boundary));
    await settleIq(tester);
    await capture(tester, 'quer_01_start');
    await startIqTest(tester);
    var index = 0;
    for (var area = 0; area < IqArea.values.length; area++) {
      await leaveAreaIntro(tester);
      for (var item = 0; item < session.itemsPerArea; item++) {
        final puzzle = session.current;
        if (item == 2 && (puzzle is IqMatrixPuzzle || puzzle is IqRotationPuzzle)) {
          await tapKey(tester, 'iq-option-${(puzzle as IqChoicePuzzle).answer}');
          await capture(tester, 'quer_03_raetsel_${area == 0 ? 'matrix' : 'rotation'}');
        }
        await answerCurrent(tester, session, correct: !_wrong.contains(index));
        index++;
      }
    }
    await capture(tester, 'quer_04_ergebnis');
    expect(tester.takeException(), isNull);
  }, skip: _out == null);

  for (final size in sizes.entries) {
    testWidgets('Knobel-Test Aufnahmen ${size.key}', (tester) async {
      final tag = size.key;
      await tester.binding.setSurfaceSize(size.value);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const repository = IqTestRepository();
      await tester.runAsync(() => repository.save(earlierIqResult()));
      final app = iqTestApp();
      final session = IqTestSession(grade: 2, seed: 41);
      await tester.pumpWidget(
        iqScreenApp(app, session: session, boundary: _boundary, repository: repository),
      );
      await settleIq(tester);
      await capture(tester, '${tag}_01_start');

      await startIqTest(tester);
      await capture(tester, '${tag}_02_anleitung_matrix');

      const names = ['matrix', 'series', 'oddone', 'rotation', 'numbers', 'memory'];
      var index = 0;
      for (var area = 0; area < IqArea.values.length; area++) {
        if (area > 0) await capture(tester, '${tag}_02_anleitung_${names[area]}');
        await leaveAreaIntro(tester);
        for (var item = 0; item < session.itemsPerArea; item++) {
          if (item == 2) {
            final puzzle = session.current;
            if (puzzle is IqMemoryPuzzle) {
              // Vorführung neu starten und mitten im ersten Aufleuchten halten.
              await tester.tap(find.byKey(const ValueKey('iq-replay')));
              await tester.pump(Duration(milliseconds: 650 + puzzle.showMs ~/ 2));
              await capture(tester, '${tag}_03_raetsel_${names[area]}_zeigen',
                  frames: 0);
              await waitForMemoryShow(tester, puzzle);
              await tapKey(tester, 'iq-memory-tile-${puzzle.sequence[0]}');
              await tapKey(tester, 'iq-memory-tile-${puzzle.sequence[1]}');
              await capture(tester, '${tag}_03_raetsel_${names[area]}');
            } else if (puzzle is IqChoicePuzzle) {
              // Eine Karte ist markiert, damit man die Hervorhebung sieht.
              await tapKey(tester, 'iq-option-${puzzle.answer}');
              await capture(tester, '${tag}_03_raetsel_${names[area]}');
            }
          }
          await answerCurrent(tester, session, correct: !_wrong.contains(index));
          index++;
        }
      }
      expect(find.byKey(const ValueKey('iq-points')), findsOneWidget);
      await capture(tester, '${tag}_04_ergebnis');

      // Ganze Ergebnisseite auf einmal: die Fläche ist so hoch wie der Inhalt.
      final scrollable = find.descendant(
        of: find.byKey(const ValueKey('iq-result-scroll')),
        matching: find.byType(Scrollable),
      );
      final extra = tester.state<ScrollableState>(scrollable).position.maxScrollExtent;
      await tester.binding.setSurfaceSize(Size(size.value.width, size.value.height + extra));
      await tester.pump(const Duration(milliseconds: 200));
      await capture(tester, '${tag}_04_ergebnis_komplett', pixelRatio: 1);
      await tester.binding.setSurfaceSize(size.value);
      await tester.pump(const Duration(milliseconds: 200));

      await tapKey(tester, 'iq-result-review');
      await capture(tester, '${tag}_05_rueckblick');
      final firstWrong = find.byKey(ValueKey('iq-review-solution-${_wrong.first}'));
      await tester.ensureVisible(firstWrong);
      await tester.pump(const Duration(milliseconds: 200));
      await capture(tester, '${tag}_05_rueckblick_loesung');
      final rotationWrong = find.byKey(const ValueKey('iq-review-solution-13'));
      await tester.ensureVisible(rotationWrong);
      await tester.pump(const Duration(milliseconds: 200));
      await capture(tester, '${tag}_05_rueckblick_drehen');
      expect(tester.takeException(), isNull);
    }, skip: _out == null);

    testWidgets('Tests-Seite mit Knobel-Karte ${size.key}', (tester) async {
      await tester.binding.setSurfaceSize(size.value);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.runAsync(() => const IqTestRepository().save(earlierIqResult()));
      final date = DateTime(2026, 10, 8);
      await tester.pumpWidget(MaterialApp(
        theme: LumoAppTheme.light(),
        home: RepaintBoundary(
          key: _boundary,
          child: AppShell(
            profile: UserProfile(
              id: 'tour',
              name: 'Mia',
              age: 8,
              grade: 2,
              createdAt: date,
              lastActiveAt: date,
            ),
            initialSection: LumoSection.tests,
          ),
        ),
      ));
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 200));
      }
      final card = find.byKey(const ValueKey('iq-test-start'));
      if (card.evaluate().isEmpty) {
        // Auf dem Fold ist die Karte erst nach etwas Scrollen gebaut.
        await tester.scrollUntilVisible(
          card,
          250,
          scrollable: find
              .descendant(
                  of: find.byType(LumoTestsScreen), matching: find.byType(Scrollable))
              .first,
        );
      }
      expect(card, findsOneWidget);
      await tester.ensureVisible(card);
      await capture(tester, '${size.key}_06_tests_seite');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }, skip: _out == null);
  }
}
