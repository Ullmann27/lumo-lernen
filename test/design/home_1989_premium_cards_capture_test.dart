import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/features/home/home_content.dart';
import 'package:lumo_lernen/features/home/widgets/lumo_subject_showcase_card.dart';
import '../helpers/lumo_capture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLumoCaptureFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Premium learning cards: complete description, progress and tap',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(160, 198));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var pressed = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LumoSubjectShowcaseCard(
          subject: 'Mathematik',
          shortName: 'Mathe',
          subtitle: 'Zahlen, Rechnen und Formen',
          icon: Icons.calculate_rounded,
          accent: const Color(0xFFFFC04A),
          completed: 5,
          onTap: () => pressed++,
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('Mathe'), findsOneWidget);
    expect(find.text('Zahlen, Rechnen und Formen'), findsOneWidget);
    expect(find.text('5 Aufgaben geschafft'), findsOneWidget);
    expect(find.text('MEIN FORTSCHRITT'), findsOneWidget);
    final progress = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator));
    expect(progress.value, .5);
    await tester.tap(find.byKey(const ValueKey('home-island-mathe')));
    expect(pressed, 1);
    expect(tester.takeException(), isNull);
  });

  for (final (device, size, textScale) in <(String, Size, double)>[
    ('phone', const Size(393, 852), 1.0),
    ('fold-cover', const Size(320, 740), 1.2),
    ('fold-open', const Size(840, 960), 1.0),
  ]) {
    testWidgets('Real home premium islands $device', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final state = LumoAppState();
      addTearDown(state.dispose);
      const captureKey = ValueKey('home-1989-boundary');
      await tester.pumpWidget(
        MaterialApp(
          theme: LumoAppTheme.light(),
          home: MediaQuery(
            data: MediaQueryData(
              disableAnimations: true,
              textScaler: TextScaler.linear(textScale),
            ),
            child: Scaffold(
              body: RepaintBoundary(
                key: captureKey,
                child: HomeContent(appState: state, onSection: (_) {}),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));
      final out = Platform.environment['LUMO_1989_CARD_CAPTURES'];
      if (out != null) {
        await captureLumoBoundary(
          tester, captureKey, '$out/$device-start.png',
        );
      }
      final first = find.byKey(const ValueKey('home-island-mathe'));
      await tester.scrollUntilVisible(
        first, 270, scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(first, findsOneWidget);
      final deutsch = find.byKey(const ValueKey('home-island-deutsch'));
      expect(deutsch, findsOneWidget);
      if (size.width < 460) {
        final matheRect = tester.getRect(first);
        final deutschRect = tester.getRect(deutsch);
        expect(deutschRect.top, greaterThanOrEqualTo(matheRect.bottom),
            reason: 'Narrow phone needs full-width legible card rows');
        expect(deutschRect.left, closeTo(matheRect.left, 1));
      }
      expect(tester.takeException(), isNull,
          reason: 'No small-cover/Fold overflow for $device');
      if (out != null) {
        await captureLumoBoundary(
          tester, captureKey, '$out/$device-learning-cards.png',
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 300));
    });
  }
}
