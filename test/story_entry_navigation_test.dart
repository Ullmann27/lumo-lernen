import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_story_library.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/home/home_content.dart';
import 'package:lumo_lernen/features/deutsch/lumo_deutsch_screen.dart';
import 'package:lumo_lernen/features/reading/reading_content.dart';
import 'package:lumo_lernen/features/story/lumo_story_library_screen.dart';
import 'package:lumo_lernen/features/story/lumo_story_setup_screen.dart';
import 'package:lumo_lernen/features/story/lumo_story_reader_screen.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';

Future<void> frames(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<LumoAppState> profile(WidgetTester tester, int grade) async {
  final app = (await tester.runAsync(() async {
    final app = LumoAppState();
    app.update(app.state.copyWith(grade: grade));
    app.updateSettings(const AppSettings(
        voiceEnabled: false,
        soundEnabled: false,
        autoReadEnabled: false,
        microphoneEnabled: false,
        aiProxyEnabled: false,
        reduceAnimations: true,
        calmMode: true));
    await app.loadLearningProfile();
    await LumoStoryLibrary.instance.load();
    return app;
  }))!;
  addTearDown(app.dispose);
  return app;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Nunito')
          ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final enabled = LumoVoice.instance.isEnabled;
    LumoVoice.instance.isEnabled = false;
    addTearDown(() => LumoVoice.instance.isEnabled = enabled);
  });
  for (final entry in ['home', 'deutsch', 'reading']) {
    testWidgets(
        '$entry opens free story creation without changing profile grade',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = await profile(tester, 3);
      final Widget source = switch (entry) {
        'home' => HomeContent(appState: app, onSection: (_) {}),
        'deutsch' => LumoDeutschScreen(appState: app),
        _ => ReadingContent(appState: app, onBack: () {}),
      };
      await tester.pumpWidget(MaterialApp(
          theme: LumoAppTheme.light(), home: Scaffold(body: source)));
      await frames(tester);
      final action = find.byKey(ValueKey('$entry-stories'));
      expect(action, findsOneWidget);
      await tester.ensureVisible(action);
      await tester.runAsync(() => tester.tap(action));
      await frames(tester);
      expect(find.byType(LumoStoryLibraryScreen), findsOneWidget);
      expect(
          tester
              .widget<LumoStoryLibraryScreen>(
                  find.byType(LumoStoryLibraryScreen))
              .gradeLevel,
          isNull);
      await tester.tap(find.text('Erste Geschichte!'));
      await frames(tester);
      final setup = tester
          .widget<LumoStorySetupScreen>(find.byType(LumoStorySetupScreen));
      expect(setup.initialGrade, isNull);
      expect(find.text('3. Klasse'), findsOneWidget);
      await tester.tap(find.text('1. Klasse'));
      await tester.tap(find.text('Überraschung!'));
      await frames(tester);
      expect(
          tester
              .widget<LumoStoryReaderScreen>(find.byType(LumoStoryReaderScreen))
              .story
              .gradeLevel,
          1);
      expect(app.state.grade, 3);
      expect(app.state.settings.microphoneEnabled, false);
      expect(app.state.settings.aiProxyEnabled, false);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await frames(tester);
    }, timeout: const Timeout(Duration(seconds: 45)));
  }
  testWidgets(
      'learning path forwards its selected grade as a fixed story grade',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = await profile(tester, 1);
    await tester.pumpWidget(MaterialApp(
        theme: LumoAppTheme.light(), home: LumoAkademieScreen(appState: app)));
    await frames(tester);
    final grade = find.byKey(const ValueKey('grade-pill-3'));
    await tester.ensureVisible(grade);
    await tester.tap(grade);
    await frames(tester);
    final action = find.byKey(const ValueKey('academy-stories'));
    expect(action, findsOneWidget);
    await tester.ensureVisible(action);
    await tester.tap(action);
    await frames(tester);
    expect(
        tester
            .widget<LumoStoryLibraryScreen>(find.byType(LumoStoryLibraryScreen))
            .gradeLevel,
        3);
    await tester.tap(find.text('Erste Geschichte!'));
    await frames(tester);
    expect(
        tester
            .widget<LumoStorySetupScreen>(find.byType(LumoStorySetupScreen))
            .initialGrade,
        3);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    expect(find.text('3. Klasse'), findsOneWidget);
    expect(find.text('1. Klasse'), findsNothing);
    await tester.tap(find.text('Überraschung!'));
    await frames(tester);
    expect(
        tester
            .widget<LumoStoryReaderScreen>(find.byType(LumoStoryReaderScreen))
            .story
            .gradeLevel,
        3);
    expect(app.state.grade, 1);
    expect(app.learningSkills(), isEmpty,
        reason:
            'Opening a higher-grade story must not book regular learning progress.');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await frames(tester);
  }, timeout: const Timeout(Duration(seconds: 45)));
}
