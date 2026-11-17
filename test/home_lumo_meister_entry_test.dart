import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/features/games/games_content.dart';
import 'package:lumo_lernen/features/home/home_content.dart';
import 'package:lumo_lernen/features/quiz/quiz_show_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'Home Lumo-Meister shortcut enters protected game world and starts the real 20-question show',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final appState = LumoAppState();
    addTearDown(appState.dispose);
    appState.updateSettings(const AppSettings(
      soundEnabled: false,
      voiceEnabled: false,
      autoReadEnabled: false,
      reduceAnimations: true,
    ));

    var inGameWorld = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setLocalState) => inGameWorld
                ? GamesContent(
                    appState: appState,
                    onSection: (_) {},
                    drawBackground: false,
                  )
                : HomeContent(
                    appState: appState,
                    onSection: (section) {
                      expect(section, LumoSection.games,
                          reason: 'The home shortcut must not bypass parental game access.');
                      setLocalState(() => inGameWorld = true);
                    },
                  ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull, reason: 'Home initial layout');

    final discover =
        find.byKey(const PageStorageKey<String>('home-discover'));
    await tester.scrollUntilVisible(
      discover, 280, scrollable: find.byType(Scrollable).first,
      maxScrolls: 60,
    );
    await tester.pump();
    await Scrollable.ensureVisible(
      tester.element(discover), alignment: 0.5,
    );
    await tester.pump();
    expect(discover.hitTestable(), findsOneWidget);
    await tester.tap(discover);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    final meister = find.text('Wer wird Lumo-Meister?');
    await tester.scrollUntilVisible(
      meister, 240, scrollable: find.byType(Scrollable).first,
      maxScrolls: 60,
    );
    await tester.pump();
    await Scrollable.ensureVisible(
      tester.element(meister), alignment: 0.5,
    );
    await tester.pump();
    expect(meister.hitTestable(), findsOneWidget);
    await tester.tap(meister);
    await tester.pump();
    expect(inGameWorld, isTrue);
    expect(find.byType(GamesContent), findsOneWidget);

    // The actual Spielwelt loads saved level/unlock data asynchronously.
    // Do not launch the quiz until its real portal has been built.
    final quizPortal =
        find.byKey(const ValueKey('spielwelt-portal-quizShow'));
    for (var attempt = 0; attempt < 40 &&
        quizPortal.evaluate().isEmpty; attempt++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(quizPortal, findsOneWidget);
    await tester.ensureVisible(quizPortal);
    await tester.pump();
    expect(quizPortal.hitTestable(), findsOneWidget);
    await tester.tap(quizPortal);
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(QuizShowContent), findsOneWidget);
    expect(find.text('Wer wird Lumo-Meister?'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
