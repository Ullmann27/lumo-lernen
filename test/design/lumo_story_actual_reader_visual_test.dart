import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_story_generator.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/story/lumo_story_library_screen.dart';
import 'package:lumo_lernen/features/story/lumo_story_reader_screen.dart';
import 'package:lumo_lernen/features/story/lumo_story_setup_screen.dart';

Future<void> _frames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
}

void main() {
  testWidgets('story creation shows a saved-stories entry on the phone',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = LumoAppState();
    addTearDown(state.dispose);
    await tester.pumpWidget(MaterialApp(
      home: LumoStorySetupScreen(appState: state, initialGrade: 2),
    ));
    await _frames(tester);
    expect(find.text('Lumo erfindet dir eine Geschichte!'), findsOneWidget);
    final library = find.byKey(const ValueKey('lumo-story-open-library'));
    expect(library, findsOneWidget);
    await tester.ensureVisible(library);
    await tester.pump();
    await tester.tap(library);
    await _frames(tester);
    expect(find.byType(LumoStoryLibraryScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('real story text is visible before illustration on cover and Fold',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final originalVoice = LumoVoice.instance.isEnabled;
    LumoVoice.instance.isEnabled = false;
    addTearDown(() => LumoVoice.instance.isEnabled = originalVoice);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = LumoAppState();
    addTearDown(state.dispose);
    final story = LumoStoryGenerator.instance.generate(
      hero: 'Drache',
      location: 'Zauberwald',
      theme: 'Freundschaft',
      gradeLevel: 2,
    );
    for (final size in [const Size(360, 800), const Size(967, 805)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(MaterialApp(
        home: LumoStoryReaderScreen(
          key: ValueKey(size.width),
          story: story,
          appState: state,
        ),
      ));
      await _frames(tester);
      final actualText = find.byKey(const ValueKey('lumo-story-actual-page-text'));
      final art = find.byKey(const ValueKey('lumo-story-original-fox-art'));
      expect(actualText, findsOneWidget);
      expect(art, findsOneWidget);
      expect(tester.getTopLeft(actualText).dy,
          lessThan(tester.getTopLeft(art).dy));
      expect(tester.getTopLeft(actualText).dy, lessThan(300),
          reason: 'Children must see the actual reading text immediately');
      expect(find.text('Weiterlesen'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });
}
