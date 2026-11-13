import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/lumo3d/lumo3d_launcher.dart';

class _VillageState extends LumoAppState {
  @override
  Future<void> flushRewards() async {}

  @override
  Future<void> ensureSettingsLoaded() async {}

  @override
  bool get canPlayToday => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('lumo_lernen/bridge');

  testWidgets('village narration carries the existing local voice choice',
      (tester) async {
    final calls = <MethodCall>[];
    SharedPreferences.setMockInitialValues(
        {'lumo_3d_save_salt_v1': 'village-voice-test'});
    final state = _VillageState();
    addTearDown(state.dispose);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return <String, Object?>{'destination': 'games'};
    });
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      late BuildContext launchContext;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Builder(builder: (context) {
          launchContext = context;
          return const Text('Bauwelt');
        })),
      ));
      for (final choice in [
        (true, true, LumoVoiceIdentity.freeOffline, false, true),
        (false, true, LumoVoiceIdentity.freeOffline, false, false),
        (true, false, LumoVoiceIdentity.freeOffline, false, false),
        (true, true, LumoVoiceIdentity.sulafatOriginal, false, false),
        (true, true, LumoVoiceIdentity.freeOffline, true, true),
      ]) {
        state.state.settings = AppSettings(
          voiceEnabled: choice.$1,
          localVoiceLicenseAccepted: choice.$2,
          autoReadEnabled: true,
          calmMode: choice.$4,
          voiceRate: 0.35,
        );
        await LumoVoice.instance.configure(identity: choice.$3);
        final launched =
            launchLumo3D(launchContext, scene: 'build', appState: state);
        for (var frame = 0; frame < 20; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        }
        expect(await launched, isTrue);
        final options = calls.last.arguments as Map;
        expect(options['scene'], 'build');
        expect(options['learningVoiceEnabled'], choice.$5);
        expect(options['localVoiceLicenseAccepted'], choice.$2);
        expect(options['learningAutoRead'], !choice.$4);
        expect(options['learningVoiceRate'], 1.0);
        expect(options.containsKey('learning'), isFalse,
            reason:
                'The village keeps its game route and creates no scored lesson.');
        expect(options['childKey'], startsWith('p_'));
      }
    } finally {
      debugDefaultTargetPlatformOverride = null;
      await LumoVoice.instance
          .configure(identity: LumoVoiceIdentity.freeOffline);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    }
  });
}
