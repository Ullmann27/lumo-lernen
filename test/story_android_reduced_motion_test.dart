import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_story_generator.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/story/lumo_story_reader_screen.dart';

void main() {
  testWidgets('Android reduce motion removes both page-turn animations',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final voiceEnabled = LumoVoice.instance.isEnabled;
    LumoVoice.instance.isEnabled = false;
    addTearDown(() => LumoVoice.instance.isEnabled = voiceEnabled);
    await tester.binding.setSurfaceSize(const Size(412, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final appState = LumoAppState();
    addTearDown(appState.dispose);

    const story = LumoStory(
      title: 'Ein ruhiges Leseabenteuer',
      heroName: 'Lumo',
      location: 'Zauberwald',
      theme: 'Lernen',
      gradeLevel: 2,
      newWords: [],
      pages: [
        LumoStoryPage(pageNum: 1, text: 'Lumo findet ein Buch.', imagePrompt: ''),
        LumoStoryPage(pageNum: 2, text: 'Lumo liest darin.', imagePrompt: ''),
      ],
    );

    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: LumoStoryReaderScreen(story: story, appState: appState),
      ),
    ));
    await tester.pump();

    AnimatedSwitcher pageTurn() {
      final ancestor = find.ancestor(
        of: find.byKey(const ValueKey('lumo-story-page-flip-1')),
        matching: find.byType(AnimatedSwitcher),
      );
      expect(ancestor, findsOneWidget);
      return tester.widget<AnimatedSwitcher>(ancestor);
    }

    expect(pageTurn().duration, Duration.zero);
    expect(pageTurn().reverseDuration, Duration.zero);

    await tester.ensureVisible(find.byKey(const ValueKey('lumo-story-continue')));
    await tester.tap(find.byKey(const ValueKey('lumo-story-continue')));
    await tester.pump();
    expect(find.text('Lumo liest darin.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
