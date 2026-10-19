import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_story_generator.dart';
import 'package:lumo_lernen/core/lumo_story_summary_scoring.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/story/lumo_story_reader_screen.dart';

void main() {
  test('Summary keywords require whole words and known German endings', () {
    const keyPoints = ['Stern', 'Buch', 'Freund', 'Rätsel'];
    final accidental = LumoStorySummaryScorer.evaluate(
      summary: 'Sterben, Buchhaltung und Freundlichkeit sind keine '
          'Antworten. Wir rätseln noch.',
      keyPoints: keyPoints,
    );
    expect(accidental.hits, 1);
    expect(accidental.stars, 2);

    final valid = LumoStorySummaryScorer.evaluate(
      summary: 'Wir folgen den Sternen und lesen im Buches nach; '
          'die Freunde wollen gemeinsam rätseln.',
      keyPoints: keyPoints,
    );
    expect(valid.hits, 4);
    expect(valid.stars, 5);

    final compound = LumoStorySummaryScorer.evaluate(
      summary: 'Wir sind im Mond-Palast angekommen.',
      keyPoints: const ['Mond-Palast'],
    );
    expect(compound.hits, 1);
    expect(LumoStorySummaryScorer.evaluate(
      summary: 'Wir sehen den Mond und den Palast.',
      keyPoints: const ['Mond-Palast'],
    ).hits, 0);
    expect(LumoStorySummaryScorer.evaluate(
      summary: 'Nur Wörter.',
      keyPoints: const [],
    ).stars, 0);
  });

  testWidgets('Fast repeated summary evaluation awards stars and XP only once',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final originalVoice = LumoVoice.instance.isEnabled;
    LumoVoice.instance.isEnabled = false;
    addTearDown(() => LumoVoice.instance.isEnabled = originalVoice);
    await tester.binding.setSurfaceSize(const Size(412, 950));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = LumoAppState();
    addTearDown(state.dispose);
    const story = LumoStory(
      title: 'Lumo lernt fair',
      heroName: 'Lumo',
      location: 'Wald',
      theme: 'Lesen',
      newWords: [],
      gradeLevel: 2,
      pages: [
        LumoStoryPage(
          pageNum: 1, text: 'Lumo fand ein Buch im Wald.',
          imagePrompt: '',
        ),
      ],
      keyPoints: ['Lumo', 'Stern', 'Buch', 'Rätsel', 'Freund'],
    );
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: LumoStoryReaderScreen(story: story, appState: state),
      ),
    ));
    await tester.pump();
    final initialStars = state.state.stars;
    final initialXp = state.state.xp;
    await tester.tap(find.byKey(const ValueKey('lumo-story-continue')));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Lumo hat etwas entdeckt.');
    await tester.pump();

    final evaluate = find.text('Bewertung holen');
    expect(evaluate, findsOneWidget);
    await tester.tap(evaluate);
    // Intentionally no pump between taps: the previous button callback could
    // still be activated before Flutter builds its disabled replacement.
    await tester.tap(evaluate);
    await tester.pump();
    expect(state.state.stars, initialStars + 2);
    expect(state.state.xp, initialXp + 20);
    expect(find.text('Fertig!'), findsOneWidget);
    expect(find.text('Bewertung holen'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
