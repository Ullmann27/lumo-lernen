import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_learning_narration.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';

void main() {
  late _NarrationVoice voice;
  late LumoLearningNarration narration;

  setUp(() {
    voice = _NarrationVoice();
    narration = LumoLearningNarration(voice: voice);
  });

  tearDown(() {
    narration.dispose();
    voice.status.dispose();
  });

  test('read replaces an explanation and its late completion stays harmless',
      () async {
    final first = narration.read('Zuerst legen wir drei Steine hin.');
    await _flush();
    expect(voice.playbacks, hasLength(1));
    final oldAudio = voice.playbacks.single;
    final second = narration.read('Jetzt legen wir zwei Steine dazu.');
    await _flush();

    expect(oldAudio.stopped, isTrue);
    expect(voice.activeCount, 1);
    expect(narration.currentText, 'Jetzt legen wir zwei Steine dazu.');
    expect(voice.playbacks.last.style, VoiceStyle.explain);
    oldAudio.finished.complete();
    await first;
    expect(narration.isActive, isTrue,
        reason: 'The retired completion must not clear the new explanation.');

    voice.finishCurrent();
    await second;
    expect(narration.isActive, isFalse);
    expect(narration.isPaused, isFalse);
  });

  test('only the latest explicit read survives a slow native stop', () async {
    final gate = Completer<void>();
    voice.nextStop = gate;
    final first = narration.read('Diese alte Erklärung wird vorbereitet.');
    final second = narration.read('Diese neue Erklärung möchtest du hören.');
    await _flush();
    expect(voice.playbacks, hasLength(1));
    expect(
        voice.playbacks.single.text, 'Diese neue Erklärung möchtest du hören.');

    gate.complete();
    await first;
    expect(voice.playbacks, hasLength(1));
    expect(narration.isActive, isTrue);
    voice.finishCurrent();
    await second;
  });

  test('pause cancels preparation and repeat restarts the same explanation',
      () async {
    final gate = Completer<void>();
    voice.nextStop = gate;
    final first = narration.read('Drei plus zwei sind fünf.');
    expect(narration.isActive, isTrue);
    await narration.pause();
    gate.complete();
    await first;
    expect(voice.playbacks, isEmpty);
    expect(narration.isActive, isFalse);
    expect(narration.isPaused, isTrue);
    expect(narration.currentText, 'Drei plus zwei sind fünf.');

    final repeated = narration.repeat();
    await _flush();
    expect(voice.playbacks.single.text, 'Drei plus zwei sind fünf.');
    expect(narration.isPaused, isFalse);
    expect(narration.isActive, isTrue);
    voice.finishCurrent();
    await repeated;
  });

  test('pause stops audio and ignores its eventual completion', () async {
    final reading = narration.read('Zähle jeden Stein genau einmal.');
    await _flush();
    expect(voice.playbacks, hasLength(1));
    final audio = voice.playbacks.single;
    await narration.pause();
    expect(audio.stopped, isTrue);
    expect(narration.isPaused, isTrue);
    audio.finished.complete();
    await reading;
    expect(narration.isPaused, isTrue);
    expect(narration.isActive, isFalse);
  });

  for (final status in [
    VoiceStatus.preparing,
    VoiceStatus.speaking,
    VoiceStatus.paused,
  ]) {
    test('automatic feedback skips central $status audio without queuing',
        () async {
      voice.status.value = status;
      await narration.feedback('Das hast du gut erkannt!');
      voice.status.value = VoiceStatus.idle;
      await _flush();
      expect(voice.playbacks, isEmpty);
      expect(voice.stops, 0);
    });
  }

  test('automatic feedback skips a paused explanation', () async {
    final reading = narration.read('Drei Steine und zwei Steine sind fünf.');
    await _flush();
    await narration.pause();
    await narration.feedback('Super!');
    expect(voice.playbacks, hasLength(1));
    expect(narration.isPaused, isTrue);
    voice.playbacks.single.finished.complete();
    await reading;
  });

  test('idle feedback keeps the explanation available for repeat', () async {
    final reading = narration.read('Wir teilen sechs Steine in zwei Gruppen.');
    await _flush();
    expect(voice.playbacks, hasLength(1));
    voice.finishCurrent();
    await reading;
    final feedback = narration.feedback('Genau, in jeder Gruppe liegen drei.');
    await _flush();
    expect(voice.playbacks.last.text, 'Genau, in jeder Gruppe liegen drei.');
    expect(narration.currentText, 'Wir teilen sechs Steine in zwei Gruppen.');
    voice.finishCurrent();
    await feedback;
    final repeated = narration.repeat();
    await _flush();
    expect(
        voice.playbacks.last.text, 'Wir teilen sechs Steine in zwei Gruppen.');
    voice.finishCurrent();
    await repeated;
  });

  test('stop clears repeat and cancels pending preparation', () async {
    final gate = Completer<void>();
    voice.nextStop = gate;
    final reading = narration.read('Dieser alte Text darf nicht weiterlaufen.');
    expect(narration.isActive, isTrue);
    await narration.stop();
    gate.complete();
    await reading;
    await narration.repeat();
    expect(voice.playbacks, isEmpty);
    expect(narration.currentText, isNull);
    expect(narration.isActive, isFalse);
    expect(narration.isPaused, isFalse);
  });

  test('profile change cancels preparation instead of starting another voice',
      () async {
    final gate = Completer<void>();
    voice.nextStop = gate;
    final reading = narration.read('Diese Erklärung gehört zur alten Stimme.');
    expect(narration.isActive, isTrue);
    voice.identity = LumoVoiceIdentity.sulafatOriginal;
    gate.complete();
    await reading;
    expect(voice.playbacks, isEmpty);
    expect(narration.isActive, isFalse);
  });

  test('dispose cancels preparation and rejects every later request', () async {
    final gate = Completer<void>();
    voice.nextStop = gate;
    final reading = narration.read('Diese Seite ist schon geschlossen.');
    expect(narration.isActive, isTrue);
    narration.dispose();
    gate.complete();
    await reading;
    await narration.read('Nicht starten.');
    await narration.repeat();
    await narration.feedback('Auch nicht starten.');
    await narration.pause();
    await narration.stop();
    expect(voice.playbacks, isEmpty);
  });
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

/// Models delayed audio completion independently of stop acknowledgement.
/// This tests session ordering; native source routing has separate tests.
class _NarrationVoice implements LumoVoice {
  @override
  final status = ValueNotifier<VoiceStatus>(VoiceStatus.idle);
  @override
  LumoVoiceIdentity identity = LumoVoiceIdentity.freeOffline;
  final playbacks = <_Playback>[];
  Completer<void>? nextStop;
  int stops = 0;

  int get activeCount => playbacks
      .where((audio) => !audio.stopped && !audio.finished.isCompleted)
      .length;

  @override
  Future<void> stop() async {
    stops++;
    for (final audio in playbacks) {
      audio.stopped = true;
    }
    status.value = VoiceStatus.idle;
    final gate = nextStop;
    nextStop = null;
    if (gate != null) await gate.future;
  }

  @override
  Future<void> speakAndWait(String text,
      {VoiceStyle style = VoiceStyle.warm}) async {
    final audio = _Playback(text, style);
    playbacks.add(audio);
    status.value = VoiceStatus.speaking;
    await audio.finished.future;
  }

  void finishCurrent() {
    status.value = VoiceStatus.idle;
    playbacks.last.finished.complete();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Playback {
  _Playback(this.text, this.style);
  final String text;
  final VoiceStyle style;
  final finished = Completer<void>();
  bool stopped = false;
}
