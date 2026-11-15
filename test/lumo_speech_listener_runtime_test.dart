import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_speech_listener.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Synthetic recognizer callbacks test ownership and cancellation. They are
/// deliberately not recordings or evidence of Android speech recognition.
class _SpeechEngine extends stt.SpeechToText {
  _SpeechEngine() : super.withMethodChannel();

  int initializes = 0;
  int listens = 0;
  int cancels = 0;
  int stops = 0;
  bool initialized = false;
  bool ready = true;
  bool throwOnListen = false;
  Duration? configuredFinalTimeout;
  stt.SpeechListenOptions? options;
  stt.SpeechStatusListener? statusCallback;
  stt.SpeechErrorListener? errorCallback;
  final callbacks = <stt.SpeechResultListener>[];
  List<stt.LocaleName> supportedLocales = [
    stt.LocaleName('en_US', 'English'),
    stt.LocaleName('de_AT', 'Deutsch (Österreich)'),
    stt.LocaleName('de_DE', 'Deutsch (Deutschland)'),
  ];
  Completer<void>? blockCancel;

  @override
  Future<bool> initialize({
    stt.SpeechErrorListener? onError,
    stt.SpeechStatusListener? onStatus,
    dynamic debugLogging = false,
    Duration finalTimeout = stt.SpeechToText.defaultFinalTimeout,
    List<stt.SpeechConfigOption>? options,
  }) async {
    if (initialized) return ready;
    initializes++;
    statusCallback = onStatus;
    errorCallback = onError;
    configuredFinalTimeout = finalTimeout;
    initialized = ready;
    return ready;
  }

  @override
  Future<List<stt.LocaleName>> locales() async => supportedLocales;

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
    if (throwOnListen) throw StateError('native recognizer unavailable');
    listens++;
    options = listenOptions;
    if (onResult != null) callbacks.add(onResult);
  }

  @override
  Future<void> cancel() async {
    cancels++;
    await blockCancel?.future;
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  void status(String status) => statusCallback?.call(status);

  void failure(String message) =>
      errorCallback?.call(SpeechRecognitionError(message, true));

  void words(
    String text, {
    bool finalResult = false,
    double confidence = .92,
    List<String> alternatives = const [],
    int? capture,
  }) {
    final result = SpeechRecognitionResult.init([
      SpeechRecognitionWords(text, null, confidence),
      for (final other in alternatives) SpeechRecognitionWords(other, null, .4),
    ], finalResult ? ResultType.finalResult : ResultType.partial);
    callbacks[capture ?? callbacks.length - 1](result);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _SpeechEngine engine;
  late LumoSpeechRecognizer recognizer;
  late LumoSpeechListener listener;

  setUp(() {
    engine = _SpeechEngine();
    recognizer = LumoSpeechRecognizer.withEngine(engine);
    listener = LumoSpeechListener(
      isAndroid: false,
      recognizer: recognizer,
      stopPlayback: () async {},
    );
  });
  tearDown(() => listener.dispose());

  test('standard German, local-only and device finals are requested', () async {
    await listener.startListening();
    expect(engine.options?.localeId, 'de_DE');
    expect(engine.options?.onDevice, true);
    expect(engine.configuredFinalTimeout, Duration.zero);
    expect(listener.starting, true);
    expect(listener.listening, false);
    engine.status('listening');
    expect(listener.listening, true);
    expect(listener.starting, false);
    expect(listener.supportsAcousticBargeIn, false);
  });

  testWidgets('unconfirmed native startup ends with a text fallback',
      (tester) async {
    await listener.startListening();
    expect(listener.starting, true);
    expect(listener.listening, false);
    await tester.pump(const Duration(seconds: 5));
    expect(listener.starting, false);
    expect(listener.listening, false);
    expect(listener.errorKind, LumoSpeechErrorKind.unavailable);
    expect(listener.error, contains('Start nicht bestätigt'));
  });

  testWidgets('partial and status events never become a final answer', (
    tester,
  ) async {
    final finals = <String>[];
    var noMatches = 0;
    await listener.startListening(
      onFinalResult: finals.add,
      onNoMatch: () => noMatches++,
    );
    engine.status('listening');
    engine.words('Ich meinte drei');
    engine.status('notListening');
    engine.status('done');
    expect(finals, isEmpty);
    expect(listener.awaitingFinalResult, true);
    expect(listener.lastRecognition?.isFinal, false);
    await tester.pump(const Duration(seconds: 3));
    expect(finals, isEmpty);
    expect(noMatches, 1);
    expect(listener.lastWords, 'Ich meinte drei');
    expect(listener.errorKind, LumoSpeechErrorKind.noMatch);
    expect(listener.awaitingFinalResult, false);
    engine.failure('error_no_match');
    engine.words('dreizehn', finalResult: true);
    expect(noMatches, 1);
    expect(finals, isEmpty);
  });

  test(
    'real final can replace a partial after microphone has stopped',
    () async {
      final finals = <String>[];
      await listener.startListening(onFinalResult: finals.add);
      engine.status('listening');
      engine.words('drei');
      final captureId = listener.lastRecognition!.captureId;
      engine.status('notListening');
      engine.words('dreizehn', finalResult: true, alternatives: ['drei zehn']);
      expect(finals, ['dreizehn']);
      expect(listener.lastRecognition!.captureId, captureId);
      expect(listener.lastRecognition!.isFinal, true);
      expect(listener.lastRecognition!.confidence, .92);
      expect(listener.lastRecognition!.alternatives, ['dreizehn', 'drei zehn']);
      expect(listener.awaitingFinalResult, false);
      engine.words('dreizehn', finalResult: true);
      expect(finals, ['dreizehn']);
    },
  );

  test(
    'unknown or low confidence is exposed without inventing certainty',
    () async {
      await listener.startListening();
      engine.words('vierzehn', finalResult: true, confidence: -1);
      expect(listener.lastRecognition!.confidence, isNull);
      expect(listener.lastRecognition!.needsConfirmation, true);
      final firstId = listener.lastRecognition!.captureId;
      await listener.startListening();
      engine.words('dreizehn', finalResult: true, confidence: .42);
      expect(listener.lastRecognition!.captureId, greaterThan(firstId));
      expect(listener.lastRecognition!.needsConfirmation, true);
      expect(listener.error, isNull);
    },
  );

  test(
    'manual stop waits for a native final without submitting partial text',
    () async {
      final finals = <String>[];
      await listener.startListening(onFinalResult: finals.add);
      engine.status('listening');
      engine.words('ich meinte');
      await listener.stopListening();
      expect(engine.stops, 1);
      expect(finals, isEmpty);
      expect(listener.awaitingFinalResult, true);
      engine.words('ich meinte dreizehn', finalResult: true);
      expect(finals, ['ich meinte dreizehn']);
    },
  );

  test(
    'cancel fences late results and keeps the next capture independent',
    () async {
      final finals = <String>[];
      await listener.startListening(onFinalResult: finals.add);
      engine.status('listening');
      engine.words('alte Aufgabe');
      await listener.cancel();
      engine.words('alte Aufgabe', finalResult: true, capture: 0);
      expect(listener.lastWords, isEmpty);
      expect(listener.lastRecognition, isNull);
      await listener.startListening(onFinalResult: finals.add);
      engine.words('alter Nachlauf', finalResult: true, capture: 0);
      engine.words('neue Aufgabe', finalResult: true, capture: 1);
      expect(finals, ['neue Aufgabe']);
    },
  );

  test(
    'one initialization transfers callbacks to the current screen owner',
    () async {
      final oldFinals = <String>[];
      final newFinals = <String>[];
      await listener.startListening(onFinalResult: oldFinals.add);
      engine.status('listening');
      final second = LumoSpeechListener(
        isAndroid: false,
        recognizer: recognizer,
        stopPlayback: () async {},
      );
      addTearDown(second.dispose);
      await second.startListening(onFinalResult: newFinals.add);
      expect(engine.initializes, 1);
      expect(listener.listening, false);
      expect(listener.errorKind, LumoSpeechErrorKind.interrupted);
      engine.status('listening');
      expect(second.listening, true);
      final priorCancels = engine.cancels;
      await listener.cancel();
      expect(engine.cancels, priorCancels);
      engine.words(
        'Nachlauf im alten Bildschirm',
        finalResult: true,
        capture: 0,
      );
      engine.words('Warum zuerst zwei?', finalResult: true, capture: 1);
      expect(oldFinals, isEmpty);
      expect(newFinals, ['Warum zuerst zwei?']);
    },
  );

  test(
    'disposing an old screen does not stop the current microphone',
    () async {
      final old = LumoSpeechListener(
        isAndroid: false,
        recognizer: recognizer,
        stopPlayback: () async {},
      );
      await old.startListening();
      await listener.startListening();
      engine.status('listening');
      final before = engine.cancels;
      old.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(listener.listening, true);
      expect(engine.cancels, before);
      engine.failure('error_permission');
      expect(listener.listening, false);
      expect(listener.errorKind, LumoSpeechErrorKind.permissionDenied);
      expect(listener.error, contains('Du kannst tippen'));
    },
  );

  test('cancel during output shutdown prevents microphone startup', () async {
    final outputStopped = Completer<void>();
    final waiting = LumoSpeechListener(
      isAndroid: false,
      recognizer: recognizer,
      stopPlayback: () => outputStopped.future,
    );
    addTearDown(waiting.dispose);
    final pending = waiting.startListening();
    expect(waiting.starting, true);
    await waiting.cancel();
    outputStopped.complete();
    await pending;
    expect(engine.initializes, 0);
    expect(engine.listens, 0);
    expect(waiting.listening, false);
  });

  test(
    'superseding a pending native cancellation starts only the newest turn',
    () async {
      engine.blockCancel = Completer<void>();
      final first = listener.startListening();
      await Future<void>.delayed(Duration.zero);
      final second = listener.startListening();
      engine.blockCancel!.complete();
      await Future.wait([first, second]);
      expect(engine.listens, 1);
      expect(listener.starting, true);
    },
  );

  test(
    'noise is not a learning answer and no-match is delivered once',
    () async {
      final finals = <String>[];
      var noMatches = 0;
      await listener.startListening(
        onFinalResult: finals.add,
        onNoMatch: () => noMatches++,
      );
      engine.status('listening');
      engine.words('unvollständig');
      engine.failure('error_speech_timeout');
      engine.failure('error_no_match');
      expect(finals, isEmpty);
      expect(noMatches, 1);
      expect(listener.lastRecognition?.isFinal, false);
      expect(listener.errorKind, LumoSpeechErrorKind.noMatch);
    },
  );

  test('no German locale never silently chooses English', () async {
    engine.supportedLocales = [stt.LocaleName('en_US', 'English')];
    await listener.startListening();
    expect(engine.listens, 0);
    expect(listener.available, false);
    expect(listener.bestLocaleId, isNull);
    expect(listener.errorKind, LumoSpeechErrorKind.languageUnavailable);
    // An explicit later attempt can recover after a language becomes ready.
    engine.supportedLocales = [stt.LocaleName('de_DE', 'Deutsch')];
    await listener.startListening();
    expect(engine.listens, 1);
    expect(listener.available, true);
  });

  test(
    'listed German locale does not mask a missing offline language model',
    () async {
      final finals = <String>[];
      await listener.startListening(onFinalResult: finals.add);
      engine.failure('error_language_unavailable');
      expect(listener.available, false);
      expect(listener.errorKind, LumoSpeechErrorKind.languageUnavailable);
      expect(listener.error, contains('keine Cloud-Aufnahme'));
      expect(finals, isEmpty);
    },
  );

  test(
    'native startup exception becomes a recoverable text fallback',
    () async {
      engine.throwOnListen = true;
      await listener.startListening();
      expect(listener.starting, false);
      expect(listener.listening, false);
      expect(listener.errorKind, LumoSpeechErrorKind.unavailable);
      expect(listener.error, isNot(contains('StateError')));
      engine.throwOnListen = false;
      await listener.startListening();
      expect(engine.listens, 1);
    },
  );
}
