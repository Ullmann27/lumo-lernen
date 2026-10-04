import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/live/lumo_live_pro_screen.dart';
import 'package:lumo_lernen/features/photo_lesson/lumo_photo_lesson_screen.dart';
import 'package:lumo_lernen/widgets/scan_screen.dart';

void main() {
  final sensorCalls = <MethodCall>[];
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'lumo_app_settings_v1': jsonEncode(const AppSettings(
              microphoneEnabled: false,
              scannerEnabled: false,
              voiceEnabled: false)
          .toJson()),
    });
    LumoVoice.instance.isEnabled = false;
    sensorCalls.clear();
    for (final channel in const [
      MethodChannel('plugin.csdcorp.com/speech_to_text'),
      MethodChannel('plugins.flutter.io/image_picker')
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        sensorCalls.add(call);
        return true;
      });
    }
  });
  tearDown(() {
    for (final channel in const [
      MethodChannel('plugin.csdcorp.com/speech_to_text'),
      MethodChannel('plugins.flutter.io/image_picker')
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    }
    LumoVoice.instance.isEnabled = true;
  });

  for (final pro in [true]) {
    testWidgets(
        'Live ${pro ? 'Pro' : ''} opens without initializing microphone; denied tap stays local',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final state = LumoAppState();
      await state.ensureSettingsLoaded();
      await tester.pumpWidget(MaterialApp(
          home: LumoLiveProScreen(appState: state)));
      await tester.pump(const Duration(seconds: 1));
      expect(sensorCalls.where((call) => call.method == 'initialize'), isEmpty);
      await tester.tap(find.text('Sprechen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('Das Mikrofon ist ausgeschaltet.'),
          findsOneWidget);
      expect(
          sensorCalls.where(
              (call) => call.method == 'initialize' || call.method == 'listen'),
          isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      state.dispose();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'Photo lesson checks saved camera consent before opening the scanner',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = LumoAppState();
    await state.ensureSettingsLoaded();
    await tester
        .pumpWidget(MaterialApp(home: LumoPhotoLessonScreen(appState: state)));
    await tester.pump();
    await tester.tap(find.text('Foto aufnehmen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(ScanScreen), findsNothing);
    expect(
        find.textContaining('Die Kamera ist ausgeschaltet.'), findsOneWidget);
    expect(sensorCalls.where((call) => call.method == 'pickImage'), isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
    expect(tester.takeException(), isNull);
  });
}
