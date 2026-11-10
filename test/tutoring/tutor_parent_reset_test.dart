import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/learning_journey.dart';
import 'package:lumo_lernen/core/learning_profile_engine.dart';
import 'package:lumo_lernen/core/legacy_learning_data.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/core/writing_progress_repository.dart';
import 'package:lumo_lernen/domain/learning_intelligence/learning_scene_contract.dart';
import 'package:lumo_lernen/domain/learning_intelligence/scene_memory.dart';
import 'package:lumo_lernen/domain/tutoring/guided_lesson_catalog.dart';
import 'package:lumo_lernen/domain/tutoring/guided_lesson_evidence.dart';
import 'package:lumo_lernen/features/parents/widgets/lumo_tutor_evidence_card.dart';
import 'package:lumo_lernen/features/journal/journal_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _ResetStore extends InMemorySharedPreferencesStore {
  _ResetStore() : super.withData({});
  bool rejectJourney = false;
  @override
  Future<bool> setValue(String type, String key, Object value) async =>
      rejectJourney && key.contains('lumo_progress_journey_v1')
          ? false
          : super.setValue(type, key, value);
}

const _evidence = LearningEvidence(
    taskId: 'parent-observation',
    problemId: 'sum-8-5',
    correct: true,
    helpLevel: 2);

Future<void> _seed(LumoAppState app, String child) async {
  await app.school.setActiveStudent(child);
  await app.loadLearningProfile();
  await app.recordLearningAnswer(
      subject: 'Mathematik',
      unit: 'Plus bis 20',
      correct: true,
      requireSaved: true);
  await app.recordTutorEvidence(
      subject: 'Mathematik', unit: 'Plus bis 20', evidence: _evidence);
  await app.saveLearningScene(
      observation: SceneObservation.methodFeedback(
          id: 'parent-scene',
          conceptId: 'math.tens_ones',
          problemId: 'tens-13',
          method: ExplanationMethod.pictorial,
          understood: false,
          at: DateTime.utc(2026, 11, 10)));
}

bool _isTutorKey(String key) => [
      'lumo_progress_journey_v1',
      'lumo_learning_scenes_v1',
      'lumo_learning_scene_pending_v1',
      'lumo_tutor_reset_pending_v1'
    ].any((prefix) =>
        key ==
            'shared_preferences.${LearningDataNamespace.keyFor(prefix, 'reset-a')}' ||
        key == LearningDataNamespace.keyFor(prefix, 'reset-a'));

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 25; i++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
      'targeted reset preserves every unrelated saved byte and rejects old actions',
      () async {
    final app = LumoAppState();
    addTearDown(app.dispose);
    await _seed(app, 'reset-b');
    await _seed(app, 'reset-a');
    await app.recordLumoCardsResult(won: true);
    await WritingProgressRepository().recordCompletedWord('Testwort');
    await const JournalRepository().add(text: 'Fiktiver Testeintrag', title: 'Test');
    final owner = await app.captureLearningProfile();
    final prefs = await SharedPreferences.getInstance();
    final before = {
      for (final key in prefs.getKeys())
        if (!_isTutorKey(key)) key: prefs.get(key)
    };
    expect(await app.resetTutorObservations(lease: owner), isTrue);
    expect(app.canUseLearningLease(owner), isFalse);
    await app.recordTutorEvidence(
        subject: 'Mathematik',
        unit: 'Plus bis 20',
        evidence: _evidence,
        lease: owner);
    final restored = LearningProfileEngine(
        repository: ProgressRepository(studentId: 'reset-a'));
    await restored.load();
    await restored.loadJourney();
    await restored.loadSceneMemory();
    expect(restored.journey.records, isEmpty);
    expect(restored.sceneMemory.records, isEmpty);
    expect(restored.skills.values.single.correct, 1);
    expect(restored.dailyDone(), 1);
    await prefs.reload();
    expect({
      for (final key in prefs.getKeys())
        if (!_isTutorKey(key)) key: prefs.get(key)
    }, before);
    expect(
        (await ProgressRepository(studentId: 'reset-b').loadJourney())
            .records
            .values
            .single
            .assistedCorrect,
        1);
    expect(await app.resetTutorObservations(lease: owner), isFalse);
  });

  test(
      'interrupted deletion recovers before reading stale evidence or pending receipt',
      () async {
    final store = _ResetStore();
    SharedPreferencesStorePlatform.instance = store;
    final app = LumoAppState();
    addTearDown(app.dispose);
    await _seed(app, 'reset-a');
    final owner = await app.captureLearningProfile();
    final prefs = await SharedPreferences.getInstance();
    // An old receipt must be discarded, not parsed/replayed after deletion.
    await prefs.setString(
        LearningDataNamespace.keyFor(
            'lumo_learning_scene_pending_v1', 'reset-a'),
        '{old-pending');
    store.rejectJourney = true;
    await expectLater(
        app.resetTutorObservations(lease: owner), throwsStateError);
    expect(
        prefs.getString(LearningDataNamespace.keyFor(
            'lumo_tutor_reset_pending_v1', 'reset-a')),
        '1');
    store.rejectJourney = false;
    final restarted = ProgressRepository(studentId: 'reset-a');
    expect(await restarted.loadPendingSceneReceipt(), isNull);
    expect((await restarted.loadJourney()).records, isEmpty);
    expect((await restarted.loadSceneMemory()).records, isEmpty);
    expect((await restarted.loadSkills()).values.single.correct, 1);
    expect(
        prefs.getString(LearningDataNamespace.keyFor(
            'lumo_tutor_reset_pending_v1', 'reset-a')),
        '0');
  });

  test(
      'real error patterns, assistance, transfer and delayed review survive restarts',
      () async {
    const lesson = GuidedLessonCatalog.bridgeTen;
    final questions = lesson.steps.where((step) => step.isIndependent).toList();
    final initial = DateTime.utc(2026, 11, 10);
    final repository = ProgressRepository(studentId: 'review-a');
    var engine = LearningProfileEngine(repository: repository);
    Future<void> answer(String id, GuidedLessonStep step, String answer,
        {int attempts = 1, int help = 0, int day = 0}) async {
      await engine.recordJourneyEvidence(
          subject: lesson.subject,
          unit: lesson.schoolUnit,
          now: initial.add(Duration(days: day)),
          evidence: GuidedLessonEvidence.observation(
              lesson: lesson,
              step: step,
              attemptId: id,
              answer: answer,
              attempts: attempts,
              helpLevel: help));
      engine = LearningProfileEngine(
          repository: ProgressRepository(studentId: 'review-a'));
      await engine.loadJourney();
    }

    for (var i = 0; i < 3; i++) {
      await answer('mistake-$i', questions.first, '10');
    }
    var skill = engine.journey.records.values.single;
    expect(skill.errorCounts['answer_stops_at_ten'], 3);
    expect(skill.needsPractice, isTrue);
    expect(skill.status, JourneyStatus.practicing);
    expect(
        GuidedLessonEvidence.hintForAnswer(
            lesson: lesson, step: questions.first, answer: '10'),
        contains('Äpfel daneben'));
    await answer('assisted', questions.first, questions.first.expected,
        attempts: 4, help: 2);
    expect(engine.journey.records.values.single.assistedCorrect, 1);
    expect(engine.journey.records.values.single.independentCorrect, 0);
    await answer('fresh-try', questions.first, questions.first.expected);
    await answer('different-problem', questions.last, questions.last.expected);
    skill = engine.journey.records.values.single;
    expect(skill.status, JourneyStatus.independentlyChecked);
    expect(skill.transferCorrect, 1);
    expect(skill.dueAt, initial.add(const Duration(days: 1)));
    await answer('day-three', questions.last, questions.last.expected, day: 3);
    skill = engine.journey.records.values.single;
    expect(skill.status, JourneyStatus.retained);
    expect(skill.reviewStage, 1);
    expect(skill.dueAt, initial.add(const Duration(days: 6)));
    await answer('day-seven', questions.first, questions.first.expected,
        day: 7);
    skill = engine.journey.records.values.single;
    expect(skill.reviewStage, 2);
    expect(skill.dueAt, initial.add(const Duration(days: 14)));
    expect(
        (await ProgressRepository(studentId: 'unobserved-child').loadJourney())
            .records,
        isEmpty);
  });

  for (final switchChild in [false, true]) {
    testWidgets(
        'parent reset requires confirmation; changed child=$switchChild',
        (tester) async {
      final app = LumoAppState();
      addTearDown(app.dispose);
      await tester.runAsync(() => _seed(app, 'reset-a'));
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SingleChildScrollView(
                  child: LumoTutorEvidenceCard(appState: app)))));
      final reset = find.byKey(const ValueKey('parent-reset-tutor-evidence'));
      await tester.ensureVisible(reset);
      await tester.tap(reset);
      await _frames(tester);
      final confirm = find.byKey(const ValueKey('parent-confirm-tutor-reset'));
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      await tester.tap(find.text('Abbrechen'));
      await _frames(tester);
      expect(app.learningJourney().values.single.assistedCorrect, 1);
      await tester.tap(reset);
      await _frames(tester);
      await tester.tap(find.byType(CheckboxListTile));
      await _frames(tester);
      if (switchChild) {
        await tester.runAsync(() async {
          await app.school.setActiveStudent('reset-b');
          await app.loadLearningProfile();
        });
      }
      await tester.tap(confirm);
      await _frames(tester);
      await tester.runAsync(() async {
        final saved =
            (await ProgressRepository(studentId: 'reset-a').loadJourney())
                .records;
        expect(saved.isEmpty, !switchChild);
        expect(
            (await ProgressRepository(studentId: 'reset-a').loadSkills())
                .values
                .single
                .correct,
            1);
      });
      expect(
          find.textContaining(switchChild
              ? 'Es wurde nichts gelöscht.'
              : 'Lerneinschätzungen zurückgesetzt.'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
