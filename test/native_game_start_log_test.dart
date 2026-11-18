import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/features/lumo3d/native_game_start_log_screen.dart';
import 'package:lumo_lernen/features/settings/native_game_saves_card.dart';
import 'package:lumo_lernen/app/app_state.dart';

import 'helpers/lumo_capture.dart';

const _diagnostics = MethodChannel('lumo_lernen/diagnostics');

final _start = DateTime(2026, 11, 18, 19, 4, 12).millisecondsSinceEpoch;

Map<String, Object?> _report() => {
      'device': {
        'Gerät': 'samsung SM-F966B (q7q)',
        'Android': '16 (API 36)',
        'App-Version': '0.13.38 (2050)',
        'Godot-Stand': 'bdef298',
      },
      'starts': jsonEncode([
        {
          'id': 'a',
          'scene': 'run',
          'startedAt': _start,
          'endedAt': _start + 40000,
          'outcome': 'process_ended',
          'detail': 'resultCode=0',
        },
        {
          'id': 'b',
          'scene': 'run',
          'startedAt': _start + 60000,
          'outcome': 'game_running',
          'detail': 'Start läuft noch',
        },
        {
          'id': 'c',
          'scene': 'quiz',
          'startedAt': _start + 90000,
          'endedAt': _start + 300000,
          'outcome': 'returned',
          'loadedAfterMs': 6400,
          'loadedScene': 'quiz',
          'note': 'Ein übrig gebliebenes Spiel wurde vorher beendet.',
        },
      ]),
      'log': '2026-11-18 19:04:13.120  4711  4733 I godot   : '
          '[Router] boot\n'
          '2026-11-18 19:04:51.004  4711  4733 F libc    : '
          'Fatal signal 11 (SIGSEGV)',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('start entries become one readable sentence each', () {
    final report = NativeGameStartReport.fromPlatform(_report());
    expect(report.starts.map((start) => start.scene), ['quiz', 'run', 'run'],
        reason: 'neueste zuerst');
    expect(
        report.starts[0].sentence,
        'Ohne Fehler geladen nach 6,4 s und normal zurückgekehrt. '
        'Ein übrig gebliebenes Spiel wurde vorher beendet.');
    expect(report.starts[1].sentence, contains('game_running'));
    expect(report.starts[2].sentence, contains('Prozess beendet'));
    expect(report.starts[2].failed, isTrue);
    expect(report.starts[0].failed, isFalse);
    expect(report.copyText, contains('Godot-Stand: bdef298'));
    expect(report.copyText, contains('Fatal signal 11'));
    expect(report.copyText, contains('18.11. 19:04:12  run:'));
  });

  test('malformed platform replies never throw', () {
    final empty = NativeGameStartReport.fromPlatform(null);
    expect(empty.starts, isEmpty);
    expect(empty.copyText, contains('– noch keine –'));
    final broken = NativeGameStartReport.fromPlatform(
        {'starts': '{kaputt', 'log': 3, 'device': 'x'});
    expect(broken.starts, isEmpty);
    expect(broken.log, isEmpty);
    final mixed = NativeGameStartReport.fromPlatform({
      'starts': jsonEncode([
        {'scene': 'kart'},
        {'scene': 'kart', 'startedAt': _start, 'outcome': 'neu'},
      ])
    });
    expect(mixed.starts.single.sentence, 'Ergebnis: neu.');
  });

  testWidgets('parents open the protocol from the 3D card and copy it',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    final calls = <String>[];
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(_diagnostics,
        (call) async {
      calls.add(call.method);
      return _report();
    });
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
    SharedPreferences.setMockInitialValues({});
    final app = LumoAppState();
    try {
      await tester.pumpWidget(MaterialApp(
          theme: LumoAppTheme.light(),
          home: Scaffold(
              body: SingleChildScrollView(
                  child: NativeGameSavesCard(appState: app)))));
      await tester
          .tap(find.byKey(const ValueKey('native-game-start-log-open')));
      await tester.pumpAndSettle();
      expect(calls, ['gameStartLog']);
      expect(find.text('Spiel-Startprotokoll'), findsOneWidget);
      expect(find.textContaining('quiz: Ohne Fehler geladen nach 6,4 s'),
          findsOneWidget);
      expect(find.textContaining('run: Fehler: Das Spiel wurde beendet'),
          findsOneWidget);
      await tester.scrollUntilVisible(
          find.textContaining('Fatal signal 11'), 300,
          scrollable: find.descendant(
              of: find.byKey(const ValueKey('game-start-log-list')),
              matching: find.byType(Scrollable)).first);
      expect(find.textContaining('Fatal signal 11'), findsOneWidget);
      await tester.drag(find.byKey(const ValueKey('game-start-log-list')),
          const Offset(0, 3000));
      await tester.pumpAndSettle();
      final capture = Platform.environment['LUMO_START_LOG_CAPTURE'];
      if (capture != null) {
        await loadLumoCaptureFonts();
        // Android liefert eine eigene Monospace-Schrift; im Test nur für das Bild laden.
        final mono = File('/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf');
        if (mono.existsSync()) {
          await (FontLoader('monospace')
                ..addFont(Future.value(
                    ByteData.sublistView(mono.readAsBytesSync()))))
              .load();
        }
        await tester.pumpAndSettle();
        await captureLumoBoundary(
            tester, const ValueKey('game-start-log-boundary'), capture);
      }
      await tester.tap(find.byKey(const ValueKey('game-start-log-copy')));
      await tester.pumpAndSettle();
      expect(copied, contains('LUMO Spiel-Startprotokoll'));
      expect(copied, contains('Gerät: samsung SM-F966B'));
      expect(copied, contains('quiz: Ohne Fehler geladen nach 6,4 s'));
      expect(find.text('Startprotokoll kopiert.'), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(_diagnostics, null);
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
      await tester.binding.setSurfaceSize(null);
    }
  });

  testWidgets('a host without the method explains itself', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        _diagnostics, (_) async => throw MissingPluginException());
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(_diagnostics, null));
    await tester.pumpWidget(MaterialApp(
        theme: LumoAppTheme.light(), home: const NativeGameStartLogScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('game-start-log-error')), findsOneWidget);
    expect(find.textContaining('nur in der Android-App'), findsOneWidget);
  });
}
