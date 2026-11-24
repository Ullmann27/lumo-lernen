import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/legacy_learning_data.dart';
import 'package:lumo_lernen/core/lumo_speech_listener.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/features/recognition/lumo_task_recognition_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Controlled native callbacks exercise the real shared speech adapter and
/// screen. They are not recordings or proof of recognition on a physical phone.
class _SpeechEngine extends stt.SpeechToText {
  _SpeechEngine() : super.withMethodChannel();
  int initializes = 0, listens = 0, cancels = 0, stops = 0;
  stt.SpeechListenOptions? options;
  stt.SpeechStatusListener? status;
  stt.SpeechErrorListener? error;
  Completer<bool>? initialization;
  final results = <stt.SpeechResultListener>[];

  @override
  Future<bool> initialize({
    stt.SpeechErrorListener? onError,
    stt.SpeechStatusListener? onStatus,
    dynamic debugLogging = false,
    Duration finalTimeout = stt.SpeechToText.defaultFinalTimeout,
    List<stt.SpeechConfigOption>? options,
  }) async {
    initializes++;
    status = onStatus;
    error = onError;
    return initialization == null ? true : initialization!.future;
  }

  @override
  Future<List<stt.LocaleName>> locales() async => [
    stt.LocaleName('de_DE', 'Deutsch'),
  ];

  @override
  Future<void> listen({
    stt.SpeechResultListener? onResult,
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
    stt.SpeechSoundLevelChange? onSoundLevelChange,
    dynamic cancelOnError = false,
    dynamic partialResults = true,
    dynamic onDevice = false,
    stt.ListenMode listenMode = stt.ListenMode.confirmation,
    dynamic sampleRate = 0,
    stt.SpeechListenOptions? listenOptions,
  }) async {
    listens++;
    options = listenOptions;
    results.add(onResult!);
    status?.call('listening');
  }

  @override
  Future<void> cancel() async => cancels++;

  @override
  Future<void> stop() async => stops++;

  void words(String text, {bool finalResult = true, int? capture}) =>
      results[capture ?? results.length - 1](
        SpeechRecognitionResult.init([
          SpeechRecognitionWords(text, null, .92),
        ], finalResult ? ResultType.finalResult : ResultType.partial),
      );
}

Future<void> _frames(WidgetTester tester, [int count = 8]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 17));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<void> _tap(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.tap(target);
  await _frames(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const diagnostics = MethodChannel('lumo_lernen/diagnostics');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final field = find.byKey(const ValueKey('recognition-input'));
  late _SpeechEngine engine;
  late LumoAppState app;
  bool localAvailable = true;

  Future<void> open(WidgetTester tester, {bool microphone = true}) async {
    const localId = 'recognition-speech-child';
    SharedPreferences.setMockInitialValues({
      LegacyLearningDataRepository.localIdKey: localId,
      'lumo_app_settings_v1': jsonEncode(
        AppSettings(
          microphoneEnabled: microphone,
          voiceEnabled: false,
        ).toJson(),
      ),
    });
    LumoVoice.instance.isEnabled = false;
    localAvailable = true;
    messenger.setMockMethodCallHandler(
      diagnostics,
      (_) async => localAvailable,
    );
    engine = _SpeechEngine();
    app = (await tester.runAsync(() async {
      final state = LumoAppState();
      await state.ensureSettingsLoaded();
      await state.loadLearningProfile();
      await state.hydrateFromWallet();
      return state;
    }))!;
    final speech = LumoSpeechListener(
      isAndroid: true,
      recognizer: LumoSpeechRecognizer.withEngine(engine),
      stopPlayback: () async {},
    );
    await tester.pumpWidget(
      MaterialApp(
        home: LumoTaskRecognitionScreen(appState: app, speechListener: speech),
      ),
    );
    await _frames(tester, 24);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      if (engine.initialization case final gate?) {
        if (!gate.isCompleted) gate.complete(false);
      }
      await _frames(tester, 2);
      app.dispose();
      messenger.setMockMethodCallHandler(diagnostics, null);
      LumoVoice.instance.isEnabled = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });
  }

  String text(WidgetTester tester) =>
      tester.widget<TextField>(field).controller!.text;

  testWidgets(
    'native final proposes the spoken task without starting or grading',
    (tester) async {
      await open(tester);
      expect(engine.initializes, 0);
      final microphone = find.byKey(const ValueKey('recognition-speech'));
      expect(tester.getSize(microphone).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(microphone).width, greaterThanOrEqualTo(48));
      await _tap(tester, 'recognition-speech');
      expect(engine.options?.onDevice, true);
      expect(engine.options?.localeId, 'de_DE');
      engine.words('Anfangsbuchstabe', finalResult: false);
      await _frames(tester);
      expect(text(tester), isEmpty);
      expect(find.byKey(const ValueKey('recognition-start')), findsNothing);
      engine.words('Anfangsbuchstabe Mama');
      await _frames(tester);
      expect(text(tester), 'Anfangsbuchstabe Mama');
      expect(
        find.text('Mit welchem Buchstaben beginnt „Mama“?'),
        findsOneWidget,
      );
      expect(find.byType(AdaptiveTaskRenderer), findsNothing);
      expect(app.state.stars, 0);
      expect(app.state.xp, 0);
      expect(await tester.runAsync(() => app.attemptLog.load()), isEmpty);
      await tester.enterText(field, '12 + 7');
      await _frames(tester);
      expect(find.byKey(const ValueKey('recognition-preview')), findsNothing);
      await _tap(tester, 'recognition-parse');
      expect(find.text('12 + 7 = ?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'explicit finish waits for the final and preserves parser errors',
    (tester) async {
      await open(tester);
      await _tap(tester, 'recognition-speech');
      engine.words('12 +', finalResult: false);
      await _frames(tester);
      final finish = find.byKey(const ValueKey('recognition-speech-finish'));
      expect(tester.getSize(finish).height, greaterThanOrEqualTo(48));
      await _tap(tester, 'recognition-speech-finish');
      expect(engine.stops, 1);
      expect(text(tester), isEmpty);
      engine.words('12 + 7');
      await _frames(tester);
      expect(text(tester), '12 + 7');
      expect(find.text('12 + 7 = ?'), findsOneWidget);
      await _tap(tester, 'recognition-speech');
      engine.words('zwölf plus sieben');
      await _frames(tester);
      expect(text(tester), 'zwölf plus sieben');
      expect(find.byKey(const ValueKey('recognition-error')), findsOneWidget);
      expect(find.byKey(const ValueKey('recognition-start')), findsNothing);
      expect(tester.widget<TextField>(field).enabled, true);
    },
  );

  testWidgets('cancel keeps the typed draft and ignores a late native final', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(field, '6 × 3');
    await _tap(tester, 'recognition-speech');
    engine.words('Anfangsbuchstabe', finalResult: false);
    await _frames(tester);
    final cancels = engine.cancels;
    await _tap(tester, 'recognition-speech');
    expect(engine.cancels, greaterThan(cancels));
    engine.words('Anfangsbuchstabe Mama');
    await _frames(tester);
    expect(text(tester), '6 × 3');
    expect(find.byKey(const ValueKey('recognition-start')), findsNothing);
    await _tap(tester, 'recognition-parse');
    expect(find.text('6 × 3 = ?'), findsOneWidget);
  });

  testWidgets(
    'no local recognizer keeps typing available without cloud capture',
    (tester) async {
      await open(tester);
      localAvailable = false;
      await _tap(tester, 'recognition-speech');
      expect(engine.initializes, 0);
      expect(engine.listens, 0);
      expect(find.textContaining('keine Cloud-Aufnahme'), findsOneWidget);
      expect(tester.widget<TextField>(field).enabled, true);
      await tester.enterText(field, '12 + 7');
      await _tap(tester, 'recognition-parse');
      expect(find.text('12 + 7 = ?'), findsOneWidget);
    },
  );

  testWidgets('parent microphone denial never initializes the recognizer', (
    tester,
  ) async {
    await open(tester, microphone: false);
    await _tap(tester, 'recognition-speech');
    expect(engine.initializes, 0);
    expect(engine.listens, 0);
    expect(find.textContaining('Elternbereich ausgeschaltet'), findsOneWidget);
    expect(tester.widget<TextField>(field).enabled, true);
  });

  testWidgets('device permission denial exposes a usable text fallback', (
    tester,
  ) async {
    await open(tester);
    await _tap(tester, 'recognition-speech');
    engine.error?.call(SpeechRecognitionError('error_permission', true));
    await _frames(tester);
    expect(
      find.textContaining('Mikrofon ist nicht freigegeben'),
      findsOneWidget,
    );
    expect(tester.widget<TextField>(field).enabled, true);
    expect(find.byKey(const ValueKey('recognition-start')), findsNothing);
  });

  for (final invalidation in [
    'profile',
    'background',
    'route',
    'parent setting',
  ]) {
    testWidgets(
      '$invalidation fences the old transcript before it can be used',
      (tester) async {
        await open(tester);
        await _tap(tester, 'recognition-speech');
        switch (invalidation) {
          case 'profile':
            await tester.runAsync(
              () => app.school.setActiveStudent('other-child'),
            );
          case 'background':
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.inactive,
            );
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.resumed,
            );
          case 'route':
            final navigator = Navigator.of(tester.element(field));
            unawaited(
              navigator.push(
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: Text('Andere Ansicht')),
                ),
              ),
            );
            await _frames(tester, 30);
            navigator.pop();
          case 'parent setting':
            app.updateSettings(
              app.state.settings.copyWith(microphoneEnabled: false),
            );
        }
        await _frames(tester, 30);
        engine.words('Anfangsbuchstabe Mama');
        await _frames(tester);
        expect(text(tester), isEmpty);
        expect(find.byKey(const ValueKey('recognition-start')), findsNothing);
        expect(app.state.stars, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'disposed screen cannot start after delayed permission succeeds',
    (tester) async {
      await open(tester);
      engine.initialization = Completer<bool>();
      await _tap(tester, 'recognition-speech');
      expect(engine.initializes, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      engine.initialization!.complete(true);
      await _frames(tester);
      expect(engine.listens, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
