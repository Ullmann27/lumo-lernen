import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/quiz/quiz_show_content.dart';
import 'package:lumo_lernen/widgets/fox/lumo_character.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Lumo host stays inside its own slot on phone and Fold widths',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final width in <double>[220, 320, 420, 720, 1024]) {
      // Ohne reale Test-Viewport-Breite würde 1024 px auf 800 px geklemmt.
      await tester.binding.setSurfaceSize(Size(width + 40, 1400));
      for (final stage in <int>[1, 15, 20, 21]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: width,
                  child: MediaQuery(
                    data: const MediaQueryData(disableAnimations: true),
                    child: LumoMeisterHost(
                      questionNumber: stage == 21 ? 20 : stage,
                      finale: stage >= 20,
                      won: stage == 21,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 260));

        final host = find.byKey(const ValueKey('lumo-meister-host'));
        final slot = find.byKey(const ValueKey('lumo-meister-fox-slot'));
        final fox = find.byKey(const ValueKey('lumo-meister-fox'));
        final caption = find.byKey(
          const ValueKey('lumo-meister-host-caption'),
        );
        expect(host, findsOneWidget);
        expect(fox, findsOneWidget);
        expect(find.byType(LumoCharacter), findsOneWidget);

        final hostRect = tester.getRect(host);
        final slotRect = tester.getRect(slot);
        final foxRect = tester.getRect(fox);
        final captionRect = tester.getRect(caption);

        expect(slotRect.right, lessThanOrEqualTo(captionRect.left),
            reason: 'Lumo overlaps the text/joker reserved area at $width');
        expect(foxRect.left, greaterThanOrEqualTo(slotRect.left - .1));
        expect(foxRect.right, lessThanOrEqualTo(slotRect.right + .1));
        expect(captionRect.right, lessThanOrEqualTo(hostRect.right + .1));
        expect(tester.takeException(), isNull,
            reason: 'Host overflow at width=$width stage=$stage');
      }
    }
  });

  testWidgets('Lumo remains in the widget tree after an answer is revealed',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState();
    addTearDown(app.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: QuizShowContent(appState: app),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('lumo-meister-host')), findsOneWidget);
    expect(find.byKey(const ValueKey('lumo-meister-fox')), findsOneWidget);

    final answer = find.textContaining(RegExp(r'^A  '));
    expect(answer, findsOneWidget);
    await tester.ensureVisible(answer);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(answer);
    await tester.pump(const Duration(milliseconds: 100));

    final reveal = find.text('Antwort einloggen');
    await tester.ensureVisible(reveal);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(reveal);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('lumo-meister-host')), findsOneWidget);
    expect(find.byKey(const ValueKey('lumo-meister-fox')), findsOneWidget);
    expect(find.byType(LumoCharacter), findsOneWidget);
    expect(tester.takeException(), isNull,
        reason: 'No missing Lumo or RenderFlex overflow after feedback');
  });
}
