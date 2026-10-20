import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/settings_repository.dart';
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

Future<LumoAppState> profile(WidgetTester tester, int grade,
    {LumoAppState Function()? create}) async {
  final app = (await tester.runAsync(() async {
    final app = create?.call() ?? LumoAppState();
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


class DelayedSettingsApp extends LumoAppState {
  Completer<void>? settingsGate;
  @override
  Future<void> ensureSettingsLoaded() =>
      settingsGate?.future ?? super.ensureSettingsLoaded();
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
      if (entry == 'academy') {
        await tester.tap(find.byKey(const ValueKey('learning-advanced-entry')));
        await frames(tester);
      }
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
    await tester.tap(find.byKey(const ValueKey('learning-advanced-entry')));
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
  testWidgets('story entries survive display resize and large text', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final app = await profile(tester, 2);
    for (final entry in ['home', 'deutsch', 'reading', 'academy']) {
      final Widget source = switch (entry) {
        'home' => HomeContent(appState: app, onSection: (_) {}),
        'deutsch' => LumoDeutschScreen(appState: app),
        'academy' => LumoAkademieScreen(appState: app),
        _ => ReadingContent(appState: app, onBack: () {}),
      };
      for (final width in [360.0, 800.0]) {
        tester.view.physicalSize = Size(width, 1200);
        await tester.pumpWidget(MaterialApp(
          theme: LumoAppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: RepaintBoundary(
            key: ValueKey('capture-$entry'), child: Scaffold(body: source)),
        ));
        await frames(tester);
        final action = find.byKey(ValueKey('$entry-stories'));
        if (action.evaluate().isEmpty) {
          // Nested lazy slivers can omit offscreen actions from the element
          // tree. Search the scrollable owning each surface, from inside out,
          // rather than assuming Scrollable.first is always its parent.
          final scrollables = find.byType(Scrollable).evaluate().toList();
          for (final element in scrollables.reversed) {
            if (action.evaluate().isNotEmpty) break;
            final scrollable = find.byWidget(element.widget);
            await tester.drag(scrollable, const Offset(0, 2000));
            await tester.pump(const Duration(milliseconds: 30));
            for (var n = 0; n < 35 && action.evaluate().isEmpty; n++) {
              await tester.drag(scrollable, const Offset(0, -230));
              await tester.pump(const Duration(milliseconds: 30));
            }
          }
        }
        expect(action, findsOneWidget,
            reason: '$entry stories action at width $width with large text '
                'must remain reachable through scrolling');
        await tester.ensureVisible(action);
        await frames(tester);
        expect(action, findsOneWidget);
        expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
        expect(tester.takeException(), isNull);
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(ValueKey('capture-$entry')));
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          try {
            final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
            final file = File(
              '.ci-results/story-entry/$entry-${width.toInt()}-large-text.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
          } finally { image.dispose(); }
        });
        await tester.runAsync(() => tester.tap(action));
        await frames(tester);
        expect(find.byType(LumoStoryLibraryScreen), findsOneWidget);
        expect(app.state.grade, 2);
        Navigator.of(tester.element(find.byType(LumoStoryLibraryScreen))).pop();
        await frames(tester);
        expect(find.byType(LumoStoryLibraryScreen), findsNothing);
        expect(action, findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await frames(tester);
    }
  }, timeout: const Timeout(Duration(seconds: 45)));

  testWidgets('a pending microphone start cannot restart behind the library',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = await profile(tester, 2, create: DelayedSettingsApp.new)
        as DelayedSettingsApp;
    await tester.runAsync(() async {
      // The real settings loader restores persisted values asynchronously.
      // Persist microphone permission first so the fixture cannot be reset
      // to the default (disabled) before the pending-start race is exercised.
      final enabled = app.state.settings.copyWith(microphoneEnabled: true);
      await SettingsRepository.save(enabled);
      await app.ensureSettingsLoaded();
      expect(app.state.settings.microphoneEnabled, true);
    });
    const speechChannel = MethodChannel('plugin.csdcorp.com/speech_to_text');
    final speechMethods = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      speechChannel, (call) async {
        speechMethods.add(call.method);
        return false;
      });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(speechChannel, null));
    await tester.pumpWidget(MaterialApp(
      theme: LumoAppTheme.light(),
      home: Scaffold(body: ReadingContent(appState: app, onBack: () {}))));
    await frames(tester);
    expect(app.state.settings.microphoneEnabled, true);
    app.settingsGate = Completer<void>();
    final microphone = find.byKey(const ValueKey('reading-microphone'));
    await tester.ensureVisible(microphone);
    await tester.tap(microphone);
    await tester.pump();
    final library = find.byKey(const ValueKey('reading-stories'));
    await tester.ensureVisible(library);
    await tester.runAsync(() => tester.tap(library));
    await frames(tester);
    expect(find.byType(LumoStoryLibraryScreen), findsOneWidget);
    app.settingsGate!.complete();
    await frames(tester);
    // Route cleanup may cancel or stop speech; every other call is forbidden.
    expect(
      speechMethods.where((method) => method != 'cancel' && method != 'stop'),
      isEmpty,
      reason: 'A delayed start must not initialize or listen behind another '
          'route. Observed speech methods: $speechMethods',
    );
    expect(app.learningSkills(), isEmpty);
    Navigator.of(tester.element(find.byType(LumoStoryLibraryScreen))).pop();
    await frames(tester);
    expect(tester.widget<GestureDetector>(microphone).onTap, isNotNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await frames(tester);
  }, timeout: const Timeout(Duration(seconds: 45)));

}
