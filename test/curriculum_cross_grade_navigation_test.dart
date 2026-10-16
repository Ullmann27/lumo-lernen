import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/learning_modules/wortarten/wortarten_screen.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';
import 'package:lumo_lernen/features/tutoring/guided_learning_hub.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';

/// Heinz, 15. Oktober: Ein Kind der 2. Klasse tippt auf die 3. oder 4. Klasse
/// und landete statt im Lernstoff in „Lumo – Entdecke mit mir“. Verbindlich:
/// Jede Klasse 1–4 öffnet ihren echten Lernstoff, die Profilklasse bleibt 2,
/// Aufgaben kommen aus der gewählten Klasse, Antworten tragen ihre Klasse.
/// (Fortsetzung von Astras Navigationstests; im alten Stand scheiterten alle acht.)
Future<LumoAppState> _openAcademy(WidgetTester tester, int selectedGrade) async {
  await tester.binding.setSurfaceSize(const Size(800, 1280));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final app = LumoAppState(walletRepository: RewardWalletRepository());
  app.update(app.state.copyWith(grade: 2));
  await tester.pumpWidget(MaterialApp(home: LumoAkademieScreen(appState: app)));
  await tester.pump(const Duration(milliseconds: 900));
  final pill = find.byKey(ValueKey('grade-pill-$selectedGrade'));
  await tester.ensureVisible(pill);
  await tester.pump();
  await tester.tap(pill);
  await tester.pump(const Duration(milliseconds: 400));
  return app;
}

Future<void> _tapSubject(WidgetTester tester, String id) async {
  final focus = find.byKey(ValueKey('academy-grade-focus-$id'));
  await tester.scrollUntilVisible(focus, 220,
      scrollable: find.byType(Scrollable).first, maxScrolls: 25);
  await tester.pump();
  await tester.tap(focus);
  // Neue Seiten werden im ersten Bild verdeckt aufgebaut.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 650));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
  });
  tearDown(() => LumoVoice.instance.isEnabled = true);

  const subjects = {
    'mathe': 'Mathematik',
    'deutsch': 'Deutsch',
    'englisch': 'Englisch',
    'sachk': 'Sachunterricht',
  };

  for (final grade in [3, 4]) {
    for (final entry in subjects.entries) {
      testWidgets(
          'Profilklasse 2 öffnet ${entry.value} der $grade. Klasse als echten Lernstoff',
          (tester) async {
        final app = await _openAcademy(tester, grade);
        expect(find.text('$grade. Klasse – Lernstoff'), findsOneWidget);
        await _tapSubject(tester, '${entry.key}$grade');

        expect(find.byType(GuidedLearningHub), findsNothing,
            reason: 'Klasseninhalt darf nicht in „Entdecke mit mir“ landen');
        expect(app.state.grade, 2, reason: 'Profilklasse bleibt unverändert');
        if (find.byType(WortartenScreen).evaluate().isNotEmpty) {
          // 3. Klasse Deutsch: eigenes Fachmodul „Wortarten“.
          expect(grade, 3);
        } else {
          final st = app.state;
          expect(st.section, LumoSection.exercises);
          expect(st.subject, entry.value);
          expect(st.learningGrade, grade);
          expect(Curriculum.unitsForGrade(st.subject, grade), contains(st.unit));
          expect(Curriculum.unitsForGrade(st.subject, 2), isNot(contains(st.unit)),
              reason: 'Es ist wirklich Stoff der $grade. Klasse, nicht der 2.');
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        app.dispose();
      });
    }
  }

  testWidgets('Aufgaben kommen aus der Lernklasse, Antworten tragen ihre Klasse',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    await tester.runAsync(app.loadLearningProfile);
    app.update(app.state.copyWith(
      childName: 'Mia',
      grade: 2,
      section: LumoSection.exercises,
      subject: 'Mathematik',
      unit: 'Plus bis 1000',
      learningGrade: 3,
    ));
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: LearningContent(appState: app))));
    await tester.pump();
    final renderer =
        tester.widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer).last);
    expect(renderer.task.difficulty, 3, reason: 'Aufgabe der 3. Klasse');
    expect(renderer.task.parameters['unit'], 'Plus bis 1000');

    final right = renderer.task.options.firstWhere((option) =>
        '${option.payload ?? option.label}' == '${renderer.task.correctAnswer}');
    await tester.tap(find
        .descendant(
            of: find.byType(AdaptiveTaskRenderer).last,
            matching: find.text(right.label))
        .last);
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() async {
      await app.flushAttemptLog();
      final attempts = await app.attemptLog.load();
      expect(attempts, isNotEmpty);
      expect(attempts.last.unit, 'Plus bis 1000');
      expect(attempts.last.grade, 3);
    });
    expect(app.state.grade, 2);
    await tester.pumpWidget(const SizedBox.shrink());
    await app.flushRewards();
    app.dispose();
  });

  test('Die Lernklasse endet mit dem Verlassen der Übung', () {
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    app.update(app.state.copyWith(
        grade: 2, section: LumoSection.exercises, learningGrade: 4));
    expect(app.state.curriculumGrade, 4);
    app.setSection(LumoSection.home);
    expect(app.state.learningGrade, isNull);
    expect(app.state.curriculumGrade, 2);
    expect(app.state.grade, 2);
    app.dispose();
  });

  testWidgets('„Mit Lumo Neues entdecken“ bleibt ein eigener Bereich',
      (tester) async {
    final app = await _openAcademy(tester, 2);
    final discover = find.byKey(const ValueKey('akademie-voluntary-discovery'));
    await tester.scrollUntilVisible(discover, 220,
        scrollable: find.byType(Scrollable).first, maxScrolls: 30);
    await tester.pump();
    await tester.tap(discover);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.byType(GuidedLearningHub), findsOneWidget);
    expect(app.state.grade, 2);
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
  });
}
