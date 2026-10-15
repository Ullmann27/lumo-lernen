import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/legacy_learning_data.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/tutoring/guided_lesson_catalog.dart';
import 'package:lumo_lernen/features/sections/section_content.dart';
import 'package:lumo_lernen/features/tutoring/guided_lesson_screen.dart';
import 'package:lumo_lernen/features/tutoring/tutoring_flow_card.dart';
import 'package:lumo_lernen/widgets/design/lumo_design_system.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

const _boundary = ValueKey('actual-tutoring-flow-capture');
final _captureDir = Platform.environment['LUMO_TUTORING_CAPTURE_DIR'];

class _RejectableStore extends InMemorySharedPreferencesStore {
  _RejectableStore() : super.withData({});
  String? rejectedKey;

  @override
  Future<bool> setValue(String type, String key, Object value) async =>
      key == rejectedKey ? false : super.setValue(type, key, value);
}

Future<void> _frames(WidgetTester tester, [int count = 30]) async {
  for (var frame = 0; frame < count; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  expect(tester.takeException(), isNull);
}

Future<LumoAppState> _app(WidgetTester tester,
    {int grade = 2, Size size = const Size(600, 1100)}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  await tester.binding.setSurfaceSize(size);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  late LumoAppState app;
  await tester.runAsync(() async {
    app = LumoAppState(walletRepository: RewardWalletRepository());
    app.update(app.state.copyWith(
        childName: 'Testkind', grade: grade, section: LumoSection.missions));
    await app.school.setActiveStudent('tutoring-proof-a');
    await app.hydrateFromWallet();
    await app.loadLearningProfile();
    app.updateSettings(const AppSettings(
        voiceEnabled: false,
        autoReadEnabled: false,
        soundEnabled: false,
        reduceAnimations: true));
  });
  addTearDown(app.dispose);
  return app;
}

Future<void> _recordFive(
    WidgetTester tester, LumoAppState app, String subject, String unit) async {
  await tester.runAsync(() async {
    await app.recordLearningAnswer(
        subject: subject, unit: unit, correct: true, requireSaved: true);
    for (var answer = 0; answer < 4; answer++) {
      await app.recordLearningAnswer(
          subject: subject, unit: unit, correct: false, requireSaved: true);
    }
  });
}

Widget _shell(LumoAppState app,
        {List<LumoSection>? sections,
        Future<void> Function(LumoSection)? beforeNavigation}) =>
    MaterialApp(
      theme: LumoAppTheme.light(),
      builder: (context, child) =>
          RepaintBoundary(key: _boundary, child: child!),
      home: Scaffold(
        backgroundColor: const Color(0xFF071B3B),
        body: LumoSceneBackground(
          scene: LumoScene.learning,
          showPlaceholderLabel: false,
          child: AnimatedBuilder(
            animation: app,
            builder: (context, _) => SectionContent(
              appState: app,
              section: app.state.section,
              onSection: (section) async {
                sections?.add(section);
                if (beforeNavigation != null) await beforeNavigation(section);
                app.update(app.state.copyWith(section: section));
              },
            ),
          ),
        ),
      ),
    );

Widget _cardShell(LumoAppState app,
        {double textScale = 1, VoidCallback? onGuided}) =>
    MaterialApp(
      theme: LumoAppTheme.light(),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            backgroundColor: const Color(0xFF071B3B),
            body: LumoSceneBackground(
              scene: LumoScene.learning,
              showPlaceholderLabel: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: TutoringFlowCard(
                  appState: app,
                  onStartTutoring: (_) {},
                  onStartGuidedLearning: (_) => onGuided?.call(),
                ),
              ),
            ),
          ),
        ),
      ),
    );

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  // Scrolling changes layout on the next frame; never tap stale coordinates.
  await tester.pump();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await _frames(tester);
}

Future<void> _capture(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    await Future.wait(find.byType(Image).evaluate().map(
        (element) => precacheImage((element.widget as Image).image, element)));
  });
  await tester.pump();
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$_captureDir/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  expect(tester.takeException(), isNull);
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
    WidgetController.hitTestWarningShouldBeFatal = true;
  });
  tearDownAll(() => WidgetController.hitTestWarningShouldBeFatal = false);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
    LumoCompanionRequests.instance.clearLearningScope();
  });
  tearDown(LumoCompanionRequests.instance.clearLearningScope);

  for (final (name, size) in [
    ('phone-360x800', const Size(360, 800)),
    ('fold-target', const Size(2176 / 2.25, 1812 / 2.25)),
  ]) {
    testWidgets('actual tutoring card capture: $name', (tester) async {
      final app = await _app(tester, size: size);
      await _recordFive(tester, app, 'Mathematik', 'Plus bis 20');
      await tester.pumpWidget(_shell(app));
      await _frames(tester);
      await _capture(tester, '$name-actual-tutoring-card');
      await _tap(tester, find.byKey(const ValueKey('tutoring-reason-toggle')));
      expect(find.textContaining('4 von 5 gespeicherten Antworten'),
          findsOneWidget);
      await _capture(tester, '$name-actual-tutoring-reason');
      await _tap(tester, find.byKey(const ValueKey('tutoring-guided-start')));
      expect(find.byType(GuidedLessonScreen), findsOneWidget);
      expect(LumoCompanionRequests.instance.taskContext.value!.ownerSection,
          'learn');
      await _capture(tester, '$name-actual-opened-course');
      await _close(tester);
    }, skip: _captureDir == null);
  }

  testWidgets('a new profile is not assigned invented assessments or steps',
      (tester) async {
    final app = await _app(tester);
    await tester.pumpWidget(_shell(app));
    await _frames(tester);
    expect(find.text('Lumo hat geschaut, wo du Hilfe brauchst.'), findsNothing);
    expect(find.text('8 Schritte'), findsNothing);
    expect(find.text('Zusammenfassung und Belohnung.'), findsNothing);
    expect(find.textContaining('noch keine'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('the tutoring card uses five actual stored answers',
      (tester) async {
    final app = await _app(tester);
    await _recordFive(tester, app, 'Deutsch', 'Silben');
    await tester.pumpWidget(_shell(app));
    await _frames(tester);
    expect(find.textContaining('5 gespeicherte Antworten'), findsOneWidget);
    expect(find.textContaining('Silben'), findsWidgets);
    await _close(tester);
  });

  testWidgets('tutoring follows the actual German subject and topic',
      (tester) async {
    final app = await _app(tester);
    await _recordFive(tester, app, 'Deutsch', 'Silben');
    final sections = <LumoSection>[];
    await tester.pumpWidget(_shell(app, sections: sections));
    await _frames(tester);
    await _tap(tester, find.byKey(const ValueKey('tutoring-practice-start')));
    expect(app.state.subject, 'Deutsch');
    expect(app.state.unit, 'Silben');
    expect(app.state.sessionKind, LumoSessionKind.tutoring);
    expect(sections, [LumoSection.exercises]);
    await _close(tester);
  });

  testWidgets('the actual explanation uses stored errors, not guessed attempts',
      (tester) async {
    final app = await _app(tester);
    await _recordFive(tester, app, 'Deutsch', 'Silben');
    app.update(app.state.copyWith(weakSkills: {'Fremdes Thema': 99}));
    await tester.pumpWidget(_shell(app));
    await _frames(tester);
    await _tap(tester, find.byKey(const ValueKey('tutoring-reason-toggle')));
    expect(
        find.textContaining('4 von 5 gespeicherten Antworten'), findsOneWidget);
    expect(find.textContaining('Fremdes Thema'), findsNothing);
    expect(find.textContaining('keine Bewertung von dir'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('three real successes end remedial mode without a diagnosis',
      (tester) async {
    final app = await _app(tester);
    await _recordFive(tester, app, 'Deutsch', 'Silben');
    await tester.pumpWidget(_shell(app));
    await _frames(tester);
    expect(find.text('Gemeinsam Schritt für Schritt'), findsOneWidget);
    await tester.runAsync(() async {
      for (var answer = 0; answer < 3; answer++) {
        await app.recordLearningAnswer(
            subject: 'Deutsch',
            unit: 'Silben',
            correct: true,
            requireSaved: true);
      }
    });
    await _frames(tester);
    expect(find.text('Gemeinsam Schritt für Schritt'), findsNothing);
    expect(find.text('Hier machen wir weiter'), findsOneWidget);
    expect(find.textContaining('8 gespeicherte Antworten'), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('tutoring-practice-start')));
    expect(app.state.sessionKind, LumoSessionKind.quickPractice);
    expect(app.state.subject, 'Deutsch');
    expect(app.state.unit, 'Silben');
    await _close(tester);
  });

  testWidgets('the recommended bridge opens its actual course and task context',
      (tester) async {
    final app = await _app(tester);
    await _recordFive(tester, app, 'Mathematik', 'Plus bis 20');
    await tester.pumpWidget(_shell(app));
    await _frames(tester);
    await _tap(tester, find.byKey(const ValueKey('tutoring-guided-start')));
    expect(find.byType(GuidedLessonScreen), findsOneWidget);
    expect(
        tester
            .widget<GuidedLessonScreen>(find.byType(GuidedLessonScreen))
            .lesson
            .id,
        GuidedLessonCatalog.bridgeTen.id);
    expect(app.state.section, LumoSection.learn);
    expect(app.state.grade, 2);
    final task = LumoCompanionRequests.instance.taskContext.value!;
    expect(task.ownerSection, 'learn');
    expect(task.unit, 'Plus bis 20');
    expect(task.profileGeneration, app.profileGeneration);
    await _tap(tester, find.byKey(const ValueKey('learning-module-back')));
    expect(find.byType(GuidedLessonScreen), findsNothing);
    expect(app.state.section, LumoSection.learn);
    expect(LumoCompanionRequests.instance.taskContext.value, isNull);
    await _close(tester);
  });

  testWidgets('a German suggestion opens the matching real syllable course',
      (tester) async {
    final app = await _app(tester, grade: 1);
    await _recordFive(tester, app, 'Deutsch', 'Silben');
    await tester.pumpWidget(_shell(app));
    await _frames(tester);
    expect(find.text('Bildkurs: Wörter in Silben hören'), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('tutoring-guided-start')));
    expect(find.byType(GuidedLessonScreen), findsOneWidget);
    expect(
        tester
            .widget<GuidedLessonScreen>(find.byType(GuidedLessonScreen))
            .lesson,
        GuidedLessonCatalog.syllables);
    expect(
        LumoCompanionRequests.instance.taskContext.value!.subject, 'Deutsch');
    expect(LumoCompanionRequests.instance.taskContext.value!.unit, 'Silben');
    expect(app.state.grade, 1);
    final owner = await tester.runAsync(app.captureLearningProfile);
    expect(owner!.profile.canDiscover(2), false);
    await _close(tester);
  });

  testWidgets('a course waits for the actual asynchronous section transition',
      (tester) async {
    final app = await _app(tester);
    await _recordFive(tester, app, 'Mathematik', 'Plus bis 20');
    final transition = Completer<void>();
    await tester
        .pumpWidget(_shell(app, beforeNavigation: (_) => transition.future));
    await _frames(tester);
    await tester
        .ensureVisible(find.byKey(const ValueKey('tutoring-guided-start')));
    await tester.tap(find.byKey(const ValueKey('tutoring-guided-start')));
    await _frames(tester, 2);
    expect(find.byType(GuidedLessonScreen), findsNothing);
    expect(app.state.section, LumoSection.missions);
    transition.complete();
    await _frames(tester);
    expect(find.byType(GuidedLessonScreen), findsOneWidget);
    expect(app.state.section, LumoSection.learn);
    expect(LumoCompanionRequests.instance.taskContext.value!.ownerSection,
        'learn');
    await _close(tester);
  });

  testWidgets('profile switch during navigation cancels the old course request',
      (tester) async {
    final app = await _app(tester);
    await _recordFive(tester, app, 'Mathematik', 'Plus bis 20');
    final transition = Completer<void>();
    await tester
        .pumpWidget(_shell(app, beforeNavigation: (_) => transition.future));
    await _frames(tester);
    await tester
        .ensureVisible(find.byKey(const ValueKey('tutoring-guided-start')));
    await tester.tap(find.byKey(const ValueKey('tutoring-guided-start')));
    await _frames(tester, 2);
    await tester
        .runAsync(() => app.school.setActiveStudent('tutoring-proof-b'));
    transition.complete();
    await _frames(tester);
    expect(find.byType(GuidedLessonScreen), findsNothing);
    expect(LumoCompanionRequests.instance.taskContext.value, isNull);
    expect(app.learningSkills(), isEmpty);
    await _close(tester);
  });

  testWidgets('repeated course taps start one real asynchronous transition',
      (tester) async {
    final app = await _app(tester);
    await _recordFive(tester, app, 'Mathematik', 'Plus bis 20');
    final transition = Completer<void>();
    final sections = <LumoSection>[];
    await tester.pumpWidget(_shell(app,
        sections: sections, beforeNavigation: (_) => transition.future));
    await _frames(tester);
    final target = find.byKey(const ValueKey('tutoring-guided-start'));
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.tap(target);
    await _frames(tester, 2);
    expect(sections, [LumoSection.learn]);
    expect(find.byType(GuidedLessonScreen), findsNothing);
    transition.complete();
    await _frames(tester);
    expect(find.byType(GuidedLessonScreen), findsOneWidget);
    await _close(tester);
  });

  testWidgets('a failed course transition reports an actual retryable error',
      (tester) async {
    final app = await _app(tester);
    await _recordFive(tester, app, 'Mathematik', 'Plus bis 20');
    await tester.pumpWidget(_shell(app,
        beforeNavigation: (_) async =>
            throw StateError('Fictitious navigation failure')));
    await _frames(tester);
    await _tap(tester, find.byKey(const ValueKey('tutoring-guided-start')));
    expect(find.byType(GuidedLessonScreen), findsNothing);
    expect(app.state.section, LumoSection.missions);
    expect(find.textContaining('Der Bildkurs konnte nicht geöffnet werden'),
        findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(
                find.byKey(const ValueKey('tutoring-guided-start')))
            .onPressed,
        isNotNull);
    await _close(tester);
  });

  testWidgets('profiles keep their own recommendation and stored evidence',
      (tester) async {
    final app = await _app(tester);
    await _recordFive(tester, app, 'Deutsch', 'Silben');
    await tester.pumpWidget(_shell(app));
    await _frames(tester);
    await _tap(tester, find.byKey(const ValueKey('tutoring-reason-toggle')));
    expect(find.textContaining('4 von 5'), findsOneWidget);
    await tester
        .runAsync(() => app.school.setActiveStudent('tutoring-proof-b'));
    await _frames(tester);
    expect(find.textContaining('4 von 5'), findsNothing);
    expect(find.textContaining('5 gespeicherte Antworten'), findsNothing);
    expect(find.textContaining('noch keine'), findsOneWidget);
    expect(
        tester
            .widget<Text>(
                find.byKey(const ValueKey('tutoring-recommended-topic')))
            .data,
        'Mathematik · Plus bis 20');
    await tester
        .runAsync(() => app.school.setActiveStudent('tutoring-proof-a'));
    await _frames(tester);
    expect(find.textContaining('5 gespeicherte Antworten'), findsOneWidget);
    expect(
        tester
            .widget<Text>(
                find.byKey(const ValueKey('tutoring-recommended-topic')))
            .data,
        'Deutsch · Silben');
    await _close(tester);
  });

  testWidgets('a callback displayed for profile A cannot execute for profile B',
      (tester) async {
    final app = await _app(tester);
    await _recordFive(tester, app, 'Deutsch', 'Silben');
    final sections = <LumoSection>[];
    await tester.pumpWidget(_shell(app, sections: sections));
    await _frames(tester);
    final oldAction = tester
        .widget<ButtonStyleButton>(
            find.byKey(const ValueKey('tutoring-practice-start')))
        .onPressed!;
    await tester
        .runAsync(() => app.school.setActiveStudent('tutoring-proof-b'));
    await _frames(tester);
    oldAction();
    await _frames(tester);
    expect(sections, isEmpty);
    expect(app.state.section, LumoSection.missions);
    expect(app.learningSkills(), isEmpty);
    await _close(tester);
  });

  testWidgets('unreadable profile B reports the error and keeps both histories',
      (tester) async {
    final app = await _app(tester);
    await _recordFive(tester, app, 'Deutsch', 'Silben');
    await tester.pumpWidget(_shell(app));
    await _frames(tester);
    final badKey = LearningDataNamespace.keyFor(
        'lumo_progress_skills', 'tutoring-proof-b');
    const raw = '{"broken-fixture":';
    await tester.runAsync(() async {
      await (await SharedPreferences.getInstance()).setString(badKey, raw);
      await app.school.setActiveStudent('tutoring-proof-b');
    });
    await _frames(tester);
    expect(find.byKey(const ValueKey('tutoring-read-error')), findsOneWidget);
    expect(find.byKey(const ValueKey('tutoring-practice-start')), findsNothing);
    expect(find.textContaining('5 gespeicherte Antworten'), findsNothing);
    final stored = await tester.runAsync(SharedPreferences.getInstance);
    expect(stored!.getString(badKey), raw);
    await tester
        .runAsync(() => app.school.setActiveStudent('tutoring-proof-a'));
    await _frames(tester);
    expect(find.byKey(const ValueKey('tutoring-read-error')), findsNothing);
    expect(find.textContaining('5 gespeicherte Antworten'), findsOneWidget);
    expect(app.learningSkills()['deutsch::silben']!.attempts, 5);
    expect(stored.getString(badKey), raw);
    await _close(tester);
  });

  testWidgets(
      'failed native saving remains provisional and Retry never recounts',
      (tester) async {
    final store = _RejectableStore();
    SharedPreferencesStorePlatform.instance = store;
    final app = await _app(tester);
    await _recordFive(tester, app, 'Deutsch', 'Silben');
    await tester.pumpWidget(_shell(app));
    await _frames(tester);
    store.rejectedKey =
        'flutter.${LearningDataNamespace.keyFor('lumo_progress_daily', 'tutoring-proof-a')}';
    await tester.runAsync(() async {
      await expectLater(
          app.recordLearningAnswer(
              subject: 'Deutsch',
              unit: 'Silben',
              correct: true,
              requireSaved: true),
          throwsStateError);
    });
    app.update(app.state.copyWith(mood: LumoMood.think));
    await _frames(tester);
    expect(find.textContaining('vorläufig'), findsOneWidget);
    expect(find.textContaining('6 gespeicherte Antworten'), findsNothing);
    final before = app.learningSkills()['deutsch::silben']!.attempts;
    expect(before, 6);
    store.rejectedKey = null;
    await _tap(tester, find.byKey(const ValueKey('tutoring-save-retry')));
    expect(app.learningSkills()['deutsch::silben']!.attempts, before);
    expect(find.textContaining('6 gespeicherte Antworten'), findsOneWidget);
    expect(find.textContaining('vorläufig'), findsNothing);
    final owner = await tester.runAsync(app.captureLearningProfile);
    expect(owner!.profile.hasUnsavedChanges, false);
    await _close(tester);
  });

  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(360, 800), 1.0),
    (const Size(640, 360), 1.4),
    (const Size(2176 / 2.25, 1812 / 2.25), 1.0),
    (const Size(1024, 768), 2.0),
  ]) {
    testWidgets('real course and practice targets: $size / text $scale',
        (tester) async {
      final app = await _app(tester, size: size);
      await _recordFive(tester, app, 'Mathematik', 'Plus bis 20');
      var started = 0;
      await tester.pumpWidget(
          _cardShell(app, textScale: scale, onGuided: () => started++));
      await _frames(tester);
      for (final key in [
        'tutoring-guided-start',
        'tutoring-practice-start',
        'tutoring-reason-toggle',
      ]) {
        final target = find.byKey(ValueKey(key));
        await tester.ensureVisible(target);
        await tester.pump();
        expect(target.hitTestable(), findsOneWidget);
        final rect = tester.getRect(target);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.width, greaterThanOrEqualTo(48));
        expect(tester.takeException(), isNull);
      }
      await _tap(tester, find.byKey(const ValueKey('tutoring-guided-start')));
      expect(started, 1);
      await _close(tester);
    });
  }

  test('only compatible available maths topics get a direct introduction', () {
    expect(
        GuidedLessonCatalog.schoolIntroduction(
            subject: 'Mathematik', unit: 'Plus bis 20', grade: 1),
        GuidedLessonCatalog.bridgeTen);
    expect(
        GuidedLessonCatalog.schoolIntroduction(
            subject: 'Mathematik', unit: 'Einmaleins', grade: 2),
        GuidedLessonCatalog.equalGroups);
    for (final (subject, unit, grade) in [
      ('Deutsch', 'Plus bis 20', 2),
      ('Sachunterricht', 'Einmaleins', 2),
      ('Mathematik', 'Einmaleins', 1),
      ('Mathematik', 'Schriftliche Multiplikation', 4),
      ('Mathematik', 'Nicht vorhandenes Thema', 4),
    ]) {
      expect(
          GuidedLessonCatalog.schoolIntroduction(
              subject: subject, unit: unit, grade: grade),
          isNull);
    }
  });
}
