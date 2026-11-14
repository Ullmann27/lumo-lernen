import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/domain/tutoring/native_english_vocabulary.dart';
import 'package:lumo_lernen/domain/tutoring/native_learning_activity.dart';
import 'package:lumo_lernen/features/learning/adapters/legacy_lumo_task_adapter.dart';
import 'package:lumo_lernen/features/lumo3d/lumo3d_launcher.dart';

import '../../tool/check_native_english_activity.dart' as contract;

const _channel = MethodChannel('lumo_lernen/bridge');

class _EnglishLaunchState extends LumoAppState {
  int generation = 0;

  @override
  int get profileGeneration => generation;

  @override
  Future<void> flushRewards() async {}

  @override
  Future<void> ensureSettingsLoaded() async {}

  @override
  bool get canPlayToday => false;
}

TaskInstance _task(String word) {
  final answer = NativeEnglishVocabulary.meanings[word]!.first;
  return const LegacyLumoTaskAdapter().toTaskInstance(
    task: LumoTask(
      id: 'english-current-$word',
      grade: 1,
      subject: 'Englisch',
      unit: 'Schulsachen',
      prompt: 'Was bedeutet „$word“?',
      answer: answer,
      choices: [answer, if (answer != 'Buch') 'Buch', 'Tasche', 'Heft'],
      explanation: 'Das Wort bedeutet $answer.',
    ),
    childId: 'synthetic-english-child',
    difficulty: 1,
  );
}

Future<BuildContext> _mount(WidgetTester tester) async {
  late BuildContext launchContext;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            launchContext = context;
            return const Text('Die ursprüngliche Aufgabe bleibt hier.');
          },
        ),
      ),
    ),
  );
  return launchContext;
}

Future<void> _frames(WidgetTester tester) async {
  for (var frame = 0; frame < 30; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

void _androidWidgetTest(String name, Future<void> Function(WidgetTester) body) {
  testWidgets(name, (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await body(tester);
    } finally {
      // Flutter verifies this invariant before package-level tearDown runs.
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'lumo_3d_save_salt_v1': 'english-contract-salt',
    });
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          calls.add(call);
          return <String, Object?>{'destination': 'learn'};
        });
  });
  tearDown(() async {
    await LumoVoice.instance.configure(identity: LumoVoiceIdentity.freeOffline);
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  test(
    'actual generator, task ownership and malformed descriptor contracts',
    () {
      // The standalone form runs the same production contract without Flutter.
      // This call makes those checks mandatory in the normal Flutter suite too.
      contract.main([]);
    },
  );

  _androidWidgetTest(
    'all seven English descriptors use the existing learning bridge',
    (tester) async {
      final app = _EnglishLaunchState();
      addTearDown(app.dispose);
      final context = await _mount(tester);
      for (final word in NativeEnglishVocabulary.meanings.keys) {
        final current = _task(word);
        final originalId = current.taskInstanceId;
        final originalAnswer = current.correctAnswer;
        final activity = NativeLearningActivity.fromTask(current)!;
        final launched = launchLumo3D(
          context,
          scene: 'learning',
          appState: app,
          subject: 'Englisch',
          learning: activity,
        );
        await _frames(tester);
        expect(await launched, isTrue);
        final options = calls.last.arguments as Map;
        expect(options['scene'], 'learning');
        expect(options['subject'], 'Englisch');
        expect(options['learning'], activity.toLaunchOptions());
        expect(options['childKey'], matches(r'^p_[a-f0-9]{32}$'));
        expect(app.state.stars, 0);
        expect(current.taskInstanceId, originalId);
        expect(current.correctAnswer, originalAnswer);
      }
      expect(calls, hasLength(7));
      expect(tester.takeException(), isNull);
    },
  );

  _androidWidgetTest(
    'English help preserves the actual parent voice and license gates',
    (tester) async {
      final app = _EnglishLaunchState();
      addTearDown(app.dispose);
      final context = await _mount(tester);
      final activity = NativeLearningActivity.fromTask(_task('book'))!;
      for (final scenario in [
        (true, false, LumoVoiceIdentity.freeOffline, false),
        (false, true, LumoVoiceIdentity.freeOffline, false),
        (true, true, LumoVoiceIdentity.sulafatOriginal, false),
        (true, true, LumoVoiceIdentity.freeOffline, true),
      ]) {
        app.state.settings = AppSettings(
          voiceEnabled: scenario.$1,
          localVoiceLicenseAccepted: scenario.$2,
          autoReadEnabled: true,
          calmMode: true,
          voiceRate: 0.35,
        );
        await LumoVoice.instance.configure(identity: scenario.$3);
        final launched = launchLumo3D(
          context,
          scene: 'learning',
          appState: app,
          subject: 'Englisch',
          learning: activity,
        );
        await _frames(tester);
        expect(await launched, isTrue);
        final options = calls.last.arguments as Map;
        expect(options['learningVoiceEnabled'], scenario.$4);
        expect(options['localVoiceLicenseAccepted'], scenario.$2);
        expect(options['learningAutoRead'], isFalse);
        expect(options['learningVoiceRate'], 1.0);
        expect((options['learning'] as Map)['word'], 'book');
      }
    },
  );

  _androidWidgetTest(
    'late English return cannot attach to another profile generation',
    (tester) async {
      final app = _EnglishLaunchState();
      addTearDown(app.dispose);
      final reply = Completer<Map<String, Object?>>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) {
            calls.add(call);
            return reply.future;
          });
      final context = await _mount(tester);
      final launched = launchLumo3D(
        context,
        scene: 'learning',
        appState: app,
        subject: 'Englisch',
        learning: NativeLearningActivity.fromTask(_task('book'))!,
      );
      await _frames(tester);
      expect(calls, hasLength(1));
      app.generation++;
      reply.complete({'destination': 'learn'});
      await _frames(tester);
      expect(await launched, isFalse);
      expect(app.state.stars, 0);
    },
  );
}
