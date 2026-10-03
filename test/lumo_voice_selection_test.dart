import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/settings/widgets/lumo_voice_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, String> _raw(
  String name,
  String locale, {
  String quality = 'normal',
  bool network = false,
  String features = '',
}) =>
    <String, String>{
      'name': name,
      'locale': locale,
      'quality': quality,
      'latency': 'normal',
      'network_required': network ? '1' : '0',
      'features': features,
    };

void main() {
  group('LumoVoiceOption.fromRaw', () {
    test('liest Androids Stimmfelder', () {
      final v = LumoVoiceOption.fromRaw(_raw('de-at-x-test-local', 'de-AT', quality: 'very high'))!;
      expect(v.name, 'de-at-x-test-local');
      expect(v.locale, 'de-AT');
      expect(v.quality, 'very high');
      expect(v.networkRequired, isFalse);
      expect(v.installed, isTrue);
      expect(v.isGerman, isTrue);
      expect(v.regionLabel, 'Österreich');
      expect(v.qualityLabel, 'sehr gute Qualität');
    });

    test('erkennt nicht heruntergeladene Stimmen', () {
      final v = LumoVoiceOption.fromRaw(_raw('de-de-x-a-network', 'de-DE', features: 'networkTimeoutMs\tnotInstalled'))!;
      expect(v.installed, isFalse);
    });

    test('ignoriert kaputte Eintraege', () {
      expect(LumoVoiceOption.fromRaw(null), isNull);
      expect(LumoVoiceOption.fromRaw('de-DE'), isNull);
      expect(LumoVoiceOption.fromRaw(<String, String>{'locale': 'de-DE'}), isNull);
    });
  });

  group('LumoVoice.rankGermanVoices', () {
    test('nur deutsche, installierte Stimmen, beste Qualitaet zuerst', () {
      final ranked = LumoVoice.rankGermanVoices(<Object?>[
        _raw('en-us-x-sfg-local', 'en-US', quality: 'very high'),
        _raw('de-de-pico', 'de-DE', quality: 'normal'),
        _raw('de-de-x-good-local', 'de-DE', quality: 'very high'),
        _raw('de-de-x-missing-local', 'de-DE', quality: 'very high', features: 'notInstalled'),
        _raw('de-de-x-ok-local', 'de-DE', quality: 'high'),
        'kaputt',
      ]);
      expect(ranked.map((v) => v.name).toList(), <String>[
        'de-de-x-good-local',
        'de-de-x-ok-local',
        'de-de-pico',
      ]);
    });

    test('robotische Engines landen hinter normalen Stimmen', () {
      final pico = LumoVoice.scoreVoice(const LumoVoiceOption(name: 'pico-de', locale: 'de-DE', quality: 'normal'));
      final normal = LumoVoice.scoreVoice(const LumoVoiceOption(name: 'de-de-x-abc-local', locale: 'de-DE', quality: 'normal'));
      expect(pico, lessThan(normal));
    });

    test('bei gleicher Qualitaet gewinnt die Offline-Stimme', () {
      final local = LumoVoice.scoreVoice(const LumoVoiceOption(name: 'de-de-x-abc-local', locale: 'de-DE', quality: 'high'));
      final network = LumoVoice.scoreVoice(
        const LumoVoiceOption(name: 'de-de-x-abc-network', locale: 'de-DE', quality: 'high', networkRequired: true),
      );
      expect(local, greaterThan(network));
    });

    test('doppelte Stimmen werden nur einmal gelistet', () {
      final ranked = LumoVoice.rankGermanVoices(<Object?>[
        _raw('de-de-x-a-local', 'de-DE'),
        _raw('de-de-x-a-local', 'de-DE'),
      ]);
      expect(ranked, hasLength(1));
    });

    test('keine Liste von der Plattform ergibt leere Auswahl', () {
      expect(LumoVoice.rankGermanVoices(null), isEmpty);
    });
  });

  group('LumoVoice gespeicherte Wahl', () {
    const channel = MethodChannel('flutter_tts');
    var setVoiceResult = 1;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      setVoiceResult = 1;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'setVoice') return setVoiceResult;
        if (call.method == 'getVoices') return <Object?>[];
        return 1;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    });

    test('chooseVoice merkt sich die Stimme und null setzt zurueck', () async {
      const option = LumoVoiceOption(name: 'de-at-x-test-local', locale: 'de-AT');
      expect(await LumoVoice.instance.chooseVoice(option), isTrue);
      expect(await LumoVoice.instance.savedVoiceName(), 'de-at-x-test-local');
      expect(LumoVoice.instance.selectedVoiceName, 'de-at-x-test-local');

      await LumoVoice.instance.chooseVoice(null);
      expect(await LumoVoice.instance.savedVoiceName(), isNull);
    });

    test('Stimme, die Android ablehnt, wird nicht gespeichert', () async {
      setVoiceResult = 0;
      const option = LumoVoiceOption(name: 'de-de-x-gone-local', locale: 'de-DE');
      expect(await LumoVoice.instance.chooseVoice(option), isFalse);
      expect(await LumoVoice.instance.savedVoiceName(), isNull);
    });
  });

  group('LumoVoicePicker', () {
    const voices = <LumoVoiceOption>[
      LumoVoiceOption(name: 'de-at-x-best-local', locale: 'de-AT', quality: 'very high'),
      LumoVoiceOption(name: 'de-de-x-net-network', locale: 'de-DE', quality: 'high', networkRequired: true),
    ];

    Future<void> pumpPicker(
      WidgetTester tester, {
      List<LumoVoiceOption> list = voices,
      String? saved,
      bool enabled = true,
      String? rejectedName,
      required List<LumoVoiceOption?> chosen,
    }) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LumoVoicePicker(
              enabled: enabled,
              loadVoices: () async => list,
              loadSavedVoiceName: () async => saved,
              onChoose: (option) async {
                chosen.add(option);
                return option?.name != rejectedName;
              },
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('zeigt Automatisch und jede Stimme mit Beschreibung', (tester) async {
      await pumpPicker(tester, chosen: <LumoVoiceOption?>[]);
      expect(find.text('Automatisch'), findsOneWidget);
      expect(find.text('Stimme 1'), findsOneWidget);
      expect(find.text('Stimme 2'), findsOneWidget);
      expect(find.text('Österreich · sehr gute Qualität'), findsOneWidget);
      expect(find.text('Deutschland · gute Qualität · braucht Internet'), findsOneWidget);
    });

    testWidgets('Tippen waehlt die Stimme aus', (tester) async {
      final chosen = <LumoVoiceOption?>[];
      await pumpPicker(tester, chosen: chosen);
      await tester.tap(find.text('Stimme 2'));
      await tester.pumpAndSettle();
      expect(chosen, <LumoVoiceOption?>[voices[1]]);

      await tester.tap(find.text('Automatisch'));
      await tester.pumpAndSettle();
      expect(chosen.last, isNull);
    });

    testWidgets('gespeicherte Stimme ist markiert', (tester) async {
      await pumpPicker(tester, saved: 'de-de-x-net-network', chosen: <LumoVoiceOption?>[]);
      final tile = find.ancestor(of: find.text('Stimme 2'), matching: find.byType(Row)).first;
      expect(find.descendant(of: tile, matching: find.byIcon(Icons.check_circle_rounded)), findsOneWidget);
    });

    testWidgets('abgelehnte Stimme bleibt nicht markiert', (tester) async {
      final chosen = <LumoVoiceOption?>[];
      await pumpPicker(tester, saved: 'de-at-x-best-local', rejectedName: 'de-de-x-net-network', chosen: chosen);
      await tester.tap(find.text('Stimme 2'));
      await tester.pumpAndSettle();
      expect(chosen, <LumoVoiceOption?>[voices[1]]);
      Finder tileOf(String title) => find.ancestor(of: find.text(title), matching: find.byType(Row)).first;
      expect(find.descendant(of: tileOf('Stimme 1'), matching: find.byIcon(Icons.check_circle_rounded)), findsOneWidget);
      expect(find.descendant(of: tileOf('Stimme 2'), matching: find.byIcon(Icons.check_circle_rounded)), findsNothing);
      expect(find.text('Diese Stimme kann das Gerät gerade nicht verwenden.'), findsOneWidget);
    });

    testWidgets('ohne Lumo-Stimme nicht tippbar', (tester) async {
      final chosen = <LumoVoiceOption?>[];
      await pumpPicker(tester, enabled: false, chosen: chosen);
      await tester.tap(find.text('Stimme 1'));
      await tester.pumpAndSettle();
      expect(chosen, isEmpty);
    });

    testWidgets('Hinweis wenn keine deutsche Stimme installiert ist', (tester) async {
      await pumpPicker(tester, list: const <LumoVoiceOption>[], chosen: <LumoVoiceOption?>[]);
      expect(find.text('Auf diesem Gerät wurden keine deutschen Stimmen gefunden.'), findsOneWidget);
      expect(find.text('Automatisch'), findsOneWidget);
    });
  });
}
