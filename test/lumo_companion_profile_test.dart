import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/learning_profile_engine.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/core/legacy_learning_data.dart';
import 'package:lumo_lernen/features/magic_hub/lumo_magic_hub_screen.dart';

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

class _DelayedProfile extends LearningProfileEngine {
  _DelayedProfile(this.gate)
      : super(repository: ProgressRepository(studentId: 'slow-profile-a'));
  final Completer<void> gate;
  @override
  Future<void> load() async {
    await gate.future;
    await super.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'late profile A load cannot replace the visible profile B summary',
      (tester) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    SharedPreferences.setMockInitialValues({
      LearningDataNamespace.keyFor('lumo_progress_daily', 'slow-profile-a'):
          jsonEncode({today: 2}),
      LearningDataNamespace.keyFor('lumo_progress_daily', 'fast-profile-b'):
          jsonEncode({today: 1}),
    });
    final gate = Completer<void>();
    final slow = _DelayedProfile(gate);
    final app = LumoAppState(
        learningProfileFactory: (id) => id == 'slow-profile-a'
            ? slow
            : LearningProfileEngine(
                repository: ProgressRepository(studentId: id)));
    await tester.binding.setSurfaceSize(const Size(600, 1200));
    await tester.runAsync(() => app.school.setActiveStudent('slow-profile-a'));
    await tester
        .pumpWidget(MaterialApp(home: LumoMagicHubScreen(appState: app)));
    await _frames(tester);
    await tester.runAsync(() async {
      await app.school.setActiveStudent('fast-profile-b');
      await app.loadLearningProfile();
    });
    await _frames(tester);
    expect(find.text('Heute schon 1 richtig!'), findsOneWidget);
    await tester.runAsync(() async {
      gate.complete();
      await slow.load();
    });
    await _frames(tester);
    expect(find.text('Heute schon 1 richtig!'), findsOneWidget);
    expect(find.text('Heute schon 2 richtig!'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
    await tester.binding.setSurfaceSize(null);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Magic Hub uses its child progress and preserves unowned memory',
      (tester) async {
    final oldMemory = jsonEncode({
      'name': 'Anderes Kind',
      'ct': 42,
      'tc': 42,
      'ld': DateTime.now().toIso8601String().substring(0, 10),
    });
    SharedPreferences.setMockInitialValues({'lumo_companion_v1': oldMemory});
    await tester.binding.setSurfaceSize(const Size(600, 1200));
    final app = LumoAppState();
    app.updateSettings(const AppSettings(voiceEnabled: false));
    await tester.runAsync(() async {
      await app.school.setActiveStudent('companion-test-a');
      await app.loadLearningProfile();
      for (var i = 0; i < 2; i++) {
        await app.recordLearningAnswer(
            subject: 'Mathematik',
            unit: 'Plus bis 10',
            correct: true,
            requireSaved: true);
      }
    });
    await tester
        .pumpWidget(MaterialApp(home: LumoMagicHubScreen(appState: app)));
    await _frames(tester);
    expect(find.text('Heute schon 2 richtig!'), findsOneWidget);
    expect(find.textContaining('42'), findsNothing);
    final prefs = await tester.runAsync(SharedPreferences.getInstance);
    expect(prefs!.getString('lumo_companion_v1'), oldMemory);

    await tester.runAsync(() async {
      await app.school.setActiveStudent('companion-test-b');
      await app.loadLearningProfile();
      await app.recordLearningAnswer(
          subject: 'Deutsch',
          unit: 'Silben',
          correct: true,
          requireSaved: true);
    });
    await _frames(tester);
    expect(find.text('Heute schon 1 richtig!'), findsOneWidget);
    expect(find.text('Heute schon 2 richtig!'), findsNothing);

    await tester.runAsync(() async {
      await app.school.setActiveStudent('companion-test-a');
      await app.loadLearningProfile();
    });
    await _frames(tester);
    expect(find.text('Heute schon 2 richtig!'), findsOneWidget);
    expect(prefs.getString('lumo_companion_v1'), oldMemory);
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
    await tester.binding.setSurfaceSize(null);
    expect(tester.takeException(), isNull);
  });
}
