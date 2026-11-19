import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_story_generator.dart';
import 'package:lumo_lernen/core/lumo_story_library.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/story/lumo_story_reader_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
  });

  testWidgets('completed new story is persisted before finish dialog returns',
      (tester) async {
    final appState = LumoAppState();
    addTearDown(appState.dispose);

    const story = LumoStory(
      title: 'Audit-Geschichte',
      heroName: 'Fuchs',
      location: 'Wald',
      theme: 'Freundschaft',
      gradeLevel: 2,
      newWords: <String>['Mut'],
      pages: <LumoStoryPage>[
        LumoStoryPage(
          pageNum: 1,
          text: 'Lumo findet im Wald einen neuen Freund.',
          imagePrompt: 'friendly fox in forest',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LumoStoryReaderScreen(
          story: story,
          appState: appState,
        ),
      ),
    );
    await tester.pump();

    final finish = find.text('Erzähl mir die Geschichte!');
    expect(finish, findsOneWidget);
    await tester.tap(finish);
    await tester.pump();

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    });
    await tester.pump();

    expect(LumoStoryLibrary.instance.count, 1);
    expect(LumoStoryLibrary.instance.all.single.story.title, 'Audit-Geschichte');
    expect(find.textContaining('Geschafft!'), findsOneWidget);
    expect(find.text('Heft in deine Bibliothek gespeichert!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
