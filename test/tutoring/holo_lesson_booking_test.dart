import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/tutoring/native_learning_activity.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

const _channel = MethodChannel('lumo_lernen/bridge');

Future<void> _frames(WidgetTester tester, [int count = 20]) async {
  for (var index = 0; index < count; index++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

/// Regulärer Lernweg: Mathematik Klasse 1 → „Textaufgaben“ → Aufgabe mit
/// Zehnerübergang → „In 3D“ → Holo-Raum → Rückgabe → Buchung in der App.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];
  Map<String, Object?>? learningResult;

  setUp(() {
    LumoCompanionRequests.instance.clearLearningScope();
    SharedPreferences.setMockInitialValues(
        {'lumo_3d_save_salt_v1': 'learning-test-salt'});
    calls.clear();
    learningResult = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      calls.add(call);
      if (call.method != 'launch3D') return null;
      final learning = Map<String, Object?>.from(
          (call.arguments as Map)['learning'] as Map);
      final a = learning['a'] as int;
      final b = learning['b'] as int;
      final twin = learning['twin'] as Map;
      learningResult = {
        'resultId': 'holo-session-1',
        'taskId': learning['sourceTaskId'],
        'kind': 'holo_word_problem',
        'mode': 'add',
        // Echte Belegfolge im Holo-Raum: 12 falsch, 14 falsch, Hilfe, richtig.
        'originalAnswer': '${a + b}',
        'originalCorrect': true,
        'originalAttempts': 3,
        'hintLevel': 2,
        'twinSolved': true,
        'twinAttempts': 1,
        'twinPrompt': twin['prompt'],
      };
      return <String, Object?>{
        'destination': 'learn',
        'learningResult': jsonEncode(learningResult),
      };
    });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  testWidgets('Holo-Textaufgabe wird einmal mit Hilfe gebucht', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    LumoAppState? app;
    try {
      await tester.binding.setSurfaceSize(const Size(690, 1100));
      await tester.runAsync(() async {
        app = LumoAppState(walletRepository: RewardWalletRepository());
        app!.update(app!.state.copyWith(
            grade: 1,
            subject: 'Mathematik',
            unit: 'Textaufgaben',
            sessionKind: LumoSessionKind.quickPractice,
            section: LumoSection.learn));
      });
      // Eine Aufgabe des echten Generators mit Korb und Zehnerübergang.
      var opened = false;
      // taskSeed 7 öffnet „Im Korb liegen 9 Äpfel. Lumo legt 6 dazu.“
      for (var seed = 7; seed < 80 && !opened; seed++) {
        await tester.pumpWidget(MaterialApp(
            key: ValueKey(seed),
            home: Scaffold(
                body: LearningContent(appState: app!, taskSeed: seed))));
        await _frames(tester, 12);
        final task = tester
            .widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer))
            .task;
        opened = NativeLearningActivity.holoFor(task) != null;
        if (opened) debugPrint('Holo-Textaufgabe bei taskSeed $seed: ${task.prompt}');
      }
      expect(opened, isTrue, reason: 'Kein Holo-Einstieg in 80 Aufgaben');
      final task = tester
          .widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer))
          .task;
      final action = find.byKey(const ValueKey('adaptive-open-3d'));
      expect(action, findsOneWidget);
      await tester.ensureVisible(action);
      await tester.tap(action);
      await _frames(tester, 40);
      expect(calls.where((call) => call.method == 'launch3D'), hasLength(1));
      final launched = Map<String, Object?>.from(
          (calls.single.arguments as Map)['learning'] as Map);
      expect(launched['kind'], 'holo_word_problem');
      expect(launched['sourceTaskId'], task.taskInstanceId);
      var saved = false;
      app!.flushLearningProgress().then((_) => saved = true);
      for (var frame = 0; frame < 120 && !saved; frame++) {
        await _frames(tester, 1);
      }
      expect(saved, isTrue);
      await tester.runAsync(() async {
        final history = await app!.attemptLog.load();
        final original =
            history.where((entry) => entry.prompt == task.prompt).toList();
        expect(original, hasLength(1), reason: 'genau einmal gebucht');
        expect(original.single.correct, isTrue);
        expect(original.single.hintUsed, isTrue,
            reason: '3D und gestufte Hilfe zählen als Hilfe');
        final twin = history
            .where((entry) => entry.prompt == learningResult!['twinPrompt'])
            .toList();
        expect(twin, hasLength(1), reason: 'Zwillingsaufgabe als Nachweis');
        expect(twin.single.hintUsed, isFalse);
      });
      // Der Erfolgston braucht das native Audio-Plugin, das im Test fehlt.
      final error = tester.takeException();
      expect(error == null || '$error'.contains('audioplayers'), isTrue,
          reason: '$error');
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      app?.dispose();
      await tester.binding.setSurfaceSize(null);
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
