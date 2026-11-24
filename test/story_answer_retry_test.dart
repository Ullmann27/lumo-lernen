import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_story_generator.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/story/lumo_story_reader_screen.dart';

void main() {
  testWidgets(
      'wrong arithmetic answer stays correctable without awarding stars',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final voice = LumoVoice.instance.isEnabled;
    LumoVoice.instance.isEnabled = false;
    addTearDown(() => LumoVoice.instance.isEnabled = voice);
    await tester.binding.setSurfaceSize(const Size(412, 1500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = LumoAppState();
    addTearDown(state.dispose);
    const story = LumoStory(
        title: 'Lumo zählt',
        heroName: 'Fuchs',
        location: 'Garten',
        theme: 'Zählen',
        newWords: [],
        gradeLevel: 1,
        pages: [
          LumoStoryPage(
              pageNum: 1,
              text: 'Lumo findet zwei und dann drei Äpfel.',
              imagePrompt: '',
              exercise: StoryExercise(
                  type: StoryExerciseType.mathPlus,
                  prompt: '2 + 3 = ?',
                  correctAnswer: '5',
                  options: ['4', '5', '6'])),
          LumoStoryPage(
              pageNum: 2, text: 'Alle teilen die Äpfel.', imagePrompt: ''),
        ]);
    await tester.pumpWidget(MaterialApp(
        home: LumoStoryReaderScreen(story: story, appState: state)));
    await tester.pump(const Duration(milliseconds: 400));
    final initialStars = state.state.stars;
    await tester.ensureVisible(find.text('4'));
    await tester.tap(find.text('4'));
    await tester.pump();
    expect(
        tester
            .widget<ElevatedButton>(
                find.byKey(const ValueKey('lumo-story-continue')))
            .onPressed,
        isNull);
    expect(state.state.stars, initialStars);
    await tester.tap(find.text('5'));
    await tester.pump();
    expect(
        tester
            .widget<ElevatedButton>(
                find.byKey(const ValueKey('lumo-story-continue')))
            .onPressed,
        isNotNull);
    expect(state.state.stars, initialStars + 1);
    await tester.tap(find.text('5'));
    await tester.pump();
    expect(state.state.stars, initialStars + 1);
    expect(find.text('Geschafft! Du kannst weiterlesen.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
