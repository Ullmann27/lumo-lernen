import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_learning_session_contract.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/features/photo_lesson/photo_lesson_practice_screen.dart';
import 'package:lumo_lernen/features/photo_lesson/photo_lesson_session.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';
import 'helpers/lumo_capture.dart';

const _task = LumoTask(
    id: 'photo-math-preserved',
    grade: 1,
    subject: 'Mathematik',
    unit: 'Plus bis 20',
    prompt: '8 + 5 = ?',
    choices: ['12', '13', '14'],
    answer: '13',
    explanation: 'Acht und zwei sind zehn. Drei bleiben übrig: 13.',
    visual: 'ten_frame');

class _Repository extends PhotoLessonSessionRepository {
  _Repository({required super.studentId, required super.mayWrite});
  bool fail = false;
  @override
  Future<void> save(PhotoLessonSession value,
      {PhotoLessonSession? replacing}) async {
    if (fail) throw StateError('Disk unavailable');
    await super.save(value, replacing: replacing);
  }
}

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 40));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<({LumoAppState app, LearningProfileLease lease, _Repository repository})>
    _open(WidgetTester tester) async {
  final app = LumoAppState();
  LearningProfileLease? lease;
  _Repository? repository;
  Future<Widget> initialize() async {
    await app.ensureSettingsLoaded();
    await app.loadLearningProfile();
    final owner = await app.captureLearningProfile();
    lease = owner;
    final store = _Repository(
        studentId: owner.studentId,
        mayWrite: () =>
            app.canUseLearningLease(owner) &&
            app.profileGeneration == owner.generation);
    repository = store;
    final session = PhotoLessonSession.start([_task]);
    await store.save(session);
    return RepaintBoundary(
      key: const ValueKey('photo-full-screen-capture'),
      child: PhotoLessonPracticeScreen(
          appState: app, lease: owner, repository: store, session: session),
    );
  }

  final ready = initialize();
  await tester.pumpWidget(MaterialApp(
      theme: LumoAppTheme.light(),
      home: FutureBuilder<Widget>(
    future: ready,
    builder: (_, snapshot) => snapshot.data ?? const SizedBox.shrink(),
  )));
  await _frames(tester);
  expect(find.byType(PhotoLessonPracticeScreen), findsOneWidget);
  return (app: app, lease: lease!, repository: repository!);
}

Future<void> _close(WidgetTester tester, LumoAppState app) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await _frames(tester);
  app.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bus = LumoCompanionRequests.instance;
  setUpAll(() async {
    await loadLumoCaptureFonts();
    await loadLumoCaptureEmojiFont();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'lumo_learning_local_student_id_v1': 'photo-test-profile',
      'lumo_app_settings_v1': jsonEncode(const AppSettings(
              voiceEnabled: false, microphoneEnabled: false, calmMode: true)
          .toJson()),
    });
    LumoVoice.instance.isEnabled = false;
    bus.clearLearningScope();
  });
  tearDown(() => LumoVoice.instance.isEnabled = true);

  testWidgets(
      'an uncertain spoken proposal is editable and never scores itself',
      (tester) async {
    final fixture = await _open(tester);
    final identity = bus.learningIdentity.value!;
    expect(bus.taskContext.value!.activity, 'photo-practice');
    expect(
        bus.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: identity, candidate: 'dreizehn vielleicht'),
        isTrue);
    await _frames(tester);
    final before = await tester.runAsync(fixture.repository.load);
    expect(before!.attempts, isEmpty);
    final field = find.byKey(const ValueKey('photo-answer-proposal'));
    await tester.ensureVisible(field);
    await tester.enterText(field, '13');
    final confirm = find.text('Diese Antwort prüfen');
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await _frames(tester);
    final saved = await tester.runAsync(fixture.repository.load);
    expect(saved!.attempts, hasLength(1));
    expect(saved.attempts.single.correct, isTrue);
    expect(saved.syncedAttempts, 1);
    expect(fixture.app.state.stars, 0);
    expect(fixture.app.state.xp, 0);
    expect(find.text('Deine Foto-Übungen sind gespeichert'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _close(tester, fixture.app);
  });

  testWidgets(
      'rapid answer taps and failed storage retry keep one accepted attempt',
      (tester) async {
    final fixture = await _open(tester);
    fixture.repository.fail = true;
    final choice = find.text('13');
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    await tester.tap(choice);
    await _frames(tester);
    expect((await tester.runAsync(fixture.repository.load))!.attempts, isEmpty);
    expect(find.text('Speichern erneut versuchen'), findsOneWidget);
    fixture.repository.fail = false;
    final retry = find.text('Speichern erneut versuchen');
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await _frames(tester);
    final saved = await tester.runAsync(fixture.repository.load);
    expect(saved!.attempts, hasLength(1));
    expect(saved.syncedAttempts, 1);
    await tester.runAsync(fixture.app.loadTutorJourney);
    final journey = fixture.app.learningJourney().values.single;
    expect(journey.recentTaskIds, [saved.attempts.single.id]);
    expect(journey.independentCorrect, 1);
    expect(fixture.app.learningDailyDone(), 0,
        reason:
            'Photo practice preserves the existing separate school/reward boundary.');
    expect(tester.takeException(), isNull);
    await _close(tester, fixture.app);
  });

  testWidgets(
      'hints remain assisted after repeat stop and process-style remount',
      (tester) async {
    final fixture = await _open(tester);
    final initial = bus.learningIdentity.value!;
    expect(
        bus.requestLearningAction(LumoLearningAction.hint, identity: initial),
        isTrue);
    await _frames(tester);
    expect(bus.taskContext.value!.helpLevel, 1);
    expect(
        bus.requestLearningAction(LumoLearningAction.repeat, identity: initial),
        isFalse);
    bus.requestLearningAction(LumoLearningAction.repeat,
        identity: bus.learningIdentity.value!);
    await _frames(tester);
    bus.requestLearningAction(LumoLearningAction.stop,
        identity: bus.learningIdentity.value!);
    await _frames(tester);
    expect(bus.taskContext.value!.isExplanation, isFalse);
    final persisted = await tester.runAsync(fixture.repository.load);
    expect(persisted!.helpLevel, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await _frames(tester);
    await tester.pumpWidget(MaterialApp(
        theme: LumoAppTheme.light(),
        home: PhotoLessonPracticeScreen(
            appState: fixture.app,
            lease: fixture.lease,
            repository: fixture.repository,
            session: persisted)));
    await _frames(tester);
    final choice = find.text('13');
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    await _frames(tester);
    final saved = await tester.runAsync(fixture.repository.load);
    expect(saved!.attempts.single.helpLevel, 1);
    expect(saved.independentCount, 0);
    expect(tester.takeException(), isNull);
    await _close(tester, fixture.app);
  });

  testWidgets(
      'complete phone viewport retains the task and accessible controls',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(344, 882));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = await _open(tester);
    for (final name in ['Hilf mir', 'Noch einmal', 'Stopp']) {
      final button = find
          .ancestor(of: find.text(name), matching: find.byType(OutlinedButton))
          .first;
      final size = tester.getSize(button);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
    expect(find.text('8 + 5 = ?'), findsOneWidget);
    final destination = Platform.environment['LUMO_PHOTO_CAPTURE'];
    if (destination != null) {
      await captureLumoBoundary(
          tester, const ValueKey('photo-full-screen-capture'), destination);
    }
    expect(tester.takeException(), isNull);
    await _close(tester, fixture.app);
  });
}
