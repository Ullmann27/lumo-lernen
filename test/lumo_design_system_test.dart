import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/theme/lumo_visual_tokens.dart';
import 'package:lumo_lernen/widgets/design/lumo_design_system.dart';

void main() {
  test(
      'visual tokens preserve night glass with the requested blue learning accent',
      () {
    expect(LumoVisualTokens.night, const Color(0xFF03193F));
    expect(LumoVisualTokens.glass, const Color(0xFF063556));
    expect(LumoVisualTokens.glassRow, const Color(0xFF1F3F6C));
    expect(LumoVisualTokens.navigation, const Color(0xFF061839));
    expect(LumoVisualTokens.cyan, const Color(0xFF37D2FD));
    expect(LumoVisualTokens.cyanBright, const Color(0xFF53DDFD));
    expect(LumoVisualTokens.learning, const Color(0xFF328DFF));
    expect(LumoVisualTokens.games, const Color(0xFF5F2FBE));
    expect(LumoVisualTokens.tests, const Color(0xFF167A84));
    expect(LumoVisualTokens.rewards, const Color(0xFFB52E73));
  });

  testWidgets('design components compose and use the live wallet values',
      (tester) async {
    final appState = LumoAppState();
    addTearDown(appState.dispose);
    var tileTapped = false;
    appState.update(appState.state.copyWith(
      stars: 23,
      xp: 810,
      grade: 3,
    ));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LumoSceneBackground(
            scene: LumoScene.home,
            child: SizedBox(
              width: 440,
              height: 360,
              child: Column(
                children: [
                  LumoTopBar(appState: appState),
                  const LumoSpeechBubble(text: 'Los geht’s!'),
                  SizedBox(
                    width: 220,
                    height: 160,
                    child: LumoColorTile(
                      icon: Icons.menu_book_rounded,
                      title: 'Lernen',
                      subtitle: 'Deine Aufgaben',
                      color: LumoVisualTokens.learning,
                      onTap: () => tileTapped = true,
                    ),
                  ),
                  const LumoFoxPose(
                    pose: LumoDesignFoxPose.thumbWink,
                    size: 50,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('LUM'), findsOneWidget);
    expect(find.text('O'), findsOneWidget);
    // Die Szenenbilder sind fertig: kein Platzhalter-Schild mehr.
    expect(find.text('SZENENBILD-PLATZHALTER'), findsNothing);
    expect(find.text('Level 3'), findsOneWidget);
    expect(find.text('3. Klasse'), findsOneWidget);
    expect(find.text('23'), findsOneWidget);
    expect(find.text('10 / 400 XP'), findsOneWidget);
    expect(find.text('Los geht’s!'), findsOneWidget);
    expect(find.text('Lernen'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(LumoTopBar),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is LumoFoxPose && widget.pose == LumoDesignFoxPose.avatar,
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is LumoFoxPose && widget.pose == LumoDesignFoxPose.thumbWink,
      ),
      findsOneWidget,
    );
    expect(find.text('POSE FEHLT'), findsNothing);
    expect(tester.takeException(), isNull);

    appState.update(appState.state.copyWith(
      stars: 24,
      xp: 1200,
      grade: 4,
    ));
    await tester.pump();
    expect(find.text('Level 4'), findsOneWidget);
    expect(find.text('4. Klasse'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
    expect(find.text('0 / 400 XP'), findsOneWidget);

    await tester.tap(find.text('Lernen'));
    expect(tileTapped, isTrue);
  });

  testWidgets('mobile navigation has five requested destinations',
      (tester) async {
    LumoSection? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: LumoBottomNavigation(
              active: LumoSection.home,
              onSelect: (section) => selected = section,
            ),
          ),
        ),
      ),
    );

    for (final label in ['Start', 'Lernen', 'Spielen', 'Tests', 'Profil']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byType(LumoBottomNavigation), findsOneWidget);

    await tester.tap(find.text('Spielen'));
    expect(selected, LumoSection.games);
    await tester.tap(find.text('Tests'));
    expect(selected, LumoSection.tests);
  });

  testWidgets('Fold progress panel displays live tasks and wallet values',
      (tester) async {
    final appState = LumoAppState();
    addTearDown(appState.dispose);
    appState.update(appState.state.copyWith(stars: 17, xp: 240));
    var openedRewards = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: LumoFoldProgressPanel(
              appState: appState,
              onOpenRewards: () => openedRewards = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Dein Lernfortschritt'), findsOneWidget);
    expect(find.text('Tägliche Aufgaben'), findsOneWidget);
    expect(find.text('Deine Belohnungen'), findsOneWidget);
    expect(find.text('17 Sterne'), findsOneWidget);
    await tester.tap(find.text('Deine Belohnungen'));
    expect(openedRewards, isTrue);
    expect(tester.takeException(), isNull);
  });
}
