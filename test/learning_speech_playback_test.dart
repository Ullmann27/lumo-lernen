import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_learning_narration.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/lumo_voice_clips.dart';

import 'helpers/lumo_native_audio_harness.dart';

/// Actual catalog + central player, with mocked native audio events.
/// These assertions do not demonstrate audible Android playback.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final native = LumoNativeAudioHarness();
  final voice = LumoVoice.instance;
  late LumoLearningNarration narration;
  const explanation = '3 plus 4 - wie viel ist das?';

  setUpAll(() async {
    native.install();
    await LumoVoiceClips.ensureFreeLoaded();
  });

  setUp(() async {
    await voice.configure(
      identity: LumoVoiceIdentity.freeOffline,
      enabled: true,
      localVoiceLicenseAccepted: false,
      cloudVoiceEnabled: false,
      rate: .35,
    );
    await voice.stop();
    voice.clipsEnabled = true;
    native.calls.clear();
    native.retiredTtsCalls.clear();
    narration = LumoLearningNarration();
  });

  tearDown(() async {
    narration.dispose();
    await voice.stop();
  });

  test('explanation uses the shipped F2 clip and waits for native completion',
      () async {
    final clip = LumoVoiceClips.freeLookup(explanation)!;
    final completedBefore = voice.completedPlaybackCount;
    final reading = narration.read(explanation);
    await _waitFor(VoiceStatus.speaking);
    expect(narration.isActive, isTrue);
    expect(voice.lastStartedAudioIdentity,
        'Lumo Frei / F2 / lokale Aufnahme ${clip.id}.m4a');
    expect(voice.completedPlaybackCount, completedBefore);
    expect(native.retiredTtsCalls, isEmpty);
    native.nativePositionMs = clip.duration.inMilliseconds;
    native.complete();
    await reading;
    expect(voice.completedPlaybackCount, completedBefore + 1);
    expect(narration.isActive, isFalse);
    expect(voice.status.value, VoiceStatus.idle);
  });

  test('pause stops the central source and repeat starts that clip again',
      () async {
    final reading = narration.read(explanation);
    await _waitFor(VoiceStatus.speaking);
    final startsBefore = voice.startedPlaybackCount;
    final completionsBefore = voice.completedPlaybackCount;
    await narration.pause();
    await reading;
    expect(voice.status.value, VoiceStatus.idle);
    expect(narration.isPaused, isTrue);
    expect(voice.completedPlaybackCount, completionsBefore);

    final repeated = narration.repeat();
    await _waitFor(VoiceStatus.speaking);
    expect(voice.startedPlaybackCount, startsBefore + 1);
    expect(narration.isPaused, isFalse);
    native.complete();
    await repeated;
    expect(voice.completedPlaybackCount, completionsBefore + 1);
  });

  test('automatic feedback leaves audio from another page owner uninterrupted',
      () async {
    await voice.speak('Fast! Schau nochmal.');
    final startsBefore = voice.startedPlaybackCount;
    final stopsBefore = native.calls.where((c) => c.method == 'stop').length;
    await narration.feedback('Super!');
    expect(voice.startedPlaybackCount, startsBefore);
    expect(native.calls.where((c) => c.method == 'stop').length, stopsBefore);
    expect(voice.status.value, VoiceStatus.speaking);
  });

  test('changing the selected profile ends an explanation without a restart',
      () async {
    final reading = narration.read(explanation);
    await _waitFor(VoiceStatus.speaking);
    final startsBefore = voice.startedPlaybackCount;
    await voice.configure(identity: LumoVoiceIdentity.sulafatOriginal);
    await reading;
    expect(narration.isActive, isFalse);
    expect(voice.status.value, VoiceStatus.idle);
    expect(voice.startedPlaybackCount, startsBefore);
  });
}

Future<void> _waitFor(VoiceStatus expected) async {
  final status = LumoVoice.instance.status;
  if (status.value == expected) return;
  final ready = Completer<void>();
  void changed() {
    if (status.value == expected && !ready.isCompleted) ready.complete();
  }

  status.addListener(changed);
  try {
    await ready.future.timeout(const Duration(seconds: 5));
  } finally {
    status.removeListener(changed);
  }
}
