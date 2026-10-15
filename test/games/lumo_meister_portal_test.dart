import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/domain/games/game_level_catalog.dart';
import 'package:lumo_lernen/features/games/games_content.dart';
import 'package:lumo_lernen/features/quiz/quiz_show_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
  });

  test('Level 50 traegt konsistent den Namen Lumo-Meister', () {
    final level = GameLevelCatalog.byId(50);
    expect(level, isNotNull);
    expect(level!.title, 'Lumo-Meister');
    expect(level.learningGoal, contains('Meister-Finale'));
  });

  testWidgets('Spielewelt zeigt einen direkten Lumo-Meister-Einstieg',
      (tester) async {
    final appState = LumoAppState();
    addTearDown(appState.dispose);

    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GamesContent(appState: appState),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final portal = find.byKey(const ValueKey('games-lumo-meister-portal'));
    if (portal.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        portal,
        300,
        scrollable: find.byType(Scrollable).first,
      );
    }

    expect(portal, findsOneWidget);
    expect(find.text('Wer wird Lumo-Meister?'), findsOneWidget);
    expect(find.text('20 Fragen · 3 Joker · bis 5.000 Sterne'), findsOneWidget);

    await tester.tap(portal);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(QuizShowContent), findsOneWidget);
    expect(find.text('Wer wird Lumo-Meister?'), findsWidgets);
  });
}
