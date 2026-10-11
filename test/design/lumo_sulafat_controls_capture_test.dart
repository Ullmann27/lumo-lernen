import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/lumo_voice_clips.dart';
import 'package:lumo_lernen/core/settings_repository.dart';
import 'package:lumo_lernen/features/settings/settings_content.dart';
import 'package:lumo_lernen/widgets/lumo_speech_controls.dart';

import '../helpers/lumo_native_audio_harness.dart';
import 'parent_games_polish_test.dart' as capture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final harness = LumoNativeAudioHarness();
  setUpAll(() async {
    harness.install();
    final font = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    LumoVoiceClips.debugSetCatalog(null);
    await LumoVoiceClips.ensureLoaded();
    // Global/native initialization belongs to the real event loop. Keep it
    // out of a widget's fake animation clock; UI still starts its own clip.
    final voice = LumoVoice.instance;
    voice.clipsEnabled = true;
    await voice.configure(enabled: true, cloudVoiceEnabled: false, rate: .35);
    await voice.test();
    await voice.stop();
  });
  tearDown(() async => LumoVoice.instance.stop());

  for (final (name, size) in [
    ('phone-360x800', const Size(360, 800)),
    ('fold-2176x1812-density-225', const Size(2176 / 2.25, 1812 / 2.25)),
    ('tablet-1024x768', const Size(1024, 768)),
  ]) {
    testWidgets('real parent Sulafat controls on $name', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final app = await capture.stateFor(tester, size: size);
      app.updateSettings(app.state.settings.copyWith(voiceEnabled: true));
      await SettingsRepository.save(app.state.settings);
      await tester.runAsync(() => LumoVoice.instance
          .configure(enabled: true, cloudVoiceEnabled: false, rate: .35));
      await capture.mount(tester, SettingsContent(appState: app));
      final voiceTestButton =
          find.widgetWithText(FilledButton, 'Stimme testen');
      await Scrollable.ensureVisible(tester.element(voiceTestButton),
          alignment: .15);
      await tester.pump();
      expect(app.state.settings.voiceEnabled, true);
      expect(
          tester
              .widget<FilledButton>(
                  find.widgetWithText(FilledButton, 'Stimme testen'))
              .onPressed,
          isNotNull);
      final startsBeforeTap = LumoVoice.instance.startedPlaybackCount;
      await tester.runAsync(() async {
        final speaking = _waitFor(VoiceStatus.speaking);
        await tester.tap(find.text('Stimme testen'));
        await speaking;
      });
      await tester.pump();
      expect(LumoVoice.instance.lastStartedAudioIdentity,
          'Originalaufnahme c3034465f7dd.m4a');
      expect(LumoVoice.instance.startedPlaybackCount, startsBeforeTap + 1,
          reason: 'The actual parent button must start this clip itself.');
      expect(find.text('Pause'), findsOneWidget);
      final testButtonRect = tester.getRect(voiceTestButton);
      final pauseRect =
          tester.getRect(find.widgetWithText(OutlinedButton, 'Pause'));
      for (final rect in [testButtonRect, pauseRect]) {
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
      }
      await capture.capture(tester, 'sulafat-playing-$name');

      final starts = LumoVoice.instance.startedPlaybackCount;
      await tester.runAsync(() async {
        final paused = _waitFor(VoiceStatus.paused);
        await tester.tap(find.text('Pause'));
        await paused;
      });
      await tester.pump();
      expect(find.text('Fortsetzen'), findsOneWidget);
      final resume =
          tester.getRect(find.widgetWithText(FilledButton, 'Fortsetzen'));
      expect(resume.height, greaterThanOrEqualTo(48));
      expect(resume.left, greaterThanOrEqualTo(0));
      expect(resume.top, greaterThanOrEqualTo(0));
      expect(resume.right, lessThanOrEqualTo(size.width));
      expect(resume.bottom, lessThanOrEqualTo(size.height));
      await capture.capture(tester, 'sulafat-paused-$name');

      await tester.runAsync(() async {
        final speaking = _waitFor(VoiceStatus.speaking);
        await tester.tap(find.text('Fortsetzen'));
        await speaking;
      });
      await tester.pump();
      expect(LumoVoice.instance.startedPlaybackCount, starts,
          reason: 'Continuation is not a new clip or a new provider request.');
      expect(app.state.settings.cloudVoiceEnabled, false);
      expect(app.state.childName, 'Probe');
      expect(harness.retiredTtsCalls, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.runAsync(() => LumoVoice.instance.stop());
      await tester.pumpWidget(const SizedBox());
    }, timeout: const Timeout(Duration(seconds: 40)));
  }

  testWidgets('missing speech stays understandable at 2x text on 320px',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() async {
      await LumoVoice.instance
          .configure(enabled: true, cloudVoiceEnabled: false);
      await LumoVoice.instance.stop();
    });
    await tester.pumpWidget(MaterialApp(
      builder: (_, child) => MediaQuery(
        data: const MediaQueryData(
            size: Size(320, 700), textScaler: TextScaler.linear(2)),
        child: child!,
      ),
      home: Scaffold(
        body: RepaintBoundary(
          key: capture.boundaryKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: LumoSpeechControls(
              onRead: () => unawaited(LumoVoice.instance.speak(
                  'Von sieben bis zehn fehlen drei. Danach bleiben zwei.')),
              showUnavailableNotice: true,
            ),
          ),
        ),
      ),
    ));
    await tester.runAsync(() async {
      final unavailable = _waitFor(VoiceStatus.error);
      await tester.tap(find.text('Vorlesen'));
      await unavailable;
    });
    await tester.pump();
    expect(find.textContaining('Eine passende Lumo-Aufnahme'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(LumoVoice.instance.cloudVoiceEnabled, false);
    expect(harness.retiredTtsCalls, isEmpty);
    await capture.capture(tester, 'sulafat-unavailable-320x700-text-200');
    await tester.pumpWidget(const SizedBox());
  }, timeout: const Timeout(Duration(seconds: 40)));
}

Future<void> _waitFor(VoiceStatus expected) async {
  final status = LumoVoice.instance.status;
  if (status.value == expected) return;
  final completed = Completer<void>();
  void changed() {
    if (status.value == expected && !completed.isCompleted) {
      completed.complete();
    }
  }

  status.addListener(changed);
  try {
    await completed.future.timeout(const Duration(seconds: 3));
  } finally {
    status.removeListener(changed);
  }
}
