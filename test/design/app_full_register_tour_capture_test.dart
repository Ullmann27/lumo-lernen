// Vollständiger visueller Register-Audit (kein Konzeptbild): rendert die
// vollständige AppShell mit Profil auf Telefon- und Fold-Größe.
// Läuft nur mit LUMO_FULL_REGISTER_TOUR_DIR=<ordner>, sonst übersprungen.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_shell.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/core/user_profile.dart';

final String? _out = Platform.environment['LUMO_FULL_REGISTER_TOUR_DIR'];
const _boundary = ValueKey('lumo-app-tour');

// Pure Flutter widget tests do not register audioplayers' Android plugin.
// AppShell deliberately keeps real tap sounds enabled. Its first AudioPlayer
// subscribes to the global EventChannel, whose asynchronous `listen` error
// escapes the existing Future try/catch and fails the *next* captured screen.
// Stub only the native transport for this test library, not app audio logic.
const _nativeAudioGlobal = MethodChannel('xyz.luan/audioplayers.global');
const _nativeAudioEvents =
    MethodChannel('xyz.luan/audioplayers.global/events');
final _audioCalls = <String>[];

void _installCaptureAudioTransport() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(_nativeAudioGlobal, (call) async {
    _audioCalls.add('global:${call.method}');
    if (call.method == 'init' ||
        call.method == 'setGlobalAudioContext') {
      return null;
    }
    throw MissingPluginException('Unexpected audioplayers global call: ${call.method}');
  });
  messenger.setMockMethodCallHandler(_nativeAudioEvents, (call) async {
    _audioCalls.add('events:${call.method}');
    if (call.method == 'listen' || call.method == 'cancel') {
      return null;
    }
    throw MissingPluginException('Unexpected audioplayers events call: ${call.method}');
  });
}

void _removeCaptureAudioTransport() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(_nativeAudioGlobal, null);
  messenger.setMockMethodCallHandler(_nativeAudioEvents, null);
}

const sizes = <String, Size>{
  'phone': Size(412, 915),
  'fold': Size(690, 829),
  'reference-phone': Size(360, 800),
};
// Capture every registered section, not only the six previous highlights.
final sections = LumoSection.values;
const academicSections = <LumoSection>{
  LumoSection.learn,
  LumoSection.exercises,
  LumoSection.reading,
  LumoSection.tests,
  LumoSection.schoolwork,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    _installCaptureAudioTransport();
    final font = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf'));
    await font.load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });

  tearDownAll(_removeCaptureAudioTransport);

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'lumo_app_settings_v1': jsonEncode(const AppSettings(
        voiceEnabled: false,
        autoReadEnabled: false,
        microphoneEnabled: false,
        aiProxyEnabled: false,
        reduceAnimations: true,
      ).toJson()),
    });
    LumoVoice.instance.isEnabled = false;
    await RewardWalletRepository.instance.reset();
  });

  Future<void> capture(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      await Future.wait(tester
          .widgetList<Image>(find.byType(Image))
          .map((image) => precacheImage(
              image.image, tester.element(find.byWidget(image)))
              .catchError((_) {})));
    });
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    final render =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary));
    await tester.runAsync(() async {
      final image = await render.toImage(
        pixelRatio:
            double.parse(Platform.environment['LUMO_TOUR_CAPTURE_SCALE'] ?? '2'),
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$_out/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  test('Capture audio transport accepts native global init and event lifecycle',
      () async {
    _audioCalls.clear();
    await _nativeAudioGlobal.invokeMethod<void>('init');
    const events = EventChannel('xyz.luan/audioplayers.global/events');
    final subscription = events.receiveBroadcastStream().listen((_) {});
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();
    expect(_audioCalls, containsAllInOrder([
      'global:init',
      'events:listen',
      'events:cancel',
    ]));
  });

  for (final size in sizes.entries) {
    for (final section in sections) {
      // Full register coverage for grade 2, plus every actual academic
      // screen at grades 1, 3 and 4. Never fake profiles or rewards.
      final grades = academicSections.contains(section)
          ? const <int>[1, 2, 3, 4]
          : const <int>[2];
      for (final grade in grades) {
        testWidgets('Tour ${size.key} ${section.name} grade $grade',
            (tester) async {
          await tester.binding.setSurfaceSize(size.value);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final date = DateTime(2026, 10, 8);
          await tester.pumpWidget(MaterialApp(
            theme: LumoAppTheme.light(),
            home: RepaintBoundary(
              key: _boundary,
              child: AppShell(
                profile: UserProfile(
                  id: 'tour-grade-$grade',
                  name: 'Mia',
                  age: 5 + grade,
                  grade: grade,
                  createdAt: date,
                  lastActiveAt: date,
                ),
                initialSection: section,
              ),
            ),
          ));
          for (var i = 0; i < 6; i++) {
            await tester.pump(const Duration(milliseconds: 200));
          }
          expect(find.byType(Scaffold), findsWidgets,
              reason: 'Section ${section.name} has no visible app scaffold');
          await capture(tester,
              '${size.key}_klasse${grade}_${section.name}');
          expect(tester.takeException(), isNull,
              reason: 'Screen ${section.name}, grade $grade, ${size.key}');
          await tester.pumpWidget(const SizedBox());
        }, skip: _out == null);
      }
    }
  }
}
