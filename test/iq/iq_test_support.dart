// Gemeinsame Hilfen für die Tests des Lumo Knobel-Tests (Widget-Tests und
// Aufnahme-Test). Alles deterministisch: feste Seeds, feste Uhr.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/iq/iq_test_repository.dart';
import 'package:lumo_lernen/core/iq/iq_test_session.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/iq/iq_puzzle.dart';
import 'package:lumo_lernen/features/tests/iq_test_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Die Uhr der Tests: 8. Oktober 2026, 10 Uhr.
DateTime iqTestNow() => DateTime(2026, 10, 8, 10);

/// Lädt Nunito und die Symbolschrift, damit Textbreiten und Symbole in den
/// Tests so aussehen wie in der App.
Future<void> loadIqFonts() async {
  final nunito = FontLoader('Nunito')
    ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf'));
  await nunito.load();
  await (FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
      .load();
}

/// Setzt Speicher, Stimme und Belohnungs-Konto zurück. Gehört in `setUp`
/// (nicht in den Testrumpf): Das Konto ist ein Einzelstück, dessen
/// Schreibwarteschlange sonst an der Zeit des vorigen Tests hängen bleibt.
Future<void> resetIqEnvironment({
  Map<String, Object> prefs = const {},
  bool reduceAnimations = true,
}) async {
  SharedPreferences.setMockInitialValues({
    'lumo_app_settings_v1': jsonEncode(AppSettings(
      voiceEnabled: false,
      autoReadEnabled: false,
      microphoneEnabled: false,
      aiProxyEnabled: false,
      reduceAnimations: reduceAnimations,
    ).toJson()),
    ...prefs,
  });
  LumoVoice.instance.isEnabled = false;
  await RewardWalletRepository.instance.reset();
}

/// Ein Kind „Mia“ in der 2. Klasse mit den gewünschten Einstellungen und
/// einem eigenen, frischen Sternen-Konto.
LumoAppState iqTestApp({bool reduceAnimations = true, int grade = 2}) {
  final app = LumoAppState(walletRepository: RewardWalletRepository());
  app.update(app.state.copyWith(
    childName: 'Mia',
    grade: grade,
    settings: AppSettings(
      voiceEnabled: false,
      autoReadEnabled: false,
      microphoneEnabled: false,
      aiProxyEnabled: false,
      reduceAnimations: reduceAnimations,
    ),
  ));
  return app;
}

/// Kennung, unter der Mias Ergebnisse gespeichert werden.
const iqTestStudentId = 'local_mia_2';

/// Baut den Test-Bildschirm. [boundary] markiert die Fläche für Aufnahmen.
Widget iqScreenApp(
  LumoAppState app, {
  IqTestSession? session,
  Key? boundary,
  double textScale = 1,
  IqTestRepository repository = const IqTestRepository(),
  DateTime Function() now = iqTestNow,
}) {
  final screen = IqTestScreen(
    appState: app,
    session: session,
    repository: repository,
    now: now,
  );
  return MaterialApp(
    theme: LumoAppTheme.light(),
    debugShowCheckedModeBanner: false,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: boundary == null ? screen : RepaintBoundary(key: boundary, child: screen),
  );
}

/// Öffnet den Test wie in der App: von einer Startseite aus mit Navigator.push.
Widget iqLauncherApp(
  LumoAppState app, {
  IqTestSession? session,
  IqTestRepository repository = const IqTestRepository(),
  DateTime Function() now = iqTestNow,
}) =>
    MaterialApp(
      theme: LumoAppTheme.light(),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              key: const ValueKey('open-iq'),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => IqTestScreen(
                    appState: app,
                    session: session,
                    repository: repository,
                    now: now,
                  ),
                ),
              ),
              child: const Text('Öffnen'),
            ),
          ),
        ),
      ),
    );

/// Zeit weiterlaufen lassen, bis Seitenwechsel und Speichern fertig sind.
Future<void> settleIq(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  expect(finder, findsOneWidget, reason: key);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await settleIq(tester);
}

/// Von der Startseite zur ersten Anleitung.
Future<void> startIqTest(WidgetTester tester) => tapKey(tester, 'iq-start-button');

/// Anleitung wegtippen („Los geht’s“).
Future<void> leaveAreaIntro(WidgetTester tester) => tapKey(tester, 'iq-area-go');

/// Lässt den Merk-Blitz ablaufen (alle Felder haben geleuchtet).
Future<void> waitForMemoryShow(WidgetTester tester, IqMemoryPuzzle puzzle) async {
  final total = 700 +
      puzzle.sequence.length * (puzzle.showMs + puzzle.gapMs) +
      300;
  await tester.pump(Duration(milliseconds: total));
  await tester.pump(const Duration(milliseconds: 50));
}

/// Beantwortet das aktuelle Rätsel durch Antippen und tippt „Weiter“.
///
/// [correct] false: eine falsche Karte, beim Merk-Blitz die umgekehrte
/// Reihenfolge.
Future<void> answerCurrent(
  WidgetTester tester,
  IqTestSession session, {
  required bool correct,
}) async {
  final puzzle = session.current;
  switch (puzzle) {
    case IqChoicePuzzle p:
      final pick = correct ? p.answer : (p.answer + 1) % p.optionCount;
      await tapKey(tester, 'iq-option-$pick');
    case IqMemoryPuzzle p:
      await waitForMemoryShow(tester, p);
      final taps = correct ? p.sequence : p.sequence.reversed.toList();
      for (final cell in taps) {
        await tapKey(tester, 'iq-memory-tile-$cell');
      }
  }
  await tapKey(tester, 'iq-next');
}

/// Ein früheres Ergebnis (für Vergleich und „Letztes Mal“).
IqTestResult earlierIqResult({
  DateTime? finishedAt,
  int seed = 3,
  bool good = true,
}) {
  final session = IqTestSession(grade: 2, seed: seed);
  var i = 0;
  while (!session.finished) {
    final puzzle = session.current;
    final right = good ? i % 4 != 3 : i % 4 == 0;
    session.answer(
      switch (puzzle) {
        IqChoicePuzzle p => [right ? p.answer : (p.answer + 1) % p.optionCount],
        IqMemoryPuzzle p => right ? p.sequence : p.sequence.reversed.toList(),
      },
      durationMs: 4000 + i * 100,
    );
    i++;
  }
  return session.result(
    id: 'iq-frueher-$seed',
    studentId: iqTestStudentId,
    finishedAt: finishedAt ?? DateTime(2026, 10, 1, 16),
    durationMs: 540000,
  );
}

/// Spielt einen ganzen Test ohne Oberfläche durch (für Ergebnis- und
/// Rückblick-Seiten). [correct] sagt je Rätsel (0 bis 23), ob es stimmt.
IqTestSession finishedIqSession({
  int seed = 5,
  int grade = 2,
  bool Function(int index)? correct,
}) {
  final session = IqTestSession(grade: grade, seed: seed);
  var i = 0;
  while (!session.finished) {
    final right = correct?.call(i) ?? i % 4 != 1;
    final puzzle = session.current;
    session.answer(
      switch (puzzle) {
        IqChoicePuzzle p => [right ? p.answer : (p.answer + 1) % p.optionCount],
        IqMemoryPuzzle p => right ? p.sequence : p.sequence.reversed.toList(),
      },
      durationMs: 3000 + i * 50,
    );
    i++;
  }
  return session;
}
