import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/features/learning/lab/learning_lab_catalog.dart';
import 'package:lumo_lernen/features/learning/lab/learning_lab_screen.dart';

Future<void> frames(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 25));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<void> tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  // Commit scroll geometry before touch on the 320dp and Fold landscape.
  await tester.pump();
  await tester.tap(finder);
  await frames(tester);
}

Future<LumoAppState> mountLab(WidgetTester tester,
    {int grade = 1, int topic = 0, Size size = const Size(600, 1000), double scale = 1}) async {
  SharedPreferences.setMockInitialValues({});
  LumoVoice.instance.isEnabled = false;
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  late LumoAppState app;
  await tester.runAsync(() async {
    app = LumoAppState();
    await app.school.setActiveStudent('atelier-runtime-a');
    await app.hydrateFromWallet();
    await app.loadLearningProfile();
    app.update(app.state.copyWith(grade: grade));
    app.updateSettings(const AppSettings(voiceEnabled: false, autoReadEnabled: false, reduceAnimations: true));
  });
  await tester.pumpWidget(MaterialApp(
    theme: LumoAppTheme.light(),
    builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(scale), disableAnimations: true), child: child!),
    home: LearningLabScreen(appState: app, topic: LabCatalog.topics[topic], seed: 0),
  ));
  await frames(tester);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    app.dispose();
  });
  return app;
}

void main() {
  testWidgets('real build then two new free recall problems persist honest evidence', (tester) async {
    final app = await mountLab(tester);
    await tap(tester, 'lab-next');
    expect(find.byKey(const ValueKey('lab-phase-build')), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tap(tester, 'quantity-add');
    }
    await tap(tester, 'lab-check-model');
    await tap(tester, 'lab-next');
    expect(find.byKey(const ValueKey('lab-answer')), findsOneWidget);
    expect(find.byKey(const ValueKey('lab-model')), findsNothing);
    await tester.enterText(find.byKey(const ValueKey('lab-answer')), '16');
    await tap(tester, 'lab-check-answer');
    await tap(tester, 'lab-next');
    await tester.enterText(find.byKey(const ValueKey('lab-answer')), '11');
    await tap(tester, 'lab-check-answer');
    await tap(tester, 'lab-next');
    expect(find.text('Dein Verstehensmoment'), findsOneWidget);
    await tester.runAsync(() async {
      final owner = await app.captureLearningProfile();
      await owner.profile.loadJourney();
      final id = SkillRecord.makeId('Mathematik', 'Plus bis 20');
      final record = owner.profile.journey.records[id]!;
      expect(record.independentCorrect, 2);
      expect(record.assistedCorrect, 1);
      expect(record.statusLabel, 'Selbstständig geprüft');
      expect(owner.profile.dailyDone(), 2);
    });
    expect(tester.takeException(), isNull);
  });

  testWidgets('specific error opens escalating help and does not claim independence', (tester) async {
    final app = await mountLab(tester);
    await tap(tester, 'lab-next');
    for (var i = 0; i < 3; i++) { await tap(tester, 'quantity-add'); }
    await tap(tester, 'lab-check-model');
    await tap(tester, 'lab-next');
    await tester.enterText(find.byKey(const ValueKey('lab-answer')), '10');
    await tap(tester, 'lab-check-answer');
    expect(find.textContaining('übrige Teil'), findsOneWidget);
    for (var i = 0; i < 3; i++) { await tap(tester, 'lab-help'); }
    expect(find.byKey(const ValueKey('lab-model')), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('lab-answer')), '16');
    await tap(tester, 'lab-check-answer');
    await tester.runAsync(() async {
      final owner = await app.captureLearningProfile();
      final record = owner.profile.journey.records[SkillRecord.makeId('Mathematik', 'Plus bis 20')]!;
      expect(record.independentCorrect, 0);
      expect(record.assistedCorrect, 2);
      expect(record.errorCounts['remainder_missing'], 1);
    });
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile switch invalidates the open task', (tester) async {
    final app = await mountLab(tester);
    await tester.runAsync(() => app.school.setActiveStudent('atelier-runtime-b'));
    await frames(tester);
    expect(find.textContaining('Kinderprofil wurde gewechselt'), findsOneWidget);
    expect(find.byKey(const ValueKey('lab-next')), findsNothing);
  });

  for (final config in [
    (const Size(320, 740), 2.0), (const Size(840, 720), 1.0),
    (const Size(915, 412), 1.4),
  ]) {
    testWidgets('real lab layout ${config.$1} text ${config.$2}', (tester) async {
      await mountLab(tester, size: config.$1, scale: config.$2);
      await tap(tester, 'lab-next');
      expect(tester.takeException(), isNull);
      final check = find.byKey(const ValueKey('lab-check-model'));
      await tester.ensureVisible(check);
      await tester.pump();
      expect(tester.getSize(check).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    });
  }
}
