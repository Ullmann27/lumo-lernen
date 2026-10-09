import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/theme/lumo_visual_tokens.dart';
import 'package:lumo_lernen/widgets/design/lumo_design_system.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_cards_score_header.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_intro_splash.dart';
import 'package:lumo_lernen/features/shared/widgets/lumo_audio_settings_sheet.dart';

void main() {
  testWidgets('learning glass stays readable and tiles retain their actions',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(children: [
            const LumoGlassCard(
              child: Text('Mathe-Abenteuer'),
            ),
            SizedBox(
              width: 220,
              height: 175,
              child: LumoColorTile(
                icon: Icons.book_rounded,
                title: 'Lernen',
                subtitle: 'Mathematik und Deutsch',
                color: LumoVisualTokens.learning,
                onTap: () => taps++,
              ),
            ),
          ]),
        ),
      ),
    ));
    await tester.pump();

    final allDecorations = tester
        .widgetList<Container>(find.byType(Container))
        .map((container) => container.decoration)
        .whereType<BoxDecoration>()
        .toList();
    expect(
      allDecorations.any((decoration) =>
          decoration.gradient is LinearGradient &&
          decoration.borderRadius != null),
      isTrue,
      reason: 'Learning glass must use real multi-stop highlights.',
    );
    expect(find.text('Mathe-Abenteuer'), findsOneWidget);
    await tester.tap(find.text('Lernen'));
    await tester.pump();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lumo Cards scoreboard is branded, readable and touch-safe',
      (tester) async {
    var back = 0;
    var pause = 0;
    var audio = 0;
    await tester.binding.setSurfaceSize(const Size(320, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        backgroundColor: LumoVisualTokens.night,
        body: SafeArea(child: LumoCardsScoreHeader(
          round: 2,
          totalRounds: 3,
          targetPoints: 24,
          onClose: () => back++,
          onSettings: () => pause++,
          onAudioSettings: () => audio++,
        )),
      ),
    ));
    await tester.pump();

    expect(find.text('Lumo Cards'), findsOneWidget);
    expect(find.text('Runde 2/3'), findsOneWidget);
    expect(find.text('24 Sterne'), findsOneWidget);
    expect(find.byKey(const ValueKey('lumo-cards-real-fox')), findsOneWidget);
    expect(find.text('🦊 Lumo Cards'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Pausieren / Zurück'));
    await tester.tap(find.byTooltip('Pause und Neustart'));
    await tester.tap(find.byTooltip('Ton einstellen'));
    expect([back, pause, audio], [1, 1, 1]);
  });

  testWidgets('Cards audio panel uses readable blue glass instead of paper',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: LumoVisualTokens.night,
          body: SafeArea(child: LumoAudioSettingsSheet()),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Ton'), findsOneWidget);
    expect(find.text('Musik'), findsOneWidget);
    expect(find.text('Sound-Effekte'), findsOneWidget);
    expect(find.text('Fertig'), findsOneWidget);
    final decorations = tester
        .widgetList<Container>(find.byType(Container))
        .map((e) => e.decoration)
        .whereType<BoxDecoration>()
        .toList();
    expect(
      decorations.any((d) =>
          d.gradient is LinearGradient &&
          d.border?.top.color == LumoVisualTokens.cyan.withOpacity(0.42)),
      isTrue,
      reason: 'Audio controls must use the shared dark-blue/cyan design.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cards intro uses the original fox and can be skipped once',
      (tester) async {
    var completed = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Stack(children: [
          LumoIntroSplash(onComplete: () => completed++),
        ]),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byKey(const ValueKey('lumo-cards-intro-fox')),
        findsOneWidget);
    await tester.tap(find.byType(LumoIntroSplash));
    await tester.pump();
    expect(completed, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Fold landscape keeps the complete Lumo Cards title',
      (tester) async {
    var audioTaps = 0;
    var pauseTaps = 0;
    await tester.binding.setSurfaceSize(const Size(250, 420));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        backgroundColor: LumoVisualTokens.night,
        body: SafeArea(
          child: LumoCardsScoreHeader(
            round: 1,
            totalRounds: 2,
            targetPoints: 9,
            onAudioSettings: () => audioTaps++,
            onSettings: () => pauseTaps++,
          ),
        ),
      ),
    ));
    await tester.pump();
    final brandFinder = find.byKey(const ValueKey('lumo-cards-brand'));
    final brand = tester.widget<Text>(brandFinder);
    final painter = TextPainter(
      text: TextSpan(text: brand.data!, style: brand.style),
      textDirection: TextDirection.ltr,
    )..layout();
    expect(tester.getSize(brandFinder).width,
        greaterThanOrEqualTo(painter.width),
        reason: 'Landscape title must not end in an ellipsis.');
    painter.dispose();
    expect(find.text('Lumo Cards'), findsOneWidget);
    expect(find.text('Runde 1/2'), findsOneWidget);
    expect(find.text('9 Sterne'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Ton einstellen'));
    await tester.tap(find.byTooltip('Pause und Neustart'));
    expect([audioTaps, pauseTaps], [1, 1]);
  });

}
