import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/quiz/quiz_show_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Three live jokers, mascot and prize rail remain separated',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final width in <double>[280, 320, 360, 420, 720, 1024]) {
      await tester.binding.setSurfaceSize(Size(width, 1050));
      final app = LumoAppState();
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: QuizShowContent(appState: app),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 260));

      final stage = find.byKey(const ValueKey('lumo-meister-stage'));
      final joker = find.byKey(const ValueKey('lumo-meister-joker-rail'));
      final mascot = find.byKey(const ValueKey('lumo-meister-fox-slot'));
      final prize = find.byKey(const ValueKey('lumo-meister-prize-rail'));
      expect(stage, findsOneWidget);
      expect(joker, findsOneWidget);
      expect(mascot, findsOneWidget);
      expect(prize, findsOneWidget);
      expect(find.byKey(const ValueKey('lumo-meister-fox')), findsOneWidget);
      expect(find.byKey(const ValueKey('lumo-meister-prize-step-20')), findsOneWidget);
      expect(find.byKey(const ValueKey('lumo-meister-prize-step-1')), findsOneWidget);
      expect(find.text('50:50'), findsOneWidget);
      expect(find.text('Publikum'), findsOneWidget);
      expect(find.text('Lumo-Tipp'), findsOneWidget);

      final left = tester.getRect(joker);
      final center = tester.getRect(mascot);
      final right = tester.getRect(prize);
      expect(left.right, lessThanOrEqualTo(center.left + .1),
          reason: 'Jokers must not overlap mascot at width $width');
      expect(center.right, lessThanOrEqualTo(right.left + .1),
          reason: 'Mascot must not overlap prize rail at width $width');
      if (width == 320) {
        expect(tester.getSize(mascot).width, greaterThanOrEqualTo(125),
          reason: 'Moderator must stay prominent even on a Fold cover display');
      }
      expect(tester.takeException(), isNull,
          reason: 'No Flex or render overflow at width $width');
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
    }
  });

  testWidgets('Lumo remains present after selecting and revealing a question',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState();
    addTearDown(app.dispose);
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: QuizShowContent(appState: app),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 260));

    final answer = find.byKey(const ValueKey('lumo-meister-answer-0'));
    expect(answer, findsOneWidget);
    await tester.ensureVisible(answer);
    await tester.pump();
    await tester.tap(answer);
    await tester.pump(const Duration(milliseconds: 100));

    final reveal = find.text('Antwort einloggen');
    await tester.ensureVisible(reveal);
    await tester.pump();
    await tester.tap(reveal);
    await tester.pump(const Duration(milliseconds: 260));
    expect(find.byKey(const ValueKey('lumo-meister-fox')), findsOneWidget);
    expect(find.byKey(const ValueKey('lumo-meister-stage')), findsOneWidget);
    expect(find.byKey(const ValueKey('lumo-meister-fox')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
