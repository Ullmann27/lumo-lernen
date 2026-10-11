import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/discovery_progress.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/legacy_learning_data.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/tutoring/guided_lesson_catalog.dart';
import 'package:lumo_lernen/domain/tutoring/tutoring_session_planner.dart';
import 'package:lumo_lernen/features/settings/discovery_settings_card.dart';
import 'package:lumo_lernen/features/tutoring/guided_learning_hub.dart';
import 'package:lumo_lernen/features/tutoring/guided_lesson_screen.dart';
import 'package:lumo_lernen/widgets/design/lumo_quantity_art.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

class _RejectableDiscoveryStore extends InMemorySharedPreferencesStore {
  _RejectableDiscoveryStore() : super.withData({});
  String? rejectedKey;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (key == rejectedKey) return false;
    return super.setValue(type, key, value);
  }
}

Future<void> _frames(WidgetTester tester, [int count = 30]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await _frames(tester);
  expect(tester.takeException(), isNull);
}

Future<LumoAppState> _app(WidgetTester tester,
    {int grade = 1,
    Size size = const Size(600, 1100),
    double density = 1}) async {
  tester.view.devicePixelRatio = density;
  tester.view.physicalSize = size * density;
  await tester.binding.setSurfaceSize(size);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  late LumoAppState app;
  await tester.runAsync(() async {
    // Native-storage queues must be born in this real async zone, not a
    // FakeAsync zone that cannot advance while runAsync awaits their tail.
    // Use a real repository per test, not a permissive storage mock.
    debugPrint('QA fixture: create real asynchronous storage scope');
    app = LumoAppState(walletRepository: RewardWalletRepository());
    app.update(app.state.copyWith(grade: grade, section: LumoSection.learn));
    await app.school.setActiveStudent('learning-test-a');
    debugPrint('QA fixture: selected the fictitious test profile');
    await app.hydrateFromWallet();
    debugPrint('QA fixture: existing wallet hydrated');
    await app.loadLearningProfile();
    app.updateSettings(const AppSettings(
        voiceEnabled: false, autoReadEnabled: false, reduceAnimations: true));
    debugPrint('QA fixture: regular profile loaded; ready for actual taps');
  });
  return app;
}

Widget _shell(LumoAppState app) => MaterialApp(
    theme: LumoAppTheme.light(),
    home: Builder(
        builder: (context) => Scaffold(
                body: Column(children: [
              FilledButton(
                  onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                          builder: (_) => Scaffold(
                              appBar:
                                  AppBar(title: const Text('Elternfreigabe')),
                              body: SingleChildScrollView(
                                  child:
                                      DiscoverySettingsCard(appState: app))))),
                  child: const Text('Elternfreigabe öffnen')),
              FilledButton(
                  onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                          builder: (_) => GuidedLearningHub(
                              appState: app, discovery: true))),
                  child: const Text('Entdecken öffnen')),
            ]))));

Future<void> _close(WidgetTester tester, LumoAppState app) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  app.dispose();
  await tester.binding.setSurfaceSize(null);
  expect(tester.takeException(), isNull);
}

Future<void> _finish(WidgetTester tester, GuidedLesson lesson,
    {bool wrongIndependent = false, bool checkTargets = false}) async {
  for (final step in lesson.steps) {
    debugPrint('QA actual step: ${lesson.id}/${step.type.name}/${step.title}');
    expect(find.byKey(const ValueKey('guided-step-title')), findsOneWidget);
    expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('guided-step-title')))
            .data,
        step.title);
    if (step.isQuestion) {
      if (checkTargets) {
        for (final answer in step.choices) {
          final target = find.byKey(ValueKey('guided-answer-$answer'));
          await tester.ensureVisible(target);
          await tester.pump();
          expect(target.hitTestable(), findsOneWidget);
          expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
          expect(tester.getSize(target).width, greaterThanOrEqualTo(48));
          expect(tester.takeException(), isNull);
        }
      }
      if (wrongIndependent &&
          step.observation == DiscoveryStepKind.independent) {
        await _tap(tester,
            find.byKey(ValueKey('guided-answer-${step.choices.first}')));
        expect(find.textContaining('Fast!'), findsOneWidget);
        expect(LumoCompanionRequests.instance.taskContext.value!.lastCorrect,
            false);
        await _tap(tester, find.text('Tipp'));
        expect(
            find.byKey(const ValueKey('guided-actual-hint')), findsOneWidget);
        expect(
            tester
                .widget<Text>(find.byKey(const ValueKey('guided-actual-hint')))
                .data,
            isNot(contains(step.expected)));
      }
      await _tap(
          tester, find.byKey(ValueKey('guided-answer-${step.expected}')));
      expect(
          LumoCompanionRequests.instance.taskContext.value!.lastCorrect, true);
    } else if (step.type == TutoringStepType.showExample) {
      final total = lesson.concept == GuidedMathConcept.equalGroups
          ? step.a * step.b
          : step.a + step.b;
      expect(find.byType(LumoQuantityArt), findsNWidgets(total));
      await _tap(tester, find.text('Erklärung lesen'));
      expect(find.text(step.instruction), findsOneWidget);
      await _tap(tester, find.text('Erklärung einklappen'));
      expect(find.text(step.instruction), findsNothing);
      await _tap(tester, find.text('Beispiel noch einmal'));
      expect(find.byType(LumoQuantityArt), findsNWidgets(total));
    }
    if (checkTargets &&
        tester.view.physicalSize.width / tester.view.devicePixelRatio < 600) {
      final next = find.byKey(const ValueKey('guided-continue'));
      expect(next.hitTestable(), findsOneWidget,
          reason: 'The phone Continue button must be fixed and fully visible');
      expect(tester.getSize(next).height, greaterThanOrEqualTo(48));
    }
    if (step.type != TutoringStepType.recap) {
      await _tap(tester, find.widgetWithText(FilledButton, 'Weiter'));
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Nunito')
          ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
    LumoCompanionRequests.instance.clearLearningScope();
  });
  tearDown(LumoCompanionRequests.instance.clearLearningScope);

  testWidgets('school instruction counts only actual independent answers',
      (tester) async {
    final app = await _app(tester);
    await tester.pumpWidget(MaterialApp(
        theme: LumoAppTheme.light(),
        home: GuidedLessonScreen(
            appState: app,
            lesson: GuidedLessonCatalog.bridgeTen,
            discovery: false)));
    await _frames(tester);
    await _finish(tester, GuidedLessonCatalog.bridgeTen,
        wrongIndependent: true);
    expect(app.state.grade, 1);
    expect(app.learningDailyDone(), 2);
    final record = app.learningSkills()['mathematik::plus bis 20']!;
    expect(record.correct, 2);
    expect(record.wrong, 1);
    expect(record.hintCount, 1);
    expect(LumoCompanionRequests.instance.learningEvents.value.last.kind,
        LumoLearningEventKind.lessonCompleted);
    expect(
        (await tester.runAsync(() =>
                ProgressRepository(studentId: 'learning-test-a')
                    .loadDiscovery()))!
            .topics,
        isEmpty);
    await _close(tester, app);
  });

  testWidgets(
      'actual adult choice and complete higher-stage discovery stay separate',
      (tester) async {
    final app = await _app(tester);
    await tester.runAsync(() => app.recordLearningAnswer(
        subject: 'Mathematik',
        unit: 'Plus bis 10',
        correct: true,
        requireSaved: true));
    await tester.pumpWidget(_shell(app));
    await _frames(tester);
    await _tap(tester, find.text('Elternfreigabe öffnen'));
    await _tap(tester, find.byType(DropdownButtonFormField<int>));
    await _tap(tester, find.text('Bis zur 2. Schulstufe').last);
    await _tap(tester, find.byType(Switch));
    await _tap(tester, find.text('Nicht jetzt'));
    final lease = await tester.runAsync(app.captureLearningProfile);
    expect(lease!.profile.canDiscover(2), false);
    await _tap(tester, find.byType(Switch));
    await _tap(tester, find.text('Als Erwachsene:r freigeben'));
    expect(lease.profile.canDiscover(2), true);
    expect(app.state.settings.aiProxyEnabled, false);
    expect(app.state.settings.cloudVoiceEnabled, false);
    expect(app.state.settings.microphoneEnabled, false);
    expect(app.state.settings.scannerEnabled, false);
    await tester.pageBack();
    await _frames(tester);
    final prefs = await tester.runAsync(SharedPreferences.getInstance);
    final before = {
      for (final key in prefs!.getKeys())
        if (!key.contains('lumo_progress_discovery_v1')) key: prefs.get(key),
    };
    await _tap(tester, find.text('Entdecken öffnen'));
    await _tap(tester, find.byKey(const ValueKey('guided-open-equal_groups')));
    await _finish(tester, GuidedLessonCatalog.equalGroups,
        wrongIndependent: true);
    expect(app.learningDailyDone(), 1);
    expect(app.learningSkills().length, 1);
    expect(app.state.grade, 1);
    await tester.runAsync(prefs.reload);
    expect({
      for (final key in prefs.getKeys())
        if (!key.contains('lumo_progress_discovery_v1')) key: prefs.get(key),
    }, before);
    final topic = lease.profile.discovery.topics['equal_groups']!;
    expect(topic.introduced, true);
    expect(topic.foundationCorrect, 1);
    expect(topic.guidedCorrect, 1);
    expect(topic.independentWrong, 1);
    expect(topic.independentCorrect, 1);
    expect(topic.checkCorrect, 1);
    expect(topic.hintsUsed, 1);
    await _tap(tester, find.widgetWithText(FilledButton, 'Zur Lernübersicht'));
    expect(find.byType(GuidedLearningHub), findsOneWidget);
    await tester.pageBack();
    await _frames(tester);
    await tester.runAsync(() async {
      await app.school.setActiveStudent('learning-test-b');
      await app.loadLearningProfile();
      final b = await app.captureLearningProfile();
      await b.profile.loadDiscovery();
      expect(b.profile.discovery.enabled, false);
      expect(b.profile.discovery.topics, isEmpty);
      expect(app.learningDailyDone(), 0);
      await app.school.setActiveStudent('learning-test-a');
      await app.loadLearningProfile();
      final a = await app.captureLearningProfile();
      await a.profile.loadDiscovery();
      expect(a.profile.discovery.topics['equal_groups']!.checkCorrect, 1);
      expect(app.learningDailyDone(), 1);
    });
    await _close(tester, app);
  });

  testWidgets(
      'first error does not reveal the solution and easier practice returns',
      (tester) async {
    final app = await _app(tester);
    await tester.pumpWidget(MaterialApp(
        home: GuidedLessonScreen(
            appState: app,
            lesson: GuidedLessonCatalog.bridgeTen,
            discovery: false)));
    await _frames(tester);
    await _tap(tester, find.widgetWithText(FilledButton, 'Weiter'));
    await _tap(tester, find.byKey(const ValueKey('guided-answer-5')));
    expect(find.byKey(const ValueKey('guided-actual-hint')), findsNothing);
    expect(
        tester.widget<Text>(find.byKey(const ValueKey('guided-feedback'))).data,
        isNot(contains('6')));
    await _tap(tester, find.text('Leichter üben'));
    expect(find.text('Ein kleiner Schritt'), findsOneWidget);
    expect(find.byType(LumoQuantityArt), findsNWidgets(3));
    await _tap(tester, find.byKey(const ValueKey('guided-answer-3')));
    await _tap(tester, find.text('Zurück zu meiner Aufgabe'));
    expect(find.text('Was kannst du schon?'), findsOneWidget);
    expect(app.learningDailyDone(), 0);
    await _close(tester, app);
  });

  testWidgets('direct higher-stage school route fails closed without a grant',
      (tester) async {
    final app = await _app(tester);
    await tester.pumpWidget(MaterialApp(
        home: GuidedLessonScreen(
            appState: app,
            lesson: GuidedLessonCatalog.equalGroups,
            discovery: false)));
    await _frames(tester);
    expect(find.textContaining('höheren Schulstufe'), findsOneWidget);
    expect(find.byKey(const ValueKey('guided-step-title')), findsNothing);
    expect(app.learningDailyDone(), 0);
    await _close(tester, app);
  });

  testWidgets('profile change while the consent dialog is open cannot grant B',
      (tester) async {
    final app = await _app(tester);
    await tester.pumpWidget(_shell(app));
    await _frames(tester);
    await _tap(tester, find.text('Elternfreigabe öffnen'));
    await _tap(tester, find.byType(Switch));
    await tester.runAsync(() async {
      await app.school.setActiveStudent('learning-test-b');
      await app.loadLearningProfile();
    });
    await _frames(tester);
    await _tap(tester, find.text('Als Erwachsene:r freigeben'));
    await tester.runAsync(() async {
      for (final child in ['learning-test-a', 'learning-test-b']) {
        expect(
            (await ProgressRepository(studentId: child).loadDiscovery())
                .enabled,
            false);
      }
    });
    await _close(tester, app);
  });

  testWidgets('nested lesson exits to Games without leaving its hub on top',
      (tester) async {
    final app = await _app(tester);
    await tester.pumpWidget(MaterialApp(
      theme: LumoAppTheme.light(),
      home: AnimatedBuilder(
        animation: app,
        builder: (context, _) => Scaffold(
          body: Column(children: [
            Text('Hauptbereich: ${app.state.section.name}'),
            FilledButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                    builder: (_) =>
                        GuidedLearningHub(appState: app, discovery: false)),
              ),
              child: const Text('Unterricht öffnen'),
            ),
          ]),
        ),
      ),
    ));
    await _frames(tester);
    await _tap(tester, find.text('Unterricht öffnen'));
    await _tap(tester, find.byKey(const ValueKey('guided-open-bridge_ten')));
    expect(find.byType(GuidedLessonScreen), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('lumo-nav-spielen')));
    expect(app.state.section, LumoSection.games);
    expect(find.text('Hauptbereich: games').hitTestable(), findsOneWidget);
    expect(find.byType(GuidedLearningHub), findsNothing);
    expect(find.byType(GuidedLessonScreen), findsNothing);
    await _close(tester, app);
  });

  testWidgets('native failed grant stays off and an actual retry enables it',
      (tester) async {
    final store = _RejectableDiscoveryStore();
    SharedPreferencesStorePlatform.instance = store;
    final app = await _app(tester);
    await tester.pumpWidget(_shell(app));
    await _frames(tester);
    await _tap(tester, find.text('Elternfreigabe öffnen'));
    await _tap(tester, find.byType(DropdownButtonFormField<int>));
    await _tap(tester, find.text('Bis zur 2. Schulstufe').last);
    final owner = await tester.runAsync(app.captureLearningProfile);
    store.rejectedKey =
        'flutter.${LearningDataNamespace.keyFor("lumo_progress_discovery_v1", "learning-test-a")}';
    await _tap(tester, find.byType(Switch));
    await _tap(tester, find.text('Als Erwachsene:r freigeben'));
    expect(owner!.profile.canDiscover(2), false);
    expect(tester.widget<Switch>(find.byType(Switch)).value, false);
    expect(find.text('Freigabe erneut speichern'), findsOneWidget);
    store.rejectedKey = null;
    await _tap(tester, find.text('Freigabe erneut speichern'));
    expect(owner.profile.canDiscover(2), true);
    expect(tester.widget<Switch>(find.byType(Switch)).value, true);
    expect(app.learningDailyDone(), 0);
    await _close(tester, app);
  });

  for (final (name, size, density, textScale) in [
    ('small phone', const Size(320, 568), 1.0, 1.0),
    ('phone', const Size(360, 800), 1.0, 1.0),
    ('fold target', const Size(2176 / 2.25, 1812 / 2.25), 2.25, 1.0),
    ('tablet', const Size(1024, 768), 1.0, 1.0),
    ('short landscape', const Size(640, 360), 1.0, 1.0),
    ('large type phone', const Size(320, 568), 1.0, 2.0),
  ]) {
    testWidgets('complete school course and reachable targets: $name',
        (tester) async {
      final app = await _app(tester, size: size, density: density);
      await tester.pumpWidget(MaterialApp(
        theme: LumoAppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: GuidedLessonScreen(
            appState: app,
            lesson: GuidedLessonCatalog.bridgeTen,
            discovery: false),
      ));
      await _frames(tester);
      await _finish(tester, GuidedLessonCatalog.bridgeTen, checkTargets: true);
      expect(app.learningDailyDone(), 2);
      await _close(tester, app);
    });
  }

  testWidgets('adult confirmation remains usable on a small large-type phone',
      (tester) async {
    final app = await _app(tester, size: const Size(320, 568));
    await tester.pumpWidget(MaterialApp(
      theme: LumoAppTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: Scaffold(
        body:
            SingleChildScrollView(child: DiscoverySettingsCard(appState: app)),
      ),
    ));
    await _frames(tester);
    await _tap(tester, find.byType(Switch));
    expect(find.text('Neues entdecken freigeben'), findsOneWidget);
    await _tap(tester, find.text('Nicht jetzt'));
    expect(tester.widget<Switch>(find.byType(Switch)).value, false);
    await _close(tester, app);
  });
}
