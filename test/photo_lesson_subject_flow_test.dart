import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/photo_lesson/lumo_photo_lesson_screen.dart';
import 'package:lumo_lernen/widgets/scan_screen.dart';

// This file only imports existing public entry points, so it can run unchanged
// against the baseline to prove the wrong-subject defect before production edits.
void main() {
  const recognizer = MethodChannel('google_mlkit_text_recognizer');
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'lumo_app_settings_v1': jsonEncode(const AppSettings(
        scannerEnabled: true, microphoneEnabled: false, voiceEnabled: false,
      ).toJson()),
    });
    LumoVoice.instance.isEnabled = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(recognizer, (_) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(recognizer, null);
    LumoVoice.instance.isEnabled = true;
  });

  for (final entry in <String, List<String>>{
    'Deutsch': ['Hausaufgabe: Silben klatschen.', 'Wie viele Silben hat'],
    'Englisch': ['English: colour red blue green yellow.', 'Was bedeutet „'],
    'Sachunterricht': ['Sachunterricht: Tiere Hund Katze Fisch.', 'Welches Tier'],
  }.entries) {
    testWidgets('photo lesson displays actual ${entry.key} exercises after OCR callback', (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final state = LumoAppState();
      await state.ensureSettingsLoaded();
      final starsBefore = state.state.stars;
      final xpBefore = state.state.xp;
      await tester.pumpWidget(MaterialApp(home: LumoPhotoLessonScreen(appState: state)));
      await tester.pump();
      await tester.tap(find.text('Foto aufnehmen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.byType(ScanScreen), findsOneWidget);
      // Deliver the same public callback that receives completed local OCR.
      tester.widget<ScanScreen>(find.byType(ScanScreen)).onTextDetected(entry.value[0]);
      await tester.pump();
      expect(find.byType(ScanScreen), findsNothing);
      expect(find.text(entry.key), findsOneWidget);
      expect(find.textContaining(entry.value[1]), findsNWidgets(5),
          reason: 'Photo lesson must keep recognized subject ${entry.key} and topic.');
      expect(find.text('5 Übungen zum Trainieren'), findsOneWidget);
      await tester.tap(find.text('Antwort zeigen').first);
      await tester.pump();
      expect(find.textContaining('Antwort: '), findsOneWidget);
      expect(state.state.stars, starsBefore);
      expect(state.state.xp, xpBefore);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      state.dispose();
      expect(tester.takeException(), isNull);
    });
  }
}
