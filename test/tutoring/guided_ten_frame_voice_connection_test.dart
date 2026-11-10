import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_offline_voice_client.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/lumo_voice_clips.dart';
import 'package:lumo_lernen/domain/tutoring/guided_lesson_catalog.dart';
import 'package:lumo_lernen/features/tutoring/guided_lesson_screen.dart';
import 'package:lumo_lernen/widgets/lumo_speech_controls.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 25; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final spoken = <String>[];
  final pending = <Completer<Map<String, Object?>>>[];
  var cancelled = 0;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    spoken.clear();
    pending.clear();
    cancelled = 0;
    messenger.setMockMethodCallHandler(LumoOfflineVoiceClient.channel,
        (call) async {
      if (call.method == 'cancel') cancelled++;
      if (call.method == 'synthesize') {
        spoken.add((call.arguments as Map)['text'] as String);
        final completion = Completer<Map<String, Object?>>();
        pending.add(completion);
        return completion.future;
      }
      return null;
    });
    LumoVoice.instance.clipsEnabled = false;
    // Do not retain an asset-loading Future from another FakeAsync test zone.
    LumoVoiceClips.debugSetFreeCatalog({});
  });
  tearDown(() async {
    await LumoVoice.instance.stop();
    await LumoVoice.instance
        .configure(enabled: false, localVoiceLicenseAccepted: false);
    LumoVoice.instance.clipsEnabled = true;
    LumoVoiceClips.debugSetFreeCatalog(null);
    messenger.setMockMethodCallHandler(LumoOfflineVoiceClient.channel, null);
  });

  for (final (name, voice, automatic, calm) in [
    ('automatic', true, true, false),
    ('manual', true, false, false),
    ('calm', true, true, true),
    ('muted', false, true, false),
  ]) {
    testWidgets(
        '$name: real lesson sends matching phases through local voice only',
        (tester) async {
      final app = LumoAppState();
      addTearDown(app.dispose);
      final lesson = GuidedLesson(
          id: 'ten-frame-voice-contract',
          title: 'Über den Zehner',
          description: '',
          grade: 1,
          schoolUnit: 'Plus bis 20',
          concept: GuidedLessonConcept.bridgeTen,
          steps: GuidedLessonCatalog.bridgeTen.steps.sublist(2, 4));
      await tester.runAsync(() async {
        await app.school.setActiveStudent('voice-contract-child');
        await app.loadLearningProfile();
        app.updateSettings(AppSettings(
            voiceEnabled: voice,
            autoReadEnabled: automatic,
            calmMode: calm,
            localVoiceLicenseAccepted: true));
        await LumoVoice.instance.configure(
            enabled: voice,
            identity: LumoVoiceIdentity.freeOffline,
            cloudVoiceEnabled: false,
            localVoiceLicenseAccepted: true);
      });
      await tester.pumpWidget(MaterialApp(
          home: GuidedLessonScreen(
              appState: app, lesson: lesson, discovery: false)));
      await _frames(tester);
      expect(find.byType(LumoSpeechControls), findsNothing,
          reason:
              'The old full paragraph must not be read alongside the phases.');
      final shouldAutomaticallySpeak = voice && automatic && !calm;
      if (shouldAutomaticallySpeak) {
        expect(spoken, ['8 Äpfel sind im Zehnerfeld. 5 kommen dazu.']);
        final cancelBeforePause = cancelled;
        await tester
            .ensureVisible(find.byKey(const ValueKey('ten-frame-play')));
        await tester.tap(find.byKey(const ValueKey('ten-frame-play')));
        await _frames(tester);
        expect(cancelled, greaterThan(cancelBeforePause));
        await tester.tap(find.byKey(const ValueKey('ten-frame-next')));
        await _frames(tester);
        expect(spoken.last, 'Im Zehnerfeld sind noch 2 Plätze frei.');
      } else {
        expect(spoken, isEmpty);
        final read = find.byKey(const ValueKey('ten-frame-read'));
        if (voice) {
          await tester.ensureVisible(read);
          await tester.pump();
          expect(LumoVoice.instance.isEnabled, isTrue);
          expect(LumoVoice.instance.localVoiceLicenseAccepted, isTrue);
          expect(read.hitTestable(), findsOneWidget);
          await tester.tap(read);
          await _frames(tester);
          expect(
              spoken.single,
              calm
                ? '8 + 2 + 3 ist gleich 13. Ein Zehner und 3 Einer.'
                  : '8 Äpfel sind im Zehnerfeld. 5 kommen dazu.');
        } else {
          expect(read, findsNothing);
        }
      }
      expect(spoken.any((text) => text.contains('Acht Äpfel sind schon da.')),
          isFalse);
      expect(LumoVoice.instance.cloudVoiceEnabled, isFalse);
      if (shouldAutomaticallySpeak) {
        final next = find.byKey(const ValueKey('guided-continue'));
        await tester.ensureVisible(next);
        await tester.tap(next);
        await _frames(tester);
        expect(spoken.last, lesson.steps.last.instruction);
        expect(LumoVoice.instance.status.value, VoiceStatus.preparing,
            reason:
                'Disposing the old animation must not cancel the next task voice.');
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await _frames(tester);
      for (final request in pending) {
        if (!request.isCompleted) request.complete({});
      }
      await _frames(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
