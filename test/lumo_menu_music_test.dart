import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_shell.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_music.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/home/home_content.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _LocalAudioCache extends AudioCache {
  @override
  Future<Uri> load(String fileName) async => Uri.file('/tmp/$fileName');
}

class _TestArtwork extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.endsWith('.png') || key.endsWith('.webp')) {
      return ByteData.sublistView(base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGOwT1kPAAI4AVMV7Y4kAAAAAElFTkSuQmCC',
      ));
    }
    return rootBundle.load(key);
  }
}

Future<void> _frames(WidgetTester tester) async {
  for (var index = 0; index < 6; index++) {
    // The audio plugin holds its initialization future across widget tests.
    // Deliver native acknowledgements on the real event loop.
    await tester.runAsync(() => tester.pump(const Duration(milliseconds: 80)));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const playerId = 'lumo-menu-music';
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final music = LumoMusic.instance;
  final calls = <MethodCall>[];
  final voice = LumoVoice.instance.status;
  MockStreamHandlerEventSink? eventSink;
  Completer<void>? awaitingResume;

  Iterable<MethodCall> native(String method) =>
      calls.where((call) => call.method == method);
  Iterable<double> volumes() => native('setVolume').map(
        (call) => (call.arguments['volume'] as num).toDouble(),
      );

  setUpAll(() {
    AudioCache.instance = _LocalAudioCache();
    messenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers.global'), (_) async => null);
    messenger.setMockStreamHandler(
      const EventChannel('xyz.luan/audioplayers.global/events'),
      MockStreamHandler.inline(onListen: (_, __) {}),
    );
    messenger.setMockStreamHandler(
      const EventChannel('xyz.luan/audioplayers/events/$playerId'),
      MockStreamHandler.inline(onListen: (_, sink) {
        eventSink = sink;
      }),
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async {
        if (call.arguments['playerId'] != playerId) return null;
        calls.add(call);
        if (call.method == 'setSourceUrl') {
          eventSink?.success({'event': 'audio.onPrepared', 'value': true});
        }
        if (call.method == 'resume' && awaitingResume != null) {
          await awaitingResume!.future;
        }
        return null;
      },
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'lumo_app_settings_v1': jsonEncode(const AppSettings(
        voiceEnabled: false,
        autoReadEnabled: false,
        reduceAnimations: true,
      ).toJson()),
    });
    voice.value = VoiceStatus.idle;
    await music.dispose();
    await music.init();
    calls.clear();
    awaitingResume = null;
  });

  Future<void> showHome(WidgetTester tester,
      {GlobalKey<NavigatorState>? navigator,
      Size size = const Size(390, 840)}) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() => tester.pumpWidget(DefaultAssetBundle(
          bundle: _TestArtwork(),
          child: MaterialApp(
            navigatorKey: navigator,
            theme: LumoAppTheme.light(),
            home: AppShell(menuMusic: music),
          ),
        )));
    await _frames(tester);
  }

  LumoAppState appState(WidgetTester tester) =>
      tester.widget<HomeContent>(find.byType(HomeContent)).appState;

  test('stored mute and retired owners do not start or stop a newer menu',
      () async {
    await music.dispose();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lumo_music_muted', true);
    await music.init();
    final oldShell = Object();
    final newShell = Object();
    await music.setMenuActive(oldShell, true);
    expect(native('resume'), isEmpty);

    music.muted = false;
    await music.setMenuActive(newShell, true);
    expect(native('resume'), hasLength(1));
    await music.setMenuActive(oldShell, false);
    expect(native('stop'), isEmpty);
    await music.setMenuActive(newShell, false);
    expect(native('stop'), hasLength(1));
  });

  testWidgets('home plays one quiet local loop and ducks speech',
      (tester) async {
    await showHome(tester);
    expect(find.byType(HomeContent), findsOneWidget);
    expect(native('resume'), hasLength(1),
        reason: 'Calls: ${calls.map((call) => call.method).join(', ')}');
    expect(native('setSourceUrl').single.arguments['url'],
        contains('chill_loop.m4a'));
    expect(volumes().last, inInclusiveRange(0.08, 0.14));

    voice.value = VoiceStatus.preparing;
    await _frames(tester);
    expect(volumes().last, inInclusiveRange(0.0, 0.04));
    voice.value = VoiceStatus.speaking;
    await _frames(tester);
    expect(volumes().last, inInclusiveRange(0.0, 0.04));
    voice.value = VoiceStatus.idle;
    await _frames(tester);
    expect(volumes().last, inInclusiveRange(0.08, 0.14));
    expect(native('resume'), hasLength(1));

    await tester.pumpWidget(const SizedBox.shrink());
    await _frames(tester);
    expect(native('stop'), isNotEmpty);
  });

  testWidgets(
      'route, spoken conversation cover, quiet settings and lifecycle gate the loop',
      (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await showHome(tester, navigator: navigator);
    final app = appState(tester);
    expect(native('resume'), hasLength(1));

    unawaited(showModalBottomSheet<void>(
      context: navigator.currentState!.overlay!.context,
      builder: (_) => const Text('Spracheingabe'),
    ));
    await _frames(tester);
    expect(native('stop'), hasLength(1));
    navigator.currentState!.pop();
    await _frames(tester);
    expect(native('resume'), hasLength(2));

    app.updateSettings(app.state.settings.copyWith(calmMode: true));
    await _frames(tester);
    expect(native('stop'), hasLength(2));
    app.updateSettings(
        app.state.settings.copyWith(calmMode: false, soundEnabled: false));
    await _frames(tester);
    expect(native('resume'), hasLength(2));
    app.updateSettings(app.state.settings.copyWith(soundEnabled: true));
    await _frames(tester);
    expect(native('resume'), hasLength(3));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await _frames(tester);
    expect(native('stop'), hasLength(3));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _frames(tester);
    expect(native('resume'), hasLength(4));

    app.setSection(LumoSection.tests);
    await _frames(tester);
    expect(native('stop'), hasLength(4));
    await tester.pumpWidget(const SizedBox.shrink());
    await _frames(tester);
    expect(native('resume'), hasLength(4));
  });

  testWidgets('a native start still in flight stays silent after leaving home',
      (tester) async {
    awaitingResume = Completer<void>();
    await showHome(tester);
    expect(native('resume'), hasLength(1));
    expect(volumes().last, 0.0);

    appState(tester).setSection(LumoSection.tests);
    awaitingResume!.complete();
    await _frames(tester);
    expect(volumes(), everyElement(0.0));
    expect(native('stop'), isNotEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    await _frames(tester);
  });

  testWidgets(
      'Eltern schalten Menümusik separat aus und lesen sie nach Neustart zurück',
      (tester) async {
    const window = Size(900, 940);
    final toggle = find.widgetWithText(SwitchListTile, 'Menümusik');
    Future<void> tap(Finder finder) async {
      await tester.runAsync(() async {
        await tester.ensureVisible(finder);
        await tester.tap(finder);
      });
      await _frames(tester);
    }

    await showHome(tester, size: window);
    final app = appState(tester);
    expect(native('resume'), hasLength(1));
    await tap(find.text('Eltern'));
    expect(find.text('Ton und Stimme'), findsOneWidget);
    expect(toggle, findsOneWidget);
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    await tap(toggle);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('lumo_music_muted'), isTrue);
    expect(app.state.settings.soundEnabled, isTrue);
    await tap(find.text('Start'));
    expect(native('resume'), hasLength(1));

    await tester.pumpWidget(const SizedBox.shrink());
    await _frames(tester);
    await tester.runAsync(music.dispose);
    await showHome(tester, size: window);
    expect(native('resume'), hasLength(1));
    await tap(find.text('Eltern'));
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    await tap(toggle);
    expect(prefs.getBool('lumo_music_muted'), isFalse);
    await tap(find.text('Start'));
    expect(find.byType(HomeContent), findsOneWidget);
    await _frames(tester);
    expect(native('resume'), hasLength(2),
        reason: 'Calls: ${calls.map((call) => call.method).join(', ')}');
    expect(volumes().last, 0.12);

    await tester.pumpWidget(const SizedBox.shrink());
    await _frames(tester);
  });
}
