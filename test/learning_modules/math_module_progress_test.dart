import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/learning_profile_engine.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/learning_modules/minus_bis_10/minus_bis_10_screen.dart';
import 'package:lumo_lernen/features/learning_modules/zahlen_bis_10/zahlen_bis_10_screen.dart';
import 'package:lumo_lernen/features/learning_modules/formen/formen_screen.dart';
import 'package:lumo_lernen/features/learning_modules/uhr_lernen/uhr_lernen_screen.dart';
import 'package:lumo_lernen/features/learning_modules/geld/geld_screen.dart';
import 'package:lumo_lernen/features/learning_modules/zahlen_bis_100/zahlen_bis_100_screen.dart';
import 'package:lumo_lernen/features/learning_modules/einmaleins/einmaleins_screen.dart';

import 'learning_module_progress_test.dart'
    show BlockedModuleProgress, BlockedModuleWallet;

typedef _Screen = Widget Function(LumoAppState);

final _modules = <(String, _Screen, int)>[
  ('Minus bis 10', (app) => MinusBis10Screen(appState: app), 5),
  ('Zahlen 1-10', (app) => ZahlenBis10Screen(appState: app), 5),
  ('Formen', (app) => FormenScreen(appState: app), 5),
  ('Die Uhr', (app) => UhrLernenScreen(appState: app), 8),
  ('Geld', (app) => GeldScreen(appState: app), 7),
  ('Zahlen bis 100', (app) => ZahlenBis100Screen(appState: app), 6),
  ('Kleines 1×1', (app) => EinmaleinsScreen(appState: app), 6),
  ('Großes 1×1', (app) => EinmaleinsScreen(appState: app, fullRange: true), 6),
];

Future<void> _frames(WidgetTester tester, [int count = 90]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(microseconds: 16667));
  }
}

Future<void> _open(
    WidgetTester tester, LumoAppState app, _Screen screen) async {
  await tester.binding.setSurfaceSize(const Size(480, 1000));
  await tester.runAsync(() async {
    await app.hydrateFromWallet();
    await app.loadLearningProfile();
  });
  await tester.pumpWidget(MaterialApp(
    home: Builder(
        builder: (context) => Scaffold(
                body: TextButton(
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute<void>(builder: (_) => screen(app))),
              child: const Text('Modul öffnen'),
            ))),
  ));
  await tester.tap(find.text('Modul öffnen'));
  await _frames(tester);
  expect(
      find.textContaining(RegExp(r'^(Aufgabe|Uhrzeit) 1 /')), findsOneWidget);
}

List<Text> _texts(WidgetTester tester) =>
    tester.widgetList<Text>(find.byType(Text)).toList();
List<String> _choices(WidgetTester tester) => tester
    .widgetList<Text>(
        find.descendant(of: find.byType(GridView), matching: find.byType(Text)))
    .map((text) => text.data!)
    .toList();

Finder _choice(String value) =>
    find.descendant(of: find.byType(GridView), matching: find.text(value));

/// Compute from the actual visible problem, quantities or painter input used
/// to draw the illustration; never replace a task or call its private answer.
String _correct(WidgetTester tester, String unit) {
  final texts = _texts(tester);
  final labels = texts.map((text) => text.data ?? '').toList();
  if (unit == 'Minus bis 10' || unit.contains('1×1')) {
    final pattern = RegExp(r'^(\d+) (−|×) (\d+) = \?$');
    final match =
        labels.map(pattern.firstMatch).whereType<RegExpMatch>().single;
    final a = int.parse(match[1]!), b = int.parse(match[3]!);
    return '${match[2] == '−' ? a - b : a * b}';
  }
  if (unit == 'Formen') {
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .singleWhere((p) => p.runtimeType.toString() == '_ShapePainter');
    final name = ((painter as dynamic).shape as Enum).name;
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }
  if (unit == 'Die Uhr') {
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .singleWhere((p) => p.runtimeType.toString() == '_ClockPainter');
    final hour = (painter as dynamic).hour as int;
    final minute = (painter as dynamic).minute as int;
    if (minute == 0) return '$hour Uhr';
    if (minute == 30) return 'halb ${hour + 1}';
    return minute == 15 ? 'Viertel nach $hour' : 'Viertel vor ${hour + 1}';
  }
  if (unit == 'Geld') {
    final question = labels.singleWhere((value) =>
        value.startsWith('Welche Münze') ||
        value == 'Wie viel Geld siehst du?');
    if (question.startsWith('Welche Münze')) {
      return question.substring(
          'Welche Münze ist '.length, question.length - 1);
    }
    final coins = texts
        .where((text) => text.style?.fontSize == 70 * .26)
        .map((text) => RegExp(r'^(\d+)(c|€)$').firstMatch(text.data ?? ''))
        .whereType<RegExpMatch>();
    final cents = coins
        .map((coin) => int.parse(coin[1]!) * (coin[2] == '€' ? 100 : 1))
        .reduce((a, b) => a + b);
    return cents < 100
        ? '$cents Cent'
        : cents % 100 == 0
            ? '${cents ~/ 100} Euro'
            : '${cents ~/ 100} Euro ${cents % 100}';
  }
  if (labels.contains('Welche Zahl ist größer?')) {
    final fontSize = unit == 'Zahlen 1-10' ? 56.0 : 48.0;
    final numbers = texts
        .where((text) => text.style?.fontSize == fontSize)
        .map((text) => int.tryParse(text.data ?? ''))
        .whereType<int>();
    return '${numbers.reduce((a, b) => a > b ? a : b)}';
  }
  if (labels.contains('Wie viele Punkte siehst du?')) {
    return '${tester.widgetList<Container>(find.byType(Container)).where((box) => box.constraints?.maxWidth == 36 && box.constraints?.maxHeight == 36).length}';
  }
  final question = labels.singleWhere((value) =>
      value.startsWith('Welche Zahl kommt') ||
      value.startsWith('Wie viele Zehner hat'));
  final number = int.parse(RegExp(r'\d+').firstMatch(question)![0]!);
  return '${question.contains('Zehner') ? number ~/ 10 : number + (question.contains('nach') ? 1 : -1)}';
}

Future<void> _tap(WidgetTester tester, String answer) async {
  await tester.ensureVisible(_choice(answer));
  await tester.pump();
  await tester.tap(_choice(answer));
  await _frames(tester, 170);
}

Future<void> _stored(WidgetTester tester, String unit,
    {required int correct,
    int wrong = 0,
    required int stars,
    required int xp}) async {
  await tester.runAsync(() async {
    final reopened = LumoAppState(walletRepository: RewardWalletRepository());
    await reopened.hydrateFromWallet();
    await reopened.loadLearningProfile();
    expect(reopened.learningDailyDone(), correct);
    final record =
        reopened.learningSkills()[SkillRecord.makeId('Mathematik', unit)]!;
    expect(record.correct, correct);
    expect(record.wrong, wrong);
    expect(reopened.state.stars, stars);
    expect(reopened.state.xp, xp);
    reopened.dispose();
  });
}

Future<void> _close(WidgetTester tester, LumoAppState app) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  app.dispose();
  await tester.binding.setSurfaceSize(null);
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
  });

  for (final (unit, screen, xp) in _modules) {
    testWidgets(
        '$unit: actual controls persist false then correct once, retaining rewards',
        (tester) async {
      final app = LumoAppState(walletRepository: RewardWalletRepository());
      await _open(tester, app, screen);
      final answer = _correct(tester, unit);
      final wrong = _choices(tester).firstWhere((choice) => choice != answer);
      await _tap(tester, wrong);
      expect(app.learningDailyDone(), 0);
      await _tap(tester, _correct(tester, unit));
      expect(app.learningDailyDone(), 1);
      await _stored(tester, unit, correct: 1, wrong: 1, stars: 1, xp: xp);
      await tester.binding.handlePopRoute();
      await _frames(tester);
      expect(find.text('Modul öffnen'), findsOneWidget);
      await _close(tester, app);
    });
  }

  testWidgets(
      'actual Minus retries wallet then profile, blocks both Back paths and pauses feedback',
      (tester) async {
    final wallet = BlockedModuleWallet();
    final repository = BlockedModuleProgress();
    final app = LumoAppState(
        walletRepository: wallet,
        learningProfile: LearningProfileEngine(repository: repository));
    await _open(tester, app, (app) => MinusBis10Screen(appState: app));
    wallet.reject = true;
    final answer = _correct(tester, 'Minus bis 10');
    await tester.ensureVisible(_choice(answer));
    final touch = tester.getCenter(_choice(answer));
    await tester.tapAt(touch);
    await tester.tapAt(touch);
    await _frames(tester);
    expect(find.text('Erneut versuchen'), findsOneWidget);
    expect(find.text('Aufgabe 1 / 30'), findsOneWidget);
    for (final size in [const Size(360, 800), const Size(720, 1000)]) {
      await tester.binding.setSurfaceSize(size);
      await _frames(tester, 20);
      expect(find.text('Erneut versuchen'), findsOneWidget);
      expect(find.text('Aufgabe 1 / 30'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final retryBounds = tester.getRect(find.text('Erneut versuchen'));
      final contentBounds = tester.getRect(find.descendant(
          of: find.byType(MinusBis10Screen), matching: find.byType(Scaffold)));
      expect(retryBounds.bottom, lessThanOrEqualTo(contentBounds.top));
    }
    await tester.binding.handlePopRoute();
    await _frames(tester);
    await tester.tap(find.byType(IconButton), warnIfMissed: false);
    await _frames(tester);
    expect(find.byType(MinusBis10Screen), findsOneWidget);
    wallet.reject = false;
    repository.rejectWrite = true;
    await tester.tap(find.text('Erneut versuchen'));
    await _frames(tester);
    expect(find.text('Erneut versuchen'), findsOneWidget);
    expect(app.learningDailyDone(), 1);
    repository.rejectWrite = false;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.tap(find.text('Erneut versuchen'));
    await _frames(tester, 300);
    expect(find.text('Aufgabe 1 / 30'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _frames(tester);
    expect(find.text('Aufgabe 2 / 30'), findsOneWidget);
    await _stored(tester, 'Minus bis 10', correct: 1, stars: 1, xp: 5);
    await _close(tester, app);
  });

  testWidgets(
      'actual module unmount during a delayed wallet still stores the learning answer',
      (tester) async {
    final wallet = BlockedModuleWallet();
    final app = LumoAppState(walletRepository: wallet);
    await _open(tester, app, (app) => MinusBis10Screen(appState: app));
    wallet.gate = Completer<void>();
    final answer = _correct(tester, 'Minus bis 10');
    await tester.ensureVisible(_choice(answer));
    await tester.tap(_choice(answer));
    await _frames(tester, 30);
    await tester.pumpWidget(const SizedBox());
    wallet.gate!.complete();
    await _frames(tester);
    await _stored(tester, 'Minus bis 10', correct: 1, stars: 1, xp: 5);
    await _close(tester, app);
  });

  testWidgets(
      'actual complete Uhr session persists eight answers and only one separate finish bonus',
      (tester) async {
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    await _open(tester, app, (app) => UhrLernenScreen(appState: app));
    for (var i = 0; i < 8; i++) {
      await _tap(tester, _correct(tester, 'Die Uhr'));
    }
    expect(find.text('🕐 Geschafft!'), findsOneWidget);
    await _stored(tester, 'Die Uhr', correct: 8, stars: 13, xp: 144);
    await tester.tap(find.text('Fertig'));
    await _frames(tester);
    expect(find.text('Modul öffnen'), findsOneWidget);
    await _close(tester, app);
  });
}
